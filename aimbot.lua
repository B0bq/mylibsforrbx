local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local aimbot = {}

aimbot.Settings = {
    Enabled = true,
    Smoothness = 5,
    FOV = 150,
    TargetPart = "Head", -- "HumanoidRootPart", etc
    TeamCheck = true,
    VisibleCheck = true,
    HoldToAim = true, -- right click hold
    VisibleFOV = true,
    ShowLine = true
}

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Thickness = 1
fovCircle.Transparency = 0.5
fovCircle.Filled = false

-- Line to Target
local targetLine = Drawing.new("Line")
targetLine.Thickness = 1.5
targetLine.Color = Color3.fromRGB(255, 255, 255)
targetLine.Transparency = 0.8

-- Closest Target Logic
local function getClosest()
    local closest = nil
    local closestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local hum = player.Character:FindFirstChild("Humanoid")
        local part = player.Character:FindFirstChild(aimbot.Settings.TargetPart)
        if not hum or hum.Health <= 0 or not part then continue end
        if aimbot.Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        if aimbot.Settings.VisibleCheck then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            rayParams.IgnoreWater = true

            local ray = Workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 500, rayParams)
            if ray and ray.Instance and not part:IsDescendantOf(ray.Instance.Parent) then
                continue
            end
        end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
        if dist < closestDist and dist <= aimbot.Settings.FOV then
            closest = part
            closestDist = dist
        end
    end

    return closest
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- FOV Circle updates
    fovCircle.Position = screenCenter
    fovCircle.Radius = aimbot.Settings.FOV
    fovCircle.Visible = aimbot.Settings.Enabled and aimbot.Settings.VisibleFOV

    -- Default: hide line
    targetLine.Visible = false

    if not aimbot.Settings.Enabled then return end
    if aimbot.Settings.HoldToAim and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

    local targetPart = getClosest()
    if targetPart then
        local screenPos = Camera:WorldToViewportPoint(targetPart.Position)
        local targetVec = Vector2.new(screenPos.X, screenPos.Y)
        local moveVec = (targetVec - mousePos) / math.max(aimbot.Settings.Smoothness, 1)

        -- Move cursor
        if moveVec.Magnitude > 1 then
            mousemoverel(moveVec.X, moveVec.Y)
        end

        -- Draw line to target
        if aimbot.Settings.ShowLine then
            targetLine.From = mousePos
            targetLine.To = targetVec
            targetLine.Visible = true
        end
    end
end)

return aimbot
