Config = {
    Radius = 100,
    DecayRate = 0.15
}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local IsAimbotActive = false 
local FakeCameraCFrame = Camera.CFrame

-- FEAT: TỐI ƯU HÓA ĐỒ HỌA GAME
local function OptimizeGamePerformance()
    local lighting = game:GetService("Lighting")
    lighting.GlobalShadows = false
    lighting.FogEnd = 9e9
    for _, fx in ipairs(lighting:GetChildren()) do
        if fx:IsA("PostEffect") or fx:IsA("BloomEffect") or fx:IsA("BlurEffect") or fx:IsA("DepthOfFieldEffect") or fx:IsA("SunRaysEffect") then
            fx:Destroy()
        end
    end
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("Texture") or object:IsA("Decal") then
            object:Destroy()
        elseif object:IsA("BasePart") or object:IsA("MeshPart") then
            object.Material = Enum.Material.SmoothPlastic
        elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Smoke") or object:IsA("Sparkles") or object:IsA("Fire") then
            object.Enabled = false
        end
    end
end

-- ƯU TIÊN LẤY PHẦN ĐẦU (HEAD)
local function FindHeadPart(character)
    if not character then return nil end
    local head = character:FindFirstChild("Head") or character:FindFirstChild("FakeHead")
    if head and head:IsA("BasePart") then return head end

    -- Dự phòng nếu không tìm thấy Head
    local torso = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if torso and torso:IsA("BasePart") then return torso end

    return nil
end

-- VÒNG TÂM FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Color = Color3.fromRGB(0, 255, 150)
FOVCircle.Filled = false
FOVCircle.Visible = true

-- TỰ ĐỘNG TÔ MÀU ĐỊCH (ESP HIGHLIGHT TỰ BẬT 24/7)
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local highlight = char:FindFirstChild("ESPHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ESPHighlight"
                    highlight.FillColor = Color3.fromRGB(255, 50, 50)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = char
                end
            else
                local hl = char:FindFirstChild("ESPHighlight")
                if hl then hl:Destroy() end
            end
        end
    end
end

-- UI DI ĐỘNG (CHỈ CÒN NÚT BẬT/TẮT KHÓA TÂM)
local function CreateMobileUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("DeltaXMobileUI") then
        playerGui.DeltaXMobileUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DeltaXMobileUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = playerGui

    -- NÚT BẬT/TẮT AIMBOT
    local AimButton = Instance.new("ImageButton")
    AimButton.Size = UDim2.new(0, 65, 0, 65)
    AimButton.Position = UDim2.new(0.85, 0, 0.4, 0)
    AimButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    AimButton.BackgroundTransparency = 0.3
    AimButton.BorderSizePixel = 0
    AimButton.Active = true
    AimButton.Draggable = true
    AimButton.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = AimButton

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(0, 255, 150)
    UIStroke.Thickness = 2
    UIStroke.Parent = AimButton

    local PlusLabel = Instance.new("TextLabel")
    PlusLabel.Size = UDim2.new(1, 0, 1, 0)
    PlusLabel.BackgroundTransparency = 1
    PlusLabel.Text = "+"
    PlusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    PlusLabel.TextSize = 35
    PlusLabel.Font = Enum.Font.SourceSansBold
    PlusLabel.Position = UDim2.new(0, 0, 0, -2)
    PlusLabel.Parent = AimButton

    AimButton.MouseButton1Click:Connect(function()
        IsAimbotActive = not IsAimbotActive
        if IsAimbotActive then
            PlusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            AimButton.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
        else
            PlusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
            AimButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        end
    end)
end

-- TÌM ĐẦU CỦA ĐỊCH GẦN TÂM MÀN HÌNH NHẤT
local function GetClosestPlayerHeadToCenter()
    local closestHead = nil
    local shortestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        
        local headPart = FindHeadPart(char)
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        if headPart and humanoid and humanoid.Health > 0 then
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPart.Position)
            if onScreen then
                local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
                local centerDistance = (screenPos2D - screenCenter).Magnitude
                
                if centerDistance <= Config.Radius and centerDistance < shortestDistance then
                    shortestDistance = centerDistance
                    closestHead = headPart
                end
            end
        end
    end
    return closestHead
end

LocalPlayer.CharacterAdded:Connect(function()
    task.spawn(OptimizeGamePerformance)
    task.spawn(CreateMobileUI)
end)

-- VÒNG LẶP RENDER CHÍNH
RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = screenCenter
    FOVCircle.Radius = Config.Radius

    -- Tự động tô màu cập nhật liên tục
    UpdateESP()

    -- Khóa tâm vào ĐẦU khi bật nút
    if IsAimbotActive then
        local targetHead = GetClosestPlayerHeadToCenter()
        if targetHead then
            local targetRotation = CFrame.lookAt(Camera.CFrame.Position, targetHead.Position)
            FakeCameraCFrame = FakeCameraCFrame:Lerp(targetRotation, 1 - Config.DecayRate)
            Camera.CFrame = FakeCameraCFrame
            return
        end
    end
    FakeCameraCFrame = Camera.CFrame
end)

OptimizeGamePerformance()
CreateMobileUI()

