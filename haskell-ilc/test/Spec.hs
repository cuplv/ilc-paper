module Main where

import Text.Printf
import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.Hspec
import Test.Tasty.QuickCheck as QC
import Test.Tasty.SmallCheck as SC

import Syntax
import Parser

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Tests" [parserTests]

parserTests :: TestTree
parserTests =
    testGroup "Parser tests" $ makeParserTests

makeParserTests = map f parserExamples
  where f test = case test of
            (str, src, ast) -> testCase (printf "parse %s" str) $
                                 assertEqual "" (parser src) (ast)
                           
parserExamples =
    [ ( "lambda"
      , "lam x . x + x"
      , Right [ CExpr (ELam (EVar "x")
                            (EPlus (EVar "x")
                                   (EVar "x")))
              ]
      )
    , ( "allocate channel then write"
      , "nu c . wr 1 -> c"
      , Right [ CExpr (ENu (EVar "c")
                           (EWr (EInt 1)
                                (EVar "c")))
              ]
      )
    , ( "let binding"
      , "let x = 100 in x * 1"
      , Right [ CExpr (ELet (PVar "x")
                            (EInt 100)
                            (ETimes (EVar "x")
                                     (EInt 1)))
              ]
      )
    , ( "let binding w/ tuple matching"
      , "let (x, y) = (1, 2) in x + y"
      , Right [ CExpr (ELet (PTuple [PVar "x", PVar "y"])
                            (ETuple [EInt 1, EInt 2])
                            (EPlus (EVar "x")
                                   (EVar "y")))
              ]
      )
    , ( "let binding w/ unit and function application"
      , "let () = \"whatever\" in double 2"
      , Right [ CExpr (ELet (PUnit)
                            (EString "whatever")
                            (EApp (EVar "double")
                                  (EInt 2)))
              ]
      )
    , ( "sequencing let bindings"
      , "let x = 1 in x; let y = 1 in y"
      , Right [ CExpr (ELet (PVar "x")
                            (EInt 1)
                            (ESeq (EVar "x")
                                  (ELet (PVar "y")
                                        (EInt 1)
                                        (EVar "y"))))
              ]
      )
    , ( "nested let bindings"
      , "let x = 1 in let y = 2 in x + y"
      , Right [ CExpr (ELet (PVar "x")
                            (EInt 1)
                            (ELet (PVar "y")
                                  (EInt 2)
                                  (EPlus (EVar "x")
                                         (EVar "y"))))
              ]
      )
    , ( "let commands"
      , "let x = 1 let y = 2 let z = x + y"
      , Right [ CDef (PVar "x")
                     (EInt 1)
              , CDef (PVar "y")
                     (EInt 2)
              , CDef (PVar "z")
                     (EPlus (EVar "x")
                            (EVar "y"))
              ]
      )
    , ( "let command, let binding, expr command"
      , "let _ = let x = 1 in 2 * x let y = 1;; \"foo\""
      , Right [ CDef (PWildcard)
                     (ELet (PVar "x")
                           (EInt 1)
                           (ETimes (EInt 2)
                                   (EVar "x")))
              , CDef (PVar "y")
                     (EInt 1)
              , CExpr (EString "foo")
              ]
      )
    , ( "expr commands and sequencing"
      , "1 ; 2 ;; 3 ; 4"
      , Right [ CExpr (ESeq (EInt 1)
                            (EInt 2))
              , CExpr (ESeq (EInt 3)
                            (EInt 4))
              ]
      )
    , ( "pattern matching"
      , "match b with | 0 => \"zero\" | 1 => \"one\""
      , Right [ CExpr (EMatch (EVar "b")
                              ([ (PInt 0, EBool True, EString "zero")
                               , (PInt 1, EBool True, EString "one")
                               ]))
              ]
      )
    , ( "let binding w/ assign"
      , "let x = 1 ; let y := 1 in x + y"
      , Right [ CExpr (ELet (PVar "x")
                            (ESeq (EInt 1)
                                  (EAssign (PVar "y")
                                           (EInt 1)))
                            (EPlus (EVar "x")
                                   (EVar "y")))
              ]
      )
    , ( "ref and deref"
      , "let a = ref 1 ;; let b := @ a"
      , Right [ CDef (PVar "a")
                     (ERef (EInt 1))
              , CExpr (EAssign (PVar "b")
                               (EDeref (EVar "a")))
              ]
      )
    , ( "let binding w/ sequencing and assign"
      , "let a = 1 ; let b := 1 in b"
      , Right [ CExpr (ELet (PVar "a")
                            (ESeq (EInt 1)
                                  (EAssign (PVar "b")
                                           (EInt 1)))
                            (EVar "b"))
              ]
      )
    , ( "cons pattern matching"
      , "match a with | [] => 0 | x:xs => 1"
      , Right [ CExpr (EMatch (EVar "a")
                              ([ (PList [], EBool True, EInt 0)
                               , (PCons (PVar "x")
                                        (PVar "xs"), EBool True, EInt 1)
                               ]))
              ]
      )
    , ( "pattern matching with guards"
      , "match b with | 0 when 0 < 1 => 0 | 1 when true => 1"
      , Right [ CExpr (EMatch (EVar "b")
                              ([ (PInt 0, ELt (EInt 0)
                                              (EInt 1), EInt 0)
                               , (PInt 1, EBool True, EInt 1)
                               ]))
              ]
      )
    ]