local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local teleportDistance = 130  -- Adjusted default teleport distance
local teleporting = false  -- Flag to control the teleportation loop
local usingLootRemote = false  -- Flag to control using loot remote
local openingWeapons = false  -- Flag to control opening weapons

-- Function to get all enemies in nested folders
local function getAllEnemies()
    local enemies = {}

    -- Recursive function to collect enemies from a folder
    local function collectEnemiesFromFolder(folder)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") and child:FindFirstChild("HumanoidRootPart") then
                    table.insert(enemies, child)
                elseif child:IsA("Folder") or child:IsA("Model") then
                    collectEnemiesFromFolder(child)
                end
            end
        end
    end

    -- Collect enemies from Entities folder
    collectEnemiesFromFolder(game.Workspace:FindFirstChild("Entities"))

    -- Collect enemies from Dungeons folder
    collectEnemiesFromFolder(game.Workspace:FindFirstChild("Dungeons"))

    return enemies
end

-- Function to teleport all enemies in front of the player
local function bringEnemiesToPlayer()
    local player = LocalPlayer.Character

    if player and player:FindFirstChild("HumanoidRootPart") then
        local enemies = getAllEnemies()
        for _, enemy in ipairs(enemies) do
            local humanoidRootPart = enemy:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                -- Calculate position in front of the player with adjusted teleport distance
                local playerPosition = player.HumanoidRootPart.Position
                local playerDirection = player.HumanoidRootPart.CFrame.LookVector
                local enemyPosition = playerPosition + playerDirection * teleportDistance
                humanoidRootPart.CFrame = CFrame.new(enemyPosition)
            end
        end
    end
end

-- Function to fire a skill by key
local function fireSkillKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    wait(0.5)  -- Adjusted to 0.5 seconds delay between skill presses
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

-- Main loop to teleport enemies and fire skills rapidly
local function teleportAndFireLoop()
    while teleporting do
        bringEnemiesToPlayer()
        wait()  -- Adjust the wait time for optimal performance
    end
end

-- Function to fire the remote for a specific quest
local function makeKillQuest(questName)
    local args = {
        [1] = questName
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Main"):WaitForChild("Remotes"):WaitForChild("MakeKillQuest"):FireServer(unpack(args))
end

-- Function to fire the remote for a dungeon specific quest
local function makeDungeonQuest(DungeonquestName)
    local args = {
        [1] = DungeonquestName
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Main"):WaitForChild("Remotes"):WaitForChild("MakeDungeonQuest"):FireServer(unpack(args))
end

-- Function to fire the remote for each item found in the path
local function fireRemotes(path, remoteName)
    local items = path:GetChildren()
    for _, item in ipairs(items) do
        OrionLib:MakeNotification({
            Name = "Remote Action",
            Content = string.format("Firing remote: %s for item: %s", remoteName, item.Name),
            Image = "rbxassetid://464093673",
            Time = 3
        })
        local args = {
            [1] = item
        }
        game:GetService("ReplicatedStorage").Main.Remotes[remoteName]:FireServer(unpack(args))
    end
end

local Window = OrionLib:MakeWindow({
    Name = "zo's shitterhub",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "OrionTest",
    CloseCallback = function()
        OrionLib:MakeNotification({
            Name = "Window Closed",
            Content = "Window closed",
            Image = "rbxassetid://464093673",
            Time = 3
        })
        teleporting = false
    end
})

-- Create a tab for the Autofarm
local Tab1 = Window:MakeTab({
    Name = "Autofarm",
    Icon = "rbxassetid://464093673",
    PremiumOnly = false
})

-- Toggle button to enable/disable the script
local toggleScriptEnabled = false
local toggleButton = Tab1:AddToggle({
    Name = "Enable Autofarm",
    Default = false,
    Callback = function(value)
        toggleScriptEnabled = value
        if toggleScriptEnabled then
            OrionLib:MakeNotification({
                Name = "Autofarm",
                Content = "Script enabled",
                Image = "rbxassetid://464093673",
                Time = 3
            })
            teleporting = true
            spawn(teleportAndFireLoop)
        else
            OrionLib:MakeNotification({
                Name = "Autofarm",
                Content = "Script disabled",
                Image = "rbxassetid://464093673",
                Time = 3
            })
            teleporting = false
        end
    end
})

-- Checkbox to toggle enemy teleportation
local toggleTeleport = false
Tab1:AddToggle({
    Name = "Toggle Enemy Teleportation",
    Default = false,
    Callback = function(value)
        toggleTeleport = value
        OrionLib:MakeNotification({
            Name = "Autofarm",
            Content = string.format("Enemy teleportation toggled: %s", tostring(toggleTeleport)),
            Image = "rbxassetid://464093673",
            Time = 3
        })
        teleporting = toggleTeleport
    end
})

-- Slider to adjust teleport distance
local teleportSlider = Tab1:AddSlider({
    Name = "Teleport Distance",
    Min = 1,
    Max = 200,
    Default = teleportDistance,
    Increment = 1,
    ValueName = " studs",
    Callback = function(value)
        teleportDistance = value
        OrionLib:MakeNotification({
            Name = "Autofarm",
            Content = string.format("Teleport distance set to: %d studs", teleportDistance),
            Image = "rbxassetid://464093673",
            Time = 3
        })
    end
})

-- Create a tab for Quest Toggles
local Tab2 = Window:MakeTab({
    Name = "Kill Quests",
    Icon = "rbxassetid://464093673",
    PremiumOnly = false
})

-- Table to keep track of toggled quests
local activeQuests = {}

-- Function to handle quest toggles
local function toggleQuest(questName, value)
    OrionLib:MakeNotification({
        Name = "Quest Toggles",
        Content = string.format("%s toggle: %s", questName, tostring(value)),
        Image = "rbxassetid://464093673",
        Time = 3
    })
    if value then
        activeQuests[questName] = true
        -- Loop to repeatedly get the quest until the toggle is turned off
        spawn(function()
            while activeQuests[questName] do
                makeKillQuest(questName)
                wait(2)  -- Adjust the interval as needed
            end
        end)
    else
        activeQuests[questName] = nil
    end
end

-- List of quest names
local questNames = {
    "Dummy", "Dummy2", "Frost Slime", "Frost Goblin", "Wheat Slime",
    "Wolfen Footman", "Frost Warrior", "Elder Frost Slime",
    "Sand Slime", "Tundra Wolf", "Tundra Golem", "Frost Wizard",
    "Sand Knight", "Sand Warrior", "Sand Turtling", "Shira General",
    "Sand Wizard", "Frost Lord", "Sand Snake", "Sand Scorpion",
    "Electro Raptor", "Valley Knight", "Valley Angel", "Fire Bird",
    "Valley Guardian", "Holy Wizard", "Stone Knight", "Divine General Solen",
    "Overseer Ranger", "Bluebow",
}

-- Loop through questNames to create toggles for each quest
for _, questName in ipairs(questNames) do
    Tab2:AddToggle({
        Name = questName,
        Default = false,
        Callback = function(value)
            toggleQuest(questName, value)
        end
    })
end

-- DUNGEON QUESTS
-- Create a tab for Dungeon Quest Toggles
local Tab3 = Window:MakeTab({
    Name = "Dungeon Quests",
    Icon = "rbxassetid://464093673",
    PremiumOnly = false
})

-- Table to keep track of toggled dungeon quests
local activeDungeonQuests = {}

-- Function to handle dungeon quest toggles
local function toggleDungeonQuest(DungeonquestName, value)
    OrionLib:MakeNotification({
        Name = "Quest Toggles",
        Content = string.format("%s toggle: %s", DungeonquestName, tostring(value)),
        Image = "rbxassetid://464093673",
        Time = 3
    })
    if value then
        activeDungeonQuests[DungeonquestName] = true
        -- Loop to repeatedly get the quest until the toggle is turned off
        spawn(function()
            while activeDungeonQuests[DungeonquestName] do
                makeDungeonQuest(DungeonquestName)
                wait(2)  -- Adjust the interval as needed
            end
        end)
    else
        activeDungeonQuests[DungeonquestName] = nil
    end
end

-- List of Dungeon quest names
local DungeonquestNames = {
    "Tundra Wolves Dungeon", "Tundra Wolves Dungeon2", "Skar Boss Dungeon"
}

-- Loop through DungeonquestNames to create toggles for each quest
for _, DungeonquestName in ipairs(DungeonquestNames) do
    Tab3:AddToggle({
        Name = DungeonquestName,
        Default = false,
        Callback = function(value)
            toggleDungeonQuest(DungeonquestName, value)
        end
    })
end

-- Create a tab for Loot
local Tab4 = Window:MakeTab({
    Name = "Loot",
    Icon = "rbxassetid://464093673",
    PremiumOnly = false
})

-- Checkbox to toggle using the loot remote
Tab4:AddToggle({
    Name = "Toggle Use Loot Remote",
    Default = false,
    Callback = function(value)
        usingLootRemote = value
        OrionLib:MakeNotification({
            Name = "Loot Remote",
            Content = string.format("Using loot remote toggled: %s", tostring(usingLootRemote)),
            Image = "rbxassetid://464093673",
            Time = 3
        })
        -- If toggled on, use the loot remote
        if usingLootRemote then
            spawn(function()
                local path = LocalPlayer.Backpack
                while usingLootRemote do
                    fireRemotes(path, "UseLootRemote")
                    wait(1)  -- Adjust the wait time for optimal performance
                end
            end)
        end
    end
})

-- Checkbox to toggle opening all weapons
Tab4:AddToggle({
    Name = "Toggle Open All Weapons",
    Default = false,
    Callback = function(value)
        openingWeapons = value
        OrionLib:MakeNotification({
            Name = "Loot Remote",
            Content = string.format("Opening weapons toggled: %s", tostring(openingWeapons)),
            Image = "rbxassetid://464093673",
            Time = 3
        })
        -- If toggled on, open all weapons
        if openingWeapons then
            spawn(function()
                local path = LocalPlayer.Backpack
                while openingWeapons do
                    fireRemotes(path, "OpenAllWeapons")
                    wait(1)  -- Adjust the wait time for optimal performance
                end
            end)
        end
    end
})

OrionLib:Init()
