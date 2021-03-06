#InspectDR: Base functionnality and types for Cairo layer
#-------------------------------------------------------------------------------

#=TODO
-Fix glyph size for "constant area" (appearance).  Currently, algorithms use
 "constant bounding box" to avoid repeating complex math (ex: h=sqrt(a^2+b^2)).
 Solution: Create glyph object that takes Vector{Point2D} - or something
 similar.  That way, complex math is done only once per curve.
=#


#==Constants
===============================================================================#
immutable CAlignment #Cairo alignment
	v::Int
end
Base.|(a::CAlignment, b::CAlignment) = CAlignment(a.v|b.v)

const ALIGN_LEFT = CAlignment(0)
const ALIGN_HCENTER = CAlignment(1)
const ALIGN_RIGHT = CAlignment(2)
const ALIGN_HMASK = 0x3

const ALIGN_BOTTOM = CAlignment(0)
const ALIGN_VCENTER = CAlignment(4)
const ALIGN_TOP = CAlignment(8)
const ALIGN_VMASK = (0x3<<2)


#==Main types
===============================================================================#
#2D plot canvas; basic info:
type PCanvas2D <: PlotCanvas
	ctx::CairoContext
	bb::BoundingBox #Entire canvas
	graphbb::BoundingBox #Graph portion
	ext::PExtents2D #Extents of graph portion
	xf::Transform2D #Transform used to render data
end
PCanvas2D(ctx, bb, graphbb, ext) =
	PCanvas2D(ctx, bb, graphbb, ext, Transform2D(ext, graphbb))

immutable CGlyph{GTYPE}; end #Dispatchable glyph object
CGlyph(gtype::Symbol) = CGlyph{gtype}()


#==Helper functions
===============================================================================#

function _set_stylewidth(ctx::CairoContext, style::Symbol, linewidth::Float64)

	dashes = Float64[] #default (:solid)
	offset = 0

	if :none == style
		linewidth = 0 #In case
	elseif :dash == style
		dashes = Float64[4,2]
	elseif :dot == style
		dashes = Float64[1,2]
	elseif :dashdot == style
		dashes = Float64[4,2,1,2]
	elseif :solid != style
		warn("Unrecognized line style: $style")
	end

	Cairo.set_line_width(ctx, linewidth);
	Cairo.set_dash(ctx, dashes.*linewidth, offset)
end


#==Rendering Glyphs
===============================================================================#

function drawglyph{T}(ctx::CairoContext, ::CGlyph{T}, pt::Point2D, size::DReal)
	warn("Glyph not supported: $T")
end

#= Supported:
	:square, :diamond,
	:uarrow, :darrow, :larrow, :rarrow, #usually triangles
	:cross, :+, :diagcross, :x,
	:circle, :o, :star, :*,
=#

function drawglyph(ctx::CairoContext, ::CGlyph{:circle}, pt::Point2D, size::DReal)
	radius = size/2
	Cairo.arc(ctx, pt.x, pt.y, radius, 0, 2pi)
	Cairo.stroke(ctx)
end

function drawglyph(ctx::CairoContext, ::CGlyph{:square}, pt::Point2D, size::DReal)
	elen = size #full edge length
	hlen = elen/2 #halflength
	Cairo.rectangle(ctx, pt.x-hlen, pt.y-hlen, elen, elen)
	Cairo.stroke(ctx)
end

function drawglyph(ctx::CairoContext, ::CGlyph{:cross}, pt::Point2D, size::DReal)
	elen = size*sqrt(2) #full edge length
	hlen = elen/2 #halflength
	Cairo.move_to(ctx, pt.x, pt.y-hlen)
	Cairo.rel_line_to(ctx, 0, elen)
	Cairo.stroke(ctx)
	Cairo.move_to(ctx, pt.x-hlen, pt.y)
	Cairo.rel_line_to(ctx, elen, 0)
	Cairo.stroke(ctx)
end
drawglyph(ctx::CairoContext, ::CGlyph{:+}, pt::Point2D, size::DReal) =
	drawglyph(ctx, CGlyph{:cross}(), pt, size)

function drawglyph(ctx::CairoContext, ::CGlyph{:diagcross}, pt::Point2D, size::DReal)
	elen = size #full edge length
	hlen = elen/2 #halflength
	Cairo.move_to(ctx, pt.x-hlen, pt.y-hlen)
	Cairo.rel_line_to(ctx, elen, elen)
	Cairo.stroke(ctx)
	Cairo.move_to(ctx, pt.x-hlen, pt.y+hlen)
	Cairo.rel_line_to(ctx, elen, -elen)
	Cairo.stroke(ctx)
end
drawglyph(ctx::CairoContext, ::CGlyph{:x}, pt::Point2D, size::DReal) =
	drawglyph(ctx, CGlyph{:diagcross}(), pt, size)

function drawglyph(ctx::CairoContext, ::CGlyph{:star}, pt::Point2D, size::DReal)
	elen = size*sqrt(2) #full edge length
	hlen = elen/2 #halflength

	Cairo.move_to(ctx, pt.x, pt.y-hlen)
	Cairo.rel_line_to(ctx, 0, elen)
	Cairo.stroke(ctx)
	Cairo.move_to(ctx, pt.x-hlen, pt.y)
	Cairo.rel_line_to(ctx, elen, 0)
	Cairo.stroke(ctx)

	elen = size #full edge length
	hlen = elen/2 #halflength

	Cairo.move_to(ctx, pt.x-hlen, pt.y-hlen)
	Cairo.rel_line_to(ctx, elen, elen)
	Cairo.stroke(ctx)
	Cairo.move_to(ctx, pt.x-hlen, pt.y+hlen)
	Cairo.rel_line_to(ctx, elen, -elen)
	Cairo.stroke(ctx)
end
drawglyph(ctx::CairoContext, ::CGlyph{:*}, pt::Point2D, size::DReal) =
	drawglyph(ctx, CGlyph{:star}(), pt, size)

function drawglyph(ctx::CairoContext, ::CGlyph{:diamond}, pt::Point2D, size::DReal)
	elen = size #full edge length
	hlen = elen/2 #halflength
	Cairo.move_to(ctx, pt.x, pt.y-hlen)
	Cairo.rel_line_to(ctx, hlen, hlen)
	Cairo.rel_line_to(ctx, -hlen, hlen)
	Cairo.rel_line_to(ctx, -hlen, -hlen)
	Cairo.close_path(ctx)
	Cairo.stroke(ctx)
end


#dir=1: up, -1: down
function drawglyph_varrow(ctx::CairoContext, pt::Point2D, size::DReal, dir::Int)
	elen = size #full edge length
	hlen = elen/2 #halflength
	dlen = dir*elen #directional edge
	Cairo.move_to(ctx, pt.x, pt.y-dir*hlen)
	Cairo.rel_line_to(ctx, hlen, dlen)
	Cairo.rel_line_to(ctx, -elen, 0)
	Cairo.close_path(ctx)
	Cairo.stroke(ctx)
end

drawglyph(ctx::CairoContext, ::CGlyph{:uarrow}, pt::Point2D, size::DReal) =
	drawglyph_varrow(ctx, pt, size, 1)
drawglyph(ctx::CairoContext, ::CGlyph{:darrow}, pt::Point2D, size::DReal) =
	drawglyph_varrow(ctx, pt, size, -1)

#dir=1: right, -1: left
function drawglyph_harrow(ctx::CairoContext, pt::Point2D, size::DReal, dir::Int)
	elen = size #full edge length
	hlen = elen/2 #halflength
	dlen = dir*elen #directional edge
	Cairo.move_to(ctx, pt.x+dir*hlen, pt.y)
	Cairo.rel_line_to(ctx, -dlen, hlen)
	Cairo.rel_line_to(ctx, 0, -elen)
	Cairo.close_path(ctx)
	Cairo.stroke(ctx)
end

drawglyph(ctx::CairoContext, ::CGlyph{:larrow}, pt::Point2D, size::DReal) =
	drawglyph_harrow(ctx, pt, size, -1)
drawglyph(ctx::CairoContext, ::CGlyph{:rarrow}, pt::Point2D, size::DReal) =
	drawglyph_harrow(ctx, pt, size, 1)


#==Basic rendering
===============================================================================#

#Reset context to known state:
function _reset(ctx::CairoContext)
	Cairo.set_source(ctx, COLOR_BLACK)
	Cairo.set_line_width(ctx, 1);
	Cairo.set_dash(ctx, Float64[], 0)
end

function clear(ctx::CairoContext, bb::BoundingBox, color::Colorant=COLOR_WHITE)
	Cairo.set_source(ctx, color)
	Cairo.rectangle(ctx, bb)
	fill(ctx)
end

function _clip(ctx::CairoContext, bb::BoundingBox)
	Cairo.rectangle(ctx, bb)
	Cairo.clip(ctx)
end

#Draw a simple line on a CairoContext
#-------------------------------------------------------------------------------
function drawline(ctx::CairoContext, p1::Point2D, p2::Point2D)
	Cairo.move_to(ctx, p1.x, p1.y)
	Cairo.line_to(ctx, p2.x, p2.y)
	Cairo.stroke(ctx)
end


#==Rendering text
===============================================================================#
function textoffset(t_ext::Array{Float64}, align::CAlignment)
#=
typedef struct {
	double x_bearing, y_bearing;
	double width, height;
	double x_advance, y_advance;
} cairo_text_extents_t;
=#

	halign = align.v & ALIGN_HMASK
	_size = t_ext[3]; bearing = t_ext[1]
	xoff = -bearing #ALIGN_LEFT

	if ALIGN_HCENTER.v == halign
		xoff -= _size/2
	elseif ALIGN_RIGHT.v == halign
		xoff -= _size
	end

	valign = align.v & ALIGN_VMASK
	_size = t_ext[4]; bearing = t_ext[2]
	yoff = -bearing #ALIGN_TOP

	if ALIGN_VCENTER.v == valign
		yoff -= _size/2
	elseif ALIGN_BOTTOM.v == valign
		yoff -= _size
	end

	return tuple(xoff, yoff)
end
text_dims(t_ext::Array{Float64}) = tuple(t_ext[3], t_ext[4]) #w, h


#Render text on a CairoContext
#-------------------------------------------------------------------------------
function setfont(ctx::CairoContext, font::Font)
	const fontname = "Serif" #Sans, Serif, Fantasy, Monospace
	const weight = font.bold? Cairo.FONT_WEIGHT_BOLD: Cairo.FONT_WEIGHT_NORMAL
	const noitalic = Cairo.FONT_SLANT_NORMAL
	Cairo.select_font_face(ctx, fontname, noitalic,	weight)
	Cairo.set_font_size(ctx, font._size);
end

function render(ctx::CairoContext, t::DisplayString, pt::Point2D,
	font::Font, align::CAlignment, angle::Float64, color::Colorant)
	setfont(ctx, font)
	t_ext = Cairo.text_extents(ctx, t)
	(xoff, yoff) = textoffset(t_ext, align)

	Cairo.save(ctx) #-----

	Cairo.translate(ctx, pt.x, pt.y);
	if angle != 0 #In case is a bit faster...
		Cairo.rotate(ctx, angle*(pi/180));
	end

	Cairo.move_to(ctx, xoff, yoff);
	Cairo.set_source(ctx, color)
	Cairo.show_text(ctx, t);

	Cairo.restore(ctx) #-----
end
render(ctx::CairoContext, t::AbstractString, pt::Point2D, font::Font;
	align::CAlignment=ALIGN_BOTTOM|ALIGN_LEFT, angle::Real=0, color::Colorant=COLOR_BLACK) =
	render(ctx, DisplayString(t), pt, font, align, Float64(angle), color)

#Draws number as base, raised to a power (ex: 10^9):
#-------------------------------------------------------------------------------
function render_power(ctx::CairoContext, base::Int, val::DReal, pt::Point2D, font::Font, align::CAlignment)
	const EXP_SCALE = 0.75
	const EXP_SHIFT = 0.5
	fontexp = deepcopy(font)
	fontexp._size = font._size*EXP_SCALE

	setfont(ctx, font)
	tbase = @sprintf("%d", base)
	(wbase, hbase) = text_dims(Cairo.text_extents(ctx, tbase))
	setfont(ctx, fontexp)
	texp = @sprintf("%0.0f", val)
	(wexp, hexp) = text_dims(Cairo.text_extents(ctx, texp))

	#Compute bounding box:
	voffset_exp = EXP_SHIFT * hbase
	w = wbase+wexp
	h = max(hbase, voffset_exp+hexp)

	halign = align.v & ALIGN_HMASK
	xoff = 0 #ALIGN_LEFT
	if ALIGN_HCENTER.v == halign
		xoff -= w/2
	elseif ALIGN_RIGHT.v == halign
		xoff -= w
	end

	valign = align.v & ALIGN_VMASK
	yoff = 0 #ALIGN_BOTTOM
	if ALIGN_VCENTER.v == valign
		yoff += h/2
	elseif ALIGN_TOP.v == valign
		yoff += h
	end

	pt = Point2D(pt.x + xoff, pt.y + yoff)
	render(ctx, tbase, pt, font, align=ALIGN_LEFT|ALIGN_BOTTOM)

	pt = Point2D(pt.x + wbase, pt.y - voffset_exp)
	render(ctx, texp, pt, fontexp, align=ALIGN_LEFT|ALIGN_BOTTOM)
end


#==Rendering base plot elements
===============================================================================#

#Render main plot annotation (titles, axis labels, ...)
#-------------------------------------------------------------------------------
function render(canvas::PCanvas2D, a::Annotation, lyt::Layout)
	const ctx = canvas.ctx
	const bb = canvas.bb
	const graph = canvas.graphbb

	xcenter = (graph.xmin+graph.xmax)/2
	ycenter = (graph.ymin+graph.ymax)/2

	#Title
	pt = Point2D(xcenter, bb.ymin+lyt.htitle/2)
	render(ctx, a.title, pt, lyt.fnttitle, align=ALIGN_HCENTER|ALIGN_VCENTER)

	#X-axis
	pt = Point2D(xcenter, bb.ymax-lyt.haxlabel/2)
	render(ctx, a.xlabel, pt, lyt.fntaxlabel, align=ALIGN_HCENTER|ALIGN_VCENTER)

	#Y-axis
	pt = Point2D(bb.xmin+lyt.waxlabel/2, ycenter)
	render(ctx, a.ylabel, pt, lyt.fntaxlabel, align=ALIGN_HCENTER|ALIGN_VCENTER, angle=-90)
end

#Render frame around graph
#-------------------------------------------------------------------------------
function render_graphframe(canvas::PCanvas2D)
	const ctx = canvas.ctx
	Cairo.set_source(ctx, COLOR_BLACK)
	Cairo.set_line_width(ctx, 2);
	Cairo.rectangle(ctx, canvas.graphbb)
	Cairo.stroke(ctx)
end

#==Render grid
===============================================================================#
render_vlines(ctx::CairoContext, graphbb::BoundingBox, xf::Transform2D, lyt::Layout, xlines::AbstractGridLines) = nothing
function render_vlines(ctx::CairoContext, graphbb::BoundingBox, xf::Transform2D, lyt::Layout, xlines::GridLines)
	if lyt.grid.vmajor
		_set_stylewidth(ctx, :dash, GRID_MAJOR_WIDTH)
		Cairo.set_source(ctx, GRID_MAJOR_COLOR)
		for xline in xlines.major
			x = ptmap(xf, Point2D(xline, 0)).x
			drawline(ctx, Point2D(x, graphbb.ymin), Point2D(x, graphbb.ymax))
		end
	end
	if lyt.grid.vminor
		_set_stylewidth(ctx, :dash, GRID_MINOR_WIDTH)
		Cairo.set_source(ctx, GRID_MINOR_COLOR)
		for xline in xlines.minor
			x = ptmap(xf, Point2D(xline, 0)).x
			drawline(ctx, Point2D(x, graphbb.ymin), Point2D(x, graphbb.ymax))
		end
	end
end
render_hlines(ctx::CairoContext, graphbb::BoundingBox, xf::Transform2D, lyt::Layout, ylines::AbstractGridLines) = nothing
function render_hlines(ctx::CairoContext, graphbb::BoundingBox, xf::Transform2D, lyt::Layout, ylines::GridLines)
	if lyt.grid.hmajor
		_set_stylewidth(ctx, :dash, GRID_MAJOR_WIDTH)
		Cairo.set_source(ctx, GRID_MAJOR_COLOR)
		for yline in ylines.major
			y = ptmap(xf, Point2D(0, yline)).y
			drawline(ctx, Point2D(graphbb.xmin, y), Point2D(graphbb.xmax, y))
		end
	end
	if lyt.grid.hminor
		_set_stylewidth(ctx, :dash, GRID_MINOR_WIDTH)
		Cairo.set_source(ctx, GRID_MINOR_COLOR)
		for yline in ylines.minor
			y = ptmap(xf, Point2D(0, yline)).y
			drawline(ctx, Point2D(graphbb.xmin, y), Point2D(graphbb.xmax, y))
		end
	end
end

function render_grid(canvas::PCanvas2D, lyt::Layout, grid::GridRect)
	const ctx = canvas.ctx
	Cairo.save(ctx) #-----
	render_vlines(ctx, canvas.graphbb, canvas.xf, lyt, grid.xlines)
	render_hlines(ctx, canvas.graphbb, canvas.xf, lyt, grid.ylines)
	Cairo.restore(ctx) #-----
end


#==Render ticks
===============================================================================#

#Default label:
function render_ticklabel(ctx::CairoContext, val::DReal, pt::Point2D, font::Font, align::CAlignment, ::AxisScale)
	tstr = @sprintf("%0.1e", val)
	render(ctx, tstr, pt, font, align=align)
end

render_ticklabel(ctx::CairoContext, val::DReal, pt::Point2D, font::Font, align::CAlignment, scale::AxisScale{:log10}) =
	render_power(ctx, 10, val, pt, font, align)

#Render ticks: Well-defined GridLines
#-------------------------------------------------------------------------------
function render_xticks(ctx::CairoContext, graphbb::BoundingBox, xf::Transform2D, lyt::Layout, xlines::GridLines)
	yframe = graphbb.ymax
	ylabel = graphbb.ymax + lyt.hticklabel / 2
	for xtick in xlines.major
		x = ptmap(xf, Point2D(xtick, 0)).x
		render_ticklabel(ctx, xtick, Point2D(x, ylabel), lyt.fntaxlabel, ALIGN_HCENTER|ALIGN_VCENTER, xlines.scale)
		drawline(ctx, Point2D(x, yframe), Point2D(x, yframe-TICK_MAJOR_LEN))
	end
	for xtick in xlines.minor
		x = ptmap(xf, Point2D(xtick, 0)).x
		drawline(ctx, Point2D(x, yframe), Point2D(x, yframe-TICK_MINOR_LEN))
	end
end
function render_yticks(ctx::CairoContext, graphbb::BoundingBox, xf::Transform2D, lyt::Layout, ylines::GridLines)
	xframe = graphbb.xmin
	xlabel = graphbb.xmin - 2 #TODO: offset by with of graphframe?
	for ytick in ylines.major
		y = ptmap(xf, Point2D(0, ytick)).y
		render_ticklabel(ctx, ytick, Point2D(xlabel, y), lyt.fntaxlabel, ALIGN_RIGHT|ALIGN_VCENTER, ylines.scale)
		drawline(ctx, Point2D(xframe, y), Point2D(xframe+TICK_MAJOR_LEN, y))
	end
	for ytick in ylines.minor
		y = ptmap(xf, Point2D(0, ytick)).y
		drawline(ctx, Point2D(xframe, y), Point2D(xframe+TICK_MINOR_LEN, y))
	end
end

#Render ticks: UndefinedGridLines
#-------------------------------------------------------------------------------
function render_xticks(ctx::CairoContext, graphbb::BoundingBox, xf::Transform2D, lyt::Layout, xlines::UndefinedGridLines)
	yframe = graphbb.ymax
	ylabel = graphbb.ymax + lyt.hticklabel / 2
	for (x, xlabel) in [(graphbb.xmin, xlines.minline), (graphbb.xmax, xlines.maxline)]
		render_ticklabel(ctx, xlabel, Point2D(x, ylabel), lyt.fntaxlabel, ALIGN_HCENTER|ALIGN_VCENTER, AxisScale{:lin}())
		drawline(ctx, Point2D(x, yframe), Point2D(x, yframe-TICK_MAJOR_LEN))
	end
end
function render_yticks(ctx::CairoContext, graphbb::BoundingBox, xf::Transform2D, lyt::Layout, ylines::UndefinedGridLines)
	xframe = graphbb.xmin
	xlabel = graphbb.xmin - 2 #TODO: offset by with of graphframe?
	for (y, ylabel) in [(graphbb.ymax, ylines.minline), (graphbb.ymin, ylines.maxline)]
		render_ticklabel(ctx, ylabel, Point2D(xlabel, y), lyt.fntaxlabel, ALIGN_RIGHT|ALIGN_VCENTER, AxisScale{:lin}())
		drawline(ctx, Point2D(xframe, y), Point2D(xframe+TICK_MAJOR_LEN, y))
	end
end

function render_ticks(canvas::PCanvas2D, lyt::Layout, grid::GridRect)
	render_xticks(canvas.ctx, canvas.graphbb, canvas.xf, lyt, grid.xlines)
	render_yticks(canvas.ctx, canvas.graphbb, canvas.xf, lyt, grid.ylines)
end


#==High-level rendering
===============================================================================#

#Render axis labels, ticks, ...
#-------------------------------------------------------------------------------
function render_axes(canvas::PCanvas2D, lyt::Layout, grid::GridRect)
	render_graphframe(canvas)
	render_ticks(canvas, lyt, grid)
end

#Render an actual waveform
#-------------------------------------------------------------------------------
function render(canvas::PCanvas2D, wfrm::DWaveform)
	ctx = canvas.ctx
	ds = wfrm.ds

	if length(ds) < 2
		return
	end

	Cairo.set_source(ctx, wfrm.line.color)
	_set_stylewidth(ctx, wfrm.line.style, Float64(wfrm.line.width))
	pt = ptmap(canvas.xf, ds[1])
	Cairo.move_to(ctx, pt.x, pt.y)
	for i in 2:length(ds)
		pt = ptmap(canvas.xf, ds[i])
		Cairo.line_to(ctx, pt.x, pt.y)
	end
#	set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_MITER)
	Cairo.stroke(ctx)

	if :none == wfrm.glyph.shape; return; end
	_glyph = CGlyph(wfrm.glyph.shape)

	#TODO: do not draw when outside graph extents.

	#Draw symbols:
	_set_stylewidth(ctx, :solid, Float64(wfrm.line.width))
	gsize = Float64(wfrm.glyph.size*wfrm.line.width)
	for i in 1:length(ds)
		pt = ptmap(canvas.xf, ds[i])
		drawglyph(ctx, _glyph, pt, gsize)
	end

	return
end
render(canvas::PCanvas2D, wfrmlist::Vector{DWaveform}) =
	map((w)->render(canvas, w), wfrmlist)


#Render entire plot
#-------------------------------------------------------------------------------
function render(canvas::PCanvas2D, plot::Plot2D)
	#Render annotation/axes
	render(canvas, plot.annotation, plot.layout)

	grid = gridlines(plot.axes, canvas.ext)
	render_grid(canvas, plot.layout, grid)
	#TODO: render axes first once drawing is multi-threaded.
#	render_axes

	#Plot actual data
	Cairo.save(canvas.ctx)
	_clip(canvas.ctx, canvas.graphbb)
	render(canvas, plot.display_data)
	Cairo.restore(canvas.ctx)

	#Re-render axis over data:
	render_axes(canvas, plot.layout, grid)
end

#Render entire plot within provided bounding box:
function render(ctx::CairoContext, plot::Plot2D, bb::BoundingBox)
	graphbb = graphbounds(bb, plot.layout)
	update_ddata(plot) #Also computes new extents
	canvas = PCanvas2D(ctx, bb, graphbb, getextents_xfrm(plot))
	render(canvas, plot)
end

#Last line
