{-# LANGUAGE OverloadedStrings #-}

module HitCounter where

import Control.Monad.IO.Class
import Control.Monad.Trans.Class
import Control.Monad.Trans.Reader
import Data.IORef
import qualified Data.Map as M
import Data.Maybe (fromMaybe)
import Data.Text.Lazy (Text)
import qualified Data.Text.Lazy as TL
import System.Environment (getArgs)
import Web.Scotty.Trans
import Data.Semigroup ((<>))

data Config = Config { counts :: IORef (M.Map Text Integer)
                     , prefix :: Text
                     }

-- Stuff inside ScottyT is, except for things that escape
-- via IO, effectively read-only so we can't use StateT.
-- It would overcomplicate things to attempt to do so and
-- you should be using a proper database for production applications.
type Scotty = ScottyT Text (ReaderT Config IO)
type Handler = ActionT Text (ReaderT Config IO)

bumpBoomp :: Text -> M.Map Text Integer -> (M.Map Text Integer, Integer)
bumpBoomp k m = let v = fromMaybe 0 (M.lookup k m)
                in (M.insert k (v + 1) m, v)

app :: Scotty ()
app = get "/:key" $ do
  unprefixed <- param "key" :: Handler Text
  config <- lift ask
  let key' = prefix config <> unprefixed
  newInteger <- liftIO $ atomicModifyIORef' (counts config) (bumpBoomp key')
  html $ mconcat [ "<h1>Success! Count was: "
                 , TL.pack $ show newInteger
                 , "</h1>"
                 ]

main :: IO ()
main = do
  [prefixArg] <- getArgs
  counter <- newIORef M.empty
  let config = Config counter (TL.pack prefixArg)
      runR r = runReaderT r config
  scottyT 3000 runR app
