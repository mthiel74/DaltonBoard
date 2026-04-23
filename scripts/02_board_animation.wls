#!/usr/bin/env wolframscript
(* 02_board_animation.wls -- real-physics Galton board.

   Many balls are released from a narrow "funnel" region directly above
   the top peg (x ~ uniform in [-dx/2, +dx/2], z ~ jittered stack with
   dzStack between balls, tiny random vx).  The pegs are PHYSICAL
   cylinder colliders wrapped in FixedBody — balls genuinely bounce
   off them as per Rapier's impulse-based rigid-body collisions.

   Parameters follow the Wolfram GaltonBoardModel recipe:
     - RowCount      = 18
     - PegRadius     = 0.125 m   (ball radius 0.05 m, ratio 0.4)
     - Peg spacing   = 0.5  m    (gap between peg edges = 0.25 m
                                   = 2.5 * ball diameter so ball passes
                                   easily)
     - Restitution   = 0.5   (moderate bounce)
     - Friction      = 0.3   (moderate; transfers spin)
     - Gravity       = 9.81 m/s^2
*)

Needs["ArnoudBuzing`PhysicsModelLink`"];
Get[FileNameJoin[{DirectoryName[$InputFileName], "board.wl"}]];

SeedRandom[20260423];

CreatePhysicsModel  = ArnoudBuzing`PhysicsModelLink`CreatePhysicsModel;
DynamicBody         = ArnoudBuzing`PhysicsModelLink`DynamicBody;
FixedBody           = ArnoudBuzing`PhysicsModelLink`FixedBody;
PhysicsModelEvolve  = ArnoudBuzing`PhysicsModelLink`PhysicsModelEvolve;
PhysicsModelPlot    = ArnoudBuzing`PhysicsModelLink`PhysicsModelPlot;
DestroyPhysicsModel = ArnoudBuzing`PhysicsModelLink`DestroyPhysicsModel;

(* -- Parameters -- *)
nBalls    = 120;
dzStack   = 0.18;      (* ~= 2 * ball diameter so stacked balls don't overlap *)
dt        = 1/240.;    (* fine dt to avoid tunneling at the tight peg gaps *)
nFrames   = 3600;      (* 15 s of physics *)
videoStep = 8;         (* keep every 8th frame for MP4 (450 frames / 15s @ 30fps) *)
xSpread   = GaltonBoard`$PegDx / 2;   (* release range: ~one dx-wide funnel *)

(* -- Balls: release positions form a narrow column just above the top peg.
   Stagger them vertically so they enter sequentially rather than piling
   on top of one another.  Small random vx breaks any residual symmetry. -- *)
balls = Table[
  GaltonBoard`MakeBall[
    {RandomReal[{-xSpread, xSpread}],
     GaltonBoard`$BoardTopZ + 1.0 + k*dzStack},
    {RandomReal[{-0.15, 0.15}], 0.},
    Hue[Mod[k*0.09, 1]]],
  {k, 0, nBalls - 1}];

(* -- Static bodies: pegs are REAL colliders. -- *)
pegs  = GaltonBoard`PegList[];
bins  = GaltonBoard`BinSeparators[];
floor = FixedBody[{GrayLevel[0.85],
          Cuboid[{-GaltonBoard`$BoardHalfWidth, -GaltonBoard`$SlabHalfY,
                  GaltonBoard`$BoardBottomZ},
                 { GaltonBoard`$BoardHalfWidth,  GaltonBoard`$SlabHalfY,
                  GaltonBoard`$BoardBottomZ + 0.12}]},
          "Restitution" -> 0.1, "Friction" -> 0.8];

stackTop = GaltonBoard`$BoardTopZ + 1.0 + (nBalls - 1)*dzStack + 0.5;
walls    = GaltonBoard`BoundaryWalls[stackTop];

model = CreatePhysicsModel[
  Join[balls, pegs, bins, {floor}, walls],
  "Gravity" -> {0., 0., -9.81},
  "Graphics3DOptions" -> {
    (* Crop view to the peg + bin region so the tall initial ball-stack
       sits above the visible frame and balls cascade into view. *)
    PlotRange    -> {{-GaltonBoard`$BoardHalfWidth, GaltonBoard`$BoardHalfWidth},
                     {-0.6, 0.6},
                     {GaltonBoard`$BoardBottomZ - 0.15,
                      GaltonBoard`$BoardTopZ + 1.8}},
    Boxed        -> False,
    Axes         -> False,
    Lighting     -> "Neutral",
    ViewPoint    -> {0, -20, 0},
    ViewVertical -> {0, 0, 1},
    Background   -> RGBColor[0.97, 0.97, 1.0]}];

Print["model: ", nBalls, " balls + ", Length[pegs], " pegs (",
      GaltonBoard`$PegRows, " rows) + ", Length[bins], " bin separators + floor + 6 walls."];
Print["  peg radius / ball radius = ",
      GaltonBoard`$PegRadius / GaltonBoard`$BallRadius];
Print["  peg-edge gap / ball diameter = ",
      (GaltonBoard`$PegDx - 2*GaltonBoard`$PegRadius) / (2*GaltonBoard`$BallRadius)];

Print["evolving ", nFrames, " frames @ dt=", 1.0*dt, " s (total ", nFrames*dt, "s)..."];
t0     = AbsoluteTime[];
frames = PhysicsModelEvolve[model, nFrames, dt];
Print["sim done in ", Round[AbsoluteTime[] - t0, 0.1], " s."];

videoFrames = frames[[;; ;; videoStep]];
Print["rendering ", Length[videoFrames], " video frames..."];
renderedImages = Table[
  Rasterize[PhysicsModelPlot[f], ImageSize -> {720, 1080}, Background -> White],
  {f, videoFrames}];

videoPath = FileNameJoin[{DirectoryName[$InputFileName, 2], "output", "02_board_animation.mp4"}];
Export[videoPath, renderedImages, "MP4", "FrameRate" -> 30];
Print["wrote ", videoPath];

stillPath = FileNameJoin[{DirectoryName[$InputFileName, 2], "output", "02_board_final.png"}];
Export[stillPath, PhysicsModelPlot[frames[[-1]]], ImageSize -> {900, 1350}];
Print["wrote ", stillPath];

(* Inspect final bin distribution *)
dynBodies = Select[frames[[-1]][[1]]["Bodies"], #["BodyType"] === "Dynamic" &];
finalXs   = #["Position"][[1]] & /@ dynBodies;
finalZs   = #["Position"][[3]] & /@ dynBodies;
settled   = Pick[finalXs, # < GaltonBoard`$BinTopZ & /@ finalZs];
Print["settled balls: ", Length[settled], " / ", Length[dynBodies]];
If[Length[settled] > 0,
  binsCount = Table[
    Count[GaltonBoard`BinIndex /@ settled, b], {b, 1, GaltonBoard`$PegRows + 1}];
  Print["bin counts: ", binsCount];
  (* Scaled Binomial(18, 1/2) reference *)
  refPMF = Table[Binomial[GaltonBoard`$PegRows, k]/2.^GaltonBoard`$PegRows,
                  {k, 0, GaltonBoard`$PegRows}];
  Print["Binomial(", GaltonBoard`$PegRows, ", 1/2)*n expected: ",
        NumberForm[#, {5, 1}] & /@ (refPMF * Length[settled])]];

DestroyPhysicsModel[model];
Print["done."];
