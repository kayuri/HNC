
import CPP.CompileTools
import HN.Optimizer.ArgumentValues
import HN.Optimizer.GraphCompiler
import HN.Optimizer.Visualise
import FFI.TypeParser
import Compiler.Hoopl

main = do
	ast <- parseHN "hn_tests/print15.hn"
	ffi <- importHni "lib/lib.hni"
	putStrLn $ foo $ run avPass $ fst $ compileGraph ffi $ head ast

run pass graph = case runSimpleUniqueMonad . runWithFuel infiniteFuel $
	analyzeAndRewriteFwd pass entry graph $
	mkFactBase (fp_lattice pass) [(runSimpleUniqueMonad freshLabel, fact_bot $ fp_lattice pass)] of
	(_, newFacts, _) -> newFacts

	
entry = JustC [runSimpleUniqueMonad freshLabel]
