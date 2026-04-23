#!/usr/bin/env wolframscript
(* 03_domino_cascade.wls -- chain reaction of dominoes laid out around
   a full circle.  Constant radius -> constant tangent-rotation per
   step -> chain reaction propagates cleanly all the way round.  A
   heavy ball is fired at the first domino to trigger it. *)

Needs["ArnoudBuzing`PhysicsModelLink`"];
Get[FileNameJoin[{DirectoryName[$InputFileName], "_common.wl"}]];

CreatePhysicsModel = ArnoudBuzing`PhysicsModelLink`CreatePhysicsModel;
DynamicBody        = ArnoudBuzing`PhysicsModelLink`DynamicBody;
FixedBody          = ArnoudBuzing`PhysicsModelLink`FixedBody;
PhysicsModelEvolve = ArnoudBuzing`PhysicsModelLink`PhysicsModelEvolve;
PhysicsModelPlot   = ArnoudBuzing`PhysicsModelLink`PhysicsModelPlot;
PhysicsBoundaryBox = ArnoudBuzing`PhysicsModelLink`PhysicsBoundaryBox;

SeedRandom[3];

(* -- Domino dimensions (m) -- *)
dThk  = 0.012;
dWid  = 0.06;
dTal  = 0.14;

(* -- Circle layout: a FULL ring of dominoes, plus a short straight
   tail so the last domino tips onto the first again (the user sees
   the wave come back home to the start). *)
rCircle  = 0.80;
spacing  = 0.075;        (* arc-length between domino centres *)
nDom     = Floor[2 Pi rCircle / spacing];
Print["Dominos placed: ", nDom];

pts = Table[
  With[{theta = 2 Pi k / nDom},
    {rCircle Cos[theta], rCircle Sin[theta]}],
  {k, 0, nDom - 1}];

tangentAt[i_] := Module[{theta = 2 Pi (i - 1) / nDom},
  {-Sin[theta], Cos[theta]}];

makeDomino[i_, color_] := Module[
  {cx, cy, cz, t, tx, ty, rotMat},
  {cx, cy} = pts[[i]];
  cz = dTal;
  {tx, ty} = tangentAt[i];
  rotMat = Transpose[{{tx, ty, 0}, {-ty, tx, 0}, {0, 0, 1}}];
  DynamicBody[{color,
    Cuboid[{cx - dThk, cy - dWid, cz - dTal},
           {cx + dThk, cy + dWid, cz + dTal}]},
    "Density"     -> 1.0,
    "Restitution" -> 0.02,
    "Friction"    -> 0.8,
    "Orientation" -> rotMat]];

dominoes = Table[makeDomino[i,
    Hue[Mod[i / nDom, 1]]], {i, 1, nDom}];

(* -- Projectile smashes domino 1 from behind -- *)
{firstCx, firstCy} = pts[[1]];
{tx0, ty0}         = tangentAt[1];
projSpawn  = {firstCx - 0.30 tx0, firstCy - 0.30 ty0, 1.3 dTal};
projectile = DynamicBody[
  {RGBColor[0.85, 0.1, 0.1], Sphere[projSpawn, 0.045]},
  "Density"     -> 12.0,
  "Restitution" -> 0.02,
  "Friction"    -> 0.5,
  "Velocity"    -> {6.0 tx0, 6.0 ty0, 0.}];

(* -- Floor -- *)
floorHalf = rCircle + 0.35;
floor = FixedBody[{GrayLevel[0.92],
  Cuboid[{-floorHalf, -floorHalf, -0.05},
         { floorHalf,  floorHalf,  0.0}]},
  "Restitution" -> 0.02, "Friction" -> 0.9];
bbox = PhysicsBoundaryBox[{
  {-floorHalf - 0.05, -floorHalf - 0.05, -0.08},
  { floorHalf + 0.05,  floorHalf + 0.05, 1.50}},
  "Thickness" -> 0.2];

model = CreatePhysicsModel[
  Join[{floor, projectile}, dominoes, bbox],
  "Gravity" -> {0., 0., -9.81},
  "Graphics3DOptions" -> {
    PlotRange    -> {{-floorHalf, floorHalf},
                     {-floorHalf, floorHalf},
                     {-0.02, 0.5}},
    Boxed        -> False, Axes -> False,
    Lighting     -> "Neutral",
    ViewPoint    -> {0.2, -1.8, 1.9},
    ViewVertical -> {0, 0, 1},
    Background   -> RGBColor[0.97, 0.97, 1.0]}];

Print["evolving..."];
dt      = 1/240.;
nFrames = 3600;    (* 15 s -- full lap *)
t0      = AbsoluteTime[];
frames  = PhysicsModelEvolve[model, nFrames, dt];
Print["sim done in ", Round[AbsoluteTime[] - t0, 0.1], " s."];

outDir    = FileNameJoin[{DirectoryName[$InputFileName, 2], "output", "demos"}];
mp4Path   = FileNameJoin[{outDir, "03_domino_cascade.mp4"}];
gifPath   = FileNameJoin[{outDir, "03_domino_cascade.gif"}];
stillPath = FileNameJoin[{outDir, "03_domino_cascade_final.png"}];

GaltonBoardDemos`RenderVideo[frames, mp4Path,
  "VideoStep" -> 9, "ImageSize" -> {900, 700}, "FrameRate" -> 30];
Print["wrote ", mp4Path];
GaltonBoardDemos`MakeGif[mp4Path, gifPath, 540, 15];
Print["wrote ", gifPath];
Export[stillPath, PhysicsModelPlot[frames[[-1]]], ImageSize -> {900, 700}];
Print["wrote ", stillPath];
