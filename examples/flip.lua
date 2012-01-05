require 'directfb'

MAX = 1000

directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()

primary = dfb:CreateSurface {caps='DSCAPS_PRIMARY|DSCAPS_DOUBLE'}

primary:Clear(0, 0, 0, 0 );
primary:Flip(nil, 0 );
primary:Clear(0xff, 0xff, 0xff, 0xff );

start = os.time()

flips = MAX
while flips > 0 do
	primary:Flip(nil, 'DSFLIP_WAITFORSYNC')
	flips = flips - 1
end

stop = os.time()

print('Fps reached ' .. MAX/(stop-start) .. ' fps')
