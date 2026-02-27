local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ruby = require(`./Ruby`)
Ruby.Plugin = plugin

local Toolbar = plugin:CreateToolbar("Ruby")
local Button = Toolbar:CreateButton(`Ruby`, `Fetches the most recent serializer from the Github and automatically adds itself as a plugin`, `rbxassetid://92473074743015`)
Ruby.Button = Button

local deb = false
Button.Click:Connect(function()
	if deb then return end

	local Cache = plugin:GetSetting(`Cache`)
	if not Cache then
		deb = true
		Ruby.fetch()
		task.wait()
		deb = false
		return
	elseif Cache and not Ruby.Exporter then
		deb = true
		local folder = Instance.new(`Folder`)
		folder.Archivable = false
		folder.Name = `SerializationToolsRuby`
		folder.Parent = CoreGui
		Ruby.build(Ruby.decode(Cache), folder)
		Ruby.Exporter = require(folder.Writing.Main)
		Ruby.Folder = folder
		task.wait()
		deb = false
	end

	if not Ruby.Active then
		Ruby.Active = true
		plugin:Activate(true)
		Ruby.Exporter.Init(plugin:GetMouse())
		Ruby.getFetchSourceButton()
		Ruby.updateStatus()
		local button: TextButton = Ruby.FetchSourceButton
		if button then
			local lastClickTime = 0
			local doubleClickThreshold = 0.3
			local rubyButtonDeb = false
			local awaitingSecondClick = false

			button.Activated:Connect(function()
				if rubyButtonDeb then return end
				local currentTime = tick()
				if awaitingSecondClick and (currentTime - lastClickTime <= doubleClickThreshold) then
					awaitingSecondClick = false
					button.Text = `Ruby: Check`
					print(`Ruby :: Performing refetch`)
					Ruby.refetch()
					return
				end

				awaitingSecondClick = true
				button.Text = `Ruby: Fetch`

				task.delay(doubleClickThreshold, function()
					if awaitingSecondClick then
						awaitingSecondClick = false
						button.Text = `Ruby: Check`

						print(`Ruby :: Performing update check`)
						local outdated = Ruby.checkForUpdate(true)
						if outdated == false then
							print(`Ruby :: Serializer is up to date`)
						elseif outdated == true then
							print(`Ruby :: Serializer is outdated`)
						end
					end
				end)

				lastClickTime = currentTime
			end)
		end
	else
		Ruby.Active = false
		plugin:Deactivate()
	end
end)

local function Disable()
	if Ruby.Exporter then
		Ruby.Exporter.Clean()
	end
	if Ruby.FetchSourceButton then
		Ruby.FetchSourceButton = nil
	end
	Ruby.Active = false
end

local function Unload()
	if Ruby.SerializerAPI then
		Ruby.SerializerAPI.Clean()
	end
	Disable()
	if Ruby.Folder then
		Ruby.Folder:Destroy()
	end
end

plugin.Unloading:Connect(Unload)
plugin.Deactivation:Connect(Disable)