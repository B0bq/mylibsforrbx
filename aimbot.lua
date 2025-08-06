local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local aimbot = {}

aimbot.Settings = {
    Enabled = true,
    Smoothness = 5,
    FOV = 150,
    TargetPart = "Head", -- or "HumanoidRootPart"
    TeamCheck = true,
    VisibleCheck = true
}

-- Draw FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Thickness = 1
fovCircle.Radius = aimbot.Settings.FOV
fovCircle.Transparency = 0.5
fovCircle.Visible = true
fovCircle.Filled = false
fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

-- Function to get closest player in FOV
local function getClosest()
    local closest = nil
    local closestDist = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild(aimbot.Settings.TargetPart) then
            if aimbot.Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            if player.Character.Humanoid.Health <= 0 then continue end

            local part = player.Character[aimbot.Settings.TargetPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if not onScreen then continue end

            if aimbot.Settings.VisibleCheck then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                rayParams.IgnoreWater = true

                local result = Workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 500, rayParams)
                if result and result.Instance and not part:IsDescendantOf(result.Instance.Parent) then
                    continue
                end
            end

            local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
            if dist < closestDist and dist <= aimbot.Settings.FOV then
                closest = part
                closestDist = dist
            end
        end
    end

    return closest
end

-- Aimbot loop
RunService.RenderStepped:Connect(function()
    fovCircle.Radius = aimbot.Settings.FOV
    fovCircle.Visible = aimbot.Settings.Enabled

    if not aimbot.Settings.Enabled then return end

    local targetPart = getClosest()
    if targetPart then
        local aimPos = Camera:WorldToViewportPoint(targetPart.Position)
        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
        local moveVector = (Vector2.new(aimPos.X, aimPos.Y) - mousePos) / (aimbot.Settings.Smoothness > 0 and aimbot.Settings.Smoothness or 1)
        mousemoverel(moveVector.X, moveVector.Y)
    end
end)

return aimbot
