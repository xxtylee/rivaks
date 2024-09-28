-- esp [wip]

local players = cloneref(game:GetService("Players"))
local client = players.LocalPlayer
local camera = workspace.CurrentCamera

getgenv().global = getgenv()

function global.declare(self, index, value, check)
	if self[index] == nil then
		self[index] = value
	elseif check then
		local methods = { "remove", "Disconnect" }

		for _, method in methods do
			pcall(function()
				value[method](value)
			end)
		end
	end

	return self[index]
end

declare(global, "services", {})

function global.get(service)
	return services[service]
end

declare(declare(services, "loop", {}), "cache", {})

get("loop").new = function(self, index, func, disabled)
	if disabled == nil and (func == nil or typeof(func) == "boolean") then
		disabled = func func = index
	end

	self.cache[index] = {
		["enabled"] = (not disabled),
		["func"] = func,
		["toggle"] = function(self, boolean)
			if boolean == nil then
				self.enabled = not self.enabled
			else
				self.enabled = boolean
			end
		end,
		["remove"] = function()
			self.cache[index] = nil
		end
	}

	return self.cache[index]
end

declare(get("loop"), "connection", cloneref(game:GetService("RunService")).RenderStepped:Connect(function(delta)
	for _, loop in get("loop").cache do
		if loop.enabled then
			local success, result = pcall(function()
				loop.func(delta)
			end)

			if not success then
			end
		end
	end
end), true)

declare(services, "new", {})

get("new").drawing = function(class, properties)
	local drawing = Drawing.new(class)
	for property, value in properties do
		pcall(function()
			drawing[property] = value
		end)
	end
	return drawing
end

declare(declare(services, "player", {}), "cache", {})

get("player").find = function(self, player)
	for character, data in self.cache do
		if data.player == player then
			return character
		end
	end
end

get("player").check = function(self, player)
	local success, check = pcall(function()
		local character = player:IsA("Player") and player.Character or player
		local children = { character.Humanoid, character.HumanoidRootPart }

		return children and character.Parent ~= nil
	end)

	return success and check
end

get("player").new = function(self, player)
	local function cache(character)
		self.cache[character] = {
			["player"] = player,
			["drawings"] = {
				["box"] = get("new").drawing("Square", { Visible = false }),
				["boxFilled"] = get("new").drawing("Square", { Visible = false, Filled = true }),
				["boxOutline"] = get("new").drawing("Square", { Visible = false }),
				["name"] = get("new").drawing("Text", { Visible = false, Center = true}),
				["health"] = get("new").drawing("Line", { Visible = false }),
				["healthOutline"] = get("new").drawing("Line", { Visible = false }),
				["healthText"] = get("new").drawing("Text", { Visible = false, Center = false}),
				["distance"] = get("new").drawing("Text", { Visible = false, Center = true}),
				["weapon"] = get("new").drawing("Text", { Visible = false, Center = true}),
			}
		}
	end

	local function check(character)
		if self:check(character) then
			cache(character)
		else
			local listener; listener = character.ChildAdded:Connect(function()
				if self:check(character) then
					cache(character) listener:Disconnect()
				end
			end)
		end
	end

	if player.Character then check(player.Character) end
	player.CharacterAdded:Connect(check)
end

get("player").remove = function(self, player)
	if player:IsA("Player") then
		local character = self:find(player)
		if character then
			self:remove(character)
		end
	else
		local drawings = self.cache[player].drawings self.cache[player] = nil

		for _, drawing in drawings do
			drawing:Remove()
		end
	end
end

get("player").update = function(self, character, data)
	if not self:check(character) then
		self:remove(character)
	end

	local player = data.player
	local root = character.HumanoidRootPart
	local humanoid = character.Humanoid
	local drawings = data.drawings

	if self:check(client) then
		data.distance = (client.Character.HumanoidRootPart.CFrame.Position - root.CFrame.Position).Magnitude
	end

	local weapon = character:FindFirstChildWhichIsA("Tool") or "none"

	task.spawn(function()
		local position, visible = camera:WorldToViewportPoint(root.CFrame.Position)

		local visuals = features.visuals

		local function check()
			local team; if visuals.teamCheck then team = player.Team ~= client.Team else team = true end
			return visuals.enabled and data.distance and data.distance <= visuals.renderDistance and team
		end

		local function color(color)
			if visuals.teamColor then
				color = player.TeamColor.Color
			end
			return color
		end

		if visible and check() then
			local scale = 1 / (position.Z * math.tan(math.rad(camera.FieldOfView * 0.5)) * 2) * 1000
			local width, height = math.floor(4.5 * scale), math.floor(6 * scale)
			local x, y = math.floor(position.X), math.floor(position.Y)
			local xPosition, yPostion = math.floor(x - width * 0.5), math.floor((y - height * 0.5) + (0.5 * scale))
            --// Deafultes \\--
            drawings.boxOutline.ZIndex = 0
            drawings.boxFilled.ZIndex = 0 
            drawings.name.ZIndex = 0
            drawings.healthOutline.ZIndex = 0

			drawings.box.Size = Vector2.new(width, height)
			drawings.box.Position = Vector2.new(xPosition, yPostion)
			drawings.boxFilled.Size = drawings.box.Size
			drawings.boxFilled.Position = drawings.box.Position
			drawings.boxOutline.Size = drawings.box.Size
			drawings.boxOutline.Position = drawings.box.Position

			drawings.box.Color = color(visuals.boxes.color)
			drawings.box.Thickness = 1
			drawings.boxFilled.Color = color(visuals.boxes.filled.color)
			drawings.boxFilled.Transparency = visuals.boxes.filled.transparency
			drawings.boxOutline.Color = visuals.boxes.outline.color
			drawings.boxOutline.Thickness = 3

			drawings.boxOutline.ZIndex = drawings.box.ZIndex - 1
			drawings.boxFilled.ZIndex = drawings.boxOutline.ZIndex - 1


			drawings.name.Text = `[ {player.Name} ]`
			drawings.name.Size = math.max(math.min(math.abs(12.5 * scale), 12.5), 10)
			drawings.name.Position = Vector2.new(x, (yPostion - drawings.name.TextBounds.Y) - 2)
			drawings.name.Color = color(visuals.names.color)
			drawings.name.Outline = visuals.names.outline.enabled
			drawings.name.OutlineColor = visuals.names.outline.color

			drawings.name.ZIndex = drawings.box.ZIndex + 1

			local healthPercent = 100 / (humanoid.MaxHealth / humanoid.Health)
		
			drawings.healthOutline.From = Vector2.new(xPosition - 5, yPostion)
			drawings.healthOutline.To = Vector2.new(xPosition - 5, yPostion + height)
			drawings.health.From = Vector2.new(xPosition - 5, (yPostion + height) - 1)
			drawings.health.To = Vector2.new(xPosition - 5, ((drawings.health.From.Y - ((height / 100) * healthPercent))) + 2)
			drawings.healthText.Text = `[ HP {math.floor(humanoid.Health)} ]`
			drawings.healthText.Size = math.max(math.min(math.abs(11 * scale), 11), 10)
			drawings.healthText.Position = Vector2.new(drawings.health.To.X - (drawings.healthText.TextBounds.X + 3), (drawings.health.To.Y - (2 / scale)))

			drawings.health.Color = visuals.health.colorLow:Lerp(visuals.health.color, healthPercent * 0.01)
			drawings.healthOutline.Color = visuals.health.outline.color
			drawings.healthOutline.Thickness = 3
			drawings.healthText.Color = drawings.health.Color
			drawings.healthText.Outline = visuals.health.text.outline.enabled
			drawings.healthText.OutlineColor = visuals.health.outline.color

			drawings.healthOutline.ZIndex = drawings.health.ZIndex - 1

			drawings.distance.Text = `[ {math.floor(data.distance)} ]`
			drawings.distance.Size = math.max(math.min(math.abs(11 * scale), 11), 10)
			drawings.distance.Position = Vector2.new(x, (yPostion + height) + (drawings.distance.TextBounds.Y * 0.25))
			drawings.distance.Color = color(visuals.distance.color)
			drawings.distance.Outline = visuals.distance.outline.enabled
			drawings.distance.OutlineColor = visuals.distance.outline.color
			
			drawings.weapon.Text = `[ {weapon} ]`
			drawings.weapon.Size = math.max(math.min(math.abs(11 * scale), 11), 10)
			drawings.weapon.Position = visuals.distance.enabled and Vector2.new(drawings.distance.Position.x, drawings.distance.Position.Y + (drawings.weapon.TextBounds.Y * 0.75)) or drawings.distance.Position
			drawings.weapon.Color = color(visuals.weapon.color)
			drawings.weapon.Outline = visuals.weapon.outline.enabled
			drawings.weapon.OutlineColor = visuals.weapon.outline.color
		end

		drawings.box.Visible = (check() and visible and visuals.boxes.enabled)
		drawings.boxFilled.Visible = (check() and drawings.box.Visible and visuals.boxes.filled.enabled)
		drawings.boxOutline.Visible = (check() and drawings.box.Visible and visuals.boxes.outline.enabled)
		drawings.name.Visible = (check() and visible and visuals.names.enabled)
		drawings.health.Visible = (check() and visible and visuals.health.enabled)
		drawings.healthOutline.Visible = (check() and drawings.health.Visible and visuals.health.outline.enabled)
		drawings.healthText.Visible = (check() and drawings.health.Visible and visuals.health.text.enabled)
		drawings.distance.Visible = (check() and visible and visuals.distance.enabled)
		drawings.weapon.Visible = (check() and visible and visuals.weapon.enabled)
	end)
end

declare(get("player"), "loop", get("loop"):new(function ()
	for character, data in get("player").cache do
		get("player"):update(character, data)
	end
end), true)

declare(global, "features", {})

features.toggle = function(self, feature, boolean)
	if self[feature] then
		if boolean == nil then
			self[feature].enabled = not self[feature].enabled
		else
			self[feature].enabled = boolean
		end

		if self[feature].toggle then
			task.spawn(function()
				self[feature]:toggle()
			end)
		end
	end
end

declare(features, "visuals", {
	["enabled"] = true,
	["teamCheck"] = false,
	["teamColor"] = true,
	["renderDistance"] = 2000,

	["boxes"] = {
		["enabled"] = true,
		["color"] = Color3.fromRGB(255, 255, 255),
		["outline"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(0, 0, 0),
		},
		["filled"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(255, 255, 255),
			["transparency"] = 0.25
		},
	},
	["names"] = {
		["enabled"] = true,
		["color"] = Color3.fromRGB(255, 255, 255),
		["outline"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(0, 0, 0),
		},
	},
	["health"] = {
		["enabled"] = true,
		["color"] = Color3.fromRGB(0, 255, 0),
		["colorLow"] = Color3.fromRGB(255, 0, 0),
		["outline"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(0, 0, 0)
		},
		["text"] = {
			["enabled"] = true,
			["outline"] = {
				["enabled"] = true,
			},
		}
	},
	["distance"] = {
		["enabled"] = true,
		["color"] = Color3.fromRGB(255, 255, 255),
		["outline"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(0, 0, 0),
		},
	},
	["weapon"] = {
		["enabled"] = true,
		["color"] = Color3.fromRGB(255, 255, 255),
		["outline"] = {
			["enabled"] = true,
			["color"] = Color3.fromRGB(0, 0, 0),
		},
	}
})

for _, player in players:GetPlayers() do
	if player ~= client and not get("player"):find(player) then
		get("player"):new(player)
	end
end

declare(get("player"), "added", players.PlayerAdded:Connect(function(player)
	get("player"):new(player)
end), true)

declare(get("player"), "removing", players.PlayerRemoving:Connect(function(player)
	get("player"):remove(player)
end), true)
