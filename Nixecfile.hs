{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE RecordWildCards #-}
import System.Directory
import Data.Foldable
import Data.Maybe
import Data.String
import qualified Data.List as List
import qualified Data.Text as Text
import Nixec

predicates :: Input
predicates = PackageInput "predicates"

data JReduceSettings = JReduceSettings 
  { jreduceRunName     :: RuleName
  , jreduceStrategy    :: Text.Text
  , jreduceKeepFolders :: Bool
  , jreducePreserve    :: [Text.Text]
  } deriving (Show)

defaultSettings run strategy = JReduceSettings 
  { jreduceRunName = run
  , jreduceStrategy = strategy
  , jreduceKeepFolders = False
  , jreducePreserve = ["out", "exit"]
  }

evaluate :: JReduceSettings -> RuleM ()
evaluate JReduceSettings {..} = do
  benc <- link "benchmark" (jreduceRunName <./> "benchmark")
  predi <- link "predicate" (jreduceRunName <./> "predicate")
  path [ "haskellPackages.jreduce" ] 
  cmd "jreduce" $ args .= concat
    [ [ "-W", Output "workfolder"
      , "-v"
      , "-p", RegularArg (Text.intercalate "," jreducePreserve)
      , "--total-time", "3600"
      , "--strategy", RegularArg jreduceStrategy
      , "--output-file", Output "reduced"
      ]
    , [ "--remove-folders" | not jreduceKeepFolders ]
    , [ "--metrics-file", "../metrics.csv"
      , "--try-initial"
      , "--stdlib", "--cp", benc <.+> "/lib"
      , benc <.+> "/classes"
      , predi , "{}" , "%" <.+> benc <.+> "/lib"
      ]
    ]

main :: IO ()
main = defaultMain $ do
  benchmarks <- listFiles benchmarkpkg 
    $ Text.stripSuffix "_tgz-pJ8" . Text.pack
  
  collectWith resultCollector . scopesBy fst benchmarks $ \(name, benchmark) ->
    collectWith resultCollector . scopes predicateNames $ \predicate -> do
      run <- rule "run" $ do
        benc <- link "benchmark" benchmark
        predi <- link "predicate" $ predicates <./> toFilePath predicate
        cmd predi $ args .= [ benc <.+> "/classes" , benc <.+> "/lib"]

      reduce <- onSuccess run $ scopes strategies $ \strategy -> do
        reductions <- rules ["part", "full"] $ evaluate . \case
          "full" -> 
            defaultSettings run strategy
          "part" -> 
            (defaultSettings run strategy)
             { jreduceKeepFolders = True
             , jreducePreserve = [ "exit" ]
             }
          a -> error $ "unexpected rule " <> show a

        collect $ do
          rs <- asLinks reductions
          extract <- link "extract.py" extractpy
          path [ "python3" ]
          cmd "python3" $ do
            args .= extract : RegularArg name : RegularArg predicate : rs
            stdout .= Just "result.csv"
          exists "result.csv"

      collect $ do
        needs [ "run" ~> run ]
        r <- asLinks (concat . maybeToList $ reduce)
        joinCsv resultFields r "result.csv"

  where
    predicateNames =
      [ "cfr" , "fernflower", "procyon"]

    strategies =
      ["classes", "deep", "deep+i2m", "deep+m2m"] 

    benchmarkpkg =
      PackageInput "benchmark-small"

    resultFields =
      [ "benchmark", "predicate", "strategy" ]

    resultCollector x =
      joinCsv resultFields x "result.csv"

    extractpy = 
      FileInput "/Users/kalhauge/Work/Phd/articles/method-reduction/bin/extract.py"

