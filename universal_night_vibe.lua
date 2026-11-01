-- ==============================================================================
-- 🌙 NIGHT COMFORT // ANTI-GLARE & EYE-CARE (UNIVERSAL)
-- Сделано для игры в темноте: убирает выжигающий глаза пересвет,
-- НЕ делая игру глухой чернотой. Всё видно чётко и мягко.
-- ==============================================================================

if _G.NightComfortCleanup then
    pcall(_G.NightComfortCleanup)
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Безопасный контейнер GUI
local function getGuiContainer()
    local container = nil
    pcall(function()
        if gethui then
            container = gethui()
        elseif syn and syn.protect_gui then
            local g = Instance.new("Folder")
            syn.protect_gui(g)
            g.Parent = CoreGui
            container = g
        elseif CoreGui then
            container = CoreGui
        end
    end)
    if not container then
        container = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    return container
end

-- ==============================================================================
-- БЭКАП ОРИГИНАЛЬНОГО ОСВЕЩЕНИЯ ИГРЫ
-- ==============================================================================
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
        if not child:GetAttribute("NightComfortInternal") then
            if child:IsA("PostProcessEffect") then
                originalEffectsBackup[child] = child.Enabled
                -- Отключаем слепящие эффекты игры (SunRays и ядерный Bloom)
                if child:IsA("SunRaysEffect") or child:IsA("BloomEffect") then
                    child.Enabled = false
                end
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

-- ==============================================================================
-- НАШИ МЯГКИЕ ПОСТ-ЭФФЕКТЫ (Защита глаз от пересвета)
-- ==============================================================================
local customCC = Instance.new("ColorCorrectionEffect")
customCC.Name = "NightComfort_CC"
customCC:SetAttribute("NightComfortInternal", true)

local customBloom = Instance.new("BloomEffect")
customBloom.Name = "NightComfort_Bloom"
customBloom:SetAttribute("NightComfortInternal", true)

-- ==============================================================================
-- РЕЖИМЫ: ВСЁ ВИДНО, НО НЕТ ВЫЖИГАЮЩЕГО СВЕТА
-- ==============================================================================
local Modes = {
    -- Режим 1: Мягкий True Tone (Оригинальное время, но белый не слепит)
    SoftComfort = {
        Name = "🕯️ Мягкий свет",
        Desc = "Убирает пересветы, делает свет тёплым и мягким. 100% видимость.",
        ChangeTime = false,
        ClockTime = 14,
        Brightness = 1.1,
        OutdoorAmbient = Color3.fromRGB(120, 120, 128),
        Ambient = Color3.fromRGB(110, 110, 118),
        CC_Brightness = 0.01,
        CC_Contrast = -0.04, -- Сжимает контраст: яркое становится мягче, тёмное - светлее
        CC_Saturation = 0.0,
        CC_Tint = Color3.fromRGB(252, 244, 230), -- Тёплый фильтр синего
        BloomIntensity = 0.18,
        BloomSize = 10,
        BloomThreshold = 0.92,
    },
    -- Режим 2: Светлая уютная ночь (Вайб ночи, но тени подсвечены, 0 черноты)
    ClearNight = {
        Name = "🌙 Светлая ночь",
        Desc = "Ночной вайб, но всё видно как днём. Никакой чернухи в тенях.",
        ChangeTime = true,
        ClockTime = 0,
        Brightness = 1.3,
        OutdoorAmbient = Color3.fromRGB(115, 122, 145), -- Светлый лунный эмбиент
        Ambient = Color3.fromRGB(105, 112, 135),        -- Тени видны отчётливо
        CC_Brightness = 0.02,
        CC_Contrast = -0.03,
        CC_Saturation = 0.05,
        CC_Tint = Color3.fromRGB(240, 244, 255),
        BloomIntensity = 0.22,
        BloomSize = 12,
        BloomThreshold = 0.88,
    },
    -- Режим 3: Тёплые сумерки (Идеальный баланс для тёмной комнаты)
    CozyDusk = {
        Name = "🌆 Сумерки",
        Desc = "Приятные расслабляющие сумерки. Мягкие тени и глубокий уют.",
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
    }
}

local CurrentState = {
    Enabled = true,
    ModeKey = "SoftComfort",
    Warmth = 0.6,
}

local function applyComfortSettings()
    if not CurrentState.Enabled then return end
    local m = Modes[CurrentState.ModeKey] or Modes.SoftComfort

    if m.ChangeTime then
        Lighting.ClockTime = m.ClockTime
    end
    Lighting.Brightness = m.Brightness
    Lighting.OutdoorAmbient = m.OutdoorAmbient
    Lighting.Ambient = m.Ambient
    Lighting.ExposureCompensation = 0.0
    Lighting.FogEnd = 100000

    customCC.Parent = Lighting
    customCC.Brightness = m.CC_Brightness
    customCC.Contrast = m.CC_Contrast
    customCC.Saturation = m.CC_Saturation

    local baseTint = m.CC_Tint
    local warmShift = Color3.fromRGB(255, 232, 205)
    local w = CurrentState.Warmth
    customCC.TintColor = Color3.new(
        baseTint.R + (warmShift.R - baseTint.R) * w,
        baseTint.G + (warmShift.G - baseTint.G) * w,
        baseTint.B + (warmShift.B - baseTint.B) * w
    )

    customBloom.Parent = Lighting
    customBloom.Intensity = m.BloomIntensity
    customBloom.Size = m.BloomSize
    customBloom.Threshold = m.BloomThreshold
end

local function enableComfort()
    backupGameEffects()
    CurrentState.Enabled = true
    applyComfortSettings()
end

local function disableComfort()
    CurrentState.Enabled = false
    customCC.Parent = nil
    customBloom.Parent = nil
    restoreGameLighting()
end

local guardTimer = 0
local guardConnection = RunService.Heartbeat:Connect(function(dt)
    if not CurrentState.Enabled then return end
    guardTimer = guardTimer + dt
    if guardTimer >= 0.5 then
        guardTimer = 0
        local m = Modes[CurrentState.ModeKey] or Modes.SoftComfort
        if m.ChangeTime and math.abs(Lighting.ClockTime - m.ClockTime) > 0.1 then
            Lighting.ClockTime = m.ClockTime
        end
        if Lighting.Brightness > 1.6 or customCC.Parent ~= Lighting then
            applyComfortSettings()
        end
    end
end)

enableComfort()

-- ==============================================================================
-- МИНИМАЛИСТИЧНЫЙ КОМПАКТНЫЙ WIDGET
-- ==============================================================================
local guiContainer = getGuiContainer()
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NightComfort_PillUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    ScreenGui.Parent = guiContainer
end)

local Pill = Instance.new("Frame")
Pill.Name = "Pill"
Pill.Size = UDim2.new(0, 310, 0, 38)
Pill.Position = UDim2.new(0.5, -155, 0, 18)
Pill.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
Pill.BackgroundTransparency = 0.12
Pill.BorderSizePixel = 0
Pill.Active = true
Pill.Parent = ScreenGui

local PillCorner = Instance.new("UICorner")
PillCorner.CornerRadius = UDim.new(1, 0)
PillCorner.Parent = Pill

local PillStroke = Instance.new("UIStroke")
PillStroke.Thickness = 1.2
PillStroke.Color = Color3.fromRGB(60, 68, 88)
PillStroke.Transparency = 0.3
PillStroke.Parent = Pill

-- Перетаскивание
local dragging = false
local dragStart, startPos
Pill.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Pill.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Pill.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Вкл/Выкл
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 30, 0, 30)
ToggleBtn.Position = UDim2.new(0, 4, 0.5, -15)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 125, 75)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "🌙"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 14
ToggleBtn.BorderSizePixel = 0
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = Pill

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

-- Переключение режимов
local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 185, 0, 30)
ModeBtn.Position = UDim2.new(0, 38, 0.5, -15)
ModeBtn.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
ModeBtn.Font = Enum.Font.GothamMedium
ModeBtn.Text = Modes[CurrentState.ModeKey].Name
ModeBtn.TextColor3 = Color3.fromRGB(220, 230, 250)
ModeBtn.TextSize = 12
ModeBtn.BorderSizePixel = 0
ModeBtn.AutoButtonColor = false
ModeBtn.Parent = Pill

local ModeCorner = Instance.new("UICorner")
ModeCorner.CornerRadius = UDim.new(0, 8)
ModeCorner.Parent = ModeBtn

-- Переключение теплоты
local WarmBtn = Instance.new("TextButton")
WarmBtn.Size = UDim2.new(0, 50, 0, 30)
WarmBtn.Position = UDim2.new(0, 227, 0.5, -15)
WarmBtn.BackgroundColor3 = Color3.fromRGB(36, 32, 24)
WarmBtn.Font = Enum.Font.GothamBold
WarmBtn.Text = "ТЁПЛ"
WarmBtn.TextColor3 = Color3.fromRGB(255, 210, 130)
WarmBtn.TextSize = 10
WarmBtn.BorderSizePixel = 0
WarmBtn.AutoButtonColor = false
WarmBtn.Parent = Pill

local WarmCorner = Instance.new("UICorner")
WarmCorner.CornerRadius = UDim.new(0, 8)
WarmCorner.Parent = WarmBtn

-- Закрыть
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(140, 150, 175)
CloseBtn.TextSize = 12
CloseBtn.Parent = Pill

local modeOrder = {"SoftComfort", "ClearNight", "CozyDusk"}
local currentModeIndex = 1

ModeBtn.MouseButton1Click:Connect(function()
    currentModeIndex = currentModeIndex + 1
    if currentModeIndex > #modeOrder then
        currentModeIndex = 1
    end
    CurrentState.ModeKey = modeOrder[currentModeIndex]
    ModeBtn.Text = Modes[CurrentState.ModeKey].Name
    if CurrentState.Enabled then
        applyComfortSettings()
    end
end)

local warmLevels = {0.0, 0.5, 1.0}
local warmLabels = {"ХОЛ", "ТЕП", "МАКС"}
local warmIdx = 2

WarmBtn.MouseButton1Click:Connect(function()
    warmIdx = warmIdx + 1
    if warmIdx > #warmLevels then
        warmIdx = 1
    end
    CurrentState.Warmth = warmLevels[warmIdx]
    WarmBtn.Text = warmLabels[warmIdx]
    if warmIdx == 1 then
        WarmBtn.TextColor3 = Color3.fromRGB(160, 190, 240)
        WarmBtn.BackgroundColor3 = Color3.fromRGB(25, 32, 45)
    else
        WarmBtn.TextColor3 = Color3.fromRGB(255, 210, 130)
        WarmBtn.BackgroundColor3 = Color3.fromRGB(42, 34, 22)
    end
    if CurrentState.Enabled then
        applyComfortSettings()
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    CurrentState.Enabled = not CurrentState.Enabled
    if CurrentState.Enabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 125, 75)
        ToggleBtn.Text = "🌙"
        ModeBtn.TextColor3 = Color3.fromRGB(220, 230, 250)
        enableComfort()
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 40)
        ToggleBtn.Text = "✕"
        ModeBtn.TextColor3 = Color3.fromRGB(130, 135, 150)
        disableComfort()
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        Pill.Visible = not Pill.Visible
    end
end)

local function cleanup()
    if guardConnection then
        guardConnection:Disconnect()
        guardConnection = nil
    end
    disableComfort()
    ScreenGui:Destroy()
    _G.NightComfortCleanup = nil
end

CloseBtn.MouseButton1Click:Connect(cleanup)
_G.NightComfortCleanup = cleanup
