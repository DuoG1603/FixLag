local ValidKeys = {
    "DUOG1603"
}

local function isValidKey(key)
    for _, v in ipairs(ValidKeys) do
        if key == v then
            return true
        end
    end
    return false
end

if _G.Key == nil then
    game.Players.LocalPlayer:Kick("⚠️ Kiếm Key mà cho vô bạn ơi!")
    return
end

if typeof(_G.Key) ~= "string" then
    game.Players.LocalPlayer:Kick("⚠️ Biến mẹ mày đi!")
    return
end

if not isValidKey(_G.Key) then
    game.Players.LocalPlayer:Kick("⚠️ DM chủ script để lấy key đúng bạn ơi!")
    return
end

print("🎉 Key hợp lệ! Đang load script Fix Lag...")


local VRAMCleaner = {}

VRAMCleaner.cleanupCompleted = false

function VRAMCleaner.removeTerrain()
    local workspace = game:GetService("Workspace")
    
    if workspace:FindFirstChild("Terrain") then
        workspace.Terrain:Clear()
        print("✅ Terrain cleared")
        return true
    end
    return false
end

function VRAMCleaner.removeSkybox()
    local lighting = game:GetService("Lighting")
    
    if lighting:FindFirstChild("Sky") then
        lighting.Sky:Destroy()
        print("✅ Skybox removed")
        return true
    end
    return false
end

function VRAMCleaner.removeWater()
    local workspace = game:GetService("Workspace")
    local waterCount = 0
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Water") or obj.Name:lower():find("water") or obj.ClassName == "Water" then
            obj:Destroy()
            waterCount += 1
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
            obj:Destroy()
            texturesRemoved += 1
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
            
            if distance > 100 then  -- Objects xa hơn 100 studs
                obj.Transparency = 1
                obj.CanCollide = false
                objectsHidden += 1
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
            -- XÓA HOÀN TOÀN hình ảnh trong GUI (tiết kiệm VRAM nhất)
            if gui:IsA("ImageLabel") and gui.Image ~= "" then
                gui.Image = ""  -- Xóa hình ảnh hoàn toàn
                gui.BackgroundTransparency = 1.0  -- Làm trong suốt hoàn toàn
                guiOptimized += 1
            end
            
            -- Giảm chất lượng Frame tối đa - TRONG SUỐT HOÀN TOÀN
            if gui:IsA("Frame") or gui:IsA("ScrollingFrame") then
                gui.BackgroundTransparency = 1.0  -- Trong suốt hoàn toàn
                gui.BorderSizePixel = 0  -- Xóa viền
                guiOptimized += 1
            end
            
            -- Giảm chất lượng Text tối đa nhưng vẫn đọc được
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                gui.TextStrokeTransparency = 1.0  -- Xóa viền chữ hoàn toàn
                gui.BackgroundTransparency = 1.0  -- Nền trong suốt
                gui.TextColor3 = Color3.new(1, 1, 1)  -- Chữ trắng đơn giản
                gui.TextSize = 12  -- Font size nhỏ nhất
                guiOptimized += 1
            end
            
            -- Xóa tất cả UIStroke effects
            if gui:IsA("UIStroke") then
                gui.Enabled = false
                guiOptimized += 1
            end
            
            -- Xóa tất cả UIGradient effects
            if gui:IsA("UIGradient") then
                gui.Enabled = false
                guiOptimized += 1
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
            -- Đổi TẤT CẢ materials thành Plastic (nhẹ nhất)
            obj.Material = Enum.Material.Plastic
            objectsOptimized += 1
            
            -- Xóa reflectivity hoàn toàn
            obj.Reflectance = 0
            objectsOptimized += 1
            
            -- Đổi màu thành xám đơn giản cho TẤT CẢ objects
            obj.Color = Color3.new(0.6, 0.6, 0.6)
            objectsOptimized += 1
            
            -- Tắt cast shadow hoàn toàn
            obj.CastShadow = false
            objectsOptimized += 1
        end
        
        -- Xóa texture từ SpecialMesh hoàn toàn
        if obj:IsA("SpecialMesh") then
            obj.TextureId = ""  -- Xóa texture
            objectsOptimized += 1
        end
        
        -- Xóa SurfaceAppearance (Roblox's new material system)
        if obj:IsA("SurfaceAppearance") then
            obj:Destroy()
            objectsOptimized += 1
        end
        
        -- Xóa tất cả PointLight, SpotLight, SurfaceLight
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = false
            objectsOptimized += 1
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
    
    -- Xóa tất cả sounds trong SoundService
    for _, sound in pairs(soundService:GetDescendants()) do
        if sound:IsA("Sound") then
            sound:Destroy()
            soundsRemoved += 1
        end
    end
    
    -- Xóa tất cả sounds trong workspace
    for _, sound in pairs(workspace:GetDescendants()) do
        if sound:IsA("Sound") then
            sound:Destroy()
            soundsRemoved += 1
        end
    end
    
    print("✅ All sounds removed: " .. soundsRemoved)
    return soundsRemoved
end

function VRAMCleaner.removeHeavyEffects()
    local lighting = game:GetService("Lighting")
    local workspace = game:GetService("Workspace")
    
    local effectsRemoved = 0
    
    -- Tắt hiệu ứng trong Lighting
    lighting.GlobalShadows = false
    lighting.ShadowSoftness = 0
    
    -- Xóa các post-effect nặng
    local heavyEffects = {
        "BloomEffect", "BlurEffect", "SunRaysEffect", "ColorCorrectionEffect",
        "DepthOfFieldEffect", "Atmosphere", "VolumetricLight"
    }
    
    for _, effectName in pairs(heavyEffects) do
        for _, effect in pairs(lighting:GetChildren()) do
            if effect.ClassName == effectName then
                effect:Destroy()
                effectsRemoved += 1
            end
        end
    end
    
    -- Xóa particle effects trong workspace
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj:Destroy()
            effectsRemoved += 1
        end
    end
    
    print("✅ Heavy effects removed: " .. effectsRemoved)
    return effectsRemoved
end

function VRAMCleaner.optimizeLighting()
    local lighting = game:GetService("Lighting")
    
    lighting.GlobalShadows = false
    lighting.FogEnd = 0
    lighting.Brightness = 1.0  -- Giảm độ sáng tối đa
    lighting.EnvironmentDiffuseScale = 0
    lighting.EnvironmentSpecularScale = 0
    lighting.OutdoorAmbient = Color3.new(0.2, 0.2, 0.2)  -- Màu tối nhất
    lighting.Ambient = Color3.new(0.2, 0.2, 0.2)  -- Màu ambient tối nhất
    
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

-- TÍNH NĂNG MỚI: Kiểm tra FPS trước và sau
function VRAMCleaner.getFPS()
    local RunService = game:GetService("RunService")
    local fps = 0
    local frameCount = 0
    local lastCheck = tick()
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        if tick() - lastCheck >= 1 then
            fps = frameCount
            frameCount = 0
            lastCheck = tick()
            connection:Disconnect()
        end
    end)
    
    wait(1.1)
    return fps
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

-- TÍNH NĂNG MỚI: Khôi phục từ backup
function VRAMCleaner.restoreFromBackup()
    if not VRAMCleaner.backupData then
        print("❌ No backup found")
        return false
    end
    
    local lighting = game:GetService("Lighting")
    
    if VRAMCleaner.backupData.skybox then
        VRAMCleaner.backupData.skybox:Clone().Parent = lighting
    end
    
    lighting.GlobalShadows = VRAMCleaner.backupData.globalShadows
    lighting.FogEnd = VRAMCleaner.backupData.fogEnd
    lighting.Brightness = VRAMCleaner.backupData.brightness
    
    print("🔄 Environment restored from backup")
    return true
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
    VRAMCleaner.removeWater()
    local effectsCount = VRAMCleaner.removeHeavyEffects()
    VRAMCleaner.optimizeLighting()
    VRAMCleaner.reduceGraphicsQuality()
    
    -- THÊM TÍNH NĂNG MỚI
    local texturesCount = VRAMCleaner.removeDecalsAndTextures()
    local hiddenObjectsCount = VRAMCleaner.hideDistantObjects()
    local guiQualityCount = VRAMCleaner.reduceGUIQuality()      -- MỚI: Giảm chất lượng GUI TỐI ĐA
    local objectQualityCount = VRAMCleaner.reduceObjectQuality() -- MỚI: Giảm chất lượng vật thể TỐI ĐA
    local ambientSoundsCount = VRAMCleaner.removeAmbientSounds() -- MỚI: Xóa ambient sounds
    
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
    print("🎮 FARMING SAFE - MAXIMUM VRAM REDUCTION!")
    
    -- Force garbage collection
    wait(1)
    game:GetService("GarbageCollectionService"):CollectGarbage()
    
    VRAMCleaner.cleanupCompleted = true
    
    return {
        effectsRemoved = effectsCount,
        textures = texturesCount,
        hiddenObjects = hiddenObjectsCount,
        guiQuality = guiQualityCount,
        objectQuality = objectQualityCount,
        ambientSounds = ambientSoundsCount,
        duration = duration,
        success = true
    }
end

-- TÍNH NĂNG MỚI: Cleanup từng phần (cập nhật thêm tính năng mới)
function VRAMCleaner.partialCleanup(options)
    local defaultOptions = {
        terrain = true,
        skybox = true,
        water = true,
        effects = true,
        lighting = true,
        graphics = true,
        textures = true,           -- Xóa Decals/Textures
        distantObjects = true,     -- Ẩn Objects xa
        guiQuality = true,         -- MỚI: Giảm chất lượng GUI
        objectQuality = true,      -- MỚI: Giảm chất lượng vật thể
        ambientSounds = true       -- MỚI: Xóa ambient sounds
    }
    
    options = options or defaultOptions
    
    print("🔧 Starting partial cleanup...")
    
    if options.terrain then VRAMCleaner.removeTerrain() end
    if options.skybox then VRAMCleaner.removeSkybox() end
    if options.water then VRAMCleaner.removeWater() end
    if options.effects then VRAMCleaner.removeHeavyEffects() end
    if options.lighting then VRAMCleaner.optimizeLighting() end
    if options.graphics then VRAMCleaner.reduceGraphicsQuality() end
    if options.textures then VRAMCleaner.removeDecalsAndTextures() end
    if options.distantObjects then VRAMCleaner.hideDistantObjects() end
    if options.guiQuality then VRAMCleaner.reduceGUIQuality() end
    if options.objectQuality then VRAMCleaner.reduceObjectQuality() end
    if options.ambientSounds then VRAMCleaner.removeAmbientSounds() end
    
    print("✅ Partial cleanup completed!")
end

-- Chạy cleanup toàn bộ môi trường
VRAMCleaner.fullEnvironmentCleanup()

return VRAMCleaner


