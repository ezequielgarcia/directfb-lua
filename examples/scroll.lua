require 'directfb'

-- DFB Initialization
directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()
dfb:SetCooperativeLevel('DFSCL_NORMAL')

-- Surface creation
surface = dfb:CreateSurface {caps='DSCAPS_PRIMARY|DSCAPS_FLIPPING'}
surface:Clear( 0xff, 0xff, 0xff, 0xff )

-- Font creation
font_path = 'res/DejaVuSans.ttf'
font = dfb:CreateFont(font_path, {height=30})

surface:SetFont(font)

-- Slurp, all of the text lines, one in each table element
local t = {}
while true do
	local line = io.read()
	if line == nil then break end
	table.insert(t, line)
end

-- Space from borders
local margin = 30

-- Get the height of all the strings,
-- so we can build a proper surface
local logic, ink
local textHeight = 0
local textWidth = 0
for k,v in pairs(t) do
	logic, ink = font:GetStringExtents(v, -1)
	textHeight = textHeight + logic.h
	if logic.w > textWidth then textWidth = logic.w end
end

-- Create an internal surface
textSurf = dfb:CreateSurface {width=textWidth+2*margin,height=textHeight}
textSurf:Clear( 0x20, 0x40, 0x80, 0xff )
textSurf:SetFont(font)

-- Now we render all the text to an internal surface *once*,
-- this allows us to never render text again.
local pos = margin
for k,v in pairs(t) do
	logic, ink = font:GetStringExtents(v, -1)
	textSurf:DrawString(v, -1, margin, pos, DSTF_TOPLEFT)
	pos = pos + logic.h
end

-- Get keyboard input device
local keyboard = dfb:GetInputDevice(0)
local currY = margin

-- Clipping is one of the *keys* of the scrolling effect,
-- try out the example with this lines commented.
local clipReg = {x1=margin, y1=margin, x2=2*margin+textWidth, y2=margin+textHeight}
surface:SetClip(clipReg)
surface:Blit(textSurf, nil, 30, currY)
surface:Flip()

-- Loop through until the escape key is pressed.
while keyboard:GetKeyState('DIKI_ESCAPE') == DIKS_UP do

	if keyboard:GetKeyState('DIKI_DOWN') == DIKS_DOWN then
		currY = currY + 1

		-- Remove clip to avoid tearing
		surface:SetClip()
		surface:Clear( 0xff, 0xff, 0xff, 0xff )

		-- Clear little clip region
		surface:SetClip(clipReg)
		surface:Clear( 0x20, 0x40, 0x80, 0xff )

		-- Draw clipped text
		surface:Blit(textSurf, nil, 30, currY)

		-- Refresh
		surface:Flip()
	end

	if keyboard:GetKeyState('DIKI_UP') == DIKS_DOWN then
		currY = currY - 1

		-- Remove clip to avoid tearing
		surface:SetClip()
		surface:Clear( 0xff, 0xff, 0xff, 0xff )

		-- Clear little clip region
		surface:SetClip(clipReg)
		surface:Clear( 0x20, 0x40, 0x80, 0xff )

		-- Draw clipped text
		surface:Blit(textSurf, nil, 30, currY)

		-- Refresh
		surface:Flip()
	end
end
