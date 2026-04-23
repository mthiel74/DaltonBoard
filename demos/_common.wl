(* ::Package:: *)

(* _common.wl -- shared helpers for the demo/*.wls scripts.  Loaded with
   Get[FileNameJoin[{DirectoryName[$InputFileName], "_common.wl"}]]. *)

BeginPackage["GaltonBoardDemos`", {"ArnoudBuzing`PhysicsModelLink`"}];

RenderVideo::usage = "RenderVideo[frames, path, opts___] rasterises every frame of a list of PhysicsModelObjects and writes an MP4 to path.  Options: FrameRate (default 30), VideoStep (default 1 -- keep every Nth frame), ImageSize (default {900, 720}).";

RenderVideo[frames_List, path_String, OptionsPattern[{"FrameRate" -> 30,
                                                      "VideoStep" -> 1,
                                                      "ImageSize" -> {900, 720}}]] :=
  Module[{step, fps, size, kept, imgs},
    step = OptionValue["VideoStep"];
    fps  = OptionValue["FrameRate"];
    size = OptionValue["ImageSize"];
    kept = frames[[;; ;; step]];
    imgs = Table[
      Rasterize[ArnoudBuzing`PhysicsModelLink`PhysicsModelPlot[f],
                ImageSize -> size, Background -> White],
      {f, kept}];
    Export[path, imgs, "MP4", "FrameRate" -> fps];
    path];

MakeGif::usage = "MakeGif[mp4Path, gifPath, width:540, fps:15] invokes ffmpeg to make a looping GIF from an MP4.";
MakeGif[mp4_String, gif_String, width_Integer: 540, fps_Integer: 15] :=
  RunProcess[{"ffmpeg", "-y", "-i", mp4,
              "-vf", "fps=" <> ToString[fps] <> ",scale=" <> ToString[width] <>
                     ":-1:flags=lanczos",
              "-loop", "0", gif}];

RandomFillBox::usage = "RandomFillBox[{xmin, xmax}, {ymin, ymax}, {zmin, zmax}, r, n, tries:10000] returns up to n non-overlapping sphere centres of radius r inside the box.";
RandomFillBox[{xMin_, xMax_}, {yMin_, yMax_}, {zMin_, zMax_}, r_, n_Integer, tries_Integer: 10000] :=
  Module[{pts = {}, t = 0, p, ok, minDist = (2 r)^2},
    While[Length[pts] < n && t < tries,
      t++;
      p = {RandomReal[{xMin + r, xMax - r}],
           RandomReal[{yMin + r, yMax - r}],
           RandomReal[{zMin + r, zMax - r}]};
      ok = AllTrue[pts, EuclideanDistance[#, p]^2 > minDist &];
      If[ok, AppendTo[pts, p]]];
    pts];

GridFillBox::usage = "GridFillBox[{xmin, xmax}, {ymin, ymax}, {zmin, zmax}, r] returns a regular hex-ish grid of sphere centres spaced 2*r apart inside the box.";
GridFillBox[{xMin_, xMax_}, {yMin_, yMax_}, {zMin_, zMax_}, r_] :=
  With[{step = 2.05 r},
    Flatten[
      Table[{x, y, z},
        {x, xMin + r, xMax - r, step},
        {y, yMin + r, yMax - r, step},
        {z, zMin + r, zMax - r, step}],
      2]];

EndPackage[];
