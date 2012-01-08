
require 'directfb'

local dfb, keybuffer, primary

-- DFB Initialization
directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()

-- Create input buffer, set to receive all kinds of events
keybuffer = dfb:CreateInputEventBuffer('DICAPS_ALL', 'DFB_TRUE')

-- Create primary surface, double buffered
primary = dfb:CreateSurface {caps='DSCAPS_PRIMARY|DSCAPS_DOUBLE'}

-- We need to do this in order to 'activate' events (why?)
primary:Clear()
primary:Flip()

-- load font
font = dfb:CreateFont('DejaVuSans.ttf', {height=50})
primary:SetFont(font)
primary:SetColor(0xff, 0xff, 0xff, 0xff)

local function drawEvent(e)
	local str

	if e.type == DIET_KEYPRESS then
		str = 'Key press: '
		str = str .. e.key_symbol

	elseif e.type == DIET_KEYRELEASE then
		str = 'Key release: '
		str = str .. e.key_symbol

	elseif e.type == DIET_BUTTONPRESS then
		str = 'Button press: '
		str = str .. e.button

	elseif e.type == DIET_BUTTONRELEASE then
		str = 'Button release: '
		str = str .. e.button

	elseif e.type == DIET_AXISMOTION then
		str = 'Motion: '
		if e.axis == DIAI_X then
			str = str ..  'X: ' .. e.axisabs
		elseif e.axis == DIAI_Y then
			str = str ..  'Y: ' .. e.axisabs
		elseif e.axis == DIAI_Z then
			str = str ..  'Z: ' .. e.axisabs
		end
	end

	-- TODO: Something like this should be done,
	-- in order to show a string instead of a number.
--	if e.key_symbol == DIKS_SMALL_A then
--		str = str .. 'a'
--	end

	primary:Clear()
	primary:DrawString(str, -1, 50, 50, 'DSTF_LEFT | DSTF_TOP' )
	primary:Flip()
end

-- Main loop
while true do

	keybuffer:WaitForEvent()

	-- FIXME: 
	-- This is a little hack, to be able to use GetEvent, and 
	-- similar functions that fail on non-fatal conditions
	local status, event = pcall(keybuffer.GetEvent, keybuffer)
	if status then

		if event.type == DIET_KEYPRESS and event.key_symbol == DIKS_ESCAPE then
			break
		end

		drawEvent(event)
	end
end
