local directfb = require 'directfb'
local pairs, print, setmetatable, unpack, type, error, select = pairs, print, setmetatable, unpack, type, error, select

module('canvas')

-- DFB Initialization
directfb.DirectFBInit()
local dfb = directfb.DirectFBCreate()

-- Canvas declaration
local Canvas = {}
Canvas.__index = Canvas

Canvas.colorTable = {}
Canvas.colorTable.blue = {0, 0, 255}
Canvas.colorTable.red = {255, 0, 0}
Canvas.colorTable.green = {0, 255, 0}
Canvas.colorTable.black = {0, 0, 0}
Canvas.colorTable.white = {255, 255, 255}

function Canvas.newcanvas(surface)
	local canvas = {}
	canvas.surface = surface
	setmetatable(canvas, Canvas)
	return canvas
end

function Canvas:new(...)
	local argType = type(...)
	local surface 

	-- Create canvas from path
	if argType == 'string' then
		local path = ...
		local provider = dfb:CreateImageProvider(path)
		surface = dfb:CreateSurface(provider:GetSurfaceDescription())
		provider:RenderTo(surface, nil)
		provider:Release()

	-- Create fixed size canvas
	elseif argType == 'number' then
		local w,h = ...
		surface = dfb:CreateSurface {width=w, height=h}

	else
		error('Bad argument: string or number expected')
	end

	return Canvas.newcanvas(surface)
end

function Canvas:flush()
	self.surface:Flip(nil, 0)
end

function Canvas:attrSize()
	return self.surface:GetSize()
end

function Canvas:attrClip()
	error('UNIMPLEMENTED')
end

function Canvas:attrCrop()
	error('UNIMPLEMENTED')
end

function Canvas:attrColor(...)
	local argc = select('#', ...)
	if argc == 0 then
		return unpack(self.color)
	else
		local argType = type(...)
		local r,g,b,a,str

		if argType == 'number' then
			r,g,b,a = ...

		elseif argType == 'string' then
			str,a = ...
			r,g,b = unpack(Canvas.colorTable[str])
		end
		self.color = {r,g,b,a or 0xff}
		self.surface:SetColor(r,g,b,a or 0xff)
	end
end

-- TODO: add getter for attrFont
function Canvas:attrFont(face, size, style)
	-- style not supported, there is no easy way to build font path :(
	local name = face .. '.ttf'

	-- this is WRONG!, we must try with differents paths until
	-- we found something or give up after a few tries.
	local path = name

	local font = dfb:CreateFont(path, {height=size})
	self.surface:SetFont(font)
end

function Canvas:drawText(x, y, text)
	self.surface:DrawString(text, -1, x, y, nil)
end

function Canvas:measureText(text)
	-- GetStringExtents return logical rectangle and ink rectangle,
	-- we are interested here in the latter. 
	-- For more information, check DirectFB documentation.
	local logical, ink = self.surface:GetFont():GetStringExtents(text, -1)
	return ink.w, ink.h
end

function Canvas:drawRect(mode, x, y, width, height)

	if mode == 'fill' then
		self.surface:FillRectangle(x,y,width,height)
	elseif mode == 'frame' then
		self.surface:DrawRectangle(x,y,width,height)
	else
		error('Bad mode: frame or fill expected')
	end
end

function Canvas:drawLine(x1, y1, x2, y2)
	self.surface:DrawLine(x1,y1,x2,y2)
end

function Canvas:compose(x, y, src)
	-- second argument is source rectangle, we use nil to use
	-- the whole source surface
	self.surface:Blit(src, nil, x, y)
end

-- Create base instance
return Canvas.newcanvas(dfb:CreateSurface {caps='DSCAPS_PRIMARY|DSCAPS_FLIPPING'})
