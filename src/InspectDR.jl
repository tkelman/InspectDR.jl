#InspectDR:
#-------------------------------------------------------------------------------

#__precompile__()
module InspectDR

#Default values for data area configuration:
const DEFAULT_DATA_ASPECT = 1.6 #Roughly golden ratio
const DEFAULT_DATA_WIDTH = 500.0
const DEFAULT_DATA_HEIGHT = DEFAULT_DATA_WIDTH / DEFAULT_DATA_ASPECT

using Colors
using Graphics
import Gtk
const _Gtk = Gtk.ShortNames
import Cairo
import Cairo: CairoContext

typealias DisplayString UTF8String

include("codegen.jl")
include("math.jl")
include("base.jl")
include("datasetop.jl")
include("grids.jl")
#include("cairo_ext.jl")
include("cairo_base.jl")
include("cairo_io.jl")
include("gtk_base.jl")
include("gtk_input.jl")
include("gtk_zoom.jl")
include("gtk_top.jl")

keybindings_setdefaults(keybindings)


#==Comments
================================================================================
-SVG output from writemime does not show up properly in Notebook.  There
 appears to be an issue with determining the extents of the image (bounding box).
-Data area referred to as "graph" area.  This might not be correct.

DReal vs Float64:
	Float64: Used in API dealing with Gtk/Cairo coordinates.
	DReal: Used in API dealing with plot data itself
		(Attempt to reduce code bloat/different code paths by using concrete
		data type in internal data structures/algorithms... despite potential
		inefficiencies).

PExtents2D vs BoundingBox:
	PExtents2D: Extents of data (data coordinate system).
	BoundingBox: Extents of graphical element ("device" coordinate system).

About extents:
	Extents are typically stored using user-level coordinates (USER).
	When drawing the plot, extents are manipulated in a transformed
	coordinate system (XFRM).  For example, XFRM coordinates of a log-x
	plot are given by XFRM=log10(USER).

	ext_data::PExtents2D #Maximum extents of data
	ext_full::PExtents2D #Defines "full" zoom when combined with ext_data
		#Set fields to NaN to keep ext_data values
	ext::PExtents2D #Current/active extents

	setextents(::Plot2D, ::PExtents2D): Also invalidates rendered plot.
	getextents(...): Complementary accessor.

About bounds:
	plotbounds(...): Bounding box of entire plot.
	graphbounds(...): Bounding box of graph (plot data area).
=#


#==Exported interface
===============================================================================#
add = _add #Danger: high risk of collision (common name)
export add, line, glyph, grid
export axes

#==Unexported interface
================================================================================
Supported plot types:
	InspectDR.Multiplot() #Figure supporting multiple plots
	InspectDR.Plot2D <: Plot #2D plot object

Convenience functions:
	write_png(path, ::Plot)
	write_svg(path, ::Plot)
	write_eps(path, ::Plot)
	write_pdf(path, ::Plot)
=#

#Create new plot window (Is this a good idea?):
#	figure(args...; kwargs...) = GtkPlotWindow(args...; kwargs...)

#Accessors:
	Plot(gplot::GtkPlot) = gplot.src
	Plot(wnd::GtkPlotWindow, i::Int) = wnd.subplots[i]


#==Already exported
================================================================================
#Displaying a plot object:
	Base.display(d::InspectDR.GtkDisplay, p::Plot) #Gtk mutltiplot window

#Writing plot to IO stream:
	Base.writemime(::IO, ::MIME, ::Plot2D)
for the following MIMEs:
		MIME"image/png"
		MIME"image/svg+xml"
		MIME"image/eps"
		MIME"application/pdf"
=#

end #module
