{-# LANGUAGE GADTs #-}
module HN.Optimizer.ArgumentDeleter (runF) where

import Compiler.Hoopl
import Safe.Exact

import HN.Optimizer.ArgumentValues
import HN.Optimizer.ClassyLattice (dataflowLattice)
import HN.Optimizer.ExpressionRewriter
import HN.Optimizer.Node
import HN.Optimizer.Pass
import HN.Optimizer.Utils

cp :: DefinitionNode -> AFType -> Maybe DefinitionNode
cp ArgNode (_, PElem x) = Just $ LetNode [] x
cp ArgNode (_, Bot) = Nothing
cp ArgNode _ = error "ooo"
cp (LetNode [] _) _ = Nothing
cp (LetNode l x) (PElem f, _) = (\l -> LetNode l x) <$> rewriteFormalArgs f l
cp _ _ = Nothing

rewriteFormalArgs :: [WithTopAndBot ExpressionFix] -> Rewrite [Label] 
rewriteFormalArgs actualArgs formalArgs
	= map fst <$> process foo (zipExactNote "Wrong formalArgs during rewrite" formalArgs actualArgs)
	where
		foo ((_, PElem _) : tail) = Just tail
		foo _ = Nothing

passF :: FwdPass SimpleFuelMonad Node ArgFact
passF = FwdPass 
	{ fp_lattice = dataflowLattice
	, fp_transfer = noTransferMapF
	, fp_rewrite = pureFRewrite $ rewriteExitF $ \n f -> cp n $ fst f
	}

runF :: Pass ArgFact ArgFact
runF = runPass (analyzeAndRewriteFwd passF) const 


