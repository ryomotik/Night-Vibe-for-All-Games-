-- ==============================================================================
-- 🌙 NIGHT VIBE // UNIVERSAL ATMOSPHERE ENHANCER
-- Powered by WindUI (by Footagesus)
-- Created for @ryomotik
-- ==============================================================================

if _G.NightVibeCleanup then
    pcall(_G.NightVibeCleanup)
end

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- 1. Load WindUI Library
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- 2. Backup original lighting
local originalLighting = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    FogColor = Lighting.FogColor,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    ExposureCompensation = Lighting.ExposureCompensation,
    GlobalShadows = Lighting.GlobalShadows,
}

local originalEffectsBackup = {}

local function backupGameEffects()
    originalEffectsBackup = {}
    for _, child in ipairs(Lighting:GetChildren()) do
        if not child:GetAttribute("NightVibeInternal") then
            if child:IsA("PostProcessEffect") then
                originalEffectsBackup[child] = child.Enabled
            end
        end
    end
end

local function restoreGameLighting()
    for prop, val in pairs(originalLighting) do
        pcall(function()
            Lighting[prop] = val
        end)
    end
    for effect, state in pairs(originalEffectsBackup) do
        if effect and effect.Parent then
            pcall(function()
                effect.Enabled = state
            end)
        end
    end
    originalEffectsBackup = {}
end

-- 3. Custom Night Vibe Post-Processing
local customCC = Instance.new("ColorCorrectionEffect")
customCC.Name = "NightVibe_CC"
customCC:SetAttribute("NightVibeInternal", true)

local customBloom = Instance.new("BloomEffect")
customBloom.Name = "NightVibe_Bloom"
customBloom:SetAttribute("NightVibeInternal", true)

-- 4. Presets (Всё видно, 0 черноты, мягкий свет)
local Presets = {
    ["🕯️ Мягкий свет (True Tone)"] = {
        ChangeTime = false,
        ClockTime = 14,
        Brightness = 1.1,
        OutdoorAmbient = Color3.fromRGB(120, 120, 128),
        Ambient = Color3.fromRGB(110, 110, 118),
        CC_Brightness = 0.01,
        CC_Contrast = -0.04,
        CC_Saturation = 0.0,
        CC_Tint = Color3.fromRGB(252, 244, 230),
        BloomIntensity = 0.18,
        BloomSize = 10,
        BloomThreshold = 0.92,
    },
    ["🌙 Светлая ночь (Clear Night)"] = {
        ChangeTime = true,
        ClockTime = 0,
        Brightness = 1.3,
        OutdoorAmbient = Color3.fromRGB(115, 122, 145),
        Ambient = Color3.fromRGB(105, 112, 135),
        CC_Brightness = 0.02,
        CC_Contrast = -0.03,
        CC_Saturation = 0.05,
        CC_Tint = Color3.fromRGB(240, 244, 255),
        BloomIntensity = 0.22,
        BloomSize = 12,
        BloomThreshold = 0.88,
    },
    ["🌆 Тёплые сумерки (Cozy Dusk)"] = {
        ChangeTime = true,
        ClockTime = 17.8,
        Brightness = 1.2,
        OutdoorAmbient = Color3.fromRGB(125, 115, 120),
        Ambient = Color3.fromRGB(115, 105, 110),
        CC_Brightness = 0.01,
        CC_Contrast = -0.05,
        CC_Saturation = 0.08,
        CC_Tint = Color3.fromRGB(255, 238, 222),
        BloomIntensity = 0.25,
        BloomSize = 14,
        BloomThreshold = 0.86,
    },
    ["🌑 Минимал (Чистая ночь)"] = {
        ChangeTime = true,
        ClockTime = 0,
        Brightness = 1.15,
        OutdoorAmbient = Color3.fromRGB(100, 105, 120),
        Ambient = Color3.fromRGB(90, 95, 110),
        CC_Brightness = 0.0,
        CC_Contrast = -0.02,
        CC_Saturation = -0.02,
        CC_Tint = Color3.fromRGB(245, 246, 252),
        BloomIntensity = 0.15,
        BloomSize = 8,
        BloomThreshold = 0.94,
    }
}

local State = {
    Enabled = true,
    Preset = "🕯️ Мягкий свет (True Tone)",
    BrightnessMod = 1.0,
    Warmth = 0.6,
    AntiGlare = true,
    RemoveSunRays = true,
    SoftenBloom = true,
    RemoveFog = true,
    AntiRevert = true,
}

local function applyAtmosphere()
    if not State.Enabled then return end
    local p = Presets[State.Preset] or Presets["🕯️ Мягкий свет (True Tone)"]

    if p.ChangeTime then
        Lighting.ClockTime = p.ClockTime
    end
    Lighting.Brightness = p.Brightness * State.BrightnessMod
    Lighting.OutdoorAmbient = p.OutdoorAmbient
    Lighting.Ambient = p.Ambient
    Lighting.ExposureCompensation = 0.0

    if State.RemoveFog then
        Lighting.FogEnd = 100000
    end

    -- Настройка ColorCorrection
    customCC.Parent = Lighting
    customCC.Brightness = p.CC_Brightness
    customCC.Contrast = p.CC_Contrast
    customCC.Saturation = p.CC_Saturation

    -- Смешивание тёплого оттенка (Eye-Care True Tone)
    local baseTint = p.CC_Tint
    local warmShift = Color3.fromRGB(255, 230, 200)
    local w = math.clamp(State.Warmth, 0, 1)
    customCC.TintColor = Color3.new(
        baseTint.R + (warmShift.R - baseTint.R) * w,
        baseTint.G + (warmShift.G - baseTint.G) * w,
        baseTint.B + (warmShift.B - baseTint.B) * w
    )

    -- Настройка мягкого Bloom
    if State.SoftenBloom then
        customBloom.Parent = Lighting
        customBloom.Intensity = p.BloomIntensity
        customBloom.Size = p.BloomSize
        customBloom.Threshold = p.BloomThreshold
    else
        customBloom.Parent = nil
    end

    -- Отключение слепящих эффектов игры
    for _, child in ipairs(Lighting:GetChildren()) do
        if not child:GetAttribute("NightVibeInternal") then
            if State.RemoveSunRays and child:IsA("SunRaysEffect") then
                child.Enabled = false
            end
            if State.SoftenBloom and child:IsA("BloomEffect") then
                child.Enabled = false
            end
        end
    end
end

local function enableNightVibe()
    backupGameEffects()
    State.Enabled = true
    applyAtmosphere()
end

local function disableNightVibe()
    State.Enabled = false
    customCC.Parent = nil
    customBloom.Parent = nil
    restoreGameLighting()
end

-- Страж Anti-Revert
local guardTimer = 0
local guardConn = RunService.Heartbeat:Connect(function(dt)
    if not State.Enabled or not State.AntiRevert then return end
    guardTimer = guardTimer + dt
    if guardTimer >= 0.5 then
        guardTimer = 0
        local p = Presets[State.Preset] or Presets["🕯️ Мягкий свет (True Tone)"]
        if p.ChangeTime and math.abs(Lighting.ClockTime - p.ClockTime) > 0.1 then
            Lighting.ClockTime = p.ClockTime
        end
        if Lighting.Brightness > 1.6 or customCC.Parent ~= Lighting then
            applyAtmosphere()
        end
    end
end)

enableNightVibe()

-- ==============================================================================
-- WINDUI WINDOW CREATION
-- ==============================================================================
local Window = WindUI:CreateWindow({
    Title = "Night Vibe",
    Icon = "moon",
    Author = "by ryomotik",
    Folder = "NightVibeConfig",
    Size = UDim2.fromOffset(560, 440),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180,
    HasOutline = true,
})

-- Вкладка 1: Главное освещение
local MainTab = Window:Tab({
    Title = "Освещение",
    Icon = "moon",
})

local MasterSection = MainTab:Section({
    Title = "Основное управление",
    Opened = true,
})

MasterSection:Toggle({
    Title = "Ночной режим (Night Vibe)",
    Desc = "Включает или выключает мягкий комфортный свет",
    Value = State.Enabled,
    Callback = function(val)
        if val then
            enableNightVibe()
        else
            disableNightVibe()
        end
    end,
})

local PresetsSection = MainTab:Section({
    Title = "Выбор атмосферы",
    Opened = true,
})

PresetsSection:Dropdown({
    Title = "Пресет освещения",
    Desc = "Выберите подходящий стиль под вашу игру",
    Values = {
        "🕯️ Мягкий свет (True Tone)",
        "🌙 Светлая ночь (Clear Night)",
        "🌆 Тёплые сумерки (Cozy Dusk)",
        "🌑 Минимал (Чистая ночь)"
    },
    Default = State.Preset,
    Callback = function(selected)
        State.Preset = selected
        if State.Enabled then
            applyAtmosphere()
        end
    end,
})

PresetsSection:Slider({
    Title = "Яркость окружения",
    Desc = "Регулировка общей видимости (по умолчанию 100%)",
    Min = 50,
    Max = 180,
    Default = 100,
    Rounding = 0,
    Callback = function(val)
        State.BrightnessMod = val / 100
        if State.Enabled then
            applyAtmosphere()
        end
    end,
})

-- Вкладка 2: Защита глаз (Eye-Care)
local EyeTab = Window:Tab({
    Title = "Защита глаз",
    Icon = "eye",
})

local EyeSection = EyeTab:Section({
    Title = "Фильтр синего света (True Tone)",
    Opened = true,
})

EyeSection:Slider({
    Title = "Теплота фильтра",
    Desc = "Снижает раздражающий синий спектр в темноте",
    Min = 0,
    Max = 100,
    Default = 60,
    Rounding = 0,
    Callback = function(val)
        State.Warmth = val / 100
        if State.Enabled then
            applyAtmosphere()
        end
    end,
})

local AntiGlareSection = EyeTab:Section({
    Title = "Антиблик и защита от пересвета",
    Opened = true,
})

AntiGlareSection:Toggle({
    Title = "Убрать лучи солнца (SunRays)",
    Desc = "Отключает ослепляющие солнечные лучи в камеру",
    Value = State.RemoveSunRays,
    Callback = function(val)
        State.RemoveSunRays = val
        if State.Enabled then
            applyAtmosphere()
        end
    end,
})

AntiGlareSection:Toggle({
    Title = "Смягчить ядовитый Bloom",
    Desc = "Убирает белую пелену и агрессивное свечение текстур",
    Value = State.SoftenBloom,
    Callback = function(val)
        State.SoftenBloom = val
        if State.Enabled then
            applyAtmosphere()
        end
    end,
})

AntiGlareSection:Toggle({
    Title = "Убрать слепящий туман",
    Desc = "Очищает горизонт от густого белого тумана",
    Value = State.RemoveFog,
    Callback = function(val)
        State.RemoveFog = val
        if State.Enabled then
            applyAtmosphere()
        end
    end,
})

-- Вкладка 3: Настройки
local SettingsTab = Window:Tab({
    Title = "Настройки",
    Icon = "settings",
})

local SystemSection = SettingsTab:Section({
    Title = "Система и защита",
    Opened = true,
})

SystemSection:Toggle({
    Title = "Анти-сброс (Anti-Revert)",
    Desc = "Блокирует попытки скриптов игры включить день",
    Value = State.AntiRevert,
    Callback = function(val)
        State.AntiRevert = val
    end,
})

SystemSection:Button({
    Title = "Восстановить стандартную графику",
    Desc = "Сбрасывает все визуальные настройки к исходным",
    Callback = function()
        disableNightVibe()
        WindUI:Notify({
            Title = "Night Vibe",
            Content = "Оригинальное освещение игры восстановлено!",
            Duration = 3,
            Icon = "check",
        })
    end,
})

-- Очистка при закрытии
_G.NightVibeCleanup = function()
    if guardConn then
        guardConn:Disconnect()
        guardConn = nil
    end
    disableNightVibe()
    pcall(function()
        Window:Destroy()
    end)
    _G.NightVibeCleanup = nil
end

WindUI:Notify({
    Title = "Night Vibe",
    Content = "Загружен интерфейс WindUI! Приятной игры.",
    Duration = 4,
    Icon = "moon",
})
