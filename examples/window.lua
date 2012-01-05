
require 'directfb'

-- DFB Initialization
directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()
dfb:SetCooperativeLevel('DFSCL_NORMAL')

-- Get layer
layer = dfb:GetDisplayLayer(0)

-- Create window
w1 = layer:CreateWindow {width=300, height=300, surface_caps='DSCAPS_FLIPPING'}
w2 = layer:CreateWindow {width=300, height=300, surface_caps='DSCAPS_FLIPPING'}

-- Get windows surface
s1 = w1:GetSurface()
s2 = w2:GetSurface()

s1:Clear( 0xff, 0, 0, 0xff)
s2:Clear( 0, 0xff, 0, 0xff)

w1:MoveTo(100, 100)
w2:MoveTo(150, 150)

w1:SetOpacity(0x80)
w2:SetOpacity(0x80)
