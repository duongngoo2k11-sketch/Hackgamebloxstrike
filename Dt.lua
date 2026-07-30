local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- FEAT: TỐI ƯU HÓA ĐỒ HỌA + CÂN BẰNG ÁNH SÁNG BAN NGÀY (ĐÃ CHỈNH SÁNG BẦU TRỜI)
local function OptimizeGamePerformance()
    local lighting = game:GetService("Lighting")
    
    -- 1. ĐIỀU CHỈNH ÁNH SÁNG BAN NGÀY TỰ NHIÊN (RÕ RÀNG, DỊU MẮT)
    lighting.GlobalShadows = false
    lighting.FogEnd = 9e9
    lighting.Brightness = 2.0                  -- Tăng độ sáng môi trường lên mức chuẩn rõ nét
    lighting.ExposureCompensation = 0          -- Đưa phơi sáng về mức cân bằng tự nhiên
    lighting.ClockTime = 12                    -- Giữ thời gian chiều mát để không bị chói nắng
    lighting.Ambient = Color3.fromRGB(150, 150, 150)        -- Tăng độ sáng vùng tối xung quanh
    lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150) -- Tăng độ sáng không gian ngoài trời

    -- Xóa các hiệu ứng chói/mờ gây nhiễu màn hình
    for _, fx in ipairs(lighting:GetChildren()) do
        if fx:IsA("PostEffect") or fx:IsA("BloomEffect") or fx:IsA("BlurEffect") or fx:IsA("DepthOfFieldEffect") or fx:IsA("SunRaysEffect") or fx:IsA("Sky") then
            fx:Destroy()
        end
    end

    -- 2. ĐỔI BẦU TRỜI SANG MÀU TRỜI SÁNG (CLEAR SKY)
    local sky = Instance.new("Sky")
    sky.Name = "CustomLightSky"
    -- Sử dụng tài nguyên bầu trời xanh sáng tiêu chuẩn của Roblox giúp map sáng sủa
    sky.SkyboxBk = "rbxassetid://16047201"
    sky.SkyboxDn = "rbxassetid://16047201"
    sky.SkyboxFt = "rbxassetid://16047201"
    sky.SkyboxLf = "rbxassetid://16047201"
    sky.SkyboxRt = "rbxassetid://16047201"
    sky.SkyboxUp = "rbxassetid://16047201"
    sky.Parent = lighting

    -- 3. BỎ TEXTURE MƯỢT MÀ KHÔNG BỊ PHẢN QUANG (GIỮ NGUYÊN)
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

-- TỰ ĐỘNG TÔ MÀU ĐỊCH (GIỮ NGUYÊN 100% CẤU TRÚC HIGHLIGHT GỐC CỦA BẠN)
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

LocalPlayer.CharacterAdded:Connect(function()
    task.spawn(OptimizeGamePerformance)
end)

-- VÒNG LẶP RENDER CHÍNH (ĐÃ LƯU BỎ LOGIC AIMBOT & FOV DRAWING)
RunService.RenderStepped:Connect(function()
    -- Tự động tô màu cập nhật liên tục 24/7 theo mã gốc của bạn
    UpdateESP()
end)

-- KHỞI CHẠY HỆ THỐNG BAN ĐẦU
OptimizeGamePerformance()
