local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local esp = {}

esp.ESPSettings = {
    Enabled = true,
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowBox = true,
    ShowChams = true,
    MaxDistance = 1000,
    ShowTeam = true,
    TeamColorOverride = false,
    RainbowMode = false,

    Colors = {
        Box = Color3.fromRGB(255, 255, 255),
        Name = Color3.fromRGB(255, 255, 255),
        Health = Color3.fromRGB(0, 255, 0),
        Distance = Color3.fromRGB(255, 255, 0),
        Chams = Color3.fromRGB(255, 255, 255)
    }
}

local drawings = {}
local adorns = {}
local hue = 0

local function getColor(baseColor)
    if esp.ESPSettings.RainbowMode then
        hue = (hue + 0.005) % 1
        return Color3.fromHSV(hue, 1, 1)
    end
    return baseColor
end

local function createDrawing(class, props)
    local drawing = Drawing.new(class)
    for prop, val in pairs(props) do
        drawing[prop] = val
    end
    return drawing
end

local function clearDrawings()
    for _, v in pairs(drawings) do
        for _, d in pairs(v) do
            d:Remove()
        end
    end
    drawings = {}
end

local function clearChams()
    for _, v in pairs(adorns) do
        for _, a in pairs(v) do
            a:Destroy()
        end
    end
    adorns = {}
end

local function createCham(player)
    if adorns[player] then return end
    local model = player.Character
    if not model then return end
    local parts = {}

    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") and part.Transparency < 1 then
            local adorn = Instance.new("BoxHandleAdornment")
            adorn.Adornee = part
            adorn.AlwaysOnTop = true
            adorn.ZIndex = 5
            adorn.Size = part.Size
            adorn.Transparency = 0.5

            if esp.ESPSettings.TeamColorOverride then
                adorn.Color3 = getColor(esp.ESPSettings.Colors.Chams)
            else
                adorn.Color3 = player.Team and player.Team.TeamColor.Color or getColor(esp.ESPSettings.Colors.Chams)
            end

            adorn.Parent = game.CoreGui
            table.insert(parts, adorn)
        end
    end

    adorns[player] = parts
end

local function removeESP(player)
    if drawings[player] then
        for _, d in pairs(drawings[player]) do
            d:Remove()
        end
        drawings[player] = nil
    end
    if adorns[player] then
        for _, a in pairs(adorns[player]) do
            a:Destroy()
        end
        adorns[player] = nil
    end
end

local function setupPlayerCleanup(player)
    player.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.Died:Connect(function()
                removeESP(player)
            end)
        end
    end)

    player.CharacterRemoving:Connect(function()
        removeESP(player)
    end)
end

esp.StartESP = function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            setupPlayerCleanup(plr)
        end
    end

    Players.PlayerAdded:Connect(setupPlayerCleanup)

    RunService.RenderStepped:Connect(function()
        if not esp.ESPSettings.Enabled then
            clearDrawings()
            clearChams()
            return
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                continue
            end

            if not esp.ESPSettings.ShowTeam and player.Team == LocalPlayer.Team then
                removeESP(player)
                continue
            end

            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

            if not humanoid or humanoid.Health <= 0 then
                removeESP(player)
                continue
            end

            local cam = workspace.CurrentCamera
            local headPos, headOnScreen = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local footPos, footOnScreen = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
            if not (headOnScreen and footOnScreen) or LocalPlayer:DistanceFromCharacter(hrp.Position) > esp.ESPSettings.MaxDistance then
                if drawings[player] then
                    for _, d in pairs(drawings[player]) do d.Visible = false end
                end
                continue
            end

            if esp.ESPSettings.ShowChams then
                createCham(player)
            else
                if adorns[player] then
                    for _, a in pairs(adorns[player]) do
                        a:Destroy()
                    end
                    adorns[player] = nil
                end
            end

            local height = math.abs(headPos.Y - footPos.Y)
            local width = height / 2
            local boxPos = Vector2.new(headPos.X - width / 2, headPos.Y)

            if not drawings[player] then
                drawings[player] = {
                    name = createDrawing("Text", {Size = 13, Center = true, Outline = true, Font = 2}),
                    healthbar = createDrawing("Square", {Filled = true}),
                    distance = createDrawing("Text", {Size = 13, Center = true, Outline = true, Font = 2}),
                    box = createDrawing("Square", {Thickness = 1})
                }
            end

            -- Box
            local box = drawings[player].box
            box.Size = Vector2.new(width, height)
            box.Position = boxPos
            box.Color = esp.ESPSettings.TeamColorOverride and getColor(esp.ESPSettings.Colors.Box) or (player.Team and player.Team.TeamColor.Color or getColor(esp.ESPSettings.Colors.Box))
            box.Visible = esp.ESPSettings.ShowBox

            -- Health Bar
            local hpPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barHeight = height * hpPercent
            local healthbar = drawings[player].healthbar
            healthbar.Size = Vector2.new(2, barHeight)
            healthbar.Position = Vector2.new(boxPos.X - 5, boxPos.Y + (height - barHeight))
            healthbar.Color = getColor(esp.ESPSettings.Colors.Health)
            healthbar.Visible = esp.ESPSettings.ShowHealth

            -- Name
            local name = drawings[player].name
            name.Text = player.Name
            name.Position = Vector2.new(boxPos.X + width / 2, boxPos.Y - 15)
            name.Color = getColor(esp.ESPSettings.Colors.Name)
            name.Visible = esp.ESPSettings.ShowName

            -- Distance
            local distance = drawings[player].distance
            distance.Text = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) .. "m"
            distance.Position = Vector2.new(boxPos.X + width / 2, boxPos.Y + height + 2)
            distance.Color = getColor(esp.ESPSettings.Colors.Distance)
            distance.Visible = esp.ESPSettings.ShowDistance
        end
    end)
end

return esp
