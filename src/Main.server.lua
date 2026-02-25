local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RayUtil = require(`./RayUtil`)
local Ruby = require(`./Ruby`)
Ruby.Plugin = plugin

local Toolbar = plugin:CreateToolbar("Ruby")
local Button = Toolbar:CreateButton(`Ruby`, `Fetches the most recent serializer from the Github and automatically adds itself as a plugin`, `rbxassetid://92473074743015`)
Ruby.Button = Button

local PluginsFolder = RayUtil.getFolder(ReplicatedStorage, `Plugins`, true)
local RubyPluginFolder = PluginsFolder and RayUtil.getFolder(PluginsFolder, `Ruby`, true)
local CachedExporter = RubyPluginFolder and RubyPluginFolder:FindFirstChild(`SerializationTools`)
if CachedExporter then
	Ruby.backgroundChecks(true)
end
Ruby.RubyPluginFolder = RubyPluginFolder

local deb = false
Button.Click:Connect(function()
	if deb then return end
	PluginsFolder = RayUtil.getFolder(ReplicatedStorage, `Plugins`)
	RubyPluginFolder = RayUtil.getFolder(PluginsFolder, `Ruby`)
	CachedExporter = RubyPluginFolder:FindFirstChild(`SerializationTools`)
	Ruby.RubyPluginFolder = RubyPluginFolder
	
	if not CachedExporter then
		deb = true
		Ruby.fetch(RubyPluginFolder)
		task.wait()
		deb = false
		return
	elseif CachedExporter and not Ruby.Exporter then
		deb = true
		Ruby.hookAttributeChanges(CachedExporter, RubyPluginFolder)
		Ruby.Root = CachedExporter
		Ruby.Exporter = require(CachedExporter.Writing.Main)
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

			button.Activated:Connect(function()
				local currentTime = tick()
				if currentTime - lastClickTime <= doubleClickThreshold then
					print("Ruby :: Performing refetch")
					CachedExporter:SetAttribute("Refetch", true)
				else
					task.delay(doubleClickThreshold, function()
						if tick() - lastClickTime >= doubleClickThreshold then
							print("Ruby :: Performing update check")
							local outdated = Ruby.checkForUpdate(true)
							if outdated == false then
								print("Ruby :: Serializer is up to date")
							elseif outdated == true then
								print("Ruby :: Serializer is outdated")
							end
						end
					end)
				end

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
	Disable()
end

plugin.Unloading:Connect(Unload)
plugin.Deactivation:Connect(Disable)