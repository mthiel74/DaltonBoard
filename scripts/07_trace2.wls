#!/usr/bin/env wolframscript
(* 07_trace2.wls -- trace a single ball dropped with ZERO x-offset and
   print its (x,z) at each peg-row crossing. If the ball enters the peg
   cascade through the apex, successive x-values should alternate sign
   as it ricochets left-right-left-right. *)

Needs["ArnoudBuzing`PhysicsModelLink`"];
Get[FileNameJoin[{DirectoryName[$InputFileName], "board.wl"}]];

CreatePhysicsModel    = ArnoudBuzing`PhysicsModelLink`CreatePhysicsModel;
FixedBody             = ArnoudBuzing`PhysicsModelLink`FixedBody;
PhysicsModelIterate   = ArnoudBuzing`PhysicsModelLink`PhysicsModelIterate;
DestroyPhysicsModel   = ArnoudBuzing`PhysicsModelLink`DestroyPhysicsModel;
RapierSetBodyVelocity = ArnoudBuzing`PhysicsModelLink`RapierSetBodyVelocity;

SeedRandom[1];
x0 = RandomReal[{-0.001, 0.001}];
Print["x0 = ", x0];

ball = GaltonBoard`MakeBall[
         {x0, GaltonBoard`$BoardTopZ + 0.4},
         {RandomReal[{-0.05, 0.05}], 0.},
         RGBColor[0.8, 0.2, 0.2]];
pegs  = GaltonBoard`PegList[0.02];  (* modest jitter *)
bins  = GaltonBoard`BinSeparators[];
floor = FixedBody[{GrayLevel[0.85],
          Cuboid[{-GaltonBoard`$BoardHalfWidth, -GaltonBoard`$SlabHalfY,
                  GaltonBoard`$BoardBottomZ},
                 { GaltonBoard`$BoardHalfWidth,  GaltonBoard`$SlabHalfY,
                  GaltonBoard`$BoardBottomZ + 0.12}]}];
walls = GaltonBoard`BoundaryWalls[GaltonBoard`$BoardTopZ + 2.5];

model   = CreatePhysicsModel[Join[{ball}, pegs, bins, {floor}, walls],
            "Gravity" -> {0., 0., -9.81}];
worldId = model[[1]]["WorldID"];
bodyId  = model[[1]]["Bodies"][[1]]["Handle"];

dt = 1/240.;
current = model;
prevPos = current[[1]]["Bodies"][[1]]["Position"];
reportedRows = 0;
Do[
  current = PhysicsModelIterate[current, 4, dt];
  pos = current[[1]]["Bodies"][[1]]["Position"];
  vel = (pos - prevPos)/(4*dt);
  RapierSetBodyVelocity[worldId, bodyId, vel * 0.97];  (* drag *)
  prevPos = pos;
  While[reportedRows < GaltonBoard`$PegRows &&
        pos[[3]] < -reportedRows * GaltonBoard`$PegDz + 0.02,
    Print["  row ", reportedRows, "  x=", NumberForm[pos[[1]], {7, 4}],
          "  z=", NumberForm[pos[[3]], {7, 4}],
          "  vx=", NumberForm[vel[[1]], {6, 3}],
          "  vz=", NumberForm[vel[[3]], {6, 3}]];
    reportedRows++
  ];
  If[pos[[3]] < GaltonBoard`$BinTopZ - 0.2, Break[]],
  {step, 1, 3000}];

Print["\nfinal x=", pos[[1]], " bin=", GaltonBoard`BinIndex[pos[[1]]]];
DestroyPhysicsModel[model];
