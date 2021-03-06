# InspectDR.jl

\*Sigh\*... Yet *another* plotting tool.

[![Build Status](https://travis-ci.org/ma-laforge/InspectDR.jl.svg?branch=master)](https://travis-ci.org/ma-laforge/InspectDR.jl)

[Sample Plots](https://github.com/ma-laforge/FileRepo/tree/master/InspectDR/sampleplots/README.md) (might be out of date).<br>
**WARNING:** [NOT ALL FEATURES ARE YET IMPLEMENTED](#KnownLimitations)

## Description

InspectDR is a fast plotting tool.  The main goal is to allow the user to quickly navigate simulation results (interactive) before moving to the next design iteration.

Despite their great quality, most current Julia plotting options are still either too slow, or provide inadequate interactivity for the author's needs.

### Features/Highlights

#### Box Zoom

Use right mouse button to select new extents for plot.

#### "F1" Acceleration

InspectDR.jl includes specialized algorithms to accellerate plotting of large "F1" datasets (functions of 1 argument) in order to maintain a good "real-time" (interactive) user experience.

A dataset is defined as a function of 1 argument ("F1") if it satisfies:

	y = f(x), where x: sorted, real vector

Examples of "F1" datasets include **time domain** (`y(x=time)`) and **frequncy domain** (`X(w)`) data.

#### 2D Plot Support

InspectDR.jl also supports generic 2D plotting.  More specifically, the tool is capable of plotting arbitrary 2D datasets that satisfy:

	(x,y) = (u[i], v[i]), for i in [1...N]

Examples of of such plots (where x-values are not guaranteed to be sorted) include:

 - Nyquist plots
 - Lissajous plots
 - S-Parameter Plots

#### Keybindings

InspectDR.jl supports keybindings to improve/accelerate user control.  The following table lists supported bindings:

| Function | Key |
| -------- | :---: |
| Zoom out to full extents | `f` |
| Zoom in / zoom out | `+` / `-` |
| Zoom in / zoom out | `CTRL` + `mousewheel`|
| Pan up / pan down | &uArr; / &dArr; |
| Pan up / pan down | `mousewheel` |
| Pan left / pan right | &lArr; / &rArr; |
| Pan left / pan right | `SHIFT` + `mousewheel`|

<a name="SampleUsage"></a>
## Sample Usage

Sample code to construct InspectDR objects can be found [here](sample/).

<a name="KnownLimitations"></a>
## Known Limitations

 - Documentation is a bit limited at the moment.  See [Sample Usage](#SampleUsage) to learn from examples.
 - API is still a bit rough.  User often has to manipulate data structures directly.
 - Tick labels need to be improved (# of decimal places, ...).
 - Only generates basic annotations. Needs legends, ...
 - Does not yet support many axis scales (only linear, log10 & dB20).
 - Does not yet render plot data in separate thread (will improve interactive experience with large datasets).
 - Mouse events currently function even outside data area (a bit odd).

### Compatibility

Extensive compatibility testing of InspectDR.jl has not been performed.  The module has been tested using the following environment(s):

 - Linux / Julia-0.4.2 / Gtk 0.9.3 (Gtk+ 3) / Cairo 0.2.31

## Disclaimer

The InspectDR.jl module is not yet mature.  Expect significant changes.
