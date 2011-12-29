require 'directfb'

directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()
--dfb:SetCooperativeLevel('DFSCL_NORMAL')

-- Get layer
layer = dfb:GetDisplayLayer(0)

video = dfb:CreateVideoProvider('/dev/video0')
--vsurf = dfb:CreateSurface(video:GetSurfaceDescription())

desc = {}
desc.posx = 0;
desc.posy = 0;
desc.width = 100
desc.height = 100

window  = layer:CreateWindow(desc)
wsurf = window:GetSurface()

window:SetOpacity(0xff)
video:PlayTo(wsurf, nil, 0, 0)	
