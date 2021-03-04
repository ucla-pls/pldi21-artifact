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

-- Globals
timeout = "86400" -- 24h
extractpy = PackageInput "extractpy"
predicates = PackageInput "predicates"

-- | Run the examples and the full evaluation
main :: IO ()
main = defaultMain . collectLinks $ sequenceA
  [ scope "examples" $ examples strategies
  , scope "full" $ evaluation strategies 100
  ]
 where
  strategies =
    [ "classes"
    , "items+logic"
    , "items+graph+first"
    , "items+graph+last"
    ]

evaluation :: [ Text.Text ] -> Int -> Nixec Rule
evaluation strategies errors = do

  -- Load the benchmarks from the 'benchmarks' package, remove the bad ones
  benchmarks <-
    -- SMALLER: fmap (take 5) .
    fmap (List.sort . removeBadBenchmarks)
    . listFiles (PackageInput "benchmarks")
    $ Text.stripSuffix "_tgz-pJ8"
    . Text.pack

  -- Calculate the sizes of each each benchmark
  cn <-
    scope "sizes"
    . collectWith (\x -> do
      countcnfs <- link "countcnfs.py" (PackageInput "countcnfs")
      path ["python3"]
      cmd "python3" $ do
        args .= [countcnfs, Input "."]
        stdout .= Just "cnfs.csv"
      )
    . scopesBy fst benchmarks
    $ \(name, benchmark) -> collect $ do
        benc <- link "benchmark" benchmark
        stdlib <- link "stdlib.bin" (PackageInput "stubs")
        path ["javaq", "jreduce"]
        cmd "javaq" $ do
          args .= ["class-metrics+csv", "--cp", benc <.+> "/classes"]
          stdout .= Just "size.csv"
        cmd "jreduce" $ do
          args .=
            [ "-W" , Output "workfolder"
            , "--strategy" , "items+logic"
            , "--dump-logic"
            , "--output-file", Output "reduced"
            , "--max-iterations", "1"
            , "--stdlib", stdlib
            , "--cp", benc <.+> "/lib", benc <.+> "/classes", "true"
            ]

  -- For each benchmark
  collectWith (fullCollector cn) . scopesBy fst benchmarks $ \(name, benchmark) ->
    -- and for each predicate
    collectWith resultCollector . scopes predicateNames $ \predicate -> do

      -- Run the predicate on the benchmark
      run <- rule "run" $ do
        benc  <- link "benchmark" benchmark
        predi <- link "predicate" $ predicates <./> toFilePath predicate
        env "MAX_ERRORS" (Text.pack . show $ errors)
        cmd predi $ do
          args .= [benc <.+> "/classes", benc <.+> "/lib"]

      -- If we find errors in the run, try to reduce them with each of the
      -- strategies and jreduce. (see evaluate and evaluateOld)
      reductions <- onSuccess run . rules ("jreduce":strategies) $ \strategy -> do
          env "MAX_ERRORS" (Text.pack . show $ errors)
          case strategy of
            "jreduce" ->
              evaluateOld (defaultSettings run strategy)
            _ -> evaluate ((defaultSettings run strategy) { jreduceVersion = "jreduce" } )

      -- Finally collect the reductions using `extract.py`
      collect $ do
        rs      <- asLinks (concat . maybeToList $ reductions)
        extract <- link "extract.py" extractpy
        needs ["run" ~> run, OnPath "cloc"]
        path ["python3"]
        cmd "python3" $ do
          args .= extract : RegularArg name : RegularArg predicate : rs
          stdout .= Just "result.csv"
        exists "result.csv"
 where
  fullCollector :: RuleName -> [CommandArgument] -> RuleM ()
  fullCollector sizes a = do
    joinCsv resultFields a "result.csv"
    minutes <- link "minutes.py" (PackageInput "minutespy")
    sizes <- link "sizes" sizes
    path ["evaluation"]
    cmd "python3" $ do
      args .= [ minutes, Input "."
              , Output "classes.csv"
              , Output "bytes.csv"
              ]
   where
    resultFields = ["benchmark", "predicate", "strategy"]

  predicateNames = ["cfr", "fernflower", "procyon"]

  removeBadBenchmarks = filter $ \(n,_) -> n `notElem`
    [ -- covariant arrays
     "url22ade473db_sureshsajja_CodingProblems"
    , "url2984a84cec_yusuke2255_relation_resolver"
    , "url484e914e4f_JasperZXY_TestJava"
     -- overloads the stdlibrary
    , "url03c33a0cf1_m_m_m_java8_backports"
    ]

-- | Run the examples one by one
examples :: [ Text.Text ] -> Nixec Rule
examples strategies = do
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
          }
      reds <- rules strategies $ \strategy ->
        evaluate $ ( defaultSettings run strategy)
          { jreduceKeepFolders = True
          , jreduceArgs = []
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

resultCollector x = joinCsv resultFields x "result.csv"
  where resultFields = ["benchmark", "predicate", "strategy"]


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


-- | Shows how to setup the new J-Reduce with most interesting commandline
-- arguments
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
        , "--total-time" , timeout
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

-- | Shows how to setup the Old J-Reduce with most interesting commandline
-- arguments
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
        , "-T" , timeout
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

