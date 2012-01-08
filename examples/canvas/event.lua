
------------------
-- NCLua event  --
------------------
--
-- Pure lua implementation *loosely based* on NCLua event module.
-- The api interface is here:
-- http://www.lua.inf.puc-rio.br/~francisco/nclua/referencia/event.html
--

require 'directfb'

-- DFB Initialization
directfb.DirectFBInit()
local dfb = directfb.DirectFBCreate()
local input = dfb:CreateInputEventBuffer('DICAPS_KEYS', 'DFB_FALSE')

local MAX_STEP=100
local listeners = {}
local timers = {}

local keys = {}
keys[DIKI_0] 		= '0'
keys[DIKI_1] 		= '1'
keys[DIKI_2] 		= '2'
keys[DIKI_3] 		= '3'
keys[DIKI_4] 		= '4'
keys[DIKI_5] 		= '5'
keys[DIKI_6] 		= '6'
keys[DIKI_7] 		= '7'
keys[DIKI_8]	 	= '8'
keys[DIKI_9] 		= '9'
keys[DIKI_ESCAPE] 	= 'escape'
keys[DIKI_LEFT] 	= 'left'
keys[DIKI_RIGHT] 	= 'right'
keys[DIKI_UP] 		= 'up'
keys[DIKI_DOWN] 	= 'down'
keys[DIKI_ENTER] 	= 'enter'
keys[DIKI_SPACE] 	= 'space'

local function translate(e)
	local evt = {}
	if e.type == DIET_KEYPRESS then 
		evt.class = 'key'
		evt.type = 'press'
		evt.key = keys[e.key_id]
	elseif e.type == DIET_KEYRELEASE then 
		evt.class = 'key'
		evt.type = 'release'
		evt.key = keys[e.key_id]
	end
	return evt
end

local function checkTimers(step)
	for k,v in pairs(timers) do
		v.timeLeft = v.timeLeft - step
		-- If timer is expired then we remove 
		-- it from table, and call the expiration
		-- function (through __call).
		if v.timeLeft <= 0 then 
			timers[k] = nil
			v() 
		end
	end
end

local function main()
	local evt, e, status, err
	local currStep = MAX_STEP

	while true do

		-- Wait for an event
		while true do
			-- Check expired timers
			status, err = pcall(input.WaitForEventWithTimeout, input, 0, currStep)
			if status then
				break
			end
			checkTimers(currStep)
		end

		-- Get all events, until buffer is empty
		while true do
			status, e = pcall(input.GetEvent, input)
			if not status then
				break
			end

			-- Translate event
			evt = translate(e)

			for k,f in pairs(listeners) do
				f(evt)
			end
		end
	end
end

local table, coroutine, setmetatable, print = table, coroutine, setmetatable, print
local co = coroutine.create(main)

module('event')

function register(f) 
	table.insert(listeners,f)
end

function timer(time,fun)
	local t = {timeLeft=time, __call=fun}
	setmetatable(t,t)
	table.insert(timers,t)
end

-- Will block execution, so it must be called at last
function start()
	if coroutine.status(co) == 'suspended' then
		coroutine.resume(co)
	end
end

-- Since start() blocks, this stop() function can only be accesed 
-- from a registered listener. When stopped, execution resumes 
-- from start(). 
-- start() should be the last instruction, except from cleaning
-- code, so app will terminate.
function stop()
	if coroutine.status(co) == 'running' then
		coroutine.yield()
	end
end
