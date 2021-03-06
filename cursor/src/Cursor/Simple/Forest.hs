{-# LANGUAGE TypeFamilies #-}

module Cursor.Simple.Forest
  ( ForestCursor,
    FC.singletonForestCursor,
    makeForestCursor,
    rebuildForestCursor,
    FC.drawForestCursor,
    mapForestCursor,
    FC.forestCursorListCursorL,
    FC.forestCursorSelectedTreeL,
    forestCursorSelectPrevTreeCursor,
    forestCursorSelectNextTreeCursor,
    forestCursorSelectFirstTreeCursor,
    forestCursorSelectLastTreeCursor,
    forestCursorSelectPrev,
    forestCursorSelectNext,
    forestCursorSelectPrevOnSameLevel,
    forestCursorSelectNextOnSameLevel,
    forestCursorSelectFirst,
    forestCursorSelectLast,
    forestCursorSelectFirstOnSameLevel,
    forestCursorSelectLastOnSameLevel,
    forestCursorSelectAbove,
    forestCursorSelectBelowAtPos,
    forestCursorSelectBelowAtStart,
    forestCursorSelectBelowAtEnd,
    FC.forestCursorOpenCurrentForest,
    FC.forestCursorCloseCurrentForest,
    FC.forestCursorToggleCurrentForest,
    FC.forestCursorOpenCurrentForestRecursively,
    FC.forestCursorToggleCurrentForestRecursively,
    FC.forestCursorSelection,
    forestCursorSelectIndex,
    FC.forestCursorInsertEntireTree,
    forestCursorInsertAndSelectTreeCursor,
    FC.forestCursorAppendEntireTree,
    forestCursorAppendAndSelectTreeCursor,
    FC.forestCursorInsertTree,
    FC.forestCursorAppendTree,
    forestCursorInsertAndSelectTree,
    forestCursorAppendAndSelectTree,
    FC.forestCursorInsert,
    FC.forestCursorAppend,
    forestCursorInsertAndSelect,
    forestCursorAppendAndSelect,
    forestCursorInsertNodeSingleAndSelect,
    forestCursorAppendNodeSingleAndSelect,
    forestCursorInsertNodeAndSelect,
    forestCursorAppendNodeAndSelect,
    FC.forestCursorAddChildTreeToNodeAtPos,
    FC.forestCursorAddChildTreeToNodeAtStart,
    FC.forestCursorAddChildTreeToNodeAtEnd,
    FC.forestCursorAddChildToNodeAtPos,
    FC.forestCursorAddChildToNodeAtStart,
    FC.forestCursorAddChildToNodeAtEnd,
    forestCursorAddChildTreeToNodeAtPosAndSelect,
    forestCursorAddChildTreeToNodeAtStartAndSelect,
    forestCursorAddChildTreeToNodeAtEndAndSelect,
    forestCursorAddChildToNodeAtPosAndSelect,
    forestCursorAddChildToNodeAtStartAndSelect,
    forestCursorAddChildToNodeAtEndAndSelect,
    forestCursorAddChildNodeSingleToNodeAtPosAndSelect,
    forestCursorAddChildNodeSingleToNodeAtStartAndSelect,
    forestCursorAddChildNodeSingleToNodeAtEndAndSelect,
    forestCursorAddChildNodeToNodeAtPosAndSelect,
    forestCursorAddChildNodeToNodeAtStartAndSelect,
    forestCursorAddChildNodeToNodeAtEndAndSelect,
    forestCursorRemoveElemAndSelectPrev,
    forestCursorDeleteElemAndSelectNext,
    forestCursorRemoveElem,
    forestCursorDeleteElem,
    forestCursorRemoveSubTreeAndSelectPrev,
    forestCursorDeleteSubTreeAndSelectNext,
    forestCursorRemoveSubTree,
    forestCursorDeleteSubTree,
    forestCursorAddRoot,
    FC.forestCursorSwapPrev,
    FC.forestCursorSwapNext,
    forestCursorPromoteElem,
    forestCursorPromoteSubTree,
    forestCursorDemoteElem,
    forestCursorDemoteSubTree,
    FC.forestCursorDemoteElemUnder,
    FC.forestCursorDemoteSubTreeUnder,
    FC.CTree (..),
    FC.makeCTree,
    FC.cTree,
    FC.rebuildCTree,
    FC.CForest (..),
    FC.makeCForest,
    FC.cForest,
    FC.rebuildCForest,
  )
where

import qualified Cursor.Forest as FC
import Cursor.Simple.Tree
import Cursor.Types
import Data.List.NonEmpty (NonEmpty)
import Data.Tree
import Data.Validity.Tree ()

type ForestCursor a = FC.ForestCursor a a

makeForestCursor :: NonEmpty (CTree a) -> ForestCursor a
makeForestCursor = FC.makeForestCursor id

rebuildForestCursor :: ForestCursor a -> NonEmpty (CTree a)
rebuildForestCursor = FC.rebuildForestCursor id

mapForestCursor :: (a -> b) -> ForestCursor a -> ForestCursor b
mapForestCursor f = FC.mapForestCursor f f

forestCursorSelectPrevTreeCursor :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectPrevTreeCursor = FC.forestCursorSelectPrevTreeCursor id id

forestCursorSelectNextTreeCursor :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectNextTreeCursor = FC.forestCursorSelectNextTreeCursor id id

forestCursorSelectFirstTreeCursor :: ForestCursor a -> ForestCursor a
forestCursorSelectFirstTreeCursor = FC.forestCursorSelectFirstTreeCursor id id

forestCursorSelectLastTreeCursor :: ForestCursor a -> ForestCursor a
forestCursorSelectLastTreeCursor = FC.forestCursorSelectLastTreeCursor id id

forestCursorSelectNext :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectNext = FC.forestCursorSelectNext id id

forestCursorSelectPrev :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectPrev = FC.forestCursorSelectPrev id id

forestCursorSelectNextOnSameLevel :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectNextOnSameLevel = FC.forestCursorSelectNextOnSameLevel id id

forestCursorSelectPrevOnSameLevel :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectPrevOnSameLevel = FC.forestCursorSelectPrevOnSameLevel id id

forestCursorSelectFirst :: ForestCursor a -> ForestCursor a
forestCursorSelectFirst = FC.forestCursorSelectFirst id id

forestCursorSelectLast :: ForestCursor a -> ForestCursor a
forestCursorSelectLast = FC.forestCursorSelectLast id id

forestCursorSelectFirstOnSameLevel :: ForestCursor a -> ForestCursor a
forestCursorSelectFirstOnSameLevel = FC.forestCursorSelectFirstOnSameLevel id id

forestCursorSelectLastOnSameLevel :: ForestCursor a -> ForestCursor a
forestCursorSelectLastOnSameLevel = FC.forestCursorSelectLastOnSameLevel id id

forestCursorSelectAbove :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectAbove = FC.forestCursorSelectAbove id id

forestCursorSelectBelowAtPos :: Int -> ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectBelowAtPos = FC.forestCursorSelectBelowAtPos id id

forestCursorSelectBelowAtStart :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectBelowAtStart = FC.forestCursorSelectBelowAtStart id id

forestCursorSelectBelowAtEnd :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectBelowAtEnd = FC.forestCursorSelectBelowAtEnd id id

forestCursorSelectIndex :: Int -> ForestCursor a -> Maybe (ForestCursor a)
forestCursorSelectIndex = FC.forestCursorSelectIndex id id

forestCursorInsertAndSelectTreeCursor :: TreeCursor a -> ForestCursor a -> ForestCursor a
forestCursorInsertAndSelectTreeCursor = FC.forestCursorInsertAndSelectTreeCursor id

forestCursorAppendAndSelectTreeCursor :: TreeCursor a -> ForestCursor a -> ForestCursor a
forestCursorAppendAndSelectTreeCursor = FC.forestCursorAppendAndSelectTreeCursor id

forestCursorInsertAndSelectTree :: Tree a -> ForestCursor a -> ForestCursor a
forestCursorInsertAndSelectTree = FC.forestCursorInsertAndSelectTree id id

forestCursorAppendAndSelectTree :: Tree a -> ForestCursor a -> ForestCursor a
forestCursorAppendAndSelectTree = FC.forestCursorAppendAndSelectTree id id

forestCursorInsertAndSelect :: a -> ForestCursor a -> ForestCursor a
forestCursorInsertAndSelect = FC.forestCursorInsertAndSelect id id

forestCursorInsertNodeSingleAndSelect :: a -> ForestCursor a -> ForestCursor a
forestCursorInsertNodeSingleAndSelect = FC.forestCursorInsertNodeSingleAndSelect id

forestCursorInsertNodeAndSelect :: a -> CForest a -> ForestCursor a -> ForestCursor a
forestCursorInsertNodeAndSelect = FC.forestCursorInsertNodeAndSelect id

forestCursorAppendAndSelect :: a -> ForestCursor a -> ForestCursor a
forestCursorAppendAndSelect = FC.forestCursorAppendAndSelect id id

forestCursorAppendNodeSingleAndSelect :: a -> ForestCursor a -> ForestCursor a
forestCursorAppendNodeSingleAndSelect = FC.forestCursorAppendNodeSingleAndSelect id

forestCursorAppendNodeAndSelect :: a -> CForest a -> ForestCursor a -> ForestCursor a
forestCursorAppendNodeAndSelect = FC.forestCursorAppendNodeAndSelect id

forestCursorAddChildTreeToNodeAtPosAndSelect :: Int -> Tree a -> ForestCursor a -> ForestCursor a
forestCursorAddChildTreeToNodeAtPosAndSelect = FC.forestCursorAddChildTreeToNodeAtPosAndSelect id id

forestCursorAddChildTreeToNodeAtStartAndSelect :: Tree a -> ForestCursor a -> ForestCursor a
forestCursorAddChildTreeToNodeAtStartAndSelect =
  FC.forestCursorAddChildTreeToNodeAtStartAndSelect id id

forestCursorAddChildTreeToNodeAtEndAndSelect :: Tree a -> ForestCursor a -> ForestCursor a
forestCursorAddChildTreeToNodeAtEndAndSelect = FC.forestCursorAddChildTreeToNodeAtEndAndSelect id id

forestCursorAddChildToNodeAtPosAndSelect :: Int -> a -> ForestCursor a -> ForestCursor a
forestCursorAddChildToNodeAtPosAndSelect = FC.forestCursorAddChildToNodeAtPosAndSelect id id

forestCursorAddChildToNodeAtStartAndSelect :: a -> ForestCursor a -> ForestCursor a
forestCursorAddChildToNodeAtStartAndSelect = FC.forestCursorAddChildToNodeAtStartAndSelect id id

forestCursorAddChildToNodeAtEndAndSelect :: a -> ForestCursor a -> ForestCursor a
forestCursorAddChildToNodeAtEndAndSelect = FC.forestCursorAddChildToNodeAtEndAndSelect id id

forestCursorAddChildNodeSingleToNodeAtPosAndSelect :: Int -> a -> ForestCursor a -> ForestCursor a
forestCursorAddChildNodeSingleToNodeAtPosAndSelect = FC.forestCursorAddChildNodeSingleToNodeAtPosAndSelect id

forestCursorAddChildNodeSingleToNodeAtStartAndSelect :: a -> ForestCursor a -> ForestCursor a
forestCursorAddChildNodeSingleToNodeAtStartAndSelect = FC.forestCursorAddChildNodeSingleToNodeAtStartAndSelect id

forestCursorAddChildNodeSingleToNodeAtEndAndSelect :: a -> ForestCursor a -> ForestCursor a
forestCursorAddChildNodeSingleToNodeAtEndAndSelect = FC.forestCursorAddChildNodeSingleToNodeAtEndAndSelect id

forestCursorAddChildNodeToNodeAtPosAndSelect :: Int -> a -> Forest a -> ForestCursor a -> ForestCursor a
forestCursorAddChildNodeToNodeAtPosAndSelect = FC.forestCursorAddChildNodeToNodeAtPosAndSelect id

forestCursorAddChildNodeToNodeAtStartAndSelect :: a -> Forest a -> ForestCursor a -> ForestCursor a
forestCursorAddChildNodeToNodeAtStartAndSelect = FC.forestCursorAddChildNodeToNodeAtStartAndSelect id

forestCursorAddChildNodeToNodeAtEndAndSelect :: a -> Forest a -> ForestCursor a -> ForestCursor a
forestCursorAddChildNodeToNodeAtEndAndSelect = FC.forestCursorAddChildNodeToNodeAtEndAndSelect id

forestCursorRemoveElemAndSelectPrev :: ForestCursor a -> Maybe (DeleteOrUpdate (ForestCursor a))
forestCursorRemoveElemAndSelectPrev = FC.forestCursorRemoveElemAndSelectPrev id

forestCursorDeleteElemAndSelectNext :: ForestCursor a -> Maybe (DeleteOrUpdate (ForestCursor a))
forestCursorDeleteElemAndSelectNext = FC.forestCursorDeleteElemAndSelectNext id

forestCursorRemoveElem :: ForestCursor a -> DeleteOrUpdate (ForestCursor a)
forestCursorRemoveElem = FC.forestCursorRemoveElem id

forestCursorDeleteElem :: ForestCursor a -> DeleteOrUpdate (ForestCursor a)
forestCursorDeleteElem = FC.forestCursorDeleteElem id

forestCursorRemoveSubTreeAndSelectPrev :: ForestCursor a -> Maybe (DeleteOrUpdate (ForestCursor a))
forestCursorRemoveSubTreeAndSelectPrev = FC.forestCursorRemoveSubTreeAndSelectPrev id

forestCursorDeleteSubTreeAndSelectNext :: ForestCursor a -> Maybe (DeleteOrUpdate (ForestCursor a))
forestCursorDeleteSubTreeAndSelectNext = FC.forestCursorDeleteSubTreeAndSelectNext id

forestCursorRemoveSubTree :: ForestCursor a -> DeleteOrUpdate (ForestCursor a)
forestCursorRemoveSubTree = FC.forestCursorRemoveSubTree id

forestCursorDeleteSubTree :: ForestCursor a -> DeleteOrUpdate (ForestCursor a)
forestCursorDeleteSubTree = FC.forestCursorDeleteSubTree id

forestCursorAddRoot :: ForestCursor a -> a -> TreeCursor a
forestCursorAddRoot = FC.forestCursorAddRoot id id

forestCursorPromoteElem :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorPromoteElem = FC.forestCursorPromoteElem id id

forestCursorPromoteSubTree :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorPromoteSubTree = FC.forestCursorPromoteSubTree id id

forestCursorDemoteElem :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorDemoteElem = FC.forestCursorDemoteElem id id

forestCursorDemoteSubTree :: ForestCursor a -> Maybe (ForestCursor a)
forestCursorDemoteSubTree = FC.forestCursorDemoteSubTree id id
