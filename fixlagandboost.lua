local ValidKeys = {
    "DUOG1603",
    "concu"
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
        wait(5) -- Đợi 5 giây để character load hoàn toàn
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

-- TÍNH NĂNG MỚI: Cleanup từng phần
function VRAMCleaner.partialCleanup(options)
    local defaultOptions = {
        terrain = true,
        skybox = true,
        water = true,
        effects = true,
        lighting = true,
        graphics = true,
        textures = true,
        distantObjects = true,
        guiQuality = true,
        objectQuality = true,
        ambientSounds = true,
        ground = true,
        baseplates = true,
        blurTextures = true,
        blurItems = true,
        autoItemClean = true
    }
    
    options = options or defaultOptions
    
    print("🔧 Starting partial cleanup...")
    
    -- Bật auto item cleanup nếu được yêu cầu
    if options.autoItemClean then
        VRAMCleaner.setupItemAutoClean()
    end
    
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
    if options.ground then VRAMCleaner.removeGround() end
    if options.baseplates then VRAMCleaner.removeAllBaseplates() end
    if options.blurTextures then VRAMCleaner.blurAllTextures() end
    if options.blurItems then VRAMCleaner.maximizeItemBlur() end
    
    print("✅ Partial cleanup completed!")
end

-- TÍNH NĂNG MỚI: Bật auto-cleanup khi respawn
function VRAMCleaner.enableRespawnCleanup()
    VRAMCleaner.setupRespawnAutoClean()
    print("✅ Full respawn cleanup ENABLED - Will run complete cleanup on every respawn")
end

-- TÍNH NĂNG MỚI: Tắt auto-cleanup khi respawn
function VRAMCleaner.disableRespawnCleanup()
    if VRAMCleaner.respawnConnection then
        VRAMCleaner.respawnConnection:Disconnect()
        VRAMCleaner.respawnConnection = nil
        print("🛑 Respawn cleanup DISABLED")
    else
        print("ℹ️ No active respawn cleanup to disable")
    end
end

-- TÍNH NĂNG MỚI: Bật/tắt auto item cleanup
function VRAMCleaner.enableItemAutoClean()
    VRAMCleaner.setupItemAutoClean()
    print("✅ Auto item cleanup ENABLED - Will blur new items automatically")
end

function VRAMCleaner.disableItemAutoClean()
    if VRAMCleaner.itemCleanupConnection then
        VRAMCleaner.itemCleanupConnection:Disconnect()
        VRAMCleaner.itemCleanupConnection = nil
        print("🛑 Auto item cleanup DISABLED")
    else
        print("ℹ️ No active item cleanup to disable")
    end
end

-- Chạy cleanup toàn bộ môi trường lần đầu
VRAMCleaner.fullEnvironmentCleanup()

-- TỰ ĐỘNG BẬT RESPAWN CLEANUP VÀ ITEM AUTO CLEAN
VRAMCleaner.enableRespawnCleanup()
VRAMCleaner.enableItemAutoClean()

return VRAMCleaner

