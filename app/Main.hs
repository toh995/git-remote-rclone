module Main where

-- import Data.List
import Control.Monad
import System.Directory
import System.Environment
import System.IO
import System.Process

decryptedRemoteDir :: String
decryptedRemoteDir = "./kk"

main :: IO ()
main = do
  setEnv "RESTIC_REPOSITORY" "/tmp/restic"
  setEnv "RESTIC_PASSWORD" "foo"

  hSetBuffering stdout NoBuffering
  hSetBuffering stdin NoBuffering
  -- localGitDir <- getEnv "GIT_DIR"
  l <- getLine
  notify [l]
  processLine l
  main

processLine :: String -> IO ()
processLine "capabilities" = mapM_ putStrLn ["fetch", "push", "\n"]
processLine "list" = do
  -- setEnv "RESTIC_REPOSITORY" "/tmp/restic"
  -- setEnv "RESTIC_PASSWORD" "foo"
  -- exists <- doesDirectoryExist decryptedRemoteDir
  -- when exists $ removeDirectoryRecursive decryptedRemoteDir
  -- callCommand "notify-send $(ls /tmp/decrypted)"
  -- callCommand "notify-send $RESTIC_REPOSITORY"
  -- callCommand "notify-send $RESTIC_PASSWORD"
  -- callCommand "notify-send asdfasdfasdfasdf"
  -- callCommand "notify-send $(which restic)"
  callCommand $ "restic restore latest --target " ++ decryptedRemoteDir
-- callCommand $ "GIT_DIR=" ++ decryptedRemoteDir ++ " git show-ref"
processLine _ = pure ()

notify :: [String] -> IO ()
notify = callProcess "notify-send"

-- main :: IO ()
-- main = do
--   putStrLn "What's your first name?"
--   firstName <- getLine
--   putStrLn "What's your last name?"
--   lastName <- getLine
--   putStrLn "hello there!"
--   putStrLn $ firstName ++ lastName
