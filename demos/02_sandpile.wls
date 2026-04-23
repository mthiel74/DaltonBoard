#!/usr/bin/env wolframscript
(* 02_sandpile.wls -- angle-of-repose demonstration.

   Drop ~2500 small spheres from a narrow column high above a flat
   floor.  The resulting pile settles into a conical heap whose slope
   angle is set entirely by the ball-ball friction coefficient.  Run
   the same experiment side-by-side at three different friction
   values (0.1, 0.4, 0.8) and overlay the final pile silhouettes in
   the still image -- low friction gives a shallow pancake, high
   friction a steep cone.  Everything is real Rapier rigid-body
   physics via PhysicsModelLink. *)

Needs["ArnoudBuzing`PhysicsModelLink`"];
Get[FileNameJoin[{DirectoryName[$InputFileName], "_common.wl"}]];

CreatePhysicsModel    = ArnoudBuzing`PhysicsModelLink`CreatePhysicsModel;
DynamicBody           = ArnoudBuzing`PhysicsModelLink`DynamicBody;
FixedBody             = ArnoudBuzing`PhysicsModelLink`FixedBody;
PhysicsModelIterate   = ArnoudBuzing`PhysicsModelLink`PhysicsModelIterate;
PhysicsModelPlot      = ArnoudBuzing`PhysicsModelLink`PhysicsModelPlot;
PhysicsBoundaryBox    = ArnoudBuzing`PhysicsModelLink`PhysicsBoundaryBox;
DestroyPhysicsModel   = ArnoudBuzing`PhysicsModelLink`DestroyPhysicsModel;
RapierSetBodyVelocity = ArnoudBuzing`PhysicsModelLink`RapierSetBodyVelocity;

SeedRandom[2];

(* -- Parameters -- *)
ballR     = 0.025;
nBalls    = 150;          (* per friction panel *)
floorHalf = 0.60;         (* floor half-width *)
dropZ     = 0.12;         (* just above floor *)
dropXHalf = 0.01;
dzStack   = 0.06;
gSlow     = 9.81;         (* full gravity; damping below keeps speeds bounded *)

(* -- Run a single experiment with a given friction coefficient -- *)
runOne[friction_, label_String] := Module[
  {floor, balls, bbox, model, frames, lastFrame, finalPositions},
  Print["-- friction = ", friction, "  (", label, ") --"];

  floor = FixedBody[{GrayLevel[0.85],
    Cuboid[{-floorHalf, -floorHalf, -0.12},
           { floorHalf,  floorHalf,  0.0}]},
    "Restitution" -> 0.05, "Friction" -> friction];

  (* Balls in a narrow stack above the floor *)
  balls = Table[
    DynamicBody[{Hue[Mod[0.12 k, 1]],
      Sphere[{RandomReal[{-dropXHalf, dropXHalf}],
              RandomReal[{-dropXHalf, dropXHalf}],
              dropZ + k*dzStack}, ballR]},
      "Density" -> 1.0,
      "Restitution" -> 0.1,
      "Friction" -> friction,
      "Velocity" -> {0., 0., 0.}],
    {k, 0, nBalls - 1}];

  bbox = PhysicsBoundaryBox[{
    {-floorHalf - 0.05, -floorHalf - 0.05, -0.15},
    { floorHalf + 0.05,  floorHalf + 0.05,  dropZ + nBalls*dzStack + 0.5}},
    "Thickness" -> 0.2];          (* thick walls -> balls can't tunnel through *)

  model = CreatePhysicsModel[
    Join[balls, {floor}, bbox],
    "Gravity" -> {0., 0., -gSlow},
    "Graphics3DOptions" -> {
      PlotRange    -> {{-floorHalf, floorHalf},
                       {-floorHalf, floorHalf},
                       {-0.15, 2.0}},
      Boxed        -> False, Axes -> False,
      Lighting     -> "Neutral",
      ViewPoint    -> {0, -25, 0.2},
      ViewVertical -> {0, 0, 1},
      Background   -> RGBColor[0.97, 0.97, 1.0]}];

  (* Evolve with per-step velocity damping so balls arrive slowly
     and settle on the pile instead of bouncing off the floor.
     Ball handles are the first nBalls entries in the Bodies list. *)
  Print["evolving..."];
  Module[{worldId, ballHandles, current, prevPos, dt, nFrames,
          damping, dampEvery},
    worldId = model[[1]]["WorldID"];
    ballHandles = Table[model[[1]]["Bodies"][[k]]["Handle"], {k, 1, nBalls}];
    current   = model;
    prevPos   = Table[current[[1]]["Bodies"][[k]]["Position"], {k, 1, nBalls}];
    dt        = 1/240.;
    nFrames   = 4200;
    damping   = 0.97;
    dampEvery = 4;
    frames = Reap[
      Do[
        current = PhysicsModelIterate[current, 1, dt];
        If[Mod[step, dampEvery] == 0,
          Do[Module[{pos, v},
             pos = current[[1]]["Bodies"][[k]]["Position"];
             v   = (pos - prevPos[[k]]) / (dampEvery * dt);
             RapierSetBodyVelocity[worldId, ballHandles[[k]], v * damping];
             prevPos[[k]] = pos],
            {k, 1, nBalls}]];
        Sow[current],
        {step, 1, nFrames}]][[2, 1]]];

  lastFrame = frames[[-1]];
  finalPositions = #["Position"] & /@
    Select[lastFrame[[1]]["Bodies"], #["BodyType"] === "Dynamic" &];

  DestroyPhysicsModel[model];
  {frames, finalPositions}];

(* Run the three experiments *)
{frames1, pos1} = runOne[0.1, "slick"];
{frames2, pos2} = runOne[0.4, "medium"];
{frames3, pos3} = runOne[0.8, "rough"];

(* -- Render each as its own small video and combine stills -- *)
outDir = FileNameJoin[{DirectoryName[$InputFileName, 2], "output", "demos"}];

Do[
  GaltonBoardDemos`RenderVideo[item[[1]],
    FileNameJoin[{outDir, "02_sandpile_" <> item[[2]] <> ".mp4"}],
    "VideoStep" -> 8, "ImageSize" -> {540, 540}, "FrameRate" -> 30],
  {item, {{frames1, "slick"}, {frames2, "medium"}, {frames3, "rough"}}}];

(* A side-by-side still of the three final piles *)
lastStill[frames_] := PhysicsModelPlot[frames[[-1]]];

sidePanel = GraphicsRow[{
  Show[lastStill[frames1], PlotLabel -> "\[Mu] = 0.1"],
  Show[lastStill[frames2], PlotLabel -> "\[Mu] = 0.4"],
  Show[lastStill[frames3], PlotLabel -> "\[Mu] = 0.8"]}, ImageSize -> 1500];

Export[FileNameJoin[{outDir, "02_sandpile_compare.png"}], sidePanel, ImageSize -> 1500];
Print["wrote ", FileNameJoin[{outDir, "02_sandpile_compare.png"}]];

(* Measure the angle of repose: fit a circular pile and extract the slope *)
pileAngle[positions_] := Module[{xy, r, h, slope},
  xy = positions[[All, {1, 2}]];
  r  = Max[Norm /@ xy];
  h  = Max[positions[[All, 3]]];
  slope = ArcTan[h / r] * 180. / Pi;
  {r, h, slope}];

Print["angle of repose:"];
Print["  \[Mu]=0.1 \[Rule] ", pileAngle[pos1]];
Print["  \[Mu]=0.4 \[Rule] ", pileAngle[pos2]];
Print["  \[Mu]=0.8 \[Rule] ", pileAngle[pos3]];
