-- init
if not game:IsLoaded() then
    game.Loaded:Wait()
end

if not syn or not protectgui then
    getgenv().protectgui = function() end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Settings = {
    -- Silent Aim
    Enabled = false,
    IgnoreFriends = false,
    IgnoreFriendsExceptions = { "Second Wind", "Healing Bolt", "Blood Heal", "Inspire", "Channel", "Psychic Dimension", "PsychicDimension" },
    ProjectileSilentAim = false,
    ProjectileAbilities = { "FireBlast", "Sol", "SolarisImpulsus", "Blinding Blast", "Incendia" },
    IgnoredAbilities = { "Vis Sera Portus", "VisSeraPortus", "Sunbeam", "Cleansing Aura", "CleansingAura" },
    WallCheck = false,
    SilentAimMethod = "Raycast",
    FOVRadius = 320,
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    -- Range Expander (inclui Click Assist)
    RangeExpander = false,
    -- Spam / Cancel (Nova Aba)
    SpamMasterSwitch = false,
    SpamEnabled = false,
    AutoDrop = false,
    SpamKeybind = Enum.KeyCode.R,
    IgnoreCooldown = false,
    PacketBurst = 50,
}

getgenv().TVL2Settings = Settings

-- ==========================================
-- VARIÁVEIS DE MAGIA E UI STATUS
-- ==========================================
local SavedChannelRemote = nil
local RemetenteChannel = ""
local SavedInspireRemote = nil
local RemetenteInspire = ""

local MagicStatus = {
    channel = "Channel: ❌ Nenhum",
    inspire = "Inspire: ❌ Nenhum",
}

local ChannelStatusText = "Channel: ❌ Nenhum"
local InspireStatusText = "Inspire: ❌ Nenhum"

-- Hook do Channel Stealer
task.spawn(function()
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" and rawget(obj, "requestPrompt") then
            local isChannel = rawget(obj, "setChanneling") ~= nil
            local isInspire = rawget(obj, "setInspiring") ~= nil

            rawset(obj, "requestPrompt", function(invokerName, statAmount, acceptRemote)
                if acceptRemote then
                    if isChannel then
                        SavedChannelRemote = acceptRemote
                        RemetenteChannel = invokerName
                        ChannelStatusText = "Channel: ✅ " .. invokerName
                        MagicStatus.channel = ChannelStatusText
                        print("[✓] Magia (Channel) salva de: " .. invokerName)
                    elseif isInspire then
                        SavedInspireRemote = acceptRemote
                        RemetenteInspire = invokerName
                        InspireStatusText = "Inspire: ✅ " .. invokerName
                        MagicStatus.inspire = InspireStatusText
                        print("[✓] Vida (Inspire) salva de: " .. invokerName)
                    else
                        SavedChannelRemote = acceptRemote
                        RemetenteChannel = invokerName
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- VARIÁVEIS DO SPAM / CANCEL
-- ==========================================
local AbilityData             = require(ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("Data")
:WaitForChild("AbilityData"))
local AbilityHandler          = require(LocalPlayer.PlayerScripts:WaitForChild("ModuleScripts"):WaitForChild(
"AbilityHandler"))
local ClientDebounce          = require(LocalPlayer.PlayerScripts:WaitForChild("ModuleScripts"):WaitForChild(
"ClientDebounce"))

local AbilityRemote           = ReplicatedStorage:WaitForChild("Remotes")
    :WaitForChild("AbilityService")
    :WaitForChild("ToServer")
    :WaitForChild("AbilityActivated____")

local GetPlayers              = Players.GetPlayers
local WorldToScreen           = Camera.WorldToScreenPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild          = game.FindFirstChild

-- ... (Toda a lista de custom limits aqui)
local CustomLimits            = {
    ["Silencio"] = 20,
    ["Solaris Impulsus"] = 400,
    ["Immortale Remedium"] = 200,
    ["Vitem Tenaci"] = 75,
    ["Wound Infliction"] = 50,
    ["Esther Neck Snap"] = 200,
    ["Ossox"] = 30,
    ["Oracle Quake"] = 30,
    ["Throat Rip"] = 50,
    ["Matere Lunare Tua Vi'rtuse"] = 50,
    ["Excrucio"] = 25,
    ["Portal"] = 200,
    ["Lightning Strike"] = 20,
    ["Dissulta"] = 20,
    ["Vescaram Intacurum"] = 200,
    ["Duratus Vita"] = 20,
    ["Jail"] = 400,
    ["Phasmatos Incendia"] = 20,
    ["Lock Door"] = 10,
    ["Instant Heal"] = 20,
    ["Fireball"] = 400,
    ["Needle Of Sorrows"] = 30,
    ["Phasmatos Impetum Immortale"] = 30,
    ["Dark Josie"] = 200,
    ["Fire Blast"] = 400,
    ["Vitas Ad Animum Vitas Et Corporus"] = 100,
    ["Vido"] = 40,
    ["Infernal Twister"] = 20,
    ["Blink Attack"] = 40,
    ["Vados"] = 20,
    ["Dhalia Teleport"] = 200,
    ["Petram Aeternum"] = 20,
    ["Ictus"] = 20,
    ["Heel Stomp"] = 40,
    ["Wolf Scent"] = 200,
    ["Vulgus Animum Imperium"] = 200,
    ["Blade of Bones"] = 8,
    ["Super Slap"] = 50,
    ["Compulsion"] = 7.5,
    ["Snap Neck"] = 8,
    ["Errox Femus"] = 30,
    ["Fire Outburst"] = 37,
    ["Flame Punch"] = 5,
    ["Phasmatos Incendia Caerulus"] = 20,
    ["Illusion Attack"] = 15,
    ["Insanity Hex"] = 8,
    ["Wind Leap"] = 80,
    ["Telekinetic Submission"] = 35,
    ["Eye Gouge"] = 20,
    ["Blood Choke"] = 50,
    ["Bubilo"] = 400,
    ["Ascendo"] = 20,
    ["Telekinetic Scratch"] = 20,
    ["Incendium"] = 400,
    ["Phasmatos veras nos ex malon"] = 200,
    ["Mind Invasion"] = 20,
    ["Ignis Infernum"] = 20,
    ["Soul Binding"] = 15,
    ["Fiante Fulguris"] = 20,
    ["Spiritual Cleanse"] = 8,
    ["Golden Dagger Creation"] = 200,
    ["Disguise"] = 200,
    ["Dragon Breath"] = 20,
    ["Sunbeam"] = 80,
    ["Dolore Sanguinis"] = 32,
    ["Howl"] = 200,
    ["Wolf Ravage"] = 30,
    ["Invisique"] = 200,
    ["Harae Tamae Kioku Yomiguerashi Tamae"] = 100,
    ["Shadow Sprint"] = 200,
    ["Healing Bolt"] = 95,
    ["Aquamalia"] = 20,
    ["Poena Doloris"] = 25,
    ["Super Kick"] = 50,
    ["Upgraded Bite"] = 15,
    ["Telekinetic Attack"] = 35,
    ["Hindsight"] = 200,
    ["Wolf Transformation"] = 200,
    ["Choke Carry"] = 50,
    ["Furantur Potentia"] = 200,
    ["Brain Fry"] = 20,
    ["Phoenix Heal"] = 200,
    ["Head Rip"] = 5,
    ["Vis Sera Portus"] = 200,
    ["Fo Yato Si"] = 25,
    ["Starling Quake"] = 50,
    ["Venenum Corpus"] = 46,
    ["Fortis Salutis Ex Sanguinis"] = 200,
    ["Asgaris Distotus Tominto"] = 200,
    ["Errox Confractus"] = 200,
    ["Vestis Mutatio"] = 200,
    ["Ventrum Liquidis"] = 50,
    ["Mass Compulsion"] = 37,
    ["Psychic Restraint"] = 30,
    ["Concealed Stakes"] = 5,
    ["Enchanted Violin"] = 30,
    ["Ignis Ubique"] = 37,
    ["Blood Heal"] = 5,
    ["Ventus"] = 20,
    ["Squid Game"] = 400,
    ["Suctus Incendia"] = 46,
    ["Starling Transformation"] = 200,
    ["Starling Swarm"] = 50,
    ["Hope's Scream"] = 32,
    ["Slap"] = 6,
    ["Flame Thrower"] = 200,
    ["Flare of Life"] = 10,
    ["Necksnap Lift"] = 42,
    ["Bruciare supe terram, faciendo ignis ga praemium"] = 20,
    ["Wolf Sprint Burst"] = 200,
    ["Immobilus"] = 20,
    ["Dark Magic Repellence"] = 200,
    ["Avita Exari"] = 10,
    ["Sanitas Est Vitalis"] = 20,
    ["Ohun Pada"] = 30,
    ["Incendias Decipula"] = 14.6,
    ["Vita Essentia Extractum"] = 30,
    ["Ostium Apertum Antiquis"] = 200,
    ["Drink Blood"] = 20,
    ["Circulum Perdere"] = 200,
    ["Oo Ni Le Soro"] = 37,
    ["Immobilizing Chains"] = 100,
    ["Muse Teleport"] = 150,
    ["Cerebra Perdere"] = 200,
    ["Mentis Imperium"] = 200,
    ["Blink"] = 150,
    ["Inspire"] = 10,
    ["Wolf Pounce"] = 30,
    ["Chairify"] = 400,
    ["Incendia"] = 400,
    ["Aeternum Immortalitas"] = 200,
    ["Menedek Qual Surenta"] = 26,
    ["Ignis Tempestas"] = 32,
    ["Channel Talisman"] = 10,
    ["Animan Markamas Caristi Voka"] = 20,
    ["Vodux"] = 500,
    ["Phasmatos Motus Incendiamos"] = 50,
    ["Mass Pain Infliction"] = 47,
    ["Super Punch"] = 50,
    ["💪"] = 20,
    ["Spine Break"] = 6,
    ["Lignis Vulnus"] = 200,
    ["Psychic Teleport"] = 150,
    ["Confusion"] = 400,
    ["Psychic Blast"] = 37,
    ["Phasmatos Nos Ex Veras"] = 200,
    ["Motus"] = 30,
    ["Scream Blast"] = 40,
    ["Solvere Tenebris Sanguinis"] = 18,
    ["Coin Toss"] = 18,
    ["Channel"] = 10,
    ["Rock Throw"] = 100,
    ["Telekinetic Head Rip"] = 20,
    ["Stellabunde"] = 25,
    ["Mud Golem"] = 25,
    ["Ember Vortex"] = 20,
    ["Spiritus Vortex"] = 37,
    ["Volare Scalpere"] = 30,
    ["Apparaitre Apparebis"] = 200,
    ["Musical Chairs"] = 400,
    ["Phasmatos Tribum Solaris Circulum"] = 50,
    ["Phasmatos Tribum, Melan veras raddiam"] = 20,
    ["Expression Grimoire"] = 200,
    ["Sol"] = 400,
    ["Puppet Crown"] = 400,
    ["Dark Magic Blast"] = 95,
    ["Psychic Dimension"] = 20,
    ["Grinchify"] = 16,
    ["Blood Blade"] = 5,
    ["Strangulo Ventus"] = 30,
    ["Telekinetic Slam"] = 25,
    ["Autem"] = 200,
    ["Summon Grinches"] = 16,
    ["Dunked"] = 400,
    ["Somnus"] = 37,
    ["Bone Break Combo"] = 25,
    ["Combat Combo"] = 5,
    ["Lux Abiit"] = 200,
    ["Heart Rip"] = 5,
    ["Ah Sha Lana"] = 47,
    ["Aleora Subsitos"] = 10,
    ["Volare Hasta"] = 30,
    ["Levitate"] = 200,
    ["Regnum Confractus"] = 100,
    ["Lifted Throw"] = 5,
    ["Choke"] = 5,
    ["Vis Ventorum"] = 100,
    ["Wolf Bite"] = 20,
    ["Invisique Confero"] = 20,
    ["Graveyard Consecration"] = 100,
    ["Summon Rika"] = 400,
    ["Hope's Repulse"] = 37,
    ["Psychic Compulsion"] = 7.5,
    ["Venom Bite"] = 15,
    ["Siphon"] = 5,
    ["Phasmatos Ravaros On Animum"] = 10,
    ["Map Tracking"] = 25,
    ["Drain Blood"] = 5,
    ["Channel Ancestors"] = 200,
    ["Head Siphon"] = 20,
    ["Glace Solidatur"] = 20,
    ["Cleansing Aura"] = 37,
    ["Muse Vision"] = 200,
    ["Fire Wisps"] = 100,
    ["Body Jump"] = 40,
    ["Dark Josie Teleport"] = 200,
    ["Corvus Examen"] = 200,
    ["Osculum Tenebris"] = 35,
    ["Channel Bloodline"] = 200,
    ["Ad Somnum"] = 20,
    ["Davina Channel Ancestors"] = 200,
    ["Arcanosphere"] = 15,
    ["Motus Corporis"] = 20,
    ["Choke Out"] = 50,
    ["Arm Break"] = 20,
    ["Trickster"] = 100,
    ["Ex Spiritum In Tacullum"] = 200,
    ["Confuso Fatina, Ignos et Ignos Mortifina"] = 30,
    ["Tenebris Crepitus"] = 200,
    ["Blood Boil"] = 15,
    ["Second Wind"] = 60,
    ["Siphon Blast"] = 400,
    ["Post Tenebras Spero Lucem"] = 200,
    ["Lecutio Maxima"] = 16,
    ["Poison Blood"] = 200,
    ["Ice Shard"] = 100,
    ["Mass Siphon"] = 30,
    ["Delfan Eoten Cor"] = 30,
}

local OriginalRanges          = {}
local ActiveTargetingObjects  = setmetatable({}, { __mode = "k" })
local currentRangeTarget      = nil -- Alvo do Range Expander (segue o mouse)
local PredictionAmount        = 0.165

local function getExpandedRange(original)
    if original <= 10 then
        return original + 3
    elseif original <= 50 then
        return original + 10
    else
        return original + 15
    end
end

local function getMousePosition()
    return UserInputService:GetMouseLocation()
end

local function getPositionOnScreen(position)
    local vec3, onScreen = WorldToScreen(Camera, position)
    return Vector2.new(vec3.X, vec3.Y), onScreen
end

local function isAbilityIgnored(abilityName)
    if not abilityName or type(abilityName) ~= "string" then return false end
    for _, name in ipairs(Settings.IgnoredAbilities) do
        if string.lower(abilityName) == string.lower(name) then return true end
    end
    if string.find(string.lower(abilityName), "teleport") or string.find(string.lower(abilityName), "blink") then return true end

    local isProjectile = false
    for _, proj in ipairs(Settings.ProjectileAbilities) do
        if string.lower(abilityName) == string.lower(proj) then
            isProjectile = true
            break
        end
    end

    if isProjectile and not Settings.ProjectileSilentAim then
        return true
    end

    return false
end

local function canTarget(player, abilityNameOverride)
    if player == LocalPlayer then return false end
    if Settings.IgnoreFriends and player:IsFriendsWith(LocalPlayer.UserId) then
        local isException = false
        local abilityName = abilityNameOverride
        if not abilityName and AbilityHandler and AbilityHandler.activeAbility then
            abilityName = AbilityHandler.activeAbility._name
        end
        if abilityName and Settings.IgnoreFriendsExceptions then
            for _, ex in ipairs(Settings.IgnoreFriendsExceptions) do
                if ex == abilityName then
                    isException = true
                    break
                end
            end
        end
        if not isException then return false end
    end
    local char = player.Character
    if not char then return false end
    if char:GetAttribute("GodMode") or char:GetAttribute("NoDamage") then return false end
    return true
end

local function getClosestPlayer(maxWorldDist, abilityName, fovOverride)
    local closest, closestDist = nil, math.huge
    local worldLimit = maxWorldDist or math.huge
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (FindFirstChild(myChar, "HumanoidRootPart") or FindFirstChild(myChar, "Torso"))

    local isProjectile = false
    if abilityName then
        for _, proj in ipairs(Settings.ProjectileAbilities) do
            if string.lower(abilityName) == string.lower(proj) then
                isProjectile = true
                break
            end
        end
    end
    local bestIsRagdolled = false

    for _, player in next, GetPlayers(Players) do
        if not canTarget(player, abilityName) then continue end
        local char = player.Character
        local root = char and (FindFirstChild(char, "HumanoidRootPart") or FindFirstChild(char, "Torso"))
        local humanoid = char and FindFirstChild(char, "Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then continue end

        if myRoot then
            local worldDist = (root.Position - myRoot.Position).Magnitude
            if worldDist > worldLimit then continue end
        end

        -- Checa TODAS as partes do corpo (R6 e R15)
        local checkParts = {
            root,
            FindFirstChild(char, "Head"),
            -- R15
            FindFirstChild(char, "UpperTorso"),
            FindFirstChild(char, "LowerTorso"),
            FindFirstChild(char, "LeftUpperArm"),
            FindFirstChild(char, "LeftLowerArm"),
            FindFirstChild(char, "LeftHand"),
            FindFirstChild(char, "RightUpperArm"),
            FindFirstChild(char, "RightLowerArm"),
            FindFirstChild(char, "RightHand"),
            FindFirstChild(char, "LeftUpperLeg"),
            FindFirstChild(char, "LeftLowerLeg"),
            FindFirstChild(char, "LeftFoot"),
            FindFirstChild(char, "RightUpperLeg"),
            FindFirstChild(char, "RightLowerLeg"),
            FindFirstChild(char, "RightFoot"),
            -- R6
            FindFirstChild(char, "Left Arm"),
            FindFirstChild(char, "Right Arm"),
            FindFirstChild(char, "Left Leg"),
            FindFirstChild(char, "Right Leg"),
        }
        local mousePos = getMousePosition()
        local bestDist = math.huge
        for _, part in ipairs(checkParts) do
            if part then
                local screenPos, onScreen = getPositionOnScreen(part.Position)
                if onScreen then
                    local d = (mousePos - screenPos).Magnitude
                    if d < bestDist then bestDist = d end
                end
            end
        end

        if bestDist <= (fovOverride or Settings.FOVRadius) then
            local isRagdolled = char:GetAttribute("ragdoll") == true
            if isProjectile then
                if isRagdolled and not bestIsRagdolled then
                    closest = root
                    closestDist = bestDist
                    bestIsRagdolled = true
                elseif isRagdolled == bestIsRagdolled then
                    if bestDist < closestDist then
                        closest = root
                        closestDist = bestDist
                    end
                end
            else
                if bestDist < closestDist then
                    closest = root
                    closestDist = bestDist
                end
            end
        end
    end
    return closest
end

local function getClosestPlayerRaw(maxWorldDist, abilityName)
    local closest, closestDist = nil, math.huge
    local worldLimit = maxWorldDist or math.huge
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (FindFirstChild(myChar, "HumanoidRootPart") or FindFirstChild(myChar, "Torso"))
    local mousePos = getMousePosition()

    local isProjectile = false
    if abilityName then
        for _, proj in ipairs(Settings.ProjectileAbilities) do
            if string.lower(abilityName) == string.lower(proj) then
                isProjectile = true
                break
            end
        end
    end
    local bestIsRagdolled = false

    for _, player in next, GetPlayers(Players) do
        if not canTarget(player, abilityName) then continue end
        local char = player.Character
        local root = char and
        (FindFirstChild(char, "Torso") or FindFirstChild(char, "UpperTorso") or FindFirstChild(char, "HumanoidRootPart"))
        local humanoid = char and FindFirstChild(char, "Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then continue end

        if myRoot then
            local worldDist = (root.Position - myRoot.Position).Magnitude
            if worldDist > worldLimit then continue end
        end

        local screenPos, onScreen = getPositionOnScreen(root.Position)
        if not onScreen then continue end

        local screenDist = (mousePos - screenPos).Magnitude
        local isRagdolled = char:GetAttribute("ragdoll") == true

        if isProjectile then
            if isRagdolled and not bestIsRagdolled then
                closest = root
                closestDist = screenDist
                bestIsRagdolled = true
            elseif isRagdolled == bestIsRagdolled then
                if screenDist < closestDist then
                    closest = root
                    closestDist = screenDist
                end
            end
        else
            if screenDist < closestDist then
                closest = root
                closestDist = screenDist
            end
        end
    end
    return closest
end

-- (Função getClosestPlayerByWorld removida pois agora tudo segue o mouse)

-- Spam Helper
local function getSpamTarget()
    local target = getClosestPlayer(80, nil, math.huge)
    if target then return target.Parent end
    return nil
end

local function updateAbilityRange(restore)
    local abilityDataModule = ReplicatedStorage:FindFirstChild("ModuleScripts"):FindFirstChild("Data"):FindFirstChild(
    "AbilityData")
    if not abilityDataModule then return end
    local abilityData = require(abilityDataModule)
    if type(abilityData) ~= "table" then return end

    for key, ability in next, abilityData do
        if type(ability) == "table" then
            if OriginalRanges[key] == nil then
                OriginalRanges[key] = CustomLimits[key] or ability.range or 20
            end
            if restore then
                ability.range = OriginalRanges[key]
            else
                local original = OriginalRanges[key]
                ability.range = getExpandedRange(original)
            end
        end
    end
end

local function refreshAllRanges(restore)
    updateAbilityRange(restore)
    for targetingObj in pairs(ActiveTargetingObjects) do
        local abilityName = targetingObj.TargetInfo and targetingObj.TargetInfo._name
        if abilityName and OriginalRanges[abilityName] then
            local original = OriginalRanges[abilityName]
            local newRange = restore and original or getExpandedRange(original)

            targetingObj._range = newRange
            if targetingObj.TargetInfo then targetingObj.TargetInfo._range = newRange end

            if targetingObj.EntityPrompts then
                for _, prompt in pairs(targetingObj.EntityPrompts) do
                    prompt.MaxActivationDistance = newRange
                    prompt.RequiresLineOfSight = Settings.WallCheck
                end
            end
        end
    end
end

task.spawn(function()
    local hitDetection, targetingModule
    for _, v in next, getgc(true) do
        if type(v) == "table" then
            if not hitDetection and rawget(v, "HitscanMobile") and rawget(v, "Hitscan") then
                hitDetection = v
            end
            if not targetingModule and rawget(v, "CreateTargetProximityPrompt") and rawget(v, "new") then
                targetingModule = v
            end
        end
        if hitDetection and targetingModule then break end
    end

    if hitDetection then
        local oldHitscan = hitDetection.Hitscan
        hitDetection.Hitscan = function(data)
            local myChar = LocalPlayer.Character
            local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))

            local abilityName = data._name
            if isAbilityIgnored(abilityName) then
                return oldHitscan(data)
            end

            local baseRange = (abilityName and OriginalRanges[abilityName]) or
            (abilityName and CustomLimits[abilityName]) or data._range or 20
            local expandedRange = getExpandedRange(baseRange)

            -- Silent Aim: usa o range ORIGINAL e respeita o FOV
            if Settings.Enabled and myRoot then
                local target = getClosestPlayer(baseRange, abilityName)
                if target then
                    local player = Players:GetPlayerFromCharacter(target.Parent)
                    if player and canTarget(player, abilityName) then
                        local dist = (target.Position - myRoot.Position).Magnitude
                        if dist <= baseRange then return target.Parent end
                    end
                end
            end

            -- Range Expander: usa o range EXPANDIDO, alvo mais próximo do mouse (sem limite FOV)
            if Settings.RangeExpander and myRoot then
                local target = getClosestPlayer(expandedRange, abilityName, math.huge)
                if target then
                    local player = Players:GetPlayerFromCharacter(target.Parent)
                    if player and canTarget(player, abilityName) then
                        local dist = (target.Position - myRoot.Position).Magnitude
                        if dist <= expandedRange then return target.Parent end
                    end
                end
            end

            return oldHitscan(data)
        end
    end

    if targetingModule then
        local oldNew = targetingModule.new
        targetingModule.new = function(targetType, targetInfo, callback)
            local newObj = oldNew(targetType, targetInfo, callback)

            if type(newObj) == "table" then
                ActiveTargetingObjects[newObj] = true

                if Settings.RangeExpander and targetInfo and targetInfo._name then
                    local abilityName = targetInfo._name
                    local original = OriginalRanges[abilityName] or CustomLimits[abilityName]
                    if original then
                        if not OriginalRanges[abilityName] then OriginalRanges[abilityName] = original end
                        local expanded = getExpandedRange(original)
                        newObj._range = expanded
                        if newObj.TargetInfo then newObj.TargetInfo._range = expanded end
                    end
                end

                task.defer(function()
                    if newObj.EntityPrompts then
                        for _, prompt in pairs(newObj.EntityPrompts) do
                            if Settings.RangeExpander then prompt.MaxActivationDistance = newObj._range or
                                prompt.MaxActivationDistance end
                            prompt.RequiresLineOfSight = Settings.WallCheck
                        end
                    end
                end)

                local oldCallback = newObj.Callback
                if type(oldCallback) == "function" then
                    newObj.Callback = function(self, entity, ...)
                        if Settings.RangeExpander then
                            local abilityName = targetInfo and targetInfo._name or ""
                            local isBlacklisted = isAbilityIgnored(abilityName)

                            if not isBlacklisted and typeof(entity) ~= "Vector3" and typeof(entity) ~= "CFrame" and typeof(entity) ~= "number" and typeof(entity) ~= "RaycastResult" then
                                local entityIsPlayer = false
                                if entity then
                                    local entityChar = (typeof(entity) == "Instance" and entity:IsA("Model") and entity)
                                        or (typeof(entity) == "Instance" and entity.Parent and entity.Parent:IsA("Model") and entity.Parent)
                                    if entityChar and Players:GetPlayerFromCharacter(entityChar) then entityIsPlayer = true end
                                end

                                if not entityIsPlayer then
                                    local myChar = LocalPlayer.Character
                                    local myRoot = myChar and
                                    (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
                                    local abilityRange = newObj._range or 20

                                    if targetType == "Entity" or targetType == "Character" or targetType == "Player" or targetType == nil or type(targetType) ~= "string" then
                                        local target = getClosestPlayer(abilityRange, abilityName, math.huge)
                                        if target and myRoot then
                                            local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
                                            if targetPlayer and canTarget(targetPlayer, abilityName) then
                                                if (target.Position - myRoot.Position).Magnitude <= abilityRange then
                                                    entity = target.Parent
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        local res = oldCallback(self, entity, ...)

                        if Settings.IgnoreFriends and res then
                            local isException = false
                            local abilityName = targetInfo and targetInfo._name or ""
                            if Settings.IgnoreFriendsExceptions then
                                for _, ex in ipairs(Settings.IgnoreFriendsExceptions) do
                                    if ex == abilityName then
                                        isException = true
                                        break
                                    end
                                end
                            end

                            if not isException then
                                if typeof(res) == "Instance" then
                                    local targetChar = (res:IsA("Model") and res) or
                                    (res.Parent and res.Parent:IsA("Model") and res.Parent) or
                                    (res.Parent and res.Parent.Parent and res.Parent.Parent:IsA("Model") and res.Parent.Parent)
                                    local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
                                    if targetPlayer and targetPlayer ~= LocalPlayer and targetPlayer:IsFriendsWith(LocalPlayer.UserId) then
                                        return nil
                                    end
                                end
                            end
                        end
                        return res
                    end
                end
            end
            return newObj
        end
    end

    task.spawn(function()
        local playerScripts = LocalPlayer:WaitForChild("PlayerScripts", 10)
        if playerScripts then
            local moduleScripts = playerScripts:WaitForChild("ModuleScripts", 10)
            if moduleScripts then
                local movModule = moduleScripts:WaitForChild("EnhancedMovementClient", 10)
                if movModule then
                    local mod = require(movModule)
                    if type(mod) == "table" and type(mod.playerJumpRequested) == "function" then
                        mod.playerJumpRequested = function() end
                    end
                end
            end
        end
    end)
end)

local currentClosestPlayer = nil -- Alvo do Silent Aim (com FOV)

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = Settings.FOVRadius
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

RunService.RenderStepped:Connect(function()
    if Settings.Enabled then
        currentClosestPlayer = getClosestPlayer()
        fov_circle.Visible = true
        fov_circle.Position = getMousePosition()
    else
        currentClosestPlayer = nil
        fov_circle.Visible = false
    end

    if Settings.RangeExpander then
        currentRangeTarget = getClosestPlayer(nil, nil, math.huge)
    else
        currentRangeTarget = nil
    end
end)

-- Loop principal do Spam
RunService.Heartbeat:Connect(function()
    if not Settings.SpamEnabled then return end

    local ability = AbilityHandler.activeAbility
    if not ability or not ability._name then return end

    local name = ability._name
    local timeLeft = ClientDebounce.getTimeLeft(name)

    if not timeLeft or timeLeft <= 0 then
        local target = getSpamTarget()
        if not target then return end

        for i = 1, Settings.PacketBurst do
            AbilityRemote:FireServer(target)
        end

        ability._isHolding = true
        if ability.activated then
            task.spawn(function() ability:activated() end)
        end

        local data = AbilityData[name]
        local cd   = data and data.cooldown or 0.5
        if Settings.IgnoreCooldown then cd = 0 end
        ClientDebounce.set(name, cd)
    end
end)

local function getDirection(origin, position)
    return (position - origin).Unit * 1000
end

local function isValidAimRay(direction)
    if direction.Magnitude < 15 then return false end
    if direction.Unit.Y < -0.8 then return false end
    if direction.Unit.Y > 0.95 and math.abs(direction.Unit.X) < 0.05 and math.abs(direction.Unit.Z) < 0.05 then return false end
    return true
end

local function getCurrentAbilityName()
    local ok, ability = pcall(function()
        return AbilityHandler and AbilityHandler.activeAbility
    end)
    if ok and ability and ability._name then
        return ability._name
    end
    return nil
end

local function isCurrentAbilityProjectile()
    local name = getCurrentAbilityName()
    if not name then return false end
    for _, proj in ipairs(Settings.ProjectileAbilities) do
        if string.lower(name) == string.lower(proj) then
            return true
        end
    end
    return false
end

local function shouldBlockSilentAim()
    -- Se a habilidade atual é um projétil e ProjectileSilentAim está desligado, bloqueia
    if isCurrentAbilityProjectile() and not Settings.ProjectileSilentAim then
        return true
    end
    -- Se a habilidade atual está na lista de ignoradas, bloqueia
    local name = getCurrentAbilityName()
    if name and isAbilityIgnored(name) then
        return true
    end
    return false
end

local function getSilentAimOrigin(originalOrigin)
    local activeTarget = currentClosestPlayer or currentRangeTarget
    if not activeTarget then return originalOrigin end
    if not Settings.WallCheck then
        return activeTarget.Position + Vector3.new(0, 2, 0)
    end
    return originalOrigin
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()

    -- [ AUTO-DROP SPAM LOGIC ]
    if Settings.SpamEnabled and method == "InvokeServer" and self.Name == "RequestToReleasePlayer" then
        local targetToDrop = select(1, ...)
        task.spawn(function()
            local ability = AbilityHandler.activeAbility
            if ability and ability._name then
                local name = ability._name
                local timeLeft = ClientDebounce.getTimeLeft(name)

                if not timeLeft or timeLeft <= 0 then
                    local finalTarget = targetToDrop or getSpamTarget()
                    if finalTarget then
                        for i = 1, Settings.PacketBurst do
                            AbilityRemote:FireServer(finalTarget)
                        end

                        ability._isHolding = true
                        if ability.activated then
                            task.spawn(function() ability:activated() end)
                        end

                        local data = AbilityData[name]
                        local cd   = data and data.cooldown or 0.5
                        if Settings.IgnoreCooldown then cd = 0 end
                        ClientDebounce.set(name, cd)
                    end
                end
            end
        end)
    end

    -- [ SILENT AIM LOGIC ]
    local activeTarget = currentClosestPlayer or currentRangeTarget
    local aimActive = (Settings.Enabled or Settings.RangeExpander)

    if aimActive and self == workspace and not checkcaller() and activeTarget and not shouldBlockSilentAim() then
        if getcallingscript then
            local cs = getcallingscript()
            if cs then
                local name = cs.Name
                if name == "CameraModule" or name == "Poppercam" or name == "TransparencyController" or string.find(name, "Camera") then
                    return oldNamecall(self, ...)
                end
                if name == "EnhancedMovementClient" or string.find(name:lower(), "move") or string.find(name:lower(), "jump") or string.find(name:lower(), "control") then
                    return oldNamecall(self, ...)
                end
            end
        end

        if method == "Raycast" then
            local args = { ... }
            local origin, direction = args[1], args[2]
            if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" and isValidAimRay(direction) then
                local newOrigin = getSilentAimOrigin(origin)
                args[1] = newOrigin
                args[2] = getDirection(newOrigin, activeTarget.Position)
                return oldNamecall(self, unpack(args))
            end
        elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRay" then
            local args = { ... }
            local ray = args[1]
            if typeof(ray) == "Ray" and isValidAimRay(ray.Direction) then
                local newOrigin = getSilentAimOrigin(ray.Origin)
                args[1] = Ray.new(newOrigin, getDirection(newOrigin, activeTarget.Position))
                return oldNamecall(self, unpack(args))
            end
        end
    end

    return oldNamecall(self, ...)
end))

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
    local activeTarget = currentClosestPlayer or currentRangeTarget
    if self == Mouse and not checkcaller() and activeTarget then
        if (Settings.Enabled or Settings.RangeExpander) and not shouldBlockSilentAim() then
            if index == "Target" or index == "target" then
                return activeTarget
            elseif index == "Hit" or index == "hit" then
                if Settings.MouseHitPrediction then return activeTarget.CFrame +
                    (activeTarget.Velocity * PredictionAmount) end
                return activeTarget.CFrame
            end
        end
    end
    return oldIndex(self, index)
end))

task.spawn(function() updateAbilityRange(false) end)

local MacLib
pcall(function()
    if isfile and isfile("macui.lua") then
        MacLib = loadstring(readfile("macui.lua"))()
    else
        MacLib = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/biggaboy212/Public-Resources/main/MacLib/maclib.lua"))()
    end
end)

if type(MacLib) == "function" then MacLib = MacLib() end
if type(MacLib) ~= "table" then return end

local Window = MacLib:Window({
    Title = "The Vampire Legends 2",
    Subtitle = "",
    Size = UDim2.fromOffset(868, 650),
    DragStyle = 1
})

local TabGroup = Window:TabGroup()

-- TAB 1: COMBAT
local CombatTab = TabGroup:Tab({ Name = "Combat", Image = "rbxassetid://13060262529" })

local CombatSec = CombatTab:Section({ Name = "Combat", Side = "Left" })
CombatSec:Paragraph({
    Header = "Silent Aim",
    Body =
    "Trava a mira no jogador mais próximo do seu mouse. Respeita o FOV configurado e verifica em todas as partes do corpo."
})
CombatSec:Toggle({
    Name = "Silent Aim",
    Default = Settings.Enabled,
    Callback = function(v)
        Settings.Enabled = v
        if not v then fov_circle.Visible = false end
    end
})
CombatSec:Toggle({
    Name = "Ignore Friends",
    Default = Settings.IgnoreFriends,
    Callback = function(v) Settings.IgnoreFriends = v end
})
CombatSec:Toggle({
    Name = "Projectile Silent Aim",
    Default = Settings.ProjectileSilentAim,
    Callback = function(v) Settings.ProjectileSilentAim = v end
})
CombatSec:Toggle({
    Name = "Wall Check",
    Default = Settings.WallCheck,
    Callback = function(v)
        Settings.WallCheck = v
        refreshAllRanges(not Settings.RangeExpander)
    end
})

local RangeSec = CombatTab:Section({ Name = "Expansor de Alcance", Side = "Right" })
RangeSec:Paragraph({
    Header = "Expansor de Alcance",
    Body = "Aumenta o alcance das habilidades suportadas. Não interfere no Silent Aim — funciona de forma independente."
})
RangeSec:Toggle({
    Name = "Range Expander",
    Default = Settings.RangeExpander,
    Callback = function(v)
        Settings.RangeExpander = v
        refreshAllRanges(not v)
    end
})

-- TAB 2: MAGIC (Channel Stealer / Exploits)
local MagicTab = TabGroup:Tab({ Name = "Magic", Image = "rbxassetid://96932333352456" })

local MagicSec = MagicTab:Section({ Name = "Exploits de Magia", Side = "Left" })
MagicSec:Paragraph({
    Header = "Como Usar",
    Body =
    "Peça a um amigo para usar Channel ou Inspire em você. O prompt será ocultado e a magia será salva. Clique nos botões abaixo para aceitar à força várias vezes!"
})

local UiStatusPara = MagicSec:Paragraph({
    Header = "Status",
    Body = MagicStatus.channel .. "\n" .. MagicStatus.inspire
})

task.spawn(function()
    task.wait(1.5)

    local statusLabel = nil

    local function findStatusLabel()
        -- 1) Inspeciona propriedades do objeto MacLib diretamente
        if type(UiStatusPara) == "table" then
            for _, v in pairs(UiStatusPara) do
                if typeof(v) == "Instance" then
                    if v:IsA("TextLabel") and v.Text and
                        (v.Text:find("Channel") or v.Text:find("Inspire")) then
                        return v
                    end
                    local ok, desc = pcall(function() return v:GetDescendants() end)
                    if ok then
                        for _, d in ipairs(desc) do
                            if d:IsA("TextLabel") and d.Text and
                                (d.Text:find("Channel") or d.Text:find("Inspire")) then
                                return d
                            end
                        end
                    end
                end
            end
        end

        -- 2) Busca em PlayerGui e CoreGui
        local roots = {
            LocalPlayer:FindFirstChildOfClass("PlayerGui"),
            game:GetService("CoreGui"),
        }
        for _, root in ipairs(roots) do
            if root then
                local ok, desc = pcall(function() return root:GetDescendants() end)
                if ok then
                    for _, v in ipairs(desc) do
                        if v:IsA("TextLabel") and v.Text and
                            (v.Text:find("Channel") or v.Text:find("Inspire")) and
                            not v.Text:find("Forçar") and not v.Text:find("Force") then
                            return v
                        end
                    end
                end
            end
        end
        return nil
    end

    statusLabel = findStatusLabel()

    local lastText = ""
    while task.wait(0.5) do
        local newText = MagicStatus.channel .. "\n" .. MagicStatus.inspire
        if newText ~= lastText then
            lastText = newText
            local valid = statusLabel and pcall(function() return statusLabel.Parent end)
            if valid then
                pcall(function() statusLabel.Text = newText end)
            else
                statusLabel = findStatusLabel()
                if statusLabel then
                    pcall(function() statusLabel.Text = newText end)
                end
            end
        end
    end
end)

MagicSec:Button({
    Name = "Forçar Channel",
    Callback = function()
        if SavedChannelRemote then
            SavedChannelRemote:FireServer()
            print("[+] Usou Channel! (" .. RemetenteChannel .. ")")
        else
            warn("[-] Nenhuma magia salva! Alguem precisa mandar Channel em voce.")
        end
    end
})

MagicSec:Button({
    Name = "Forçar Inspire",
    Callback = function()
        if SavedInspireRemote then
            SavedInspireRemote:FireServer()
            print("[+] Usou Inspire! (" .. RemetenteInspire .. ")")
        else
            warn("[-] Nenhuma vida salva! Alguem precisa mandar Inspire em voce.")
        end
    end
})

-- TAB 3: SPAM / CANCEL
local SpamTab = TabGroup:Tab({ Name = "Spam", Image = "rbxassetid://13060727541" })

local SpamSec = SpamTab:Section({ Name = "Configuração de Spam", Side = "Left" })
SpamSec:Paragraph({
    Header = "Animation Cancel / Spam",
    Body =
    "Remove o delay do cliente e atira no servidor instantaneamente. Possui Auto-Drop embutido para causar dano no milissegundo exato em que o alvo é solto."
})

SpamSec:Toggle({
    Name = "Ativar Spam (R) key",
    Default = Settings.SpamMasterSwitch,
    Callback = function(v)
        Settings.SpamMasterSwitch = v
        Settings.SpamEnabled = v

        pcall(function()
            if type(MacLib) == "table" and MacLib.Notify then
                MacLib:Notify({
                    Title = "SPAM",
                    Description = v and "✅" or "❌",
                    Time = 0.7
                })
            elseif type(Window) == "table" and Window.Notify then
                Window:Notify({
                    Title = "SPAM",
                    Description = v and "✅" or "❌",
                    Time = 0.7
                })
            end
        end)

        if v and Settings.AutoDrop then
            local targetChar = getSpamTarget()
            if targetChar then
                task.spawn(function()
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    local carrySvc = remotes and remotes:FindFirstChild("CarryService")
                    if carrySvc and carrySvc:FindFirstChild("RequestToReleasePlayer") then
                        carrySvc.RequestToReleasePlayer:InvokeServer(targetChar)
                    end
                end)
            end
        end
    end
})

SpamSec:Toggle({
    Name = "Auto-Drop",
    Default = Settings.AutoDrop,
    Callback = function(v) Settings.AutoDrop = v end
})

SpamSec:Toggle({
    Name = "Ignorar Cooldown do Cliente",
    Default = Settings.IgnoreCooldown,
    Callback = function(v) Settings.IgnoreCooldown = v end
})

SpamSec:Slider({
    Name = "Packet Burst (Multi-Hit)",
    Default = 50,
    Minimum = 1,
    Maximum = 50,
    DisplayMethod = "Value",
    Callback = function(v) Settings.PacketBurst = v end
})

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Settings.SpamKeybind then
        if not Settings.SpamMasterSwitch then return end

        Settings.SpamEnabled = not Settings.SpamEnabled

        pcall(function()
            if type(MacLib) == "table" and MacLib.Notify then
                MacLib:Notify({
                    Title = "SPAM",
                    Description = Settings.SpamEnabled and "✅" or "❌",
                    Time = 0.1
                })
            elseif type(Window) == "table" and Window.Notify then
                Window:Notify({
                    Title = "SPAM",
                    Description = Settings.SpamEnabled and "✅" or "❌",
                    Time = 0.1
                })
            end
        end)

        if Settings.SpamEnabled and Settings.AutoDrop then
            local targetChar = getSpamTarget()
            if targetChar then
                task.spawn(function()
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    local carrySvc = remotes and remotes:FindFirstChild("CarryService")
                    if carrySvc and carrySvc:FindFirstChild("RequestToReleasePlayer") then
                        carrySvc.RequestToReleasePlayer:InvokeServer(targetChar)
                    end
                end)
            end
        end
    end
end)
