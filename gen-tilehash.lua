-- intended to be run with lua 5.3 from the LuaScript plug-in for Notepad++

--[[ Square.as
private static const LOOKUP:Vector.<int> = new <int>[26171,44789,20333,70429,98257,59393,33961];
private static function hash(param1:int, param2:int) : int {
	var _loc3_:int = LOOKUP[(param1 + param2) % 7];
	var _loc4_:* = (param1 << 16 | param2) ^ 81397550;
	_loc4_ = int(_loc4_ * _loc3_ % 65535);
	return _loc4_;
}
]]

-- hash function
-- fun fact: the large-scale diagonal lines in the result
-- are due to some of the constants in this lut being shit
-- 2 and 6 create long streaks
-- 7 creates runs of two of the same value
-- 1, 3, 4, 5 are coarse and noisy but spike every n
-- but, this hash is interesting because it's bad
local LOOKUP = {26171,44789,20333,70429,98257,59393,33961}
local function hash(x, y)
	-- the + 1 is to account for lua's 1-indexed array
	return LOOKUP[(x+y) % 7 + 1] * (((x << 16) | y) ~ 81397550) % 65535
end
-- local function hash(x, y) return math.random(65536) end
-- for i = 1,#LOOKUP do LOOKUP[i]=math.random(1<<17)|1 end

-- rasterization
local function pixmap32(w, h, func)
	local rope = {}
	for y = 0, h-1 do
		for x = 0, w-1 do
			local value = func(x, y)
			table.insert(rope, string.char(value >> 24 & 255))
			table.insert(rope, string.char(value >> 16 & 255))
			table.insert(rope, string.char(value >>  8 & 255))
			table.insert(rope, string.char(value       & 255))
		end
	end
	
	return table.concat(rope)
end

-- old experi
local function pixmap16al(w, h, func)
	local rope = {}
	for y = 0, h-1 do
		for x = 0, w-1 do
			local value = func(x, y)
			table.insert(rope, string.char((value >> 12 & 15) + 97))
			table.insert(rope, string.char((value >>  8 & 15) + 97))
			table.insert(rope, string.char((value >>  4 & 15) + 97))
			table.insert(rope, string.char((value       & 15) + 97))
		end
	end
	
	return table.concat(rope)
end

local function savepixmap(w, h, path, func)
	local data = pixmap32(w, h, func)
	
	local magickpath = string.format([[magick -size %sx%s -depth 8 rgba:- %s]], w, h, path)
	local magick = io.popen(magickpath, "wb")
	magick:write(data)
	magick:flush()
	
	return #data, magick:close()
end

-- testing
-- local tiles = {"█", "░", "▒", "▓", " "}
local w = 256
local h = 512
local outpath = npp:GetCurrentDirectory() .. [[\hash512.png]]

local len, success, reason, code = savepixmap(w, h, outpath, function(x, y)
	return hash(x*2, y) << 16 | hash(x*2+1, y)
end)
print(len, success, reason, code)
if success then io.popen(outpath) end -- preview image immediately

-- local file = io.open(outpath, "wb")

-- file:write(pixmap32(16, 16, function(x, y)
	-- return hash(x*2, y) << 16 | hash(x*2+1, y)
-- end))
-- for i = 0, 255 do
	-- file:write(string.char(i>>4))
	-- file:write(string.char(i&15))
-- end

-- file:write[[(define hashdata (string-append]]
-- file:write(pixmap16al(512, 512, function(x, y)
	-- return hash(x, y)
-- end):gsub(string.rep(".", 1023), [[ "%1"]]))
-- file:write[[))]]

-- file:flush()
-- file:close()

-- print(hash(4, 0))
