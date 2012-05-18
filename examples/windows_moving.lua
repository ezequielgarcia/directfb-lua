--
-- This example is based in df_window.c contained in the DirectFB distribution.
--

require 'directfb'

-- DFB Initialization
directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()
dfb:SetCooperativeLevel('DFSCL_NORMAL')

-- Get layer
layer = dfb:GetDisplayLayer(0)

-- Create windows
red = layer:CreateWindow {posx=100, posy=100, width=300, height=300, surface_caps='DSCAPS_FLIPPING'}
blue = layer:CreateWindow {posx=200, posy=200, width=300, height=300, surface_caps='DSCAPS_FLIPPING'}

-- Color windows, one red and one blue
s = red:GetSurface()
s:Clear( 0xff, 0, 0, 0xff)
s:Flip()
s:Release()

s = blue:GetSurface()
s:Clear( 0, 0, 0xff, 0xff)
s:Flip()
s:Release()

-- Make windows visible
red:SetOpacity(0x80)
blue:SetOpacity(0x80)

-- Create event buffer to receive window events (mouse, keyboard, etc)
buffer = red:CreateEventBuffer()
blue:AttachEventBuffer(buffer)

grabbed = false
x = 0
y = 0
focus = nil

-- Main event processing loop
while true do
	buffer:WaitForEvent()
	event = buffer:GetEvent()

	if event.window_id == red:GetID() then
		focus = red
	elseif event.window_id == blue:GetID() then
		focus = blue
	end

	-- Any key exits the program
	if event.type == DWET_KEYDOWN then
		if event.key_symbol == DIKS_ESCAPE or
		   event.key_symbol == DIKS_SMALL_Q or
		   event.key_symbol == DIKS_CAPITAL_Q then
			break
		end

	-- Mouse button down grabs the window
	elseif event.type == DWET_BUTTONDOWN then
		grabbed = true
		x = event.cx
		y = event.cy
		focus:GrabPointer()
		focus:Raise()

	-- Mouse button up releases the window
	elseif event.type == DWET_BUTTONUP then
		grabbed = false
		focus:UngrabPointer()

	-- Mouse movement, moves the grabbed window
	elseif event.type == DWET_MOTION then
		if grabbed then
			focus:Move(event.cx-x, event.cy-y)
			x = event.cx
			y = event.cy
		end

	-- Mouse wheel, changes opacity
	elseif event.type == DWET_WHEEL then
		opacity = focus:GetOpacity() + event.step
		if opacity >= 0xff then opacity = 0xff end
		if opacity <= 0x00 then opacity = 0x01 end
		focus:SetOpacity(opacity)
	end
end
