
require 'directfb'

-- DFB Initialization
directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()
dfb:SetCooperativeLevel(DFSCL_FULLSCREEN)

-- Get layer
layer = dfb:GetDisplayLayer(0)

-- Create window
desc = {}
desc.flags = DWDESC_WIDTH + DWDESC_HEIGHT + DWDESC_SURFACE_CAPS
desc.width = 100
desc.height = 100
desc.surface_caps = DSCAPS_FLIPPING
w1 = layer:CreateWindow(desc)
w2 = layer:CreateWindow(desc)

-- Get windows surface
s1 = w1:GetSurface()
s2 = w2:GetSurface()

s1:Clear( 0xff, 0, 0, 0xff)
s2:Clear( 0, 0xff, 0, 0xff)

w1:MoveTo(100, 100)
w2:MoveTo(150, 150)

w1:SetOpacity(0x80)
w2:SetOpacity(0x80)

--s1:Release()
--s2:Release()
--w1:Release()
--w2:Release()
--layer:Release()
--dfb:Release()
