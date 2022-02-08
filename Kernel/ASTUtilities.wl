(* ::**********************************************************************:: *)
(* ::Section::Closed:: *)
(*Package Header*)
BeginPackage[ "Wolfram`PacletCICD`" ];

ASTPattern // ClearAll;
FromAST // ClearAll;

Begin[ "`Private`" ];

Needs[ "CodeParser`" ];

(* ::**********************************************************************:: *)
(* ::Section::Closed:: *)
(*FromAST*)
FromAST[ ast_ ] := FromAST[ ast, ##1 & ];

FromAST[ ast: _LeafNode|_CallNode, wrapper_ ] :=
    ToExpression[ ToFullFormString @ ast, InputForm, wrapper ];

FromAST[ ContainerNode[ _, ast_List, _ ], wrapper_ ] :=
    FromAST[ ast, wrapper ];

FromAST[ ast_List, wrapper_ ] := FromAST[ #, wrapper ] & /@ ast;

FromAST // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Section::Closed:: *)
(*ASTPattern*)
ASTPattern // Attributes = { HoldFirst };

ASTPattern[ patt_ ] := catchTop @ astPattern @ patt;
ASTPattern[ patt_, meta_ ] := catchTop @ astPattern[ patt, meta ];

ASTPattern // catchUndefined;


astPattern // Attributes = { HoldAllComplete };
$astPattern // Attributes = { HoldAllComplete };

astPattern[ patt_ ] /; ! FreeQ[ Unevaluated @ patt, _ASTPattern ] :=
    Module[ { held, expanded, new },
        held     = HoldComplete @ patt;
        expanded = expandNestedASTPatterns @ held;
        new      = astPattern @@ expanded;
        new /. $astPattern[ a_ ] :> a
    ];

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Pattern*)
astPattern[ Verbatim[ Pattern ][ sym_Symbol? symbolQ, patt_ ] ] :=
    Pattern @@ Hold[ sym, astPattern @ patt ];

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Special patterns*)
astPattern[ patt_ASTPattern  ] := patt;
astPattern[ patt_$astPattern ] := patt;

astPattern[ Verbatim[ Verbatim     ][ a___ ] ] := a;
astPattern[ Verbatim[ HoldPattern  ][ a_   ] ] := astPattern @ a;
astPattern[ Verbatim[ Alternatives ][ a___ ] ] :=
    Alternatives @@ (astPattern /@ HoldComplete @ a);

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Blanks*)
astPattern[ Verbatim[ _   ] ] := callOrLeafNode[ ];
astPattern[ Verbatim[ __  ] ] := callOrLeafNode[ ]..;
astPattern[ Verbatim[ ___ ] ] := callOrLeafNode[ ]...;

astPattern[ Verbatim[ Blank             ][ sym_? symbolQ ] ] := blank @ sym;
astPattern[ Verbatim[ BlankSequence     ][ sym_? symbolQ ] ] := blank @ sym..;
astPattern[ Verbatim[ BlankNullSequence ][ sym_? symbolQ ] ] := blank @ sym...;

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*blank*)
blank // Attributes = { HoldAllComplete };
blank[ sym_? leafHeadQ ] := leafNode @ sym | callNode @ symNamePatt @ sym;
blank[ sym_ ] := callNode @ symNamePatt @ sym;
blank // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*leafNode*)
leafNode[            ] := LeafNode[ _, _, _ ];
leafNode[ a_         ] := LeafNode[ a, _, _ ];
leafNode[ a_, b_     ] := LeafNode[ a, b, _ ];
leafNode[ a_, b_, c_ ] := LeafNode[ a, b, c ];

leafNode // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*callNode*)
callNode[            ] := CallNode[ _, _, _ ];
callNode[ a_         ] := CallNode[ a, _, _ ];
callNode[ a_, b_     ] := CallNode[ a, b, _ ];
callNode[ a_, b_, c_ ] := CallNode[ a, b, c ];

callNode // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*callOrLeafNode*)
callOrLeafNode[            ] := (CallNode|LeafNode)[ _, _, _ ];
callOrLeafNode[ a_         ] := (CallNode|LeafNode)[ a, _, _ ];
callOrLeafNode[ a_, b_     ] := (CallNode|LeafNode)[ a, b, _ ];
callOrLeafNode[ a_, b_, c_ ] := (CallNode|LeafNode)[ a, b, c ];

callOrLeafNode // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*leafHeadQ*)
leafHeadQ // Attributes = { HoldAllComplete };
leafHeadQ[ Complex|Integer|Rational|Real|String|Symbol ] := True;
leafHeadQ[ ___ ] := False;

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Repeated*)
astPattern[ Verbatim[ Repeated ][ x_, a___ ] ] :=
    Repeated[ astPattern @ x, a ];

astPattern[ Verbatim[ RepeatedNull ][ x_, a___ ] ] :=
    RepeatedNull[ astPattern @ x, a ];

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*PatternTest*)
astPattern[ Verbatim[ PatternTest ][
    Verbatim[ Pattern ][ s_Symbol? symbolQ, patt_ ],
    test_
] ] :=
    With[ { p = astPattern @ PatternTest[ patt, test ] },
        Pattern @@ HoldComplete[ s, p ]
    ];

astPattern[
    Verbatim[ PatternTest ][
        Verbatim[ Blank ][ head_? symbolQ ],
        test_
    ] ] /; leafTestQ[ head, test ] :=
    leafNode @ head;

astPattern[
    Verbatim[ PatternTest ][
        Verbatim[ BlankSequence ][ head_? symbolQ ],
        test_
    ]
] /; leafTestQ[ head, test ] :=
    leafNode @ head..;

astPattern[
    Verbatim[ PatternTest ][
        Verbatim[ BlankNullSequence ][ head_? symbolQ ],
        test_
    ]
] /; leafTestQ[ head, test ] :=
    leafNode @ head...;

astPattern[ Verbatim[ PatternTest ][ patt_, test_ ] ] :=
    With[ { p = astPattern @ patt },
        Apply[
            PatternTest,
            HoldComplete[
                p,
                FromAST[ #, test ] &
            ]
        ]
    ];

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*leafTestQ*)
leafTestQ // Attributes = { HoldAllComplete };

leafTestQ[ Integer, IntegerQ     ] := True;
leafTestQ[ Real, Developer`RealQ ] := True;
leafTestQ[ String, StringQ       ] := True;
leafTestQ[ _? leafHeadQ, AtomQ   ] := True;
leafTestQ[ ___                   ] := False;

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Atoms*)
astPattern[ sym_Symbol? symbolQ ] := symNamePatt @ sym;
astPattern[ r_Rational ] /; AtomQ @ Unevaluated @ r := rationalPattern @ r;
astPattern[ c_Complex  ] /; AtomQ @ Unevaluated @ c := complexPattern  @ c;

astPattern[ expr: _Integer|_Real|_String ] /; AtomQ @ Unevaluated @ expr :=
    leafNode[ Head @ expr, ToString[ expr, InputForm ] ];

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*rationalPattern*)
rationalPattern[ r_ ] := rationalPattern[ Numerator @ r, Denominator @ r ];

rationalPattern[ n_, d_ ] :=
    Module[ { na, da, mo, pw },
        na = astPattern @ n;
        da = astPattern @ d;
        mo = leafNode[ Integer, "-1" ];
        pw = callNode[ symbolNode[ "Power" ], { da, mo } ];
        callNode[ symbolNode[ "Times" ], { na, pw } ]
    ];

rationalPattern // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*complexPattern*)
complexPattern[ c_ ] := complexPattern[ Re @ c, Im @ c ];

complexPattern[ r_, i_ ] :=
    Module[ { ra, ia, im },
        ra = astPattern @ r;
        ia = astPattern @ i;
        im = callNode[ symbolNode[ "Times" ], { ia, symbolNode[ "I" ] } ];
        callNode[ symbolNode[ "Plus" ], { ra, im } ]
    ];

complexPattern // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Condition*)
astPattern[ Verbatim[ Condition ][ patt_, test_ ] ] :=
    astConditionPattern[ astPattern @ patt, test ];

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*astConditionPattern*)
astConditionPattern // Attributes = { HoldRest };

astConditionPattern[ lhs_, rhs_ ] :=
    With[ { rules = rhsConditionRules @ lhs },
        Condition @@ HoldComplete[ lhs, Unevaluated @ rhs /. rules ]
    ];

astConditionPattern // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*rhsConditionRules*)
rhsConditionRules[ lhs_ ] :=
    Cases[ HoldComplete @ lhs,
           Verbatim[ Pattern ][ s_Symbol? symbolQ, _ ] :>
               HoldPattern @ s :>
                   RuleCondition[ FromAST[ s, $ConditionHold ], True ],
           Infinity,
           Heads -> True
    ];

rhsConditionRules // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Normal expressions*)
astPattern[ head_[ args___ ] ] :=
    CallNode[ astPattern @ head, astPattern /@ Unevaluated @ { args }, _ ];

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Two argument form*)
astPattern[ patt_, meta_ ] := insertMetaPatt[ astPattern @ patt, meta ];

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*insertMetaPatt*)
insertMetaPatt[ (h: CallNode|LeafNode)[ a_, b_, _ ], meta_ ] :=
    h[ a, b, meta ];

insertMetaPatt[ (h: Verbatim[ CallNode|LeafNode ])[ a_, b_, _ ], meta_ ] :=
    h[ a, b, meta ];

insertMetaPatt[ Verbatim[ Pattern ][ s_, p_ ], meta_ ] :=
    With[ { ins = insertMetaPatt[ p, meta ] },
        Pattern @@ Hold[ s, ins ]
    ];

insertMetaPatt[ patt_Alternatives, meta_ ] :=
    insertMetaPatt[ #1, meta ] & /@ patt;

insertMetaPatt[ Verbatim[ Condition ][ lhs_, rhs_ ], meta_ ] :=
    With[ { ins = insertMetaPatt[ lhs, meta ] },
        Condition @@ Hold[ ins, rhs ]
    ];

insertMetaPatt // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Undefined*)
astPattern // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Section::Closed:: *)
(*Misc Utilities*)

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*symbolNode*)
symbolNode[ name_String ] := LeafNode[ Symbol, name, _ ];
symbolNode[ sym_Symbol  ] := symNamePatt @ sym;
symbolNode // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*symNamePatt*)
symNamePatt // Attributes = { HoldAllComplete };

symNamePatt[ sym_Symbol? symbolQ ] :=
    With[
        {
            name = SymbolName @ Unevaluated @ sym,
            ctx  = Context @ Unevaluated @ sym
        },
        LeafNode[ Symbol, name | ctx <> name, _ ]
    ];

symNamePatt // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*expandNestedASTPatterns*)
expandNestedASTPatterns[ expr_ ] :=
    ReplaceAll[
        expr,
        HoldPattern @ ASTPattern[ a___ ] :>
            With[ { p = astPattern @ a }, $astPattern @ p /; True ]
    ];

expandNestedASTPatterns // catchUndefined;

(* ::**********************************************************************:: *)
(* ::Section::Closed:: *)
(*Package Footer*)
End[ ];
EndPackage[ ];