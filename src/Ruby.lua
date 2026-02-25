local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local GithubLoader = require(`./GithubLoader`)

local Ruby = {}
Ruby.RubyPluginFolder = nil
Ruby.Button = nil
Ruby.Exporter = nil
Ruby.Root = nil
Ruby.FetchSourceButton = nil
Ruby.BackgroundChecks = false
Ruby.Outdated = false
Ruby.LoadingIDs = {
	138016358530888, 70597296726422, 127832681223670, 83695390279728, 133089274035459, 84382514433800, 
	78784862813485, 112194325401656, 139036767631117, 102076830057398, 131568282874164
}

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
	if (not Ruby.Root or not Ruby.Root.Parent) then 
		Ruby.backgroundChecks(false) 
		return nil
	end
	
	local recent = Ruby.getLatestUpdate(Ruby.Root)
	if recent == nil then return nil end
	
	if recent ~= Ruby.Root:GetAttribute(`Date`) then
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
		if button:IsA(`TextButton`) and button.Text == `Fetch Source` and button:IsDescendantOf(CoreGui) then
			Ruby.FetchSourceButton = button
			return button
		end
	end
	
	return nil
end

function Ruby.getLatestUpdate(serializer: Folder)
	local success, data = GithubLoader.call(
		serializer,
		`https://api.github.com/repos/MoonstoneSkies/InfiltrationEngine-Custom-Missions/commits?path=Plugins/src/SerializationTools&per_page=1`
	)
	if not success then warn(`Ruby :: Checking SerializationTools failed {data}`) return end
	data = HttpService:JSONDecode(data)

	local lastUpdate = data[1].commit.committer.date
	return lastUpdate
end

function Ruby.fetch(cache: Folder)
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
		`SerializationTools`, 
		true
	)
	if not folder:GetAttribute(`RequestsProcessing`) then
		folder:SetAttribute(`RequestsProcessing`, 0)
	end

	folder.Name = `SerializationTools`
	folder.Parent = cache

	local mainWriting = folder:FindFirstChild(`Writing`) and folder.Writing:FindFirstChild(`Main`)
	if not mainWriting then 
		warn(`Ruby :: Main/Writing.lua is missing`) 
		loaded = true
		folder:Destroy()
		return 
	end

	Ruby.Root = folder
	folder:SetAttribute(`Date`, `recent`)
	task.spawn(function()
		folder:SetAttribute(`Date`, Ruby.getLatestUpdate(folder))
	end)

	local injections = {
		[`local%s+readbackEnabled%s*=%s*FeatureCheck%("Readback"%)%s*==%s*true`] = 
		[[
		local fetchSourceButton = Button({
			Size = UDim2.new(0, 200, 0, 30),
			Enabled = module.EnabledState,
			Position = UDim2.new(0, apiDevEnabled and 270 or 50, 1, -50),
			AnchorPoint = Vector2.new(0, 1),
			Text = `Fetch Source`,
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
	Ruby.hookAttributeChanges(folder, cache)
	if Ruby.Exporter then Ruby.Exporter.Clean() end
	Ruby.Exporter = require(mainWriting)
	task.wait(0.5)
	loaded = true
	Ruby.backgroundChecks(true)
end

function Ruby.hookAttributeChanges(folder: Folder, cache: Folder)
	folder:GetAttributeChangedSignal(`Refetch`):Connect(function()
		local nv = folder:GetAttribute(`Refetch`)
		folder:SetAttribute(`Refetch`, nil)

		if nv then
			Ruby.Active = false
			Ruby.Plugin:Deactivate()
			folder:Destroy()
			Ruby.fetch(cache)
		end
	end)
	
	folder:GetAttributeChangedSignal(`NoBackgroundChecks`):Connect(function()
		local nv = folder:GetAttribute(`NoBackgroundChecks`)
		if nv == true then
			Ruby.backgroundChecks(false)
		else
			Ruby.backgroundChecks(true)
		end
	end)
end

return Ruby