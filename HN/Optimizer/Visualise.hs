{-# LANGUAGE FlexibleContexts, GADTs, Rank2Types, ScopedTypeVariables, LambdaCase, NoMonomorphismRestriction #-}
module HN.Optimizer.Visualise (foo, formatGraph) where
import Compiler.Hoopl
import Data.Functor.Foldable
import HN.Optimizer.Node (Node(..), DefinitionNode(..))
import HN.Intermediate (ExpressionF(..))
import Utils

instance Show (Node e x) where
	show (Entry l) = show l
	show (Exit dn) = show dn

instance Show DefinitionNode where
	show = \case
		LetNode l e -> case l of
		 	[] -> " = " ++ show e
			_ -> " " ++ concatMap (\l -> show l ++ " ") l ++ "= " ++ show e
		ArgNode -> " :: @"
		LibNode -> " :: #"

instance (Show a, Show b) => Show (ExpressionF a b) where
	show = \case
		ConstantF c -> show c
		AtomF aa -> show aa
		ApplicationF a b -> show a ++ concatMap (\b -> ' ' : show b) b

formatGraph :: Graph Node C C -> String
formatGraph = showGraph2 show

type Showing2 n = forall e x . n e x -> String

showGraph2 :: forall n e x . Showing2 n -> Graph n e x -> String
showGraph2 node = g where
	g :: Graph n e x -> String
	g = \case
		GNil        -> ""
		GUnit block -> b block
		GMany g_entry g_blocks g_exit ->
			open b g_entry ++ body g_blocks ++ open b g_exit
	body blocks = concatMap b (mapElems blocks)
	b :: forall e x . Block n e x -> String
	b = \case
		BlockCO l b1   -> node l ++ "\n" ++ b b1
		BlockCC l b1 n -> node l ++ b b1 ++ node n ++ "\n"
		BlockOC   b1 n -> b b1 ++ node n ++ "\n"
		BNil           -> ""
		BMiddle n      -> node n ++ "\n"
		BCat b1 b2     -> b b1   ++ b b2
		BSnoc b1 n     -> b b1   ++ node n ++ "\n"

open :: (a -> String) -> MaybeO z a -> String
open _ NothingO  = ""
open p (JustO n) = p n
		
foo = concatMap ff . mapToList where
	ff (l, x) = show l ++ " => " ++ case x of
		Top -> "T\n"
		Bot -> "⊥\n"
		PElem x -> concatMap bar x ++ "\n"

bar = \case
	Top -> "T\n"
	Bot -> "⊥\n"
	PElem x -> cata phi x ++ " "

phi = \case
	AtomF x -> show x
	ConstantF x -> show x
	ApplicationF a b -> "(" ++ a ++ " " ++ joinStr " " b ++ ")"
