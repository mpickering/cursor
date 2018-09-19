{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DeriveFunctor #-}

module Cursor.Tree
    ( TreeCursor(..)
    , TreeAbove(..)
    , singletonTreeCursor
    , makeTreeCursor
    , makeTreeCursorWithSelection
    , rebuildTreeCursor
    , mapTreeCursor
    -- * Lenses
    , treeCursorAboveL
    , treeCursorCurrentL
    , treeCursorBelowL
    , treeAboveLeftsL
    , treeAboveAboveL
    , treeAboveNodeL
    , treeAboveRightsL
    -- * Drawing
    , drawTreeCursor
    , treeCursorWithPointer
    -- * Movements
    , treeCursorSelection
    , TreeCursorSelection(..)
    , treeCursorSelect
    , treeCursorSelectPrev
    , treeCursorSelectNext
    , treeCursorSelectFirst
    , treeCursorSelectLast
    , treeCursorSelectAbove
    , treeCursorSelectBelowAtPos
    , treeCursorSelectBelowAtStart
    , treeCursorSelectBelowAtEnd
    , treeCursorSelectBelowAtStartRecursively
    , treeCursorSelectBelowAtEndRecursively
    , treeCursorSelectPrevOnSameLevel
    , treeCursorSelectNextOnSameLevel
    , treeCursorSelectAbovePrev
    , treeCursorSelectAboveNext
    -- * Insertions
    , treeCursorInsert
    , treeCursorInsertAndSelect
    , treeCursorAppend
    , treeCursorAppendAndSelect
    , treeCursorAddChildAtPos
    , treeCursorAddChildAtStart
    , treeCursorAddChildAtEnd
    -- * Deletions
    , treeCursorDeleteSubTreeAndSelectPrevious
    , treeCursorDeleteSubTreeAndSelectNext
    , treeCursorDeleteSubTreeAndSelectAbove
    , treeCursorRemoveSubTree
    , treeCursorDeleteSubTree
    , treeCursorDeleteElemAndSelectPrevious
    , treeCursorDeleteElemAndSelectNext
    , treeCursorDeleteElemAndSelectAbove
    , treeCursorRemoveElem
    , treeCursorDeleteElem
    -- * Swapping
    , treeCursorSwapPrev
    , treeCursorSwapNext
    -- * Promotions
    , treeCursorPromoteElem
    , PromoteElemResult(..)
    , treeCursorPromoteSubTree
    , PromoteResult(..)
    -- * Demotions
    , treeCursorDemoteElem
    , treeCursorDemoteSubTree
    , DemoteResult(..)
    , treeCursorDemoteElemUnder
    , treeCursorDemoteSubTreeUnder
    ) where

import Data.Tree
import Data.Validity
import Data.Validity.Tree ()

import GHC.Generics (Generic)

import Control.Applicative
import Control.Monad

import Lens.Micro

import Cursor.Types

data TreeCursor a b = TreeCursor
    { treeAbove :: Maybe (TreeAbove b)
    , treeCurrent :: a
    , treeBelow :: Forest b
    } deriving (Show, Eq, Generic)

currentTree :: (a -> b) -> TreeCursor a b -> Tree b
currentTree f TreeCursor {..} = Node (f treeCurrent) treeBelow

treeCursorAboveL :: Lens' (TreeCursor a b) (Maybe (TreeAbove b))
treeCursorAboveL = lens treeAbove $ \tc ta -> tc {treeAbove = ta}

treeCursorCurrentL :: Lens' (TreeCursor a b) a
treeCursorCurrentL = lens treeCurrent $ \tc a -> tc {treeCurrent = a}

treeCursorBelowL :: Lens' (TreeCursor a b) (Forest b)
treeCursorBelowL = lens treeBelow $ \tc tb -> tc {treeBelow = tb}

instance (Validity a, Validity b) => Validity (TreeCursor a b)

data TreeAbove b = TreeAbove
    { treeAboveLefts :: [Tree b] -- In reverse order
    , treeAboveAbove :: Maybe (TreeAbove b)
    , treeAboveNode :: b
    , treeAboveRights :: [Tree b]
    } deriving (Show, Eq, Generic, Functor)

instance Validity b => Validity (TreeAbove b)

treeAboveLeftsL :: Lens' (TreeAbove b) [Tree b]
treeAboveLeftsL = lens treeAboveLefts $ \ta tal -> ta {treeAboveLefts = tal}

treeAboveAboveL :: Lens' (TreeAbove b) (Maybe (TreeAbove b))
treeAboveAboveL = lens treeAboveAbove $ \ta taa -> ta {treeAboveAbove = taa}

treeAboveNodeL :: Lens' (TreeAbove b) b
treeAboveNodeL = lens treeAboveNode $ \ta a -> ta {treeAboveNode = a}

treeAboveRightsL :: Lens' (TreeAbove b) [Tree b]
treeAboveRightsL = lens treeAboveRights $ \ta tar -> ta {treeAboveRights = tar}

makeTreeCursor :: (b -> a) -> Tree b -> TreeCursor a b
makeTreeCursor g (Node v fs) =
    TreeCursor {treeAbove = Nothing, treeCurrent = g v, treeBelow = fs}

makeTreeCursorWithSelection ::
       (a -> b)
    -> (b -> a)
    -> TreeCursorSelection
    -> Tree b
    -> Maybe (TreeCursor a b)
makeTreeCursorWithSelection f g sel = walkDown sel . makeTreeCursor g
  where
    walkDown SelectNode tc = pure tc
    walkDown (SelectChild i s) tc =
        treeCursorSelectBelowAtPos f g i tc >>= walkDown s

makeTreeCursorWithAbove ::
       (b -> a) -> Tree b -> Maybe (TreeAbove b) -> TreeCursor a b
makeTreeCursorWithAbove g (Node a forest) mta =
    TreeCursor {treeAbove = mta, treeCurrent = g a, treeBelow = forest}

singletonTreeCursor :: a -> TreeCursor a b
singletonTreeCursor v =
    TreeCursor {treeAbove = Nothing, treeCurrent = v, treeBelow = []}

rebuildTreeCursor :: (a -> b) -> TreeCursor a b -> Tree b
rebuildTreeCursor f TreeCursor {..} =
    wrapAbove treeAbove $ Node (f treeCurrent) treeBelow
  where
    wrapAbove Nothing t = t
    wrapAbove (Just TreeAbove {..}) t =
        wrapAbove treeAboveAbove $
        Node treeAboveNode $
        concat [reverse treeAboveLefts, [t], treeAboveRights]

drawTreeCursor :: (Show a, Show b) => TreeCursor a b -> String
drawTreeCursor = drawTree . treeCursorWithPointer

treeCursorWithPointer :: (Show a, Show b) => TreeCursor a b -> Tree String
treeCursorWithPointer TreeCursor {..} =
    wrapAbove treeAbove $
    Node (show treeCurrent ++ " <---") $ showForest treeBelow
  where
    wrapAbove :: (Show b) => Maybe (TreeAbove b) -> Tree String -> Tree String
    wrapAbove Nothing t = t
    wrapAbove (Just TreeAbove {..}) t =
        wrapAbove treeAboveAbove $
        Node (show treeAboveNode) $
        concat
            [ showForest $ reverse treeAboveLefts
            , [t]
            , showForest treeAboveRights
            ]
    showForest :: Show a => Forest a -> Forest String
    showForest = map $ fmap show

mapTreeCursor :: (a -> c) -> (b -> d) -> TreeCursor a b -> TreeCursor c d
mapTreeCursor f g TreeCursor {..} =
    TreeCursor
        { treeAbove = fmap g <$> treeAbove
        , treeCurrent = f treeCurrent
        , treeBelow = map (fmap g) treeBelow
        }

treeCursorSelection :: TreeCursor a b -> TreeCursorSelection
treeCursorSelection TreeCursor {..} = wrap treeAbove SelectNode
  where
    wrap :: Maybe (TreeAbove a) -> TreeCursorSelection -> TreeCursorSelection
    wrap Nothing ts = ts
    wrap (Just ta) ts =
        wrap (treeAboveAbove ta) $ SelectChild (length $ treeAboveLefts ta) ts

data TreeCursorSelection
    = SelectNode
    | SelectChild Int
                  TreeCursorSelection
    deriving (Show, Eq, Generic)

instance Validity TreeCursorSelection

treeCursorSelect ::
       (a -> b)
    -> (b -> a)
    -> TreeCursorSelection
    -> TreeCursor a b
    -> Maybe (TreeCursor a b)
treeCursorSelect f g sel =
    makeTreeCursorWithSelection f g sel . rebuildTreeCursor f

treeCursorSelectPrev ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectPrev f g tc =
    treeCursorSelectAbovePrev f g tc <|> treeCursorSelectPrevOnSameLevel f g tc <|>
    treeCursorSelectAbove f g tc

treeCursorSelectNext ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectNext f g tc =
    treeCursorSelectBelowAtStart f g tc <|>
    treeCursorSelectNextOnSameLevel f g tc <|>
    treeCursorSelectAboveNext f g tc

treeCursorSelectFirst ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> TreeCursor a b
treeCursorSelectFirst f g tc =
    maybe tc (treeCursorSelectFirst f g) $ treeCursorSelectPrev f g tc

treeCursorSelectLast :: (a -> b) -> (b -> a) -> TreeCursor a b -> TreeCursor a b
treeCursorSelectLast f g tc =
    maybe tc (treeCursorSelectLast f g) $ treeCursorSelectNext f g tc

treeCursorSelectAbove ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectAbove f g tc@TreeCursor {..} =
    case treeAbove of
        Nothing -> Nothing
        Just TreeAbove {..} ->
            let newForrest =
                    reverse treeAboveLefts ++
                    [currentTree f tc] ++ treeAboveRights
                newTree = Node treeAboveNode newForrest
             in Just $ makeTreeCursorWithAbove g newTree treeAboveAbove

treeCursorSelectBelowAtPos ::
       (a -> b) -> (b -> a) -> Int -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectBelowAtPos f g pos TreeCursor {..} =
    case splitAt pos treeBelow of
        (_, []) -> Nothing
        (lefts, current:rights) ->
            Just $
            makeTreeCursorWithAbove g current $
            Just $
            TreeAbove
                { treeAboveLefts = reverse lefts
                , treeAboveAbove = treeAbove
                , treeAboveNode = f treeCurrent
                , treeAboveRights = rights
                }

treeCursorSelectBelowAtStart ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectBelowAtStart f g = treeCursorSelectBelowAtPos f g 0

treeCursorSelectBelowAtEnd ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectBelowAtEnd f g tc =
    treeCursorSelectBelowAtPos f g (length (treeBelow tc) - 1) tc

treeCursorSelectBelowAtStartRecursively ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectBelowAtStartRecursively f g tc =
    go <$> treeCursorSelectBelowAtStart f g tc
  where
    go c = maybe c go $ treeCursorSelectBelowAtStart f g c

treeCursorSelectBelowAtEndRecursively ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectBelowAtEndRecursively f g tc =
    go <$> treeCursorSelectBelowAtEnd f g tc
  where
    go c = maybe c go $ treeCursorSelectBelowAtEnd f g c

treeCursorSelectPrevOnSameLevel ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectPrevOnSameLevel f g tc@TreeCursor {..} = do
    ta <- treeAbove
    case treeAboveLefts ta of
        [] -> Nothing
        tree:xs ->
            Just . makeTreeCursorWithAbove g tree $
            Just
                ta
                    { treeAboveLefts = xs
                    , treeAboveRights = currentTree f tc : treeAboveRights ta
                    }

treeCursorSelectNextOnSameLevel ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectNextOnSameLevel f g tc@TreeCursor {..} = do
    ta <- treeAbove
    case treeAboveRights ta of
        [] -> Nothing
        tree:xs ->
            Just . makeTreeCursorWithAbove g tree . Just $
            ta
                { treeAboveLefts = currentTree f tc : treeAboveLefts ta
                , treeAboveRights = xs
                }

-- | Go back and down as far as necessary to find a previous element on a level below
treeCursorSelectAbovePrev ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectAbovePrev f g =
    treeCursorSelectPrevOnSameLevel f g >=>
    treeCursorSelectBelowAtEndRecursively f g

-- | Go up as far as necessary to find a next element on a level above and forward
--
-- Note: This will fail if there is a next node on the same level or any node below the current node
treeCursorSelectAboveNext ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSelectAboveNext f g tc =
    case treeCursorSelectNextOnSameLevel f g tc of
        Just _ -> Nothing
        Nothing ->
            if (null $ treeBelow tc)
                then go tc
                else Nothing
  where
    go tc_ = do
        tc' <- treeCursorSelectAbove f g tc_
        case treeCursorSelectNextOnSameLevel f g tc' of
            Nothing -> go tc'
            Just tc'' -> pure tc''

treeCursorInsert :: Tree b -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorInsert tree tc@TreeCursor {..} = do
    ta <- treeAbove
    let newTreeAbove = ta {treeAboveLefts = tree : treeAboveLefts ta}
    pure tc {treeAbove = Just newTreeAbove}

treeCursorInsertAndSelect ::
       (a -> b)
    -> (b -> a)
    -> Tree b
    -> TreeCursor a b
    -> Maybe (TreeCursor a b)
treeCursorInsertAndSelect f g tree tc@TreeCursor {..} = do
    ta <- treeAbove
    let newTreeAbove =
            ta {treeAboveRights = currentTree f tc : treeAboveRights ta}
    pure $ makeTreeCursorWithAbove g tree $ Just newTreeAbove

treeCursorAppend :: Tree b -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorAppend tree tc@TreeCursor {..} = do
    ta <- treeAbove
    let newTreeAbove = ta {treeAboveRights = tree : treeAboveRights ta}
    pure tc {treeAbove = Just newTreeAbove}

treeCursorAppendAndSelect ::
       (a -> b)
    -> (b -> a)
    -> Tree b
    -> TreeCursor a b
    -> Maybe (TreeCursor a b)
treeCursorAppendAndSelect f g tree tc@TreeCursor {..} = do
    ta <- treeAbove
    let newTreeAbove =
            ta {treeAboveLefts = currentTree f tc : treeAboveLefts ta}
    pure $ makeTreeCursorWithAbove g tree $ Just newTreeAbove

treeCursorAddChildAtPos :: Int -> Tree b -> TreeCursor a b -> TreeCursor a b
treeCursorAddChildAtPos i t tc =
    let (before, after) = splitAt i $ treeBelow tc
     in tc {treeBelow = before ++ [t] ++ after}

treeCursorAddChildAtStart :: Tree b -> TreeCursor a b -> TreeCursor a b
treeCursorAddChildAtStart t tc = tc {treeBelow = t : treeBelow tc}

treeCursorAddChildAtEnd :: Tree b -> TreeCursor a b -> TreeCursor a b
treeCursorAddChildAtEnd t tc = tc {treeBelow = treeBelow tc ++ [t]}

treeCursorDeleteSubTreeAndSelectPrevious ::
       (b -> a) -> TreeCursor a b -> Maybe (DeleteOrUpdate (TreeCursor a b))
treeCursorDeleteSubTreeAndSelectPrevious g TreeCursor {..} =
    case treeAbove of
        Nothing -> Just Deleted
        Just ta ->
            case treeAboveLefts ta of
                [] -> Nothing
                tree:xs ->
                    Just . Updated . makeTreeCursorWithAbove g tree $
                    Just ta {treeAboveLefts = xs}

treeCursorDeleteSubTreeAndSelectNext ::
       (b -> a) -> TreeCursor a b -> Maybe (DeleteOrUpdate (TreeCursor a b))
treeCursorDeleteSubTreeAndSelectNext g TreeCursor {..} =
    case treeAbove of
        Nothing -> Just Deleted
        Just ta ->
            case treeAboveRights ta of
                [] -> Nothing
                tree:xs ->
                    Just . Updated . makeTreeCursorWithAbove g tree $
                    Just ta {treeAboveRights = xs}

treeCursorDeleteSubTreeAndSelectAbove ::
       (b -> a) -> TreeCursor a b -> DeleteOrUpdate (TreeCursor a b)
treeCursorDeleteSubTreeAndSelectAbove g TreeCursor {..} =
    case treeAbove of
        Nothing -> Deleted
        Just TreeAbove {..} ->
            Updated $
            TreeCursor
                { treeAbove = treeAboveAbove
                , treeCurrent = g treeAboveNode
                , treeBelow = reverse treeAboveLefts ++ treeAboveRights
                }

treeCursorRemoveSubTree ::
       (b -> a) -> TreeCursor a b -> DeleteOrUpdate (TreeCursor a b)
treeCursorRemoveSubTree g tc =
    joinDeletes
        (treeCursorDeleteSubTreeAndSelectPrevious g tc)
        (treeCursorDeleteSubTreeAndSelectNext g tc) <|>
    treeCursorDeleteSubTreeAndSelectAbove g tc

treeCursorDeleteSubTree ::
       (b -> a) -> TreeCursor a b -> DeleteOrUpdate (TreeCursor a b)
treeCursorDeleteSubTree g tc =
    joinDeletes
        (treeCursorDeleteSubTreeAndSelectNext g tc)
        (treeCursorDeleteSubTreeAndSelectPrevious g tc) <|>
    treeCursorDeleteSubTreeAndSelectAbove g tc

treeCursorDeleteElemAndSelectPrevious ::
       (b -> a) -> TreeCursor a b -> Maybe (DeleteOrUpdate (TreeCursor a b))
treeCursorDeleteElemAndSelectPrevious g TreeCursor {..} =
    case treeAbove of
        Nothing ->
            case treeBelow of
                [] -> Just Deleted
                _ -> Nothing
        Just ta ->
            case treeAboveLefts ta of
                [] -> Nothing
                tree:xs ->
                    Just . Updated . makeTreeCursorWithAbove g tree $
                    Just
                        ta
                            { treeAboveLefts = xs
                            , treeAboveRights = treeBelow ++ treeAboveRights ta
                            }

treeCursorDeleteElemAndSelectNext ::
       (b -> a) -> TreeCursor a b -> Maybe (DeleteOrUpdate (TreeCursor a b))
treeCursorDeleteElemAndSelectNext g TreeCursor {..} =
    case treeBelow of
        [] ->
            case treeAbove of
                Nothing -> Just Deleted
                Just ta ->
                    case treeAboveRights ta of
                        [] -> Nothing
                        tree:xs ->
                            Just . Updated . makeTreeCursorWithAbove g tree $
                            Just
                                ta
                                    { treeAboveLefts =
                                          reverse treeBelow ++ treeAboveLefts ta
                                    , treeAboveRights = xs
                                    }
        (Node e ts:xs) ->
            let t = Node e $ ts ++ xs
             in Just . Updated $ makeTreeCursorWithAbove g t treeAbove

treeCursorDeleteElemAndSelectAbove ::
       (b -> a) -> TreeCursor a b -> Maybe (DeleteOrUpdate (TreeCursor a b))
treeCursorDeleteElemAndSelectAbove g TreeCursor {..} =
    case treeAbove of
        Nothing ->
            case treeBelow of
                [] -> Just Deleted
                _ -> Nothing
        Just TreeAbove {..} ->
            Just $
            Updated $
            TreeCursor
                { treeAbove = treeAboveAbove
                , treeCurrent = g treeAboveNode
                , treeBelow =
                      reverse treeAboveLefts ++ treeBelow ++ treeAboveRights
                }

treeCursorRemoveElem ::
       (b -> a) -> TreeCursor a b -> DeleteOrUpdate (TreeCursor a b)
treeCursorRemoveElem g tc =
    joinDeletes3
        (treeCursorDeleteElemAndSelectPrevious g tc)
        (treeCursorDeleteElemAndSelectNext g tc)
        (treeCursorDeleteElemAndSelectAbove g tc)

treeCursorDeleteElem ::
       (b -> a) -> TreeCursor a b -> DeleteOrUpdate (TreeCursor a b)
treeCursorDeleteElem g tc =
    joinDeletes3
        (treeCursorDeleteElemAndSelectNext g tc)
        (treeCursorDeleteElemAndSelectPrevious g tc)
        (treeCursorDeleteElemAndSelectAbove g tc)

treeCursorSwapPrev ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSwapPrev f g tc = do
    above <- treeAbove tc
    let t = currentTree f tc
    (above', t') <-
        case treeAboveLefts above of
            [] -> Nothing
            (l:ls) -> Just (above {treeAboveLefts = t : ls}, l)
    pure $ makeTreeCursorWithAbove g t' $ Just above'

treeCursorSwapNext ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorSwapNext f g tc = do
    above <- treeAbove tc
    let t = currentTree f tc
    (above', t') <-
        case treeAboveRights above of
            [] -> Nothing
            (r:rs) -> Just (above {treeAboveRights = t : rs}, r)
    pure $ makeTreeCursorWithAbove g t' $ Just above'

-- | Promotes the current node to the level of its parent.
--
-- Example:
--
-- Before:
--
-- >  p
-- >  |- a
-- >  |  |- b
-- >  |  |  |- c
-- >  |  |- d <--
-- >  |  |  |- e
-- >  |  |- f
-- >  |     |- g
-- >  |- h
--
-- After:
--
-- >  p
-- >  |- a
-- >  |  |- b
-- >  |  |  |- c
-- >  |  |  |- e
-- >  |  |- f
-- >  |     |- g
-- >  |- d <--
-- >  |- h
treeCursorPromoteElem ::
       (a -> b)
    -> (b -> a)
    -> TreeCursor a b
    -> PromoteElemResult (TreeCursor a b)
treeCursorPromoteElem f g tc = do
    ta <-
        case treeAbove tc of
            Nothing -> CannotPromoteTopElem
            Just ta -> pure ta
    -- We need to put the below under the above lefts at the end
    lefts <-
        case treeBelow tc of
            [] -> pure $ treeAboveLefts ta
            _ ->
                case treeAboveLefts ta of
                    [] -> NoSiblingsToAdoptChildren
                    (Node t ls:ts) -> pure $ Node t (ls ++ treeBelow tc) : ts
    taa <-
        case treeAboveAbove ta of
            Nothing -> NoGrandparentToPromoteElemUnder
            Just taa -> pure taa
    pure $
        makeTreeCursorWithAbove g (Node (f $ treeCurrent tc) []) $
        Just $
        taa
            { treeAboveLefts =
                  Node (treeAboveNode ta) (reverse lefts ++ treeAboveRights ta) :
                  treeAboveLefts taa
            }

data PromoteElemResult a
    = CannotPromoteTopElem
    | NoGrandparentToPromoteElemUnder
    | NoSiblingsToAdoptChildren
    | PromotedElem a
    deriving (Show, Eq, Generic, Functor)

instance Validity a => Validity (PromoteElemResult a)

instance Applicative PromoteElemResult where
    pure = PromotedElem
    CannotPromoteTopElem <*> _ = CannotPromoteTopElem
    NoGrandparentToPromoteElemUnder <*> _ = NoGrandparentToPromoteElemUnder
    NoSiblingsToAdoptChildren <*> _ = NoSiblingsToAdoptChildren
    PromotedElem f <*> PromotedElem a = PromotedElem $ f a
    PromotedElem _ <*> CannotPromoteTopElem = CannotPromoteTopElem
    PromotedElem _ <*> NoSiblingsToAdoptChildren = NoSiblingsToAdoptChildren
    PromotedElem _ <*> NoGrandparentToPromoteElemUnder =
        NoGrandparentToPromoteElemUnder

instance Monad PromoteElemResult where
    CannotPromoteTopElem >>= _ = CannotPromoteTopElem
    NoGrandparentToPromoteElemUnder >>= _ = NoGrandparentToPromoteElemUnder
    NoSiblingsToAdoptChildren >>= _ = NoSiblingsToAdoptChildren
    PromotedElem a >>= f = f a

-- | Promotes the current node to the level of its parent.
--
-- Example:
--
-- Before:
--
-- >  p
-- >  |- a
-- >  |  |- b
-- >  |  |  |- c
-- >  |  |- d <--
-- >  |  |  |- e
-- >  |  |- f
-- >  |     |- g
-- >  |- h
--
-- After:
--
-- >  p
-- >  |- a
-- >  |  |- b
-- >  |  |  |- c
-- >  |  |- f
-- >  |     |- g
-- >  |- d <--
-- >  |  |- e
-- >  |- h
treeCursorPromoteSubTree ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> PromoteResult (TreeCursor a b)
treeCursorPromoteSubTree f g tc = do
    ta <-
        case treeAbove tc of
            Nothing -> CannotPromoteTopNode
            Just ta -> pure ta
    taa <-
        case treeAboveAbove ta of
            Nothing -> NoGrandparentToPromoteUnder
            Just taa -> pure taa
    pure $
        makeTreeCursorWithAbove g (currentTree f tc) $
        Just $
        taa
            { treeAboveLefts =
                  Node
                      (treeAboveNode ta)
                      (reverse (treeAboveLefts ta) ++ treeAboveRights ta) :
                  treeAboveLefts taa
            }

data PromoteResult a
    = CannotPromoteTopNode
    | NoGrandparentToPromoteUnder
    | Promoted a
    deriving (Show, Eq, Generic, Functor)

instance Validity a => Validity (PromoteResult a)

instance Applicative PromoteResult where
    pure = Promoted
    CannotPromoteTopNode <*> _ = CannotPromoteTopNode
    NoGrandparentToPromoteUnder <*> _ = NoGrandparentToPromoteUnder
    Promoted f <*> Promoted a = Promoted $ f a
    Promoted _ <*> CannotPromoteTopNode = CannotPromoteTopNode
    Promoted _ <*> NoGrandparentToPromoteUnder = NoGrandparentToPromoteUnder

instance Monad PromoteResult where
    CannotPromoteTopNode >>= _ = CannotPromoteTopNode
    NoGrandparentToPromoteUnder >>= _ = NoGrandparentToPromoteUnder
    Promoted a >>= f = f a

-- | Demotes the current node to the level of its children.
--
-- Example:
--
-- Before:
--
-- >  p
-- >  |- a
-- >  |  |- b
-- >  |- c <--
-- >  |  |- d
-- >  |- e
--
-- After:
--
-- >  p
-- >  |- a
-- >  |  |- b
-- >  |  |- c <--
-- >  |  |- d
-- >  |- e
treeCursorDemoteElem ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> DemoteResult (TreeCursor a b)
treeCursorDemoteElem f g tc =
    case treeAbove tc of
        Nothing -> CannotDemoteTopNode
        Just ta ->
            case treeAboveLefts ta of
                [] -> NoSiblingsToDemoteUnder
                (Node t ls:ts) ->
                    Demoted $
                    makeTreeCursorWithAbove g (Node (f $ treeCurrent tc) []) $
                    Just
                        TreeAbove
                            { treeAboveLefts = reverse ls
                            , treeAboveAbove = Just ta {treeAboveLefts = ts}
                            , treeAboveNode = t
                            , treeAboveRights = treeBelow tc
                            }

-- | Demotes the current subtree to the level of its children.
--
-- Example:
--
-- Before:
--
-- >  p
-- >  |- a
-- >  |  |- b
-- >  |- c <--
-- >  |  |- d
-- >  |- e
--
-- After:
--
-- >  p
-- >  |- a
-- >  |  |- b
-- >  |  |- c <--
-- >  |     |- d
-- >  |- e
treeCursorDemoteSubTree ::
       (a -> b) -> (b -> a) -> TreeCursor a b -> DemoteResult (TreeCursor a b)
treeCursorDemoteSubTree f g tc =
    case treeAbove tc of
        Nothing -> CannotDemoteTopNode
        Just ta ->
            case treeAboveLefts ta of
                [] -> NoSiblingsToDemoteUnder
                (Node t ls:ts) ->
                    Demoted $
                    makeTreeCursorWithAbove g (currentTree f tc) $
                    Just
                        TreeAbove
                            { treeAboveLefts = reverse ls
                            , treeAboveAbove = Just ta {treeAboveLefts = ts}
                            , treeAboveNode = t
                            , treeAboveRights = []
                            }

data DemoteResult a
    = CannotDemoteTopNode
    | NoSiblingsToDemoteUnder
    | Demoted a
    deriving (Show, Eq, Generic, Functor)

instance Validity a => Validity (DemoteResult a)

-- | Demotes the current node to the level of its children, by adding two roots.
-- One for the current node and one for its children that are left behind.
--
-- Example:
--
-- Before:
--
-- >  p
-- >  |- a <--
-- >     |- b
--
-- After:
--
-- >  p
-- >  |- <given element 1>
-- >  |  |- a <--
-- >  |- <given element 2>
-- >  |  |- b
treeCursorDemoteElemUnder :: b -> b -> TreeCursor a b -> Maybe (TreeCursor a b)
treeCursorDemoteElemUnder b1 b2 tc = do
    ta <- treeAbove tc
    let ta' = ta {treeAboveRights = Node b2 (treeBelow tc) : treeAboveRights ta}
    pure
        tc
            { treeAbove =
                  Just
                      TreeAbove
                          { treeAboveLefts = []
                          , treeAboveAbove = Just ta'
                          , treeAboveNode = b1
                          , treeAboveRights = []
                          }
            , treeBelow = []
            }

-- | Demotes the current subtree to the level of its children, by adding a root.
--
-- Example:
--
-- Before:
--
-- >  a <--
-- >  |- b
--
-- After:
--
-- >  <given element>
-- >  |- a <--
-- >     |- b
treeCursorDemoteSubTreeUnder :: b -> TreeCursor a b -> TreeCursor a b
treeCursorDemoteSubTreeUnder b tc =
    tc
        { treeAbove =
              Just
                  TreeAbove
                      { treeAboveLefts = []
                      , treeAboveAbove = treeAbove tc
                      , treeAboveNode = b
                      , treeAboveRights = []
                      }
        }
