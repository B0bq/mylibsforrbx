local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local esp = {}

esp.Settings = {
    Enabled = true,
    Smoothness = 5,
    FOV = 150,
    TargetPart = "Head", -- or "HumanoidRootPart"
    TeamCheck = true,
    VisibleCheck = true,
    HoldToAim = true,
    VisibleFOV = true,
    ShowLine = true,
    UseTeamColor = false,
    Rainbow = false,
    RainbowSpeed = 1,
    Colors = {
        BoxColor = Color3.fromRGB(255,255,255),
        NameColor = Color3.fromRGB(255,255,255),
        HealthColor = Color3.fromRGB(0,255,0),
        DistanceColor = Color3.fromRGB(255,255,0),
        WeaponColor = Color3.fromRGB(255,255,255),
        ChamsColor = Color3.fromRGB(255,0,0),
        FOVColor = Color3.fromRGB(255,255,255),
        TargetLineColor = Color3.fromRGB(255,255,255),
    }
}

-- Drawing elements
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Transparency = 0.5
fovCircle.Filled = false

local targetLine = Drawing.new("Line")
targetLine.Thickness = 1.5
targetLine.Transparency = 0.8

-- Rainbow helper
local hue = 0
local function getRainbow()
    hue = (hue + esp.Settings.RainbowSpeed / 255) % 1
    return Color3.fromHSV(hue, 1, 1)
end

-- Find closest target within FOV
local function getClosest()
    local closest, closestDist = nil, esp.Settings.FOV * 2
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild(esp.Settings.TargetPart) then
            if esp.Settings.TeamCheck and plr.Team == LocalPlayer.Team then continue end
            if plr.Character.Humanoid.Health <= 0 then continue end
            local part = plr.Character[esp.Settings.TargetPart]
            local pos2d, onScreen = Camera:WorldToViewportPoint(part.Position)
            if not onScreen then continue end
            if esp.Settings.VisibleCheck then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                rayParams.IgnoreWater = true
                local hit = Workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 500, rayParams)
                if hit and hit.Instance and not part:IsDescendantOf(hit.Instance.Parent) then
                    continue
                end
            end
            local dist = (Vector2.new(pos2d.X, pos2d.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
            if dist < closestDist then
                closestDist, closest = dist, part
            end
        end
    end
    return closest
end

-- Main loop
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Position = center
    fovCircle.Radius = esp.Settings.FOV
    fovCircle.Visible = esp.Settings.Enabled and esp.Settings.VisibleFOV
    fovCircle.Color = esp.Settings.Rainbow and getRainbow() or (esp.Settings.UseTeamColor and LocalPlayer.Team.TeamColor.Color or esp.Settings.Colors.FOVColor)

    targetLine.Visible = false

    if not esp.Settings.Enabled then return end
    if esp.Settings.HoldToAim and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

    local targetPart = getClosest()
    if targetPart then
        local tp = targetPart.Position
        local pos2d = Camera:WorldToViewportPoint(tp)
        local target2d = Vector2.new(pos2d.X, pos2d.Y)

        if esp.Settings.ShowLine then
            targetLine.From = center
            targetLine.To = target2d
            targetLine.Visible = true
            targetLine.Color = esp.Settings.Rainbow and getRainbow() or esp.Settings.Colors.TargetLineColor
        end

        local camPos = Camera.CFrame.Position
        local dir = (tp - camPos).Unit
        local desired = CFrame.new(camPos, camPos + dir)
        local smooth = math.clamp(esp.Settings.Smoothness, 1, 100)
        Camera.CFrame = Camera.CFrame:Lerp(desired, 1 / smooth)
    end
end)

-- Return the module
return esp
