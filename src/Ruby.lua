local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local GithubLoader = require(`./GithubLoader`)

local Ruby = {}
Ruby.Plugin = nil -- The `plugin` instance
Ruby.Exporter = nil -- The required SerializationTools Writing/Main.lua Mod
Ruby.Folder = nil -- The folder containing the SerializationTools, stored in CoreGui
Ruby.Button = nil -- The plugin button
Ruby.FetchSourceButton = nil -- The UI button used to perform a checkup or a refetch
Ruby.SerializerAPI = nil -- The API of SerializationTools

Ruby.BackgroundChecks = false -- Whether background checks are enabled
Ruby.Active = false -- Whether the plugin is currently enabled
Ruby.Outdated = false -- Whether the SerializationTools are outdated

Ruby.LoadingIDs = { -- An array of image IDs for a loading GIF
	138016358530888, 70597296726422, 127832681223670, 83695390279728, 133089274035459, 84382514433800, 
	78784862813485, 112194325401656, 139036767631117, 102076830057398, 131568282874164
}

function Ruby.encode(dir: Folder?)
	local encode = {}
	for _,file: Instance in (dir and dir:GetChildren() or Ruby.Folder:GetChildren()) do
		if file:IsA(`LuaSourceContainer`) then
			table.insert(encode, {
				Class = file.ClassName,
				Source = file.Source,
				Name = file.Name,
			})
		elseif file:IsA(`Folder`) then
			table.insert(encode, {
				Class = file.ClassName,
				Name = file.Name,
				Contents = Ruby.encode(file)
			})
		end
	end

	return HttpService:JSONEncode(encode)
end

function Ruby.decode(str: string)
	local decoded = HttpService:JSONDecode(str)
	for _,file in (decoded) do
		if file.Contents then
			file.Contents = Ruby.decode(file.Contents)
		end
	end

	return decoded
end

function Ruby.build(tbl: {[number]: {}}, at: Instance)
	for _,file in (tbl) do
		local inst = Instance.new(file.Class)
		inst.Name = file.Name
		if file.Source then
			inst.Source = file.Source
		end
		if file.Contents then
			Ruby.build(file.Contents, inst)
		end
		inst.Parent = at
	end

	return at
end

function Ruby.backgroundChecks(enabled: boolean)
	if Ruby.BackgroundChecks == enabled then return end

	Ruby.BackgroundChecks = enabled
	if Ruby.BackgroundChecks then
		task.spawn(function()
			while Ruby.BackgroundChecks do
				task.wait(10*60)
				if not Ruby.BackgroundChecks then break end
				Ruby.checkForUpdate()
			end
		end)
	end
end

function Ruby.checkForUpdate(noPrint: boolean?)
	--if (not Ruby.Root or not Ruby.Root.Parent) then 
	--	Ruby.backgroundChecks(false) 
	--	return nil
	--end

	local recent = Ruby.getLatestUpdate()
	if recent == nil then return nil end

	if recent ~= Ruby.Plugin:GetSetting(`Date`) then
		if not Ruby.Outdated and not noPrint then
			warn(`Ruby :: Detected new SerializationTools commit`)
		end
		Ruby.Outdated = true
		Ruby.updateStatus()
		return true
	end

	return false
end

function Ruby.updateStatus()
	if Ruby.FetchSourceButton then
		Ruby.FetchSourceButton.BackgroundColor3 = Ruby.Outdated and Color3.fromRGB(255, 38, 52) or Color3.fromRGB(0, 0, 0)
	end
end

function Ruby.getFetchSourceButton()
	local possible = CollectionService:GetTagged(`RubySerializerFetchSourceButton`)
	for _,button in (possible) do
		if button:IsA(`TextButton`) and button:IsDescendantOf(CoreGui) then
			Ruby.FetchSourceButton = button
			return button
		end
	end

	return nil
end

function Ruby.getLatestUpdate()
	local success, data = GithubLoader.call(
		`https://api.github.com/repos/MoonstoneSkies/InfiltrationEngine-Custom-Missions/commits?path=Plugins/src/SerializationTools&per_page=1`
	)
	if not success then warn(`Ruby :: Checking SerializationTools failed {data}`) return end
	data = HttpService:JSONDecode(data)

	local lastUpdate = data[1].commit.committer.date
	return lastUpdate
end

function Ruby.fetch()
	local loaded = false do
		task.spawn(function()
			local prevImg = Ruby.Button.Icon
			while not loaded do
				for i,v in (Ruby.LoadingIDs) do
					Ruby.Button.Icon = `rbxassetid://{v}`
					task.wait(0.08)
				end
			end
			Ruby.Button.Icon = prevImg
		end)
	end

	local folder = workspace:FindFirstChild(`SerializationToolsDebug`) and workspace.SerializationToolsDebug:Clone() or GithubLoader.repo(
		`https://api.github.com/repos/MoonstoneSkies/InfiltrationEngine-Custom-Missions/contents/Plugins/src/SerializationTools`, 
		`SerializationToolsRuby`, 
		true
	)
	folder.Archivable = false
	folder.Name = `SerializationToolsRuby`
	folder.Parent = CoreGui

	local mainWriting = folder:FindFirstChild(`Writing`) and folder.Writing:FindFirstChild(`Main`)
	local mainAPI = folder:FindFirstChild(`API`) and folder.API:FindFirstChild(`Main`)
	if not mainWriting or not mainAPI then 
		warn(`Ruby :: {not mainWriting and `Writing/` or `API/`}Main.lua is missing`) 
		loaded = true
		folder:Destroy()
		return 
	end

	Ruby.Folder = folder
	Ruby.Plugin:SetSetting(`Date`, `recent`)
	task.spawn(function()
		Ruby.Plugin:SetSetting(`Date`, Ruby.getLatestUpdate(folder))
	end)

	local injections = {
		[`local%s+readbackEnabled%s*=%s*FeatureCheck%("Readback"%)%s*==%s*true`] = 
		[[
		local fetchSourceButton = Button({
			Size = UDim2.new(0, 200, 0, 30),
			Enabled = module.EnabledState,
			Position = UDim2.new(0, apiDevEnabled and 270 or 50, 1, -50),
			AnchorPoint = Vector2.new(0, 1),
			Text = `Ruby: Check`,
		})
		fetchSourceButton:AddTag(`RubySerializerFetchSourceButton`)
		]],

		[`(%s*Create%(%\"ScrollingFrame\"%s*,)`] = 
		[[
		fetchSourceButton,
		]],
	}
	local modified = mainWriting.Source
	for pattern,inject in (injections) do
		modified = modified:gsub(pattern, inject .. `\n%1`, 1)
	end
	mainWriting.Source = modified
	task.wait(0.5)
	if Ruby.Exporter then Ruby.Exporter.Clean() end
	Ruby.SerializerAPI = require(mainAPI)
	Ruby.SerializerAPI.Init()
	Ruby.Exporter = require(mainWriting)
	Ruby.Plugin:SetSetting(`Cache`, Ruby.encode(folder))
	task.wait(0.5)
	loaded = true
	Ruby.backgroundChecks(true)
end

function Ruby.refetch()
	Ruby.Active = false
	Ruby.Plugin:Deactivate()
	Ruby.Folder:Destroy()
	Ruby.fetch()
end

return Ruby