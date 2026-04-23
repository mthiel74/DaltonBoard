#!/usr/bin/env wolframscript
(* 06_tune.wls -- quick parameter-sweep harness: run N independent one-ball
   trials with full physics (real pegs, no impulse) plus linear velocity
   damping (mimicking air resistance since Rapier doesn't have it built-in)
   and report the bin distribution. *)

Needs["ArnoudBuzing`PhysicsModelLink`"];
Get[FileNameJoin[{DirectoryName[$InputFileName], "board.wl"}]];

CreatePhysicsModel    = ArnoudBuzing`PhysicsModelLink`CreatePhysicsModel;
DynamicBody           = ArnoudBuzing`PhysicsModelLink`DynamicBody;
FixedBody             = ArnoudBuzing`PhysicsModelLink`FixedBody;
PhysicsModelIterate   = ArnoudBuzing`PhysicsModelLink`PhysicsModelIterate;
DestroyPhysicsModel   = ArnoudBuzing`PhysicsModelLink`DestroyPhysicsModel;
RapierSetBodyVelocity = ArnoudBuzing`PhysicsModelLink`RapierSetBodyVelocity;

(* Tunable parameters (override via env var) *)
getParam[name_String, default_] :=
  With[{e = Environment[name]},
    If[StringQ[e] && StringLength[e] > 0, ToExpression[e], default]];

nTrials = getParam["N_TRIALS", 80];
gravity  = getParam["GRAV", 9.81];
damping  = getParam["DAMP", 0.985];       (* velocity kept per-step: 1 = no drag *)
dampEvery = getParam["DAMP_EVERY", 4];    (* apply damping every N timesteps *)
dt       = 1 / 240.;
maxSteps = 6000;

Print["params: gravity=", gravity, "  damping=", damping,
      "/", dampEvery, " steps  nTrials=", nTrials];

pegJitter = getParam["JITTER", 0.0];
binSep    = GaltonBoard`BinSeparators[];
floor = FixedBody[{GrayLevel[0.85],
           Cuboid[{-GaltonBoard`$BoardHalfWidth, -GaltonBoard`$SlabHalfY,
                   GaltonBoard`$BoardBottomZ},
                  { GaltonBoard`$BoardHalfWidth,  GaltonBoard`$SlabHalfY,
                   GaltonBoard`$BoardBottomZ + 0.12}]},
           "Restitution" -> 0.1, "Friction" -> 0.8];
walls = GaltonBoard`BoundaryWalls[GaltonBoard`$BoardTopZ + 2.5];

runOne[seed_Integer] := Module[
  {ballX0, ball, pegs, model, worldId, bodyId, current, prevPos, curPos, vel, nsteps, pos},
  SeedRandom[seed];
  pegs   = GaltonBoard`PegList[pegJitter];
  ballX0 = RandomReal[{-0.05, 0.05}];
  ball = GaltonBoard`MakeBall[{ballX0, GaltonBoard`$BoardTopZ + 0.5}, {0., 0.},
            RGBColor[0.9, 0.25, 0.25]];
  model = CreatePhysicsModel[
    Join[{ball}, pegs, binSep, {floor}, walls],
    "Gravity" -> {0., 0., -gravity}];
  worldId = model[[1]]["WorldID"];
  bodyId  = model[[1]]["Bodies"][[1]]["Handle"];
  current = model;
  nsteps  = 0;
  prevPos = current[[1]]["Bodies"][[1]]["Position"];
  While[nsteps < maxSteps,
    current = PhysicsModelIterate[current, dampEvery, dt];
    nsteps += dampEvery;
    curPos = current[[1]]["Bodies"][[1]]["Position"];
    vel    = (curPos - prevPos) / (dampEvery * dt);
    RapierSetBodyVelocity[worldId, bodyId, vel * damping];
    prevPos = curPos;
    If[curPos[[3]] < GaltonBoard`$BinTopZ - 1.0 && nsteps > 300, Break[]]
  ];
  pos = current[[1]]["Bodies"][[1]]["Position"];
  DestroyPhysicsModel[model];
  GaltonBoard`BinIndex[pos[[1]]]];

t0 = AbsoluteTime[];
bins = Table[runOne[k], {k, 1, nTrials}];
Print["done in ", Round[AbsoluteTime[] - t0, 0.1], " s."];
binCounts = Table[Count[bins, b], {b, 1, GaltonBoard`$PegRows + 1}];
Print["bin counts: ", binCounts];

(* Theoretical Binomial(N, 1/2) *)
N0  = GaltonBoard`$PegRows;
exp = nTrials * Table[Binomial[N0, k]/2.^N0, {k, 0, N0}];
Print["expected:   ", NumberForm[#, {4, 1}] & /@ exp];
