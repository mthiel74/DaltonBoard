#!/usr/bin/env wolframscript
(* 03_histogram.wls -- REAL-PHYSICS statistical characterisation of the
   Galton board.  Each trial runs an independent single-ball Rapier
   simulation with:
     - rectangular alternating-offset peg array (physical cylinder
       colliders wrapped in FixedBody),
     - per-trial small random peg-x jitter (the only source of
       stochasticity in an otherwise deterministic rigid-body engine),
     - linear velocity damping every few physics steps to mimic air
       drag (Rapier has no built-in drag),
     - ball genuinely bouncing off every peg it contacts.
   The empirical distribution of final bin indices is compared against
   Binomial(N, 1/2) and the Normal approximation predicted by the
   Central Limit Theorem. *)

Needs["ArnoudBuzing`PhysicsModelLink`"];
Get[FileNameJoin[{DirectoryName[$InputFileName], "board.wl"}]];

CreatePhysicsModel    = ArnoudBuzing`PhysicsModelLink`CreatePhysicsModel;
DynamicBody           = ArnoudBuzing`PhysicsModelLink`DynamicBody;
FixedBody             = ArnoudBuzing`PhysicsModelLink`FixedBody;
PhysicsModelIterate   = ArnoudBuzing`PhysicsModelLink`PhysicsModelIterate;
DestroyPhysicsModel   = ArnoudBuzing`PhysicsModelLink`DestroyPhysicsModel;
RapierSetBodyVelocity = ArnoudBuzing`PhysicsModelLink`RapierSetBodyVelocity;

SeedRandom[20260424];

getParam[name_String, default_] :=
  With[{e = Environment[name]},
    If[StringQ[e] && StringLength[e] > 0, ToExpression[e], default]];

nTrials   = getParam["GBOARD_TRIALS", 400];
gravity   = getParam["GRAV",   9.81];
damping   = getParam["DAMP",   0.99];
dampEvery = getParam["DAMP_EVERY", 4];
pegJitter = getParam["JITTER", 0.025];
dt        = 1/240.;
maxSteps  = 1800;

Print["running ", nTrials, " real-physics trials (g=", gravity,
      "; drag=", damping, "/", dampEvery, "steps; peg jitter=", pegJitter, "m)"];

binSep = GaltonBoard`BinSeparators[];
floor  = FixedBody[{GrayLevel[0.85],
           Cuboid[{-GaltonBoard`$BoardHalfWidth, -GaltonBoard`$SlabHalfY,
                   GaltonBoard`$BoardBottomZ},
                  { GaltonBoard`$BoardHalfWidth,  GaltonBoard`$SlabHalfY,
                   GaltonBoard`$BoardBottomZ + 0.12}]},
           "Restitution" -> 0.1, "Friction" -> 0.9];
walls  = GaltonBoard`BoundaryWalls[GaltonBoard`$BoardTopZ + 2.5];

runOne[seed_Integer] := Module[
  {ballX0, pegs, ball, model, worldId, bodyId, current, prevPos, curPos, vel, nsteps, pos},
  SeedRandom[seed];
  pegs   = GaltonBoard`PegList[pegJitter];
  ballX0 = RandomReal[{-0.02, 0.02}];
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
    If[curPos[[3]] < -GaltonBoard`$PegRows*GaltonBoard`$PegDz - 0.8, Break[]]
  ];
  pos = current[[1]]["Bodies"][[1]]["Position"];
  DestroyPhysicsModel[model];
  <|"Seed" -> seed, "FinalX" -> pos[[1]], "FinalZ" -> pos[[3]],
    "Bin" -> GaltonBoard`BinIndex[pos[[1]]], "Steps" -> nsteps|>];

t0 = AbsoluteTime[];
results = Table[
  If[Mod[k, 25] == 0, Print["  trial ", k, " / ", nTrials,
                            "  (elapsed ", Round[AbsoluteTime[] - t0, 0.1], " s)"]];
  runOne[k],
  {k, 1, nTrials}];
Print["all ", nTrials, " trials done in ", Round[AbsoluteTime[] - t0, 0.1], " s."];

nBins = GaltonBoard`$PegRows + 1;
bins  = Table[Count[results, KeyValuePattern["Bin" -> b]], {b, 1, nBins}];
Print["empirical bin counts: ", bins];

N0       = GaltonBoard`$PegRows;
binomPMF = Table[Binomial[N0, k]/2.^N0, {k, 0, N0}];
binomExp = binomPMF * nTrials;
Print["binomial(", N0, ", 1/2)*n: ", NumberForm[#, {5, 1}] & /@ binomExp];

chi2   = Total[MapThread[If[#2 >= 5, (#1 - #2)^2/#2, 0] &, {bins, binomExp}]];
dof    = Length[Select[binomExp, # >= 5 &]] - 1;
Print["chi^2 = ", NumberForm[chi2, {6, 2}], "  (dof=", dof, ")"];
Print["p-value = ", NumberForm[SurvivalFunction[ChiSquareDistribution[dof], chi2], {5, 3}]];

(* -- Plot: bars of empirical density + Binomial PMF + Normal PDF -- *)
empDensity = bins / N[nTrials];
yMax       = 1.15 * Max[empDensity, binomPMF];
barsGraphics = Graphics[{
  Opacity[0.55], RGBColor[0.35, 0.55, 0.85],
  Table[Rectangle[{k - 0.45, 0}, {k + 0.45, empDensity[[k]]}], {k, 1, nBins}]
}];
mu    = (N0 + 2) / 2.;
sigma = Sqrt[N0] / 2.;
overlay = Show[
  barsGraphics,
  Plot[PDF[NormalDistribution[mu, sigma], x], {x, 0.5, N0 + 1.5},
     PlotStyle -> Directive[Red, Thick, Dashed]],
  ListPlot[Table[{k + 1, binomPMF[[k + 1]]}, {k, 0, N0}],
     PlotStyle -> Directive[PointSize[0.012], Darker@Green], Joined -> False],
  Frame -> True, Axes -> False,
  FrameLabel -> {"bin index", "density"},
  PlotLabel -> Row[{
    "Physics Galton board: empirical (blue) vs Binomial(",
    N0, ",\[VeryThinSpace]1/2) (green \[FilledCircle]) vs N(\[Mu],\[Sigma]\.b2) PDF (red dashed). ",
    nTrials, " trials"}],
  PlotRange -> {{0.3, N0 + 1.7}, {0, yMax}},
  ImageSize -> 1000, AspectRatio -> 0.5];

outDir = FileNameJoin[{DirectoryName[$InputFileName, 2], "output"}];
Export[FileNameJoin[{outDir, "03_histogram_overlay.png"}], overlay];
Export[FileNameJoin[{outDir, "03_histogram.png"}],
   Show[barsGraphics, Frame -> True, Axes -> False,
        FrameLabel -> {"bin index", "frequency"},
        PlotLabel -> Row[{"Empirical distribution of final bin, n = ", nTrials}],
        PlotRange -> {{0.3, N0 + 1.7}, {0, yMax}},
        ImageSize -> 800, AspectRatio -> 0.55]];
Export[FileNameJoin[{outDir, "03_histogram.csv"}],
   Prepend[Table[{k, bins[[k]], binomExp[[k]]}, {k, 1, nBins}],
           {"bin", "empirical", "binomial_expected"}]];

Print["wrote output/03_histogram.png, _overlay.png, and .csv"];
