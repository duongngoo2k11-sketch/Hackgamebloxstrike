Config = {
    Radius = 120,          -- Bán kính vòng FOV
    DecayRate = 0.15       -- Độ mượt khi lia tâm (nhỏ hơn = mượt hơn)
}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local IsHoldingRightClick = false 
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

-- ƯU TIÊN LẤY ĐẦU (HEAD)
local function FindHeadPart(character)
    if not character then return nil end
    local head = character:FindFirstChild("Head") or character:FindFirstChild("FakeHead")
    if head and head:IsA("BasePart") then return head end

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

-- BẮT SỰ KIỆN GIỮ / NHẢ CHUỘT PHẢI
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsHoldingRightClick = true
        FOVCircle.Color = Color3.fromRGB(255, 50, 50) -- Đổi sang màu đỏ báo hiệu đang ghim
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsHoldingRightClick = false
        FOVCircle.Color = Color3.fromRGB(0, 255, 150) -- Trả về màu xanh lá khi nhả
    end
end)

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
end)

-- VÒNG LẶP RENDER CHÍNH
RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = screenCenter
    FOVCircle.Radius = Config.Radius

    UpdateESP()

    -- Chỉ khóa tâm khi đang giữ chuột phải
    if IsHoldingRightClick then
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

