require 'directfb'

-- DFB Initialization
directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()
dfb:SetCooperativeLevel(DFSCL_EXCLUSIVE)

-- Surface creation, notice the SUM instead of OR
desc = {}
desc.flags = DSDESC_CAPS
desc.caps = DSCAPS_PRIMARY + DSCAPS_FLIPPING
surface = dfb:CreateSurface(desc)
surf1 = surface:GetSubSurface({x=450, y=450, w=100, h=100})
surf2 = surface:GetSubSurface({x=300, y=300, w=350, h=200})

-- Font creation
font_path = '/usr/share/fonts/TTF/DejaVuSans.ttf'
font = dfb:CreateFont(font_path, {flags=DFDESC_HEIGHT, height=30})

surf2:SetFont(font)

-- Image creation
image = dfb:CreateImageProvider('lua.gif')
image_surf = dfb:CreateSurface(image:GetSurfaceDescription())
image:RenderTo(image_surf, nil)

local x1,y1,t,jitter = 200, 200, 0
for i=1,200 do
	jitter = (math.random(10) - 5.5) / 5
	t = t + 0.001
	x1 = x1 + jitter
	y1 = y1 + jitter 

	surface:Clear( 0, 0, 0, 0xff )
	surf2:Clear( 0xff, 0xff, 0, 0xff)
	surf1:Clear( 0, 0, 0xff, 0xff)
	image_surf:SetSrcColorKey(0xff, 0xff, 0xff)
	surface:SetBlittingFlags(DSBLIT_SRC_COLORKEY)
	surface:Blit(image_surf, nil, 400+20*math.cos(2*3.14*t), 50+20*math.sin(2*3.14*t))

	surf2:SetColor(0x0, 0x0, 0x0, 0xff)
	surf2:DrawString('DirectFB meets Lua', -1, 10, 10, DSTF_TOPLEFT)

	surface:SetColor(0xff, 0, 0, 0xff)
	surface:FillRectangle(x1, y1, 100, 100)
	surface:Flip(nil, 0)
end

image:Release()
font:Release()
image_surf:Release()
surf1:Release()
surf2:Release()
surface:Release()
dfb:Release()
