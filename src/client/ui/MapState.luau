local visitedChunks = {} -- "x:z" -> true
local listeners = {}

local MapState = {}

function MapState.addVisited(cx, cz)
	local key = cx .. ":" .. cz
	if not visitedChunks[key] then
		visitedChunks[key] = true
		
		-- Notify listeners (for efficient updates if needed)
		for _, callback in ipairs(listeners) do
			callback(cx, cz)
		end
	end
end

function MapState.isVisited(cx, cz)
	return visitedChunks[cx .. ":" .. cz] == true
end

function MapState.subscribe(callback)
	table.insert(listeners, callback)
	return function()
		-- Unsubscribe logic
		for i, cb in ipairs(listeners) do
			if cb == callback then
				table.remove(listeners, i)
				break
			end
		end
	end
end

return MapState
