local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local pluginPrefix = `RUBY_`
local Ruby = require(`./Ruby`)
Ruby.Plugin = plugin
Ruby.Prefix = pluginPrefix

local Toolbar = plugin:CreateToolbar("Ruby")
local Button = Toolbar:CreateButton(`Ruby`, `Fetches the most recent serializer from the Github and automatically adds itself as a plugin`, `rbxassetid://92473074743015`)
Ruby.Button = Button

local deb = false
Button.Click:Connect(function()
	if deb then return end

	local Cache = plugin:GetSetting(`{pluginPrefix}Cache`)
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
		task.spawn(function()
			Ruby.checkForUpdate()
		end)
		task.wait()
		deb = false
	end
	if plugin:GetSetting(`{pluginPrefix}EnableAllFeaturesByDefault`) and not workspace:GetAttribute(`RubyEnabledAllFeaturesByDefault`) then
		workspace:SetAttribute(`SerializerEnableAllFeatures`, true)
		workspace:SetAttribute(`RubyEnabledAllFeaturesByDefault`, true)
	end

	if not Ruby.Active then
		Ruby.Active = true
		plugin:Activate(true)
		Ruby.Exporter.Init(plugin:GetMouse())
		Ruby.getFetchSourceButton()
		Ruby.updateStatus()
		local button: TextButton = Ruby.FetchSourceButton
		if button then
			local rubyButtonDeb = false
			button.Activated:Connect(function()
				if rubyButtonDeb then return end
				rubyButtonDeb = true
				if Ruby.ButtonPerformsFetch then
					print(`Ruby :: Performing refetch`)
					Ruby.refetch()
					return
				else
					print(`Ruby :: Performing update check`)
					local outdated = Ruby.checkForUpdate(true)
					if outdated == false then
						print(`Ruby :: Serializer is up to date`)
					elseif outdated == true then
						print(`Ruby :: Serializer is outdated`)
					end
				end
				task.wait()
				rubyButtonDeb = false
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

local Arc = require(`./ArcAPI`)
Arc.call(function()
	Arc.new(`ruby`):Fill({
		color = Color3.fromRGB(172, 13, 74),
		subcommands = {
			[`check`] = {
				color = Color3.fromRGB(121, 146, 255),
				run = function(data: {[string]: any})
					local outdated = Ruby.checkForUpdate(true)
					return `Serializer is {outdated and `outdated` or `up to date`}`
				end,
			},
			[`fetch`] = {
				color = Color3.fromRGB(121, 146, 255),
				run = function(data: {[string]: any})
					Ruby.refetch()
					return `Refetched serializer`
				end,
			},
			[`date`] = {
				color = Color3.fromRGB(121, 146, 255),
				args = {action = {order = 1}},
				run = function(data: {[string]: any})
					local action = data.args.action
					if action == `clear` then
						plugin:SetSetting(`{Ruby.Prefix}Date`, nil)
					elseif action == `get` then
						return `{plugin:GetSetting(`{Ruby.Prefix}Date`)}`
					else
						return `Unknown date action {action}`
					end
				end,
			},
			[`cache`] = {
				color = Color3.fromRGB(121, 146, 255),
				args = {
					perform = {order = 1},
				},
				run = function(data: {[string]: any})
					local action = data.args.perform
					if action == `clear` then
						plugin:SetSetting(`{Ruby.Prefix}Cache`, nil)
						return `Cleared cache`
					elseif action == `size` then
						local size = #(plugin:GetSetting(`{Ruby.Prefix}Cache`) or ``) * 0.001
						return `Cache size is {size}K`
					else
						return `Unknown cache action {action}`
					end
				end,
			}
		},
	}):Register()
end)