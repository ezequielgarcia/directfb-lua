
require 'directfb'

-- DFB Initialization --
directfb.DirectFBInit()
local dfb = directfb.DirectFBCreate()

local function drawImage(path, surface, rect)
	print('Drawing image: ',path)

	local image = dfb:CreateImageProvider(path)
	local imageDesc = image:GetImageDescription()
	local surfDesc = image:GetSurfaceDescription()
	local surf = dfb:CreateSurface(surfDesc)
	image:RenderTo(surf)

	if imageDesc.caps == DICAPS_COLORKEY then
		local r,g,b = imageDesc.colorkey_r, imageDesc.colorkey_g, imageDesc.colorkey_b
		print(' - Image has colorkey: ',r,g,b)
		surf:SetSrcColorKey(r,g,b)
		surface:SetBlittingFlags('DSBLIT_SRC_COLORKEY')
	elseif imageDesc.caps == DICAPS_ALPHACHANNEL then
		print(' - Image has an alpha channel')
		surface:SetBlittingFlags('DSBLIT_BLEND_ALPHACHANNEL')
	end

	print(' - Blitting')
	surface:StretchBlit(surf, nil, rect)
end

-- Display Surface --
surface = dfb:CreateSurface {caps='DSCAPS_PRIMARY|DSCAPS_FLIPPING'}
surface:Clear( 0x80, 0x80, 0x80, 0xff )
local w,h = surface:GetSize()

-- Background --
drawImage('res/background.jpg', surface)

-- PNG with alphachannel
drawImage('res/elephant.png', surface, {x=w/2, y=h/2, w=w/2, h=h/2})

-- GIF with colorkey
drawImage('res/tux.gif', surface, {x=w/10, y=h/2, w=w/4, h=h/4})

-- GIF without colorkey
drawImage('res/lua.gif', surface, {x=w/10, y=h/10, w=w/4, h=h/4})

-- Done, now we can flip --
surface:Flip()
