
require 'directfb'

-- DFB Initialization
directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()
dfb:SetCooperativeLevel(DFSCL_NORMAL)

-- Surface creation, notice the SUM instead of OR
surface = dfb:CreateSurface {caps=DSCAPS_PRIMARY+DSCAPS_FLIPPING}
surface:Clear( 0x80, 0x80, 0x80, 0xff )

-- Font creation
font_path = 'DejaVuSans.ttf'
font = dfb:CreateFont(font_path, {height=30})

surface:SetFont(font)

-- Image creation
image = dfb:CreateImageProvider('lua.gif')
image_surf = dfb:CreateSurface(image:GetSurfaceDescription())
image:RenderTo(image_surf, nil)

surface:Blit(image_surf, nil, 100, 100)
surface:SetColor(0, 0, 0, 0xff)
surface:DrawString('DirectFB meets Lua', -1, 10, 10, DSTF_TOPLEFT)

surface:Flip(nil, 0)
