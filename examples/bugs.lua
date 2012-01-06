--
-- This example is based in df_andi.c contained in the DirectFB distribution.
--

require 'directfb'

local bugs = {}
local dfb, keybuffer, primary, xres, yres, font, fontheight, provider, sprite, w, h, desc, fps, frame, temp

local step = 0.0001
local timestep = 0.0
local temp = 0

fps = 0

math.randomseed(os.time())

-- Draw the population string in upper left corner
local function drawPopulation()

	primary:SetColor(0, 0, 60, 0xff)
	primary:FillRectangle(0, 0, 640, fontheight+5)

	primary:SetColor(180, 200, 255, 0xff)
	primary:DrawString('Bug population: ' .. #bugs, -1, 10, 0, 'DSTF_LEFT | DSTF_TOP' )

	primary:SetColor(190, 200, 255, 0xff )
	primary:DrawString('FPS: ' .. math.floor(fps), -1, 300, 0, 'DSTF_LEFT | DSTF_TOP')

	primary:SetColor(255, 120, 120, 0xff )
	primary:DrawString('Temp: ' .. math.floor(temp), -1, 500, 0, 'DSTF_LEFT | DSTF_TOP')
end

local function stepBugs()

	primary:SetBlittingFlags('DSBLIT_SRC_COLORKEY')
	primary:SetColor(0, 0, 0, 0xff )

	temp = 0
	for k,v in pairs(bugs) do

		-- Get next pos
		v.x = v.x + v.vx*timestep
		v.y = v.y + v.vy*timestep

		if (v.x+w) > xres or v.x < 0 then v.vx = -v.vx end
		if (v.y+h) > yres or v.y < 0 then v.vy = -v.vy end

		-- Get temp
		temp = temp + v.vx*v.vx + v.vy*v.vy

		-- Blit this bug
		primary:Blit(sprite, nil, v.x, v.y );

		-- Draw speed line
		primary:DrawLine(v.x+w/2, v.y+h/2, v.x+w/2+v.vx*5, v.y+h/2+v.vy*5)
	end
	temp = temp/#bugs
end

local function destroy(count)
	for i=1,count do
		table.remove(bugs)
	end
end

local function create(count)
	local angle
	for i=1,count do
		angle = math.random(2*math.pi*100)/100
		table.insert(bugs, {x=xres/2, y=yres/2, vx=10*math.cos(angle), vy=10*math.sin(angle)})
	end
end

-- DFB Initialization
directfb.DirectFBInit()
dfb = directfb.DirectFBCreate()

-- Create input buffer
keybuffer = dfb:CreateInputEventBuffer('DICAPS_KEYS', 'DFB_FALSE')

-- Create primary surface, double buffered
primary = dfb:CreateSurface {caps='DSCAPS_PRIMARY|DSCAPS_DOUBLE'}
xres, yres = primary:GetSize()

-- load font
font = dfb:CreateFont('DejaVuSans.ttf', {height=24})
fontheight = font:GetHeight()
primary:SetFont(font)

-- load animation
provider = dfb:CreateImageProvider('bug.gif')
desc = provider:GetSurfaceDescription()
w,h = desc.width, desc.height
sprite = dfb:CreateSurface(desc)
provider:RenderTo(sprite)

-- white color key
sprite:SetSrcColorKey(0xff, 0xff, 0xff)

-- load background, (I hope) GC will take care of previous provider
provider = dfb:CreateImageProvider('background.jpg')
desc = provider:GetSurfaceDescription()
desc.width = xres
desc.height = yres
background = dfb:CreateSurface(desc)
provider:RenderTo(background)

create(10)

frame = 1
timestep = 0.0
local start = os.time()
local now, prev = start, start
-- Main loop
while not quit do

	-- FIXME: 
	-- This is a little hack, to be able to use GetEvent, and 
	-- similar functions that fail on non-fatal conditions
	local status, event = pcall(keybuffer.GetEvent, keybuffer)
	if status then
		if event.type == DIET_KEYPRESS then
			-- Terminate app
			if event.key_symbol == DIKS_ESCAPE or
			   event.key_symbol == DIKS_SMALL_Q or
			   event.key_symbol == DIKS_CAPITAL_Q then

				quit = true

			-- Increase bug population
			elseif event.key_symbol == DIKS_CURSOR_DOWN then
				create(10)

			-- Decrease bug population
			elseif event.key_symbol == DIKS_CURSOR_UP then
				destroy(10)
			end
		end
	end

	primary:SetBlittingFlags('DSBLIT_NOFX')
        
	primary:Blit(background)

	stepBugs()

	drawPopulation()
          
	primary:Flip()

	now = os.time()
	if now - prev > 0 then
		fps = frame / (now - start)
		prev = now
	end
	frame = frame + 1
	timestep = timestep + step
end
