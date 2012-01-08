require 'directfb'

directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()

-- Get layer
layer = dfb:GetDisplayLayer(0)

video = dfb:CreateVideoProvider('/dev/video0')
vdesc = video:GetSurfaceDescription()

window  = layer:CreateWindow {width=vdesc.width, height=vdesc.height}
wsurf = window:GetSurface()

window:SetOpacity(0xff)
video:PlayTo(wsurf)
