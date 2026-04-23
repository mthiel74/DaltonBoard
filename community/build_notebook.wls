#!/usr/bin/env wolframscript
(* Build community/galton_board.nb -- a Wolfram Notebook suitable for
   posting to the Wolfram Community as a reply to Arnoud Buzing's
   PhysicsModelLink announcement.

   The notebook embeds the 600-ball cascade animation (via
   AnimatedImage so the GIF survives the Community HTML pre-render and
   plays inline in the browser), the histogram-vs-Binomial overlay, and
   the key source snippets. Also exports a PDF for offline review. *)

hereDir = DirectoryName[If[$ScriptCommandLine =!= {}, $InputFileName,
                           NotebookFileName[]]];
outDir  = FileNameJoin[{hereDir, "..", "output"}];
scrDir  = FileNameJoin[{hereDir, "..", "scripts"}];

imgWidth = 640;
gifWidth = 420;   (* narrower: the animation is a tall portrait frame *)

loadPng[name_] := With[{p = FileNameJoin[{outDir, name}]},
  If[FileExistsQ[p],
    Image[Import[p], ImageSize -> imgWidth],
    Style["[missing image: " <> name <> "]", Red]]];

(* AnimatedImage, not ListAnimate / Manipulate -- the Wolfram Community
   viewer preserves AnimatedImage as an <img> tag that loops in the
   browser; ListAnimate is replaced by a static screenshot. *)
loadAnim[name_, maxFrames_: 80, rate_: 20] :=
  With[{p = FileNameJoin[{outDir, name}]},
    If[!FileExistsQ[p],
      Style["[missing " <> name <> "]", Red],
      With[{all = Import[p, {"GIF", "ImageList"}]},
        With[{stride = Max[1, Ceiling[Length[all]/maxFrames]]},
          AnimatedImage[
            ImageResize[#, {gifWidth}] & /@ all[[1 ;; -1 ;; stride]],
            FrameRate -> rate,
            AnimationRunning -> True,
            AnimationRepetitions -> Infinity]]]]];

(* Read a code snippet from the scripts/ folder as a formatted Input-
   cell string. *)
readSnippet[name_, startLine_: 1, endLine_: All] :=
  With[{txt = Import[FileNameJoin[{scrDir, name}], "Text"]},
    With[{lines = StringSplit[txt, "\n"]},
      StringRiffle[
        If[endLine === All,
          lines[[startLine ;;]],
          lines[[startLine ;; Min[endLine, Length[lines]]]]], "\n"]]];

codeCell[str_String] := Cell[str, "Input",
  ShowCellLabel -> False,
  CellLabelAutoDelete -> False,
  CellTags -> {"ShownInPost"}];

imgCell[img_, caption_String: ""] := Cell[
  BoxData[ToBoxes[
    If[caption === "",
      img,
      Column[{img,
        Pane[Style[caption, Italic, FontSize -> 10,
                   FontFamily -> "Helvetica"],
             imgWidth, Alignment -> Center]},
        Alignment -> Center, Spacings -> 0.6]]]],
  "Output", ShowCellLabel -> False,
  CellMargins -> {{0, 0}, {10, 14}}];

(* ------------------------------------------------------------------ *)

anim    = loadAnim["02_board_animation.gif", 80, 20];
histImg = loadPng["03_histogram_overlay.png"];
finalImg= loadPng["02_board_final.png"];

cells = {

 Cell["PhysicsModelLink in action: a Galton board, cascaded by Claude",
      "Title"],

 Cell[TextData[{
   "A reply to Arnoud Buzing's ",
   ButtonBox["PhysicsModelLink",
     BaseStyle -> "Hyperlink",
     ButtonData -> {URL["https://community.wolfram.com/groups/-/m/t/3701211"], None}],
   " announcement \[LongDash] what happened when I pointed Claude at the paclet."}],
   "Subtitle", TextAlignment -> Center],

 Cell[TextData[{"Marco Thiel, April 2026 \[LongDash] ",
    ButtonBox["github.com/mthiel74/GaltonBoard",
      BaseStyle -> "Hyperlink",
      ButtonData -> {URL["https://github.com/mthiel74/GaltonBoard"], None}]}],
      "Text", TextAlignment -> Center, FontSlant -> Italic],

 (* ---------- Animation first ---------- *)
 Cell["The result", "Section"],
 Cell[TextData[{"Six hundred balls, dropped one after another into a \
narrow funnel above a 31\[Times]18 alternating-offset peg array. Each \
ball bounces off real ",
   StyleBox["Cylinder", "Input"], " pegs (wrapped as ",
   StyleBox["FixedBody", "Input"],
   ") under gravity, settles into one of 33 bins, and the pile in \
those bins forms the expected bell curve:"}],
   "Text"],

 imgCell[anim,
   "600 balls cascading through an 18-row Galton board. Real Rapier \
rigid-body collisions throughout; no virtual impulses."],

 Cell[TextData[{"The complementary statistical view \[LongDash] 600 \
independent single-ball simulations, final bin index compared against \
Binomial(18, 1/2) and the Normal approximation predicted by \
the central-limit theorem:"}],
   "Text"],

 imgCell[histImg,
   "Empirical bin counts (blue bars) overlaid with the Binomial(18, 1/2) \
PMF (green dots) and the matching Normal PDF (red dashed)."],

 (* ---------- How it came about ---------- *)
 Cell["How this came about", "Section"],

 Cell[TextData[{"Arnoud's original post ends with an observation about \
LLMs lowering the cost of writing boilerplate wrapper code. I wanted to \
test a closely-related idea: ",
   StyleBox["can you ", Italic],
   StyleBox["point", {Italic, Bold}],
   StyleBox[" a coding agent at a paclet and have it build a new \
project on top of that paclet?", Italic],
   " I opened an empty GitHub folder and typed the following \
one-liner into Claude Code:"}], "Text"],

 Cell["\"Hi, this is an empty repo (please make an online one for \
this). I would like you to use wolframscript to make a Dalton Board \
(i.e. balls 'running over' pegs to give the Normal distribution \
based on this paclet https://www.wolframcloud.com/obj/arnoudbuzing/\
DeployedResources/Paclet/ArnoudBuzing/PhysicsModelLink/. Commit and \
push regularly.\"", "Code", FontFamily -> "Courier"],

 Cell[TextData[{"(\"Dalton\" was a typo; it is a ",
   StyleBox["Galton", Italic],
   " board. I caught that a bit later and had Claude rename the repo, \
the package context and every reference in one go.) Claude followed \
the URL, ran ",
   StyleBox["PacletInstall[ResourceObject[\"...\"]]", "Input"],
   ", read the ",
   StyleBox["PhysicsModelLink.wl", "Input"],
   " source to learn the ",
   StyleBox["CreatePhysicsModel / DynamicBody / FixedBody / \
PhysicsModelEvolve / PhysicsModelVideo", "Input"],
   " API, and pushed a first working single-ball prototype within a \
few minutes. Between that prototype and the animation above were \
several iterations \[LongDash] not about writing new code, but about \
choosing geometry and parameters that actually produce the Binomial \
distribution:"}], "Text"],

 Cell[TextData[{
   "\[FilledSmallSquare]  A \"triangular\" peg layout was eliminated \
because balls slid down the ",
   StyleBox["outside", Italic],
   " of the triangle and collected in the edge bins. A rectangular, \
alternating-offset lattice fixed that.\n",
   "\[FilledSmallSquare]  The same-row peg-edge gap must be greater \
than the ball diameter (we ended up at 0.17 m vs 0.15 m), otherwise \
balls wedge.\n",
   "\[FilledSmallSquare]  The outermost peg-to-wall gap has to satisfy \
the same constraint (fix: fewer pegs per row on the outside, walls \
further out).\n",
   "\[FilledSmallSquare]  Rapier puts a body to sleep when its motion \
is very small; a ball that balances exactly on a peg top then sits \
there forever. A tiny per-step linear-velocity refresh (damping 0.99 \
every 4 physics steps) keeps the bodies awake and also approximates \
air drag.\n",
   "\[FilledSmallSquare]  Per-trial peg-x jitter (~0.004 m) is \
the only non-deterministic ingredient; gravity, collisions and \
bounces are all real rigid-body physics.\n",
   "\[FilledSmallSquare]  Pegs have to extend beyond the Binomial's \
5\[Sigma] range or residual chaos bunches balls in the extreme bins \
(we ended up with 31 columns over 25 bins of Binomial width)."
   }], "Text", CellMargins -> {{40, 0}, {6, 6}}],

 Cell[TextData[{"Every one of these changes was ",
   StyleBox["my ", Italic],
   "physical observation ",
   StyleBox["(\"some pegs are horizontally closer than others \
\[LongDash] balls wedge there\", \"the balls slide along the outer \
edge of the triangle\", \"the outermost peg-to-wall gap is too \
small\"", Italic],
   "...) typed as a short sentence. Claude did the tuning and rebuilt \
the notebook. The total turn-around from observation to new render \
was a few minutes each time."}], "Text"],

 (* ---------- The physics layer ---------- *)
 Cell["The physics layer", "Section"],
 Cell[TextData[{"The whole board geometry lives in a tiny shared \
package, ",
   StyleBox["GaltonBoard`", "Input"],
   ", in ",
   ButtonBox["scripts/board.wl",
     BaseStyle -> "Hyperlink",
     ButtonData -> {URL["https://github.com/mthiel74/GaltonBoard/blob/main/scripts/board.wl"], None}],
   ".  The parameters that ended up producing the bell curve are:"}],
   "Text"],

 codeCell["$PegRows    = 18;
$PegCols    = 31;                 (* 31 pegs in even rows, 30 in odd *)
$PegRadius  = 0.035;
$BallRadius = 0.075;              (* ball diameter 0.15 m *)
$PegDx      = 0.24;               (* same-row peg-edge gap = 0.17 m > ball dia *)
$PegDz      = 0.21;
$NBins      = 33;                 (* > Binomial 5-sigma range *)
$SlabHalfY  = 0.13;"],

 Cell[TextData[{"Pegs are constructed with ",
   StyleBox["FixedBody[{color, Cylinder[...]}, \"Restitution\" -> 0.5, \
\"Friction\" -> 0.0]", "Input"],
   " \[LongDash] zero friction so a ball that happens to balance on a \
peg top slides off rather than being grabbed by static friction."}],
   "Text"],

 codeCell[readSnippet["board.wl", 49, 74]],

 (* ---------- Dropping the balls ---------- *)
 Cell["Dropping the balls", "Section"],

 Cell[TextData[{"The animation script drops ",
   StyleBox["nBalls = 600", "Input"],
   " balls \[LongDash] stacked vertically above the board with 0.5 m \
between them so each ball's arrival at the top peg is staggered by \
~0.03 s. The only 'non-physical' ingredient is a gentle \
per-step velocity refresh that prevents Rapier's body-sleep mechanism \
from freezing balls on peg tops:"}], "Text"],

 codeCell["current  = model;
prevPoss = Table[current[[1]][\"Bodies\"][[k]][\"Position\"], {k, 1, nBalls}];
frames   = Reap[
  Do[
    current = PhysicsModelIterate[current, 1, dt];
    If[Mod[step, dampEvery] == 0,
      Do[Module[{curPos, vel},
          curPos = current[[1]][\"Bodies\"][[b]][\"Position\"];
          vel    = (curPos - prevPoss[[b]]) / (dampEvery * dt);
          RapierSetBodyVelocity[worldId, ballHandles[[b]], vel * damping];
          prevPoss[[b]] = curPos],
        {b, 1, nBalls}]];
    Sow[current],
    {step, 1, nFrames}]][[2, 1]];"],

 Cell[TextData[{"Everything else \[LongDash] gravity (",
   StyleBox["{0, 0, -9.81}", "Input"],
   "), ball\[Dash]peg collisions, ball\[Dash]ball collisions, ball\
\[Dash]wall collisions, energy loss through restitution \[LongDash] \
is native Rapier."}], "Text"],

 (* ---------- Independent-trial histogram ---------- *)
 Cell["Independent-trial statistics", "Section"],
 Cell[TextData[{"To decouple the distribution from any ball-ball \
interactions, a second script ",
   ButtonBox["(scripts/03_histogram.wls)",
     BaseStyle -> "Hyperlink",
     ButtonData -> {URL["https://github.com/mthiel74/GaltonBoard/blob/main/scripts/03_histogram.wls"], None}],
   " runs ",
   StyleBox["N = 600", "Input"],
   " independent single-ball simulations and records the final bin. \
The loop is simply ",
   StyleBox["CreatePhysicsModel \[Rule] PhysicsModelIterate loop \
\[Rule] BinIndex[finalX] \[Rule] DestroyPhysicsModel", "Input"],
   ". That yields the blue bars in the overlay figure near the top of \
this post, tracking Binomial(18, 1/2) and the Normal PDF \
closely."}], "Text"],

 imgCell[loadPng["02_board_final.png"],
   "Final frame of the animation \[LongDash] the pile of 600 settled \
balls, one colour per ball, showing the bell curve built out of \
actual rigid bodies."],

 (* ---------- Lessons ---------- *)
 Cell["What I take from this", "Section"],

 Cell[TextData[{
   "1. ",
   StyleBox["A paclet is now a pointer.", Bold],
   " The entire project started from a URL. Claude installed the \
paclet, read its source, used its high-level ",
   StyleBox["CreatePhysicsModel / PhysicsModelEvolve", "Input"],
   " API, and turned out a working simulation without me writing a \
line of code. That is the same shape of interaction Arnoud describes \
for LLM-assisted LibraryLink work, scaled up one level: instead of \
pointing the LLM at a C header, I point it at a whole paclet.\n\n",
   "2. ",
   StyleBox["The hard part stayed hard \[LongDash] physically \
correctly parameterising a Galton board.", Bold],
   " Running the simulation was instant. Getting it to actually \
produce the Binomial(18, 1/2) took six rounds of iteration, \
and all six were driven by ",
   StyleBox["my", Italic],
   " physical intuition (\"look, balls are wedging between pegs \
there\"). Claude could see the distribution counts and the image but \
could not, without being told, reason about the 5 mm of peg-edge \
clearance or the Rapier body-sleep heuristic. Collaborators, not \
replacements.\n\n",
   "3. ",
   StyleBox["Wolfram Community embedding works.", Bold],
   " The animation above is an ",
   StyleBox["AnimatedImage", "Input"],
   " constructed from frames of ",
   StyleBox["output/02_board_animation.gif", "Input"],
   ". Community's HTML renderer serialises it as a plain looping \
",
   StyleBox["<img>", "Input"],
   " (the trick I learned from ",
   ButtonBox["Marco's TrafficJAms post",
     BaseStyle -> "Hyperlink",
     ButtonData -> {URL["https://community.wolfram.com/groups/-/m/t/3701293"], None}],
   ")."}],
 "Text"],

 Cell[TextData[{"The whole project \[LongDash] seven evolutionary \
scripts, the Rapier parameterisation, 600 trials of single-ball \
statistics, the video, the GIF, the histogram \[LongDash] sits at ",
   ButtonBox["github.com/mthiel74/GaltonBoard",
     BaseStyle -> "Hyperlink",
     ButtonData -> {URL["https://github.com/mthiel74/GaltonBoard"], None}],
   ". Feedback and further parameter tweaks welcome."}], "Text"],

 Cell["Thanks Arnoud \[LongDash] the paclet is delightful to work with.",
   "Text", TextAlignment -> Right, FontSlant -> Italic]
};

(* ---------- Write the notebook ---------- *)
nb = Notebook[cells,
  StyleDefinitions -> "Default.nb",
  WindowSize -> {900, All},
  ShowSelection -> True];

outNb = FileNameJoin[{hereDir, "galton_board.nb"}];
Export[outNb, nb];
Print["wrote ", outNb];

(* PDF for offline review -- needs the front end *)
outPdf = FileNameJoin[{hereDir, "galton_board.pdf"}];
UsingFrontEnd[
  nbObj = NotebookOpen[outNb, Visible -> False];
  Export[outPdf, nbObj];
  NotebookClose[nbObj]];
Print["wrote ", outPdf];
