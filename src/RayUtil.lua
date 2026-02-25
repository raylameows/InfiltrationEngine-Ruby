local RayUtil = {}

-- Gets a folder from the designated parent, or creates one if necessary
function RayUtil.getFolder(parent: Instance, name: string, optional: boolean)
	local folder = parent:FindFirstChild(name)
	if not folder and not optional then
		folder = Instance.new(`Folder`)
		folder.Name = name
		folder.Parent = parent
	end

	return folder
end

return RayUtil