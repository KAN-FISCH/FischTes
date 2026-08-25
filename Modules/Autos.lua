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
local function Init(AutosCollect, AutosQuest, AutosJack, AutosFavorit, AutosAppraise, AutoAppraise, AutoEnchant, Collect, AutosSection, AuraSection, AutoJetskiSection, FoodSection)
    local DataController = require(ReplicatedStorage:WaitForChild("client"):WaitForChild("legacyControllers"):WaitForChild("DataController"))
    local InventoryController = nil
    pcall(function()
        InventoryController = require(ReplicatedStorage.client.legacyControllers.InventoryController)
    end)
    local function FireProximity(proximity)
        if proximity:IsA("ProximityPrompt") and proximity.Enabled then
            pcall(function()
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
            end)
            proximity:InputHoldBegin()
            proximity.HoldDuration = 0
            proximity:InputHoldEnd()
        end
    end
    local function getEquippedItemId()
        if InventoryController and InventoryController.EquippedItemId then
            return InventoryController.EquippedItemId
        end
        local char = LocalPlayer.Character
        if not char then return nil end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return nil end
        local link = tool:FindFirstChild("link")
        return link and link.Value or nil
    end
    local function ensureToolEquipped(itemId)
        if not itemId then return nil end
        local char = LocalPlayer.Character
        if not char then return nil end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        local equippedTool = char:FindFirstChildOfClass("Tool")
        if equippedTool then
            local link = equippedTool:FindFirstChild("link")
            if link and link.Value == itemId then
                return equippedTool
            end
        end
        local targetTool = nil
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then
                local link = child:FindFirstChild("link")
                if link and link.Value == itemId then
                    targetTool = child
                    break
                end
            end
        end
        if not targetTool then
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if backpack then
                for _, child in ipairs(backpack:GetChildren()) do
                    if child:IsA("Tool") then
                        local link = child:FindFirstChild("link")
                        if link and link.Value == itemId then
                            targetTool = child
                            break
                        end
                    end
                end
            end
        end
        if targetTool and targetTool.Parent ~= char then
            humanoid:EquipTool(targetTool)
            local t = 0
            while targetTool.Parent ~= char and t < 0.5 do
                task.wait(0.05)
                t = t + 0.05
            end
        end
        return targetTool
    end
    local fishLib = nil
    pcall(function()
        local modules = ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("modules")
        local library = modules and modules:FindFirstChild("library")
        if library and library:FindFirstChild("fish") then
            fishLib = require(library.fish)
        end
    end)
    local function notifyAppraise(title, text, duration)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = title or "Auto Appraise",
                Text = text or "",
                Duration = duration or 3
            })
        end)
        print(string.format("[%s] %s", tostring(title), tostring(text)))
    end
    local function checkItemMatchesKeywords(itemId, keywords)
        if not keywords or #keywords == 0 then return false, nil, nil, "No keywords" end
        local lowerKeywords = {}
        for _, kw in ipairs(keywords) do
            table.insert(lowerKeywords, string.lower(kw))
        end
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool or (itemId and tool:FindFirstChild("link") and tool.link.Value ~= itemId) then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp and itemId then
                for _, bpt in ipairs(bp:GetChildren()) do
                    if bpt:IsA("Tool") and bpt:FindFirstChild("link") and bpt.link.Value == itemId then
                        tool = bpt
                        break
                    end
                end
            end
        end
        local itemData = nil
        pcall(function()
            if tool and InventoryController and InventoryController.GetItemFromLink then
                itemData = InventoryController:GetItemFromLink(tool)
            end
            if not itemData and InventoryController and InventoryController.EquippedItem then
                itemData = InventoryController.EquippedItem
            end
            if not itemData and DataController and DataController.InventoryReplicator then
                local linkVal = (tool and tool:FindFirstChild("link") and tool.link.Value) or itemId
                if linkVal then
                    itemData = DataController.InventoryReplicator:TryIndex({ "Inventory", linkVal })
                end
            end
        end)
        local debugInfo = ""
        if itemData and itemData.sub then
            local sub = itemData.sub
            local mutText = tostring(sub.Mutation or "None")
            local wText = tostring(sub.Weight or sub.weight or "0")
            debugInfo = string.format("Mut: %s | W: %s", mutText, wText)
            for subKey, subVal in pairs(sub) do
                local valStr = tostring(subVal):lower()
                for _, kw in ipairs(lowerKeywords) do
                    if kw == "shiny" and sub.Shiny == true then
                        return true, kw, itemData.name or (tool and tool.Name) or "Item", debugInfo
                    end
                    if kw == "sparkling" and sub.Sparkling == true then
                        return true, kw, itemData.name or (tool and tool.Name) or "Item", debugInfo
                    end
                    if valStr == kw or string.find(valStr, kw, 1, true) then
                        return true, kw, itemData.name or (tool and tool.Name) or "Item", debugInfo
                    end
                end
            end
            local fishName = itemData.name or (tool and tool.Name)
            if fishName and fishLib and fishLib[fishName] then
                local fishInfo = fishLib[fishName]
                local weight = tonumber(sub.Weight or sub.weight)
                if weight and fishInfo.WeightPool and fishInfo.WeightPool[2] then
                    local maxW = fishInfo.WeightPool[2]
                    for _, kw in ipairs(lowerKeywords) do
                        if kw == "big" and weight >= (maxW * 0.75) then
                            return true, "Big", fishName, debugInfo
                        end
                        if kw == "giant" and weight >= (maxW * 0.95) then
                            return true, "Giant", fishName, debugInfo
                        end
                    end
                end
            end
        end
        if tool then
            local tNameLower = tool.Name:lower()
            for _, kw in ipairs(lowerKeywords) do
                if string.find(tNameLower, kw, 1, true) then
                    return true, kw, tool.Name, debugInfo ~= "" and debugInfo or tool.Name
                end
            end
            for _, attrVal in pairs(tool:GetAttributes()) do
                local valStr = tostring(attrVal):lower()
                for _, kw in ipairs(lowerKeywords) do
                    if valStr == kw or string.find(valStr, kw, 1, true) then
                        return true, kw, tool.Name, debugInfo ~= "" and debugInfo or tool.Name
                    end
                end
            end
        end
        if itemData and itemData.name then
            local nameLower = tostring(itemData.name):lower()
            for _, kw in ipairs(lowerKeywords) do
                if string.find(nameLower, kw, 1, true) then
                    return true, kw, itemData.name, debugInfo ~= "" and debugInfo or itemData.name
                end
            end
        end
        return false, nil, nil, debugInfo
    end
    local function checkEquippedMatchesKeywords(keywords)
        return checkItemMatchesKeywords(nil, keywords)
    end
    local function getEquippedItemData(itemId)
        if not itemId then
            itemId = getEquippedItemId()
        end
        if not itemId then return nil end
        local inventory = nil
        pcall(function()
            if DataController.InventoryReplicator then
                inventory = DataController.InventoryReplicator:Index({"Inventory"})
            else
                inventory = DataController.fetch("Inventory")
            end
        end)
        if not inventory then return nil end
        local itemData = inventory[itemId]
        if not itemData then return nil end
        return {
            Mutation = itemData.sub and itemData.sub.Mutation,
            Weight = itemData.sub and itemData.sub.Weight,
            Shiny = itemData.sub and itemData.sub.Shiny,
            Sparkling = itemData.sub and itemData.sub.Sparkling
        }
    end
    local function normalizeKeywords(raw)
        local result = {}
        if type(raw) == "table" then
            for k, v in pairs(raw) do
                if type(k) == "string" and v == true then
                    table.insert(result, k)
                elseif type(k) == "number" and type(v) == "string" then
                    table.insert(result, v)
                end
            end
        elseif type(raw) == "string" and raw ~= "" then
            table.insert(result, raw)
        end
        return result
    end
    local dynamicAppraiseNodes = {
        talkNode = 1,
        talkChoice = 1,
        confirmNode = 3,
        confirmChoice = 1
    }
    pcall(function()
        local events = ReplicatedStorage:WaitForChild("events", 5)
        local function onDialogReceived(u17, u18, u19)
            if not u19 or not u19.dialog then return end
            local npc = (typeof(u17) == "table" and u17.npc and u17.npc.Name) or (u18 and u18.Parent and u18.Parent.Name) or ""
            if string.find(npc:lower(), "appraise") then
                for nodeIdx, nodeData in ipairs(u19.dialog) do
                    if nodeData.choices then
                        for cIdx, c in ipairs(nodeData.choices) do
                            local text = ((typeof(c) == "table" and c.text) or tostring(c)):lower()
                            if string.find(text, "appraise") then
                                dynamicAppraiseNodes.talkNode = nodeIdx
                                dynamicAppraiseNodes.talkChoice = cIdx
                                if typeof(c) == "table" and c.nextline then
                                    dynamicAppraiseNodes.confirmNode = c.nextline
                                    dynamicAppraiseNodes.confirmChoice = 1
                                end
                            elseif text == "yes!" or string.find(text, "yes") then
                                dynamicAppraiseNodes.confirmNode = nodeIdx
                                dynamicAppraiseNodes.confirmChoice = cIdx
                            end
                        end
                    end
                end
            end
        end
        if events and events:FindFirstChild("dialogstart") then
            events.dialogstart.OnClientEvent:Connect(onDialogReceived)
        end
        if events and events:FindFirstChild("clientdialog") then
            events.clientdialog.Event:Connect(onDialogReceived)
        end
    end)
    local function invokeDynamicAppraise(DialogInteract, fallbackNode)
        local cNode = dynamicAppraiseNodes.confirmNode or fallbackNode or 3
        pcall(function()
            DialogInteract:InvokeServer(dynamicAppraiseNodes.talkNode, dynamicAppraiseNodes.talkChoice)
            DialogInteract:InvokeServer(cNode, dynamicAppraiseNodes.confirmChoice or 1)
        end)
    end
    local selectAppraise = {}
    local selectAppraise1 = {}
    local selectedAppraiserLocation = "Appraiser"
    local Appraise = false
    local appraiseOptions = {
        "Mourned","Fallen","Coral","Sweet","Spooky","Frightful","Vined","Poisoned",
        "Shrouded","Spirit","Beachy","Popsicle","Summer","Mythical","Greedy",
        "Abyssal","Fossilized","Lunar","Midas","Sparkling","Shiny","Glossy",
        "Silver","Mosaic","Hexed","Electric","Crimson","Festive","Jolly",
        "Scorched","Darkened","Translucent","Frozen","Negative","Albino",
        "Amber","Big","Giant"
    }
    AutoAppraise:AddDropdown({
        Title = "Select Multi Appraise",
        Content = "Select a multi appraise",
        Options = appraiseOptions,
        Multi = true,
        Callback = function(v)
            selectAppraise = v or {}
        end
    })
    AutoAppraise:AddDropdown({
        Title = "Select Appraiser Location",
        Content = "Choose which appraiser to use",
        Options = {"Appraiser", "Drowned Appraiser"},
        Multi = false,
        Default = "Appraiser",
        Callback = function(v)
            selectedAppraiserLocation = v
        end
    })
    local appraiseOnHeldToggle
    appraiseOnHeldToggle = AutoAppraise:AddToggle({
        Title = "Auto Appraise on held",
        Default = false,
        Callback = function(value)
            Appraise = value
            if not value then return end
            task.spawn(function()
                local DialogInteract = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/DialogInteract")
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart")
                local savedPosition = hrp.CFrame
                local keywords = normalizeKeywords(selectAppraise)
                if #keywords == 0 then
                    print("[AutoAppraise] Tidak ada keyword dipilih")
                    Appraise = false
                    appraiseOnHeldToggle:SetValue(false)
                    return
                end
                local targetTool = char:FindFirstChildOfClass("Tool")
                local targetItemId = getEquippedItemId()
                if not targetItemId or not targetTool then
                    print("[AutoAppraise] Silakan lengkapi item terlebih dahulu!")
                    Appraise = false
                    appraiseOnHeldToggle:SetValue(false)
                    return
                end
                local alreadyMatch, kw, itemName = checkItemMatchesKeywords(targetItemId, keywords)
                if alreadyMatch then
                    print("[AutoAppraise] Item sudah match:", itemName, "| keyword:", kw)
                    Appraise = false
                    appraiseOnHeldToggle:SetValue(false)
                    return
                end
                local playerClone = char:Clone()
                playerClone.Name = "PlayerClone_BYPASS"
                for _, obj in ipairs(playerClone:GetDescendants()) do
                    if obj:IsA("Script") or obj:IsA("LocalScript") then obj:Destroy() end
                end
                if playerClone:FindFirstChild("HumanoidRootPart") then
                    playerClone.HumanoidRootPart.CFrame = savedPosition
                    playerClone.HumanoidRootPart.Anchored = true
                end
                playerClone.Parent = workspace
                local camera = workspace.CurrentCamera
                local origCamSubject = camera.CameraSubject
                local origCamType = camera.CameraType
                if playerClone:FindFirstChild("Humanoid") then
                    if selectedAppraiserLocation ~= "Drowned Appraiser" then
                        camera.CameraSubject = playerClone.Humanoid
                        camera.CameraType = Enum.CameraType.Custom
                    end
                end
                task.wait(0.2)
                local appraiserPosition, appraiserName
                if selectedAppraiserLocation == "Drowned Appraiser" then
                    appraiserPosition = CFrame.new(3170, -1099, 775)
                    appraiserName = "DrownedAppraiser"
                else
                    appraiserPosition = CFrame.new(
                        448.786102, 150.529297, 206.834045,
                        -0.617013216, 6.03e-08, -0.786952794,
                        5.42e-08, 1, 3.40e-08,
                        0.786952794, -2.16e-08, -0.617013216
                    )
                    appraiserName = "Appraiser"
                end
                hrp.CFrame = appraiserPosition
                task.wait(3)
                local originalAppraiser = workspace.world.npcs:WaitForChild(appraiserName, 10)
                if not originalAppraiser then
                    print("[AutoAppraise] Appraiser tidak ditemukan")
                    playerClone:Destroy()
                    hrp.CFrame = savedPosition
                    camera.CameraSubject = origCamSubject
                    camera.CameraType = origCamType
                    Appraise = false
                    appraiseOnHeldToggle:SetValue(false)
                    return
                end
                local appraiserHRP = originalAppraiser:WaitForChild("HumanoidRootPart", 3)
                local proximityPrompt = originalAppraiser:FindFirstChild("ProximityPrompt")
                if proximityPrompt then proximityPrompt.Enabled = true end
                if selectedAppraiserLocation == "Drowned Appraiser" then
                    local other = workspace.world.npcs:FindFirstChild("Appraiser")
                    if other and other:FindFirstChild("ProximityPrompt") then other.ProximityPrompt.Enabled = false end
                else
                    local other = workspace.world.npcs:FindFirstChild("DrownedAppraiser")
                    if other and other:FindFirstChild("ProximityPrompt") then other.ProximityPrompt.Enabled = false end
                end
                if not appraiserHRP or not proximityPrompt then
                    print("[AutoAppraise] HRP / ProximityPrompt tidak ada")
                    playerClone:Destroy()
                    hrp.CFrame = savedPosition
                    camera.CameraSubject = origCamSubject
                    camera.CameraType = origCamType
                    Appraise = false
                    appraiseOnHeldToggle:SetValue(false)
                    return
                end
                local ppParent = proximityPrompt.Parent
                local targetLook = nil
                if ppParent then
                    if ppParent:IsA("Model") then targetLook = ppParent:GetPivot().Position
                    elseif ppParent:IsA("BasePart") then targetLook = ppParent.Position
                    elseif ppParent:IsA("Attachment") then targetLook = ppParent.WorldPosition
                    end
                end
                if targetLook then
                    if selectedAppraiserLocation ~= "Drowned Appraiser" then
                        camera.CameraType = Enum.CameraType.Scriptable
                        pcall(function()
                            camera.CFrame = CFrame.new(camera.CFrame.Position, targetLook)
                        end)
                        task.wait(1)
                    end
                end
                FireProximity(proximityPrompt)
                task.wait(3)
                local choiceNode = (selectedAppraiserLocation == "Drowned Appraiser") and 6 or 3
                invokeDynamicAppraise(DialogInteract, choiceNode)
                task.wait(0.5)
                local clonedAppraiser = originalAppraiser:Clone()
                clonedAppraiser.Name = "BYPASS_APPRAISER"
                if clonedAppraiser:FindFirstChild("HumanoidRootPart") then
                    clonedAppraiser.HumanoidRootPart.CFrame = appraiserHRP.CFrame
                    clonedAppraiser.HumanoidRootPart.Anchored = true
                end
                clonedAppraiser.Parent = workspace.world.npcs
                task.wait(0.3)
                if selectedAppraiserLocation ~= "Drowned Appraiser" then
                    hrp.CFrame = savedPosition
                    task.wait(0.3)
                    camera.CameraSubject = char.Humanoid
                    camera.CameraType = Enum.CameraType.Custom
                    task.wait(0.2)
                end
                if playerClone and playerClone.Parent then playerClone:Destroy() end
                local targetName = (targetTool and targetTool.Name) or "Item"
                local processedItemIds = {}
                local function findNextSameItem(tName, kwList, processed)
                    local inventory = nil
                    pcall(function()
                        if DataController.InventoryReplicator then
                            inventory = DataController.InventoryReplicator:Index({"Inventory"})
                        else
                            inventory = DataController.fetch("Inventory")
                        end
                    end)
                    if inventory then
                        for itemId, itemData in pairs(inventory) do
                            if type(itemData) == "table" and itemData.name == tName and not processed[itemId] then
                                local match, _, _ = checkItemMatchesKeywords(itemId, kwList)
                                if not match then
                                    return itemId
                                else
                                    processed[itemId] = true
                                end
                            end
                        end
                    end
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        for _, tool in ipairs(backpack:GetChildren()) do
                            if tool:IsA("Tool") and tool.Name == tName then
                                local link = tool:FindFirstChild("link")
                                local itemId = (link and link.Value ~= "") and link.Value or tool.Name
                                if not processed[itemId] then
                                    local match, _, _ = checkItemMatchesKeywords(itemId, kwList)
                                    if not match then
                                        return itemId
                                    else
                                        processed[itemId] = true
                                    end
                                end
                            end
                        end
                    end
                    return nil
                end
                notifyAppraise("Auto Appraise", "Target: " .. table.concat(keywords, ", "), 2)
                local initialMatch, initKw, initName, initDebug = checkItemMatchesKeywords(targetItemId, keywords)
                if initialMatch then
                    notifyAppraise("Auto Appraise", "Item sudah memiliki: " .. tostring(initKw) .. " (" .. tostring(initDebug) .. ")", 4)
                else
                    local choiceNode = (selectedAppraiserLocation == "Drowned Appraiser") and 6 or 3
                    local count = 0
                    while Appraise do
                        count = count + 1
                        invokeDynamicAppraise(DialogInteract, choiceNode)
                        task.wait(0.12)
                        local match, kw, name, debugStr = checkItemMatchesKeywords(targetItemId, keywords)
                        if count % 3 == 0 or match then
                            notifyAppraise("Roll #" .. count, string.format("%s (%s)", tostring(name or targetName), tostring(debugStr)), 1.5)
                        end
                        if match then
                            notifyAppraise("🎉 SUCCESS!", string.format("Got %s on %s! (%s)", tostring(kw), tostring(name), tostring(debugStr)), 5)
                            break
                        end
                    end
                end
                if clonedAppraiser and clonedAppraiser.Parent then
                    clonedAppraiser:Destroy()
                end
                pcall(function()
                    if selectedAppraiserLocation == "Drowned Appraiser" then
                        hrp.CFrame = savedPosition
                    end
                    camera.CameraSubject = origCamSubject
                    camera.CameraType = origCamType
                end)
                Appraise = false
                appraiseOnHeldToggle:SetValue(false)
            end)
        end
    })
    local function buildAppraiseOptions()
        local opts = {}
        local inventory = nil
        pcall(function()
            if DataController.InventoryReplicator then
                inventory = DataController.InventoryReplicator:Index({"Inventory"})
            else
                inventory = DataController.fetch("Inventory")
            end
        end)
        if not inventory then return opts end
        for k, v in pairs(inventory) do
            if type(v) == "table" and v.name then
                table.insert(opts, {Display = v.name .. " (" .. tostring(k):sub(1,5) .. ")", Value = k})
            end
        end
        return opts
    end
    local function refreshAppraiseDropdown(dd)
        local opts = buildAppraiseOptions()
        local values = {}
        for _, opt in ipairs(opts) do
            table.insert(values, opt.Display)
        end
        pcall(function()
            if dd.SetValues then
                dd:SetValues(values)
            elseif dd.SetOptions then
                dd:SetOptions(values)
            elseif dd.Refresh then
                dd:Refresh(values)
            end
        end)
        dd.ItemMap = {}
        for _, opt in ipairs(opts) do
            dd.ItemMap[opt.Display] = opt.Value
        end
    end
    local dropdown
    dropdown = AutoAppraise:AddDropdown({
        Title = "Select Fisch Appraise",
        Multi = true,
        Options = {},
        Callback = function(v)
            if type(v) == "table" then
                selectAppraise1 = {}
                for _, picked in ipairs(v) do
                    table.insert(selectAppraise1, dropdown.ItemMap[picked] or picked)
                end
            else
                selectAppraise1 = dropdown.ItemMap[v] or v
            end
        end
    })
    refreshAppraiseDropdown(dropdown)
    AutoAppraise:AddSeperator({
        Title = 'Auto Appraise All Selected',
    })
    local appraise
    appraise = AutoAppraise:AddToggle({
        Title = "Auto Appraise All Selected Fisch",
        Default = false,
        Callback = function(value)
            Appraise = value
            if not value then return end
            task.spawn(function()
                local DialogInteract = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/DialogInteract")
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart")
                local savedPosition = hrp.CFrame
                local backpack = LocalPlayer:WaitForChild("Backpack")
                local keywords = normalizeKeywords(selectAppraise)
                if #keywords == 0 then
                    print("[AutoAppraise All] Tidak ada mutation terpilih")
                    Appraise = false
                    appraise:SetValue(false)
                    return
                end
                if not selectAppraise1 or #selectAppraise1 == 0 then
                    print("[AutoAppraise All] Tidak ada ikan target terpilih")
                    Appraise = false
                    appraise:SetValue(false)
                    return
                end
                local playerClone = char:Clone()
                playerClone.Name = "PlayerClone_BYPASS_ALL"
                for _, obj in ipairs(playerClone:GetDescendants()) do
                    if obj:IsA("Script") or obj:IsA("LocalScript") then obj:Destroy() end
                end
                if playerClone:FindFirstChild("HumanoidRootPart") then
                    playerClone.HumanoidRootPart.CFrame = savedPosition
                    playerClone.HumanoidRootPart.Anchored = true
                end
                playerClone.Parent = workspace
                local camera = workspace.CurrentCamera
                local origCamSubject = camera.CameraSubject
                local origCamType = camera.CameraType
                if playerClone:FindFirstChild("Humanoid") then
                    if selectedAppraiserLocation ~= "Drowned Appraiser" then
                        camera.CameraSubject = playerClone.Humanoid
                        camera.CameraType = Enum.CameraType.Custom
                    end
                end
                task.wait(0.2)
                local appraiserPosition, appraiserName
                if selectedAppraiserLocation == "Drowned Appraiser" then
                    appraiserPosition = CFrame.new(3170, -1099, 775)
                    appraiserName = "DrownedAppraiser"
                else
                    appraiserPosition = CFrame.new(
                        448.786102, 150.529297, 206.834045,
                        -0.617013216, 6.03e-08, -0.786952794,
                        5.42e-08, 1, 3.40e-08,
                        0.786952794, -2.16e-08, -0.617013216
                    )
                    appraiserName = "Appraiser"
                end
                hrp.CFrame = appraiserPosition
                task.wait(3)
                local originalAppraiser = workspace.world.npcs:WaitForChild(appraiserName, 10)
                if not originalAppraiser then
                    playerClone:Destroy()
                    hrp.CFrame = savedPosition
                    camera.CameraSubject = origCamSubject
                    camera.CameraType = origCamType
                    Appraise = false
                    appraise:SetValue(false)
                    return
                end
                local appraiserHRP = originalAppraiser:WaitForChild("HumanoidRootPart", 3)
                local proximityPrompt = originalAppraiser:FindFirstChild("ProximityPrompt")
                if proximityPrompt then proximityPrompt.Enabled = true end
                if selectedAppraiserLocation == "Drowned Appraiser" then
                    local other = workspace.world.npcs:FindFirstChild("Appraiser")
                    if other and other:FindFirstChild("ProximityPrompt") then other.ProximityPrompt.Enabled = false end
                else
                    local other = workspace.world.npcs:FindFirstChild("DrownedAppraiser")
                    if other and other:FindFirstChild("ProximityPrompt") then other.ProximityPrompt.Enabled = false end
                end
                if not appraiserHRP or not proximityPrompt then
                    playerClone:Destroy()
                    hrp.CFrame = savedPosition
                    camera.CameraSubject = origCamSubject
                    camera.CameraType = origCamType
                    Appraise = false
                    appraise:SetValue(false)
                    return
                end
                local ppParent = proximityPrompt.Parent
                local targetLook = nil
                if ppParent then
                    if ppParent:IsA("Model") then targetLook = ppParent:GetPivot().Position
                    elseif ppParent:IsA("BasePart") then targetLook = ppParent.Position
                    elseif ppParent:IsA("Attachment") then targetLook = ppParent.WorldPosition
                    end
                end
                if targetLook then
                    if selectedAppraiserLocation ~= "Drowned Appraiser" then
                        camera.CameraType = Enum.CameraType.Scriptable
                        camera.CFrame = CFrame.new(camera.CFrame.Position, targetLook)
                        task.wait(1)
                    end
                end
                FireProximity(proximityPrompt)
                task.wait(3)
                local choiceNode = (selectedAppraiserLocation == "Drowned Appraiser") and 6 or 3
                invokeDynamicAppraise(DialogInteract, choiceNode)
                task.wait(0.5)
                local clonedAppraiser = originalAppraiser:Clone()
                clonedAppraiser.Name = "BYPASS_APPRAISER_ALL"
                if clonedAppraiser:FindFirstChild("HumanoidRootPart") then
                    clonedAppraiser.HumanoidRootPart.CFrame = appraiserHRP.CFrame
                    clonedAppraiser.HumanoidRootPart.Anchored = true
                end
                clonedAppraiser.Parent = workspace.world.npcs
                task.wait(0.3)
                if selectedAppraiserLocation ~= "Drowned Appraiser" then
                    hrp.CFrame = savedPosition
                    task.wait(0.3)
                    camera.CameraSubject = char.Humanoid
                    camera.CameraType = Enum.CameraType.Custom
                    task.wait(0.2)
                end
                if playerClone and playerClone.Parent then playerClone:Destroy() end
                local toolsToAppraise = {}
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        local matchFish = false
                        for _, fKw in ipairs(selectAppraise1) do
                            if string.find(string.lower(tool.Name), string.lower(fKw), 1, true) then
                                matchFish = true
                                break
                            end
                        end
                        if matchFish then
                            table.insert(toolsToAppraise, tool)
                        end
                    end
                end
                for _, tool in ipairs(toolsToAppraise) do
                    if not Appraise then break end
                    local targetItemId = tool:FindFirstChild("link") and tool.link.Value
                    if targetItemId then
                        ensureToolEquipped(targetItemId)
                        task.wait(0.5)
                        local alreadyMatch, kw, itemName = checkItemMatchesKeywords(targetItemId, keywords)
                        if alreadyMatch then
                            print("[AutoAppraise All] Item", itemName, "sudah memiliki mutation:", kw)
                        else
                            local choiceNode = (selectedAppraiserLocation == "Drowned Appraiser") and 6 or 3
                            local count = 0
                            while Appraise do
                                count = count + 1
                                invokeDynamicAppraise(DialogInteract, choiceNode)
                                task.wait(0.12)
                                local match, kw, name, debugStr = checkItemMatchesKeywords(targetItemId, keywords)
                                if count % 3 == 0 or match then
                                    notifyAppraise("Roll #" .. count, string.format("%s (%s)", tostring(name or itemName), tostring(debugStr)), 1.5)
                                end
                                if match then
                                    notifyAppraise("🎉 SUCCESS!", string.format("Got %s on %s! (%s)", tostring(kw), tostring(name), tostring(debugStr)), 5)
                                    break
                                end
                            end
                            task.wait(0.3)
                        end
                    end
                end
                if clonedAppraiser and clonedAppraiser.Parent then
                    clonedAppraiser:Destroy()
                end
                pcall(function()
                    if selectedAppraiserLocation == "Drowned Appraiser" then
                        hrp.CFrame = savedPosition
                    end
                    camera.CameraSubject = origCamSubject
                    camera.CameraType = origCamType
                end)
                Appraise = false
                appraise:SetValue(false)
            end)
        end
    })
    AutoAppraise:AddButton({
        Title = "Refresh Appraise Dropdown",
        Description = "Refresh the appraise dropdown list.",
        Callback = function()
            refreshAppraiseDropdown(dropdown)
        end
    })
    local whileEnchant = false
    local targetEnc = {}
    local selectedRelic = "Auto (Any Relic)"
    local enchanList = {
        "Abyssal", "Anomalous", "Blessed", "Blessed Song", "Blood Reckoning", "Breezed",
        "Chaotic", "Chronos", "Clever", "Controlled", "Cryogenic", "Divine", "Empowered",
        "Flashline", "Frightful", "Ghastly", "Glittered", "Hasty", "Herculean", "Immortal",
        "Insight", "Invincible", "Keeperbound", "Long", "Lucky", "Lunar", "Momentum",
        "Mutated", "Mystical", "Noir", "Overclocked", "Piercing", "Quality", "Quantum",
        "Resilient", "Scavenger", "Scrapper", "Sea King", "Sea Overlord", "Sea Prince",
        "Solar", "Song of the Deep", "Spectral", "Starlight", "Steady", "Storming",
        "Swift", "Tenacity", "Tryhard", "Unbreakable", "Unforgiving", "Wise", "Wormhole", "Zeus"
    }
    pcall(function()
        local enchantsLib = require(ReplicatedStorage.shared.modules.library.rods.enchants)
        if enchantsLib and enchantsLib.Enchants then
            local list = {}
            for name, _ in pairs(enchantsLib.Enchants) do
                table.insert(list, tostring(name))
            end
            table.sort(list)
            if #list > 0 then
                enchanList = list
            end
        end
    end)
    local function getEquippedRodName()
        local rodName = nil
        pcall(function()
            local SharedDataHelper = require(ReplicatedStorage.shared.modules.SharedDataHelper)
            rodName = SharedDataHelper.readLegacyPathValue(LocalPlayer, { "Stats", "rod" })
        end)
        if not rodName or rodName == "" then
            pcall(function()
                local pStats = workspace:FindFirstChild("PlayerStats") and workspace.PlayerStats:FindFirstChild(LocalPlayer.Name)
                if pStats and pStats:FindFirstChild("T") and pStats.T:FindFirstChild(LocalPlayer.Name) then
                    rodName = pStats.T[LocalPlayer.Name].Stats.rod.Value
                end
            end)
        end
        return rodName
    end
    local function getCurrentRodEnchants()
        local cur = {}
        local rodName = getEquippedRodName()
        if rodName and rodName ~= "" then
            pcall(function()
                local SharedDataHelper = require(ReplicatedStorage.shared.modules.SharedDataHelper)
                local record = SharedDataHelper.indexNewFormat(LocalPlayer, { "Rods", rodName })
                if record then
                    if record.enchant and record.enchant ~= "none" and record.enchant ~= "" then
                        table.insert(cur, tostring(record.enchant))
                    end
                    if record.secondaryEnchant and record.secondaryEnchant ~= "none" and record.secondaryEnchant ~= "" then
                        table.insert(cur, tostring(record.secondaryEnchant))
                    end
                    if record.keeperboundEnchant and record.keeperboundEnchant ~= "" then
                        table.insert(cur, tostring(record.keeperboundEnchant))
                    end
                end
            end)
        end
        if #cur == 0 and rodName then
            pcall(function()
                local hud = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("hud")
                local enchantContainer = hud and hud.safezone.equipment.rods.scroll.safezone[rodName].rod.enchants
                if enchantContainer then
                    for _, v in pairs(enchantContainer:GetChildren()) do
                        if (v:IsA("TextLabel") or v:IsA("TextButton")) and v.Text ~= "" then
                            table.insert(cur, v.Text)
                        end
                    end
                end
            end)
        end
        return cur
    end
    local function hasTargetEnchant()
        if not targetEnc or #targetEnc == 0 or (targetEnc[1] == "None" and #targetEnc == 1) then
            return false
        end
        local curList = getCurrentRodEnchants()
        for _, t in ipairs(targetEnc) do
            local targetLower = string.lower(string.gsub(tostring(t), "%s+", ""))
            for _, c in ipairs(curList) do
                local curLower = string.lower(string.gsub(tostring(c), "%s+", ""))
                if curLower == targetLower or string.find(curLower, targetLower) or string.find(targetLower, curLower) then
                    return true
                end
            end
        end
        return false
    end
    local function findRelicTool()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local relicCandidates = {}
        local function checkItem(tool)
            if tool and tool:IsA("Tool") then
                local tName = tool.Name
                if selectedRelic == "Auto (Any Relic)" then
                    if string.find(tName, "Relic") then
                        table.insert(relicCandidates, tool)
                    end
                else
                    if tName == selectedRelic or string.find(tName, selectedRelic) then
                        table.insert(relicCandidates, tool)
                    end
                end
            end
        end
        if char then
            for _, item in ipairs(char:GetChildren()) do checkItem(item) end
        end
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do checkItem(item) end
        end
        return relicCandidates[1]
    end
    local function bypassEnchantConfirmation()
        pcall(function()
            local Net = require(ReplicatedStorage.packages.Net)
            local confirmRemote = Net:RemoteFunction("Enchant/ConfirmTarget")
            if confirmRemote then
                confirmRemote.OnClientInvoke = function()
                    return true
                end
            end
        end)
        pcall(function()
            local legacyEvents = ReplicatedStorage:FindFirstChild("events")
            local enchantEv = legacyEvents and legacyEvents:FindFirstChild("enchant")
            if enchantEv and enchantEv:IsA("RemoteFunction") then
                enchantEv.OnClientInvoke = function()
                    return true
                end
            end
        end)
    end
    AutoEnchant:AddDropdown({
        Title = "Select Multi Enchant",
        Content = "Select target enchants",
        Options = enchanList,
        Default = {"None"},
        Multi = true,
        Callback = function(v)
            targetEnc = v
        end
    })
    local relicOptions = {"Auto (Any Relic)", "Enchant Relic", "Sovereign Relic", "Abyssal Relic", "Cosmic Relic"}
    AutoEnchant:AddDropdown({
        Title = "Select Relic",
        Content = "Select which relic to use",
        Options = relicOptions,
        Default = "Auto (Any Relic)",
        Callback = function(v)
            selectedRelic = v
        end
    })
    AutoEnchant:AddToggle({
        Title = "Auto Enchant",
        Default = false,
        Callback = function(value)
            whileEnchant = value
            if value then
                task.spawn(function()
                    bypassEnchantConfirmation()
                    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local hrp = char:WaitForChild("HumanoidRootPart", 5)
                    local ALTAR_POS = CFrame.new(1310.5, -799.4, -82.7)
                    if hrp then
                        hrp.CFrame = ALTAR_POS * CFrame.new(0, 0, -5)
                    end
                    while whileEnchant do
                        task.wait(0.5)
                        if not whileEnchant then break end
                        if hasTargetEnchant() then
                            warn("[AutoEnchant] Target enchant achieved! Stopping.")
                            break
                        end
                        local relicTool = findRelicTool()
                        if not relicTool then
                            task.wait(1.5)
                            continue
                        end
                        if hrp and (hrp.Position - ALTAR_POS.Position).Magnitude > 25 then
                            hrp.CFrame = ALTAR_POS * CFrame.new(0, 0, -5)
                            task.wait(0.3)
                        end
                        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                        if humanoid and relicTool.Parent ~= char then
                            humanoid:EquipTool(relicTool)
                            task.wait(0.2)
                        end
                        local invoked = false
                        pcall(function()
                            local Net = require(ReplicatedStorage.packages.Net)
                            local altarRemote = Net:RemoteFunction("EnchantAltar/Interact")
                            if altarRemote then
                                altarRemote:InvokeServer(relicTool.Name)
                                invoked = true
                            end
                        end)
                        if not invoked then
                            pcall(function()
                                local altar = workspace:FindFirstChild("world")
                                    and workspace.world:FindFirstChild("interactables")
                                    and workspace.world.interactables:FindFirstChild("Enchant Altar")
                                local prompt = altar and altar:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt then
                                    fireproximityprompt(prompt)
                                end
                            end)
                        end
                        pcall(function()
                            local hud = LocalPlayer.PlayerGui:FindFirstChild("hud")
                            local safezone = hud and hud:FindFirstChild("safezone")
                            local confirmFrame = safezone and safezone:FindFirstChild("EnchantConfirm")
                            if confirmFrame and confirmFrame.Visible then
                                local btn = confirmFrame:FindFirstChild("enchantButton")
                                if btn then
                                    if getconnections then
                                        for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                        for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                                    end
                                    if firesignal then
                                        firesignal(btn.Activated)
                                        firesignal(btn.MouseButton1Click)
                                    end
                                end
                            end
                        end)
                        task.wait(1.5)
                    end
                end)
            end
        end
    })
    AutosJack:AddButton({
        Title = 'Teleport to Jack Marrow',
        Callback = function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-2826, 215, 1518)
            end
        end,
    })
    AutosJack:AddButton({
        Title = 'Repair Map',
        Callback = function()
            for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                if v.Name == 'Treasure Map' then
                    LocalPlayer.Character.Humanoid:EquipTool(v)
                    pcall(function()
                        workspace.world.npcs['Jack Marrow'].treasure.repairmap:InvokeServer()
                    end)
                end
            end
        end,
    })
    local ANTI_STAFF_ENABLED = true
    local staffRoles = {
        "mod", "admin", "staff", "dev", "founder", "owner", "supervis", "manager",
        "content creator", "Tester", "Tester 2", "management", "executive",
        "president", "chairman", "chairwoman", "chairperson", "director"
    }
    local staffWatchConnection = nil
    local function getStaffRole(player)
        local success, playerRole = pcall(function() return player:GetRoleInGroup(game.CreatorId) end)
        if not success then return {Role = "Unknown", Staff = false} end
        local result = {Role = playerRole, Staff = false}
        local groupSuccess, inGroup = pcall(function() return player:IsInGroup(1200769) end)
        if groupSuccess and inGroup then
            result.Role = "Roblox Employee"
            result.Staff = true
            return result
        end
        for _, role in pairs(staffRoles) do
            if playerRole and string.find(string.lower(playerRole), role) then
                result.Staff = true
                return result
            end
        end
        return result
    end
    local function leaveGame()
        if staffWatchConnection then staffWatchConnection:Disconnect() end
        game:Shutdown()
    end
    local function triggerStaffKick(staffName, staffRole)
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
        local jobId = game.JobId or "Unknown"
        local placeId = game.PlaceId or "Unknown"
        local payload = {
            content = "",
            username = "Staff Alert",
            avatar_url = "https://i.imgur.com/warning.png",
            embeds = {{
                title = "🚨 STAFF DETECTED - KICKED",
                description = string.format("**Server #%s**\n`%s`\n\n**Time:** %s\n**Staff:** %s (%s)\n**Action:** Game Shutdown", string.sub(jobId, 1, 8), jobId, os.date("%H:%M:%S"), staffName, staffRole),
                color = 16711680,
                fields = {
                    { name = "📍 Server Info", value = string.format("**Place ID:** `%s`", placeId), inline = false }
                },
                footer = { text = "Shield Team Security" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
            }}
        }
        local request = (syn and syn.request) or (http and http.request) or request
        if request then
            task.spawn(function()
                local payloadData = {
                    target = "staff",
                    payload = payload,
                    timestamp = os.time() * 1000
                }
                local encryptedData = xorEncrypt(
                    game:GetService("HttpService"):JSONEncode(payloadData),
                    "d811b3a45660f63911dc86d85bab292eaf9f3cc311608b2e8763f933c7783cdf"
                )
                pcall(request, {
                    Url = "https://key.shieldteam.asia/api/key/webhook-proxy",
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = game:GetService("HttpService"):JSONEncode({ data = encryptedData })
                })
            end)
        end
    end
    local function initAntiStaff()
        if not ANTI_STAFF_ENABLED then return end
        if game.CreatorType ~= Enum.CreatorType.Group then return end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local result = getStaffRole(player)
                if result.Staff then
                    triggerStaffKick(player.Name, result.Role)
                    task.wait(2)
                    leaveGame()
                    return
                end
            end
        end
        staffWatchConnection = Players.PlayerAdded:Connect(function(player)
            local result = getStaffRole(player)
            if result.Staff then
                triggerStaffKick(player.Name, result.Role)
                task.wait(2)
                leaveGame()
            end
        end)
    end
    initAntiStaff()
    AutosJack:AddButton({
        Title = 'Collect Treasure',
        Callback = function()
            for _, v in ipairs(workspace:GetDescendants()) do
                if v.ClassName == 'ProximityPrompt' then
                    v.HoldDuration = 0
                end
            end
            for _, v in pairs(workspace.world.chests:GetDescendants()) do
                if v:IsA('Part') and v:FindFirstChild('ChestSetup') then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = v.CFrame
                    for _, prompt in pairs(workspace.world.chests:GetDescendants()) do
                        if prompt.Name == 'ProximityPrompt' then
                            fireproximityprompt(prompt)
                        end
                    end
                    task.wait(1)
                end
            end
        end,
    })
    local Net = ReplicatedStorage:WaitForChild('packages'):WaitForChild('Net')
    local EventAppraiseGui = LocalPlayer.PlayerGui:WaitForChild('EventAppraise')
    local AppraiseUI = EventAppraiseGui.EventAppraise
    local StartAppraise = Net:WaitForChild('RE/EventAppraiseService/StartAppraise')
    local RequestUI = Net:WaitForChild('RE/EventAppraiseService/RequestAppraiseUI')
    local TakeNow = Net:WaitForChild('RE/EventAppraiseService/TakeNow')
    local SelectIndex = Net:WaitForChild('RF/EventAppraiseService/SelectIndex')
    local SelectedTreasure = 'Big'
    local AutoAppraiseActive = false
    local function AutoSelectRow(rowIndex)
        local startSlot = (rowIndex - 1) * 3 + 1
        local endSlot = startSlot + 2
        for slot = startSlot, endSlot do
            local success, result = pcall(function()
                return SelectIndex:InvokeServer(slot)
            end)
            if success and result then
                break
            end
        end
    end
    local function WaitForAppraiseItems(timeout)
        timeout = timeout or 5
        local timer = 0
        repeat
            local ready = true
            for _, child in ipairs(AppraiseUI.List:GetChildren()) do
                local itemName = child:FindFirstChild('ItemName')
                if not itemName or itemName.Text == '' then
                    ready = false
                    break
                end
            end
            if ready and #AppraiseUI.List:GetChildren() > 0 then
                break
            end
            task.wait(0.1)
            timer = timer + 0.1
        until timer >= timeout
    end
    local function CheckMutationsInventory()
        local hotbar = LocalPlayer.PlayerGui:WaitForChild('backpack'):WaitForChild('hotbar')
        local inventory = LocalPlayer.PlayerGui.backpack:WaitForChild('inventory'):WaitForChild('itemContainer')
        local function checkContainer(container)
            for _, child in ipairs(container:GetChildren()) do
                local stroke = child:FindFirstChildOfClass('UIStroke')
                if stroke and stroke.Color == Color3.fromRGB(255, 255, 255) and child:FindFirstChild('ItemName') then
                    local text = child.ItemName.Text
                    if string.find(string.lower(text), string.lower(SelectedTreasure)) then
                        AutoAppraiseActive = false
                        return true
                    end
                end
            end
            return false
        end
        return checkContainer(hotbar) or checkContainer(inventory)
    end
    local function CheckMutationUI(filter)
        WaitForAppraiseItems(1)
        for _, child in ipairs(AppraiseUI.List:GetChildren()) do
            local itemName = child:FindFirstChild('ItemName')
            if itemName and itemName.Text ~= '' then
                if string.find(string.lower(itemName.Text), string.lower(filter)) then
                    AutoAppraiseActive = false
                    return true
                end
            end
        end
        return false
    end
    local function StartAutoAppraise(filter)
        if CheckMutationsInventory() then return end
        RequestUI:FireServer()
        task.wait(0.3)
        StartAppraise:FireServer()
        task.wait(0.5)
        for row = 1, 7 do
            if not AutoAppraiseActive then break end
            AutoSelectRow(row)
            task.wait(0.1)
            if CheckMutationsInventory() then return end
        end
        if not AutoAppraiseActive then return end
        if CheckMutationUI(filter) then return end
        TakeNow:FireServer()
    end
    AutosAppraise:AddDropdown({
        Title = 'Select Appraise Treasure',
        Multi = false,
        Options = { 'Big', 'Giant' },
        Default = 'Big',
        Callback = function(selection)
            SelectedTreasure = selection
        end,
    })
    AutosAppraise:AddToggle({
        Title = 'Auto Treasure Appraise',
        Default = false,
        Callback = function(value)
            AutoAppraiseActive = value
            if value then
                task.spawn(function()
                    while AutoAppraiseActive do
                        StartAutoAppraise(SelectedTreasure)
                        task.wait(1)
                    end
                end)
            end
        end,
    })
    local fishingSpots = {}
    local successSpots, teleZoneMod = pcall(function() return getMod("TeleportZone") end)
    if successSpots and teleZoneMod and teleZoneMod.GetZoneList then
        fishingSpots = teleZoneMod.GetZoneList()
    else
        local zones = workspace:FindFirstChild("zones")
        local fishingFolder = zones and zones:FindFirstChild("fishing")
        if fishingFolder then
            for _, z in pairs(fishingFolder:GetChildren()) do
                table.insert(fishingSpots, z.Name)
            end
            table.sort(fishingSpots)
        end
    end
    local function teleportToFishingZone(zoneName)
        local TeleportArea = getMod("TeleportArea")
        if TeleportArea then
            if TeleportArea.TeleportToZone then
                TeleportArea.TeleportToZone(zoneName)
            elseif TeleportArea.teleportToFishingZone then
                TeleportArea.teleportToFishingZone(zoneName)
            end
        end
    end
    local optionQuestAngler = {
        ["Moosewood Village"] = CFrame.new(481, 151, 299),
        ["Roslit Hamlet"] = CFrame.new(-1512, 140, 688),
        ["Sunstone Island"] = CFrame.new(-885, 135, -1115),
        ["Terrapin Island"] = CFrame.new(-153, 144, 1954),
        ["The Depths"] = CFrame.new(980, -700, 1230),
        ["Ancient Isles"] = CFrame.new(5737, 177, -57),
        ["Forsaken Shores"] = CFrame.new(-2702, 169, 1798),
        ["Crimson Cavern"] = CFrame.new(-1069, -361, -4811),
        ["Luminescent Cavern"] = CFrame.new(-1050, -337, -4078),
        ["Lost Jungle"] = CFrame.new(-2726, 226, -2186)
    }
    local function getAnglerLocationFromQuest(val)
        if not val then return nil end
        local valLower = tostring(val):lower()
        for name, _ in pairs(optionQuestAngler) do
            local mainName = name:lower():match("^(%S+)")
            if mainName and valLower:find(mainName, 1, true) then
                return name
            end
        end
        return nil
    end
    local anglerOptions = {"None"}
    for name in pairs(optionQuestAngler) do
        table.insert(anglerOptions, name)
    end
    local lastSelectedAngler = "None"
    local AutoAngler = false
    local function teleportToAngler(name)
        if type(name) == "table" then
            name = name[1]
        end
        local cf = optionQuestAngler[name]
        if not cf then return end
        local char = LocalPlayer.Character
        local hrp = char and char:WaitForChild("HumanoidRootPart", 2)
        if not hrp then return end
        hrp.CFrame = cf
    end
    AutosQuest:AddSeperator({
        Title = 'Quest Angler',
    })
    AutosQuest:AddDropdown({
        Title = "Select Quest Angler Location",
        Content = "Select Quest Angler",
        Options = anglerOptions,
        Default = {"None"},
        Multi = false,
        Callback = function(v)
            if type(v) == "table" then
                lastSelectedAngler = v[1] or "None"
            else
                lastSelectedAngler = v or "None"
            end
        end
    })
    _G.QuestData = {
        Name = "None",
        Target = "None",
        Cooldown = "Ready",
        Status = "Idle",
        HaveFish = false
    }
    local function ToggleStatusWidget(visible)
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local existing = playerGui:FindFirstChild("QuestStatusWidget")
        if not visible then
            if existing then existing:Destroy() end
            return
        end
        if existing then return end
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "QuestStatusWidget"
        screenGui.Parent = playerGui
        screenGui.DisplayOrder = 99999999
        screenGui.IgnoreGuiInset = true
        screenGui.ResetOnSpawn = false
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0, 180, 0, 100)
        mainFrame.Position = UDim2.new(0, 10, 1, -130)
        mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        mainFrame.BackgroundTransparency = 0.25
        mainFrame.BorderSizePixel = 0
        mainFrame.Parent = screenGui
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 18)
        uiCorner.Parent = mainFrame
        local uiStroke = Instance.new("UIStroke")
        uiStroke.Color = Color3.fromRGB(255, 255, 255)
        uiStroke.Thickness = 1.2
        uiStroke.Transparency = 0.85
        uiStroke.Parent = mainFrame
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 45)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))
        }
        gradient.Rotation = 45
        gradient.Parent = mainFrame
        local decorFrame = Instance.new("Frame")
        decorFrame.BackgroundTransparency = 1
        decorFrame.Size = UDim2.new(1, 0, 0, 20)
        decorFrame.Parent = mainFrame
        local function makeDot(color, x)
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 8, 0, 8)
            dot.Position = UDim2.new(0, x, 0, 10)
            dot.BackgroundColor3 = color
            dot.BorderSizePixel = 0
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            dot.Parent = decorFrame
        end
        makeDot(Color3.fromRGB(255, 95, 87), 12)
        makeDot(Color3.fromRGB(255, 189, 46), 26)
        makeDot(Color3.fromRGB(40, 201, 64), 40)
        local contentFrame = Instance.new("Frame")
        contentFrame.BackgroundTransparency = 1
        contentFrame.Size = UDim2.new(1, 0, 1, -28)
        contentFrame.Position = UDim2.new(0, 0, 0, 28)
        contentFrame.Parent = mainFrame
        local listLayout = Instance.new("UIListLayout")
        listLayout.Parent = contentFrame
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 2)
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 15)
        padding.Parent = contentFrame
        local function createLabel(name, text, color, order)
            local label = Instance.new("TextLabel")
            label.Name = name
            label.Size = UDim2.new(1, -15, 0, 14)
            label.BackgroundTransparency = 1
            label.TextColor3 = color
            label.TextSize = 11
            label.Font = Enum.Font.GothamBold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = text
            label.LayoutOrder = order
            label.Parent = contentFrame
            return label
        end
        local purple = Color3.fromRGB(180, 80, 255)
        local lblQuest = createLabel("QuestLabel", "Quest: ...", purple, 1)
        local lblTarget = createLabel("TargetLabel", "Target: ...", purple, 2)
        local lblBackpack = createLabel("BackpackLabel", "Have: false", purple, 3)
        local lblStatus = createLabel("StatusLabel", "Status: Idle", purple, 4)
        task.spawn(function()
            while screenGui and screenGui.Parent do
                lblQuest.Text = "Quest: " .. (_G.QuestData.Name or "None")
                lblTarget.Text = "Target: " .. (_G.QuestData.Target or "None")
                lblBackpack.Text = "Have Fish: " .. tostring(_G.QuestData.HaveFish or "false")
                lblStatus.Text = "Status: " .. (_G.QuestData.Status or "Idle")
                task.wait(0.2)
            end
        end)
    end
    AutosQuest:AddToggle({
        Title = "Auto Angler",
        Default = false,
        Callback = function(toggleValue)
            AutoAngler = toggleValue
            ToggleStatusWidget(toggleValue)
            if not AutoAngler then
                task.spawn(function()
                    _G.Config.selectedZoneADS = false
                    teleportToFishingZone("None")
                end)
                return
            end
            task.spawn(function()
                while AutoAngler do
                    local questValueObj = nil
                    local DataController = nil
                    local function getQuest()
                        local ok, err = pcall(function()
                            warn("[NewFish5 DEBUG] getQuest: starting check")
                        end)
                        local playerStats = workspace:FindFirstChild("PlayerStats")
                        local myStats = playerStats and playerStats:FindFirstChild(LocalPlayer.Name)
                        local tFolder = myStats and myStats:FindFirstChild("T")
                        local innerPlayer = tFolder and tFolder:FindFirstChild(LocalPlayer.Name)
                        local quests = innerPlayer and innerPlayer:FindFirstChild("Quests")
                        if quests then
                            for _, child in ipairs(quests:GetChildren()) do
                                if child.Name:find("Angler Quest") then
                                    local targetFish = nil
                                    for _, sub in ipairs(child:GetChildren()) do
                                        if sub.Name ~= "AutoComplete" and sub.Name ~= "Icon" and sub.Name ~= "Tracking" and not sub.Name:find("_Goal") then
                                            targetFish = sub.Name
                                            break
                                        end
                                    end
                                    pcall(function() warn("[NewFish5 DEBUG] getQuest: found legacy quest") end)
                                    return {
                                        Name = child.Name,
                                        Value = child.Value,
                                        TargetFish = targetFish,
                                        Legacy = true,
                                        Object = child
                                    }
                                end
                            end
                        end
                        pcall(function() warn("[NewFish5 DEBUG] getQuest: legacy check done, loading DataController") end)
                        if not DataController then
                            pcall(function()
                                local client = game:GetService("ReplicatedStorage"):WaitForChild("client", 1)
                                local controllers = client and client:WaitForChild("controllers", 1)
                                local dc = controllers and controllers:WaitForChild("DataController", 1)
                                if dc then DataController = require(dc) end
                            end)
                            if not DataController then
                                pcall(function()
                                    local client = game:GetService("ReplicatedStorage"):WaitForChild("client", 1)
                                    local legacy = client and client:WaitForChild("legacyControllers", 1)
                                    local dc = legacy and legacy:WaitForChild("DataController", 1)
                                    if dc then DataController = require(dc) end
                                end)
                            end
                        end
                        pcall(function() warn("[NewFish5 DEBUG] getQuest: DataController resolved: " .. tostring(DataController ~= nil)) end)
                        if DataController then
                            local data = nil
                            if DataController.PlayerDataReplicator and DataController.PlayerDataReplicator.Index then
                                pcall(function()
                                    warn("[NewFish5 DEBUG] getQuest: trying PlayerDataReplicator:Index")
                                    data = DataController.PlayerDataReplicator:Index({"quests"})
                                end)
                                pcall(function() warn("[NewFish5 DEBUG] getQuest: Index call finished. data exists: " .. tostring(data ~= nil)) end)
                            else
                                pcall(function()
                                    warn("[NewFish5 DEBUG] getQuest: falling back to Get/fetch")
                                    data = DataController.Get and DataController:Get("quests") or DataController.fetch and DataController.fetch("quests")
                                end)
                                pcall(function() warn("[NewFish5 DEBUG] getQuest: Get/fetch call finished. data exists: " .. tostring(data ~= nil)) end)
                            end
                            if data then
                                for k, v in pairs(data) do
                                    if tostring(k):lower():find("angler") then
                                        local desc = v.Description or v.Text or v.Value or ""
                                        local targetFish = v.Fish or v.Target or v.FishName
                                        if not targetFish then
                                            local descLower = desc:lower()
                                            for _, fish in ipairs(namefish) do
                                                if descLower:find(fish:lower(), 1, true) then
                                                    targetFish = fish
                                                    break
                                                end
                                            end
                                        end
                                        pcall(function() warn("[NewFish5 DEBUG] getQuest: found DataController quest: " .. tostring(k)) end)
                                        return {
                                            Name = tostring(k),
                                            Value = desc,
                                            TargetFish = targetFish,
                                            Legacy = false,
                                            Data = v
                                        }
                                    end
                                end
                            end
                        end
                        pcall(function() warn("[NewFish5 DEBUG] getQuest: finished checking, returning nil") end)
                        return nil
                    end
                    local function triggerAnglerPrompt()
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return false end
                        local CollectionService = game:GetService("CollectionService")
                        for _, npc in ipairs(CollectionService:GetTagged("NewNpc")) do
                            if npc:IsA("Model") and npc:GetAttribute("NpcType") == "Angler" then
                                local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                                if npcHRP and (npcHRP.Position - hrp.Position).Magnitude < 50 then
                                    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt then
                                        pcall(function()
                                            local camera = workspace.CurrentCamera
                                            if camera then
                                                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, npcHRP.Position)
                                            end
                                        end)
                                        task.wait(0.15)
                                        FireProximity(prompt)
                                        return true
                                    end
                                end
                            end
                        end
                        for _, npc in pairs(workspace.world.npcs:GetChildren()) do
                            local isAngler = npc.Name:lower():find("angler") or npc:GetAttribute("NpcType") == "Angler"
                            if npc:IsA("Model") and isAngler then
                                local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                                if npcHRP and (npcHRP.Position - hrp.Position).Magnitude < 50 then
                                    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt then
                                        pcall(function()
                                            local camera = workspace.CurrentCamera
                                            if camera then
                                                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, npcHRP.Position)
                                            end
                                        end)
                                        task.wait(0.15)
                                        FireProximity(prompt)
                                        return true
                                    end
                                end
                            end
                        end
                        return false
                    end
                    _G.QuestData.Status = "Searching..."
                    _G.QuestData.Name = "None"
                    while AutoAngler do
                        pcall(function()
                            warn("[NewFish5 DEBUG] Loop tick. lastSelectedAngler = " .. tostring(lastSelectedAngler) .. " | quest = " .. tostring(questValueObj and questValueObj.Name or "None"))
                        end)
                        questValueObj = getQuest()
                        if questValueObj then
                            _G.QuestData.Status = "Quest Active!"
                            _G.QuestData.Name = questValueObj.Name or "Angler Quest"
                            break
                        end
                        if lastSelectedAngler ~= "None" then
                            _G.QuestData.Status = "Going to Angler..."
                            teleportToAngler(lastSelectedAngler)
                            task.wait(1.5)
                            local start = tick()
                            _G.QuestData.Status = "Interacting..."
                            while tick() - start < 5 do
                                if triggerAnglerPrompt() then
                                    local DialogInteract = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/DialogInteract")
                                    pcall(function()
                                        task.spawn(function()
                                            DialogInteract:InvokeServer(1, 1)
                                        end)
                                    end)
                                    break
                                end
                                task.wait(0.4)
                            end
                        end
                        task.wait(1)
                    end
                    if not AutoAngler then return end
                    local value = tostring(questValueObj.Value or ""):gsub(":$", "")
                    local valueLower = value:lower()
                    local detected = false
                    for _, phrase in ipairs(anglerOptions) do
                        for word in phrase:lower():gmatch("%S+") do
                            if valueLower:find(word, 1, true) then
                                if phrase ~= "None" then
                                    detected = true
                                    break
                                end
                            end
                        end
                        if detected then break end
                    end
                    if not detected and lastSelectedAngler ~= "None" then
                        detected = true
                    end
                    local targetFish = questValueObj.TargetFish
                    if targetFish then
                        _G.QuestData.Target = targetFish
                        _G.QuestData.Status = "Target Identified"
                    end
                    local fishActioned = false
                    if targetFish then
                        local backpack = LocalPlayer.Backpack
                        local character = LocalPlayer.Character
                        local fishTool = backpack:FindFirstChild(targetFish) or (character and character:FindFirstChild(targetFish))
                        _G.QuestData.HaveFish = (fishTool ~= nil)
                        if fishTool then
                            fishActioned = true
                            _G.QuestData.Status = "Fish Caught! Returning..."
                            local ac = getMod("AutoCast")
                            if ac then ac(false) end
                            local ar = getMod("AutoReel")
                            if ar then ar(false) end
                            local mf = getMod("MiscFishing")
                            if mf and mf.AutoEquipRod then mf.AutoEquipRod(false) end
                            local human = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                            if human then
                                pcall(function()
                                    human:UnequipTools()
                                end)
                            end
                            task.wait(0.2)
                            _G.Config.selectedZoneADS = false
                            teleportToFishingZone("None")
                            local targetAngler = getAnglerLocationFromQuest(questValueObj.Value) or lastSelectedAngler
                             if targetAngler ~= "None" then
                                 _G.QuestData.Status = "Going to Angler..."
                                 teleportToAngler(targetAngler)
                                 task.wait(1.5)
                             end
                            _G.QuestData.Status = "Equipping Fish..."
                            local human = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                            if human then
                                human:EquipTool(fishTool)
                            end
                            task.wait(0.5)
                            _G.QuestData.Status = "Turning In Quest..."
                            local claimStart = tick()
                            while tick() - claimStart < 10 do
                                if triggerAnglerPrompt() then
                                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    local oldCF
                                    if hrp then
                                        oldCF = hrp.CFrame
                                        hrp.CFrame = oldCF + Vector3.new(0, 50, 0)
                                        task.wait(0.15)
                                    end
                                    local DialogInteract = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/DialogInteract")
                                     pcall(function()
                                         task.spawn(function()
                                             DialogInteract:InvokeServer(1, 1)
                                         end)
                                     end)
                                    if hrp and oldCF then
                                        task.wait(0.5)
                                        hrp.CFrame = oldCF
                                    end
                                    task.wait(0.5)
                                    local seenButton = false
                                    local closed = false
                                    for i = 1, 20 do
                                        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                                        local optGui = pGui and pGui:FindFirstChild("options")
                                        local sf = optGui and optGui:FindFirstChild("safezone")
                                        local optionFrame = sf and sf:FindFirstChild("2option")
                                        local btn = optionFrame and optionFrame:FindFirstChild("button")
                                        if btn then
                                            local hrp2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                            local oldCF2
                                            if hrp2 then
                                                oldCF2 = hrp2.CFrame
                                                hrp2.CFrame = oldCF2 + Vector3.new(0, 9, 0)
                                                task.wait(0.15)
                                            end
                                            seenButton = true
                                            if getconnections then
                                                for _, connection in pairs(getconnections(btn.Activated)) do
                                                    task.spawn(function() connection:Fire({ UserInputType = Enum.UserInputType.Keyboard }) end)
                                                    task.spawn(function() connection:Fire({ UserInputType = Enum.UserInputType.MouseButton1 }) end)
                                                end
                                                for _, connection in pairs(getconnections(btn.MouseButton1Click)) do
                                                    task.spawn(function() connection:Fire() end)
                                                end
                                            end
                                            if hrp2 and oldCF2 then
                                                task.wait(0.5)
                                                hrp2.CFrame = oldCF2
                                            end
                                        elseif seenButton then
                                            closed = true
                                            break
                                        end
                                        task.wait(0.2)
                                    end
                                    if not closed then
                                        local char = LocalPlayer.Character
                                        if char and char:FindFirstChild("HumanoidRootPart") then
                                            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + Vector3.new(0, 50, 0)
                                            task.wait(0.5)
                                        end
                                        local targetAngler = getAnglerLocationFromQuest(questValueObj.Value) or lastSelectedAngler
                                         if targetAngler ~= "None" then
                                             teleportToAngler(targetAngler)
                                         end
                                    end
                                    break
                                end
                                task.wait(0.4)
                            end
                            _G.QuestData.Status = "Claimed!"
                            task.wait(2)
                        end
                    end
                    if not fishActioned and detected then
                        local spotDetected = false
                        for _, v in pairs(fishingSpots) do
                            local vLower = v:lower()
                            if valueLower:find(vLower, 1, true) then
                                spotDetected = true
                                _G.Config.selectedZone = v
                                break
                            end
                        end
                        if not spotDetected then
                            for _, v in pairs(fishingSpots) do
                                local vLower = v:lower()
                                local mainSpot = vLower:match("^(%S+)")
                                if mainSpot and #mainSpot > 3 and valueLower:find(mainSpot, 1, true) then
                                    if not (vLower == "terrapin olm" and not valueLower:find("olm")) then
                                        spotDetected = true
                                        _G.Config.selectedZone = v
                                        break
                                    end
                                end
                            end
                        end
                        if not spotDetected and lastSelectedAngler ~= "None" then
                            local lastLower = lastSelectedAngler:lower()
                            for _, v in pairs(fishingSpots) do
                                if v:lower():find(lastLower, 1, true) then
                                    spotDetected = true
                                    _G.Config.selectedZone = v
                                    break
                                end
                            end
                            if not spotDetected then
                                spotDetected = true
                                _G.Config.selectedZone = lastSelectedAngler
                            end
                        end
                        if spotDetected then
                            if not _G.Config.selectedZoneADS then
                                _G.Config.selectedZoneADS = true
                                teleportToFishingZone(_G.Config.selectedZone)
                                task.spawn(function()
                                    local ib = getMod("InstantBobber")
                                    if ib then ib(true) end
                                    local as = getMod("AutoShake")
                                    if as then as(true) end
                                    local ar = getMod("AutoReel")
                                    if ar then ar(true) end
                                    local mf = getMod("MiscFishing")
                                    if mf and mf.AutoEquipRod then mf.AutoEquipRod(true) end
                                    task.wait(0.8)
                                    local ac = getMod("AutoCast")
                                    if ac then ac(true) end
                                end)
                            end
                        else
                            if _G.Config.selectedZoneADS then
                                _G.Config.selectedZoneADS = false
                                teleportToFishingZone("None")
                            end
                        end
                    end
                    task.wait(1.5)
                end
            end)
        end
    })
    local namefish = {
        "Frank", "Mustard Hat", "Freezing Shroom", "Glacial Fragment", "Penguin", "White Sturgeon",
        "Charybdis", "Lusca", "Akkorokamui", "Beach Crate", "Sunsquid", "Surfboard Ray",
        "Beach Ball Pufferfish", "Sunglasses", "Sea Sponge", "Lifeguard Whistle", "Sand Castle",
        "Sunscreen Bottle", "Tidepopper", "Coconut", "Shellphone", "Popsicle", "Message in a Bottle",
        "Tiki Mask", "Sandslasher", "Mango Smoothie", "Mango", "Mango Whale", "Black Iron Bucket",
        "Flashlight", "Singularity", "Snowflake", "Snowman", "Fridge", "Ghost", "Ghoul", "Poltergeist",
        "Golden Nessie", "Golden Scylla", "Golden Coin", "Slenderfish", "String", "Opalescent Catfish",
        "Pufferflute", "Mutated Crystal Shrimp", "Crystal Lobster", "Stringed Grouper", "Crystal Frilled Shark",
        "Musical Crab", "DJ Spinopus", "Blobfish", "Manatee", "Doubloon", "Friend Fish", "Squirrelfish",
        "French Grunt", "Sergeant Major", "Coney Grouper", "Doctorfish Tang", "Bluehead Wrasse",
        "Islandhopper Butterflyfish", "Stoplight Parrotfish", "Scrawled Filefish", "Spadefish", "Ocean Triggerfish",
        "Rock Hind", "Rainbow Grouper", "Spotted Moray Eel", "Great Barracuda", "Tilefish", "Black Grouper",
        "Clowned Triggerfish", "Flamekissed Hawkfish", "Mandarinfish", "Cobalt Angelfish", "Trevally", "Warty Frogfish",
        "Hidden Pipefish", "Mirage Toadfish", "Scalloped Hammerhead", "Great Goldcursed Shark", "Bloop Fish",
        "Baby Bloop Fish", "Magician Narwhal", "Beluga", "Narwhal", "Apex Leviathan", "Mosslurker",
        "Carrot Goldfish", "Carrot Pufferfish", "Carrot Minnow", "Carrot Eel", "Carrot Salmon", "Carrot Turtle",
        "Carrot Snapper", "Carrot Shark", "Moon Idol Sea 1", "Moon Idol", "Moon Arctic Char", "Silver Scuttler",
        "Pale Ghost Lumpfish", "Frost Ray", "Blue Langanose", "Starbellied Wolf Fish", "Icy Daggerfish",
        "Lunar Monkfish", "Moon Idol Sea 2", "Moonveil Killifish", "Gloamfin Gar", "Lurking Crescent Pike",
        "Moonridge Catfish", "Crescent Madtom", "Bog Lantern Goby", "Tarnished Moongill", "Shell", "Shrimpanzee",
        "Royal Tigerfish", "Slurpfloth", "Flamangler", "Orcanda", "Octophant", "Wretched Guppy", "Hollow Gazer",
        "Eldritch Spineback", "Abyssal Maw", "Bloodscript Eel", "Veilborn Parasite", "Profane Ray", "The Whispering One",
        "Minnowse", "Kittyfish", "Parrotfish", "Pengwhal", "Racuda", "Crocokoi", "Krabbit", "Siren Sheep", "Capybass",
        "Cluckfin", "Zebrafishlet", "Piglet Pike", "Squirrelray", "Duckfin Tuna", "Porcufish", "Piranhamunk", "Salmoose",
        "Mained Lionfish", "Seacow", "Mama Poot", "Ken", "Grouchy Smurf", "No Name", "Hefty", "Vanity", "Brainy Smurf",
        "Clumsy Smurf", "Papa Smurf", "Moxie", "Sunny O'Coin", "Rowdy McCharm", "Plumrick O'Luck", "O'Mango Goldgrin",
        "Blarney McBreeze", "Magma Leviathan", "Anglers Lantern", "Crowned Anglerfish", "Crystallized Seadragon", "Scylla",
        "Ember Catfish", "Blistered Eel", "Lava Lamprey", "Molten Minnow", "Pyro Pike", "Cinder Carp", "Scooty Salmon",
        "Burnt Betta", "Ashcloud Archerfish", "Slain Maw", "Black Veil Ray", "Bone Lanternfish", "Harbinger Koi",
        "Hexeye Snapper", "Rotfin Eel", "Siren’s Guppy", "Wraithfin", "Lovestorm Eel", "Lovestorm Eel Supercharged",
        "Tempest Ray", "Abyss Snapper", "Whirlpool Marlin", "Vortex Barracuda", "Typhoon Tuna", "Cyclone Mako",
        "Maelstorm Shark", "Void Angler", "Reef Minnow", "Coral Chromis", "Reef Goby", "Coral Guard", "Crystal Wrasse",
        "Reef Parrotfish", "Coral Emperor", "Grand Reef Guardian", "Glacier Glowfish", "Frozen Fangfish",
        "Hollow Flake Catfish", "Crystal Carp", "Hollyscale Trout", "Red Energy Crystal", "Green Energy Crystal",
        "Yellow Energy Crystal", "Blue Energy Crystal", "Glass Diamond", "Ice Anchovy", "Icy Salmon", "Icy Carp",
        "Frigid Crab", "Icy Tuna", "Icy Goldfish", "Frigid Antlers", "Frozen Walnut", "Ice Eel", "Frigid Shrimp",
        "Ice Jellyfish", "Ice Octopus", "Frigid Taco", "Snowfish", "Polar Alligator", "Frigid Mammoth Tusk",
        "Frost Minnow", "Snowflake Smelt", "Iced Perch", "Snowback Char", "Chillfin Herring", "Frozen Pike",
        "Icebreaker Haddock", "Frostjaw Cod", "Aaurora Trout", "Glacial Sturgeon", "Snowgill Dace", "Frostling Goby",
        "Chillback Whitefish", "Icy Walleye", "Shiverfin Haddock", "Frostbite Flounder", "Glacier Swordfish",
        "Icefang Barracuda", "Borealis Snapper", "Icebeard Shark", "Meg's Spine", "Meg's Fang", "Moon Wood",
        "Inferno Wood", "Ancient Wood", "Void Wood", "Moonstone", "Lapis Lazuli", "Opal", "Ruby", "Amethyst",
        "Deep Sea Fragment", "Solar Fragment", "Earth Fragment", "Ancient Fragment", "Megalodon", "Phantom Megalodon",
        "Ancient Megalodon", "Forsaken Algae", "Ancient Algae", "Mushgrove Algae", "Snowcap Algae", "Barracuda's Spine",
        "Fossil Fan", "Claw Gill", "Spine Bone", "Spine Blade", "Shark Fang", "Nessie's Spine", "Spined Fin",
        "Ancient Serpent Spine", "Resin", "Ancient Serpent Skull", "Palaeoniscum", "Birgeria", "Phanerorhynchus",
        "Diplurus", "Lepidotes", "Amblypterus", "Boots", "RocketFuel", "Speed Core", "The Depths Key", "Destroyed Fossil",
        "Scrap Metal", "Deep-sea Hatchetfish", "Deep-sea Dragonfish", "Luminescent Minnow", "Frilled Shark",
        "Depth Octopus", "Three-eyed Fish", "Goblin Shark", "Black Dragon Fish", "Spider Crab", "Nautilus",
        "Small Spine Chimera", "Ancient Eel", "Mutated Shark", "Barreleye Fish", "Sea Snake", "Ancient Depth Serpent",
        "Corsair Grouper", "Shortfin Mako Shark", "Galleon Goliath", "Buccaneer Barracuda", "Scurvy Sailfish",
        "Cutlass Fish", "Reefrunner Snapper", "Cursed Eel", "Shipwreck Barracuda", "Golden Seahorse",
        "Captain's Goldfish", "Piranha", "Cladoselache", "Anomalocaris", "Starfish", "Onychodus", "Acanthodii",
        "Xiphactinus", "Hyneria", "Hallucigenia", "Cobia", "Floppy", "Leedsichthys", "Ginsu Shark", "Dunkleosteus",
        "Helicoprion", "Mosasaurus", "Banana", "Tire", "Boot", "Driftwood", "Seaweed", "Log", "Rock", "Common Crate",
        "Bloop Cosmetic Crate", "Carbon Crate", "Fish Barrel", "Bait Crate", "Quality Bait Crate", "Enchant Relic",
        "Exalted Relic", "Song of the Deep", "Cosmic Relic", "Bone", "Gazerfish", "Brine Shrimp", "Globe Jellyfish",
        "Dweller Catfish", "Eyefestation", "Brine Phantom", "Spectral Serpent", "Stalactite", "Coral Geode",
        "Horseshoe Crab", "Slate Tuna", "Phantom Ray", "Rockstar Hermit Crab", "Cockatoo Squid", "Banditfish",
        "Midnight Axolotl", "Barbed Shark", "Emperor Jellyfish", "Sea Mine", "Pale Tang", "Bluefish", "Lapisjack",
        "Keepers Guardian", "Umbral Shark", "Red Snapper", "Anchovy", "Largemouth Bass", "Trout", "Bream",
        "Sockeye Salmon", "Carp", "Yellowfin Tuna", "Goldfish", "Snook", "Flounder", "Eel", "Pike", "Whiptail Catfish",
        "Whisker Bill", "Treble Bass", "Fungal Cluster", "White Perch", "Swamp Bass", "Bowfin", "Grey Carp",
        "Swamp Scallop", "Mushgrove Crab", "Marsh Gar", "Catfish", "Alligator", "Handfish", "Sea Bass", "Porgy",
        "Mullet", "Sardine", "Mackerel", "Haddock", "Shrimp", "Sand Dollar", "Mussel", "Barracuda", "Cod",
        "Salmon", "Amberjack", "Crab", "Scallop", "Prawn", "Oyster", "Nurse Shark", "Lobster", "Ancient Lobster",
        "Studster", "Slipper Lobster", "Scalloped Spiny Lobster", "Rock Lobster", "Lagoon Lobster", "Snowcap Lobster",
        "Langoustine", "Second Sea Lobster", "Spiny Sunstone Lobster", "Terrapin Lobster", "Western Rock Lobster",
        "Roslit Ray Lobster", "Lobster King", "Azureback Haddock School", "Blobfish School", "Bluefin Tuna School",
        "Coralwing Guppy School", "Duskwave Herring School", "Infernal Halibut School", "Moonveil Salmon School",
        "Pufferling School", "Sardines School", "Seaspawn Shrimp School", "Shiver Swarmfish School", "Veinfin Tetra School",
        "Coelacath", "Bluefin Tuna", "Halibut", "Stingray", "Sea Urchin", "Anglerfish", "Pufferfish", "Swordfish",
        "Sailfish", "Cookiecutter Shark", "Bull Shark", "Moonfish", "Crown Bass", "Flying Fish", "Rabbitfish",
        "Dolphin", "Sawfish", "Oarfish", "Great White Shark", "Great Hammerhead Shark", "Mythic Fish", "Sea Pickle",
        "Colossal Squid", "Whale Shark", "Long Pike", "Mustard", "Chub", "Perch", "Minnow", "Pearl", "Pumpkinseed",
        "Clownfish", "Blue Tang", "Butterflyfish", "Gilded Pearl", "Angelfish", "Squid", "Ribbon Eel", "Yellow Boxfish",
        "Clam", "Rose Pearl", "Arapaima", "Alligator Gar", "Suckermouth Catfish", "Mauve Pearl", "Dumbo Octopus",
        "Axolotl", "Deep Pearl", "Manta Ray", "Aurora Pearl", "Golden Sea Pearl", "Basalt", "Volcanic Geode",
        "Magma Tang", "Ember Snapper", "Ember Perch", "Pyrogrub", "Obsidian Salmon", "Obsidian Swordfish",
        "Molten Banshee", "Ice", "Bluegill", "Grayling", "Red Drum", "Herring", "Pollock", "Arctic Char", "Burbot",
        "Blackfish", "Skipjack Tuna", "Glacier Pike", "Lingcod", "Sturgeon", "Pond Emperor", "Ringle", "Glacierfish",
        "Sweetfish", "Glassfish", "Longtail Bass", "Red Tang", "Chinfish", "Trumpetfish", "Mahi Mahi", "Napoleonfish",
        "Sunfish", "Wiifish", "Voltfish", "Smallmouth Bass", "Gudgeon", "White Bass", "Walleye", "Redeye Bass",
        "Chinook Salmon", "King Oyster", "Golden Smallmouth Bass", "Olm", "Sea Turtle", "Spiderfish", "Night Shrimp",
        "Twilight Eel", "Fangborn Gar", "Abyssacuda", "Voidfin Mahi", "Rubber Ducky", "Isonade", "Ghoulfish",
        "Lurkerfish", "Candy Fish", "Zombiefish", "Skelefish", "Nessie", "Turkey", "Icicle", "Basic Present",
        "Unique Present", "Supreme Present", "Festive Bait Crate", "Cookie", "Glass of Milk", "Candy Cane Carp",
        "Santa Salmon", "Gingerbread Fish", "Ornament Fish", "Snowflake Flounder", "Olmdeer", "Santa Pufferfish",
        "Northstar Serpent", "Confetti Shark", "Tidal Pike", "Countdown Perch", "Hourglass Bass", "Eternal Frostwhale",
        "Cryoskin", "Frostscale Fangtooth", "Subzero Stargazer", "Chillshadow Chub", "Deep Freeze Devilfish",
        "Iceberg Isopod", "Cryo Coelacanth", "Polar Prowler", "Chillfin Chimaera", "Frozen Leviathan",
        "Lightning Minnow", "Thunder Bass", "Static Ray", "Storm Eel", "Voltfin Carp", "Thunder Serpet",
        "Lightning Pike", "Sparkfin Tetra", "Stormcloud Angelfish", "Zeus' Herald", "Colossal Carp", "Titan Tuna",
        "Giant Manta", "Leviathan Bass", "Massive Marlin", "Titanic Sturgeon", "Titanfang Grouper", "Deep Emperor",
        "Deep Behemoth", "Abyssal Goliath", "Sunken Silverscale", "Atlantean Anchovy", "Oracle Minnow", "Poseidon's Perch",
        "Marble Maiden", "Crystal Chorus", "Helios Ray", "Philosopher's Fish", "Atlantean Guardian", "Triton's Herald",
        "Twilight Glowfish", "Atlantean Alchemist", "Deep Crownfish", "Celestial Koi", "Column Crawler",
        "Atlantean Sardine", "Neptune's Nibbler", "Aqua Scribe", "Temple Drifter", "Mosaic Swimmer", "Echo Fisher",
        "Oracle's Eye", "Siren Singer", "Chronos Deep Swimmer", "Voidscale Guppy", "Starlit Weaver", "Mage Marlin",
        "King Jellyfish", "Shadowfang Snapper", "Tentacled Horror", "Tentacle Eel", "Deep One", "Eldritch Horror",
        "Kraken's Herald", "Abyssal King", "Void Emperor", "Abyssal Devourer", "The Kraken", "Ancient Kraken", "Orca",
        "Ancient Orca", "Blue Whale", "Moby", "Titanic Black Seadevil", "Leviathan Humpback Anglerfish",
        "Abyssal Bearded Seadevil", "Colossal Saccopharynx", "Radiant Triplewart Seadevil", "Deeplight Footballfish",
        "Voidglow Ghostfish", "Infant Giant Seadevil", "Giant Seadevil", "Quartzfin Queenfish", "Diamond Discus",
        "Emerald Elephantnose", "Sapphire Stargazer", "Ruby Rasbora", "Prismatic Parrotfish", "Crystal Corydoras",
        "Shimmering Silverside", "Inferno Hide", "Hellfire Haddock", "Embertail Eel", "Infernal Iguanafish",
        "Smoldering Stingray", "Pyrite Pufferfish", "Molten Moray", "Scalding Swordfish", "Blisterback Blenny",
        "Hydra Haddock", "Serpent Surgeonfish", "Kraken Koi", "Gorgon Grouper", "Cyclone Scorpionfish",
        "Siren Sculpin", "Typhoon Tailfin", "Twilight Tentaclefish", "Baby Pond Emperor", "Sea Leviathan",
        "Gale Snapper", "Drift Claw", "Foamrunner", "Sprayfin", "Ripple Spine", "Depth Lurker", "Surge Pike",
        "Abyss Dart", "Breaker Moth", "Tide Fang", "Wave Piercer", "Gust Tail", "Vortex Ray", "Storm Skipper",
        "Watching Glowfin", "Drifting Gildfin", "Blue Foamtail", "Redwood Duskray", "Oak Stripetail",
        "Pine Zephyrfish", "Parktail Spinesnapper", "Sunray Sunscale", "Thornfish", "Bogscale", "Murkdrifter",
        "Vinefish", "Canopy Tetra", "Hollow Snapper", "Fogstripe", "Temple Perch", "Relic Dart", "Eecho Koi",
        "Glade Lurker", "Jungle Phantom", "Idolfish", "Primordial Levi", "Ashscale Minnow", "Glowfin Skipper",
        "Pyre Fang", "Firecrest", "Lava Bream", "Moltenstripe", "Magma Pike", "Hellmaw Eel", "Sulfur Snapper",
        "Smogfish", "Sunflare Tetra", "Searfin", "Basalt Pike", "Furnace Leaper", "Smolderfang", "Blazebelly",
        "Cragscale", "Volcanic Prowler", "Inferno Chaser", "Cinder Dart", "Emberwing", "Scorchray", "Brimstone Angler",
        "Obsidian Koi", "Tropicspike", "Molten Ripple", "Tidallow", "Reefdart", "Crestscale", "Horizon Tetra",
        "Driftfin", "Lantern Snapper", "Abyss Flicker", "Whisper Eel", "Phantom Koi", "Blisterfish", "Gloombiter",
        "Rotjaw", "Murkslither", "Split Eye Snapper", "Tumor Pike", "Hollowfin", "Crawling Angler", "Veinspawn",
        "Screaming Fluke", "Chasm Leech", "Dreaming Aberration", "Abyssborn Monstrosity", "Cursed Thread",
        "Hogchoker", "Rock Gunnel", "Pupfish", "Four Eyes Fish", "Black Swallower", "Warty Angler", "Lumpclinger",
        "Snipefish", "Boarfish", "Telescopefish", "Fangtooth", "Velvet Belly Lanternshark", "Snakehead",
        "Sarcastic Fringehead", "Knifefish", "Tripod Fish", "Pelican Eel", "Bigfin Squid", "X-ray Tetra",
        "Psychedelic Frogfish", "Murkfin", "Brackscale", "Lagoon Dart", "Glimmer Guppy", "Swampjaw", "Algae Lurker",
        "Reed Striker", "Azure Prowler", "Phantom Brine", "Bloomtail", "Depth Drifter", "Verdant Mirage",
        "Toilet Fish", "Dogefin", "Tartaruga", "Tropical Bait Crate", "Jurassic Mosasaurus", "Gillicus",
        "Ooreochima", "Diplomystus", "Giant Lamprey", "Edestus", "Jurassic Helicoprion", "Dasyatis", "Rhizodus",
        "Azure Studfish", "Clown Brickfish", "Goldbrick", "Yellow Studfish", "Stud Turtle", "Brickhorse",
        "Cardinal Studfish", "Crab Stud", "Glow Brick", "Jellystud", "Stud Koi", "Stud Shark", "Studling Crab",
        "Studphin", "Tentabrick", "Studolodon", "Gem Salmon", "Bluegem Angelfish", "Coin Triggerfish",
        "Crowned Royal Gramma", "Emerald Angelfish", "Gem Anchovy", "Gemscale Mandarinfish", "Goldband Butterflyfish",
        "Gem Eel", "Golden Dorado", "Hidden Filefish", "Coin Squid", "Coin Piranha", "Net Wolffish",
        "Queen Angelfish", "Gem Dolphin", "Ruby Lionfish", "Gemstone Whale Shark", "Gem Marlin", "Goldfin Octopus",
        "Gem Blobfish", "Gulf Toadfish", "Oyster toadfish", "Smooth toadfish", "Splendid toadfish", "Bearded Toadfish",
        "Giant Moray"
    }
    local targetFav = {}
    AutosFavorit:AddDropdown({
        Title = "Select Fish to Favorite",
        Content = "Select a multi favorite fish",
        Options = namefish,
        Default = {"None"},
        Multi = true,
        Callback = function(v)
            targetFav = v
        end
    })
    AutosFavorit:AddToggle({
        Title = "Auto Favorite",
        Default = _G.Config.AutoFavorite or false,
        Callback = function(value)
            _G.Config.AutoFavorite = value
            if value then
                task.spawn(function()
                    while _G.Config.AutoFavorite do
                        local backpack = LocalPlayer.Backpack
                        for _, itemName in pairs(targetFav) do
                            if not _G.Config.AutoFavorite then break end
                            for _, child in pairs(backpack:GetChildren()) do
                                if child.Name == itemName and child:FindFirstChild("link") then
                                    pcall(function()
                                        ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RE/Backpack/Favourite"):FireServer(child.link.Value, true)
                                    end)
                                    task.wait(0.1)
                                end
                            end
                        end
                        task.wait(1)
                    end
                end)
            end
        end
    })
    AutosSection:AddToggle({
        Title = "Auto Sell On Held",
        Default = _G.Config.AutoSellOnHeld,
        Callback = function(value)
            _G.Config.AutoSellOnHeld = value
            if value then
                task.spawn(function()
                    while _G.Config.AutoSellOnHeld do
                        local isShady = false
                        pcall(function()
                            local char = game.Players.LocalPlayer.Character
                            local tool = char and char:FindFirstChildOfClass("Tool")
                            if tool and tool:FindFirstChild("link") then
                                local itemId = tool.link.Value
                                local inventory = nil
                                if DataController.InventoryReplicator then
                                    inventory = DataController.InventoryReplicator:Index({"Inventory"})
                                else
                                    inventory = DataController.fetch("Inventory")
                                end
                                if inventory and inventory[itemId] then
                                    local itemData = inventory[itemId]
                                    local mut = itemData.sub and itemData.sub.Mutation
                                    if mut then
                                        local mutLower = string.lower(tostring(mut))
                                        if string.find(mutLower, "shady", 1, true) or string.find(mutLower, "sludge", 1, true) then
                                            isShady = true
                                        end
                                    end
                                end
                            end
                        end)
                        if isShady then
                            pcall(function()
                                local shadyNpc = workspace.world.npcs:FindFirstChild("Shady Merchant") or workspace:FindFirstChild("Shady Merchant")
                                if shadyNpc then
                                    local idle = shadyNpc:WaitForChild("description"):WaitForChild("idle")
                                    local args = {
                                        {
                                            voice = 12,
                                            uid = "Shady Merchant",
                                            npc = shadyNpc,
                                            idle = idle
                                        }
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("events"):WaitForChild("ShadySellAll"):InvokeServer(unpack(args))
                                end
                            end)
                        else
                            pcall(function()
                                local args = {
                                    {
                                        voice = 12,
                                        idle = workspace:WaitForChild("world"):WaitForChild("npcs"):WaitForChild("Marc Merchant"):WaitForChild("description"):WaitForChild("idle"),
                                        npc = workspace:WaitForChild("world"):WaitForChild("npcs"):WaitForChild("Marc Merchant")
                                    }
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("events"):WaitForChild("Sell"):InvokeServer(unpack(args))
                            end)
                        end
                        task.wait(0.2)
                    end
                end)
            end
        end
    })
    local autoOpenItemEnabled = false
    AutosSection:AddToggle({
        Title = "Auto Open Bait",
        Default = _G.Config.AutoOpenBait or false,
        Content = "",
        Callback = function(isEnabled)
            _G.Config.AutoOpenBait = isEnabled
            autoOpenItemEnabled = isEnabled
            task.spawn(function()
                local PromptAmount = game:GetService("ReplicatedStorage"):WaitForChild("events"):WaitForChild("PromptAmount")
                PromptAmount.OnClientInvoke = function()
                    local baitCount = 1000
                    pcall(function()
                        local dc = require(game:GetService("ReplicatedStorage").client.legacyControllers.DataController)
                        local inventory = nil
                        if dc.InventoryReplicator then
                            inventory = dc.InventoryReplicator:Index({"Inventory"})
                        else
                            inventory = dc.fetch("Inventory")
                        end
                        if inventory then
                            local char = game.Players.LocalPlayer.Character
                            local equippedTool = char and char:FindFirstChildOfClass("Tool")
                            if equippedTool then
                                local link = equippedTool:FindFirstChild("link")
                                if link and link.Value then
                                    local itemData = inventory[link.Value]
                                    if itemData and itemData.sub and itemData.sub.Stack then
                                        local remaining = itemData.sub.Stack
                                        if remaining < 1000 then
                                            baitCount = remaining
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    return baitCount
                end
                while autoOpenItemEnabled do
                    local char = game.Players.LocalPlayer.Character
                    local backpack = game.Players.LocalPlayer.Backpack
                    local item = char and char:FindFirstChildOfClass("Tool")
                    if not item and backpack then
                        item = backpack:FindFirstChildOfClass("Tool")
                        if item then item.Parent = char end
                    end
                    if item then
                        item.Enabled = true
                        item:Activate()
                    else
                        autoOpenItemEnabled = false
                        break
                    end
                    task.wait()
                end
            end)
        end,
    })
    local function getTotemStack(totemName)
        if not totemName or totemName == '' then return 0 end
        local inventory = nil
        pcall(function()
            inventory = DataController.InventoryReplicator:Index({"Inventory"})
        end)
        if not inventory then return 0 end
        local total = 0
        for _, itemData in pairs(inventory) do
            if type(itemData) == "table" and itemData.name == totemName then
                total = total + ((itemData.sub and itemData.sub.Stack) or 1)
            end
        end
        return total
    end
    local function summonMultipleAndWait(totemNames, states)
        local items = {}
        local stacksBefore = {}
        for _, totemName in ipairs(totemNames) do
            local totemItem = LocalPlayer.Backpack:FindFirstChild(totemName)
            local stackBefore = getTotemStack(totemName)
            if totemItem and stackBefore > 0 then
                table.insert(items, {name = totemName, item = totemItem, state = states[totemName]})
                stacksBefore[totemName] = stackBefore
                states[totemName].lock = true
            end
        end
        if #items == 0 then return false end
        for _, data in ipairs(items) do
            pcall(function()
                data.item.Parent = LocalPlayer.Character
            end)
        end
        task.wait(0.2)
        local anyActivated = false
        for attempt = 1, 3 do
            local allActivated = true
            for _, data in ipairs(items) do
                if not data.state.summoned then
                    local activeTotem = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(data.name)
                    if activeTotem then
                        pcall(function() activeTotem:Activate() end)
                    end
                end
            end
            task.wait(4)
            for _, data in ipairs(items) do
                if not data.state.summoned then
                    local stackAfter = getTotemStack(data.name)
                    if stackAfter < stacksBefore[data.name] then
                        data.state.lastStack = stackAfter
                        data.state.summoned = true
                        anyActivated = true
                    else
                        allActivated = false
                    end
                end
            end
            if allActivated then break end
        end
        for _, data in ipairs(items) do
            local rem = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(data.name)
            if rem then pcall(function() rem.Parent = LocalPlayer.Backpack end) end
            if not data.state.summoned then
                data.state.lastStack = getTotemStack(data.name)
            end
            data.state.lock = false
        end
        return anyActivated
    end
    local function normalizeTotemList(raw)
        local result = {}
        if type(raw) == 'table' then
            for k, v in pairs(raw) do
                if type(k) == 'string' and v == true then
                    table.insert(result, k)
                elseif type(k) == 'number' and type(v) == 'string' then
                    table.insert(result, v)
                end
            end
        elseif type(raw) == 'string' and raw ~= '' then
            table.insert(result, raw)
        end
        return result
    end
    local totemOptions = {
        'Sundial Totem', 'Clearcast Totem', 'Tempest Totem', 'Windset Totem', 'Smokescreen Totem',
        'Meteor Totem', 'Avalanche Totem', 'Eclipse Totem', 'Blizzard Totem', 'Aurora Totem',
        'Zeus Storm Totem', 'Poseidon Wrath Totem', 'Blue Moon Totem', 'Shiny Totem', 'Sparkling Totem',
        'Mutation Totem', 'Starfall Totem', 'Rainbow Totem', 'Megalodon Hunt Totem', 'Kraken Hunt Totem',
        'Colossal Dragon Hunt Totem', 'Scylla Hunt Totem', 'Dripstone Collapse Totem'
    }
    AuraSection:AddDropdown({
        Title = 'Select Multi Day Totem',
        Options = totemOptions,
        Default = _G.Config.SelectedDayTotems or {},
        PlaceHolder = 'Select Totem - Day',
        Multi = true,
        Callback = function(SelectedTotem)
            _G.Config.SelectedDayTotems = SelectedTotem or {}
        end,
    })
    AuraSection:AddDropdown({
        Title = 'Select Multi Night Totem',
        Options = totemOptions,
        Default = _G.Config.SelectedNightTotems or {},
        PlaceHolder = 'Select Totem - Night',
        Multi = true,
        Callback = function(SelectedTotem)
            _G.Config.SelectedNightTotems = SelectedTotem or {}
        end,
    })
    _G.Config.AutoTotemRunning = false
    _G.Config.InfSundialRunning = false
    AuraSection:AddToggle({
        Title = 'Auto Multi Totem',
        Default = _G.Config.AutoTotemToggle or false,
        Callback = function(isEnabled)
            _G.Config.AutoTotemToggle = isEnabled
            if isEnabled then
                if _G.Config.AutoTotemRunning then return end
                _G.Config.AutoTotemRunning = true
                _G.Config.TotemState = {}
                _G.Config.LastCycle = ''
                task.spawn(function()
                    while _G.Config.AutoTotemToggle do
                        pcall(function()
                            task.wait(0.3)
                            local currentCycle = ReplicatedStorage.world.cycle.Value
                            if _G.Config.LastCycle ~= currentCycle then
                                _G.Config.TotemState = {}
                                _G.Config.LastCycle = currentCycle
                                task.wait(0.5)
                            end
                            local raw = currentCycle == 'Day' and _G.Config.SelectedDayTotems or _G.Config.SelectedNightTotems
                            local selectedTotems = normalizeTotemList(raw)
                            if #selectedTotems == 0 then
                                task.wait(2)
                                return
                            end
                            local totemsToSummon = {}
                            local statesToSummon = {}
                            for _, totemName in ipairs(selectedTotems) do
                                if not _G.Config.AutoTotemToggle then break end
                                local state = _G.Config.TotemState[totemName]
                                if not state then
                                    state = {
                                        lastStack = getTotemStack(totemName),
                                        summoned = false,
                                        lock = false,
                                    }
                                    _G.Config.TotemState[totemName] = state
                                end
                                if not (state.summoned or state.lock) then
                                    local currentStack = getTotemStack(totemName)
                                    if currentStack < state.lastStack then
                                        state.summoned = true
                                        state.lastStack = currentStack
                                    else
                                        local inWorld = workspace:FindFirstChild(LocalPlayer.Name) and workspace[LocalPlayer.Name]:FindFirstChild(totemName)
                                        if inWorld then
                                            state.summoned = true
                                        else
                                            if currentStack <= 0 then
                                                if _G.Config.AutoPurchaseIfNone then
                                                    pcall(function()
                                                        ReplicatedStorage.events.purchase:FireServer(totemName, 'Item', nil, 1)
                                                    end)
                                                    task.wait(2)
                                                    state.lastStack = getTotemStack(totemName)
                                                end
                                            else
                                                table.insert(totemsToSummon, totemName)
                                                statesToSummon[totemName] = state
                                            end
                                        end
                                    end
                                end
                                table.insert(totemsToSummon, totemName)
                                statesToSummon[totemName] = state
                            end
                            if #totemsToSummon > 0 then
                                summonMultipleAndWait(totemsToSummon, statesToSummon)
                                task.wait(0.5)
                            end
                        end)
                    end
                    _G.Config.AutoTotemRunning = false
                    _G.Config.TotemState = {}
                end)
            else
                _G.Config.AutoTotemToggle = false
                _G.Config.AutoTotemRunning = false
                _G.Config.TotemState = {}
            end
        end,
    })
    local auroraCoordinates = {
        Vector3.new(-1813, -137, -3281),
        Vector3.new(-1836, -103, -3321),
        Vector3.new(-1716, -100, -3392),
        Vector3.new(-950, -232, -2751),
        Vector3.new(-1155, -329, -4366),
        Vector3.new(-1161, -345, -4922),
        Vector3.new(-934, -361, -4771),
        Vector3.new(-5120, 158, -1629),
        Vector3.new(-5502, 153, -1962),
        Vector3.new(-5219, 158, -1511),
        Vector3.new(-4508, -699, -2027),
        Vector3.new(15, 136, 1933),
        Vector3.new(4376, -2009, -4728),
        Vector3.new(4453, -2710, -4600),
        Vector3.new(4376, -2706, -4749),
        Vector3.new(-4061, -561, 1529),
        Vector3.new(-3552, -550, 924),
        Vector3.new(-4231, -627, 2664),
        Vector3.new(-3952, -673, 2421),
        Vector3.new(-5018, -589, 1762),
        Vector3.new(-9068, -2346, 1050),
        Vector3.new(-8972, -2272, 150),
        Vector3.new(-8560, -2881, 847),
        Vector3.new(-8700, -2838, 786),
        Vector3.new(-9084, -2799, 860),
        Vector3.new(-8635, -3091, 504),
        Vector3.new(-8905, -3171, 464),
        Vector3.new(-7638, -4242, 426),
        Vector3.new(-8406, -4250, 148),
        Vector3.new(-8279, -4252, 596),
        Vector3.new(-8699, -4196, -521),
        Vector3.new(-8685, -4243, -313),
        Vector3.new(-8862, -4303, -892),
        Vector3.new(-8904, -4300, -8784),
        Vector3.new(-2885, 142, -2258),
        Vector3.new(-2584, -309, -3109),
        Vector3.new(-2570, -310, -2928),
        Vector3.new(-1934, -302, -3349),
        Vector3.new(-1885, 354, 198),
        Vector3.new(-3393, -1974, 3887),
        Vector3.new(-2941, -1954, 4252),
        Vector3.new(-4418, -11167, 1595),
        Vector3.new(-106, -566, 1578),
        Vector3.new(-87, -724, 1154),
        Vector3.new(908, -620, 616),
        Vector3.new(1007, -596, 1212),
        Vector3.new(1357, -614, 2357),
        Vector3.new(6026, 258, 589),
        Vector3.new(5944, 154, 453),
        Vector3.new(-3105, -756, 1667),
        Vector3.new(-3222, -768, 1866),
        Vector3.new(3038, -1102, 431),
        Vector3.new(4630, -1083, 835),
        Vector3.new(4311, -1086, 1045),
        Vector3.new(2999, -1126, 2046),
        Vector3.new(2383, -1011, 747),
        Vector3.new(20260, 273, 5596),
        Vector3.new(19862, 424, 5390),
        Vector3.new(20016, 900, 5675),
        Vector3.new(20067, 1226, 5413),
        Vector3.new(21236, 617, 3561),
        Vector3.new(21779.2, 133, 3909.5),
        Vector3.new(-711, -864, -9),
        Vector3.new(-790, -812, -316),
        Vector3.new(-265, -897, -99),
        Vector3.new(1523, -802, -238),
        Vector3.new(790, -716, -14),
        Vector3.new(567, 281, -2121),
        Vector3.new(285, 211, -2233),
        Vector3.new(-2796, 208, 1542),
        Vector3.new(2884, 136, 2705),
        Vector3.new(2794, 89, 2498),
        Vector3.new(1821, -324, -2440)
    }
    local AutoBuyAuroraToggle
    AutoBuyAuroraToggle = AuraSection:AddToggle({
        Title = "Auto Buy Aurora",
        Default = false,
        Callback = function(state)
            _G.Config.AutoBuyAurora = state
            if state then
                task.spawn(function()
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        warn("[ShielD] Character or HumanoidRootPart not found!")
                        AutoBuyAuroraToggle:SetValue(false)
                        return
                    end
                    local function getCoins()
                        local success, val = pcall(function()
                            local stats = workspace:FindFirstChild("PlayerStats")
                            local pFolder = stats and stats:FindFirstChild(LocalPlayer.Name)
                            local tFolder = pFolder and pFolder:FindFirstChild("T")
                            local subFolder = tFolder and tFolder:FindFirstChild(LocalPlayer.Name)
                            local statsSub = subFolder and subFolder:FindFirstChild("Stats")
                            local coinsObj = statsSub and statsSub:FindFirstChild("coins")
                            return coinsObj and coinsObj.Value
                        end)
                        if success and val then return val end
                        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
                        local cashObj = leaderstats and (leaderstats:FindFirstChild("C$") or leaderstats:FindFirstChild("E$"))
                        return cashObj and cashObj.Value or 0
                    end
                    if getCoins() < 500000 then
                        warn("[ShielD] Not enough cash to purchase Aurora Totem (needs 500k)!")
                        AutoBuyAuroraToggle:SetValue(false)
                        return
                    end
                    local originalPosition = hrp.CFrame
                    while _G.Config.AutoBuyAurora do
                        if getCoins() < 500000 then
                            break
                        end
                        for _, coord in ipairs(auroraCoordinates) do
                            if not _G.Config.AutoBuyAurora then break end
                            if getCoins() < 500000 then break end
                            hrp.CFrame = CFrame.new(coord)
                            task.wait(1.0)
                            local totemFound = nil
                            local interactables = workspace:WaitForChild("world"):WaitForChild("interactables")
                            for _, child in ipairs(interactables:GetChildren()) do
                                if child.Name == "Aurora Totem" then
                                    local totemPos = child:GetPivot().Position
                                    if (totemPos - hrp.Position).Magnitude < 100 then
                                        totemFound = child
                                        break
                                    end
                                end
                            end
                            if totemFound then
                                local coinsBefore = getCoins()
                                pcall(function()
                                    ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RF/AuroraTotem/Purchase"):InvokeServer(totemFound)
                                end)
                                task.wait(1.0)
                            end
                        end
                        if originalPosition and hrp then
                            hrp.CFrame = originalPosition
                        end
                        if _G.Config.AutoBuyAurora then
                            task.wait(10)
                        end
                    end
                end)
            end
        end
    })
end
return Init