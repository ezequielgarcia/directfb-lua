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

x1 = 200
y1 = 200
while true do
	x1 = x1 + (math.random(1000) - 500) / 1000
	y1 = y1 + (math.random(1000) - 500) / 1000

	print (tostring(x1) .. "," .. tostring(y1))
	surface:Clear( 0, 0, 0, 0xff )
	surface:SetColor(0xff, 0, 0, 0xff)
	surface:FillRectangle( x1, y1, 100, 100)
	surface:Flip(nil, 0)
end
