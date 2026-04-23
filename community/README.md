# Community

Reply-post material for the Wolfram Community thread
*PhysicsModelLink: modeling physical models with The Wolfram language*
(<https://community.wolfram.com/groups/-/m/t/3701211>).

- [`galton_board.nb`](galton_board.nb) — the Wolfram Notebook I post
  as a reply. Embeds the 600-ball cascade GIF (as an `AnimatedImage`
  so it plays inline in the Community viewer), the
  empirical-vs-Binomial histogram, and the parameter tuning notes.
- [`galton_board.pdf`](galton_board.pdf) — PDF for offline review.
- [`build_notebook.wls`](build_notebook.wls) — wolframscript that
  regenerates the notebook (and the PDF) from the animation GIF, the
  histogram PNG, and the scripts under `../scripts/`.

## How the video embeds

Wolfram Community's HTML renderer preserves `AnimatedImage` as a
looping `<img>` in the browser. `ListAnimate` / `Manipulate` get
replaced by a static screenshot. So the animation in the post is
built with

```wolfram
AnimatedImage[
  ImageResize[#, {420}] & /@
    Import["../output/02_board_animation.gif", {"GIF", "ImageList"}],
  FrameRate -> 20, AnimationRunning -> True,
  AnimationRepetitions -> Infinity]
```

(the approach I learned from Marco's [TrafficJAms post](https://community.wolfram.com/groups/-/m/t/3701293)).

## Rebuilding

```bash
wolframscript -file build_notebook.wls
```

It needs `output/02_board_animation.gif`, `output/03_histogram_overlay.png`
and `output/02_board_final.png` to exist (all are produced by running
`scripts/02_board_animation.wls` and `scripts/03_histogram.wls` first).
