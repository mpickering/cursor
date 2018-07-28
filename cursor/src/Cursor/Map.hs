{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE TypeFamilies #-}

module Cursor.Map
    ( MapCursor(..)
    , makeMapCursor
    , makeMapCursorWithSelection
    , singletonMapCursor
    , rebuildMapCursor
    , mapCursorNonEmptyCursorL
    , mapCursorElemL
    , mapCursorElemKeyL
    , mapCursorElemValueL
    , module Cursor.Map.KeyValue
    ) where

import GHC.Generics (Generic)

import Data.Validity
import Data.Validity.Tree ()

import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NE

import Lens.Micro

import Cursor.Map.KeyValue
import Cursor.NonEmpty

newtype MapCursor k v = MapCursor
    { mapCursorList :: NonEmptyCursor (KeyValueCursor k v)
    } deriving (Show, Eq, Generic, Functor)

instance (Validity k, Validity v) => Validity (MapCursor k v)

makeMapCursor :: NonEmpty (k, v) -> MapCursor k v
makeMapCursor = makeMapCursorWithSelection 0

makeMapCursorWithSelection :: Int -> NonEmpty (k, v) -> MapCursor k v
makeMapCursorWithSelection i ne =
    MapCursor
        { mapCursorList =
              makeNonEmptyCursorWithSelection i $
              NE.map (uncurry makeKeyValueCursor) ne
        }

singletonMapCursor :: k -> v -> MapCursor k v
singletonMapCursor k v = makeMapCursor $ (k, v) :| []

rebuildMapCursor :: MapCursor k v -> NonEmpty (k, v)
rebuildMapCursor =
    NE.map rebuildKeyValueCursor . rebuildNonEmptyCursor . mapCursorList

mapCursorNonEmptyCursorL ::
       Lens' (MapCursor k v) (NonEmptyCursor (KeyValueCursor k v))
mapCursorNonEmptyCursorL =
    lens mapCursorList $ \mc ne -> mc {mapCursorList = ne}

mapCursorElemL :: Lens' (MapCursor k v) (KeyValueCursor k v)
mapCursorElemL = mapCursorNonEmptyCursorL . nonEmptyCursorElemL

mapCursorElemKeyL :: Lens' (MapCursor k v) k
mapCursorElemKeyL = mapCursorElemL . keyValueCursorKeyL

mapCursorElemValueL :: Lens' (MapCursor k v) v
mapCursorElemValueL = mapCursorElemL . keyValueCursorValueL
