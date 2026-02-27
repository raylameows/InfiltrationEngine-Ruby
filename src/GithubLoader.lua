local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GithubLoader = {}
GithubLoader.FileTypeToInstance = {
	[`dir`] = `Folder`,
	[`file.server.lua`] = `Script`,
	[`file.lua`] = `ModuleScript`,
}
GithubLoader.RequestsProcessing = 0
GithubLoader.LastProcessed = 0

function GithubLoader.toProxy(url: string)
	local pattern = "^https://raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/(.*)$"
	local user, repo, branch, path = url:match(pattern)

	if not (user and repo and branch and path) then
		warn(`GithubLoader :: Invalid url {url}`)
		return nil
	end

	local jsDelivrUrl = ("https://cdn.jsdelivr.net/gh/%s/%s@%s/%s"):format(user, repo, branch, path)
	return jsDelivrUrl
end

function GithubLoader.call(url: string)
	GithubLoader.RequestsProcessing += 1
	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	GithubLoader.RequestsProcessing -= 1
	GithubLoader.LastProcessed = tick()
	return success, response
end

function GithubLoader.dir(holder: Folder, folder: Folder, url: string)
	print(`GithubLoader :: Loading {url}`)
	folder = folder or holder

	local success, response = GithubLoader.call(url)
	if not success then warn(`GithubLoader :: {response}`) return end

	local files = HttpService:JSONDecode(response)
	local currentBatch = 0
	for _, fileData in (files) do
		local split = string.split(fileData.name, `.`)
		local key = `{fileData.type}{split[2] and `.{split[2]}` or ``}{#split >= 3 and `.{split[3]}` or ``}`
		local obj = Instance.new(GithubLoader.FileTypeToInstance[key])
		obj.Name = split[1]
		obj.Parent = folder

		if fileData.type == `dir` then
			task.spawn(function()
				GithubLoader.dir(holder, obj, fileData.url)
			end)
		elseif fileData.download_url then
			task.spawn(function()
				local success, response = GithubLoader.call(GithubLoader.toProxy(fileData.download_url))
				if not success then warn(`GithubLodaer :: {response}`) return end
				obj.Source = response
			end)
		end
	end
end

function GithubLoader.repo(url: string, name: string?, yield: boolean?)
	local folder = Instance.new(`Folder`)
	folder.Name = name or `RubySerializerFolder`
	folder.Parent = ReplicatedStorage

	GithubLoader.dir(folder, nil, url)

	if yield then
		repeat task.wait() until GithubLoader.RequestsProcessing == 0 and tick() - GithubLoader.LastProcessed >= 1
	end

	return folder
end

return GithubLoader