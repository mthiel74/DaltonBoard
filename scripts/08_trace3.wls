#!/usr/bin/env wolframscript
(* Trace a single ball falling through the peg array with NO damping, printing
   its z every 0.25 s to see how fast it actually cascades. *)

Needs["ArnoudBuzing`PhysicsModelLink`"];
Get[FileNameJoin[{DirectoryName[$InputFileName], "board.wl"}]];

CreatePhysicsModel  = ArnoudBuzing`PhysicsModelLink`CreatePhysicsModel;
FixedBody           = ArnoudBuzing`PhysicsModelLink`FixedBody;
PhysicsModelIterate = ArnoudBuzing`PhysicsModelLink`PhysicsModelIterate;
DestroyPhysicsModel = ArnoudBuzing`PhysicsModelLink`DestroyPhysicsModel;

SeedRandom[42];

ball = GaltonBoard`MakeBall[{0.01, GaltonBoard`$BoardTopZ + 0.4}, {0., 0.},
          RGBColor[0.85, 0.2, 0.2]];
pegs  = GaltonBoard`PegList[0.02];
bins  = GaltonBoard`BinSeparators[];
floor = FixedBody[{GrayLevel[0.85],
          Cuboid[{-GaltonBoard`$BoardHalfWidth, -GaltonBoard`$SlabHalfY,
                  GaltonBoard`$BoardBottomZ},
                 { GaltonBoard`$BoardHalfWidth,  GaltonBoard`$SlabHalfY,
                  GaltonBoard`$BoardBottomZ + 0.12}]}];
walls = GaltonBoard`BoundaryWalls[GaltonBoard`$BoardTopZ + 2.5];

model = CreatePhysicsModel[Join[{ball}, pegs, bins, {floor}, walls],
          "Gravity" -> {0., 0., -9.81}];
dt = 1/240.;
current = model;
Do[
  current = PhysicsModelIterate[current, 60, dt];
  pos = current[[1]]["Bodies"][[1]]["Position"];
  Print["t=", NumberForm[t*60*dt, {4, 2}],
        "s  x=", NumberForm[pos[[1]], {6, 3}],
        "  z=", NumberForm[pos[[3]], {6, 3}]];
  If[pos[[3]] < GaltonBoard`$BinTopZ - 0.2, Break[]],
  {t, 1, 100}];

DestroyPhysicsModel[model];
