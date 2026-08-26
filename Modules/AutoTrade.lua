if getgenv().__ShielDTrade_Loaded then
    if getgenv().__ShielDTrade_GUI and typeof(getgenv().__ShielDTrade_GUI) == "Instance" then
        pcall(function() getgenv().__ShielDTrade_GUI:Destroy() end)
    end
end
getgenv().__ShielDTrade_Loaded = true

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function getParentContainer()
    local parent = nil
    if typeof(gethui) == "function" then
        pcall(function() parent = gethui() end)
    end
    if not parent then
        local coreGui = game:GetService("CoreGui")
        local canParentToCoreGui = pcall(function()
            local test = Instance.new("Folder")
            test.Parent = coreGui
            test:Destroy()
        end)
        if canParentToCoreGui then
            parent = coreGui
        else
            parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 2)
        end
    end
    return parent or LocalPlayer:WaitForChild("PlayerGui")
end

local function findChildCaseInsensitive(parent, name)
    if not parent then return nil end
    local exact = parent:FindFirstChild(name)
    if exact then return exact end
    local lowerName = name:lower()
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name:lower() == lowerName then
            return child
        end
    end
    return nil
end

local function safeRequire(parentObj, ...)
    local curr = parentObj
    for _, name in ipairs({...}) do
        if not curr then return nil end
        curr = findChildCaseInsensitive(curr, name)
    end
    if curr and curr:IsA("ModuleScript") then
        local ok, mod = pcall(require, curr)
        if ok then return mod end
    end
    return nil
end

local Net = safeRequire(ReplicatedStorage, "packages", "Net")
local function getRemoteEvent(name)
    if Net and typeof(Net.RemoteEvent) == "function" then
        local ok, remote = pcall(function() return Net:RemoteEvent(name) end)
        if ok and remote then return remote end
        local ok2, remote2 = pcall(function() return Net:RemoteEvent("RE/" .. name) end)
        if ok2 and remote2 then return remote2 end
    end
    local netFolder = findChildCaseInsensitive(ReplicatedStorage, "packages")
    netFolder = netFolder and findChildCaseInsensitive(netFolder, "Net")
    if netFolder then
        local r = findChildCaseInsensitive(netFolder, name) or findChildCaseInsensitive(netFolder, "RE/" .. name)
        if r and r:IsA("RemoteEvent") then return r end
    end
    local events = findChildCaseInsensitive(ReplicatedStorage, "events")
    if events then
        local r = findChildCaseInsensitive(events, name)
        if r and r:IsA("RemoteEvent") then return r end
    end
    return nil
end

local DataController = safeRequire(ReplicatedStorage, "client", "legacyControllers", "DataController")
local legacyLocalPlayerData = safeRequire(ReplicatedStorage, "client", "modules", "legacyLocalPlayerData")
local library = safeRequire(ReplicatedStorage, "shared", "modules", "library")
local fishing = safeRequire(ReplicatedStorage, "shared", "modules", "fishing")

local function getDataController()
    if DataController then return DataController end
    DataController = safeRequire(ReplicatedStorage, "client", "legacyControllers", "DataController")
    return DataController
end

local function getLibrary()
    if library then return library end
    library = safeRequire(ReplicatedStorage, "shared", "modules", "library")
    return library
end

local function sanitizePrice(p)
    if not p then return 0 end
    local num = tonumber(p)
    if not num then return 0 end
    if num ~= num or num == math.huge or num == -math.huge or tostring(num):lower():find("inf") or tostring(num):lower():find("nan") then
        return 0
    end
    if num < 0 then return 0 end
    return math.floor(num)
end

local function formatNumber(n)
    local num = tonumber(n) or 0
    if num >= 1e15 then
        return string.format("%.2fQd", num / 1e15)
    elseif num >= 1e12 then
        return string.format("%.2fT", num / 1e12)
    elseif num >= 1e9 then
        return string.format("%.2fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.2fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.2fK", num / 1e3)
    else
        local val = math.floor(num)
        local str = tostring(val)
        local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
        if formatted:sub(1, 1) == "," then
            formatted = formatted:sub(2)
        end
        return formatted
    end
end

local function getGameFishingModule()
    local ok, mod = pcall(function()
        return require(game:GetService("ReplicatedStorage").shared.modules.fishing)
    end)
    if ok and mod then return mod end
    return fishing
end

local function getGameLibraryModule()
    local ok, mod = pcall(function()
        return require(game:GetService("ReplicatedStorage").shared.modules.library)
    end)
    if ok and mod then return mod end
    return library
end

local function getInventoryData()
    local dc = getDataController()
    if not dc then return nil end
    local inv = nil
    pcall(function()
        if dc.InventoryReplicator then
            pcall(function() dc.InventoryReplicator:WaitForLoaded() end)
            inv = dc.InventoryReplicator:Index({"Inventory"})
        end
        if not inv and typeof(dc.fetch) == "function" then
            inv = dc.fetch("Inventory")
        end
    end)
    return inv
end

local function getItemRealPrice(itemData)
    if not itemData then return 0 end
    local name = tostring(itemData.name or "")

    if _G.CustomItemPrices and type(_G.CustomItemPrices) == "table" then
        if _G.CustomItemPrices[name] and tonumber(_G.CustomItemPrices[name]) then
            return sanitizePrice(_G.CustomItemPrices[name])
        end
    end

    local fishingMod = getGameFishingModule()
    if fishingMod then
        local isNonFish = name:find("Relic") or name:find("Driftwood") or name:find("Amulet") or name:find("Basket")
        if not isNonFish then
            local okSell, sellVal = pcall(function()
                return fishingMod:SellFish(LocalPlayer, itemData, true)
            end)
            if okSell and tonumber(sellVal) and tonumber(sellVal) > 0 then
                return sanitizePrice(sellVal)
            end
        end

        local okCalc, calcVal = pcall(function()
            if typeof(fishingMod.CalculatePrice) == "function" then
                return fishingMod:CalculatePrice(itemData)
            elseif typeof(fishingMod.CalculateFishPrice) == "function" then
                return fishingMod:CalculateFishPrice(itemData)
            end
        end)
        if okCalc and tonumber(calcVal) and tonumber(calcVal) > 0 then
            return sanitizePrice(calcVal)
        end
    end

    local libMod = getGameLibraryModule()
    if libMod then
        for _, tblName in ipairs({"items", "relics", "baits", "rods", "equipment", "crates"}) do
            local tbl = libMod[tblName]
            if type(tbl) == "table" and tbl[name] then
                local info = tbl[name]
                local p = info.Price or info.price or info.SellPrice or info.sellPrice or info.Worth or info.Cost
                if p and tonumber(p) and tonumber(p) > 0 then
                    return sanitizePrice(p)
                end
            end
        end

        if libMod.fish and libMod.fish[name] then
            local fishInfo = libMod.fish[name]
            local basePrice = tonumber(fishInfo.Price) or 50

            if itemData.sub and itemData.sub.Weight and fishInfo.WeightPool and fishInfo.WeightPool[2] and fishInfo.WeightPool[2] > 0 then
                basePrice = math.ceil(basePrice / fishInfo.WeightPool[2] * itemData.sub.Weight * 10)
            end

            if itemData.sub then
                if itemData.sub.Shiny then basePrice = math.floor(basePrice * 1.85) end
                if itemData.sub.Sparkling then basePrice = math.floor(basePrice * 1.85) end
                if itemData.sub.Mutation and libMod.mutations and libMod.mutations[itemData.sub.Mutation] then
                    local mutInfo = libMod.mutations[itemData.sub.Mutation]
                    local mult = tonumber(mutInfo.PriceMultiply or mutInfo.Multiplier) or 1
                    basePrice = math.floor(basePrice * mult)
                end
            end
            return sanitizePrice(basePrice)
        end
    end

    if itemData.Price and tonumber(itemData.Price) and tonumber(itemData.Price) > 0 then
        return sanitizePrice(itemData.Price)
    end
    if itemData.price and tonumber(itemData.price) and tonumber(itemData.price) > 0 then
        return sanitizePrice(itemData.price)
    end
    if itemData.Worth and tonumber(itemData.Worth) and tonumber(itemData.Worth) > 0 then
        return sanitizePrice(itemData.Worth)
    end
    if itemData.sub then
        if itemData.sub.Price and tonumber(itemData.sub.Price) and tonumber(itemData.sub.Price) > 0 then
            return sanitizePrice(itemData.sub.Price)
        end
        if itemData.sub.Worth and tonumber(itemData.sub.Worth) and tonumber(itemData.sub.Worth) > 0 then
            return sanitizePrice(itemData.sub.Worth)
        end
    end

    local knownPrices = _G.KnownItemPrices or {
        ["Enchant Relic"]      = 11000,
        ["Twisted Relic"]      = 35000,
        ["Exalted Relic"]      = 75000,
        ["Abyssal Relic"]      = 150000,
        ["Cosmic Relic"]       = 250000,
        ["Sovereign Relic"]    = 250000,
        ["Egg Basket"]         = 15000,
        ["Driftwood"]          = 5,
        ["Amulet"]             = 2500,
        ["Super Flute"]        = 5000,
        ["Merlin's Rod"]       = 50000,
        ["Fortune Rod"]        = 15000,
        ["Magical Conch"]      = 2500,
        ["Glider"]             = 1000,
        ["GPS"]                = 100,
    }
    if knownPrices[name] then
        return sanitizePrice(knownPrices[name])
    end

    return 0
end

local isTradeActive = false
local liveTradeData = {
    MyTotal = 0,
    MyItems = 0,
    TheirTotal = 0,
    TheirItems = 0,
    Active = false
}

local updateActiveTradeDisplay

local RemoteUpdateOffered = getRemoteEvent("Trade/UpdateOfferedItems")
local RemoteAddItem       = getRemoteEvent("Trade/AddItem")
local RemoteRemoveItem    = getRemoteEvent("Trade/RemoveItem")
local RemoteTradeStarted  = getRemoteEvent("Trade/TradeStarted")
local RemoteTradeEnded    = getRemoteEvent("Trade/TradeEnded")
local RemoteCancelTrade   = getRemoteEvent("Trade/CancelTrade")
local RemoteSetReady      = getRemoteEvent("Trade/SetReady")

local function fireRemoteAddItem(itemId, stack)
    if not RemoteAddItem then
        RemoteAddItem = getRemoteEvent("Trade/AddItem")
    end
    if RemoteAddItem then
        pcall(function()
            RemoteAddItem:FireServer("Item", itemId, stack or 1)
        end)
    else
        warn("[Trade] RemoteAddItem tidak ditemukan!")
    end
end

local function calculateOfferDictValue(offerDict)
    local total = 0
    local count = 0
    local inv = getInventoryData() or {}
    local dc = getDataController()

    if type(offerDict) == "table" then
        for key, itemObj in pairs(offerDict) do
            if type(itemObj) == "table" then
                local itemType = itemObj.type or "Item"
                local itemData = itemObj.data
                local stack = tonumber(itemObj.stack) or 1

                if type(itemData) == "string" then
                    itemData = (inv and inv[itemData]) or (dc and typeof(dc.getItem) == "function" and dc.getItem(itemData))
                end

                if not itemData or type(itemData) ~= "table" then

                    local parts = tostring(key):split("\254\254")
                    local uuid = parts[2] or parts[1]
                    if uuid then
                        itemData = (inv and inv[uuid]) or (dc and typeof(dc.getItem) == "function" and dc.getItem(uuid))
                    end
                end

                if itemType == "Currency" then
                    local currencyAmt = tonumber(itemObj.data or itemObj.stack) or 0
                    total = total + currencyAmt
                elseif itemData and type(itemData) == "table" then
                    local price = getItemRealPrice(itemData)
                    total = total + (price * stack)
                    count = count + stack
                elseif itemObj.name or itemObj.Name then
                    local price = getItemRealPrice(itemObj)
                    total = total + (price * stack)
                    count = count + stack
                else
                    count = count + stack
                end
            end
        end
    end
    return sanitizePrice(total), count
end

local function scanTradeGuiLive()
    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return end

    local tradeGui = pGui:FindFirstChild("hud") and pGui.hud:FindFirstChild("safezone") and pGui.hud.safezone:FindFirstChild("Trade")
    if not tradeGui or not tradeGui.Visible then
        for _, g in ipairs(pGui:GetChildren()) do
            if g:IsA("ScreenGui") and (g.Name:lower():find("trade") or g:FindFirstChild("PlayerOffer", true)) then
                local po = g:FindFirstChild("PlayerOffer", true)
                if po and po.Parent and po.Parent.Visible then
                    tradeGui = po.Parent
                    break
                end
            end
        end
    end

    if tradeGui and tradeGui.Visible then
        isTradeActive = true
        liveTradeData.Active = true

        local playerOfferFrame = tradeGui:FindFirstChild("PlayerOffer", true)
        local otherOfferFrame = tradeGui:FindFirstChild("OtherOffer", true)
        local inv = getInventoryData() or {}

        if playerOfferFrame then
            local scroll = playerOfferFrame:FindFirstChild("ScrollingFrame", true)
            if scroll then
                local myTotal = 0
                local myCount = 0
                for _, child in ipairs(scroll:GetChildren()) do
                    if child:IsA("GuiObject") and child.Visible and not child.Name:find("^_") and child.Name ~= "UIListLayout" and child.Name ~= "UIGridLayout" then
                        local itemId = child:GetAttribute("itemId")
                        local itemData = (itemId and inv[itemId])
                        local stack = 1
                        local stackLbl = child:FindFirstChild("Stack", true) or child:FindFirstChild("Amount", true)
                        if stackLbl and stackLbl:IsA("TextLabel") then
                            local num = stackLbl.Text:match("%d+")
                            if num then stack = tonumber(num) or 1 end
                        end

                        if itemData then
                            myTotal = myTotal + (getItemRealPrice(itemData) * stack)
                            myCount = myCount + stack
                        else
                            local nameLbl = child:FindFirstChild("Label", true) or child:FindFirstChild("Name", true) or child:FindFirstChild("Title", true)
                            local itemName = (nameLbl and nameLbl.Text) or child.Name
                            local p = getItemRealPrice({ name = itemName })
                            myTotal = myTotal + (p * stack)
                            myCount = myCount + stack
                        end
                    end
                end
                if myCount > 0 then
                    liveTradeData.MyTotal = myTotal
                    liveTradeData.MyItems = myCount
                end
            end
        end

        if otherOfferFrame then
            local scroll = otherOfferFrame:FindFirstChild("ScrollingFrame", true)
            if scroll then
                local theirTotal = 0
                local theirCount = 0
                for _, child in ipairs(scroll:GetChildren()) do
                    if child:IsA("GuiObject") and child.Visible and not child.Name:find("^_") and child.Name ~= "UIListLayout" and child.Name ~= "UIGridLayout" then
                        local itemId = child:GetAttribute("itemId")
                        local itemData = (itemId and inv[itemId])
                        local stack = 1
                        local stackLbl = child:FindFirstChild("Stack", true) or child:FindFirstChild("Amount", true)
                        if stackLbl and stackLbl:IsA("TextLabel") then
                            local num = stackLbl.Text:match("%d+")
                            if num then stack = tonumber(num) or 1 end
                        end

                        if itemData then
                            theirTotal = theirTotal + (getItemRealPrice(itemData) * stack)
                            theirCount = theirCount + stack
                        else
                            local nameLbl = child:FindFirstChild("Label", true) or child:FindFirstChild("Name", true) or child:FindFirstChild("Title", true)
                            local itemName = (nameLbl and nameLbl.Text) or child.Name
                            local p = getItemRealPrice({ name = itemName })
                            theirTotal = theirTotal + (p * stack)
                            theirCount = theirCount + stack
                        end
                    end
                end
                if theirCount > 0 then
                    liveTradeData.TheirTotal = theirTotal
                    liveTradeData.TheirItems = theirCount
                end
            end
        end
    end
end

if RemoteTradeStarted then
    RemoteTradeStarted.OnClientEvent:Connect(function()
        isTradeActive = true
        liveTradeData.Active = true

        liveTradeData.MyTotal = 0
        liveTradeData.MyItems = 0
        liveTradeData.TheirTotal = 0
        liveTradeData.TheirItems = 0
        if updateActiveTradeDisplay then updateActiveTradeDisplay() end
    end)
end

if RemoteTradeEnded then
    RemoteTradeEnded.OnClientEvent:Connect(function()
        isTradeActive = false
        liveTradeData.Active = false
        liveTradeData.MyTotal = 0
        liveTradeData.MyItems = 0
        liveTradeData.TheirTotal = 0
        liveTradeData.TheirItems = 0
        if updateActiveTradeDisplay then updateActiveTradeDisplay() end
    end)
end

if RemoteCancelTrade then
    RemoteCancelTrade.OnClientEvent:Connect(function()
        isTradeActive = false
        liveTradeData.Active = false
        liveTradeData.MyTotal = 0
        liveTradeData.MyItems = 0
        liveTradeData.TheirTotal = 0
        liveTradeData.TheirItems = 0
        if updateActiveTradeDisplay then updateActiveTradeDisplay() end
    end)
end

local debugLogs = {}
local debugLogLbl = nil

local function addDebugLog(msg)
    local ts = os.date("%H:%M:%S")
    local line = string.format("[%s] %s", ts, msg)
    table.insert(debugLogs, line)
    if #debugLogs > 30 then table.remove(debugLogs, 1) end
    if debugLogLbl then
        debugLogLbl.Text = table.concat(debugLogs, "\n")

        pcall(function()
            local scroll = debugLogLbl.Parent
            if scroll and scroll:IsA("ScrollingFrame") then
                scroll.CanvasPosition = Vector2.new(0, math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y))
            end
        end)
    end
end

local function processOfferData(sessionData)
    if type(sessionData) ~= "table" then
        addDebugLog("ERROR: sessionData bukan table, type=" .. type(sessionData))
        return
    end

    local keys = {}
    for k in pairs(sessionData) do table.insert(keys, tostring(k)) end
    addDebugLog("sessionData keys: " .. table.concat(keys, ", "))

    if type(sessionData.offer) ~= "table" then
        addDebugLog("ERROR: offer bukan table, type=" .. type(sessionData.offer))
        return
    end

    isTradeActive = true
    liveTradeData.Active = true

    local myTotal = 0
    local myCount = 0
    local theirTotal = 0
    local theirCount = 0

    for playerName, playerOffers in pairs(sessionData.offer) do

        local offerCount = 0
        local offerKeys = {}
        if type(playerOffers) == "table" then
            for k, v in pairs(playerOffers) do
                offerCount = offerCount + 1
                table.insert(offerKeys, tostring(k):sub(1, 20))
            end
        end
        addDebugLog("Player: " .. tostring(playerName) .. " | items=" .. offerCount
            .. " | keys=" .. table.concat(offerKeys, ";"):sub(1, 60))
        if type(playerOffers) == "table" then
            local total = 0
            local count = 0
            for key, itemObj in pairs(playerOffers) do
                if type(itemObj) == "table" then
                    local stack = tonumber(itemObj.stack) or 1
                    local itemType = tostring(itemObj.type or "Item")
                    local itemData = itemObj.data

                    local keyId = tostring(key):match("\xFE\xFE(.+)$") or tostring(key)

                    if itemType == "Currency" then
                        local amt = tonumber(itemData) or 0
                        total = total + amt
                        addDebugLog("  Currency: " .. tostring(amt))
                    elseif type(itemData) == "table" then

                        local price = getItemRealPrice(itemData)
                        total = total + (price * stack)
                        count = count + stack
                        addDebugLog(string.format("  TABLE | name=%s | x%d | C$%s",
                            tostring(itemData.name), stack, formatNumber(price)))
                    else

                        local inv = getInventoryData() or {}
                        local dc = getDataController()
                        local resolved = nil

                        resolved = inv[keyId]
                        if resolved then
                            addDebugLog("  Found by keyId=" .. tostring(keyId):sub(1,15))
                        end

                        if not resolved and type(itemData) == "string" then
                            resolved = inv[itemData]
                            if resolved then addDebugLog("  Found by itemData=" .. tostring(itemData):sub(1,15)) end
                        end

                        if not resolved and dc then
                            pcall(function()
                                if typeof(dc.getItem) == "function" then
                                    resolved = dc.getItem(keyId)
                                elseif typeof(dc.getItemFromLink) == "function" then
                                    resolved = dc.getItemFromLink(keyId)
                                end
                            end)
                            if resolved then addDebugLog("  Found by dc.getItem") end
                        end

                        if not resolved then
                            for _, v in pairs(inv) do
                                if type(v) == "table" and tostring(v.name) == keyId then
                                    resolved = v
                                    addDebugLog("  Found by name scan=" .. keyId:sub(1,15))
                                    break
                                end
                            end
                        end

                        if resolved and type(resolved) == "table" then
                            local price = getItemRealPrice(resolved)
                            total = total + (price * stack)
                            count = count + stack
                            addDebugLog(string.format("  %s | name=%s | x%d | C$%s",
                                itemType, tostring(resolved.name), stack, formatNumber(price)))
                        else
                            addDebugLog(string.format("  %s | keyId=%s | data=%s | NOT FOUND",
                                itemType, tostring(keyId):sub(1,15), type(itemData)))
                        end
                    end
                else
                    addDebugLog("  key=" .. tostring(key):sub(1,20) .. " | itemObj=" .. type(itemObj))
                end
            end

            if tostring(playerName) == LocalPlayer.Name then
                myTotal = total
                myCount = count
            else
                theirTotal = total
                theirCount = count
            end
        end
    end

    liveTradeData.MyTotal = sanitizePrice(myTotal)
    liveTradeData.MyItems = myCount
    liveTradeData.TheirTotal = sanitizePrice(theirTotal)
    liveTradeData.TheirItems = theirCount
    addDebugLog(string.format("RESULT → Me:C$%s(%d) Partner:C$%s(%d)",
        formatNumber(myTotal), myCount, formatNumber(theirTotal), theirCount))

    if updateActiveTradeDisplay then updateActiveTradeDisplay() end
end

task.spawn(function()
    task.wait(1)
    local hooked = false

    if Net then
        pcall(function()
            local remote = Net:RemoteEvent("Trade/UpdateOfferedItems")
            if remote and remote.OnClientEvent then
                remote.OnClientEvent:Connect(function(sessionData)
                    addDebugLog("EVENT FIRED (Net method)")
                    processOfferData(sessionData)
                end)
                hooked = true
                addDebugLog("Hook OK via Net:RemoteEvent")
            end
        end)
    end

    if not hooked then
        addDebugLog("Mencari event Trade/UpdateOfferedItems...")
        local function scanForRemote(parent, depth)
            if depth > 6 then return nil end
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("RemoteEvent") and (child.Name == "Trade/UpdateOfferedItems" or child.Name == "UpdateOfferedItems") then
                    return child
                end
                local found = scanForRemote(child, depth + 1)
                if found then return found end
            end
            return nil
        end
        local remote = scanForRemote(ReplicatedStorage, 0)
        if remote then
            remote.OnClientEvent:Connect(function(sessionData)
                addDebugLog("EVENT FIRED (scan method)")
                processOfferData(sessionData)
            end)
            hooked = true
            addDebugLog("Hook OK via scan: " .. remote:GetFullName())
        end
    end

    if not hooked and typeof(hookfunction) == "function" then
        addDebugLog("Mencoba hookfunction...")
        pcall(function()
            local origFireClient = game.ReplicatedStorage.__namecall

        end)
    end

    if not hooked then
        addDebugLog("GAGAL hook event! Mencari via getconnections...")

        if typeof(getconnections) == "function" then
            local function tryConnect(remote)
                local conns = getconnections(remote.OnClientEvent)
                addDebugLog("Found " .. #conns .. " connections on " .. remote.Name)
            end
            if RemoteUpdateOffered then tryConnect(RemoteUpdateOffered) end
        else
            addDebugLog("getconnections not available")
        end

        addDebugLog("Using GUI scan fallback")
        task.spawn(function()
            local lastCount = 0
            while true do
                task.wait(0.5)
                pcall(function()
                    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                    if not pGui then return end

                    local tradeFrame = nil
                    local hudSG = pGui:FindFirstChild("hud")
                    if hudSG then
                        local safezone = hudSG:FindFirstChild("safezone")
                        if safezone then
                            tradeFrame = safezone:FindFirstChild("Trade")
                        end
                    end

                    if tradeFrame and tradeFrame.Visible then
                        isTradeActive = true
                        liveTradeData.Active = true

                        local playerOffer = tradeFrame:FindFirstChild("PlayerOffer")
                        local otherOffer = tradeFrame:FindFirstChild("OtherOffer")
                        local inv = getInventoryData() or {}

                        local myTotal = 0
                        local myCount = 0
                        local theirTotal = 0
                        local theirCount = 0

                        if playerOffer then
                            local list = playerOffer:FindFirstChild("List")
                            local scroll = list and list:FindFirstChild("ScrollingFrame")
                            if scroll then
                                for _, item in ipairs(scroll:GetChildren()) do
                                    if item:IsA("GuiObject") and item.Visible and
                                       not item.Name:find("^_") and item.Name ~= "UIListLayout" then
                                        local itemId = item:GetAttribute("itemId")
                                        local itemData = itemId and inv[itemId]
                                        local stack = 1

                                        local stackLbl = item:FindFirstChild("Stack", true)
                                        if stackLbl and stackLbl:IsA("TextLabel") then
                                            local n = stackLbl.Text:match("(%d+)")
                                            if n then stack = tonumber(n) or 1 end
                                        end
                                        if itemData then
                                            myTotal = myTotal + getItemRealPrice(itemData) * stack
                                            myCount = myCount + stack
                                        end
                                    end
                                end
                            end
                        end

                        if otherOffer then
                            local list = otherOffer:FindFirstChild("List")
                            local scroll = list and list:FindFirstChild("ScrollingFrame")
                            if scroll then
                                for _, item in ipairs(scroll:GetChildren()) do
                                    if item:IsA("GuiObject") and item.Visible and
                                       not item.Name:find("^_") and item.Name ~= "UIListLayout" then
                                        local itemId = item:GetAttribute("itemId")
                                        local itemData = itemId and inv[itemId]
                                        local stack = 1
                                        local stackLbl = item:FindFirstChild("Stack", true)
                                        if stackLbl and stackLbl:IsA("TextLabel") then
                                            local n = stackLbl.Text:match("(%d+)")
                                            if n then stack = tonumber(n) or 1 end
                                        end
                                        if itemData then
                                            theirTotal = theirTotal + getItemRealPrice(itemData) * stack
                                            theirCount = theirCount + stack
                                        end
                                    end
                                end
                            end
                        end

                        local newCount = myCount + theirCount
                        if newCount ~= lastCount then
                            lastCount = newCount
                            liveTradeData.MyTotal = sanitizePrice(myTotal)
                            liveTradeData.MyItems = myCount
                            liveTradeData.TheirTotal = sanitizePrice(theirTotal)
                            liveTradeData.TheirItems = theirCount
                            addDebugLog(string.format("GUI→Me:C$%d(%d) Partner:C$%d(%d)",
                                myTotal, myCount, theirTotal, theirCount))
                            if updateActiveTradeDisplay then updateActiveTradeDisplay() end
                        end
                    end
                end)
            end
        end)
    end
end)

local TradeState = {
    TargetPlayer = "",
    TargetCSAmount = 0,
    StartFromExpensive = false,
    SelectedRarity = "None",
    SearchFishName = "",
    AutoTradeLoop = false,
    AutoAcceptReceiver = false,
    ActionDelay = 0.12
}

local function isTradeCurrentlyActive()
    if isTradeActive then return true end
    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, guiName in ipairs({"trade", "Trade", "TradeGui", "TradeApp", "TradeFrame"}) do
            local g = pGui:FindFirstChild(guiName)
            if g and ((g:IsA("ScreenGui") and g.Enabled) or (g:IsA("Frame") and g.Visible)) then
                return true
            end
        end
    end
    return true
end

local function getPlayerTradeableFishList()
    local fishList = {}
    pcall(function()
        local inv = getInventoryData()
        if not inv then
            warn("[Trade] Gagal mendapatkan data Inventory dari DataController!")
            return
        end
        local lib = getLibrary()

        local fishTable = (lib and lib.fish) or {}
        local itemsTable = (lib and lib.items) or {}
        local relicsTable = (lib and lib.relics) or {}

        for itemId, itemData in pairs(inv) do
            if type(itemData) == "table" and itemData.name then
                local itemName = tostring(itemData.name)
                local meta = fishTable[itemName] or itemsTable[itemName] or relicsTable[itemName] or {}
                local isUntradeable = meta.Untradeable or meta.IsCrate
                local isNuke = itemName:lower():find("nuke") or itemName:lower():find("nuklir")
                local isTotem = itemName:lower():find("totem")

                if not isUntradeable and not isNuke and not isTotem then
                    local canTrade = not itemData.sub or not itemData.sub.CanTradeIn or (itemData.sub.CanTradeIn <= Workspace:GetServerTimeNow() and itemData.sub.CanTradeIn ~= -1)
                    if canTrade then
                        local price = getItemRealPrice(itemData)
                        local rarity = tostring(meta.Rarity or meta.rarity or (itemName:find("Relic") and "Relic") or "Common"):lower()
                        local stack = (itemData.sub and itemData.sub.Stack) or itemData.Stack or itemData.stack or 1

                        local sub = itemData.sub or itemData
                        local mutation = (sub and sub.Mutation) or itemData.Mutation
                        local isShiny = (sub and sub.Shiny) or itemData.Shiny
                        local isSparkling = (sub and sub.Sparkling) or itemData.Sparkling
                        local weight = tonumber((sub and sub.Weight) or itemData.Weight)

                        local tags = {}
                        if isShiny then table.insert(tags, "Shiny") end
                        if isSparkling then table.insert(tags, "Sparkling") end
                        if mutation and tostring(mutation) ~= "" and tostring(mutation) ~= "nil" then
                            table.insert(tags, tostring(mutation))
                        end

                        local tagText = ""
                        if #tags > 0 then
                            tagText = "[" .. table.concat(tags, "] [") .. "]"
                        end

                        local weightText = ""
                        if weight and weight > 0 then
                            weightText = string.format("(%.1fkg)", weight)
                        end

                        local displayName = (tagText ~= "" and (tagText .. " ") or "") .. itemName .. (weightText ~= "" and (" " .. weightText) or "")

                        table.insert(fishList, {
                            id = itemId,
                            name = itemName,
                            displayName = displayName,
                            tagText = tagText,
                            weightText = weightText,
                            mutation = mutation,
                            shiny = isShiny,
                            sparkling = isSparkling,
                            weight = weight,
                            price = price,
                            rarity = rarity,
                            stack = stack,
                            data = itemData
                        })
                    end
                end
            end
        end
    end)
    return fishList
end

local function addTargetCSAmountOfFish(targetAmount, expensiveFirst)
    local fishList = getPlayerTradeableFishList()
    if #fishList == 0 then
        warn("[Trade] Tidak ada ikan tradeable ditemukan di Inventory!")
        return
    end

    table.sort(fishList, function(a, b)
        if expensiveFirst then
            return a.price > b.price
        else
            return a.price < b.price
        end
    end)

    local accumulated = 0
    task.spawn(function()
        for _, f in ipairs(fishList) do
            if accumulated >= targetAmount then break end
            fireRemoteAddItem(f.id, f.stack)
            accumulated = accumulated + (f.price * f.stack)
            task.wait(TradeState.ActionDelay)
        end
        print(string.format("[Trade] Sukses menambahkan ikan senilai ~C$ %d ke Trade!", accumulated))
    end)
end

local function addSelectedRarityFish(targetRarity)
    local fishList = getPlayerTradeableFishList()
    if #fishList == 0 then
        warn("[Trade] Tidak ada ikan tradeable ditemukan di Inventory!")
        return
    end

    task.spawn(function()
        local count = 0
        for _, f in ipairs(fishList) do
            if targetRarity == "all" or targetRarity == "All" or f.rarity:find(targetRarity:lower()) then
                fireRemoteAddItem(f.id, f.stack)
                count = count + 1
                task.wait(TradeState.ActionDelay)
            end
        end
        print(string.format("[Trade] Sukses menambahkan %d ikan kategori [%s] ke Trade!", count, targetRarity))
    end)
end

local function addSearchedFishByName(queryName)
    if not queryName or queryName == "" then return end
    local fishList = getPlayerTradeableFishList()
    if #fishList == 0 then
        warn("[Trade] Tidak ada ikan tradeable ditemukan di Inventory!")
        return
    end

    task.spawn(function()
        local count = 0
        for _, f in ipairs(fishList) do
            if f.name:lower():find(queryName:lower()) then
                fireRemoteAddItem(f.id, f.stack)
                count = count + 1
                task.wait(TradeState.ActionDelay)
            end
        end
        print(string.format("[Trade] Sukses menambahkan %d ikan dengan nama '%s' ke Trade!", count, queryName))
    end)
end

local function addSearchedFishByMutation(queryMut)
    if not queryMut or queryMut == "" then return end
    local fishList = getPlayerTradeableFishList()
    if #fishList == 0 then
        warn("[Trade] Tidak ada ikan tradeable ditemukan di Inventory!")
        return
    end

    task.spawn(function()
        local count = 0
        for _, f in ipairs(fishList) do
            local mutStr = tostring(f.mutation or ""):lower()
            local tagStr = tostring(f.tagText or ""):lower()
            if mutStr:find(queryMut:lower()) or tagStr:find(queryMut:lower()) then
                fireRemoteAddItem(f.id, f.stack)
                count = count + 1
                task.wait(TradeState.ActionDelay)
            end
        end
        print(string.format("[Trade] Sukses menambahkan %d ikan dengan mutasi '%s' ke Trade!", count, queryMut))
    end)
end

local function getAllMutationNames()
    local muts = { "All", "None", "Shiny", "Sparkling" }
    local seen = { ["all"] = true, ["none"] = true, ["shiny"] = true, ["sparkling"] = true }

    local lib = getLibrary()
    if lib and type(lib.mutations) == "table" then
        for mutName, _ in pairs(lib.mutations) do
            local nameStr = tostring(mutName)
            if not seen[nameStr:lower()] then
                seen[nameStr:lower()] = true
                table.insert(muts, nameStr)
            end
        end
    end

    local fallbackMuts = {
        "Albino", "Dark", "Electric", "Midas", "Hexed", "Ghastly", "Lunar", "Solar",
        "Radioactive", "Subspace", "Purified", "Corrupted", "Blighted", "Silver", "Gold",
        "Amber", "Sinister", "Anomalous", "Fossilized", "Neon", "Festive", "Aurora",
        "Astral", "Cursed", "Phantom", "Greedy", "Revitalized", "Tryhard", "Resilient",
        "Giant", "Tiny", "Colossal", "Big", "Translucent", "Glossy", "Frozen"
    }
    for _, nameStr in ipairs(fallbackMuts) do
        if not seen[nameStr:lower()] then
            seen[nameStr:lower()] = true
            table.insert(muts, nameStr)
        end
    end

    return muts
end

local function addSelectedMutationFish(targetMutation)
    targetMutation = tostring(targetMutation or "None")
    if targetMutation:lower() == "none" or targetMutation == "" then
        warn("[Trade] Pilih Mutation terlebih dahulu!")
        return
    end

    local fishList = getPlayerTradeableFishList()
    if #fishList == 0 then
        warn("[Trade] Tidak ada ikan tradeable ditemukan di Inventory!")
        return
    end

    task.spawn(function()
        local count = 0
        for _, f in ipairs(fishList) do
            local isMatch = false
            if targetMutation:lower() == "all" then
                isMatch = (f.mutation ~= nil and f.mutation ~= "" and f.mutation ~= "nil") or f.shiny or f.sparkling
            elseif targetMutation:lower() == "shiny" then
                isMatch = f.shiny == true
            elseif targetMutation:lower() == "sparkling" then
                isMatch = f.sparkling == true
            else
                local mutStr = tostring(f.mutation or ""):lower()
                local tagStr = tostring(f.tagText or ""):lower()
                isMatch = mutStr:find(targetMutation:lower()) ~= nil or tagStr:find(targetMutation:lower()) ~= nil
            end

            if isMatch then
                fireRemoteAddItem(f.id, f.stack)
                count = count + 1
                if TradeState.ActionDelay > 0 then
                    task.wait(TradeState.ActionDelay)
                end
            end
        end
        print(string.format("[Trade] Sukses menambahkan %d ikan dengan mutasi [%s] ke Trade!", count, targetMutation))
    end)
end

local parentGui = getParentContainer()
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShielDTeam_PurpleTrade"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui
getgenv().__ShielDTrade_GUI = ScreenGui

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert) then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 460)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -230)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 10, 20)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.4
MainStroke.Color = Color3.fromRGB(147, 51, 234)
MainStroke.Parent = MainFrame

local isDragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local TopHeader = Instance.new("Frame")
TopHeader.Name = "TopHeader"
TopHeader.Size = UDim2.new(1, 0, 0, 44)
TopHeader.BackgroundColor3 = Color3.fromRGB(20, 15, 32)
TopHeader.BorderSizePixel = 0
TopHeader.Parent = MainFrame

local TopHeaderCorner = Instance.new("UICorner")
TopHeaderCorner.CornerRadius = UDim.new(0, 14)
TopHeaderCorner.Parent = TopHeader

local HeaderBottomCover = Instance.new("Frame")
HeaderBottomCover.Size = UDim2.new(1, 0, 0, 10)
HeaderBottomCover.Position = UDim2.new(0, 0, 1, -10)
HeaderBottomCover.BackgroundColor3 = Color3.fromRGB(20, 15, 32)
HeaderBottomCover.BorderSizePixel = 0
HeaderBottomCover.Parent = TopHeader

local HeaderStroke = Instance.new("UIStroke")
HeaderStroke.Thickness = 1
HeaderStroke.Color = Color3.fromRGB(88, 28, 135)
HeaderStroke.Parent = TopHeader

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Text = "FISCH AUTO TRADE"
HeaderTitle.Size = UDim2.new(0, 200, 1, 0)
HeaderTitle.Position = UDim2.new(0, 16, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 14
HeaderTitle.TextColor3 = Color3.fromRGB(243, 232, 255)
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = TopHeader

local HeaderBadge = Instance.new("TextLabel")
HeaderBadge.Text = "PRO V2"
HeaderBadge.Size = UDim2.new(0, 52, 0, 20)
HeaderBadge.Position = UDim2.new(0, 165, 0.5, -10)
HeaderBadge.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
HeaderBadge.Font = Enum.Font.GothamBold
HeaderBadge.TextSize = 9
HeaderBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderBadge.Parent = TopHeader

local HeaderBadgeCorner = Instance.new("UICorner")
HeaderBadgeCorner.CornerRadius = UDim.new(0, 6)
HeaderBadgeCorner.Parent = HeaderBadge

local HeaderHint = Instance.new("TextLabel")
HeaderHint.Text = "[RightCtrl / Insert]"
HeaderHint.Size = UDim2.new(0, 130, 1, 0)
HeaderHint.Position = UDim2.new(1, -202, 0, 0)
HeaderHint.BackgroundTransparency = 1
HeaderHint.Font = Enum.Font.GothamMedium
HeaderHint.TextSize = 10
HeaderHint.TextColor3 = Color3.fromRGB(167, 139, 210)
HeaderHint.TextXAlignment = Enum.TextXAlignment.Right
HeaderHint.Parent = TopHeader

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
MinimizeBtn.Position = UDim2.new(1, -66, 0.5, -13)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(28, 20, 44)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(220, 200, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 14
MinimizeBtn.Parent = TopHeader

local MinimizeBtnCorner = Instance.new("UICorner")
MinimizeBtnCorner.CornerRadius = UDim.new(0, 6)
MinimizeBtnCorner.Parent = MinimizeBtn

local MinimizeBtnStroke = Instance.new("UIStroke")
MinimizeBtnStroke.Color = Color3.fromRGB(147, 51, 234)
MinimizeBtnStroke.Thickness = 1
MinimizeBtnStroke.Parent = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 20, 44)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(220, 200, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.Parent = TopHeader

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

local CloseBtnStroke = Instance.new("UIStroke")
CloseBtnStroke.Color = Color3.fromRGB(147, 51, 234)
CloseBtnStroke.Thickness = 1
CloseBtnStroke.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
end)

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, -24, 1, -56)
ContentScroll.Position = UDim2.new(0, 12, 0, 50)
ContentScroll.BackgroundTransparency = 1
ContentScroll.ScrollBarThickness = 4
ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(147, 51, 234)
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 480)
ContentScroll.Parent = MainFrame

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        ContentScroll.Visible = false
        MinimizeBtn.Text = "+"
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 500, 0, 44)
        }):Play()
    else
        MinimizeBtn.Text = "-"
        local tw = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 500, 0, 460)
        })
        tw:Play()
        task.delay(0.15, function()
            if not isMinimized then
                ContentScroll.Visible = true
            end
        end)
    end
end)

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentScroll

local ActiveTradeBanner = Instance.new("Frame")
ActiveTradeBanner.Size = UDim2.new(1, 0, 0, 52)
ActiveTradeBanner.BackgroundColor3 = Color3.fromRGB(22, 16, 36)
ActiveTradeBanner.LayoutOrder = 1
ActiveTradeBanner.Parent = ContentScroll

local ActiveTradeCorner = Instance.new("UICorner")
ActiveTradeCorner.CornerRadius = UDim.new(0, 8)
ActiveTradeCorner.Parent = ActiveTradeBanner

local ActiveTradeStroke = Instance.new("UIStroke")
ActiveTradeStroke.Color = Color3.fromRGB(147, 51, 234)
ActiveTradeStroke.Thickness = 1.2
ActiveTradeStroke.Parent = ActiveTradeBanner

local ActiveTradeTitle = Instance.new("TextLabel")
ActiveTradeTitle.Text = "LIVE TRADE VALUE"
ActiveTradeTitle.Size = UDim2.new(0, 200, 0, 20)
ActiveTradeTitle.Position = UDim2.new(0, 12, 0, 6)
ActiveTradeTitle.BackgroundTransparency = 1
ActiveTradeTitle.Font = Enum.Font.GothamBold
ActiveTradeTitle.TextSize = 10
ActiveTradeTitle.TextColor3 = Color3.fromRGB(192, 132, 252)
ActiveTradeTitle.TextXAlignment = Enum.TextXAlignment.Left
ActiveTradeTitle.Parent = ActiveTradeBanner

local ActiveTradeStatusLbl = Instance.new("TextLabel")
ActiveTradeStatusLbl.Text = "WAITING"
ActiveTradeStatusLbl.Size = UDim2.new(0, 120, 0, 20)
ActiveTradeStatusLbl.Position = UDim2.new(1, -132, 0, 6)
ActiveTradeStatusLbl.BackgroundTransparency = 1
ActiveTradeStatusLbl.Font = Enum.Font.GothamBold
ActiveTradeStatusLbl.TextSize = 9
ActiveTradeStatusLbl.TextColor3 = Color3.fromRGB(167, 139, 210)
ActiveTradeStatusLbl.TextXAlignment = Enum.TextXAlignment.Right
ActiveTradeStatusLbl.Parent = ActiveTradeBanner

local ActiveTradeValueLbl = Instance.new("TextLabel")
ActiveTradeValueLbl.Text = "Open Trade with a player to view real-time total offer value."
ActiveTradeValueLbl.Size = UDim2.new(1, -24, 0, 20)
ActiveTradeValueLbl.Position = UDim2.new(0, 12, 0, 26)
ActiveTradeValueLbl.BackgroundTransparency = 1
ActiveTradeValueLbl.Font = Enum.Font.GothamBold
ActiveTradeValueLbl.TextSize = 11
ActiveTradeValueLbl.TextColor3 = Color3.fromRGB(74, 222, 128)
ActiveTradeValueLbl.TextXAlignment = Enum.TextXAlignment.Left
ActiveTradeValueLbl.TextTruncate = Enum.TextTruncate.AtEnd
ActiveTradeValueLbl.Parent = ActiveTradeBanner

local Row1 = Instance.new("Frame")
Row1.Size = UDim2.new(1, 0, 0, 36)
Row1.BackgroundColor3 = Color3.fromRGB(20, 15, 32)
Row1.LayoutOrder = 2
Row1.Parent = ContentScroll

local Row1Corner = Instance.new("UICorner")
Row1Corner.CornerRadius = UDim.new(0, 8)
Row1Corner.Parent = Row1

local Row1Label = Instance.new("TextLabel")
Row1Label.Text = "Target C$ Amount"
Row1Label.Size = UDim2.new(0, 160, 1, 0)
Row1Label.Position = UDim2.new(0, 12, 0, 0)
Row1Label.BackgroundTransparency = 1
Row1Label.Font = Enum.Font.GothamMedium
Row1Label.TextSize = 12
Row1Label.TextColor3 = Color3.fromRGB(243, 232, 255)
Row1Label.TextXAlignment = Enum.TextXAlignment.Left
Row1Label.Parent = Row1

local CSInput = Instance.new("TextBox")
CSInput.Size = UDim2.new(0, 180, 0, 26)
CSInput.Position = UDim2.new(1, -190, 0.5, -13)
CSInput.BackgroundColor3 = Color3.fromRGB(13, 10, 20)
CSInput.PlaceholderText = "Enter C$ value (e.g. 500000)"
CSInput.PlaceholderColor3 = Color3.fromRGB(140, 110, 175)
CSInput.Text = ""
CSInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CSInput.Font = Enum.Font.Gotham
CSInput.TextSize = 11
CSInput.Parent = Row1

local CSInputCorner = Instance.new("UICorner")
CSInputCorner.CornerRadius = UDim.new(0, 6)
CSInputCorner.Parent = CSInput

local CSInputStroke = Instance.new("UIStroke")
CSInputStroke.Color = Color3.fromRGB(88, 28, 135)
CSInputStroke.Thickness = 1
CSInputStroke.Parent = CSInput

CSInput.FocusLost:Connect(function()
    TradeState.TargetCSAmount = tonumber(CSInput.Text) or 0
end)

local Row2 = Instance.new("Frame")
Row2.Size = UDim2.new(1, 0, 0, 36)
Row2.BackgroundColor3 = Color3.fromRGB(20, 15, 32)
Row2.LayoutOrder = 3
Row2.Parent = ContentScroll

local Row2Corner = Instance.new("UICorner")
Row2Corner.CornerRadius = UDim.new(0, 8)
Row2Corner.Parent = Row2

local Row2Label = Instance.new("TextLabel")
Row2Label.Text = "Start From Expensive Fishes"
Row2Label.Size = UDim2.new(0, 200, 1, 0)
Row2Label.Position = UDim2.new(0, 12, 0, 0)
Row2Label.BackgroundTransparency = 1
Row2Label.Font = Enum.Font.GothamMedium
Row2Label.TextSize = 12
Row2Label.TextColor3 = Color3.fromRGB(243, 232, 255)
Row2Label.TextXAlignment = Enum.TextXAlignment.Left
Row2Label.Parent = Row2

local ToggleBg = Instance.new("TextButton")
ToggleBg.Size = UDim2.new(0, 42, 0, 22)
ToggleBg.Position = UDim2.new(1, -54, 0.5, -11)
ToggleBg.BackgroundColor3 = Color3.fromRGB(35, 25, 52)
ToggleBg.Text = ""
ToggleBg.Parent = Row2

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBg

local ToggleCircle = Instance.new("Frame")
ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
ToggleCircle.Position = UDim2.new(0, 3, 0.5, -8)
ToggleCircle.BackgroundColor3 = Color3.fromRGB(167, 139, 210)
ToggleCircle.Parent = ToggleBg

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = ToggleCircle

ToggleBg.MouseButton1Click:Connect(function()
    TradeState.StartFromExpensive = not TradeState.StartFromExpensive
    if TradeState.StartFromExpensive then
        ToggleBg.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
        ToggleCircle.Position = UDim2.new(1, -19, 0.5, -8)
        ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    else
        ToggleBg.BackgroundColor3 = Color3.fromRGB(35, 25, 52)
        ToggleCircle.Position = UDim2.new(0, 3, 0.5, -8)
        ToggleCircle.BackgroundColor3 = Color3.fromRGB(167, 139, 210)
    end
end)

local BtnAddCS = Instance.new("TextButton")
BtnAddCS.Size = UDim2.new(1, 0, 0, 34)
BtnAddCS.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
BtnAddCS.Text = "Add Target C$ Amount of Fish to Trade"
BtnAddCS.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnAddCS.Font = Enum.Font.GothamBold
BtnAddCS.TextSize = 11
BtnAddCS.LayoutOrder = 4
BtnAddCS.Parent = ContentScroll

local BtnAddCSCorner = Instance.new("UICorner")
BtnAddCSCorner.CornerRadius = UDim.new(0, 8)
BtnAddCSCorner.Parent = BtnAddCS

BtnAddCS.MouseButton1Click:Connect(function()
    if TradeState.TargetCSAmount > 0 then
        addTargetCSAmountOfFish(TradeState.TargetCSAmount, TradeState.StartFromExpensive)
    else
        warn("[Trade] Masukkan nilai Target C$ Amount terlebih dahulu!")
    end
end)

local DropdownPopup = Instance.new("Frame")
DropdownPopup.Name = "DropdownPopup"
DropdownPopup.Size = UDim2.new(0, 260, 0, 240)
DropdownPopup.Position = UDim2.new(0.5, -130, 0.5, -120)
DropdownPopup.BackgroundColor3 = Color3.fromRGB(18, 13, 28)
DropdownPopup.BorderSizePixel = 0
DropdownPopup.ZIndex = 50
DropdownPopup.Visible = false
DropdownPopup.Parent = MainFrame

local DropdownPopupCorner = Instance.new("UICorner")
DropdownPopupCorner.CornerRadius = UDim.new(0, 10)
DropdownPopupCorner.Parent = DropdownPopup

local DropdownPopupStroke = Instance.new("UIStroke")
DropdownPopupStroke.Color = Color3.fromRGB(168, 85, 247)
DropdownPopupStroke.Thickness = 1.4
DropdownPopupStroke.Parent = DropdownPopup

local DropdownHeader = Instance.new("Frame")
DropdownHeader.Size = UDim2.new(1, 0, 0, 34)
DropdownHeader.BackgroundColor3 = Color3.fromRGB(26, 18, 42)
DropdownHeader.ZIndex = 51
DropdownHeader.Parent = DropdownPopup

local DropdownHeaderCorner = Instance.new("UICorner")
DropdownHeaderCorner.CornerRadius = UDim.new(0, 10)
DropdownHeaderCorner.Parent = DropdownHeader

local DropdownHeaderTitle = Instance.new("TextLabel")
DropdownHeaderTitle.Text = "SELECT OPTION"
DropdownHeaderTitle.Size = UDim2.new(1, -60, 1, 0)
DropdownHeaderTitle.Position = UDim2.new(0, 12, 0, 0)
DropdownHeaderTitle.BackgroundTransparency = 1
DropdownHeaderTitle.Font = Enum.Font.GothamBold
DropdownHeaderTitle.TextSize = 11
DropdownHeaderTitle.TextColor3 = Color3.fromRGB(243, 232, 255)
DropdownHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
DropdownHeaderTitle.ZIndex = 52
DropdownHeaderTitle.Parent = DropdownHeader

local DropdownCloseBtn = Instance.new("TextButton")
DropdownCloseBtn.Text = "Close"
DropdownCloseBtn.Size = UDim2.new(0, 48, 0, 22)
DropdownCloseBtn.Position = UDim2.new(1, -54, 0.5, -11)
DropdownCloseBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 52)
DropdownCloseBtn.Font = Enum.Font.GothamBold
DropdownCloseBtn.TextSize = 10
DropdownCloseBtn.TextColor3 = Color3.fromRGB(192, 132, 252)
DropdownCloseBtn.ZIndex = 52
DropdownCloseBtn.Parent = DropdownHeader

local DropdownCloseCorner = Instance.new("UICorner")
DropdownCloseCorner.CornerRadius = UDim.new(0, 4)
DropdownCloseCorner.Parent = DropdownCloseBtn

DropdownCloseBtn.MouseButton1Click:Connect(function()
    DropdownPopup.Visible = false
end)

local DropdownSearch = Instance.new("TextBox")
DropdownSearch.Size = UDim2.new(1, -16, 0, 26)
DropdownSearch.Position = UDim2.new(0, 8, 0, 40)
DropdownSearch.BackgroundColor3 = Color3.fromRGB(12, 8, 18)
DropdownSearch.PlaceholderText = "Search list..."
DropdownSearch.PlaceholderColor3 = Color3.fromRGB(140, 110, 175)
DropdownSearch.Text = ""
DropdownSearch.TextColor3 = Color3.fromRGB(255, 255, 255)
DropdownSearch.Font = Enum.Font.Gotham
DropdownSearch.TextSize = 11
DropdownSearch.ZIndex = 51
DropdownSearch.Parent = DropdownPopup

local DropdownSearchCorner = Instance.new("UICorner")
DropdownSearchCorner.CornerRadius = UDim.new(0, 6)
DropdownSearchCorner.Parent = DropdownSearch

local DropdownSearchStroke = Instance.new("UIStroke")
DropdownSearchStroke.Color = Color3.fromRGB(88, 28, 135)
DropdownSearchStroke.Thickness = 1
DropdownSearchStroke.Parent = DropdownSearch

local DropdownListScroll = Instance.new("ScrollingFrame")
DropdownListScroll.Size = UDim2.new(1, -14, 1, -78)
DropdownListScroll.Position = UDim2.new(0, 7, 0, 72)
DropdownListScroll.BackgroundTransparency = 1
DropdownListScroll.ScrollBarThickness = 3
DropdownListScroll.ScrollBarImageColor3 = Color3.fromRGB(147, 51, 234)
DropdownListScroll.ZIndex = 51
DropdownListScroll.Parent = DropdownPopup

local DropdownListLayout = Instance.new("UIListLayout")
DropdownListLayout.Padding = UDim.new(0, 4)
DropdownListLayout.SortOrder = Enum.SortOrder.LayoutOrder
DropdownListLayout.Parent = DropdownListScroll

local function openDropdownMenu(title, optionsList, currentSelected, onSelectCallback)
    DropdownHeaderTitle.Text = string.upper(title)
    DropdownSearch.Text = ""
    DropdownPopup.Visible = true

    local function refreshItems(filterText)
        filterText = (filterText or ""):lower()
        for _, child in ipairs(DropdownListScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        local totalH = 0
        for idx, opt in ipairs(optionsList) do
            local optStr = tostring(opt)
            if filterText == "" or optStr:lower():find(filterText) then
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, -6, 0, 26)
                optBtn.BackgroundColor3 = (optStr:lower() == tostring(currentSelected):lower()) and Color3.fromRGB(147, 51, 234) or Color3.fromRGB(28, 20, 44)
                optBtn.Text = optStr
                optBtn.TextColor3 = Color3.fromRGB(245, 240, 255)
                optBtn.Font = Enum.Font.GothamMedium
                optBtn.TextSize = 11
                optBtn.ZIndex = 52
                optBtn.LayoutOrder = idx
                optBtn.Parent = DropdownListScroll

                local optCorner = Instance.new("UICorner")
                optCorner.CornerRadius = UDim.new(0, 4)
                optCorner.Parent = optBtn

                optBtn.MouseButton1Click:Connect(function()
                    DropdownPopup.Visible = false
                    if onSelectCallback then onSelectCallback(optStr) end
                end)
                totalH = totalH + 30
            end
        end
        DropdownListScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 10)
    end

    refreshItems("")

    local conn
    conn = DropdownSearch:GetPropertyChangedSignal("Text"):Connect(function()
        if DropdownPopup.Visible then
            refreshItems(DropdownSearch.Text)
        else
            conn:Disconnect()
        end
    end)
end

local Row3 = Instance.new("Frame")
Row3.Size = UDim2.new(1, 0, 0, 36)
Row3.BackgroundColor3 = Color3.fromRGB(20, 15, 32)
Row3.LayoutOrder = 5
Row3.Parent = ContentScroll

local Row3Corner = Instance.new("UICorner")
Row3Corner.CornerRadius = UDim.new(0, 8)
Row3Corner.Parent = Row3

local RarityBtn = Instance.new("TextButton")
RarityBtn.Text = "Select Rarities : None"
RarityBtn.Size = UDim2.new(1, -20, 1, 0)
RarityBtn.Position = UDim2.new(0, 12, 0, 0)
RarityBtn.BackgroundTransparency = 1
RarityBtn.Font = Enum.Font.GothamBold
RarityBtn.TextSize = 11
RarityBtn.TextColor3 = Color3.fromRGB(243, 232, 255)
RarityBtn.TextXAlignment = Enum.TextXAlignment.Left
RarityBtn.Parent = Row3

local RaritiesList = { "None", "All", "Secret", "Exotic", "Relic", "Mythic", "Legendary", "Rare", "Uncommon", "Common" }

RarityBtn.MouseButton1Click:Connect(function()
    openDropdownMenu("Select Rarity", RaritiesList, TradeState.SelectedRarity, function(selected)
        TradeState.SelectedRarity = selected
        RarityBtn.Text = "Select Rarities : " .. selected
    end)
end)

local BtnAddRarity = Instance.new("TextButton")
BtnAddRarity.Size = UDim2.new(1, 0, 0, 34)
BtnAddRarity.BackgroundColor3 = Color3.fromRGB(32, 22, 50)
BtnAddRarity.Text = "Add Selected Rarity Fish to Trade"
BtnAddRarity.TextColor3 = Color3.fromRGB(220, 200, 255)
BtnAddRarity.Font = Enum.Font.GothamMedium
BtnAddRarity.TextSize = 11
BtnAddRarity.LayoutOrder = 6
BtnAddRarity.Parent = ContentScroll

local BtnAddRarityCorner = Instance.new("UICorner")
BtnAddRarityCorner.CornerRadius = UDim.new(0, 8)
BtnAddRarityCorner.Parent = BtnAddRarity

local BtnAddRarityStroke = Instance.new("UIStroke")
BtnAddRarityStroke.Color = Color3.fromRGB(107, 33, 168)
BtnAddRarityStroke.Thickness = 1
BtnAddRarityStroke.Parent = BtnAddRarity

BtnAddRarity.MouseButton1Click:Connect(function()
    if TradeState.SelectedRarity ~= "None" then
        addSelectedRarityFish(TradeState.SelectedRarity)
    else
        warn("[Trade] Pilih Rarity terlebih dahulu!")
    end
end)

local Row4 = Instance.new("Frame")
Row4.Size = UDim2.new(1, 0, 0, 36)
Row4.BackgroundColor3 = Color3.fromRGB(20, 15, 32)
Row4.LayoutOrder = 7
Row4.Parent = ContentScroll

local Row4Corner = Instance.new("UICorner")
Row4Corner.CornerRadius = UDim.new(0, 8)
Row4Corner.Parent = Row4

local MutationBtn = Instance.new("TextButton")
MutationBtn.Text = "Select Mutation : None"
MutationBtn.Size = UDim2.new(1, -20, 1, 0)
MutationBtn.Position = UDim2.new(0, 12, 0, 0)
MutationBtn.BackgroundTransparency = 1
MutationBtn.Font = Enum.Font.GothamBold
MutationBtn.TextSize = 11
MutationBtn.TextColor3 = Color3.fromRGB(250, 204, 21)
MutationBtn.TextXAlignment = Enum.TextXAlignment.Left
MutationBtn.Parent = Row4

TradeState.SelectedMutation = "None"

MutationBtn.MouseButton1Click:Connect(function()
    local allMuts = getAllMutationNames()
    openDropdownMenu("Select Mutation", allMuts, TradeState.SelectedMutation, function(selected)
        TradeState.SelectedMutation = selected
        MutationBtn.Text = "Select Mutation : " .. selected
        updateInventoryListUI(SearchInput and SearchInput.Text, selected ~= "None" and selected ~= "All" and selected or "")
    end)
end)

local BtnAddMutation = Instance.new("TextButton")
BtnAddMutation.Size = UDim2.new(1, 0, 0, 34)
BtnAddMutation.BackgroundColor3 = Color3.fromRGB(32, 22, 50)
BtnAddMutation.Text = "Add Selected Mutation Fish to Trade"
BtnAddMutation.TextColor3 = Color3.fromRGB(250, 204, 21)
BtnAddMutation.Font = Enum.Font.GothamMedium
BtnAddMutation.TextSize = 11
BtnAddMutation.LayoutOrder = 8
BtnAddMutation.Parent = ContentScroll

local BtnAddMutationCorner = Instance.new("UICorner")
BtnAddMutationCorner.CornerRadius = UDim.new(0, 8)
BtnAddMutationCorner.Parent = BtnAddMutation

local BtnAddMutationStroke = Instance.new("UIStroke")
BtnAddMutationStroke.Color = Color3.fromRGB(107, 33, 168)
BtnAddMutationStroke.Thickness = 1
BtnAddMutationStroke.Parent = BtnAddMutation

BtnAddMutation.MouseButton1Click:Connect(function()
    if TradeState.SelectedMutation ~= "None" then
        addSelectedMutationFish(TradeState.SelectedMutation)
    else
        warn("[Trade] Pilih Mutation terlebih dahulu!")
    end
end)

local InvSectionHeader = Instance.new("TextLabel")
InvSectionHeader.Text = "INVENTORY & PRICE LIST"
InvSectionHeader.Size = UDim2.new(1, 0, 0, 24)
InvSectionHeader.BackgroundTransparency = 1
InvSectionHeader.Font = Enum.Font.GothamBold
InvSectionHeader.TextSize = 11
InvSectionHeader.TextColor3 = Color3.fromRGB(167, 139, 210)
InvSectionHeader.TextXAlignment = Enum.TextXAlignment.Left
InvSectionHeader.LayoutOrder = 9
InvSectionHeader.Parent = ContentScroll

local InvSummaryBox = Instance.new("Frame")
InvSummaryBox.Size = UDim2.new(1, 0, 0, 40)
InvSummaryBox.BackgroundColor3 = Color3.fromRGB(20, 15, 32)
InvSummaryBox.LayoutOrder = 10
InvSummaryBox.Parent = ContentScroll

local InvSummaryCorner = Instance.new("UICorner")
InvSummaryCorner.CornerRadius = UDim.new(0, 8)
InvSummaryCorner.Parent = InvSummaryBox

local InvSummaryStroke = Instance.new("UIStroke")
InvSummaryStroke.Color = Color3.fromRGB(88, 28, 135)
InvSummaryStroke.Thickness = 1
InvSummaryStroke.Parent = InvSummaryBox

local InvSummaryText = Instance.new("TextLabel")
InvSummaryText.Text = "Total Value: ~C$ 0 | Items: 0"
InvSummaryText.Size = UDim2.new(1, -110, 1, 0)
InvSummaryText.Position = UDim2.new(0, 12, 0, 0)
InvSummaryText.BackgroundTransparency = 1
InvSummaryText.Font = Enum.Font.GothamBold
InvSummaryText.TextSize = 11
InvSummaryText.TextColor3 = Color3.fromRGB(74, 222, 128)
InvSummaryText.TextXAlignment = Enum.TextXAlignment.Left
InvSummaryText.Parent = InvSummaryBox

local RefreshInvBtn = Instance.new("TextButton")
RefreshInvBtn.Size = UDim2.new(0, 90, 0, 26)
RefreshInvBtn.Position = UDim2.new(1, -98, 0.5, -13)
RefreshInvBtn.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
RefreshInvBtn.Text = "Refresh"
RefreshInvBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshInvBtn.Font = Enum.Font.GothamBold
RefreshInvBtn.TextSize = 11
RefreshInvBtn.Parent = InvSummaryBox

local RefreshInvCorner = Instance.new("UICorner")
RefreshInvCorner.CornerRadius = UDim.new(0, 6)
RefreshInvCorner.Parent = RefreshInvBtn

local Row5 = Instance.new("Frame")
Row5.Size = UDim2.new(1, 0, 0, 36)
Row5.BackgroundColor3 = Color3.fromRGB(20, 15, 32)
Row5.LayoutOrder = 11
Row5.Parent = ContentScroll

local Row5Corner = Instance.new("UICorner")
Row5Corner.CornerRadius = UDim.new(0, 8)
Row5Corner.Parent = Row5

local Row5Label = Instance.new("TextLabel")
Row5Label.Text = "Search Fish Name"
Row5Label.Size = UDim2.new(0, 150, 1, 0)
Row5Label.Position = UDim2.new(0, 12, 0, 0)
Row5Label.BackgroundTransparency = 1
Row5Label.Font = Enum.Font.GothamMedium
Row5Label.TextSize = 12
Row5Label.TextColor3 = Color3.fromRGB(243, 232, 255)
Row5Label.TextXAlignment = Enum.TextXAlignment.Left
Row5Label.Parent = Row5

local SearchInput = Instance.new("TextBox")
SearchInput.Size = UDim2.new(0, 180, 0, 26)
SearchInput.Position = UDim2.new(1, -190, 0.5, -13)
SearchInput.BackgroundColor3 = Color3.fromRGB(13, 10, 20)
SearchInput.PlaceholderText = "Enter fish name"
SearchInput.PlaceholderColor3 = Color3.fromRGB(140, 110, 175)
SearchInput.Text = ""
SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchInput.Font = Enum.Font.Gotham
SearchInput.TextSize = 11
SearchInput.Parent = Row5

local SearchInputCorner = Instance.new("UICorner")
SearchInputCorner.CornerRadius = UDim.new(0, 6)
SearchInputCorner.Parent = SearchInput

local SearchInputStroke = Instance.new("UIStroke")
SearchInputStroke.Color = Color3.fromRGB(88, 28, 135)
SearchInputStroke.Thickness = 1
SearchInputStroke.Parent = SearchInput

local BtnAddSearched = Instance.new("TextButton")
BtnAddSearched.Size = UDim2.new(1, 0, 0, 34)
BtnAddSearched.BackgroundColor3 = Color3.fromRGB(32, 22, 50)
BtnAddSearched.Text = "Add Searched Fish to Trade"
BtnAddSearched.TextColor3 = Color3.fromRGB(220, 200, 255)
BtnAddSearched.Font = Enum.Font.GothamMedium
BtnAddSearched.TextSize = 11
BtnAddSearched.LayoutOrder = 12
BtnAddSearched.Parent = ContentScroll

local BtnAddSearchedCorner = Instance.new("UICorner")
BtnAddSearchedCorner.CornerRadius = UDim.new(0, 8)
BtnAddSearchedCorner.Parent = BtnAddSearched

local BtnAddSearchedStroke = Instance.new("UIStroke")
BtnAddSearchedStroke.Color = Color3.fromRGB(107, 33, 168)
BtnAddSearchedStroke.Thickness = 1
BtnAddSearchedStroke.Parent = BtnAddSearched

BtnAddSearched.MouseButton1Click:Connect(function()
    if TradeState.SearchFishName ~= "" then
        addSearchedFishByName(TradeState.SearchFishName)
    else
        warn("[Trade] Masukkan nama ikan di Search Box terlebih dahulu!")
    end
end)

local InvListContainer = Instance.new("Frame")
InvListContainer.Size = UDim2.new(1, 0, 0, 100)
InvListContainer.BackgroundTransparency = 1
InvListContainer.LayoutOrder = 13
InvListContainer.Parent = ContentScroll

local InvListLayout = Instance.new("UIListLayout")
InvListLayout.Padding = UDim.new(0, 6)
InvListLayout.SortOrder = Enum.SortOrder.LayoutOrder
InvListLayout.Parent = InvListContainer

InvListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    InvListContainer.Size = UDim2.new(1, 0, 0, InvListLayout.AbsoluteContentSize.Y)
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 40)
end)

local function getRarityColor(rarity)
    local r = tostring(rarity or ""):lower()
    if r:find("secret") then
        return Color3.fromRGB(239, 68, 68) -- Secret Neon Red
    elseif r:find("mythic") then
        return Color3.fromRGB(244, 114, 182)
    elseif r:find("relic") or r:find("exotic") then
        return Color3.fromRGB(192, 132, 252)
    elseif r:find("legendary") then
        return Color3.fromRGB(250, 204, 21)
    elseif r:find("rare") then
        return Color3.fromRGB(96, 165, 250)
    elseif r:find("uncommon") then
        return Color3.fromRGB(74, 222, 128)
    else
        return Color3.fromRGB(203, 213, 225)
    end
end

local function updateInventoryListUI(nameFilter, mutFilter)
    nameFilter = nameFilter or (SearchInput and SearchInput.Text) or ""
    mutFilter = mutFilter or (TradeState and TradeState.SelectedMutation ~= "None" and TradeState.SelectedMutation ~= "All" and TradeState.SelectedMutation) or ""
    local rarityFilter = (TradeState and TradeState.SelectedRarity ~= "None" and TradeState.SelectedRarity ~= "All" and TradeState.SelectedRarity) or ""

    for _, child in ipairs(InvListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local fishList = getPlayerTradeableFishList()
    local totalVal = 0
    local totalCount = 0

    table.sort(fishList, function(a, b) return a.price > b.price end)

    for _, f in ipairs(fishList) do
        local matchName = (nameFilter == "") or f.name:lower():find(nameFilter:lower())
        local matchMut = (mutFilter == "") or (f.mutation and f.mutation:lower():find(mutFilter:lower())) or (f.tagText and f.tagText:lower():find(mutFilter:lower()))
        local matchRarity = (rarityFilter == "") or (f.rarity and f.rarity:lower():find(rarityFilter:lower()))

        if matchName and matchMut and matchRarity then
            totalCount = totalCount + f.stack
            totalVal = totalVal + (f.price * f.stack)

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 44)
            row.BackgroundColor3 = Color3.fromRGB(20, 15, 32)
            row.Parent = InvListContainer

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 6)
            rowCorner.Parent = row

            local rowStroke = Instance.new("UIStroke")
            rowStroke.Color = Color3.fromRGB(58, 38, 92)
            rowStroke.Thickness = 1
            rowStroke.Parent = row

            local rColor = getRarityColor(f.rarity)
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 70, 0, 22)
            badge.Position = UDim2.new(0, 8, 0.5, -11)
            badge.BackgroundColor3 = Color3.fromRGB(12, 8, 18)
            badge.Text = f.rarity:upper()
            badge.TextColor3 = rColor
            badge.Font = Enum.Font.GothamBold
            badge.TextSize = 9
            badge.Parent = row

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -305, 0, 18)
            nameLbl.Position = UDim2.new(0, 84, 0, 4)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = string.format("%s (x%d)", f.name, f.stack)
            nameLbl.TextColor3 = Color3.fromRGB(243, 232, 255)
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 11
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Parent = row

            local subLbl = Instance.new("TextLabel")
            subLbl.Size = UDim2.new(1, -305, 0, 16)
            subLbl.Position = UDim2.new(0, 84, 0, 22)
            subLbl.BackgroundTransparency = 1

            local subDetails = {}
            if f.tagText and f.tagText ~= "" then table.insert(subDetails, f.tagText) end
            if f.weightText and f.weightText ~= "" then table.insert(subDetails, f.weightText) end
            local subText = #subDetails > 0 and table.concat(subDetails, " ") or "Normal"
            subLbl.Text = subText
            subLbl.TextColor3 = (f.mutation or f.shiny or f.sparkling) and Color3.fromRGB(250, 204, 21) or Color3.fromRGB(167, 139, 210)
            subLbl.Font = Enum.Font.GothamMedium
            subLbl.TextSize = 10
            subLbl.TextXAlignment = Enum.TextXAlignment.Left
            subLbl.TextTruncate = Enum.TextTruncate.AtEnd
            subLbl.Parent = row

            local priceLbl = Instance.new("TextLabel")
            priceLbl.Size = UDim2.new(0, 100, 0, 18)
            priceLbl.Position = UDim2.new(1, -215, 0.5, -9)
            priceLbl.BackgroundTransparency = 1
            priceLbl.Text = string.format("~C$ %s", formatNumber(f.price * f.stack))
            priceLbl.TextColor3 = Color3.fromRGB(74, 222, 128)
            priceLbl.Font = Enum.Font.GothamBold
            priceLbl.TextSize = 11
            priceLbl.TextXAlignment = Enum.TextXAlignment.Right
            priceLbl.Parent = row

            local amtBox = Instance.new("TextBox")
            amtBox.Size = UDim2.new(0, 36, 0, 24)
            amtBox.Position = UDim2.new(1, -108, 0.5, -12)
            amtBox.BackgroundColor3 = Color3.fromRGB(12, 8, 18)
            amtBox.PlaceholderText = tostring(f.stack)
            amtBox.Text = tostring(f.stack)
            amtBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            amtBox.Font = Enum.Font.Gotham
            amtBox.TextSize = 10
            amtBox.ClearTextOnFocus = true
            amtBox.Parent = row

            local amtCorner = Instance.new("UICorner")
            amtCorner.CornerRadius = UDim.new(0, 4)
            amtCorner.Parent = amtBox

            local amtStroke = Instance.new("UIStroke")
            amtStroke.Color = Color3.fromRGB(88, 28, 135)
            amtStroke.Thickness = 1
            amtStroke.Parent = amtBox

            local addBtn = Instance.new("TextButton")
            addBtn.Size = UDim2.new(0, 62, 0, 24)
            addBtn.Position = UDim2.new(1, -68, 0.5, -12)
            addBtn.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
            addBtn.Text = "+ Trade"
            addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            addBtn.Font = Enum.Font.GothamBold
            addBtn.TextSize = 10
            addBtn.Parent = row

            local addBtnCorner = Instance.new("UICorner")
            addBtnCorner.CornerRadius = UDim.new(0, 4)
            addBtnCorner.Parent = addBtn

            local itemID = f.id
            local itemStack = f.stack
            addBtn.MouseButton1Click:Connect(function()
                local amt = tonumber(amtBox.Text) or itemStack
                amt = math.clamp(amt, 1, itemStack)
                fireRemoteAddItem(itemID, amt)
            end)
        end
    end

    InvSummaryText.Text = string.format("Total Value: ~C$ %s | Items: %d", formatNumber(totalVal), totalCount)
end

SearchInput.FocusLost:Connect(function(enterPressed)
    TradeState.SearchFishName = SearchInput.Text
    updateInventoryListUI(SearchInput.Text, TradeState.SelectedMutation)
    if enterPressed and TradeState.SearchFishName ~= "" then
        addSearchedFishByName(TradeState.SearchFishName)
    end
end)

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    updateInventoryListUI(SearchInput.Text, TradeState.SelectedMutation)
end)

RefreshInvBtn.MouseButton1Click:Connect(function()
    updateInventoryListUI(SearchInput.Text, TradeState.SelectedMutation)
end)

updateActiveTradeDisplay = function()
    if not ActiveTradeValueLbl or not ActiveTradeStatusLbl then return end
    local active = liveTradeData.Active or isTradeCurrentlyActive()

    if active then
        ActiveTradeStatusLbl.Text = "ACTIVE SESSION"
        ActiveTradeStatusLbl.TextColor3 = Color3.fromRGB(74, 222, 128)
        ActiveTradeValueLbl.Text = string.format("You: ~C$ %s (%d items)  |  Partner: ~C$ %s (%d items)",
            formatNumber(liveTradeData.MyTotal), liveTradeData.MyItems,
            formatNumber(liveTradeData.TheirTotal), liveTradeData.TheirItems)
    else
        ActiveTradeStatusLbl.Text = "WAITING"
        ActiveTradeStatusLbl.TextColor3 = Color3.fromRGB(167, 139, 210)
        ActiveTradeValueLbl.Text = "Open Trade with a player to view real-time total offer value."
    end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if updateActiveTradeDisplay then
                updateActiveTradeDisplay()
            end
        end)
    end
end)

task.spawn(function()
    task.wait(0.5)
    updateInventoryListUI()
    if updateActiveTradeDisplay then
        updateActiveTradeDisplay()
    end
end)

if RemoteTradeStarted then
    pcall(function()
        RemoteTradeStarted.OnClientEvent:Connect(function(partner)
            isTradeActive = true
            liveTradeData.Active = true
            liveTradeData.MyTotal = 0
            liveTradeData.MyItems = 0
            liveTradeData.TheirTotal = 0
            liveTradeData.TheirItems = 0
            if updateActiveTradeDisplay then updateActiveTradeDisplay() end
        end)
    end)
end

if RemoteTradeEnded then
    pcall(function()
        RemoteTradeEnded.OnClientEvent:Connect(function()
            isTradeActive = false
            liveTradeData.Active = false
            liveTradeData.MyTotal = 0
            liveTradeData.MyItems = 0
            liveTradeData.TheirTotal = 0
            liveTradeData.TheirItems = 0
            if updateActiveTradeDisplay then updateActiveTradeDisplay() end
        end)
    end)
end

print("[ShielDTeam] Purple Theme Fisch Auto Trade GUI Berhasil Dimuat!")

