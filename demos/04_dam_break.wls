#!/usr/bin/env wolframscript
(* 04_dam_break.wls -- granular dam break.

   ~600 small spheres are pre-packed behind a vertical "gate" wall.
   At t = 0 the gate is given a large upward velocity and flies
   straight up out of the way, releasing the grains. They flow down
   the channel in a proper granular front, splash at the leading
   edge, and gradually settle. *)

Needs["ArnoudBuzing`PhysicsModelLink`"];
Get[FileNameJoin[{DirectoryName[$InputFileName], "_common.wl"}]];

CreatePhysicsModel = ArnoudBuzing`PhysicsModelLink`CreatePhysicsModel;
DynamicBody        = ArnoudBuzing`PhysicsModelLink`DynamicBody;
FixedBody          = ArnoudBuzing`PhysicsModelLink`FixedBody;
PhysicsModelEvolve = ArnoudBuzing`PhysicsModelLink`PhysicsModelEvolve;
PhysicsModelPlot   = ArnoudBuzing`PhysicsModelLink`PhysicsModelPlot;
PhysicsBoundaryBox = ArnoudBuzing`PhysicsModelLink`PhysicsBoundaryBox;

SeedRandom[4];

(* -- Geometry -- *)
ballR      = 0.022;
containerW = 0.6;     (* x width of the grains (x from -containerW to 0) *)
slabHalfY  = 0.05;
containerH = 0.50;    (* max fill height of grains *)
channelLen = 1.80;    (* x from 0 to channelLen downstream *)

(* -- Grain positions: tightly packed rectangular region behind the gate -- *)
step = 2.05 ballR;
grainPos = Flatten[
  Table[{x, 0., z},
    {x, -containerW + ballR, -1.5 ballR, step},
    {z, ballR + 0.01, containerH - ballR, step}], 1];
Print["grains placed: ", Length[grainPos]];

grains = DynamicBody[
  {Hue[Mod[0.3 #[[1]] + 0.8 #[[3]], 1]], Sphere[#, ballR]},
  "Density"     -> 1.0,
  "Restitution" -> 0.15,
  "Friction"    -> 0.6] & /@ grainPos;

(* -- Gate: a DynamicBody with high mass, flies up at t = 0 -- *)
gateThk = 0.015;
gateZ0  = 0.0;
gateZ1  = containerH + 0.05;
gate = DynamicBody[{RGBColor[0.4, 0.3, 0.2],
  Cuboid[{-gateThk, -slabHalfY, gateZ0},
         { gateThk,  slabHalfY, gateZ1}]},
  "Density"     -> 200.0,    (* heavier so grain pressure can't deflect it *)
  "Restitution" -> 0.1,
  "Friction"    -> 0.4,
  "Velocity"    -> {0., 0., 35.0}];   (* fast up -- doesn't return inside the sim *)

(* -- Floor (extends from left container to right channel) -- *)
floor = FixedBody[{GrayLevel[0.92],
  Cuboid[{-containerW - 0.05, -slabHalfY - 0.01, -0.05},
         { channelLen,          slabHalfY + 0.01,  0.0}]},
  "Restitution" -> 0.05, "Friction" -> 0.8];

(* -- Back wall -- *)
backWall = FixedBody[{GrayLevel[0.4],
  Cuboid[{-containerW - gateThk, -slabHalfY - 0.01, 0.},
         {-containerW + 0.,        slabHalfY + 0.01, containerH + 0.1}]},
  "Restitution" -> 0.1, "Friction" -> 0.6];

(* -- Bounding box -- ceiling far up so the gate can fly out of sight
   and not bounce back down into the flow during the sim window. *)
bbox = PhysicsBoundaryBox[{
  {-containerW - 0.10, -slabHalfY - 0.02, -0.08},
  { channelLen + 0.10,  slabHalfY + 0.02, 80.0}},
  "Thickness" -> 0.3];

model = CreatePhysicsModel[
  Join[{floor, backWall, gate}, grains, bbox],
  "Gravity" -> {0., 0., -9.81},
  "Graphics3DOptions" -> {
    PlotRange    -> {{-containerW - 0.05, channelLen + 0.05},
                     {-slabHalfY - 0.05, slabHalfY + 0.05},
                     {-0.05, containerH + 0.3}},
    Boxed        -> False, Axes -> False,
    Lighting     -> "Neutral",
    ViewPoint    -> {0, -22, 0.3},
    ViewVertical -> {0, 0, 1},
    Background   -> RGBColor[0.97, 0.97, 1.0]}];

Print["evolving..."];
dt      = 1/240.;
(* 5 s only -- gate flies to z > 60 m and doesn't come back; all grains
   are well downstream by then. *)
nFrames = 1200;
t0      = AbsoluteTime[];
frames  = PhysicsModelEvolve[model, nFrames, dt];
Print["sim done in ", Round[AbsoluteTime[] - t0, 0.1], " s."];

outDir    = FileNameJoin[{DirectoryName[$InputFileName, 2], "output", "demos"}];
mp4Path   = FileNameJoin[{outDir, "04_dam_break.mp4"}];
gifPath   = FileNameJoin[{outDir, "04_dam_break.gif"}];
stillPath = FileNameJoin[{outDir, "04_dam_break_final.png"}];

GaltonBoardDemos`RenderVideo[frames, mp4Path,
  "VideoStep" -> 10, "ImageSize" -> {1200, 500}, "FrameRate" -> 30];
Print["wrote ", mp4Path];
GaltonBoardDemos`MakeGif[mp4Path, gifPath, 720, 15];
Print["wrote ", gifPath];
Export[stillPath, PhysicsModelPlot[frames[[-1]]], ImageSize -> {1200, 500}];
Print["wrote ", stillPath];
