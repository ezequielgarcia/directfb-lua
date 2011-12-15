
require 'directfb'

-- DFB Initialization
directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()
dfb:SetCooperativeLevel(DFSCL_FULLSCREEN)

-- Get layer
layer = dfb:GetDisplayLayer(0)

-- Create window
desc = {}
desc.flags = DWDESC_POSX + DWDESC_POSY + DWDESC_WIDTH + DWDESC_HEIGHT + DWDESC_SURFACE_CAPS
desc.posx = 100
desc.posy = 100
desc.width = 100
desc.height = 100
desc.surface_caps = DSCAPS_FLIPPING
w1 = layer:CreateWindow(desc)
w2 = layer:CreateWindow(desc)
w3 = layer:CreateWindow(desc)

-- Get windows surface
s1 = w1:GetSurface()
s2 = w2:GetSurface()
s3 = w3:GetSurface()

s1:Clear( 0xff, 0, 0, 0xff)
s2:Clear( 0, 0xff, 0, 0xff)
s3:Clear( 0, 0, 0xff, 0xff)

s1:Flip(nil, 0)
s2:Flip(nil, 0)
s3:Flip(nil, 0)

w1:MoveTo(100, 100)
w2:MoveTo(120, 120)
w3:MoveTo(150, 150)

w1:SetOpacity(0x80)
w2:SetOpacity(0x80)
w3:SetOpacity(0x80)
