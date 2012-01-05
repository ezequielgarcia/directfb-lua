--
-- This example is based in df_andi.c contained in the DirectFB distribution.
--

require 'directfb'

local bugs = {}
local dfb, keybuffer, primary, xres, yres, font, fontheight, provider, sprite, desc, fps, frame, temp

local step = 0.0001
local timestep = 0.0
local temp = 0

fps = 0

-- Draw the population string in upper left corner
local function drawPopulation()

	primary:SetColor(0, 0, 60, 0xff)
	primary:FillRectangle(0, 0, 640, fontheight+5)

	primary:SetColor(180, 200, 255, 0xff)
	primary:DrawString('Bug population: ' .. #bugs, -1, 10, 0, 'DSTF_LEFT | DSTF_TOP' )

	primary:SetColor(190, 210, 255, 0xff )
	primary:DrawString('FPS: ' .. math.floor(fps), -1, 300, 0, 'DSTF_LEFT | DSTF_TOP')

	primary:SetColor(255, 210, 120, 0xff )
	primary:DrawString('Temp: ' .. math.floor(temp), -1, 500, 0, 'DSTF_LEFT | DSTF_TOP')
end

local function drawBugs()

	primary:SetBlittingFlags('DSBLIT_SRC_COLORKEY')

	for k,v in pairs(bugs) do
		primary:Blit(sprite, nil, v.x, v.y );
	end
end

local function moveBugs()

	for k,v in pairs(bugs) do

		temp = v.vx*v.vx + v.vy*v.vy

		-- TODO: next frame
		v.x = v.x + v.vx*timestep
		v.y = v.y + v.vy*timestep

		if v.x > xres or v.x < 0 then v.vx = -v.vx end
		if v.y > yres or v.y < 0 then v.vy = -v.vy end
		
	end

end

local function spawn(count)
	for i=1,count do
		table.insert(bugs, {x=xres/2, y=yres/2, vx=math.random(5)-3, vy=math.random(5)-3})
	end
end

-- DFB Initialization
directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()

-- Create input buffer
keybuffer = dfb:CreateInputEventBuffer(DICAPS_KEYS, DFB_FALSE)

-- Create primary surface, double buffered
primary = dfb:CreateSurface {caps='DSCAPS_PRIMARY|DSCAPS_DOUBLE'}
xres, yres = primary:GetSize()

-- load font
font = dfb:CreateFont('DejaVuSans.ttf', {height=24})
fontheight = font:GetHeight()
primary:SetFont(font)

-- load animation
provider = dfb:CreateImageProvider('bug.gif')
sprite = dfb:CreateSurface(provider:GetSurfaceDescription())
provider:RenderTo(sprite, nil)

-- white color key
sprite:SetSrcColorKey(0xff, 0xff, 0xff)

-- load background, (I hope) GC will take care of previous provider
provider = dfb:CreateImageProvider('background.jpg')
desc = provider:GetSurfaceDescription()
desc.width = xres
desc.height = yres
background = dfb:CreateSurface(desc)
provider:RenderTo(background, nil)

spawn(25)

frame = 1
timestep = 0.0
local start = os.time()
local now, prev = start, start
-- Main loop
while not quit do

	primary:SetBlittingFlags('DSBLIT_NOFX')
        
	primary:Blit(background, nil, 0, 0)

	moveBugs()

	drawBugs()

	drawPopulation()
          
	primary:Flip(nil, 0)

	now = os.time()
	if now - prev > 0 then
		fps = frame / (now - start)
		prev = now
	end
	frame = frame + 1
	timestep = timestep + step
end
