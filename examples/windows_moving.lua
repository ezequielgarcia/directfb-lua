
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
s:Release()

s = blue:GetSurface()
s:Clear( 0, 0, 0xff, 0xff)
s:Release()

-- Make windows visible
red:SetOpacity(0xff)
blue:SetOpacity(0x80)

-- Create event buffer to receive window events (mouse, keyboard, etc)
buffer = red:CreateEventBuffer()
blue:AttachEventBuffer(buffer)

grabbed = false
x = 0
y = 0
focus = nil

-- Main event processing loop
print('Press any key on the window to exit.')
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
		break
	-- Mouse button down grabs the window
	elseif event.type == DWET_BUTTONDOWN then
		grabbed = true
		x = event.cx
		y = event.cy
		focus:GrabPointer()

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
	end
end
