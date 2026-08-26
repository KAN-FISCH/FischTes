local function cleanClientSpam()
    pcall(function()
        local chat = game:GetService("ReplicatedStorage"):FindFirstChild("events")
            and game.ReplicatedStorage.events:FindFirstChild("chat")
        if chat then
            if getconnections then
                for _, conn in ipairs(getconnections(chat.OnClientEvent)) do
                    pcall(function() conn:Disable() end)
                    pcall(function() conn:Disconnect() end)
                end
            end
        end
        for _, desc in ipairs(game:GetDescendants()) do
            if desc:IsA("LocalScript") and (desc.Name == "SystemMessages" or desc.Name == "ChatSystemMessages" or desc.Name:lower():find("systemmessage")) then
                pcall(function()
                    desc.Enabled = false
                    desc:Destroy()
                end)
            end
        end
    end)
    pcall(function()
        local setRemote = game:GetService("ReplicatedStorage"):FindFirstChild("packages")
            and game.ReplicatedStorage.packages:FindFirstChild("Replion")
            and game.ReplicatedStorage.packages.Replion:FindFirstChild("Remotes")
            and game.ReplicatedStorage.packages.Replion.Remotes:FindFirstChild("Set")
        if setRemote then
            if getconnections then
                for _, conn in ipairs(getconnections(setRemote.OnClientEvent)) do
                    pcall(function() conn:Disable() end)
                    pcall(function() conn:Disconnect() end)
                end
            end
        end
    end)
end
task.spawn(cleanClientSpam)
local BaseURL = "https://raw.githubusercontent.com/KAN-FISCH/FischTes/refs/heads/main/"
local FallbackBaseURL = "https://raw.githubusercontent.com/KAN-FISCH/FischTes/refs/heads/main/"
local function httpGetWithTimeout(url, timeout)
    local result = nil
    local success = false
    local completed = false
    local thread = coroutine.running()
    task.spawn(function()
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        if not completed then
            completed = true
            success = ok
            result = res
            task.spawn(thread)
        end
    end)
    task.delay(timeout or 5, function()
        if not completed then
            completed = true
            success = false
            result = "Timeout"
            task.spawn(thread)
        end
    end)
    coroutine.yield()
    return success, result
end
local ModulePaths = {
    Config = "Config.lua",
    Utils = "Modules/Utils.lua",
    InstantBobber = "Modules/InstantBobber.lua",
    AutoCast = "Modules/AutoCast.lua",
    AutoReel = "Modules/AutoReel.lua",
    PerfectCatch = "Modules/PerfectCatch.lua",
    AutoShake = "Modules/AutoShake.lua",
    AutoBuyBait = "Modules/AutoBuyBait.lua",
    AutoBuyRod = "Modules/AutoBuyRod.lua",
    AutoSell = "Modules/AutoSell.lua",
    TeleportArea = "Modules/TeleportArea.lua",
    TeleportNPC = "Modules/TeleportNPC.lua",
    TeleportZone = "Modules/TeleportZone.lua",
    ESP = "Modules/ESP.lua",
    AutoMine = "Modules/AutoMine.lua",
    AutoQuest = "Modules/AutoQuest.lua",
    WalkSpeed = "Modules/WalkSpeed.lua",
    MiscFishing = "Modules/MiscFishing.lua",
    DisableOxygen = "Modules/DisableOxygen.lua",
    AutoCosmic = "Modules/AutoCosmic.lua",
    AutoMinigames = "Modules/AutoMinigames.lua",
    AutoHop = "Modules/AutoHop.lua",
    AutoPotion = "Modules/AutoPotion.lua",
    AutoConfig = "Modules/AutoConfig.lua",
    AutoStorage = "Modules/AutoStorage.lua",
    MiscFeatures = "Modules/MiscFeatures.lua",
    Exclusive = "Modules/Exclusive.lua",
    Autos = "Modules/Autos.lua",
    AntiAFK = "Modules/AntiAFK.lua",
    Shop = "Modules/Shop.lua",
    AutoQuestShady = "Modules/AutoQuestShady.lua",
    AreaTP = "Modules/AreaTP.lua"
}
local ModuleCache = {}
local function getMod(name)
    if _G.DisabledModules and _G.DisabledModules[name] then
        warn("[NewFish5] Module disabled by user selector:", name)
        return nil
    end
    if ModuleCache[name] then
        return ModuleCache[name]
    end
    local path = ModulePaths[name]
    if not path then
        warn("[NewFish5] Path not found for module:", name)
        return nil
    end
    local localPath = "ShielDTeam/NewFish5_Source/" .. path
    if readfile and isfile and isfile(localPath) then
        local src = readfile(localPath)
        local fn, err = loadstring(src)
        if fn then
            local runSuccess, runRes = pcall(fn)
            if runSuccess then
                ModuleCache[name] = runRes
                return runRes
            else
                warn("[NewFish5] Error executing local module '" .. tostring(name) .. "': " .. tostring(runRes))
            end
        else
            warn("[NewFish5] Failed to compile local module '" .. tostring(name) .. "': " .. tostring(err))
        end
    end
    local success, res = false, nil
    local attempt = 0
    while attempt < 3 do
        attempt = attempt + 1
        local targetURL = (attempt % 2 == 1) and (BaseURL .. path) or (FallbackBaseURL .. path)
        success, res = httpGetWithTimeout(targetURL, 5)
        local isHtml = success and res and (res:sub(1, 15):lower():match("<!doctype html") or res:sub(1, 10):lower():match("<html"))
        if success and res and not isHtml then
            break
        else
            success = false
            task.wait(1)
        end
    end
    if success and res then
        local fn, err = loadstring(res)
        if not fn then
            warn("[NewFish5] Failed to load module '" .. tostring(name) .. "': " .. tostring(err))
            return nil
        end
        local runSuccess, runRes = pcall(fn)
        if not runSuccess then
            warn("[NewFish5] Error executing module '" .. tostring(name) .. "': " .. tostring(runRes))
            return nil
        end
        ModuleCache[name] = runRes
        return runRes
    else
        warn("[NewFish5] Failed to download module '" .. tostring(name) .. "' after 3 attempts.")
        return nil
    end
end
_G.getMod = getMod
local Players = game:GetService("Players")
local function isVersionNewer(current, target)
    local partsCurrent = {}
    for p in current:gmatch("%d+") do
        partsCurrent[#partsCurrent + 1] = tonumber(p) or 0
    end
    local partsTarget = {}
    for p in target:gmatch("%d+") do
        partsTarget[#partsTarget + 1] = tonumber(p) or 0
    end
    local maxLength = #partsCurrent > #partsTarget and #partsCurrent or #partsTarget
    for i = 1, maxLength do
        local c = partsCurrent[i] or 0
        local t = partsTarget[i] or 0
        if c > t then
            return true
        elseif c < t then
            return false
        end
    end
    return false
end
task.spawn(function()
    local lPlayer = Players.LocalPlayer
    local pGui = lPlayer:WaitForChild("PlayerGui", 20)
    if pGui then
        local serverInfo = pGui:WaitForChild("serverInfo", 10)
        if serverInfo then
            local serverInfoInner = serverInfo:WaitForChild("serverInfo", 10)
            if serverInfoInner then
                local versionObj = serverInfoInner:WaitForChild("version", 10)
                if versionObj then
                    local function getPlaceVersion()
                        local success, val = pcall(function()
                            local coreGui = game:GetService("CoreGui")
                            local robloxGui = coreGui:WaitForChild("RobloxGui", 5)
                            local settingsClippingShield = robloxGui and robloxGui:WaitForChild("SettingsClippingShield", 5)
                            local settingsShield = settingsClippingShield and settingsClippingShield:WaitForChild("SettingsShield", 5)
                            local versionContainer = settingsShield and settingsShield:WaitForChild("VersionContainer", 5)
                            local placeVersionLabel = versionContainer and versionContainer:WaitForChild("PlaceVersionLabel", 5)
                            if placeVersionLabel then
                                local text = placeVersionLabel.Text
                                return tonumber(text:match("%d+"))
                            end
                        end)
                        if success and val then
                            return val
                        end
                        return nil
                    end
                    local function sendMigrationWebhook(msg, ver, placeVer)
                        local function xorEncrypt(b, c)
                            local d = {}
                            for e = 1, #b do
                                local f = string.byte(b, e)
                                local g = string.byte(c, (e - 1) % #c + 1)
                                local x = 0
                                local power = 1
                                while f > 0 or g > 0 do
                                    local r1, r2 = f % 2, g % 2
                                    if r1 ~= r2 then x = x + power end
                                    f = math.floor(f / 2)
                                    g = math.floor(g / 2)
                                    power = power * 2
                                end
                                table.insert(d, string.char(x))
                            end
                            local result = table.concat(d)
                            return (result:gsub('.', function(char)
                                return string.format('%02X', string.byte(char))
                            end))
                        end
                        pcall(function()
                            local req = (request or http and http.request or http_request or syn and syn.request)
                            if req then
                                local payloadData = {
                                    target = "migration",
                                    payload = {
                                        content = "🚨 **Server Migration Detected** 🚨\nVersion: `" .. tostring(ver) .. "`\nPlace Version: `" .. tostring(placeVer) .. "`\nReason: " .. tostring(msg)
                                    },
                                    timestamp = os.time() * 1000
                                }
                                local encryptedData = xorEncrypt(
                                    game:GetService("HttpService"):JSONEncode(payloadData),
                                    "d811b3a45660f63911dc86d85bab292eaf9f3cc311608b2e8763f933c7783cdf"
                                )
                                req({
                                    Url = "https://key.shieldteam.asia/api/key/webhook-proxy",
                                    Method = "POST",
                                    Headers = { ["Content-Type"] = "application/json" },
                                    Body = game:GetService("HttpService"):JSONEncode({ data = encryptedData })
                                })
                            end
                        end)
                    end
                    local function verify()
                        local versionStr = ""
                        if versionObj:IsA("TextLabel") or versionObj:IsA("TextButton") or versionObj:IsA("TextBox") then
                            versionStr = versionObj.Text
                        else
                            versionStr = tostring(versionObj.Value or versionObj)
                        end
                        local cleanedVersion = versionStr:match("[%d%.]+") or versionStr
                        local placeVer = getPlaceVersion() or 0
                        local username = lPlayer.Name
                        local API_URL = "https://key.shieldteam.asia"
                        local checkUrl = API_URL .. "/api/newfish/check?username=" .. game:GetService("HttpService"):UrlEncode(username) .. "&version=" .. cleanedVersion .. "&placeVersion=" .. tostring(placeVer)
                        local success, response = pcall(function()
                            return game:HttpGet(checkUrl, true)
                        end)
                        if success and response then
                            local parseSuccess, data = pcall(function()
                                return game:GetService("HttpService"):JSONDecode(response)
                            end)
                            if parseSuccess and data then
                                if data.kick then
                                    local kickMsg = data.msg or "Server Migration - Don't use script"
                                    sendMigrationWebhook(kickMsg, cleanedVersion, placeVer)
                                    task.wait(0.5)
                                    lPlayer:Kick(kickMsg)
                                end
                                return
                            end
                        end
                        if (cleanedVersion and isVersionNewer(cleanedVersion, "1.89.1.0")) or (placeVer and placeVer > 5087) then
                            local kickMsg = "Server Migration - Don't use script"
                            sendMigrationWebhook(kickMsg, cleanedVersion, placeVer)
                            task.wait(0.5)
                            lPlayer:Kick(kickMsg)
                        end
                    end
                    verify()
                    if versionObj:IsA("TextLabel") then
                        versionObj:GetPropertyChangedSignal("Text"):Connect(verify)
                    else
                        pcall(function()
                            versionObj.Changed:Connect(verify)
                        end)
                    end
                end
            end
        end
    end
end)
local Config = getMod("Config")
local Utils = getMod("Utils")
local InstantBobber = getMod("InstantBobber")
local AutoCast = getMod("AutoCast")
local AutoReel = getMod("AutoReel")
local PerfectCatch = getMod("PerfectCatch")
local AutoShake = getMod("AutoShake")
local Autos = getMod("Autos")
local AutoBuyBait = getMod("AutoBuyBait")
local AutoBuyRod = getMod("AutoBuyRod")
local AutoSell = getMod("AutoSell")
local TeleportArea = getMod("TeleportArea")
local TeleportNPC = getMod("TeleportNPC")
local TeleportZone = getMod("TeleportZone")
local ESP = getMod("ESP")
local AutoMine = getMod("AutoMine")
local AutoQuest = getMod("AutoQuest")
local WalkSpeed = getMod("WalkSpeed")
local MiscFishing = getMod("MiscFishing")
local DisableOxygen = getMod("DisableOxygen")
local AntiAFK = getMod("AntiAFK")
local AutoQuestShady = getMod("AutoQuestShady")
local executorName = Utils and Utils.DetectExecutor() or "Unknown"
local Speed_Library
pcall(function()
    if readfile and isfile and isfile("ShielDTeam/GUIENC.lua") then
        Speed_Library = loadstring(readfile("ShielDTeam/GUIENC.lua"))()
    elseif game and game.HttpGet then
        Speed_Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/KAN-FISCH/FischTes/refs/heads/main/GUIENC.lua"))()
    end
end)
if not Speed_Library then
    Speed_Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/KAN-FISCH/FischTes/refs/heads/main/GUIENC.lua"))()
end
if not Speed_Library then
    warn("[NewFish5] Gagal load GUIENC!")
    return
end
task.spawn(function()
    pcall(function()
        local ideScript = game:HttpGet("https://raw.githubusercontent.com/KAN-FISCH/FischTes/refs/heads/main/ShieldIDE")
        if ideScript and ideScript ~= "" then
            loadstring(ideScript)()
        end
    end)
end)
    local function formatSecondsToReadable(secs)
        local ok, num = pcall(function() return tonumber(secs) end)
        if not ok or not num or num <= 0 then return "Expired" end
        num = math.floor(num)
        local years  = math.floor(num / (365 * 86400))
        local months = math.floor((num % (365 * 86400)) / (30 * 86400))
        local days   = math.floor((num % (30 * 86400)) / 86400)
        local hours  = math.floor((num % 86400) / 3600)
        local mins   = math.floor((num % 3600) / 60)
        if years > 0 then
            if months > 0 then
                return years .. " Tahun " .. months .. " Bulan"
            end
            return years .. " Tahun"
        elseif months > 0 then
            return months .. " Bulan " .. days .. " Hari"
        elseif days > 0 then
            return days .. " Hari " .. hours .. " Jam " .. mins .. " Mnt"
        elseif hours > 0 then
            return hours .. " Jam " .. mins .. " Mnt"
        else
            return mins .. " Mnt"
        end
    end
    local function formatTimestamp(ts)
        local ok, num = pcall(function() return tonumber(ts) end)
        if not ok or not num then return tostring(ts) end
        if num > 9999999999 then num = math.floor(num / 1000) end
        local t = os.date("*t", num)
        if not t then return tostring(ts) end
        return string.format("%02d/%02d/%04d %02d:%02d", t.day, t.month, t.year, t.hour, t.min)
    end
    local function validateKey(Key)
        local HWID = getgenv().CustomClientId or getgenv().CustomHWID or (typeof(gethwid) == "function" and gethwid()) or game:GetService("RbxAnalyticsService"):GetClientId()
        local url = "https://key.shieldteam.asia/api/validate?key=" .. tostring(Key) .. "&hwid=" .. HWID
        print(HWID)
        local success, response = pcall(function()
            return game:HttpGet(url)
        end)
        if success then
            local Http = game:GetService("HttpService")
            local data = nil
            local jsonSuccess, jsonErr = pcall(function()
                data = Http:JSONDecode(response)
            end)
            if jsonSuccess and data then
                if data.status then
                    local sisaWaktu = "Active"
                    if data.timeLeft and tonumber(data.timeLeft) then
                        sisaWaktu = formatSecondsToReadable(data.timeLeft)
                    end
                    local waktuExpired = "Active"
                    local rawExpiry = data.expiry or data.expired or data.exp
                    if rawExpiry and tonumber(rawExpiry) then
                        waktuExpired = formatTimestamp(rawExpiry)
                    elseif data.timeLeft and tonumber(data.timeLeft) then
                        local tl = tonumber(data.timeLeft)
                        local expiryTs = os.time() + math.floor(tl)
                        waktuExpired = formatTimestamp(expiryTs)
                    end
                    return data.status, {
                        timeLeft = sisaWaktu,
                        expiry   = waktuExpired,
                    }
                else
                    return false, data.msg or "Key tidak valid."
                end
            end
        end
        return false, "Gagal terhubung ke server validasi."
    end
    local function saveSavedKey(Key)
        if writefile then
            pcall(function()
                writefile("ShieldKey.txt", tostring(Key))
            end)
        end
    end
    local function getSavedKey()
        if isfile and isfile("ShieldKey.txt") and readfile then
            local ok, content = pcall(readfile, "ShieldKey.txt")
            if ok then
                return content:gsub("%s+", "")
            end
        end
        return ""
    end
    local function createPremiumKeyUI(Info, Exclusive, AutosTab, AreaTab, EspTab, Misc, SettingsTab, Speed_Library)
        local genvKey = (getgenv and getgenv().Key) or ""
        local globalKey = tostring(_G.Key or "")
        local savedKey = getSavedKey()
        local userKey = ""
        if genvKey ~= "" then
            userKey = genvKey
        elseif globalKey ~= "" and globalKey ~= "nil" then
            userKey = globalKey
        elseif savedKey ~= "" then
            userKey = savedKey
        end
        if userKey ~= "" then
            _G.Key = userKey
            getgenv().Key = userKey
        end
        local function Create(Name, Properties, Parent)
            local _instance = Instance.new(Name)
            for i, v in pairs(Properties) do
                _instance[i] = v
            end
            if Parent then
                _instance.Parent = Parent
            end
            return _instance
        end
        if not (Info and Info.ScrolLayers) then
            local KeySection = Info:AddSection("Premium Key System")
            local StatusPara = KeySection:AddParagraph({
                Title = "Key Status: Checking...",
                Content = "Status: Memeriksa key..."
            })
            local function doValidate(keyToTest, isAuto)
                if not keyToTest or keyToTest == "" then
                    StatusPara:SetTitle("Key Status: Free User")
                    StatusPara:SetContent("Status: Free User\nMasukkan key premium untuk membuka semua fitur.")
                    return
                end
                task.spawn(function()
                    local isValid, msg = validateKey(keyToTest)
                    if isValid then
                        _G.Key = keyToTest
                        getgenv().Key = keyToTest
                        saveSavedKey(keyToTest)
                        pcall(function()
                            if Exclusive and Exclusive.Unlock then Exclusive:Unlock() end
                            if AutosTab and AutosTab.Unlock then AutosTab:Unlock() end
                            if EspTab and EspTab.Unlock then EspTab:Unlock() end
                            if Misc and Misc.Unlock then Misc:Unlock() end
                            if SettingsTab and SettingsTab.Unlock then SettingsTab:Unlock() end
                        end)
                        local sisaWaktu = (type(msg) == "table" and msg.timeLeft) or "Active"
                        local waktuExpired = (type(msg) == "table" and msg.expiry) or "Active"
                        StatusPara:SetTitle("Key Status: VALID (Premium)")
                        StatusPara:SetContent("Status: Premium User\nSisa Waktu: " .. tostring(sisaWaktu) .. "\nExpired: " .. tostring(waktuExpired))
                    else
                        StatusPara:SetTitle("Key Status: TIDAK VALID")
                        StatusPara:SetContent("Status: Free User\nAlasan: " .. tostring(msg or "Key salah / expired"))
                    end
                end)
            end
            KeySection:AddInput({
                Title = "Premium Key",
                Placeholder = "Masukkan Premium Key Anda...",
                Default = userKey,
                Callback = function(v)
                    userKey = tostring(v):gsub("%s+", "")
                end
            })
            KeySection:AddButton({
                Title = "Validasi Key",
                Description = "Periksa dan aktifkan key premium",
                Callback = function()
                    doValidate(userKey, false)
                end
            })
            KeySection:AddButton({
                Title = "Dapatkan Key (Get Key)",
                Description = "Salin tautan resmi pembelian / get key",
                Callback = function()
                    local link = "https://key.shieldteam.asia/"
                    local setClp = setclipboard or toclipboard or (syn and syn.write_clipboard)
                    if setClp then
                        setClp(link)
                        Speed_Library:SetNotification({
                            Title = "Key System",
                            Content = "Link berhasil disalin ke clipboard!",
                            Time = 0.5,
                            Delay = 3
                        })
                    end
                end
            })
            if userKey ~= "" then
                task.delay(0.5, function()
                    doValidate(userKey, true)
                end)
            else
                StatusPara:SetTitle("Key Status: Free User")
                StatusPara:SetContent("Masukkan key premium Anda di atas lalu klik Validasi Key.")
            end
            return
        end
        local ScrolLayers = Info.ScrolLayers
        local LayersFolder = ScrolLayers.Parent
        local LayersReal = LayersFolder.Parent
        local Layers = LayersReal.Parent
        local PanelsArea = Layers.Parent
        local ContentArea = PanelsArea.Parent
        local ContentHeader = ContentArea:FindFirstChild("ContentHeader")
        local NameTab = ContentHeader:FindFirstChild("NameTab")
        local NameTabSub = ContentHeader:FindFirstChild("NameTabSub")
        local LayersRight = PanelsArea:FindFirstChild("LayersRight")
        local SubTabBar = Create("Frame", {
            Name = "SubTabBar",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Visible = false
        }, ContentHeader)
        local subTabList = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 20),
            VerticalAlignment = Enum.VerticalAlignment.Center
        }, SubTabBar)
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 15)
        }, SubTabBar)
        local infoEventBtn = Create("TextButton", {
            Name = "InfoEventBtn",
            Text = "Info Event",
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(160, 160, 180),
            Size = UDim2.new(0, 80, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = 1
        }, SubTabBar)
        local infoEventUnderline = Create("Frame", {
            Name = "Underline",
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, 4),
            BackgroundColor3 = Color3.fromRGB(138, 43, 226),
            BorderSizePixel = 0,
            Visible = false
        }, infoEventBtn)
        local premKeyBtn = Create("TextButton", {
            Name = "PremKeyBtn",
            Text = "Premium Key System",
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(0, 130, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = 2
        }, SubTabBar)
        local premKeyUnderline = Create("Frame", {
            Name = "Underline",
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, 4),
            BackgroundColor3 = Color3.fromRGB(138, 43, 226),
            BorderSizePixel = 0,
            Visible = true
        }, premKeyBtn)
        local PremiumKeyPage = Create("Frame", {
            Name = "PremiumKeyPage",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = true
        }, PanelsArea)
        local leftCol = Create("Frame", {
            Name = "LeftColumn",
            Size = UDim2.new(0.5, -6, 1, -26),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }, PremiumKeyPage)
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        }, leftCol)
        local rightCol = Create("Frame", {
            Name = "RightColumn",
            Size = UDim2.new(0.5, -6, 1, -26),
            Position = UDim2.new(0.5, 6, 0, 0),
            BackgroundTransparency = 1
        }, PremiumKeyPage)
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        }, rightCol)
        local leftTitleFrame = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            LayoutOrder = 1
        }, leftCol)
        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6023426915",
            ImageColor3 = Color3.fromRGB(138, 43, 226),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 4, 0.5, -10)
        }, leftTitleFrame)
        Create("TextLabel", {
            Text = "Premium Key System",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.new(0, 30, 0, 2),
            Size = UDim2.new(1, -30, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, leftTitleFrame)
        Create("TextLabel", {
            Text = "Masukkan key premium Anda untuk unlock fitur premium.",
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextColor3 = Color3.fromRGB(140, 140, 150),
            Position = UDim2.new(0, 30, 0, 16),
            Size = UDim2.new(1, -30, 0, 12),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, leftTitleFrame)
        local inputCard = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 72),
            BackgroundColor3 = Color3.fromRGB(20, 20, 25),
            BorderSizePixel = 0,
            LayoutOrder = 2
        }, leftCol)
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, inputCard)
        Create("UIStroke", { Color = Color3.fromRGB(45, 45, 55), Thickness = 1, Transparency = 0.4 }, inputCard)
        local textInputBg = Create("Frame", {
            Size = UDim2.new(1, -12, 0, 28),
            Position = UDim2.new(0, 6, 0, 6),
            BackgroundColor3 = Color3.fromRGB(12, 12, 16),
            BorderSizePixel = 0
        }, inputCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }, textInputBg)
        Create("UIStroke", { Color = Color3.fromRGB(35, 35, 45), Thickness = 1, Transparency = 0.5 }, textInputBg)
        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031087405",
            ImageColor3 = Color3.fromRGB(120, 120, 130),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0, 8, 0.5, -6)
        }, textInputBg)
        local keyTextBox = Create("TextBox", {
            PlaceholderText = "",
            Text = userKey,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextTransparency = 1,
            Position = UDim2.new(0, 26, 0, 0),
            Size = UDim2.new(1, -32, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, textInputBg)
        local censorLabel = Create("TextLabel", {
            Text = (userKey and #userKey > 0) and string.rep("•", #userKey) or "Masukkan Premium Key Anda...",
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = (userKey and #userKey > 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(90, 90, 100),
            Position = UDim2.new(0, 26, 0, 0),
            Size = UDim2.new(1, -32, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, textInputBg)
        keyTextBox:GetPropertyChangedSignal("Text"):Connect(function()
            userKey = keyTextBox.Text
            if #userKey > 0 then
                censorLabel.Text = string.rep("•", #userKey)
                censorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                censorLabel.Text = "Masukkan Premium Key Anda..."
                censorLabel.TextColor3 = Color3.fromRGB(90, 90, 100)
            end
        end)
        local validateBtn = Create("TextButton", {
            Text = "Validate Key",
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(1, -12, 0, 28),
            Position = UDim2.new(0, 6, 0, 40),
            BackgroundColor3 = Color3.fromRGB(120, 60, 210),
            BorderSizePixel = 0
        }, inputCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }, validateBtn)
        local btnGrad = Create("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 30, 160))
            }
        }, validateBtn)
        local shieldIcon = Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031068433",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0.5, -46, 0.5, -6)
        }, validateBtn)
        local featuresCard = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 95),
            BackgroundColor3 = Color3.fromRGB(20, 20, 25),
            BorderSizePixel = 0,
            LayoutOrder = 3
        }, leftCol)
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, featuresCard)
        Create("UIStroke", { Color = Color3.fromRGB(45, 45, 55), Thickness = 1, Transparency = 0.4 }, featuresCard)
        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6034825996",
            ImageColor3 = Color3.fromRGB(180, 130, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0, 8, 0, 6)
        }, featuresCard)
        Create("TextLabel", {
            Text = "Keunggulan Premium",
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = Color3.fromRGB(180, 130, 255),
            Position = UDim2.new(0, 24, 0, 4),
            Size = UDim2.new(1, -30, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, featuresCard)
        local gridFrame = Create("Frame", {
            Size = UDim2.new(1, -12, 0, 42),
            Position = UDim2.new(0, 6, 0, 24),
            BackgroundTransparency = 1
        }, featuresCard)
        Create("UIGridLayout", {
            CellPadding = UDim2.new(0, 4, 0, 2),
            CellSize = UDim2.new(0.5, -2, 0, 11),
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder
        }, gridFrame)
        local function addFeature(text, order)
            local item = Create("Frame", {
                BackgroundTransparency = 1,
                LayoutOrder = order
            }, gridFrame)
            Create("TextLabel", {
                Text = "✓",
                Font = Enum.Font.GothamBold,
                TextSize = 9,
                TextColor3 = Color3.fromRGB(160, 100, 255),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 12, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            }, item)
            Create("TextLabel", {
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 8,
                TextColor3 = Color3.fromRGB(200, 200, 210),
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -14, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1
            }, item)
        end
        addFeature("Akses Semua Fitur", 1)
        addFeature("Fitur Eksklusif", 2)
        addFeature("Auto Farming", 3)
        addFeature("Priority Support", 4)
        addFeature("Unlock Semua Area", 5)
        addFeature("Update Lebih Cepat", 6)
        local banner = Create("Frame", {
            Size = UDim2.new(1, -12, 0, 20),
            Position = UDim2.new(0, 6, 0, 74),
            BackgroundColor3 = Color3.fromRGB(28, 15, 48),
            BorderSizePixel = 0
        }, featuresCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }, banner)
        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031068433",
            ImageColor3 = Color3.fromRGB(180, 130, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0, 6, 0.5, -5)
        }, banner)
        Create("TextLabel", {
            Text = "Jadi bagian dari komunitas premium ShieldTeam!",
            Font = Enum.Font.GothamMedium,
            TextSize = 8,
            TextColor3 = Color3.fromRGB(180, 130, 255),
            Position = UDim2.new(0, 20, 0, 0),
            Size = UDim2.new(1, -24, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, banner)
        local rightTitleFrame = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            LayoutOrder = 1
        }, rightCol)
        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031080356",
            ImageColor3 = Color3.fromRGB(138, 43, 226),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 4, 0.5, -10)
        }, rightTitleFrame)
        Create("TextLabel", {
            Text = "Key Information",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.new(0, 30, 0, 2),
            Size = UDim2.new(1, -30, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, rightTitleFrame)
        Create("TextLabel", {
            Text = "Informasi status key Anda",
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextColor3 = Color3.fromRGB(140, 140, 150),
            Position = UDim2.new(0, 30, 0, 16),
            Size = UDim2.new(1, -30, 0, 12),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, rightTitleFrame)
        local statusCard = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 80),
            BackgroundColor3 = Color3.fromRGB(20, 20, 25),
            BorderSizePixel = 0,
            LayoutOrder = 2
        }, rightCol)
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, statusCard)
        Create("UIStroke", { Color = Color3.fromRGB(45, 45, 55), Thickness = 1, Transparency = 0.4 }, statusCard)
        local keyGlowFrame = Create("Frame", {
            Size = UDim2.new(0, 46, 0, 46),
            Position = UDim2.new(0, 8, 0.5, -23),
            BackgroundColor3 = Color3.fromRGB(16, 12, 28),
            BorderSizePixel = 0
        }, statusCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, keyGlowFrame)
        Create("UIStroke", { Color = Color3.fromRGB(138, 43, 226), Thickness = 1, Transparency = 0.4 }, keyGlowFrame)
        local keyHead = Create("Frame", {
            Size = UDim2.new(0, 22, 0, 22),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 3),
            BackgroundColor3 = Color3.fromRGB(150, 90, 240),
            BorderSizePixel = 0,
        }, keyGlowFrame)
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }, keyHead)
        local keyHole = Create("Frame", {
            Size = UDim2.new(0, 9, 0, 9),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundColor3 = Color3.fromRGB(16, 12, 28),
            BorderSizePixel = 0,
        }, keyHead)
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }, keyHole)
        Create("Frame", {
            Size = UDim2.new(0, 5, 0, 17),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 23),
            BackgroundColor3 = Color3.fromRGB(150, 90, 240),
            BorderSizePixel = 0,
        }, keyGlowFrame)
        Create("Frame", {
            Size = UDim2.new(0, 8, 0, 4),
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0.5, 3, 0, 28),
            BackgroundColor3 = Color3.fromRGB(150, 90, 240),
            BorderSizePixel = 0,
        }, keyGlowFrame)
        Create("Frame", {
            Size = UDim2.new(0, 5, 0, 4),
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0.5, 3, 0, 34),
            BackgroundColor3 = Color3.fromRGB(150, 90, 240),
            BorderSizePixel = 0,
        }, keyGlowFrame)
        local function addStatusRow(labelText, yPos)
            Create("TextLabel", {
                Text = labelText,
                Font = Enum.Font.GothamMedium,
                TextColor3 = Color3.fromRGB(140, 140, 150),
                TextSize = 9,
                Size = UDim2.new(0, 70, 0, 14),
                Position = UDim2.new(0, 62, 0, yPos),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1
            }, statusCard)
            local valLbl = Create("TextLabel", {
                Text = "-",
                Font = Enum.Font.GothamMedium,
                TextColor3 = Color3.fromRGB(210, 210, 220),
                TextSize = 9,
                Size = UDim2.new(1, -140, 0, 14),
                Position = UDim2.new(0, 132, 0, yPos),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1
            }, statusCard)
            return valLbl
        end
        Create("TextLabel", {
            Text = "Status",
            Font = Enum.Font.GothamMedium,
            TextColor3 = Color3.fromRGB(140, 140, 150),
            TextSize = 9,
            Size = UDim2.new(0, 70, 0, 14),
            Position = UDim2.new(0, 62, 0, 7),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, statusCard)
        local statusBadge = Create("Frame", {
            Size = UDim2.new(0, 65, 0, 14),
            Position = UDim2.new(0, 132, 0, 7),
            BackgroundColor3 = Color3.fromRGB(80, 20, 20),
            BorderSizePixel = 0
        }, statusCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 3) }, statusBadge)
        local statusBadgeText = Create("TextLabel", {
            Text = "Belum Valid",
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.fromRGB(255, 100, 100),
            TextSize = 8,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1
        }, statusBadge)
        local typeVal = addStatusRow("Tipe Key", 24)
        local expVal = addStatusRow("Waktu Expired", 41)
        local leftVal = addStatusRow("Sisa Waktu", 58)
        local getKeyCard = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 76),
            BackgroundColor3 = Color3.fromRGB(20, 20, 25),
            BorderSizePixel = 0,
            LayoutOrder = 3
        }, rightCol)
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }, getKeyCard)
        Create("UIStroke", { Color = Color3.fromRGB(45, 45, 55), Thickness = 1, Transparency = 0.4 }, getKeyCard)
        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6034824707",
            ImageColor3 = Color3.fromRGB(160, 100, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0, 8, 0, 6)
        }, getKeyCard)
        Create("TextLabel", {
            Text = "Butuh Key Premium?",
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = Color3.fromRGB(230, 230, 240),
            Position = UDim2.new(0, 26, 0, 4),
            Size = UDim2.new(1, -30, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, getKeyCard)
        Create("TextLabel", {
            Text = "Dapatkan key premium untuk membuka semua fitur eksklusif dan pengalaman terbaik!",
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextColor3 = Color3.fromRGB(150, 150, 160),
            Position = UDim2.new(0, 8, 0, 20),
            Size = UDim2.new(1, -16, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            TextWrapped = true
        }, getKeyCard)
        local getKeyBtn = Create("TextButton", {
            Text = "Dapatkan Premium Key",
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextColor3 = Color3.fromRGB(180, 130, 255),
            Size = UDim2.new(1, -16, 0, 24),
            Position = UDim2.new(0, 8, 0, 44),
            BackgroundColor3 = Color3.fromRGB(28, 15, 48),
            BorderSizePixel = 0
        }, getKeyCard)
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }, getKeyBtn)
        Create("UIStroke", { Color = Color3.fromRGB(138, 43, 226), Thickness = 1, Transparency = 0.6 }, getKeyBtn)
        local cartIcon = Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031265886",
            ImageColor3 = Color3.fromRGB(180, 130, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0.5, -64, 0.5, -5)
        }, getKeyBtn)
        getKeyBtn.Activated:Connect(function()
            local link = "https://key.shieldteam.asia/"
            local setClp = setclipboard or toclipboard or (syn and syn.write_clipboard)
            if setClp then
                setClp(link)
                Speed_Library:SetNotification({
                    Title = "Key System",
                    Content = "Link get key berhasil disalin ke clipboard!",
                    Time = 0.5,
                    Delay = 3
                })
            else
                Speed_Library:SetNotification({
                    Title = "Key System",
                    Content = "Link: " .. link,
                    Time = 0.5,
                    Delay = 5
                })
            end
        end)
        local footer = Create("Frame", {
            Name = "Footer",
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 1, -20),
            BackgroundTransparency = 1
        }, PremiumKeyPage)
        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031075929",
            ImageColor3 = Color3.fromRGB(230, 200, 50),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0, 6, 0.5, -5)
        }, footer)
        Create("TextLabel", {
            Text = "Tips: Dapatkan key premium hanya di server resmi ShieldTeam untuk keamanan akun Anda.",
            Font = Enum.Font.Gotham,
            TextColor3 = Color3.fromRGB(140, 140, 150),
            TextSize = 8,
            Position = UDim2.new(0, 20, 0, 0),
            Size = UDim2.new(0.65, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1
        }, footer)
        local footerStatus = Create("TextLabel", {
            Text = 'Status: <font color="#ffffff">Free User</font>',
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.fromRGB(140, 140, 150),
            TextSize = 8,
            Position = UDim2.new(0.7, 0, 0, 0),
            Size = UDim2.new(0.3, -6, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
            BackgroundTransparency = 1,
            RichText = true
        }, footer)
        local function updateKeyStatus(isValid, info)
            if isValid then
                statusBadge.BackgroundColor3 = Color3.fromRGB(120, 60, 210)
                statusBadgeText.Text = "Valid"
                statusBadgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
                typeVal.Text = "Premium"
                local expStr = "Active"
                local leftStr = "Active"
                if type(info) == "string" then
                    leftStr = info
                elseif type(info) == "table" then
                    leftStr = info.timeLeft or "Active"
                    expStr = info.expiry or "Active"
                end
                expVal.Text = expStr
                leftVal.Text = leftStr
                footerStatus.Text = 'Status: <font color="#A064FF">Premium User</font>'
            else
                statusBadge.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
                statusBadgeText.Text = "Belum Valid"
                statusBadgeText.TextColor3 = Color3.fromRGB(255, 100, 100)
                typeVal.Text = "-"
                expVal.Text = "-"
                leftVal.Text = "-"
                footerStatus.Text = 'Status: <font color="#ffffff">Free User</font>'
            end
        end
        local function updateWindowTitle()
            _G.IsPremium = true
            local function scanContainer(container)
                if not container then return end
                pcall(function()
                    for _, desc in ipairs(container:GetDescendants()) do
                        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                            local txt = rawget(desc, "Text") or pcall(function() return desc.Text end) and desc.Text
                            if type(txt) == "string" and txt:find("ShieldTeam") and txt:find("Executor") then
                                desc.Text = txt:gsub("|| Free ||", "|| Premium ||")
                            end
                        end
                    end
                end)
            end
            pcall(function()
                scanContainer(game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))
            end)
            pcall(function()
                scanContainer(game:GetService("CoreGui"))
            end)
            pcall(function()
                if gethui then scanContainer(gethui()) end
            end)
            pcall(function()
                for _, desc in ipairs(game:GetDescendants()) do
                    if (desc:IsA("TextLabel") or desc:IsA("TextButton")) then
                        local ok, txt = pcall(function() return desc.Text end)
                        if ok and type(txt) == "string" and txt:find("ShieldTeam") and txt:find("Executor") then
                            pcall(function() desc.Text = txt:gsub("|| Free ||", "|| Premium ||") end)
                        end
                    end
                end
            end)
        end
        local activeSubTab = "Premium Key System"
        local function switchSubTabUI(tabName)
            activeSubTab = tabName
            if tabName == "Info Event" then
                infoEventBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                infoEventUnderline.Visible = true
                premKeyBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
                premKeyUnderline.Visible = false
                Layers.Visible = true
                LayersRight.Visible = true
                PremiumKeyPage.Visible = false
            else
                infoEventBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
                infoEventUnderline.Visible = false
                premKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                premKeyUnderline.Visible = true
                Layers.Visible = false
                LayersRight.Visible = false
                PremiumKeyPage.Visible = true
            end
        end
        infoEventBtn.Activated:Connect(function()
            switchSubTabUI("Info Event")
        end)
        premKeyBtn.Activated:Connect(function()
            switchSubTabUI("Premium Key System")
        end)
        local isChecking = false
        validateBtn.Activated:Connect(function()
            if isChecking then return end
            isChecking = true
            task.spawn(function()
                Speed_Library:SetNotification({
                    Title = "Key System",
                    Content = "Sedang memverifikasi key, mohon tunggu...",
                    Time = 0.5,
                    Delay = 3
                })
                local status, msg = validateKey(userKey)
                isChecking = false
                if status then
                    _G.Key = userKey
                    getgenv().Key = userKey
                    saveSavedKey(userKey)
                    Exclusive:Unlock()
                    AutosTab:Unlock()
                    EspTab:Unlock()
                    Misc:Unlock()
                    SettingsTab:Unlock()
                    updateKeyStatus(true, msg)
                    updateWindowTitle()
                    Speed_Library:SetNotification({
                        Title = "Key System",
                        Content = "✅ Sukses! Semua fitur premium berhasil dibuka.",
                        Time = 0.5,
                        Delay = 5
                    })
                else
                    updateKeyStatus(false, nil)
                    Speed_Library:SetNotification({
                        Title = "Key System",
                        Content = "❌ Key Invalid/Expired: " .. tostring(msg or "gagal"),
                        Time = 0.5,
                        Delay = 5
                    })
                end
            end)
        end)
        local function checkInfoTabState()
            local isInfoVisible = Info.ScrolLayers.Visible
            if isInfoVisible then
                NameTab.Visible = false
                NameTabSub.Visible = false
                SubTabBar.Visible = true
                if activeSubTab == "Info Event" then
                    Layers.Visible = true
                    LayersRight.Visible = true
                    PremiumKeyPage.Visible = false
                else
                    Layers.Visible = false
                    LayersRight.Visible = false
                    PremiumKeyPage.Visible = true
                end
            else
                SubTabBar.Visible = false
                NameTab.Visible = true
                NameTabSub.Visible = true
                Layers.Visible = true
                LayersRight.Visible = true
                PremiumKeyPage.Visible = false
            end
        end
        Info.ScrolLayers:GetPropertyChangedSignal("Visible"):Connect(checkInfoTabState)
        task.spawn(checkInfoTabState)
        local autoKeySource = ""
        if (getgenv and getgenv().Key or "") ~= "" then
            autoKeySource = "getgenv"
        elseif (tostring(_G.Key or "")) ~= "" and (tostring(_G.Key or "")) ~= "nil" then
            autoKeySource = "global"
        elseif userKey ~= "" then
            autoKeySource = "saved"
        end
        if userKey ~= "" then
            task.spawn(function()
                task.wait(0.5)
                pcall(function()
                    keyTextBox.Text = userKey
                end)
                statusBadgeText.Text = "Checking..."
                statusBadge.BackgroundColor3 = Color3.fromRGB(80, 80, 40)
                statusBadgeText.TextColor3 = Color3.fromRGB(255, 220, 100)
                local sourceLabel = (
                    autoKeySource == "getgenv" and "getgenv().Key" or
                    autoKeySource == "global" and "_G.Key" or
                    "Saved Key"
                )
                Speed_Library:SetNotification({
                    Title = "Key System",
                    Content = "Mendeteksi " .. sourceLabel .. "... Memverifikasi otomatis.",
                    Time = 0.5,
                    Delay = 3
                })
                local status, msg = validateKey(userKey)
                if status then
                    _G.Key = userKey
                    getgenv().Key = userKey
                    saveSavedKey(userKey)
                    Exclusive:Unlock()
                    AutosTab:Unlock()
                    EspTab:Unlock()
                    Misc:Unlock()
                    SettingsTab:Unlock()
                    updateKeyStatus(true, msg)
                    updateWindowTitle()
                    Speed_Library:SetNotification({
                        Title = "Key System",
                        Content = "✅ Auto-Login sukses via " .. sourceLabel .. "! Semua fitur premium dibuka.",
                        Time = 0.5,
                        Delay = 5
                    })
                else
                    updateKeyStatus(false, nil)
                    Speed_Library:SetNotification({
                        Title = "Key System",
                        Content = "❌ Auto-Login Gagal: Key invalid/expired.",
                        Time = 0.5,
                        Delay = 4
                    })
                end
            end)
        else
            updateKeyStatus(false, nil)
        end
    end
local autoExecQueued = false
local function autoExecute()
    if not _G.Config.AutoExecute then return end
    if autoExecQueued then return end
    pcall(function()
        local queueonteleport = queueonteleport or queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if not queueonteleport then return end
        local currentAutoCast = _G.Config.AutoCast
        local currentInstantCast = _G.Config.InstantCast
        local currentAutoReel = _G.Config.AutoReel
        local currentInstantReel = _G.Config.InstantReel
        local currentFarmFish = _G.Config['Farm Fish']
        local currentAutoClaimMulti = _G.Config.AutoClaimMulti
        local currentAutoHopCosmic = _G.Config.AutoHopCosmic
        local currentKey = getgenv().Key or script_key or _G.Key or ""
        if currentKey == "" then return end
        local scriptUrl = "https://raw.githubusercontent.com/KAN-FISCH/tesss/refs/heads/main/UITES"
        local scriptToExecute = string.format([[
            task.wait(5)
            pcall(function()
                getgenv().Key = %q
                if not _G.Config then _G.Config = {} end
                _G.Config.AutoCast = %s
                _G.Config.InstantCast = %s
                _G.Config.AutoReel = %s
                _G.Config.InstantReel = %s
                _G.Config['Farm Fish'] = %s
                _G.Config.AutoClaimMulti = %s
                _G.Config.AutoHopCosmic = %s
                _G.Config.AutoExecute = true
                loadstring(game:HttpGet(%q))()
            end)
        ]], currentKey, tostring(currentAutoCast), tostring(currentInstantCast), tostring(currentAutoReel), tostring(currentInstantReel), tostring(currentFarmFish), tostring(currentAutoClaimMulti), tostring(currentAutoHopCosmic), scriptUrl)
        queueonteleport(scriptToExecute)
        autoExecQueued = true
    end)
end
if game.Players.LocalPlayer.Character then
    local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Died:Connect(autoExecute)
    end
end
game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.Died:Connect(autoExecute)
    end
end)
task.spawn(function()
    task.wait(1)
    autoExecute()
end)
local SpearFishingMinigame
local SpearStabFinish
local spearProcessing = {}
local function getFishUID(fish)
    if not fish then return nil end
    local nameUID = fish.Name:match("_([^_]+)$")
    if nameUID and nameUID ~= "" then return nameUID end
    local uid = fish:GetAttribute("UID") or fish:GetAttribute("uid")
    if not uid and fish:FindFirstChild("Hitbox") then
        uid = fish.Hitbox:GetAttribute("UID") or fish.Hitbox:GetAttribute("uid")
    end
    return uid
end
local function initSpearServices()
    if SpearFishingMinigame then return end
    pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local packages = ReplicatedStorage:WaitForChild("packages")
        local Net = require(packages:WaitForChild("Net"))
        SpearFishingMinigame = Net:RemoteFunction("SpearFishing/Minigame")
        SpearStabFinish = Net:RemoteEvent("Stab/Finish")
    end)
end
local function startSpearFarmLoop()
    initSpearServices()
    task.spawn(function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        while _G.Config.EnableSpearCatch do
            local ok, err = pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then task.wait(0.5); return end
                local bestFish, bestPart, bestDist = nil, nil, math.huge
                local targetRarities = _G.Config.SelectedSpearRarities or {}
                local active = workspace:FindFirstChild("active")
                local rFish = active and active:FindFirstChild("roamingFish")
                if rFish then
                    for _, child in ipairs(rFish:GetChildren()) do
                        if child:IsA("Model") or child:IsA("Folder") then
                            local rarity = child.Name
                            if #targetRarities == 0 or table.find(targetRarities, rarity) then
                                for _, fish in ipairs(child:GetChildren()) do
                                    if fish:IsA("Model") then
                                        local part = fish:FindFirstChild("Hitbox") or fish:FindFirstChild("Center") or fish.PrimaryPart
                                        local fUid = getFishUID(fish)
                                        if part and fUid and fUid ~= "nil" and not fish:GetAttribute("locked")
                                            and not spearProcessing[fUid]
                                        then
                                            local dist = (part.Position - hrp.Position).Magnitude
                                            if dist < bestDist then
                                                bestDist = dist
                                                bestFish = fish
                                                bestPart = part
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if bestFish and bestPart then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if not hrp then task.wait(0.5); return end
                    if hum then
                        pcall(function()
                            hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
                        end)
                    end
                    local uid = getFishUID(bestFish)
                    if uid and uid ~= "nil" then
                        spearProcessing[uid] = true
                        local targetPos = bestPart.Position + Vector3.new(0, 5, 0)
                        hrp.CFrame = CFrame.new(targetPos)
                        task.wait(0.1)
                        if SpearFishingMinigame then
                            task.spawn(function()
                                pcall(function()
                                    SpearFishingMinigame:InvokeServer(uid, nil, true)
                                end)
                            end)
                            task.wait(0.05)
                            if SpearStabFinish then
                                pcall(function()
                                    SpearStabFinish:FireServer({
                                        e = 100,
                                        p = true,
                                        l = {},
                                        d = {}
                                    })
                                end)
                            end
                        end
                        task.wait(0.5)
                        spearProcessing[uid] = nil
                    end
                else
                    task.wait(1)
                end
            end)
            if not ok then
                warn("[NewFish5] Error in Spear Farm: " .. tostring(err))
                task.wait(1)
            end
        end
    end)
end
local function setupGUI()
    local Window = Speed_Library:CreateWindow({
        Title = "ShieldTeam || NewFish5 || Executor : " .. executorName,
        ["Tab Width"] = 110,
        SizeUi = UDim2.fromOffset(680, 420)
    })
    local GrpMain = Window:CreateGroup({"Main", "rbxassetid://7733960981"})
    local GrpMore = Window:CreateGroup({"More", "rbxassetid://7733765398"})
    local GrpSettings = Window:CreateGroup({"Settings", "rbxassetid://6031280882"})
    local Info        = GrpMain:CreateTab({ "Info",     "", "Informasi & Event" })
    local FishingTab  = GrpMain:CreateTab({ "Fishing",  "", "Auto Fishing & Cast" })
    local ShopTab     = GrpMain:CreateTab({ "Shop",     "", "Auto Shop" })
    local Exclusive   = GrpMore:CreateTab({ "Exclusive", "", "Fitur Eksklusif", Locked = true })
    local AutosTab    = GrpMore:CreateTab({ "Autos",     "", "Auto Features", Locked = true })
    local AreaTab     = GrpMore:CreateTab({ "Area/TP",   "", "Area & Teleport"})
    local EspTab      = GrpMore:CreateTab({ "ESP",       "", "ESP & Visuals", Locked = true })
    local Misc        = GrpSettings:CreateTab({ "Misc",    "", "Misc & Utils", Locked = true })
    local SettingsTab = GrpSettings:CreateTab({ "Setting", "", "Pengaturan", Locked = true })
    local PrivateServerTab = GrpSettings:CreateTab({ "VIP Server", "", "Private Server List" })
    local Infr = Info:AddSection('Info Event', true, "Left")
    Infr:AddParagraph({
        Title = "ShieldTeam NewFish5",
        Content = "Status: Online & Ready\nExecutor: " .. tostring(executorName) .. "\nVersion: 5.0"
    })
    Infr:AddParagraph({
        Title = "Server Information",
        Content = "Place Version: " .. tostring(game.PlaceVersion) .. "\nPlayers: " .. tostring(#game:GetService("Players"):GetPlayers())
    })
    pcall(function()
        createPremiumKeyUI(Info, Exclusive, AutosTab, AreaTab, EspTab, Misc, SettingsTab, Speed_Library)
    end)
    local VipSectionLeft = PrivateServerTab:AddSection("VIP Servers", true, "Left")
    local VipSectionRight = PrivateServerTab:AddSection("VIP Servers", true, "Right")
    local function loadPrivateServers()
        local success, res = pcall(function()
            return game:HttpGet("https://key.shieldteam.asia/api/private-servers")
        end)
        if success and res then
            local HttpService = game:GetService("HttpService")
            local decodeSuccess, servers = pcall(function()
                return HttpService:JSONDecode(res)
            end)
            if not decodeSuccess then
                warn("[NewFish5] JSON Decode Error: " .. tostring(servers))
                warn("[NewFish5] Response: " .. tostring(res):sub(1, 300))
            end
            if decodeSuccess and type(servers) == "table" then
                VipSectionLeft:AddParagraph({
                    Title = "Total VIP Servers: " .. tostring(#servers),
                    Content = "Salin tautan server di bawah untuk bergabung."
                })
                VipSectionRight:AddParagraph({
                    Title = "Total VIP Servers: " .. tostring(#servers),
                    Content = "Salin tautan server di bawah untuk bergabung."
                })
                if #servers == 0 then
                    VipSectionLeft:AddParagraph({
                        Title = "No Servers Available",
                        Content = "Belum ada server VIP yang terdaftar saat ini."
                    })
                else
                    for idx, server in ipairs(servers) do
                        if server.id and server.link then
                            local section = (idx % 2 == 1) and VipSectionLeft or VipSectionRight
                            section:AddParagraph({
                                Title = "Server ID: " .. tostring(server.id),
                                Content = "Klik tombol di bawah untuk menyalin tautan."
                            })
                            section:AddButton({
                                Title = "Copy Link",
                                Description = "Salin tautan server VIP ke clipboard",
                                Callback = function()
                                    local setClp = setclipboard or toclipboard or (syn and syn.write_clipboard)
                                    if setClp then
                                        setClp(server.link)
                                        Speed_Library:SetNotification({
                                            Title = "Private Server",
                                            Content = "Tautan server VIP berhasil disalin!",
                                            Time = 0.5,
                                            Delay = 3
                                        })
                                    else
                                        Speed_Library:SetNotification({
                                            Title = "Error",
                                            Content = "Executor Anda tidak mendukung setclipboard.",
                                            Time = 0.5,
                                            Delay = 3
                                        })
                                    end
                                end
                            })
                        end
                    end
                end
            else
                VipSectionLeft:AddParagraph({
                    Title = "Error Parsing Data",
                    Content = "Gagal memproses data server dari VPS."
                })
            end
        else
            VipSectionLeft:AddParagraph({
                Title = "Error Connection",
                Content = "Gagal mengambil daftar server VIP dari VPS."
            })
        end
    end
    task.spawn(loadPrivateServers)
    local MainSection      = FishingTab:AddSection("Fishing", true, "Left")
    local SettingFish      = FishingTab:AddSection("Fishing Setting", true, "Right")
    local FishingZone      = FishingTab:AddSection("Fishing Zone", true, "Right")
    local FishingEventZone = FishingTab:AddSection("Fishing Event Zone", true, "Left")
    local ShopBait = ShopTab:AddSection("Bait", true, "Left")
    local ShopItem = ShopTab:AddSection("Shop Item", true, "Right")
    local ShopRod  = ShopTab:AddSection("Rod", true, "Left")
    local Merlin   = ShopTab:AddSection("Merlin", true, "Right")
    local ExclusiveSection = Exclusive:AddSection("Exclusive", true, "Left")
    local AutoMineSection  = Exclusive:AddSection("Auto Mine", true, "Right")
    local AutoSaveSection  = Exclusive:AddSection("Auto Save", true, "Right")
    local AutosQuest        = AutosTab:AddSection("Auto Quest", true, "Left")
    local AutosJack         = AutosTab:AddSection("Auto Treasure", true, "Right")
    local AutosFavorit      = AutosTab:AddSection("Auto Fav Item/Fish", true, "Left")
    local AutosAppraise     = AutosTab:AddSection("Appraise Treasure", true, "Right")
    local AutoAppraise      = AutosTab:AddSection("Appraise", true, "Left")
    local AutoEnchant       = AutosTab:AddSection("Enchant", true, "Right")
    local AutosSection      = AutosTab:AddSection("Auto Sell", true, "Right")
    local AuraSection       = AutosTab:AddSection("Totem", true, "Left")
    local Main          = AreaTab:AddSection('Main', true, "Left")
    local SAVEPOSTION   = AreaTab:AddSection('Save Positon', true, "Right")
    local NPCSection    = AreaTab:AddSection('NPC Teleport', true, "Left")
    local BallonSection = AreaTab:AddSection('Ballon', false, "Right")
    local EspCharacterSection = EspTab:AddSection("ESP Character", true, "Left")
    local EspEventSection     = EspTab:AddSection("ESP Zone", true, "Right")
    local EspNpcSection       = EspTab:AddSection("ESP NPC", true, "Right")
    local MiscSection       = Misc:AddSection("Misc", true, "Left")
    local MiscPlayerSection = Misc:AddSection("Misc Player", true, "Right")
    local _uiRefs = {}
    local function _regToggle(ref, configKey, cb)
        if ref then _uiRefs[#_uiRefs + 1] = { ref = ref, key = configKey, cb = cb } end
    end
    getgenv().__uiRefs = _uiRefs
    getgenv().regUIElement = _regToggle
    local streakStatsParagraph = SettingFish:AddParagraph({
        Title = "Player Tracker Stats",
        Content = "- Caught: 0 (0.00% perf)\n- Reels: 0 broken\n- Streak: 0"
    })
    SettingFish:AddSlider({
        Title = "Break Streak Target",
        Description = "Gagalkan ikan setiap X kali streak",
        Min = 1,
        Max = 500,
        Default = _G.Config.BreakStreakCount or 100,
        Callback = function(value)
            _G.Config.BreakStreakCount = value
        end
    })
    local _tBreakStreak = SettingFish:AddToggle({
        Title = "Auto Break Streak",
        Description = "Gagalkan tangkapan otomatis setelah mencapai target streak",
        Default = _G.Config.BreakStreakEnabled or false,
        Callback = function(value)
            _G.Config.BreakStreakEnabled = value
            if not value then
                _G.Config.BreakStreakCurrent = 0
            end
        end
    })
    _regToggle(_tBreakStreak, "BreakStreakEnabled", function(v) _G.Config.BreakStreakEnabled = v end)
    local cachedStatsFolder = nil
    local function getStatsFolder()
        if cachedStatsFolder and cachedStatsFolder.Parent then return cachedStatsFolder end
        pcall(function()
            local player = Players.LocalPlayer
            if not player then return end
            print("[Tracker Debug] Searching for PlayerStats for:", player.Name)
            local ps = workspace:FindFirstChild("PlayerStats") or game:GetService("ReplicatedStorage"):FindFirstChild("PlayerStats")
            if ps then
                print("[Tracker Debug] Found PlayerStats container:", ps:GetFullName())
                local pf = ps:FindFirstChild(player.Name)
                if pf then
                    print("[Tracker Debug] Found player folder:", pf:GetFullName())
                    for _, desc in ipairs(pf:GetDescendants()) do
                        if desc.Name == "tracker_fishcaught" or desc.Name == "tracker_streak" or desc.Name == "tracker_reelsbroken" then
                            print("[Tracker Debug] Found stat item:", desc.Name, "in folder:", desc.Parent:GetFullName())
                            cachedStatsFolder = desc.Parent
                            return
                        end
                    end
                else
                    print("[Tracker Debug] Player folder NOT found in PlayerStats for:", player.Name)
                end
                for _, desc in ipairs(ps:GetDescendants()) do
                    if desc.Name == "tracker_fishcaught" or desc.Name == "tracker_streak" then
                        print("[Tracker Debug] Found stat item via fallback:", desc.Name, "in folder:", desc.Parent:GetFullName())
                        cachedStatsFolder = desc.Parent
                        return
                    end
                end
            else
                print("[Tracker Debug] PlayerStats container NOT found in workspace or ReplicatedStorage!")
            end
        end)
        return cachedStatsFolder
    end
    local lastPrintTick = 0
    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                local stats = getStatsFolder()
                local function readVal(itemNames, localFallback)
                    if stats then
                        for _, n in ipairs(itemNames) do
                            local v = stats:FindFirstChild(n)
                            if v and (v:IsA("ValueObject") or v.ClassName:find("Value")) then
                                return v.Value
                            end
                        end
                    end
                    return localFallback or 0
                end
                local caught = readVal({"tracker_fishcaught", "fishcaught", "FishCaught"}, _G.LocalFishCaught)
                local perf = readVal({"tracker_perfectcatches", "perfectcatches", "PerfectCatches"}, _G.LocalPerfectCatches)
                local reelsBroken = readVal({"tracker_reelsbroken", "reelsbroken", "ReelsBroken"}, _G.LocalReelsBroken)
                local streak = readVal({"tracker_streak", "streak", "Streak", "FishStreak"}, _G.LocalCurrentStreak)
                local perfPct = (caught > 0) and ((perf / caught) * 100) or 0
                if tick() - lastPrintTick >= 3 then
                    lastPrintTick = tick()
                    print(string.format("[Tracker Debug] Stats -> StatsFolder: %s | Caught: %s | Perf: %s | ReelsBroken: %s | Streak: %s",
                        stats and stats:GetFullName() or "N/A", tostring(caught), tostring(perf), tostring(reelsBroken), tostring(streak)))
                end
                local formattedContent = string.format(
                    "- Caught: %s (%.2f%% perf)\n- Reels: %s broken\n- Streak: %s",
                    tostring(caught), perfPct, tostring(reelsBroken), tostring(streak)
                )
                if streakStatsParagraph then
                    local ok = pcall(function()
                        streakStatsParagraph:Set({ Title = "Player Tracker Stats", Content = formattedContent })
                    end)
                    if not ok then
                        pcall(function() streakStatsParagraph:Set(formattedContent) end)
                        pcall(function() streakStatsParagraph:SetText(formattedContent) end)
                        pcall(function() streakStatsParagraph:SetContent(formattedContent) end)
                        pcall(function()
                            local pObj = (typeof(streakStatsParagraph) == "table" and streakStatsParagraph.Instance) or streakStatsParagraph
                            if typeof(pObj) == "Instance" then
                                for _, desc in ipairs(pObj:GetDescendants()) do
                                    if desc:IsA("TextLabel") and desc.Name ~= "Title" then
                                        desc.Text = formattedContent
                                    end
                                end
                            end
                        end)
                    end
                end
            end)
        end
    end)
    local _tReel = MainSection:AddDropdown({
        Title = "Reel...",
        Options = {"Super Instant", "Legit", "Manual"},
        Default = _G.Config.ReelMode or "Super Instant",
        Callback = function(v)
            _G.Config.ReelMode = v
            _G.Config.InstantReel = false
            if v == "Super Instant" then
                _G.Config.InstantReel = true
                if AutoReel then AutoReel(true) end
            elseif v == "Legit" then
                if AutoReel then AutoReel(true) end
            else
                if AutoReel then AutoReel(false) end
            end
        end
    })
    _regToggle(_tReel, "ReelMode", function(v)
        _G.Config.ReelMode = v
        _G.Config.InstantReel = (v == "Super Instant")
        if AutoReel then AutoReel(v ~= "Manual") end
    end)
    local _tBobber = MainSection:AddToggle({
        Title = "Instant Bobber",
        Default = _G.Config.AutoCast or false,
        Callback = function(value)
            _G.Config.AutoCast = value
            _G.Config.InstantCast = value
            if AutoCast then AutoCast(value) end
            if InstantBobber then InstantBobber(value) end
        end
    })
    _regToggle(_tBobber, "AutoCast", function(v)
        _G.Config.AutoCast = v
        _G.Config.InstantCast = v
        if AutoCast then AutoCast(v) end
        if InstantBobber then InstantBobber(v) end
    end)
    local _tAutoEquip = MainSection:AddToggle({
        Title = "Auto Equip Rod",
        Default = _G.Config.isEquipRpd or false,
        Callback = function(value)
            _G.Config.isEquipRpd = value
            if MiscFishing then MiscFishing.AutoEquipRod(value) end
        end
    })
    _regToggle(_tAutoEquip, "isEquipRpd", function(v)
        _G.Config.isEquipRpd = v
        if MiscFishing then MiscFishing.AutoEquipRod(v) end
    end)
    local _tAutoShake = MainSection:AddToggle({
        Title = "Auto Shake",
        Default = _G.Config.AutoShake or false,
        Callback = function(value)
            _G.Config.AutoShake = value
            if AutoShake then AutoShake(value) end
        end
    })
    _regToggle(_tAutoShake, "AutoShake", function(v)
        _G.Config.AutoShake = v
        if AutoShake then AutoShake(v) end
    end)
    local _tNoActionSafe = MainSection:AddToggle({
        Title = "No Action Safe",
        Description = "Reset rod jika stuck pas nyemplung/narik ikan >10 dtk",
        Default = _G.Config.NoActionSafe or false,
        Callback = function(enabled)
            _G.Config.NoActionSafe = enabled
            if enabled then
                if _G.__noActionSafeRunning then return end
                _G.__noActionSafeRunning = true
                task.spawn(function()
                    local lastFishTick = tick()
                    while _G.Config.NoActionSafe do
                        task.wait(1)
                        local char = Players.LocalPlayer.Character
                        if char then
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            local tool = char:FindFirstChildOfClass("Tool")
                            local isRod = false
                            if tool then
                                if tool:FindFirstChild("events") or tool:FindFirstChild("rod/client") or (tool:FindFirstChild("rod") and tool.rod:FindFirstChild("client")) then
                                    isRod = true
                                end
                            end
                            if isRod then
                                local recentCatch = false
                                if type(_G.LastCatchTick) == "number" and (tick() - _G.LastCatchTick < 5) then
                                    recentCatch = true
                                end
                                if type(_G.LastCaughtEventTick) == "number" and (tick() - _G.LastCaughtEventTick < 10) then
                                    recentCatch = true
                                end
                                if recentCatch then
                                    lastFishTick = tick()
                                end
                                if tick() - lastFishTick >= 10 then
                                    if _G.Config.DiscordWebhookEnabled and _G.Config.DiscordWebhookURL and _G.Config.DiscordWebhookURL ~= "" then
                                        task.spawn(function()
                                            pcall(function()
                                                local requestFunc = request or http_request or (http and http.request) or (syn and syn.request)
                                                if requestFunc then
                                                    local payload = {
                                                        content = "@everyone",
                                                        embeds = {{
                                                            title = "⚠️ No Action Safe Triggered!",
                                                            description = "Rod terjebak lebih dari 10 detik. Melakukan reset otomatis.",
                                                            color = 16711680,
                                                            footer = { text = "Shield Team Client" },
                                                            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                                                        }}
                                                    }
                                                    requestFunc({
                                                        Url = _G.Config.DiscordWebhookURL,
                                                        Method = "POST",
                                                        Headers = { ["Content-Type"] = "application/json" },
                                                        Body = game:GetService("HttpService"):JSONEncode(payload)
                                                    })
                                                end
                                            end)
                                        end)
                                    end
                                    pcall(function()
                                        char:SetAttribute("Reeling", nil)
                                        if hum then
                                            hum:UnequipTools()
                                        end
                                    end)
                                    lastFishTick = tick()
                                end
                            else
                                lastFishTick = tick()
                            end
                        end
                    end
                    _G.__noActionSafeRunning = false
                end)
            end
        end
    })
    _regToggle(_tNoActionSafe, "NoActionSafe", function(v) _G.Config.NoActionSafe = v end)
    local _tBalanceNuke = MainSection:AddToggle({
        Title = "Balance Nuke",
        Description = "Auto completes Love Nuke and Atomic Nuke minigames",
        Default = _G.Config.AutoNukeEnabled or false,
        Callback = function(Value)
            _G.Config.AutoNukeEnabled = Value
            if Value then
                if _G.__autoNukeRunning then return end
                _G.__autoNukeRunning = true
                task.spawn(function()
                    if getgc and debug and debug.info and debug.setupvalue then
                        task.spawn(function()
                            for _, v in pairs(getgc(true)) do
                                if type(v) == "function" then
                                    local name = debug.info(v, "n")
                                    if name == "LoopMinigame" then
                                        task.spawn(function()
                                            while _G.Config.AutoNukeEnabled do
                                                local ok = pcall(function()
                                                    debug.setupvalue(v, 13, workspace:GetServerTimeNow() - 10)
                                                end)
                                                if not ok then break end
                                                task.wait(0.05)
                                            end
                                        end)
                                    end
                                end
                            end
                        end)
                    end
                    local function pressButton(button)
                        if not button then return end
                        pcall(function()
                            local mockInput = { UserInputType = Enum.UserInputType.MouseButton1 }
                            if firesignal then
                                pcall(function() firesignal(button.Activated, mockInput) end)
                                pcall(function() firesignal(button.Activated) end)
                                pcall(function() firesignal(button.MouseButton1Click) end)
                            end
                            if getconnections then
                                for _, c in pairs(getconnections(button.Activated)) do
                                    pcall(function() c:Fire(mockInput) end)
                                end
                                for _, c in pairs(getconnections(button.MouseButton1Click)) do
                                    pcall(function() c:Fire() end)
                                end
                            end
                        end)
                    end
                    while _G.Config.AutoNukeEnabled do
                        task.wait()
                        pcall(function()
                            local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
                            local nukeGui = playerGui and playerGui:FindFirstChild("NukeMinigame")
                            if nukeGui and nukeGui.Enabled then
                                local center = nukeGui:FindFirstChild("Center")
                                local marker = center and center:FindFirstChild("Marker")
                                local pointer = marker and marker:FindFirstChild("Pointer")
                                local frame = pointer and (pointer:FindFirstChild("Frame") or pointer)
                                local leftBtn = center and center:FindFirstChild("Left")
                                local rightBtn = center and center:FindFirstChild("Right")
                                if pointer then
                                    local rot = pointer.Rotation
                                    if rot == 0 and frame then
                                        rot = frame.AbsoluteRotation
                                    end
                                    if rot < -5 then
                                        pressButton(rightBtn)
                                    elseif rot > 5 then
                                        pressButton(leftBtn)
                                    end
                                end
                            end
                        end)
                    end
                    _G.__autoNukeRunning = false
                end)
            end
        end
    })
    _regToggle(_tBalanceNuke, "AutoNukeEnabled", function(v) _G.Config.AutoNukeEnabled = v end)
    MainSection:AddSeperator({
        Title = 'Snap Fish',
    })
    MainSection:AddDropdown({
        Title = "Snap Rarity",
        Multi = true,
        Options = {"Trash", "Common", "Uncommon", "Unusual", "Rare", "Legendary", "Mythical", "Exotic", "Secret", "Divine Secret", "Limited", "Special","Gemstone", "Event", "Extinct", "Apex"},
        Default = _G.__var.SnapRarity or {},
        Callback = function(val)
            _G.__var.SnapRarity = val
            if _G.ClearSnapCache then _G.ClearSnapCache() end
        end
    })
    MainSection:AddDropdown({
        Title = "Snap Relic",
        Multi = true,
        Options = {
            "Exalted Relic",
            "Cosmic Relic",
            "Enchant Relic",
            "Sovereign Relic",
            "Twisted Relic",
        },
        Default = _G.__var.SnapRelics or {},
        Callback = function(val)
            _G.__var.SnapRelics = val
            if _G.ClearSnapCache then _G.ClearSnapCache() end
        end
    })
    MainSection:AddInput({
        Title = "Snap Fish Name",
        Default = _G.__var.SnapTargetManual or "",
        Placeholder = "Example: Salmon, Shark, Tuna",
        Callback = function(v)
            _G.__var.SnapTargetManual = v
            if _G.ClearSnapCache then _G.ClearSnapCache() end
        end
    })
    local finalOptions = {"Shiny", "Sparkling", "Husk", "RainbowCluster", "None"}
    local succeeded, err = pcall(function()
        local shared = game:GetService("ReplicatedStorage"):WaitForChild("shared")
        local modules = shared:WaitForChild("modules")
        local fishing = modules:WaitForChild("fishing")
        local mutationsModule = fishing:WaitForChild("mutations")
        local module = require(mutationsModule)
        local mutations = module.Mutations or module
        local sortedMutations = {}
        for name, data in pairs(mutations) do
            if type(data) == "table" then
                local displayName = data.Display or name
                table.insert(sortedMutations, displayName)
            end
        end
        table.sort(sortedMutations)
        for _, mut in ipairs(sortedMutations) do
            if not table.find(finalOptions, mut) then
                table.insert(finalOptions, mut)
            end
        end
    end)
    if not succeeded then warn("Failed to fetch mutations: " .. tostring(err)) end
    MainSection:AddDropdown({
        Title = "Snap Mutation/Trait",
        Multi = true,
        Options = finalOptions,
        Default = _G.__var.SnapMutations or {},
        Callback = function(v)
            if _G.ClearSnapCache then _G.ClearSnapCache() end
            _G.__var.SnapMutations = v
        end
    })
    MainSection:AddToggle({
        Title = "Enable Auto Snap",
        Description = "Automatically reset rod if fish doesn't match filters",
        Default = _G.__var.AutoSnapEnabled or false,
        Callback = function(v)
            _G.__var.AutoSnapEnabled = v
        end
    })
    local _tDelFish = SettingFish:AddToggle({
        Title = "Delete Fish Model",
        Default = _G.Config.DeleteFishModel or false,
        Callback = function(value)
            if MiscFishing then MiscFishing.DeleteFishModel(value) end
        end
    })
    _regToggle(_tDelFish, "DeleteFishModel", function(v)
        if MiscFishing then MiscFishing.DeleteFishModel(v) end
    end)
    SettingFish:AddToggle({
        Title = "Delete All Map",
        Default = false,
        Callback = function(value)
            if MiscFishing then MiscFishing.DeleteAllMap(value) end
        end
    })
    local _tDelPlayer = SettingFish:AddToggle({
        Title = "Delete All Characters",
        Default = _G.Config.DeletePlayer or false,
        Callback = function(value)
            if MiscFishing then MiscFishing.DeleteAllCharacters(value) end
        end
    })
    _regToggle(_tDelPlayer, "DeletePlayer", function(v)
        if MiscFishing then MiscFishing.DeleteAllCharacters(v) end
    end)
    local _tAutoExecute = SettingFish:AddToggle({
        Title = "Auto Execute",
        Default = _G.Config.AutoExecute or false,
        Callback = function(value)
            _G.Config.AutoExecute = value
            if value then
                autoExecute()
            end
        end
    })
    _regToggle(_tAutoExecute, "AutoExecute", function(v) _G.Config.AutoExecute = v end)
    SettingFish:AddSlider({
        Title = "Bar Size",
        Min = 1,
        Max = 20,
        Default = 1,
        Callback = function(value)
            if _G.__var then _G.__var.barSize = value end
        end
    })
    SettingFish:AddSlider({
        Title = "Perfect Catch %",
        Min = 0,
        Max = 100,
        Default = _G.Config.perfectCatchEnabled or 0,
        Callback = function(value)
            _G.Config.perfectCatchEnabled = value
            _G.Config.PerfectCatchChance = value
        end
    })
    SettingFish:AddSlider({
        Title = "Perfect Cast %",
        Min = 0,
        Max = 100,
        Default = _G.Config.perfectCastEnabled or 0,
        Callback = function(value)
            _G.Config.perfectCastEnabled = value
        end
    })
    local fishingSpots = {
        "None", "Moosewood Village", "Roslit Hamlet", "Sunstone Island",
        "Terrapin Island", "The Depths", "Ancient Isles", "Forsaken Shores",
        "Crimson Cavern", "Luminescent Cavern", "Lost Jungle", "Crystal Cove"
    }
    FishingZone:AddDropdown({
        Title = "Fishing Zone",
        Options = fishingSpots,
        Default = _G.Config.selectedZone or "None",
        Callback = function(selected)
            if type(selected) == "table" then
                _G.Config.selectedZone = selected[1] or "None"
            else
                _G.Config.selectedZone = selected
            end
        end
    })
    local _tZoneTp = FishingZone:AddToggle({
        Title = "Auto Fishing Teleport",
        Content = "Enable/Disable Teleport to Fishing Zone",
        Default = _G.Config.selectedZoneADS or false,
        Callback = function(Value)
            task.spawn(function()
                _G.Config.selectedZoneADS = Value
                local TeleportArea = getMod("TeleportArea")
                if TeleportArea and TeleportArea.TeleportToZone then
                    if _G.Config.selectedZoneADS then
                        TeleportArea.TeleportToZone(_G.Config.selectedZone or "None")
                    else
                        TeleportArea.TeleportToZone("None")
                    end
                end
            end)
        end
    })
    _regToggle(_tZoneTp, "selectedZoneADS", function(v)
        _G.Config.selectedZoneADS = v
        local TeleportArea = getMod("TeleportArea")
        if TeleportArea and TeleportArea.TeleportToZone then
            if v then
                TeleportArea.TeleportToZone(_G.Config.selectedZone or "None")
            else
                TeleportArea.TeleportToZone("None")
            end
        end
    end)
    FishingZone:AddSeperator({
        Title = "Spear Fishing",
    })
    local detectedRarities = {}
    local function getRoamingFolders()
        local active = workspace:FindFirstChild("active")
        local rFish = active and active:FindFirstChild("roamingFish")
        if rFish then
            for _, child in ipairs(rFish:GetChildren()) do
                if (child:IsA("Model") or child:IsA("Folder")) and not table.find(detectedRarities, child.Name) then
                    table.insert(detectedRarities, child.Name)
                end
            end
        end
        table.sort(detectedRarities)
        return detectedRarities
    end
    local _tSpearRarities = FishingZone:AddDropdown({
        Title = "Spear Target Rarities",
        Multi = true,
        Options = getRoamingFolders(),
        Default = _G.Config.SelectedSpearRarities or {},
        Callback = function(val)
            _G.Config.SelectedSpearRarities = val
        end
    })
    task.spawn(function()
        local active = workspace:WaitForChild("active", 10)
        local rFish = active and active:WaitForChild("roamingFish", 10)
        if rFish then
            local current = getRoamingFolders()
            if #current > 0 then
                pcall(function()
                    _tSpearRarities:Refresh(current, _G.Config.SelectedSpearRarities or {})
                end)
            end
            rFish.ChildAdded:Connect(function(child)
                if child:IsA("Model") or child:IsA("Folder") then
                    task.wait(0.5)
                    local name = child.Name
                    if not table.find(detectedRarities, name) then
                        table.insert(detectedRarities, name)
                        table.sort(detectedRarities)
                        pcall(function()
                            _tSpearRarities:Refresh(detectedRarities, _G.Config.SelectedSpearRarities or {})
                        end)
                    end
                end
            end)
        end
    end)
    local _tSpearCatch = FishingZone:AddToggle({
        Title = "Spear Auto Catch",
        Content = "Auto catch roaming fish with spear",
        Default = _G.Config.EnableSpearCatch or false,
        Callback = function(val)
            _G.Config.EnableSpearCatch = val
            if val then
                startSpearFarmLoop()
            end
        end
    })
    _regToggle(_tSpearCatch, "EnableSpearCatch", function(v)
        _G.Config.EnableSpearCatch = v
        if v then
            startSpearFarmLoop()
        end
    end)
    FishingEventZone:AddDropdown({
        Title = "Select Zone Event",
        Multi = true,
        Options = {
            "Orca", "Lovestorm", "Baby Bloop Fish", "Plesiosaur Hunt", "Pliosaur Hunt",
            "Goldwraith Hunt", "Reef Titan Hunt", "Sunken Reliquary", "Omnithal Hunt",
            "Bloop Fish", "Moby", "Megalodon", "Mossjaw", "Megalodon Ancient",
            "Megalodon Phantom", "Great White Shark", "Hammerhead Shark", "Whale Shark",
            "The Depths - Serpent", "Sovereign Beam", "Isonade (Strange Whirlpool)",
            "Scylla (Forsaken Veil)", "Blarney McBreeze", "Sea Leviathan Pool",
            "Animal Pool", "Octophant Pool Without Elephant", "Kraken Pool",
            "Blue Moon - Sea 2", "Blue Moon - Sea 1", "Lego Pool", "Studolodon Pool",
            "Mosslurker", "Narwhal", "MossjawHunt", "BrineStorm", "KrakenHunt",
            "MegHunt", "MoonlitMirage", "ScyllaHunt", "ReefTitan", "FrostwyrmHunt",
            "The Sanctum Hunt", "The Sanctum Profane Hunt", "DepthsAbsoluteDarkness",
            "Colossal Blue Dragon", "Colossal Ancient Dragon", "Colossal Ethereal Dragon",
            "SkeletalLeviathanHunt", "WyvernHunt", "NectarBloom", "RotbloomHunt",
            "FlowerGuardianHunt"
        },
        Default = _G.__var and _G.__var.Hunting_Target or {},
        Callback = function(Value)
            if _G.__var then
                _G.__var.Hunting_Target = Value
            end
        end
    })
    FishingEventZone:AddToggle({
        Title = "Auto Zone Event",
        Default = _G.__var and _G.__var.Hunting_Enabled or false,
        Callback = function(Value)
            if not _G.__var then return end
            if Value then
                _G.__var.Hunting_Enabled = true
                local lp = Players.LocalPlayer
                if not _G.__var.savedPosition then
                    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        _G.__var.savedPosition = root.CFrame
                    end
                end
                task.spawn(function()
                    while _G.__var and _G.__var.Hunting_Enabled do
                        task.wait(1)
                        pcall(function()
                            local fishingZone = workspace:FindFirstChild("zones") and workspace.zones:FindFirstChild("fishing")
                            if not fishingZone then return end
                            local targetArray = type(_G.__var.Hunting_Target) == "table" and _G.__var.Hunting_Target or {_G.__var.Hunting_Target}
                            local target_pool = nil
                            local target_spawn = nil
                            local target_name = nil
                            for _, t in ipairs(targetArray) do
                                local temp_pool = nil
                                local temp_spawn = nil
                                if t == "Orca" then
                                    temp_pool = fishingZone:FindFirstChild("Orcas Pool")
                                elseif t == "Moby" then
                                    local whale_pool = fishingZone:FindFirstChild("Whales Pool")
                                    if whale_pool then
                                        temp_pool = whale_pool
                                        temp_spawn = whale_pool:FindFirstChild("MobySpawn")
                                    end
                                elseif t == "Sovereign Beam" then
                                    local tagged = game:GetService("CollectionService"):GetTagged("SovereignBeam")
                                    if #tagged > 0 then temp_pool = tagged[1] end
                                else
                                    temp_pool = fishingZone:FindFirstChild(t)
                                end
                                if temp_pool then
                                    target_pool = temp_pool
                                    target_spawn = temp_spawn
                                    target_name = t
                                    break
                                end
                            end
                            if target_pool then
                                local teleport_pos = nil
                                if target_name == "Orca" or target_name == "Scylla (Forsaken Veil)" or target_name == "Blarney McBreeze" or target_name == "Sea Leviathan Pool" then
                                    teleport_pos = CFrame.new(target_pool.Position + Vector3.new(0, 74, 0))
                                elseif target_name == "Moby" and target_spawn then
                                    teleport_pos = CFrame.new(target_spawn.Position + Vector3.new(0, 50, 0))
                                elseif target_name == "Kraken Pool" then
                                    teleport_pos = CFrame.new(target_pool.Position + Vector3.new(0, 73, 0))
                                elseif target_name == "Isonade (Strange Whirlpool)" then
                                    teleport_pos = CFrame.new(target_pool.Position + Vector3.new(20, 115, 20))
                                else
                                    teleport_pos = CFrame.new(target_pool.Position + Vector3.new(0, 15, 0))
                                end
                                local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                                if root and teleport_pos then
                                    root.CFrame = teleport_pos
                                end
                            end
                        end)
                    end
                    if _G.__var and _G.__var.savedPosition then
                        local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            root.CFrame = _G.__var.savedPosition
                        end
                        _G.__var.savedPosition = nil
                    end
                end)
            else
                _G.__var.Hunting_Enabled = false
                if _G.__var.savedPosition then
                    local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.CFrame = _G.__var.savedPosition
                    end
                    _G.__var.savedPosition = nil
                end
            end
        end
    })
    local _t = AutosSection:AddToggle({
        Title = "Auto Sell",
        Default = _G.Config.AutoSell or false,
        Callback = function(value)
            if AutoSell then AutoSell(value) end
        end
    })
    _regToggle(_t, "AutoSell", function(v) if AutoSell then AutoSell(v) end end)
    getgenv().__var = {
        reelConnection = nil,
        autoReelEnabled = true,
        perfectCatchEnabled = 0,
        perfectCastEnabled = 0,
        DelayTimeFaster = 0.1,
        isReeling = false,
        AutoSnapEnabled = false,
        SnapRelics = {},
        SnapRarity = {},
        SnapTarget = "",
        SnapMutations = {},
        Hunting_Enabled = false,
        Hunting_Target = nil,
        SnapTargetManual = "",
        savedPosition = nil,
        barSize = 2,
        Notif5Counter = 0,
        lastSkipTime = os.time()
    }
    _G.__var = getgenv().__var
    getgenv().configFolder = "ExclusiveConfigs/"
    getgenv().currentConfigFile = "Default"
    getgenv().savedConfigsList = {}
    getgenv().lastSaveTime = os.time()
    getgenv().totalSaves = 0
    getgenv().ConfigStatusParagraph = nil
    getgenv().teleportToSavedPosition = function(position)
        if not position or not position.X or not position.Y or not position.Z then
            return false
        end
        task.spawn(function()
            local player = game.Players.LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(position.X, position.Y, position.Z)
                task.wait(0.5)
            end
        end)
        return true
    end
    getgenv().deepCopy = function(original)
        if type(original) ~= "table" then
            return original
        end
        local copy = {}
        for key, value in pairs(original) do
            local typeKey = type(key)
            local typeVal = type(value)
            if typeKey == "string" or typeKey == "number" then
                if typeKey == "string" and key:match("^<Function>") then
                else
                    if typeVal == "table" then
                        copy[key] = getgenv().deepCopy(value)
                    elseif typeVal == "string" or typeVal == "number" or typeVal == "boolean" then
                        copy[key] = value
                    end
                end
            end
        end
        return copy
    end
    getgenv().loadConfig = function(configName, autoTeleport)
        configName = configName or getgenv().currentConfigFile
        if autoTeleport == nil then
            autoTeleport = _G.Config.AutoTeleportOnLoad
        end
        local filePath = getgenv().configFolder .. configName .. ".json"
        if readfile and isfile and isfile(filePath) then
            local HttpService = game:GetService("HttpService")
            local success, result = pcall(function()
                return HttpService:JSONDecode(readfile(filePath))
            end)
            if success and result then
                local loadedConfig = result.Config or result
                local loadedVar = result.Var or {}
                for key, value in pairs(loadedConfig) do
                    if key == "SavedPosition" then
                        if type(value) == "table" and value.x then
                            _G.Config[key] = CFrame.new(value.x, value.y, value.z)
                        else
                            _G.Config[key] = nil
                        end
                    elseif type(value) == "table" then
                        _G.Config[key] = value
                    else
                        _G.Config[key] = value
                    end
                end
                for key, value in pairs(loadedVar) do
                    if key ~= "reelConnection" and key ~= "isReeling" then
                        getgenv().__var[key] = value
                    end
                end
                getgenv().currentConfigFile = configName
                getgenv().lastSaveTime = os.time()
                task.defer(function()
                    local refs = getgenv().__uiRefs
                    if refs then
                        for _, entry in ipairs(refs) do
                            local val = _G.Config[entry.key]
                            if val ~= nil then
                                pcall(function()
                                    if entry.ref.Set then
                                        entry.ref:Set(val)
                                    elseif entry.ref.SetValue then
                                        entry.ref:SetValue(val)
                                    end
                                end)
                                pcall(entry.cb, val)
                            end
                        end
                    end
                end)
                if autoTeleport and _G.Config.SavedPosition then
                    getgenv().teleportToSavedPosition(_G.Config.SavedPosition)
                end
                return true
            end
        end
        warn("[Config] Load failed: " .. configName)
        return false
    end
    getgenv().saveConfig = function(configName)
        configName = configName or getgenv().currentConfigFile
        if not isfolder(getgenv().configFolder) then
            makefolder(getgenv().configFolder)
        end
        local configCopy = getgenv().deepCopy(_G.Config)
        local savedPosCF = _G.Config.SavedPosition
        if savedPosCF then
            if typeof(savedPosCF) == "CFrame" then
                configCopy.SavedPosition = { x = savedPosCF.X, y = savedPosCF.Y, z = savedPosCF.Z }
            elseif type(savedPosCF) == "table" and (savedPosCF.x or savedPosCF.X) then
                configCopy.SavedPosition = {
                    x = savedPosCF.x or savedPosCF.X,
                    y = savedPosCF.y or savedPosCF.Y,
                    z = savedPosCF.z or savedPosCF.Z
                }
            else
                configCopy.SavedPosition = nil
            end
        else
            configCopy.SavedPosition = nil
        end
        local data = {
            Config = configCopy,
            Var = {}
        }
        for k, v in pairs(getgenv().__var) do
            if k ~= "reelConnection" and k ~= "isReeling" then
                data.Var[k] = v
            end
        end
        local HttpService = game:GetService("HttpService")
        local success, result = pcall(function()
            return HttpService:JSONEncode(data)
        end)
        if success and writefile then
            writefile(getgenv().configFolder .. configName .. ".json", result)
            print("[Config] Saved config successfully to " .. configName)
            return true
        end
        return false
    end
    if isfolder and isfolder(getgenv().configFolder) and listfiles then
        local files = listfiles(getgenv().configFolder)
        local found = {}
        for _, file in pairs(files) do
            if type(file) == "string" and file:match("%.json$") then
                local fileName = file:match("([^/\\]+)%.json$")
                if fileName then
                    table.insert(found, fileName)
                end
            end
        end
        table.sort(found)
        if #found > 0 then
            getgenv().loadConfig(found[1], true)
        end
    end
    local InitExclusive = getMod("Exclusive")
    if not InitExclusive then
        pcall(function()
            InitExclusive = require(script.Parent.Modules.Exclusive)
        end)
    end
    local InitShop = getMod("Shop")
    if not InitShop then
        pcall(function()
            InitShop = require(script.Parent.Modules.Shop)
        end)
    end
    local InitAutos = getMod("Autos")
    if not InitAutos then
        pcall(function()
            InitAutos = require(script.Parent.Modules.Autos)
        end)
    end
    local InitAreaTP = getMod("AreaTP")
    if not InitAreaTP then
        pcall(function()
            InitAreaTP = require(script.Parent.Modules.AreaTP)
        end)
    end
    if InitExclusive then
        local function patchUI(obj)
            if type(obj) ~= "table" then return obj end
            if not obj.AddSeperator then
                obj.AddSeperator = function() end
            end
            if not obj.AddSeparator then
                obj.AddSeparator = function() end
            end
            if obj.AddSection then
                local oldAddSection = obj.AddSection
                obj.AddSection = function(self, ...)
                    local newSec = oldAddSection(self, ...)
                    if newSec then patchUI(newSec) end
                    return newSec
                end
            end
            if obj.AddParagraph then
                local oldAddPara = obj.AddParagraph
                obj.AddParagraph = function(self, ...)
                    local para = oldAddPara(self, ...)
                    if para and not para.SetDesc then
                        para.SetDesc = function(s, text)
                            if s.Set then pcall(function() s:Set({Content = text}) end) end
                        end
                    end
                    return para
                end
            end
            return obj
        end
        getgenv().Info = patchUI(Info)
        getgenv().FishingTab = patchUI(FishingTab)
        getgenv().ShopTab = patchUI(ShopTab)
        getgenv().Exclusive = patchUI(Exclusive)
        getgenv().AutosTab = patchUI(AutosTab)
        getgenv().AreaTab = patchUI(AreaTab)
        getgenv().EspTab = patchUI(EspTab)
        getgenv().Misc = patchUI(Misc)
        getgenv().SettingsTab = patchUI(SettingsTab)
        patchUI(ExclusiveSection)
        patchUI(AutoMineSection)
        patchUI(AutoSaveSection)
        patchUI(NPCSection)
        patchUI(BallonSection)
        patchUI(EspCharacterSection)
        patchUI(EspEventSection)
        patchUI(EspNpcSection)
        getgenv().startAutoClaimMulti = function()
            local targetItems = {"Lunar Thread", "Starfall Totem", "Cosmic Relic", "Meteoric"}
            local function searchForItems(parent, depth)
                if depth > 10 then return false end
                local itemsClaimed = false
                for _, child in ipairs(parent:GetChildren()) do
                    if not _G.Config.AutoClaimMulti then return false end
                    for _, itemName in ipairs(targetItems) do
                        if child.Name == itemName then
                            local prompt = nil
                            local targetPosition = nil
                            local center = child:FindFirstChild("Center")
                            if center then
                                for _, centerChild in ipairs(center:GetChildren()) do
                                    if centerChild:IsA("ProximityPrompt") and centerChild.Enabled then
                                        prompt = centerChild
                                        break
                                    end
                                end
                            end
                            if not prompt then
                                for _, itemChild in ipairs(child:GetChildren()) do
                                    if itemChild:IsA("ProximityPrompt") and itemChild.Enabled then
                                        prompt = itemChild
                                        break
                                    end
                                end
                            end
                            if child:IsA("BasePart") then
                                targetPosition = child.CFrame
                            elseif child:IsA("Model") and child.PrimaryPart then
                                targetPosition = child.PrimaryPart.CFrame
                            elseif child:IsA("Model") then
                                for _, modelChild in ipairs(child:GetChildren()) do
                                    if modelChild:IsA("BasePart") then
                                        targetPosition = modelChild.CFrame
                                        break
                                    end
                                end
                            end
                            if prompt and targetPosition then
                                local player = game.Players.LocalPlayer
                                local char = player.Character
                                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    print("Teleporting to claim " .. itemName .. "...")
                                    hrp.CFrame = targetPosition + Vector3.new(0, 3, 0)
                                    task.wait(0.5)
                                    local claimAttempts = 0
                                    while _G.Config.AutoClaimMulti and prompt and prompt.Parent and prompt.Enabled and claimAttempts < 10 do
                                        pcall(function()
                                            fireproximityprompt(prompt)
                                        end)
                                        task.wait(0.2)
                                        claimAttempts = claimAttempts + 1
                                    end
                                    if not prompt.Enabled then
                                        print("Successfully claimed " .. itemName .. "!")
                                        itemsClaimed = true
                                    end
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                    if child:IsA("Folder") or child:IsA("Model") or child.Name == "StarCrater" or child.Name == "Root" then
                        if searchForItems(child, depth + 1) then
                            itemsClaimed = true
                        end
                    end
                end
                return itemsClaimed
            end
            task.spawn(function()
                while _G.Config.AutoClaimMulti do
                    local player = game.Players.LocalPlayer
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local oldCFrame = hrp.CFrame
                        local claimed = searchForItems(workspace, 0)
                        if _G.Config.AutoClaimMulti and claimed and hrp then
                            hrp.CFrame = oldCFrame
                            print("Returned to original position")
                        end
                        task.wait(2)
                    else
                        task.wait(2)
                    end
                end
            end)
        end
        if InitExclusive then
            pcall(function()
                InitExclusive(ExclusiveSection, AutoMineSection, AutoSaveSection, EspCharacterSection, EspEventSection, EspNpcSection)
            end)
        end
        if InitShop then
            pcall(function()
                InitShop(ShopBait, ShopItem, ShopRod, Merlin)
            end)
        end
        if InitAutos then
            pcall(function()
                InitAutos(nil, AutosQuest, AutosJack, AutosFavorit, AutosAppraise, AutoAppraise, AutoEnchant, nil, AutosSection, AuraSection, nil, nil)
            end)
        end
        pcall(function()
            local shadyStatus = AutosQuest:AddParagraph({
                Title = "Shady Rod Requirements Status",
                Content = "Inactive"
            })
            local function updateParagraph(para, text)
                if not para then return end
                local ok = pcall(function()
                    para:Set({ Title = "Shady Rod Requirements Status", Content = text })
                end)
                if not ok then
                    pcall(function() para:Set(text) end)
                    pcall(function() para:SetText(text) end)
                    pcall(function() para:SetContent(text) end)
                    pcall(function()
                        if typeof(para) == "table" and para.Instance then
                            para = para.Instance
                        end
                        if typeof(para) == "Instance" then
                            local desc = para:FindFirstChild("ParagraphContent") or para:FindFirstChildWhichIsA("TextLabel")
                            if desc then desc.Text = text end
                        end
                    end)
                end
            end
            if AutoQuestShady then
                AutoQuestShady.StatusCallback = function(statusString)
                    updateParagraph(shadyStatus, statusString)
                end
                task.spawn(function()
                    task.wait(1)
                    pcall(function()
                        if AutoQuestShady.RefreshStatus then
                            AutoQuestShady.RefreshStatus("Siap (aktifkan toggle untuk mulai)")
                        end
                    end)
                end)
            end
            AutosQuest:AddToggle({
                Title = "Auto Quest Shady Rod",
                Default = _G.Config.AutoQuestShady or false,
                Callback = function(value)
                    if AutoQuestShady then
                        AutoQuestShady(value)
                    end
                end
            })
            local bazaarStatus = AutosQuest:AddParagraph({
                Title = "Bazaar Quest Status",
                Content = "Checking..."
            })
            local function updateBazaarParagraph(text)
                if not bazaarStatus then return end
                local ok = pcall(function()
                    bazaarStatus:Set({ Title = "Bazaar Quest Status", Content = text })
                end)
                if not ok then
                    pcall(function() bazaarStatus:Set(text) end)
                    pcall(function() bazaarStatus:SetText(text) end)
                    pcall(function() bazaarStatus:SetContent(text) end)
                    pcall(function()
                        local para = bazaarStatus
                        if typeof(para) == "table" and para.Instance then para = para.Instance end
                        if typeof(para) == "Instance" then
                            local desc = para:FindFirstChild("ParagraphContent") or para:FindFirstChildWhichIsA("TextLabel")
                            if desc then desc.Text = text end
                        end
                    end)
                end
            end
            if AutoQuestShady then
                AutoQuestShady.BazaarCallback = function(statusStr)
                    updateBazaarParagraph(statusStr)
                end
                pcall(function()
                    if AutoQuestShady.GetBazaarStatus then
                        local bs = AutoQuestShady.GetBazaarStatus()
                        if bs then
                            local str = ""
                            if bs.BazaarUnlocked then
                                str = "✓ Bazaar Terbuka\n✓ Quest 1 (3 Figur) SELESAI\n✓ Quest 2 (Lighthouse) SELESAI"
                            elseif bs.FindFiguresDone then
                                str = "✓ Quest 1 (3 Figur) SELESAI\n✗ Quest 2 (Lighthouse) BELUM"
                            else
                                str = "✗ Quest 1 (3 Figur) BELUM\n✗ Quest 2 (Lighthouse) BELUM"
                            end
                            updateBazaarParagraph(str)
                        end
                    end
                end)
            end
            AutosQuest:AddButton({
                Title = "Force Open Bazaar Hatch",
                Callback = function()
                    pcall(function()
                        if AutoQuestShady and AutoQuestShady.ForceOpenHatch then
                            local opened = AutoQuestShady.ForceOpenHatch()
                            updateBazaarParagraph(opened
                                and "✓ Hatch berhasil dibuka (client-side)!"
                                or  "✗ Hatch tidak ditemukan (LighthouseHatch tag)")
                        end
                    end)
                end
            })
            AutosQuest:AddButton({
                Title = "Teleport ke Shady Fishing Spot",
                Callback = function()
                    pcall(function()
                        local char = game.Players.LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = CFrame.new(-1067.4, 130.8, -1163.3)
                        end
                    end)
                end
            })
        end)
        if InitAreaTP then
            pcall(function()
                InitAreaTP(Main, SAVEPOSTION, NPCSection, BallonSection)
            end)
        end
    end
    ExclusiveSection:AddButton({
        Title = "Save Config",
        Callback = function()
            local HttpService = game:GetService("HttpService")
            pcall(function()
                writefile("ShieldTeamConfig.json", HttpService:JSONEncode(_G.Config))
            end)
        end
    })
    ExclusiveSection:AddToggle({
        Title = "Anti AFK",
        Default = (_G.Config and _G.Config.AntiAFK) ~= false,
        Callback = function(value)
            _G.Config.AntiAFK = value
            local LocalPlayer = game:GetService("Players").LocalPlayer
            getgenv().disabledAfkConnections = getgenv().disabledAfkConnections or {}
            if value then
                task.spawn(function()
                    for i = 1, 30 do
                        local found = false
                        pcall(function()
                            local conns = getconnections(LocalPlayer.Idled)
                            if #conns > 0 then
                                for _, conn in pairs(conns) do
                                    if conn.Disable then
                                        conn:Disable()
                                        table.insert(getgenv().disabledAfkConnections, conn)
                                    elseif conn.Disconnect then
                                        conn:Disconnect()
                                        table.insert(getgenv().disabledAfkConnections, conn)
                                    end
                                end
                                found = true
                            end
                        end)
                        if found then break end
                        task.wait(1)
                    end
                end)
            else
                for _, conn in ipairs(getgenv().disabledAfkConnections) do
                    pcall(function()
                        if conn.Enable then conn:Enable() end
                    end)
                end
                getgenv().disabledAfkConnections = {}
            end
        end
    })
    MiscPlayerSection:AddSlider({
        Title = "WalkSpeed",
        Min = 16,
        Max = 200,
        Default = 16,
        Callback = function(value)
            if WalkSpeed then WalkSpeed(value) end
        end
    })
    local freezeConn = nil
    local function SetFreezeCharacter(enabled)
        _G.Config.FreezeCharacter = enabled
        if enabled then
            if not freezeConn then
                freezeConn = game:GetService("RunService").Heartbeat:Connect(function()
                    if _G.Config and _G.Config.FreezeCharacter then
                        local char = game.Players.LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Anchored = true
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        end
                    end
                end)
            end
        else
            if freezeConn then
                freezeConn:Disconnect()
                freezeConn = nil
            end
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = false
            end
        end
    end
    if not getgenv()._freezeCharAddedConn then
        getgenv()._freezeCharAddedConn = game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
            if _G.Config and _G.Config.FreezeCharacter then
                local hrp = char:WaitForChild("HumanoidRootPart", 5)
                if hrp then
                    hrp.Anchored = true
                end
            end
        end)
    end
    local _tInfJump = MiscPlayerSection:AddToggle({
        Title = "Infinity Jump",
        Default = _G.Config.InfinityJump or false,
        Callback = function(value)
            _G.Config.InfinityJump = value
            if WalkSpeed and WalkSpeed.SetInfJump then
                WalkSpeed.SetInfJump(value)
            end
        end
    })
    _regToggle(_tInfJump, "InfinityJump", function(v)
        _G.Config.InfinityJump = v
        if WalkSpeed and WalkSpeed.SetInfJump then
            WalkSpeed.SetInfJump(v)
        end
    end)
    local _tFreeze = MiscPlayerSection:AddToggle({
        Title = "Freeze Character",
        Default = _G.Config.FreezeCharacter or false,
        Callback = function(value)
            SetFreezeCharacter(value)
        end
    })
    _regToggle(_tFreeze, "FreezeCharacter", function(v)
        SetFreezeCharacter(v)
    end)
    MiscSection:AddSlider({
        Title = "WalkSpeed",
        Min = 16,
        Max = 200,
        Default = 16,
        Callback = function(value)
            local ws = getMod("WalkSpeed") or WalkSpeed
            if ws and ws.SetSpeed then
                ws.SetSpeed(value > 16, value)
            elseif ws then
                ws(value)
            end
        end
    })
    MiscSection:AddToggle({
        Title = "Infinite Jump",
        Default = false,
        Callback = function(value)
            local ws = getMod("WalkSpeed") or WalkSpeed
            if ws and ws.SetInfJump then
                ws.SetInfJump(value)
            end
        end
    })
    MiscSection:AddToggle({
        Title = "No Clip",
        Default = false,
        Callback = function(value)
            local ws = getMod("WalkSpeed") or WalkSpeed
            if ws and ws.SetNoClip then
                ws.SetNoClip(value)
            end
        end
    })
    MiscSection:AddToggle({
        Title = "Disable Oxygen",
        Default = false,
        Callback = function(value)
            if DisableOxygen then DisableOxygen(value) end
        end
    })
    MiscSection:AddToggle({
        Title = "Remove Fog",
        Default = _G.Config.RemoveFog or false,
        Callback = function(value)
            _G.Config.RemoveFog = value
            local MiscFeatures = getMod("MiscFeatures")
            if MiscFeatures and MiscFeatures.SetRemoveFog then
                MiscFeatures.SetRemoveFog(value)
            end
        end
    })
    MiscSection:AddToggle({
        Title = "Boost FPS / Optimize",
        Default = _G.Config.BoostFPS or false,
        Callback = function(value)
            _G.Config.BoostFPS = value
            local MiscFeatures = getMod("MiscFeatures")
            if MiscFeatures and MiscFeatures.SetBoostFPS then
                MiscFeatures.SetBoostFPS(value)
            end
        end
    })
    MiscSection:AddToggle({
        Title = "Black Screen (AFK Saver)",
        Default = _G.Config.BlackScreen or false,
        Callback = function(value)
            _G.Config.BlackScreen = value
            local MiscFeatures = getMod("MiscFeatures")
            if MiscFeatures and MiscFeatures.SetScreenSaver then
                MiscFeatures.SetScreenSaver(value, "Black")
            end
        end
    })
    MiscSection:AddToggle({
        Title = "White Screen (AFK Saver)",
        Default = _G.Config.WhiteScreen or false,
        Callback = function(value)
            _G.Config.WhiteScreen = value
            local MiscFeatures = getMod("MiscFeatures")
            if MiscFeatures and MiscFeatures.SetScreenSaver then
                MiscFeatures.SetScreenSaver(value, "White")
            end
        end
    })
    MiscSection:AddToggle({
        Title = "Low Graphics (Level 1)",
        Default = _G.Config.LowGraphics or false,
        Callback = function(value)
            _G.Config.LowGraphics = value
            pcall(function()
                local userSettings = UserSettings():GetService("UserGameSettings")
                if value then
                    userSettings.SavedQualityLevel = Enum.SavedQualityLevel.Level01
                else
                    userSettings.SavedQualityLevel = Enum.SavedQualityLevel.Automatic
                end
            end)
            pcall(function()
                if value then
                    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                else
                    settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
                end
            end)
        end
    })
    EspCharacterSection:AddToggle({
        Title = "ESP Player",
        Default = false,
        Callback = function(value)
            local espMod = getMod("ESP") or ESP
            if espMod then espMod("Players", value) end
        end
    })
    EspCharacterSection:AddToggle({
        Title = "ESP NPC",
        Default = false,
        Callback = function(value)
            local espMod = getMod("ESP") or ESP
            if espMod then espMod("NPCs", value) end
        end
    })
    EspCharacterSection:AddToggle({
        Title = "ESP Hunt / Events (Megalodon, Kraken, etc.)",
        Default = false,
        Callback = function(value)
            local espMod = getMod("ESP") or ESP
            if espMod then espMod("Hunts", value) end
        end
    })
    EspCharacterSection:AddToggle({
        Title = "ESP Roaming Fish",
        Default = false,
        Callback = function(value)
            local espMod = getMod("ESP") or ESP
            if espMod then espMod("Roaming", value) end
        end
    })
    CreditsSection:AddParagraph({
        Title = "ShieldTeam || NewFish5",
        Content = "Full GUI Layout Re-added.\nSemua Tab & Section sudah dibuatkan.\nSilahkan tambahkan Toggle lebih lanjut jika perlu!"
    })
end
setupGUI()
print("[NewFish5] GUI Loaded Successfully from ReplicatedStorage!")
task.spawn(function()
    task.wait(1)
    if _G.Config then
        if _G.Config['Farm Fish'] then
            _G.Config.AutoCast = true
            _G.Config.AutoReel = true
            _G.Config.AutoShake = true
            _G.Config.InstantCast = true
        end
        if InstantBobber and _G.Config.InstantCast then InstantBobber(true) end
        if AutoCast and _G.Config.AutoCast then AutoCast(true) end
        if AutoReel and _G.Config.AutoReel then AutoReel(true) end
        if AutoShake and _G.Config.AutoShake then AutoShake(true) end
        if AutoSell and _G.Config.AutoSell then AutoSell(true) end
        if MiscFishing and MiscFishing.AutoEquipRod and _G.Config.isEquipRpd then MiscFishing.AutoEquipRod(true) end
        if _G.Config.LowGraphics then
            pcall(function()
                UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualityLevel.Level01
            end)
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
        end
    end
end)