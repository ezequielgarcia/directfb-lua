------------------
-- Game of Life --
------------------
--
-- Based on Game of Life implementation from RosettaCode,
-- check http://rosettacode.org/wiki/Conway's_Game_of_Life#Lua
--

require 'event'
require 'canvas'

local m = 100
local w, h = canvas:attrSize()
local cell_width = math.floor((w) / m)
local cell_height = math.floor((h) / m)
local cell = {}
 
function evolve(cell)
    local m = #cell
    local cell2 = {}
    for i = 1, m do
        cell2[i] = {}
        for j = 1, m do
            cell2[i][j] = cell[i][j]
        end
    end
 
    for i = 1, m do
        for j = 1, m do
            local count
 
            if cell2[i][j] == 0 then 
                count = 0 
            else 
                count = -1 
            end
 
            for x = -1, 1 do
                for y = -1, 1 do
                    if i+x >= 1 and 
                       i+x <= m and 
                       j+y >= 1 and 
                       j+y <= m and cell2[i+x][j+y] == 1 then 
 
                           count = count + 1 
                    end
                end
            end
 
            if count < 2 or count > 3 then 
                cell[i][j] = 0 
            end
 
            if count == 3 then 
                cell[i][j] = 1 
            end
        end
    end
 
    return cell
end    
 
function birth(i,j)
    canvas:attrColor('black')
    canvas:drawRect('fill', i * cell_width, j * cell_height, cell_width, cell_height )
end
 
function death(i,j)
    canvas:attrColor('white')
    canvas:drawRect('fill', i * cell_width, j * cell_height, cell_width, cell_height )
    canvas:attrColor('black')
    canvas:drawRect('frame', i * cell_width, j * cell_height, cell_width, cell_height )
end
 
function refresh()
 
    for i=1,m do
        for j=1,m do
            if cell[i][j] == 1 then 
				birth(i,j)
			else 
				death(i,j) 
			end
        end
    end    
 
    canvas:flush()
 
    cell = evolve(cell)

	event.timer(0, refresh)
end
 
canvas:attrColor('white')
canvas:drawRect('fill', 0, 0, w, h)
 
for i = 1, m do
    cell[i] = {}
    for j = 1, m do
        cell[i][j] = 0
    end
end
 
for j=1,m do
    cell[j][m/2] = 1
end

-- Stop handler
event.register(function(evt) 
				if evt.class == 'key' and evt.type == 'press' and evt.key == 'escape' then
					event.stop()
				end
				end)

refresh()
event.start()
