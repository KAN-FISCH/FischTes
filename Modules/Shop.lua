local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local function getMod(name)
    if _G.getMod then return _G.getMod(name) end
    local core = game:GetService("ReplicatedStorage"):FindFirstChild("Shield_Core")
    if core then
        local folder = core:FindFirstChild(name)
        if folder then
            local src = ""
            if folder:IsA("Folder") then
                for i = 1, #folder:GetChildren() do
                    local chunk = folder:FindFirstChild(tostring(i))
                    if chunk then src = src .. chunk.Value end
                end
            else
                src = folder.Value
            end
            local fn, err = loadstring(src)
            if not fn then
                warn("[NewFish5] Failed to load module '" .. tostring(name) .. "': " .. tostring(err))
                return nil
            end
            local success, res = pcall(fn)
            if not success then
                warn("[NewFish5] Error executing module '" .. tostring(name) .. "': " .. tostring(res))
                return nil
            end
            return res
        end
    end
    return nil
end
local function Init(ShopBait, ShopItem, ShopRod, Merlin)
    local purchase = ReplicatedStorage:WaitForChild("events"):WaitForChild("purchase")
    local fire = purchase.FireServer
    local selectedBait = nil
    local baitBuyAmount = 1
    ShopBait:AddParagraph({
        Title = "Purchase System",
        Content = "• Max 50 per transaction\n• Auto-loops for larger amounts\n• 0.5s delay between purchases\n• Stops after 3 consecutive failures\n• Use 'Stop Purchase' to cancel"
    })
    ShopBait:AddDropdown({
        Title = "Select Bait",
        Content = "Choose a Bait to Purchase",
        Multi = false,
        Options = {
            "Common Crate",
            "Tropical Bait Crate",
            "Carbon Crate",
            "Bait Crate",
            "Quality Bait Crate",
            "Coral Geode",
            "Volcanic Geode",
            "Festive Bait Crate"
        },
        Callback = function(v)
            selectedBait = v
        end
    })
    ShopBait:AddInput({
        Title = "Buy Amount",
        Content = "Amount To Buy Bait",
        Value = "1",
        Callback = function(Text)
            local amount = tonumber(Text)
            if amount then
                baitBuyAmount = amount
            end
        end
    })
    ShopBait:AddButton({
        Title = "Buy Bait Crate",
        Content = "Theoretical maximum",
        Callback = function()
            if not selectedBait then return end
                local item = selectedBait
                local rem = tonumber(baitBuyAmount) or 1
                task.spawn(function()
                    pcall(function()
                        while rem > 0 do
                            local buyBatch = rem > 50 and 50 or rem
                            purchase:FireServer(item, "Fish", nil, buyBatch)
                            rem = rem - buyBatch
                        end
                    end)
                end)
        end
    })
    ShopBait:AddSeperator({
        Title = "Auto Buy Bait (NPC)"
    })
    ShopBait:AddToggle({
        Title = "Enable Auto Buy Bait",
        Default = _G.Config.AutoBuyBait or false,
        Callback = function(state)
            _G.Config.AutoBuyBait = state
        end
    })
    local BAIT_LIST = {
        "Worm", "Cricket", "Leech", "Minnow", "Firefly",
        "Shrimp", "Squid", "Sand Dollar", "Pearl",
        "Phantom Worm", "Enchanted Bait", "Seaside Sardine"
    }
    ShopBait:AddDropdown({
        Title = "Auto Buy Bait Type",
        Content = "Select individual bait to buy automatically",
        Options = BAIT_LIST,
        Default = _G.Config.SelectedBait or "Worm",
        Callback = function(v)
            _G.Config.SelectedBait = v
        end
    })
    ShopBait:AddInput({
        Title = "Auto Buy Quantity",
        Content = "Quantity of bait to purchase automatically",
        Value = tostring(_G.Config.BuyBaitAmount or 1),
        Callback = function(Text)
            local amount = tonumber(Text)
            if amount then
                _G.Config.BuyBaitAmount = amount
            end
        end
    })
    local itemNames = {}
    local successItems, itemsModule = pcall(function()
        return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("modules"):WaitForChild("library"):WaitForChild("items"))
    end)
    if successItems and itemsModule and itemsModule.Items then
        for itemName in pairs(itemsModule.Items) do
            table.insert(itemNames, itemName)
        end
        table.sort(itemNames)
    else
        itemNames = {"Common Crate", "Carbon Crate"}
    end
    local PurchaseQuantity = 1
    local ItemDropdown = nil
    ShopItem:AddInput({
        Title = "Purchase Quantity",
        Content = "Amount To Buy Item",
        Value = "1",
        Callback = function(value)
            local num = tonumber(value)
            if num then
                PurchaseQuantity = num
            end
        end
    })
    ShopItem:AddDropdown({
        Title = "Select an Item",
        Content = "Choose an item from the shop to purchase.",
        Options = itemNames,
        Multi = false,
        Default = nil,
        Callback = function(value)
            ItemDropdown = value
        end
    })
    ShopItem:AddButton({
        Title = "Buy Selected Item",
        Content = "Theoretical maximum",
        Callback = function()
            if not ItemDropdown then return end
            task.spawn(function()
                local item = ItemDropdown
                local amount = tonumber(PurchaseQuantity) or 1
                for i = 1, amount do
                    task.spawn(function()
                        pcall(function()
                            purchase:FireServer(item, "Item", nil, 1)
                        end)
                    end)
                    if i % 20 == 0 then
                        task.wait(0.01)
                    end
                end
            end)
        end
    })
    ShopItem:AddSeperator({
        Title = 'Black Market',
    })
    local hud = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("hud")
    local safezone = hud:WaitForChild("safezone")
    local BlackMarketGui = safezone:WaitForChild("BlackMarket")
    local ListFrame = BlackMarketGui:WaitForChild("List")
    local PurchaseRemote = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RE/BlackMarket/Purchase")
    local AutoBM = {
        Enabled = false,
        TargetItem = nil,
        Items = {},
        ItemIDs = {},
        DropdownUI = nil
    }
    local function RefreshItemList()
        AutoBM.Items = {}
        AutoBM.ItemIDs = {}
        for _, child in ipairs(ListFrame:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChild("ItemPreview") then
                local titleLabel = child.ItemPreview:FindFirstChild("ItemHeader")
                    and child.ItemPreview.ItemHeader:FindFirstChild("ItemTitle")
                if titleLabel then
                    local displayName = titleLabel.Text
                    table.insert(AutoBM.Items, displayName)
                    AutoBM.ItemIDs[displayName] = child.Name
                end
            end
        end
        if #AutoBM.Items == 0 then
            table.insert(AutoBM.Items, "No items found")
        end
        if AutoBM.DropdownUI then
            pcall(function()
                if AutoBM.DropdownUI.SetValues then
                    AutoBM.DropdownUI:SetValues(AutoBM.Items)
                elseif AutoBM.DropdownUI.SetOptions then
                    AutoBM.DropdownUI:SetOptions(AutoBM.Items)
                elseif AutoBM.DropdownUI.Refresh then
                    AutoBM.DropdownUI:Refresh(AutoBM.Items)
                end
            end)
        end
    end
    AutoBM.DropdownUI = ShopItem:AddDropdown({
        Title = "Select Item Black Market",
        Options = AutoBM.Items,
        Multi = false,
        Value = nil,
        Callback = function(value)
            if value and AutoBM.ItemIDs[value] then
                AutoBM.TargetItem = value
            end
        end
    })
    ShopItem:AddButton({
        Title = "Refresh Item List Black Market",
        Callback = function()
            RefreshItemList()
        end
    })
    ShopItem:AddToggle({
        Title = "Auto Buy Selected Item Black Market",
        Content = "Automatically buy selected item repeatedly",
        Default = false,
        Callback = function(state)
            AutoBM.Enabled = state
            if state then
                task.spawn(function()
                    while AutoBM.Enabled do
                        if AutoBM.TargetItem and AutoBM.ItemIDs[AutoBM.TargetItem] then
                            local uuid = AutoBM.ItemIDs[AutoBM.TargetItem]
                            pcall(function()
                                PurchaseRemote:FireServer(uuid)
                            end)
                            task.wait(1)
                        else
                            task.wait(0.5)
                        end
                    end
                end)
            end
        end
    })
    ShopItem:AddToggle({
        Title = "Auto Buy Carrot",
        Default = _G.Config.AutoBuyCarrot or false,
        Callback = function(state)
            _G.Config.AutoBuyCarrot = state
            if state then
                task.spawn(function()
                    while _G.Config.AutoBuyCarrot do
                        pcall(function()
                            local char = LocalPlayer.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = CFrame.new(266, 147, -146)
                            end
                            task.wait(0.2)
                            local args = { buffer.fromstring("h\000\006Carrot") }
                            ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })
    local rodNames = {}
    local successRods, rodsModule = pcall(function()
        return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("modules"):WaitForChild("library"):WaitForChild("rods"))
    end)
    if successRods and rodsModule then
        local rodsTable = rodsModule.Rods or rodsModule
        if typeof(rodsTable) == "table" then
            for rodName in pairs(rodsTable) do
                table.insert(rodNames, rodName)
            end
            table.sort(rodNames)
        end
    end
    local selectedTPRod = nil
    ShopRod:AddDropdown({
        Title = "Select Rod (TP Method)",
        Options = rodNames,
        Multi = false,
        Callback = function(v)
            selectedTPRod = v
        end
    })
    ShopRod:AddButton({
        Title = "Buy Selected Rod (TP Method)",
        Callback = function()
            if not selectedTPRod then return end
            task.spawn(function()
                local AutoBuyRod = getMod("AutoBuyRod")
                if AutoBuyRod and AutoBuyRod.BuyRodTP then
                    AutoBuyRod.BuyRodTP(selectedTPRod)
                end
            end)
        end
    })
    ShopRod:AddToggle({
        Title = "Auto Buy All Rods (TP Method)",
        Content = "Automatically teleports to buy all available rods",
        Default = _G.Config.AutoBuyAllRods or false,
        Callback = function(state)
            _G.Config.AutoBuyAllRods = state
            if state then
                task.spawn(function()
                    local AutoBuyRod = getMod("AutoBuyRod")
                    if AutoBuyRod and AutoBuyRod.StartLoop then
                        AutoBuyRod.StartLoop()
                    end
                end)
            end
        end
    })
    local function FireProximity(proximity)
        if proximity and proximity:IsA("ProximityPrompt") and proximity.Enabled then
            pcall(function()
                if fireproximityprompt then
                    fireproximityprompt(proximity)
                else
                    local camera = workspace.CurrentCamera
                    if camera then
                        local targetPos = nil
                        if proximity.Parent:IsA("Attachment") then
                            targetPos = proximity.Parent.WorldPosition
                        elseif proximity.Parent:IsA("BasePart") then
                            targetPos = proximity.Parent.Position
                        end
                        if targetPos then
                            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPos)
                            task.wait(0.1)
                        end
                    end
                    proximity:InputHoldBegin()
                    proximity.HoldDuration = 0
                    proximity:InputHoldEnd()
                end
            end)
        end
    end

    Merlin:AddButton({
        Title = "🔍 Open Dialog & Node Tracker",
        Description = "Track Node ID & Choice when talking to Merlin/NPC",
        Callback = function()
            pcall(function()
                if readfile and isfile and isfile("ShielDTeam/NewFish5_Source/TrackDialog.lua") then
                    loadstring(readfile("ShielDTeam/NewFish5_Source/TrackDialog.lua"))()
                elseif game and game.HttpGet then
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/KAN-FISCH/FischTes/refs/heads/main/NewFish5_Source/TrackDialog.lua"))()
                end
            end)
        end
    })

    local dynamicMerlin = {
        relic = { startNode = 2, startChoice = 1, buyNode = 11, buyChoice = 1 },
        luck  = { startNode = 2, startChoice = 2, buyNode = 9,  buyChoice = 1 },
        lure  = { startNode = 2, startChoice = 2, buyNode = 10, buyChoice = 1 },
        xp    = { startNode = 2, startChoice = 2, buyNode = 7,  buyChoice = 1 },
        chasm = { startNode = 2, startChoice = 3, buyNode = 3,  buyChoice = 1 },
    }

    local function parseMerlinDialogTree(npc, u18, u19)
        if not npc or not string.find(tostring(npc):lower(), "merlin") then return end
        if not u19 or type(u19.dialog) ~= "table" then return end
        local dialog = u19.dialog
        local menuNodeIdx = 2
        for nIdx, nData in ipairs(dialog) do
            if nData.choices and #nData.choices >= 2 then
                for cIdx, cData in ipairs(nData.choices) do
                    local tLower = tostring(cData.text):lower()
                    if string.find(tLower, "power") or string.find(tLower, "relic") then
                        dynamicMerlin.relic.startNode = nIdx
                        dynamicMerlin.relic.startChoice = cIdx
                        menuNodeIdx = nIdx
                    elseif string.find(tLower, "shop") then
                        dynamicMerlin.luck.startNode = nIdx
                        dynamicMerlin.luck.startChoice = cIdx
                        dynamicMerlin.lure.startNode = nIdx
                        dynamicMerlin.lure.startChoice = cIdx
                        dynamicMerlin.xp.startNode = nIdx
                        dynamicMerlin.xp.startChoice = cIdx
                    elseif string.find(tLower, "chasm") then
                        dynamicMerlin.chasm.startNode = nIdx
                        dynamicMerlin.chasm.startChoice = cIdx
                    end
                end
            end
        end
        for nIdx, nData in ipairs(dialog) do
            local textLower = tostring(nData.text or ""):lower()
            if nData.choices then
                for cIdx, cData in ipairs(nData.choices) do
                    local choiceTextLower = tostring(cData.text or ""):lower()
                    local combined = textLower .. " " .. choiceTextLower
                    if string.find(combined, "luck") then
                        dynamicMerlin.luck.buyNode = nIdx
                        dynamicMerlin.luck.buyChoice = cIdx
                    elseif string.find(combined, "lure") then
                        dynamicMerlin.lure.buyNode = nIdx
                        dynamicMerlin.lure.buyChoice = cIdx
                    elseif string.find(combined, "xp") or string.find(combined, "exp") or string.find(combined, "experience") then
                        dynamicMerlin.xp.buyNode = nIdx
                        dynamicMerlin.xp.buyChoice = cIdx
                    elseif string.find(combined, "relic") or string.find(combined, "power") or string.find(combined, "twisted") then
                        if nIdx ~= menuNodeIdx then
                            dynamicMerlin.relic.buyNode = nIdx
                            dynamicMerlin.relic.buyChoice = cIdx
                        end
                    end
                end
            end
        end
        print("[Shop/Merlin] Dynamic nodes resolved | Relic:", dynamicMerlin.relic.buyNode, "| Luck:", dynamicMerlin.luck.buyNode, "| Lure:", dynamicMerlin.lure.buyNode, "| XP:", dynamicMerlin.xp.buyNode)
    end

    pcall(function()
        local events = ReplicatedStorage:WaitForChild("events", 5)
        if events then
            if events:FindFirstChild("dialogstart") then
                events.dialogstart.OnClientEvent:Connect(parseMerlinDialogTree)
            end
            if events:FindFirstChild("clientdialog") then
                events.clientdialog.Event:Connect(parseMerlinDialogTree)
            end
        end
    end)

    local function triggerMerlinProximity()
        pcall(function()
            local npcs = workspace:FindFirstChild("world") and workspace.world:FindFirstChild("npcs")
            local npcMerlin = npcs and npcs:FindFirstChild("Merlin")
            local prompt = npcMerlin and npcMerlin:FindFirstChild("ProximityPrompt")
            if prompt then
                FireProximity(prompt)
            end
        end)
    end

    local merlinOptions = {"1", "2", "5", "10", "25", "50"}
    local selectedMerlinOpt = 1

    local function invokeDynamicMerlinBuy(itemKey, amountOpt)
        local countMap = {1, 2, 5, 10, 25, 50}
        local actualCount = 1
        local choiceIdx = 1

        if type(amountOpt) == "number" then
            if amountOpt >= 1 and amountOpt <= #countMap then
                actualCount = countMap[amountOpt]
                choiceIdx = amountOpt
            else
                actualCount = amountOpt
                choiceIdx = amountOpt
            end
        end

        local bought = false
        -- Strategy 3: RF/DialogInteract RemoteFunction
        pcall(function()
            local DialogInteract = nil
            pcall(function()
                local Net = require(ReplicatedStorage.packages.Net)
                DialogInteract = Net:RemoteFunction("DialogInteract")
            end)
            if not DialogInteract then
                DialogInteract = ReplicatedStorage:FindFirstChild("packages")
                    and ReplicatedStorage.packages:FindFirstChild("Net")
                    and ReplicatedStorage.packages.Net:FindFirstChild("RF/DialogInteract")
            end
            if DialogInteract then
                local target = dynamicMerlin[itemKey] or {}
                if target.startNode and target.startChoice then
                    pcall(function() DialogInteract:InvokeServer(target.startNode, target.startChoice) end)
                    task.wait(0.05)
                else
                    local startChoice = (itemKey == "relic" and 1 or 2)
                    pcall(function() DialogInteract:InvokeServer(2, startChoice) end)
                    task.wait(0.05)
                end

                local buyNode = target.buyNode
                if not buyNode then
                    if itemKey == "relic" then buyNode = 11
                    elseif itemKey == "luck" then buyNode = 9
                    elseif itemKey == "lure" then buyNode = 10
                    elseif itemKey == "xp" then buyNode = 7
                    end
                end

                if buyNode then
                    pcall(function() DialogInteract:InvokeServer(buyNode, choiceIdx) end)
                end

                if itemKey == "relic" and buyNode ~= 3 then
                    pcall(function() DialogInteract:InvokeServer(3, choiceIdx) end)
                end
            end
        end)
    end

    Merlin:AddDropdown({
        Title = "Relic Buy Amount",
        Options = merlinOptions,
        Default = "1",
        Callback = function(v)
            for i, option in ipairs(merlinOptions) do
                if option == v then
                    selectedMerlinOpt = i
                    break
                end
            end
        end
    })

    Merlin:AddButton({
        Title = "⚡ Buy Relic Once",
        Description = "Purchase Enchant Relic(s) using selected amount",
        Callback = function()
            triggerMerlinProximity()
            invokeDynamicMerlinBuy("relic", selectedMerlinOpt)
        end
    })

    Merlin:AddToggle({
        Title = "Auto Buy Relic (Spam)",
        Default = _G.Config.AutoBuyMerlin or false,
        Callback = function(state)
            _G.Config.AutoBuyMerlin = state
            if state then
                task.spawn(function()
                    triggerMerlinProximity()
                    while _G.Config.AutoBuyMerlin do
                        invokeDynamicMerlinBuy("relic", selectedMerlinOpt)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })

    local MerlinBuffs = {
        {Title = "Auto Buy - Temporary Luck Boost", Key = "luck"},
        {Title = "Auto Buy - Temporary Lure Boost", Key = "lure"},
        {Title = "Auto Buy - Temporary XP Boost",   Key = "xp"},
        {Title = "Auto Buy - Twisted Relic",       Key = "relic"},
    }

    for _, item in ipairs(MerlinBuffs) do
        local configKey = "AutoBuyMerlin_" .. item.Key
        Merlin:AddToggle({
            Title = item.Title,
            Default = _G.Config[configKey] or false,
            Callback = function(state)
                _G.Config[configKey] = state
                if state then
                    task.spawn(function()
                        triggerMerlinProximity()
                        invokeDynamicMerlinBuy(item.Key, 1)
                        while _G.Config[configKey] do
                            task.wait(30 * 60)
                            if not _G.Config[configKey] then break end
                            invokeDynamicMerlinBuy(item.Key, 1)
                        end
                    end)
                end
            end
        })
    end
end
return Init