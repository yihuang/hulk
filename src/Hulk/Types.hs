{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Hulk.Types where

import Control.Monad.Reader
import Control.Monad.State
import Control.Monad.Writer
import Data.Function
import Data.Map             (Map)
import Network
import Network.IRC          hiding (Channel)
import System.IO

data Config = Config {
      configListen :: PortNumber
    , configHostname :: String
    , configMotd :: Maybe FilePath
    , configPreface :: Maybe FilePath
    , configPasswd :: FilePath
    , configPasswdKey :: FilePath
    } deriving (Show)

newtype Ref = Ref { unRef :: Handle } 
    deriving (Show,Eq)

instance Ord Ref where
  compare = on compare show

-- | Construct a Ref value.
newRef :: Handle -> Ref
newRef = Ref

data Error = Error String

data Env = Env {
   envClients :: Map Ref Client
  ,envNicks :: Map String Ref
  ,envChannels :: Map String Channel
}

data Channel = Channel {
      channelName :: String
    , channelTopic :: Maybe String
    , channelUsers :: [Ref]
} deriving Show

data User = Unregistered UnregUser | Registered RegUser
  deriving Show

data UnregUser = UnregUser {
   unregUserName :: Maybe String
  ,unregUserNick :: Maybe String
  ,unregUserUser :: Maybe String
  ,unregUserPass :: Maybe String
} deriving Show

data RegUser = RegUser {
   regUserName :: String
  ,regUserNick :: String
  ,regUserUser :: String
  ,regUserPass :: String
} deriving Show

data Client = Client {
      clientRef :: Ref
    , clientUser :: User
    , clientHostname :: String
    } deriving Show

data Conn = Conn {
   connRef :: Ref
  ,connHostname :: String
  ,connServerName :: String
} deriving Show

data Reply = MessageReply Ref Message | LogReply String | Close

newtype IRC m a = IRC { 
      runIRC :: ReaderT Conn (WriterT [Reply] (StateT Env m)) a
  }
  deriving (Monad
           ,Functor
           ,MonadWriter [Reply]
           ,MonadState Env
           ,MonadReader Conn)

data Event = PASS | USER | NICK | PING | QUIT | TELL | JOIN | PART | PRIVMSG
           | NOTICE | CONNECT | DISCONNECT | NOTHING
  deriving (Read,Show)
