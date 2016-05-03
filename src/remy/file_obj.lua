-- Remy - File object
-- By m1cr0man
-- License: MIT

local File = {
	name = nil,
	path = nil,
	content_type = nil,
	move_to = nil,
	handle = nil
}

-- Efficiency function for saving the temp file
-- somewhere else instead of reading & writing it
function File:move_to(path)
	local success, err = os.rename(self.path, path)
	if not success then return success, err end
	self.path = path
	return true
end

function File.new(name, content_type)
	local new_file = {
		name = name,
		path = os.tmpname(),
		content_type = content_type
	}

	-- We will want a handle to write to
	-- when we create the file
	new_file.handle = io.open(new_file.path, "w")
	setmetatable(new_file, {__index = File})

	return new_file
end

return File
