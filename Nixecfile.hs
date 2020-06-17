{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

import           System.Directory
import           System.FilePath
import           Data.Foldable
import           Data.Maybe
import           Data.String
import qualified Data.List                     as List
import qualified Data.Text                     as Text
import           Nixec

predicates :: Input
predicates = PackageInput "predicates"

data JReduceSettings = JReduceSettings
  { jreduceRunName     :: RuleName
  , jreduceStrategy    :: Text.Text
  , jreduceKeepFolders :: Bool
  , jreduceKeepOutputs :: Bool
  , jreduceVersion     :: Text.Text
  , jreducePreserve    :: [Text.Text]
  , jreduceArgs        :: [ CommandArgument ]
  } deriving (Show)

defaultSettings run strategy = JReduceSettings
  { jreduceRunName     = run
  , jreduceStrategy    = strategy
  , jreduceKeepFolders = False
  , jreduceKeepOutputs = True
  , jreduceVersion     = "jreduce"
  , jreducePreserve    = ["out", "exit"]
  , jreduceArgs        = []
  }

evaluate :: JReduceSettings -> RuleM ()
evaluate JReduceSettings {..} = do
  benc   <- link "benchmark" (jreduceRunName <./> "benchmark")
  predi  <- link "predicate" (jreduceRunName <./> "predicate")
  expect  <- link "expectation" (jreduceRunName <./> "stdout")
  stdlib <- link "stdlib.bin" (PackageInput "stubs")
  path [packageFromText $ jreduceVersion]
  cmd "jreduce" $ do
    args .= concat
      [ [ "-W" , Output "workfolder"
        , "-v" , "-p"
        , RegularArg (Text.intercalate "," jreducePreserve)
        , "--total-time" , "3200"
        , "--strategy" , RegularArg jreduceStrategy
        , "--output-file", Output "reduced"
        , "--stdlib", stdlib
        , DebugArgs
        ]
      , jreduceArgs
      , [ "--keep-folders" | jreduceKeepFolders ]
      , [ "--keep-outputs" | jreduceKeepOutputs ]
      , [ "--metrics-file", "../metrics.csv"
        , "--try-initial"
        , "--ignore-failure"
        , "--out", expect
        , "--cp", benc <.+> "/lib", benc <.+> "/classes", predi , "{}"
        , "%" <.+> benc <.+> "/lib"
        ]
      ]

evaluateOld :: JReduceSettings -> RuleM ()
evaluateOld JReduceSettings {..} = do
  benc   <- link "benchmark" (jreduceRunName <./> "benchmark")
  predi  <- link "predicate" (jreduceRunName <./> "predicate")
  fix <- link "fix.py" (PackageInput "fixpy")
  -- expect  <- link "expectation" (jreduceRunName <./> "stdout")
  -- stdlib <- link "stdlib.bin" (PackageInput "stubs")
  path ["jreduce-old", "python3", "glibcLocales"]
  env "LANG" "en_US.UTF-8"
  cmd "jreduce" $ do
    args .= concat
      [ [ "-W" , Output "workfolder"
        , "-v"
        , "-T" , "3200"
        , DebugArgs
        ]
      , [ "--stdout" | elem "out" jreducePreserve ]
      , [ "--stderr" | elem "err" jreducePreserve ]
      , jreduceArgs
      , [ "-K" ]
      , [ "--metrics", "workfolder/metrics2.csv"
        , "--cp", benc <.+> "/lib", benc <.+> "/classes", predi , "{}"
        , benc <.+> "/lib"
        ]
      ]
  cmd "python3" $ do
    args .= [ fix, Output "workfolder/metrics2.csv"]
    stdout .= Just "workfolder/metrics.csv"

evaluation :: [ Text.Text ] -> Int -> Nixec Rule
evaluation strategies errors = do
  benchmarks <-
    fmap (List.sort . removeBadBenchmarks)
    . listFiles (PackageInput "benchmarks")
    $ Text.stripSuffix "_tgz-pJ8"
    . Text.pack

  cn <-
    scope "sizes"
    . collectWith (\x -> joinCsv [] x "size.csv")
    . scopesBy fst benchmarks
    $ \(name, benchmark) -> collect $ do
        benc <- link "benchmark" benchmark
        path ["javaq"]
        cmd "javaq" $ do
          args .= ["class-metrics+csv", "--cp", benc <.+> "/classes"]
          stdout .= Just "size.csv"

  collectWith resultCollector . scopesBy fst benchmarks $ \(name, benchmark) ->
    collectWith resultCollector . scopes predicateNames $ \predicate -> do
      run <- rule "run" $ do
        benc  <- link "benchmark" benchmark
        predi <- link "predicate" $ predicates <./> toFilePath predicate
        env "MAX_ERRORS" (Text.pack . show $ errors)
        cmd predi $ do
          args .= [benc <.+> "/classes", benc <.+> "/lib"]

      reductions <- onSuccess run . rules ("jreduce":strategies) $ \strategy -> do
          env "MAX_ERRORS" (Text.pack . show $ errors)
          case strategy of
            "jreduce" ->
              evaluateOld (defaultSettings run strategy)
            _ -> case Text.stripSuffix "+rev" strategy of
              Just strategy' ->
                evaluate ( (defaultSettings run strategy')
                         { jreduceVersion = "jreduce", jreduceArgs = [ "--reverse-order"] }
                        )
              Nothing ->
                evaluate ( (defaultSettings run strategy) { jreduceVersion = "jreduce" } )

      collect $ do
        rs      <- asLinks (concat . maybeToList $ reductions)
        extract <- link "extract.py" extractpy
        needs ["run" ~> run]
        path ["python3"]
        cmd "python3" $ do
          args .= extract : RegularArg name : RegularArg predicate : rs
          stdout .= Just "result.csv"
        exists "result.csv"
 where
   predicateNames = ["cfr", "fernflower", "procyon"]

   removeBadBenchmarks =
    filter (\(n,_) -> n `notElem`
        [ -- covariant arrays
          "url22ade473db_sureshsajja_CodingProblems"
        , "url2984a84cec_yusuke2255_relation_resolver"
        , "url484e914e4f_JasperZXY_TestJava"
          -- overloads the stdlibrary
        , "url03c33a0cf1_m_m_m_java8_backports"
        ]
      )

extractpy = PackageInput "extractpy"

examples = scope "examples" $ do
  let examplenames = ["main_example", "field", "throws", "lambda", "metadata"]
  collectWith resultCollector . scopes examplenames $ \name -> do
    run <- rule "run" $ do
      bench <- link
        "benchmark"
        (PackageInput (fromString . Text.unpack $ "examples." <> name))
      predi <- createScript "predicate" $ "java -cp $1:$2 Main"
      cmd predi $ args .= [bench <.+> "/classes", bench <.+> "/lib"]

    reductions <- onSuccess run $ do
      jred <- rule "jreduce" $ evaluateOld (defaultSettings run "")
          { jreduceKeepFolders = True
          -- , jreduceArgs = [ "--core" , RegularArg $ "Main" ]
          }
      reds <- rules ["classes", "logic", "logic+single"] $ \strategy ->
        evaluate $ ( defaultSettings run strategy)
          { jreduceKeepFolders = True
          , jreduceArgs = []
                          -- [ "--core" , RegularArg $ "Main"
                          -- , "--core" , RegularArg $ "Main.main:([Ljava/lang/String;)V!code"
                          -- ]
          }

      return $ jred:reds

    collect $ do
      rs      <- asLinks (concat . maybeToList $ reductions)
      extract <- link "test.py" extractpy
      path ["python3"]
      cmd "python3" $ do
        args .= extract : RegularArg name : RegularArg "run" : rs
        stdout .= Just "result.csv"
      exists "result.csv"

main :: IO ()
main = defaultMain . collectLinks $ sequenceA
  [ examples
  , scope "full" $ evaluation ["classes", "logic", "logic+single"] 100
  ]

resultCollector x = joinCsv resultFields x "result.csv"
  where resultFields = ["benchmark", "predicate", "strategy"]
