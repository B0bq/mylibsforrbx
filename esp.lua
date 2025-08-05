local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local esp = {}

esp.ESPSettings = {
    Enabled = true,
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowWeapon = true,
    ShowBox = true,
    ShowChams = true,
    MaxDistance = 1000
}

local drawings = {}
local adorns = {}

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
            adorn.Color3 = player.Team and player.Team.TeamColor.Color or Color3.new(1, 1, 1)
            adorn.Parent = game.CoreGui
            table.insert(parts, adorn)
        end
    end

    adorns[player] = parts
end

local function clearChams()
    for _, v in pairs(adorns) do
        for _, a in pairs(v) do
            a:Destroy()
        end
    end
    adorns = {}
end

esp.StartESP = function()
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

            local hrp = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)

            if not onScreen or (LocalPlayer:DistanceFromCharacter(hrp.Position) > esp.ESPSettings.MaxDistance) then
                if drawings[player] then
                    for _, d in pairs(drawings[player]) do
                        d.Visible = false
                    end
                end
                continue
            end

            -- Chams
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

            if not drawings[player] then
                drawings[player] = {
                    name = createDrawing("Text", {Size = 13, Color = Color3.new(1,1,1), Center = true, Outline = true, Font = 2}),
                    health = createDrawing("Text", {Size = 13, Color = Color3.new(0,1,0), Center = true, Outline = true, Font = 2}),
                    distance = createDrawing("Text", {Size = 13, Color = Color3.new(1,1,0), Center = true, Outline = true, Font = 2}),
                    weapon = createDrawing("Text", {Size = 13, Color = Color3.new(1,1,1), Center = true, Outline = true, Font = 2}),
                    box = createDrawing("Square", {Thickness = 1, Color = player.Team and player.Team.TeamColor.Color or Color3.new(1,1,1)})
                }
            end

            local rootPos = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            local headPos = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local height = math.abs(headPos.Y - rootPos.Y)
            local width = height / 2

            -- Box
            if esp.ESPSettings.ShowBox then
                local box = drawings[player].box
                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                box.Color = player.Team and player.Team.TeamColor.Color or Color3.new(1,1,1)
                box.Visible = true
            else
                drawings[player].box.Visible = false
            end

            -- Name
            if esp.ESPSettings.ShowName then
                local nameText = drawings[player].name
                nameText.Text = player.Name
                nameText.Position = Vector2.new(pos.X, pos.Y - 30)
                nameText.Visible = true
            else
                drawings[player].name.Visible = false
            end

            -- Health
            if esp.ESPSettings.ShowHealth then
                local hpText = drawings[player].health
                hpText.Text = math.floor(humanoid.Health) .. " HP"
                hpText.Position = Vector2.new(pos.X, pos.Y - 15)
                hpText.Visible = true
            else
                drawings[player].health.Visible = false
            end

            -- Distance
            if esp.ESPSettings.ShowDistance then
                local distText = drawings[player].distance
                distText.Text = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) .. "m"
                distText.Position = Vector2.new(pos.X, pos.Y + 15)
                distText.Visible = true
            else
                drawings[player].distance.Visible = false
            end

            -- Weapon
            if esp.ESPSettings.ShowWeapon then
                local tool = player.Character:FindFirstChildOfClass("Tool")
                local weaponText = drawings[player].weapon
                if tool then
                    weaponText.Text = "[" .. tool.Name .. "]"
                    weaponText.Position = Vector2.new(pos.X, pos.Y)
                    weaponText.Visible = true
                else
                    weaponText.Visible = false
                end
            else
                drawings[player].weapon.Visible = false
            end
        end
    end)
end

return esp
