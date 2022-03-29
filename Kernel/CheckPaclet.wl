(* ::**********************************************************************:: *)
(* ::Section::Closed:: *)
(*Package Header*)
BeginPackage[ "Wolfram`PacletCICD`" ];

CheckPaclet // ClearAll;

Begin[ "`Private`" ];

$ContextAliases[ "dnc`"  ] = "DefinitionNotebookClient`";

(* ::**********************************************************************:: *)
(* ::Section::Closed:: *)
(*CheckPaclet*)
CheckPaclet::invfile =
"`1` is not a valid definition notebook file or directory.";

CheckPaclet::invfmt =
"`1` is not a valid format specification.";

CheckPaclet::errors =
"Errors encountered while checking paclet.";

CheckPaclet::undefined =
"Unhandled arguments for `1` in `2`.";

CheckPaclet::unknown =
"An unexpected error occurred.";

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Options*)
CheckPaclet // Options = {
    "Target"           -> "Submit",
    "DisabledHints"    -> Automatic,
    "FailureCondition" -> "Error"
};

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Argument patterns*)
$$hintProp   = _String | All | Automatic | { ___String };
$$cpFMTName  = "JSON"|"Dataset"|Automatic|None;
$$cpFMT      = $$cpFMTName | { $$cpFMTName, $$hintProp };

$$cpOpts = OptionsPattern @ {
               CheckPaclet,
               dnc`CheckDefinitionNotebook
           };

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Main definition*)
CheckPaclet[ opts: $$cpOpts ] :=
    catchTop @ CheckPaclet[ File @ Directory[ ], opts ];

CheckPaclet[ dir_File? DirectoryQ, opts: $$cpOpts ] :=
    catchTop @ CheckPaclet[ findDefinitionNotebook @ dir, opts ];

CheckPaclet[ file_File, opts: $$cpOpts ] :=
    catchTop @ CheckPaclet[ file, Automatic, opts ];

CheckPaclet[ file_File? defNBQ, fmt: $$cpFMT, opts: $$cpOpts ] :=
    catchTop @ checkPaclet[
        file,
        "DisabledHints" -> toDisabledHints @ OptionValue[ "DisabledHints" ],
        takeCheckDefNBOpts @ opts,
        "ConsoleType"      -> Automatic,
        "ClickedButton"    -> OptionValue[ "Target" ],
        "Format"           -> toCheckFormat @ fmt,
        "FailureCondition" -> OptionValue[ "FailureCondition" ]
    ];

(* TODO: save as JSON to build dir so it gets included in build artifacts *)

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Error cases*)

(* Invalid file specification: *)
e: CheckPaclet[ file: Except[ _File? defNBQ ], ___ ] :=
    throwMessageFailure[ CheckPaclet::invfile, file, HoldForm @ e ];

(* Invalid format specification: *)
e: CheckPaclet[ file_File? defNBQ, fmt: Except[ $$cpFMT ], ___ ] :=
    throwMessageFailure[ CheckPaclet::invfmt, fmt, HoldForm @ e ];

(* Invalid options specification: *)
e: CheckPaclet[
    file_File? defNBQ,
    fmt: $$cpFMT,
    a: OptionsPattern[ ],
    inv: Except[ OptionsPattern[ ] ],
    ___
] :=
    throwMessageFailure[
        CheckPaclet::nonopt,
        HoldForm @ inv,
        2 + Length @ HoldComplete @ a,
        HoldForm @ e
    ];

(* Unexpected arguments: *)
e: CheckPaclet[ ___ ] :=
    throwMessageFailure[ CheckPaclet::undefined, CheckPaclet, HoldForm @ e ];

(* ::**********************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Dependencies*)

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*checkPaclet*)
checkPaclet[ nb_, opts___ ] := (
    Needs[ "DefinitionNotebookClient`" -> None ];
    ccPromptFix @ checkExit @ dnc`CheckDefinitionNotebook[ nb, opts ]
);

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*checkExit*)
checkExit[ Failure[ "FailureCondition", as_Association ] ] :=
    exitFailure[
        "CheckPaclet::errors",
        Association[
            "MessageTemplate"   :> CheckPaclet::errors,
            "MessageParameters" :> { },
            KeyTake[ as, { "FailureCondition", "Result" } ]
        ],
        1
    ];

checkExit[ res_? FailureQ ] :=
    exitFailure[ CheckPaclet::unknown, 1, res ];

checkExit[ result_ ] := result;

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*takeCheckDefNBOpts*)
takeCheckDefNBOpts[ opts: $$cpOpts ] := (
    Needs[ "DefinitionNotebookClient`" -> None ];
    filterOptions[ dnc`CheckDefinitionNotebook, opts ]
);

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*toDisabledHints*)
toDisabledHints[ Automatic|Inherited ] := (
    Needs[ "DefinitionNotebookClient`" -> None ];
    toDisabledHints @ {
        dnc`$DisabledHints,
        "PacletRequiresBuild",
        "PacletFileChanged",
        "PacletFilesChanged"
    }
);

toDisabledHints[ tag_String ] :=
    Map[ <| "MessageTag" -> tag, "Level" -> #1, "ID" -> All |> &,
         { "Suggestion", "Warning", "Error" }
    ];

toDisabledHints[ as: KeyValuePattern[ "MessageTag" -> _ ] ] :=
    { as };

toDisabledHints[ as: KeyValuePattern[ "Tag" -> tag_ ] ] :=
    { Append[ as, "MessageTag" -> tag ] };

toDisabledHints[ hints_List ] :=
    DeleteDuplicates @ Flatten[ toDisabledHints /@ hints ];

toDisabledHints[ ___ ] := { };

(* ::**********************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*toCheckFormat*)
toCheckFormat[ None             ] := None;
toCheckFormat[ fmt: $$cpFMTName ] := { fmt, $defaultHintProps };
toCheckFormat[ fmt_             ] := fmt;

$defaultHintProps = { "Level", "Message", "Tag", "CellID" };

(* ::**********************************************************************:: *)
(* ::Subsubsubsection::Closed:: *)
(*disableTag*)
disableTag[ tag_ ] :=
    Map[ <| "MessageTag" -> tag, "Level" -> #1, "ID" -> All |> &,
         { "Suggestion", "Warning", "Error" }
    ];

(* ::**********************************************************************:: *)
(* ::Section::Closed:: *)
(*Package Footer*)
End[ ];
EndPackage[ ];