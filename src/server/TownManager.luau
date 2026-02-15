local TownManager = {}

local SEED = 2026
local CHUNK_SIZE = 16
local VOXEL_SIZE = 4
local STUD_PER_CHUNK = CHUNK_SIZE * VOXEL_SIZE -- 64 studs

-- Grid Configuration
-- Towns are spaced roughly 20 chunks apart (1280 studs) on a grid
-- Max town size is 1200 studs (~19 chunks)
-- Radius is ~10 chunks. Margin 5 chunks (320 studs) to prevent overlap.
local TOWN_GRID_SIZE = 40 -- Increased to ~2560 studs spacing
local TOWN_MARGIN = 8

local TownPrefixes = {
	"Oak",
	"Pine",
	"Maple",
	"River",
	"Stone",
	"Iron",
	"Gold",
	"Silver",
	"Crystal",
	"Shadow",
	"Light",
	"North",
	"South",
	"East",
	"West",
	"High",
	"Low",
	"New",
	"Old",
	"Red",
	"Blue",
	"Green",
	"White",
	"Black",
}
local TownSuffixes = {
	"wood",
	"field",
	"haven",
	"ford",
	"burgh",
	"ton",
	"ville",
	"port",
	"view",
	"side",
	"valley",
	"hill",
	"mount",
	"lake",
	"creek",
	"spring",
}

export type TownData = {
	Name: string,
	CenterChunkX: number,
	CenterChunkZ: number,
	RadiusChunks: number, -- Radius in chunks
	SizeStuds: number, -- For reference
	Seed: number,
	GridX: number,
	GridZ: number,
}

-- Cache for generated town data
local townCache = {}

function TownManager.GetTownAt(cx: number, cz: number): TownData?
	local gridX = math.floor(cx / TOWN_GRID_SIZE)
	local gridZ = math.floor(cz / TOWN_GRID_SIZE)

	local key = gridX .. ":" .. gridZ

	local townData = townCache[key]

	if not townData then
		-- Deterministic generation for this grid cell
		-- Unique seed for this grid cell based on world seed
		local cellSeed = SEED + (gridX * 73856093) + (gridZ * 19349663)
		local rng = Random.new(cellSeed)

		-- 80% chance for a town in this grid cell
		-- Always generate at (0,0)
		local isOrigin = (gridX == 0 and gridZ == 0)

		if isOrigin or rng:NextNumber() > 0.2 then
			-- Valid town

			-- Calculate center
			-- Range within the grid: [margin, size - margin]
			local range = TOWN_GRID_SIZE - (2 * TOWN_MARGIN)
			if range < 1 then
				range = 1
			end

			local offsetX = rng:NextInteger(0, range)
			local offsetZ = rng:NextInteger(0, range)

			local centerX = (gridX * TOWN_GRID_SIZE) + TOWN_MARGIN + offsetX
			local centerZ = (gridZ * TOWN_GRID_SIZE) + TOWN_MARGIN + offsetZ

			-- Size: 500 to 1200 studs
			local sizeStuds = rng:NextInteger(500, 1200)

			if isOrigin then
				sizeStuds = 1000
				-- Force center to 0,0 for spawn town
				centerX = 0
				centerZ = 0
			end -- Good size for spawn
			-- Convert to chunks (radius is half size)
			local radiusChunks = math.ceil((sizeStuds / 2) / STUD_PER_CHUNK)

			-- Name
			local name = TownPrefixes[rng:NextInteger(1, #TownPrefixes)]
				.. TownSuffixes[rng:NextInteger(1, #TownSuffixes)]

			townData = {
				Name = name,
				CenterChunkX = centerX,
				CenterChunkZ = centerZ,
				RadiusChunks = radiusChunks,
				SizeStuds = sizeStuds,
				Seed = rng:NextInteger(1, 10000000),
				GridX = gridX,
				GridZ = gridZ,
			}
		else
			townData = { NoTown = true }
		end

		townCache[key] = townData
	end

	if townData.NoTown then
		return nil
	end

	-- Check if the given chunk (cx, cz) is within the town's radius
	local dist = math.sqrt((cx - townData.CenterChunkX) ^ 2 + (cz - townData.CenterChunkZ) ^ 2)

	if dist <= townData.RadiusChunks then
		-- Return a copy or just the reference? Reference is fine for reading
		-- Add distance info to the return?
		-- Let's return a new table with distance context if needed, but for now just data
		return townData
	end

	return nil
end

-- Check if a specific chunk is a valid spot for a structure
-- (e.g., inside town but not on a road)
function TownManager.GetStructurePlacement(cx: number, cz: number, townData: TownData)
	-- Deterministic logic for specific chunk
	-- local rng = Random.new(townData.Seed + (cx * 100) + cz) -- Unused

	-- Relative position
	local relX = cx - townData.CenterChunkX
	local relZ = cz - townData.CenterChunkZ

	-- Simple Grid layout
	-- Roads every 4 chunks? Or 2 chunks?
	-- 1 chunk = 64 studs.
	-- Roads every 2 chunks (128 studs) is spacious.
	-- Let's say main roads cross at center.

	local isRoad = (relX == 0) or (relZ == 0) or (math.abs(relX) % 3 == 0) or (math.abs(relZ) % 3 == 0)

	if isRoad then
		return "Road"
	end

	return "Plot"
end

return TownManager
