
require 'directfb'

directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()

primary = dfb:CreateSurface {caps='DSCAPS_PRIMARY|DSCAPS_FLIPPING'}

-- Render tux image to tux surface
prov = dfb:CreateImageProvider('lua.gif')
desc = prov:GetSurfaceDescription();
tux = dfb:CreateSurface(desc)
prov:RenderTo(tux)
prov:Release();

-- Get keyboard input device
keyboard = dfb:GetInputDevice(0)

local x,y = 100, 100
-- Loop through until the escape key is pressed.
while keyboard:GetKeyState('DIKI_ESCAPE') == DIKS_UP do

	-- Clear surface
	primary:Clear( 0x80, 0x80, 0x80, 0xff )
	
	-- Draw tux
	primary:Blit(tux, nil, x, y)
	primary:Flip()

	if keyboard:GetKeyState('DIKI_LEFT') == DIKS_DOWN then
		x = x - 1 
	end

	if keyboard:GetKeyState('DIKI_RIGHT') == DIKS_DOWN then
		x = x + 1 
	end

	if keyboard:GetKeyState('DIKI_DOWN') == DIKS_DOWN then
		y = y + 1 
	end

	if keyboard:GetKeyState('DIKI_UP') == DIKS_DOWN then
		y = y - 1 
	end
end


