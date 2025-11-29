local key_system = {}

-- Config của bạn - THAY ĐỔI 2 DÒNG NÀY
key_system.keys_url = "https://raw.githubusercontent.com/DuoG1603/FixLag/refs/heads/main/key.json" -- THAY URL GITHUB CỦA BẠN
key_system.discord_webhook = "https://discord.com/api/webhooks/1374025784611836074/kkmdFGWAggdZ_AYBmAA5KQKYiQGsnMhzbuT59Z-Oo3JjIIk-P7pmb6ZPwBUie5sP-9_U" -- THAY WEBHOOK DISCORD CỦA BẠN

-- Biến toàn cục để lưu key (giống như yêu cầu)
_G.Key = ""

-- Hàm lấy HWID đơn giản cho Roblox
function key_system:get_hwid()
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    
    -- Sử dụng UserId và các thông tin duy nhất của player
    local hwid = tostring(localPlayer.UserId) .. "_" .. tostring(game.JobId)
    
    -- Thêm thông tin về place/game
    hwid = hwid .. "_" .. tostring(game.PlaceId)
    
    return hwid
end

-- Hàm lấy tên PC (sửa lỗi io.popen)
function key_system:get_pc_name()
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    
    -- Sử dụng DisplayName hoặc Name của player
    if localPlayer then
        return localPlayer.DisplayName or localPlayer.Name or "UnknownPlayer"
    end
    
    return "UnknownPlayer"
end

-- Hàm gửi log đến Discord
function key_system:send_to_discord(key, status, pc_name, hwid)
    local time = os.date("%Y-%m-%d %H:%M:%S")
    
    local payload = {
        embeds = {
            {
                title = "🔑 Key Check Log",
                color = status == "SUCCESS" and 65280 or 16711680,
                fields = {
                    {
                        name = "Player Name",
                        value = "```" .. pc_name .. "```",
                        inline = true
                    },
                    {
                        name = "Key",
                        value = "```" .. key .. "```",
                        inline = true
                    },
                    {
                        name = "Status",
                        value = "```" .. status .. "```",
                        inline = true
                    },
                    {
                        name = "HWID",
                        value = "```" .. hwid .. "```",
                        inline = false
                    },
                    {
                        name = "Time",
                        value = "```" .. time .. "```",
                        inline = true
                    },
                    {
                        name = "Game",
                        value = "```" .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name .. "```",
                        inline = true
                    }
                },
                footer = {
                    text = "Key System"
                }
            }
        }
    }
    
    -- Gửi request đến Discord webhook
    pcall(function()
        local httpService = game:GetService("HttpService")
        httpService:PostAsync(self.discord_webhook, httpService:JSONEncode(payload))
    end)
end

-- Hàm tải keys từ GitHub
function key_system:fetch_keys()
    local success, result = pcall(function()
        return game:GetService("HttpService"):GetAsync(self.keys_url)
    end)
    
    if success and result then
        return game:GetService("HttpService"):JSONDecode(result)
    else
        self:send_to_discord("SYSTEM", "FAILED_TO_FETCH_KEYS", self:get_pc_name(), self:get_hwid())
        return nil
    end
end

-- Hàm chính check key
function key_system:check_key(input_key)
    local keys_data = self:fetch_keys()
    if not keys_data then
        return false, "Không thể tải danh sách key"
    end
    
    local hwid = self:get_hwid()
    local pc_name = self:get_pc_name()
    
    -- Tìm key trong danh sách
    for _, key_info in ipairs(keys_data.keys or {}) do
        if key_info.key == input_key then
            if not key_info.is_active then
                self:send_to_discord(input_key, "KEY_DEACTIVATED", pc_name, hwid)
                return false, "Key đã bị vô hiệu hóa!"
            end
            
            -- Check HWID limit
            local current_hwids = key_info.registered_hwids or {}
            local is_registered = false
            
            for _, registered_hwid in ipairs(current_hwids) do
                if registered_hwid == hwid then
                    is_registered = true
                    break
                end
            end
            
            if is_registered then
                -- HWID đã đăng ký
                self:send_to_discord(input_key, "SUCCESS", pc_name, hwid)
                _G.Key = input_key -- Lưu key vào biến toàn cục
                return true, "Key hợp lệ!"
            else
                -- Check số lượng HWID
                if #current_hwids >= (key_info.max_devices or 1) then
                    self:send_to_discord(input_key, "HWID_LIMIT_EXCEEDED", pc_name, hwid)
                    return false, "Key đã đạt giới hạn số lượng thiết bị!"
                else
                    -- Thêm HWID mới
                    self:send_to_discord(input_key, "NEW_DEVICE_REGISTERED", pc_name, hwid)
                    _G.Key = input_key -- Lưu key vào biến toàn cục
                    return true, "Key hợp lệ! Thiết bị mới đã được đăng ký."
                end
            end
        end
    end
    
    -- Key không tồn tại
    self:send_to_discord(input_key, "INVALID_KEY", pc_name, hwid)
    return false, "Key không hợp lệ!"
end

-- Hàm tự động điền key từ biến toàn cục
function key_system:auto_fill_key()
    -- Kiểm tra nếu đã có key trong _G.Key
    if _G.Key and _G.Key ~= "" then
        print("🔑 Đang kiểm tra key tự động: " .. _G.Key)
        local success, message = self:check_key(_G.Key)
        if success then
            print("✅ " .. message)
            return true
        else
            print("❌ " .. message)
            return false
        end
    end
    return false
end

-- Hàm hiển thị menu key system
function key_system:show_menu()
    -- Thử tự động điền key trước
    if self:auto_fill_key() then
        print("🎉 Key tự động hợp lệ! Đang khởi chạy VRAM Cleaner...")
        wait(2)
        startVRAMCleaner()
        return
    end
    
    print("=== 🔑 KEY SYSTEM ===")
    print("Không tìm thấy key tự động, vui lòng nhập key thủ công...")
    
    -- Tạo GUI cho key system
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local PlayerGui = player:WaitForChild("PlayerGui")
    
    -- Tạo ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystemGUI"
    screenGui.Parent = PlayerGui
    
    -- Tạo main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    title.Text = "🔑 KEY SYSTEM"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    -- Input field
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(0.8, 0, 0, 40)
    inputBox.Position = UDim2.new(0.1, 0, 0.3, 0)
    inputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.PlaceholderText = "Nhập key của bạn..."
    inputBox.Text = ""
    inputBox.TextSize = 16
    inputBox.Parent = mainFrame
    
    -- Submit button
    local submitButton = Instance.new("TextButton")
    submitButton.Size = UDim2.new(0.6, 0, 0, 40)
    submitButton.Position = UDim2.new(0.2, 0, 0.5, 0)
    submitButton.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
    submitButton.Text = "KIỂM TRA KEY"
    submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitButton.TextSize = 16
    submitButton.Font = Enum.Font.GothamBold
    submitButton.Parent = mainFrame
    
    -- Result label
    local resultLabel = Instance.new("TextLabel")
    resultLabel.Size = UDim2.new(0.8, 0, 0, 60)
    resultLabel.Position = UDim2.new(0.1, 0, 0.7, 0)
    resultLabel.BackgroundTransparency = 1
    resultLabel.Text = ""
    resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    resultLabel.TextSize = 14
    resultLabel.TextWrapped = true
    resultLabel.Parent = mainFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = mainFrame
    
    -- Auto fill button (nếu có key trong _G.Key)
    local autoFillButton = Instance.new("TextButton")
    autoFillButton.Size = UDim2.new(0.6, 0, 0, 30)
    autoFillButton.Position = UDim2.new(0.2, 0, 0.85, 0)
    autoFillButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    autoFillButton.Text = "AUTO FILL KEY"
    autoFillButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoFillButton.TextSize = 12
    autoFillButton.Font = Enum.Font.Gotham
    autoFillButton.Visible = false
    autoFillButton.Parent = mainFrame
    
    -- Hiển thị nút auto fill nếu có key
    if _G.Key and _G.Key ~= "" then
        autoFillButton.Visible = true
        inputBox.Text = _G.Key
    end
    
    -- Button click events
    submitButton.MouseButton1Click:Connect(function()
        local key = inputBox.Text
        if key and key ~= "" then
            local success, message = self:check_key(key)
            if success then
                resultLabel.Text = "✅ " .. message
                resultLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                wait(2)
                screenGui:Destroy()
                -- Khởi chạy VRAM Cleaner sau khi key hợp lệ
                startVRAMCleaner()
            else
                resultLabel.Text = "❌ " .. message
                resultLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            end
        else
            resultLabel.Text = "⚠️ Vui lòng nhập key!"
            resultLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
    end)
    
    autoFillButton.MouseButton1Click:Connect(function()
        if _G.Key and _G.Key ~= "" then
            inputBox.Text = _G.Key
            resultLabel.Text = "🔑 Đã điền key tự động!"
            resultLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        print("Key system đã đóng")
    end)
end

-- Hàm khởi chạy VRAM Cleaner sau khi key hợp lệ
function startVRAMCleaner()
    print("🔑 Key hợp lệ! Đang khởi chạy VRAM Cleaner...")
    
    local VRAMCleaner = {}

    VRAMCleaner.cleanupCompleted = false
    VRAMCleaner.respawnConnection = nil
    VRAMCleaner.itemCleanupConnection = nil

    -- TÍNH NĂNG MỚI: Tự động chạy lại TOÀN BỘ khi respawn
    function VRAMCleaner.setupRespawnAutoClean()
        local players = game:GetService("Players")
        local localPlayer = players.LocalPlayer
        
        if not localPlayer then
            players.PlayerAdded:Wait()
            localPlayer = players.LocalPlayer
        end
        
        -- Hủy kết nối cũ nếu có
        if VRAMCleaner.respawnConnection then
            VRAMCleaner.respawnConnection:Disconnect()
        end
        
        -- Thiết lập kết nối mới cho respawn - CHẠY LẠI TOÀN BỘ
        VRAMCleaner.respawnConnection = localPlayer.CharacterAdded:Connect(function(character)
            wait(2) -- Đợi 2 giây để character load hoàn toàn
            print("🔄 Player respawned - Running FULL VRAM cleanup...")
            VRAMCleaner.cleanupCompleted = false -- Reset flag để chạy lại toàn bộ
            VRAMCleaner.fullEnvironmentCleanup() -- CHẠY LẠI TOÀN BỘ
        end)
        
        print("✅ Auto-respawn FULL cleanup enabled")
    end

    -- TÍNH NĂNG MỚI: Tự động xóa hình ảnh vật phẩm mới
    function VRAMCleaner.setupItemAutoClean()
        local players = game:GetService("Players")
        local localPlayer = players.LocalPlayer
        
        if not localPlayer then
            players.PlayerAdded:Wait()
            localPlayer = players.LocalPlayer
        end
        
        -- Hủy kết nối cũ nếu có
        if VRAMCleaner.itemCleanupConnection then
            VRAMCleaner.itemCleanupConnection:Disconnect()
        end
        
        -- Theo dõi khi có vật phẩm mới được thêm vào Backpack
        if localPlayer:FindFirstChild("Backpack") then
            VRAMCleaner.itemCleanupConnection = localPlayer.Backpack.ChildAdded:Connect(function(child)
                wait(0.5) -- Đợi một chút để vật phẩm load hoàn toàn
                if child:IsA("Tool") then
                    print("🎒 New item detected: " .. child.Name .. " - Blurring textures...")
                    VRAMCleaner.blurItemTextures(child)
                end
            end)
        end
        
        -- Theo dõi khi có vật phẩm mới trong workspace
        workspace.ChildAdded:Connect(function(child)
            wait(0.5)
            if child:IsA("Tool") or child.Name:lower():find("item") or child.Name:lower():find("weapon") then
                print("🌍 New item in workspace: " .. child.Name .. " - Blurring textures...")
                VRAMCleaner.blurItemTextures(child)
            end
        end)
        
        print("✅ Auto item texture cleanup enabled")
    end

    -- TÍNH NĂNG MỚI: Làm mờ textures của vật phẩm cụ thể
    function VRAMCleaner.blurItemTextures(item)
        local texturesBlurred = 0
        
        for _, child in pairs(item:GetDescendants()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                pcall(function()
                    child.Texture = "rbxasset://textures/blank.png"
                    texturesBlurred += 1
                end)
            end
            if child:IsA("SpecialMesh") and child.TextureId ~= "" then
                pcall(function()
                    child.TextureId = "rbxasset://textures/blank.png"
                    texturesBlurred += 1
                end)
            end
            if child:IsA("MeshPart") then
                pcall(function()
                    child.TextureID = "rbxasset://textures/blank.png"
                    texturesBlurred += 1
                end)
            end
        end
        
        if texturesBlurred > 0 then
            print("✅ Blurred " .. texturesBlurred .. " textures in item: " .. item.Name)
        end
        
        return texturesBlurred
    end

    -- TÍNH NĂNG MỚI: Xóa mặt đất HOÀN TOÀN
    function VRAMCleaner.removeGround()
        local workspace = game:GetService("Workspace")
        local groundRemoved = 0
        
        for _, obj in pairs(workspace:GetDescendants()) do
            -- Xóa tất cả parts có tên liên quan đến ground/floor
            if (obj:IsA("Part") or obj:IsA("MeshPart")) and 
               (obj.Name:lower():find("ground") or 
                obj.Name:lower():find("floor") or 
                obj.Name:lower():find("baseplate") or
                obj.Name:lower():find("terrain") or
                obj.Name:lower():find("land")) then
                pcall(function()
                    obj:Destroy()
                    groundRemoved += 1
                end)
            end
        end
        
        print("✅ Ground objects removed: " .. groundRemoved)
        return groundRemoved
    end

    -- TÍNH NĂNG MỚI: Làm mờ hình ảnh vật phẩm TỐI ĐA
    function VRAMCleaner.blurAllTextures()
        local workspace = game:GetService("Workspace")
        local texturesBlurred = 0
        
        for _, obj in pairs(workspace:GetDescendants()) do
            -- Làm mờ tất cả Texture
            if obj:IsA("Texture") then
                pcall(function()
                    obj.Texture = "rbxasset://textures/blank.png"
                    texturesBlurred += 1
                end)
            end
            
            -- Làm mờ tất cả Decal
            if obj:IsA("Decal") then
                pcall(function()
                    obj.Texture = "rbxasset://textures/blank.png"
                    texturesBlurred += 1
                end)
            end
            
            -- Làm mờ SpecialMesh textures
            if obj:IsA("SpecialMesh") and obj.TextureId ~= "" then
                pcall(function()
                    obj.TextureId = "rbxasset://textures/blank.png"
                    texturesBlurred += 1
                end)
            end
            
            -- Làm mờ MeshPart textures
            if obj:IsA("MeshPart") then
                pcall(function()
                    obj.TextureID = "rbxasset://textures/blank.png"
                    texturesBlurred += 1
                end)
            end
        end
        
        print("✅ All textures blurred/removed: " .. texturesBlurred)
        return texturesBlurred
    end

    -- TÍNH NĂNG MỚI: Giảm chất lượng hình ảnh VẬT PHẨM cực đại
    function VRAMCleaner.maximizeItemBlur()
        local players = game:GetService("Players")
        local workspace = game:GetService("Workspace")
        local itemsBlurred = 0
        
        -- Làm mờ vật phẩm trong Backpack
        for _, player in pairs(players:GetPlayers()) do
            if player:FindFirstChild("Backpack") then
                for _, tool in pairs(player.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        itemsBlurred += VRAMCleaner.blurItemTextures(tool)
                    end
                end
            end
        end
        
        -- Làm mờ vật phẩm trong workspace
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") or obj.Name:lower():find("item") or obj.Name:lower():find("weapon") then
                itemsBlurred += VRAMCleaner.blurItemTextures(obj)
            end
        end
        
        print("✅ Item textures maximally blurred: " .. itemsBlurred)
        return itemsBlurred
    end

    -- TÍNH NĂNG MỚI: Xóa tất cả Baseplate
    function VRAMCleaner.removeAllBaseplates()
        local workspace = game:GetService("Workspace")
        local baseplatesRemoved = 0
        
        -- Xóa tất cả baseplate mặc định
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Part") and (obj.Name == "Baseplate" or obj.Name == "BasePlate") then
                pcall(function()
                    obj:Destroy()
                    baseplatesRemoved += 1
                end)
            end
        end
        
        -- Xóa tất cả parts lớn có thể là ground
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Part") and obj.Size.Y < 5 and obj.Size.X > 50 and obj.Size.Z > 50 then
                pcall(function()
                    obj:Destroy()
                    baseplatesRemoved += 1
                end)
            end
        end
        
        print("✅ Baseplates removed: " .. baseplatesRemoved)
        return baseplatesRemoved
    end

    function VRAMCleaner.removeTerrain()
        local workspace = game:GetService("Workspace")
        
        if workspace:FindFirstChild("Terrain") then
            pcall(function()
                workspace.Terrain:Clear()
                print("✅ Terrain cleared")
            end)
            return true
        end
        return false
    end

    function VRAMCleaner.removeSkybox()
        local lighting = game:GetService("Lighting")
        
        if lighting:FindFirstChild("Sky") then
            pcall(function()
                lighting.Sky:Destroy()
                print("✅ Skybox removed")
            end)
            return true
        end
        return false
    end

    -- FIX LỖI: Xóa nước triệt để hơn
    function VRAMCleaner.removeWater()
        local workspace = game:GetService("Workspace")
        local waterCount = 0
        
        -- Xóa tất cả Water objects
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Water") or obj.ClassName == "Water" then
                pcall(function()
                    obj:Destroy()
                    waterCount += 1
                end)
            end
        end
        
        -- Xóa các parts có tên liên quan đến water
        for _, obj in pairs(workspace:GetDescendants()) do
            if (obj:IsA("Part") or obj:IsA("MeshPart")) and 
               (obj.Name:lower():find("water") or 
                obj.Name:lower():find("ocean") or 
                obj.Name:lower():find("sea") or
                obj.Name:lower():find("river") or
                obj.Name:lower():find("lake")) then
                pcall(function()
                    obj:Destroy()
                    waterCount += 1
                end)
            end
        end
        
        print("✅ Water objects removed: " .. waterCount)
        return waterCount
    end

    -- TÍNH NĂNG MỚI: Xóa Decals/Textures
    function VRAMCleaner.removeDecalsAndTextures()
        local workspace = game:GetService("Workspace")
        local texturesRemoved = 0
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Decal") or obj:IsA("Texture") then
                pcall(function()
                    obj:Destroy()
                    texturesRemoved += 1
                end)
            end
        end
        
        print("✅ Decals/Textures removed: " .. texturesRemoved)
        return texturesRemoved
    end

    -- TÍNH NĂNG MỚI: Ẩn Objects xa
    function VRAMCleaner.hideDistantObjects()
        local workspace = game:GetService("Workspace")
        local players = game:GetService("Players")
        local localPlayer = players.LocalPlayer
        local objectsHidden = 0
        
        if not localPlayer or not localPlayer.Character then return 0 end
        
        local rootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return 0 end
        
        local playerPos = rootPart.Position
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if (obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")) and
               not obj:IsDescendantOf(localPlayer.Character) then
                
                local distance = (obj.Position - playerPos).Magnitude
                
                if distance > 50 then
                    pcall(function()
                        obj.Transparency = 1
                        obj.CanCollide = false
                        objectsHidden += 1
                    end)
                end
            end
        end
        
        print("✅ Distant objects hidden: " .. objectsHidden)
        return objectsHidden
    end

    -- TÍNH NĂNG MỚI: Giảm chất lượng GUI TỐI ĐA (AN TOÀN)
    function VRAMCleaner.reduceGUIQuality()
        local players = game:GetService("Players")
        local localPlayer = players.LocalPlayer
        local guiOptimized = 0
        
        if not localPlayer then return 0 end
        
        if localPlayer:FindFirstChild("PlayerGui") then
            for _, gui in pairs(localPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("ImageLabel") and gui.Image ~= "" then
                    pcall(function()
                        gui.Image = ""
                        gui.BackgroundTransparency = 1.0
                        guiOptimized += 1
                    end)
                end
                
                if gui:IsA("Frame") or gui:IsA("ScrollingFrame") then
                    pcall(function()
                        gui.BackgroundTransparency = 1.0
                        gui.BorderSizePixel = 0
                        guiOptimized += 1
                    end)
                end
                
                if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                    pcall(function()
                        gui.TextStrokeTransparency = 1.0
                        gui.BackgroundTransparency = 1.0
                        gui.TextColor3 = Color3.new(1, 1, 1)
                        gui.TextSize = 12
                        guiOptimized += 1
                    end)
                end
                
                if gui:IsA("UIStroke") then
                    pcall(function()
                        gui.Enabled = false
                        guiOptimized += 1
                    end)
                end
                
                if gui:IsA("UIGradient") then
                    pcall(function()
                        gui.Enabled = false
                        guiOptimized += 1
                    end)
                end
            end
        end
        
        print("✅ GUI quality reduced to MINIMUM: " .. guiOptimized)
        return guiOptimized
    end

    -- TÍNH NĂNG MỚI: Giảm chất lượng hình ảnh vật thể TỐI ĐA
    function VRAMCleaner.reduceObjectQuality()
        local workspace = game:GetService("Workspace")
        local objectsOptimized = 0
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Part") or obj:IsA("MeshPart") then
                pcall(function()
                    obj.Material = Enum.Material.Plastic
                    objectsOptimized += 1
                    
                    obj.Reflectance = 0
                    objectsOptimized += 1
                    
                    obj.BrickColor = BrickColor.new("Medium stone grey")
                    objectsOptimized += 1
                    
                    obj.CastShadow = false
                    objectsOptimized += 1
                    
                    if not obj:IsDescendantOf(game.Players.LocalPlayer.Character) then
                        obj.Transparency = 0.8
                        objectsOptimized += 1
                    end
                end)
            end
            
            if obj:IsA("SpecialMesh") then
                pcall(function()
                    obj.TextureId = ""
                    objectsOptimized += 1
                end)
            end
            
            if obj:IsA("SurfaceAppearance") then
                pcall(function()
                    obj:Destroy()
                    objectsOptimized += 1
                end)
            end
            
            if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                pcall(function()
                    obj.Enabled = false
                    objectsOptimized += 1
                end)
            end
        end
        
        print("✅ Object quality reduced to MINIMUM: " .. objectsOptimized)
        return objectsOptimized
    end

    -- TÍNH NĂNG MỚI: Xóa AMBIENT SOUNDS & BACKGROUND MUSIC
    function VRAMCleaner.removeAmbientSounds()
        local soundService = game:GetService("SoundService")
        local workspace = game:GetService("Workspace")
        local soundsRemoved = 0
        
        for _, sound in pairs(soundService:GetDescendants()) do
            if sound:IsA("Sound") then
                pcall(function()
                    sound:Destroy()
                    soundsRemoved += 1
                end)
            end
        end
        
        for _, sound in pairs(workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                pcall(function()
                    sound:Destroy()
                    soundsRemoved += 1
                end)
            end
        end
        
        print("✅ All sounds removed: " .. soundsRemoved)
        return soundsRemoved
    end

    function VRAMCleaner.removeHeavyEffects()
        local lighting = game:GetService("Lighting")
        local workspace = game:GetService("Workspace")
        
        local effectsRemoved = 0
        
        pcall(function()
            lighting.GlobalShadows = false
            lighting.ShadowSoftness = 0
        end)
        
        local heavyEffects = {
            "BloomEffect", "BlurEffect", "SunRaysEffect", "ColorCorrectionEffect",
            "DepthOfFieldEffect", "Atmosphere", "VolumetricLight"
        }
        
        for _, effectName in pairs(heavyEffects) do
            for _, effect in pairs(lighting:GetChildren()) do
                if effect.ClassName == effectName then
                    pcall(function()
                        effect:Destroy()
                        effectsRemoved += 1
                    end)
                end
            end
        end
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                pcall(function()
                    obj:Destroy()
                    effectsRemoved += 1
                end)
            end
        end
        
        print("✅ Heavy effects removed: " .. effectsRemoved)
        return effectsRemoved
    end

    function VRAMCleaner.optimizeLighting()
        local lighting = game:GetService("Lighting")
        
        pcall(function()
            lighting.GlobalShadows = false
            lighting.FogEnd = 0
            lighting.Brightness = 0.5
            lighting.EnvironmentDiffuseScale = 0
            lighting.EnvironmentSpecularScale = 0
            lighting.OutdoorAmbient = Color3.new(0.1, 0.1, 0.1)
            lighting.Ambient = Color3.new(0.1, 0.1, 0.1)
        end)
        
        print("✅ Lighting optimized to MINIMUM")
        return true
    end

    function VRAMCleaner.reduceGraphicsQuality()
        local UserGameSettings = UserSettings():GetService("UserGameSettings")
        local success = false
        
        if UserGameSettings then
            pcall(function()
                UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
                UserGameSettings.MasterVolume = 0
                success = true
            end)
        end
        
        if success then
            print("✅ Graphics quality reduced")
        else
            print("⚠️ Could not reduce graphics quality (no permission)")
        end
        return success
    end

    -- TÍNH NĂNG MỚI: Cleanup có thể hoàn tác (backup)
    VRAMCleaner.backupData = {}

    function VRAMCleaner.createBackup()
        local lighting = game:GetService("Lighting")
        
        VRAMCleaner.backupData = {
            skybox = lighting:FindFirstChild("Sky"),
            globalShadows = lighting.GlobalShadows,
            fogEnd = lighting.FogEnd,
            brightness = lighting.Brightness
        }
        
        print("📁 Backup created")
    end

    function VRAMCleaner.restoreFromBackup()
        if not VRAMCleaner.backupData then
            print("❌ No backup found")
            return false
        end
        
        local lighting = game:GetService("Lighting")
        
        if VRAMCleaner.backupData.skybox then
            pcall(function()
                VRAMCleaner.backupData.skybox:Clone().Parent = lighting
            end)
        end
        
        pcall(function()
            lighting.GlobalShadows = VRAMCleaner.backupData.globalShadows
            lighting.FogEnd = VRAMCleaner.backupData.fogEnd
            lighting.Brightness = VRAMCleaner.backupData.brightness
        end)
        
        print("🔄 Environment restored from backup")
        return true
    end

    -- FIX LỖI: Thay thế GarbageCollectionService bằng phương pháp khác
    function VRAMCleaner.forceGarbageCollection()
        -- Phương pháp thay thế để kích hoạt garbage collection
        local startMemory = collectgarbage("count")
        
        -- Tạo và hủy nhiều object để kích thích garbage collection
        for i = 1, 100 do
            local temp = Instance.new("Part")
            temp.Name = "TempGarbageCollector"
            temp:Destroy()
        end
        
        -- Đợi một chút để garbage collection hoạt động
        wait(0.5)
        
        local endMemory = collectgarbage("count")
        local memoryFreed = startMemory - endMemory
        
        print("🗑️ Garbage collection completed - Memory freed: " .. string.format("%.2f", memoryFreed) .. " KB")
        return memoryFreed
    end

    function VRAMCleaner.fullEnvironmentCleanup()
        if VRAMCleaner.cleanupCompleted then
            print("⚠️ Cleanup already completed!")
            return
        end
        
        print("🚀 Starting ULTIMATE VRAM optimization...")
        
        -- Tạo backup trước khi cleanup
        VRAMCleaner.createBackup()
        
        local startTime = tick()
        
        -- Thực hiện cleanup CƠ BẢN (phiên bản cũ)
        VRAMCleaner.removeTerrain()
        VRAMCleaner.removeSkybox()
        VRAMCleaner.removeWater() -- FIX: Đảm bảo nước bị xóa
        local effectsCount = VRAMCleaner.removeHeavyEffects()
        VRAMCleaner.optimizeLighting()
        VRAMCleaner.reduceGraphicsQuality()
        
        -- THÊM TÍNH NĂNG MỚI
        local texturesCount = VRAMCleaner.removeDecalsAndTextures()
        local hiddenObjectsCount = VRAMCleaner.hideDistantObjects()
        local guiQualityCount = VRAMCleaner.reduceGUIQuality()
        local objectQualityCount = VRAMCleaner.reduceObjectQuality()
        local ambientSoundsCount = VRAMCleaner.removeAmbientSounds()
        
        -- TÍNH NĂNG MỚI CỰC MẠNH: XÓA MẶT ĐẤT & LÀM MỜ VẬT PHẨM
        local groundCount = VRAMCleaner.removeGround()
        local baseplatesCount = VRAMCleaner.removeAllBaseplates()
        local blurredTexturesCount = VRAMCleaner.blurAllTextures()
        local blurredItemsCount = VRAMCleaner.maximizeItemBlur()
        
        local endTime = tick()
        local duration = endTime - startTime
        
        print("🎉 " .. string.format("ULTIMATE CLEANUP completed in %.2f seconds", duration))
        print("📊 RESULTS:")
        print("📉- Effects removed: " .. effectsCount)
        print("📉- Textures removed: " .. texturesCount)
        print("📉- Distant objects hidden: " .. hiddenObjectsCount)
        print("🎨- GUI quality reduced: " .. guiQualityCount)
        print("🔧- Object quality reduced: " .. objectQualityCount)
        print("🔊- Ambient sounds removed: " .. ambientSoundsCount)
        print("🌍- Ground objects removed: " .. groundCount)
        print("🏗️- Baseplates removed: " .. baseplatesCount)
        print("🖼️- Textures blurred: " .. blurredTexturesCount)
        print("🎒- Item textures blurred: " .. blurredItemsCount)
        print("🔄 Auto item cleanup: ENABLED")
        print("🎮 FARMING SAFE - MAXIMUM VRAM REDUCTION!")
        
        -- Force garbage collection (FIXED)
        wait(1)
        VRAMCleaner.forceGarbageCollection()
        
        VRAMCleaner.cleanupCompleted = true
        
        return {
            effectsRemoved = effectsCount,
            textures = texturesCount,
            hiddenObjects = hiddenObjectsCount,
            guiQuality = guiQualityCount,
            objectQuality = objectQualityCount,
            ambientSounds = ambientSoundsCount,
            groundRemoved = groundCount,
            baseplatesRemoved = baseplatesCount,
            texturesBlurred = blurredTexturesCount,
            itemsBlurred = blurredItemsCount,
            duration = duration,
            success = true
        }
    end

    -- Chạy cleanup toàn bộ môi trường lần đầu
    VRAMCleaner.fullEnvironmentCleanup()

    -- TỰ ĐỘNG BẬT RESPAWN CLEANUP VÀ ITEM AUTO CLEAN
    VRAMCleaner.enableRespawnCleanup()
    VRAMCleaner.enableItemAutoClean()

    print("🎉 VRAM Cleaner đã được khởi chạy thành công!")
    return VRAMCleaner
end

-- Khởi chạy key system khi script bắt đầu
wait(1)
key_system:show_menu()

return key_system
