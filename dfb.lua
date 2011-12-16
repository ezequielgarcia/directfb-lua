
require 'directfb'

-- DFB Initialization
directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()
dfb:SetCooperativeLevel(DFSCL_FULLSCREEN)

-- Surface creation, notice the SUM instead of OR
desc = {}
desc.flags = DSDESC_CAPS
desc.caps = DSCAPS_PRIMARY + DSCAPS_FLIPPING

surface = dfb:CreateSurface(desc)
surface:Clear( 0x80, 0x80, 0x80, 0xff )

-- Font creation
font_path = '/usr/share/fonts/TTF/DejaVuSans.ttf'
font = dfb:CreateFont(font_path, {flags=DFDESC_HEIGHT, height=30})

surface:SetFont(font)

-- Image creation
image = dfb:CreateImageProvider('lua.gif')
image_surf = dfb:CreateSurface(image:GetSurfaceDescription())
image:RenderTo(image_surf, nil)

surface:Blit(image_surf, nil, 100, 100)
surface:SetColor(0, 0, 0, 0xff)
surface:DrawString('DirectFB meets Lua', -1, 10, 10, DSTF_TOPLEFT)

surface:Flip(nil, 0)

--image:Release()
--font:Release()
--image_surf:Release()
--surface:Release()
--dfb:Release()
