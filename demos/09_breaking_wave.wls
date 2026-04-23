#!/usr/bin/env wolframscript
(* 09_breaking_wave.wls -- a "breaking wave" built from a granular
   dam-break of cubes.  A tall rectangular column of ~250 small
   cubes sits against a back wall; the front wall is removed at
   t = 0 (heavy DynamicBody flung upward and out of the frame).
   The column collapses forward and propagates along the floor as
   a wedge whose leading edge curls -- the signature silhouette of
   a breaking water wave, reproduced in rigid-body physics. *)

Needs["ArnoudBuzing`PhysicsModelLink`"];
Get[FileNameJoin[{DirectoryName[$InputFileName], "_common.wl"}]];

CreatePhysicsModel = ArnoudBuzing`PhysicsModelLink`CreatePhysicsModel;
DynamicBody        = ArnoudBuzing`PhysicsModelLink`DynamicBody;
FixedBody          = ArnoudBuzing`PhysicsModelLink`FixedBody;
PhysicsModelEvolve = ArnoudBuzing`PhysicsModelLink`PhysicsModelEvolve;
PhysicsModelPlot   = ArnoudBuzing`PhysicsModelLink`PhysicsModelPlot;
PhysicsBoundaryBox = ArnoudBuzing`PhysicsModelLink`PhysicsBoundaryBox;

SeedRandom[9];

(* -- Geometry -- *)
cubeHalf    = 0.035;
colXHalf    = 0.25;      (* column width in x *)
colZ        = 1.20;      (* column height *)
slabY       = 0.15;
channelLen  = 3.0;

(* -- Cubes packed in a tall rectangular column behind the gate -- *)
step = 2.05 cubeHalf;
cubePos = Flatten[
  Table[{x, y, z},
    {x, -colXHalf + cubeHalf, -cubeHalf*1.5, step},    (* column is from -colXHalf to ~0 *)
    {y, -slabY + cubeHalf, slabY - cubeHalf, step},
    {z, cubeHalf + 0.01, colZ - cubeHalf, step}], 2];
Print["cubes packed: ", Length[cubePos]];

cubes = Table[
  With[{p = cubePos[[k]]},
    DynamicBody[{Hue[Mod[0.55 + 0.002 k, 1]],
      Cuboid[p - {cubeHalf, cubeHalf, cubeHalf},
             p + {cubeHalf, cubeHalf, cubeHalf}]},
      "Density" -> 1.0, "Restitution" -> 0.05, "Friction" -> 0.5]],
  {k, 1, Length[cubePos]}];

(* -- Gate: heavy DynamicBody that flies up and never returns -- *)
gateThk = 0.02;
gateH   = colZ + 0.05;
gate = DynamicBody[{RGBColor[0.4, 0.3, 0.2],
  Cuboid[{-gateThk, -slabY, 0.}, {gateThk, slabY, gateH}]},
  "Density" -> 200.0, "Restitution" -> 0.05, "Friction" -> 0.3,
  "Velocity" -> {0., 0., 40.0}];

(* -- Back wall behind the column -- *)
backWall = FixedBody[{GrayLevel[0.4],
  Cuboid[{-colXHalf - 0.04, -slabY - 0.01, 0.},
         {-colXHalf,          slabY + 0.01, gateH}]},
  "Restitution" -> 0.1, "Friction" -> 0.5];

(* -- Floor + far-right "beach" catcher -- *)
floor = FixedBody[{GrayLevel[0.92],
  Cuboid[{-colXHalf - 0.05, -slabY - 0.01, -0.05},
         { channelLen,        slabY + 0.01,  0.0}]},
  "Restitution" -> 0.05, "Friction" -> 0.7];

bbox = PhysicsBoundaryBox[{
  {-colXHalf - 0.10, -slabY - 0.02, -0.08},
  { channelLen + 0.10,  slabY + 0.02, 80.0}},
  "Thickness" -> 0.3];

model = CreatePhysicsModel[
  Join[{floor, backWall, gate}, cubes, bbox],
  "Gravity" -> {0., 0., -9.81},
  "Graphics3DOptions" -> {
    PlotRange    -> {{-colXHalf - 0.05, channelLen},
                     {-slabY - 0.05, slabY + 0.05},
                     {-0.05, colZ + 0.4}},
    Boxed        -> False, Axes -> False,
    Lighting     -> "Neutral",
    ViewPoint    -> {0.5, -22, 0.4},
    ViewVertical -> {0, 0, 1},
    Background   -> RGBColor[0.9, 0.94, 1.0]}];

Print["evolving..."];
dt      = 1/240.;
nFrames = 1500;    (* 6.25 s *)
t0      = AbsoluteTime[];
frames  = PhysicsModelEvolve[model, nFrames, dt];
Print["sim done in ", Round[AbsoluteTime[] - t0, 0.1], " s."];

outDir    = FileNameJoin[{DirectoryName[$InputFileName, 2], "output", "demos"}];
mp4Path   = FileNameJoin[{outDir, "09_breaking_wave.mp4"}];
gifPath   = FileNameJoin[{outDir, "09_breaking_wave.gif"}];
stillPath = FileNameJoin[{outDir, "09_breaking_wave_final.png"}];

GaltonBoardDemos`RenderVideo[frames, mp4Path,
  "VideoStep" -> 4, "ImageSize" -> {1200, 520}, "FrameRate" -> 30];
Print["wrote ", mp4Path];
GaltonBoardDemos`MakeGif[mp4Path, gifPath, 720, 15];
Print["wrote ", gifPath];
Export[stillPath, PhysicsModelPlot[frames[[-1]]], ImageSize -> {1200, 520}];
Print["wrote ", stillPath];
