local VRAMCleaner = {}

-- Biến để theo dõi trạng thái
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
    lighting.Brightness = 2
    lighting.EnvironmentDiffuseScale = 0
    lighting.EnvironmentSpecularScale = 0
    lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
    
    print("✅ Lighting optimized")
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
    
    -- Đây là cách đơn giản để ước tính FPS
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
    
    print("🚀 Starting environment VRAM optimization...")
    
    -- Tạo backup trước khi cleanup
    VRAMCleaner.createBackup()
    
    local startTime = tick()
    
    -- Thực hiện cleanup
    VRAMCleaner.removeTerrain()
    VRAMCleaner.removeSkybox()
    VRAMCleaner.removeWater()
    local effectsCount = VRAMCleaner.removeHeavyEffects()
    VRAMCleaner.optimizeLighting()
    VRAMCleaner.reduceGraphicsQuality()
    
    local endTime = tick()
    local duration = endTime - startTime
    
    print("🎉 " .. string.format("Environment cleanup completed in %.2f seconds", duration))
    print("📉 VRAM should be significantly reduced!")
    
    -- Force garbage collection
    wait(1)
    game:GetService("GarbageCollectionService"):CollectGarbage()
    
    VRAMCleaner.cleanupCompleted = true
    
    return {
        effectsRemoved = effectsCount,
        duration = duration,
        success = true
    }
end

-- TÍNH NĂNG MỚI: Cleanup từng phần
function VRAMCleaner.partialCleanup(options)
    local defaultOptions = {
        terrain = true,
        skybox = true,
        water = true,
        effects = true,
        lighting = true,
        graphics = true
    }
    
    options = options or defaultOptions
    
    print("🔧 Starting partial cleanup...")
    
    if options.terrain then VRAMCleaner.removeTerrain() end
    if options.skybox then VRAMCleaner.removeSkybox() end
    if options.water then VRAMCleaner.removeWater() end
    if options.effects then VRAMCleaner.removeHeavyEffects() end
    if options.lighting then VRAMCleaner.optimizeLighting() end
    if options.graphics then VRAMCleaner.reduceGraphicsQuality() end
    
    print("✅ Partial cleanup completed!")
end

-- Chạy cleanup toàn bộ môi trường
VRAMCleaner.fullEnvironmentCleanup()

-- Ví dụ sử dụng các tính năng mới:
-- VRAMCleaner.partialCleanup({terrain = true, effects = true}) -- Chỉ xóa terrain và effects
-- VRAMCleaner.restoreFromBackup() -- Khôi phục môi trường

return VRAMCleaner