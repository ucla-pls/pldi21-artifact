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
  , jreducePreserve    :: [Text.Text]
  , jreduceArgs        :: [ CommandArgument ]
  } deriving (Show)

defaultSettings run strategy = JReduceSettings
  { jreduceRunName     = run
  , jreduceStrategy    = strategy
  , jreduceKeepFolders = False
  , jreducePreserve    = ["out", "exit"]
  , jreduceArgs        = []
  }

evaluate :: JReduceSettings -> RuleM ()
evaluate JReduceSettings {..} = do
  benc   <- link "benchmark" (jreduceRunName <./> "benchmark")
  predi  <- link "predicate" (jreduceRunName <./> "predicate")
  stdlib <- link "stdlib.bin" (PackageInput "stubs")
  path ["haskellPackages.jreduce"]
  cmd "jreduce" $ args .= concat
    [ [ "-W"
      , Output "workfolder"
      , "-v"
      , "-p"
      , RegularArg (Text.intercalate "," jreducePreserve)
      , "--total-time"
      , "3200"
      , "--strategy"
      , RegularArg jreduceStrategy
      , "--output-file"
      , Output "reduced"
      , "--stdlib"
      , stdlib
      , DebugArgs
      ]
    , jreduceArgs
    , [ "--keep-folders" | jreduceKeepFolders ]
    , [ "--metrics-file"
      , "../metrics.csv"
      , "--try-initial"
      , "--cp"
      , benc <.+> "/lib"
      , benc <.+> "/classes"
      , predi
      , "{}"
      , "%" <.+> benc <.+> "/lib"
      ]
    ]

evaluation :: (JReduceSettings -> JReduceSettings) -> Nixec Rule
evaluation update = do
  benchmarks <-
    -- fmap (take 20 . List.sort)
    fmap (List.sort . removeCovariantArrays)
    . listFiles (PackageInput "benchmarks")
    $ Text.stripSuffix "_tgz-pJ8"
    . Text.pack

  cn <-
    scope "sizes"
    . collectWith (\x -> joinCsv [] x "size.csv")
    . scopesBy fst benchmarks
    $ \(name, benchmark) -> collect $ do
        benc <- link "benchmark" benchmark
        path ["haskellPackages.javaq"]
        cmd "javaq" $ do
          args .= ["class-metrics+csv", "--cp", benc <.+> "/classes"]
          stdout .= Just "size.csv"

  collectWith resultCollector . scopesBy fst benchmarks $ \(name, benchmark) ->
    collectWith resultCollector . scopes predicateNames $ \predicate -> do
      run <- rule "run" $ do
        benc  <- link "benchmark" benchmark
        predi <- link "predicate" $ predicates <./> toFilePath predicate
        cmd predi $ args .= [benc <.+> "/classes", benc <.+> "/lib"]

      reductions <- onSuccess run $ rules strategies $ \strategy ->
        evaluate (update $ defaultSettings run strategy)

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

   removeCovariantArrays = 
    filter (\(n,_) -> n `notElem` 
        [ "url22ade473db_sureshsajja_CodingProblems"
        , "url2984a84cec_yusuke2255_relation_resolver"
        , "url484e914e4f_JasperZXY_TestJava" 
        ]
      )

extractpy =
  FileInput "/home/kalhauge/Work/Evaluation/method-reduction/bin/extract.py"

examples = scope "examples" $ do
  let examplenames = ["main_example", "field", "throws", "lambda"]
  collectWith resultCollector . scopes examplenames $ \name -> do
    run <- rule "run" $ do
      bench <- link
        "benchmark"
        (PackageInput (fromString . Text.unpack $ "examples." <> name))
      predi <- createScript "predicate" $ "java -cp $1:$2 Main"
      cmd predi $ args .= [bench <.+> "/classes", bench <.+> "/lib"]

    reductions <- onSuccess run . rules strategies $ \strategy ->
      evaluate $ (defaultSettings run strategy)
        { jreduceKeepFolders = True
        , jreduceArgs = [ "--core"
                        , RegularArg $ "Main"
                        , "--core"
                        , RegularArg $ "Main.main:([Ljava/lang/String;)V!code"
                        ]
        }

    collect $ do
      rs      <- asLinks (concat . maybeToList $ reductions)
      extract <- link "test.py" extractpy
      path ["python3"]
      cmd "python3" $ do
        args .= extract : RegularArg name : rs
        stdout .= Just "result.csv"
      exists "result.csv"

main :: IO ()
main = defaultMain . collectLinks $ sequenceA
  [ examples
  , scope "part" $ evaluation
    (\a -> a { jreduceKeepFolders = False, jreducePreserve = ["exit"] })
  , scope "full" $ evaluation id
  ]

strategies = ["classes", "logic+under", "logic+over"]

resultCollector x = joinCsv resultFields x "result.csv"
  where resultFields = ["benchmark", "predicate", "strategy"]
