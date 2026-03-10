-- ╔══════════════════════════════════════╗
-- ║        KAITUN BOSS (ALL) SCRIPT       ║
-- ║     Auto Farm All Boss In Server      ║
-- ╚══════════════════════════════════════╝

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

local Plr = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

-- ─── World Detection ───
local World1 = (PlaceId == 2753915549 or PlaceId == 85211729168715)
local World2 = (PlaceId == 4442272183 or PlaceId == 79091703265657)
local World3 = (PlaceId == 7449423635 or PlaceId == 100117331123089)

-- ─── Boss Lists Per Sea ───
local BossListW1 = {
    "The Gorilla King",
    "Bobby",
    "Yeti",
    "Mob Leader",
    "Vice Admiral",
    "Warden",
    "Chief Warden",
    "Swan",
    "Magma Admiral",
    "Fishman Lord",
    "Wysper",
    "Thunder God",
    "Cyborg",
    "Saber Expert",
}

local BossListW2 = {
    "Diamond",
    "Jeremy",
    "Fajita",
    "Don Swan",
    "Smoke Admiral",
    "Cursed Captain",
    "Darkbeard",
    "Order",
    "Awakened Ice Admiral",
    "Tide Keeper",
}

local BossListW3 = {
    "Terrorshark",
    "Stone",
    "Island Empress",
    "Kilo Admiral",
    "Captain Elephant",
    "Beautiful Pirate",
    "rip_indra True Form",
    "Longma",
    "Soul Reaper",
    "Cake Queen",
    "Tyrant of the Skies",
}

-- Boss bị loại trừ
local SkipBoss = {
    ["Ice Admiral"] = true,
}

local function getBossList()
    if World1 then return BossListW1
    elseif World2 then return BossListW2
    elseif World3 then return BossListW3
    end
    return BossListW1
end

-- ─── State ───
_G.KaitunAllBoss = true
local killedBosses = {}
local currentBossName = "Searching..."
local currentDistance = 0
local uiVisible = true

-- ─── Bay tới trên đầu boss và GHİM ở đó (BodyPosition, không rơi) ───
local _currentBP = nil  -- BodyPosition đang giữ vị trí

local function clearBodyForces(hrp)
    for _, obj in pairs(hrp:GetChildren()) do
        if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro")
        or obj:IsA("BodyPosition") or obj:IsA("AlignPosition")
        or obj:IsA("AlignOrientation") then
            obj:Destroy()
        end
    end
    _currentBP = nil
end

local function tweenTo(targetPos)
    -- targetPos: Vector3 (vị trí đích, đã tính offset trên đầu boss)
    pcall(function()
        local char = Plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        clearBodyForces(hrp)

        local dist = (targetPos - hrp.Position).Magnitude
        local duration = math.max(dist / 350, 0.05)

        -- Tween di chuyển tới đích
        local tw = TweenService:Create(
            hrp,
            TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
            { CFrame = CFrame.new(targetPos) }
        )
        tw:Play()
        tw.Completed:Wait()

        -- Sau khi tới nơi, ghim bằng BodyPosition để không rơi
        if hrp and hrp.Parent then
            local bp = Instance.new("BodyPosition")
            bp.Name = "KaitunHold"
            bp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bp.D = 1000
            bp.P = 10000
            bp.Position = targetPos
            bp.Parent = hrp
            _currentBP = bp
        end
    end)
end

-- Cập nhật vị trí ghim theo boss liên tục (theo dõi boss di chuyển)
local function holdAboveBoss(bossHRP)
    pcall(function()
        if _currentBP and bossHRP and bossHRP.Parent then
            _currentBP.Position = bossHRP.Position + Vector3.new(0, 18, 0)
        end
    end)
end

-- ─── Auto Buso Haki ───
local function AutoHaki()
    pcall(function()
        local char = Plr.Character
        if char and not char:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end
    end)
end

-- ─── Join Marines ───
local function JoinMarines()
    pcall(function()
        if not Plr.Team or (Plr.Team.Name ~= "Marines") then
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam", "Marines")
        end
    end)
end
JoinMarines()

-- ─── Equip Tool ───
local function EquipTool(name)
    if not name then return end
    local tool = Plr.Backpack:FindFirstChild(name)
    if tool then
        Plr.Character.Humanoid:EquipTool(tool)
        task.wait(0.05)
    end
end

-- ─── Attack System (RegisterHit) ───
local _u4 = nil
local _u5 = nil

-- Lắng nghe RemoteEvent có Id trong các thư mục RS
local _watchFolders = {
    ReplicatedStorage:WaitForChild("Util", 5),
    ReplicatedStorage:WaitForChild("Common", 5),
    ReplicatedStorage:WaitForChild("Remotes", 5),
    ReplicatedStorage:WaitForChild("Assets", 5),
    ReplicatedStorage:WaitForChild("FX", 5),
}

for _, folder in pairs(_watchFolders) do
    if not folder then continue end
    for _, child in pairs(folder:GetChildren()) do
        if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
            _u5 = child:GetAttribute("Id")
            _u4 = child
        end
    end
    folder.ChildAdded:Connect(function(child)
        if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
            _u5 = child:GetAttribute("Id")
            _u4 = child
        end
    end)
end

-- Auto Attack loop (RegisterHit) — chạy liên tục khi _G.KaitunAllBoss bật
task.spawn(function()
    while task.wait(0.0001) do
        if not _G.KaitunAllBoss then task.wait(0.5) continue end
        pcall(function()
            local _Character = Plr.Character
            if not _Character then return end
            local v13 = _Character:FindFirstChild("HumanoidRootPart")
            if not v13 then return end

            local hitTargets = {}

            for _, container in ipairs({workspace.Enemies, workspace.Characters}) do
                if not container then continue end
                for _, entity in ipairs(container:GetChildren()) do
                    local _HRP = entity:FindFirstChild("HumanoidRootPart")
                    local _Hum = entity:FindFirstChild("Humanoid")
                    if entity ~= _Character
                        and _HRP and _Hum
                        and _Hum.Health > 0
                        and (_HRP.Position - v13.Position).Magnitude <= 60
                    then
                        for _, part in ipairs(entity:GetChildren()) do
                            if part:IsA("BasePart") then
                                hitTargets[#hitTargets + 1] = {entity, part}
                            end
                        end
                    end
                end
            end

            local _Tool = _Character:FindFirstChildOfClass("Tool")
            if #hitTargets > 0 and _Tool and (
                _Tool:GetAttribute("WeaponType") == "Melee" or
                _Tool:GetAttribute("WeaponType") == "Sword"
            ) then
                pcall(function()
                    require(ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit", true)
                    ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()

                    local _Head = hitTargets[1][1]:FindFirstChild("Head")
                    if _Head and _u4 then
                        ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(
                            _Head, hitTargets, {},
                            tostring(Plr.UserId):sub(2,4) .. tostring(coroutine.running()):sub(11,15)
                        )
                        cloneref(_u4):FireServer(
                            string.gsub("RE/RegisterHit", ".", function(c)
                                return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
                            end),
                            bit32.bxor(_u5 + 909090, ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2),
                            _Head, hitTargets
                        )
                    end
                end)
            end
        end)
    end
end)

-- ─── AttackTarget: Equip melee rồi để loop trên tự đánh ───
local function AttackTarget(target)
    if not target or not target.Parent then return end
    pcall(function()
        AutoHaki()
        -- Tìm và equip melee/sword từ backpack
        local backpack = Plr.Backpack
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local wtype = tool:GetAttribute("WeaponType")
                if wtype == "Melee" or wtype == "Sword"
                    or tool.ToolTip == "Melee" or tool.Name == "Combat"
                then
                    EquipTool(tool.Name)
                    break
                end
            end
        end
    end)
end

-- ─── Find Boss ───
local function findBoss(name)
    -- Tìm trong workspace.Enemies
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if string.find(v.Name, name, 1, true) then
            return v
        end
    end
    -- Tìm trong ReplicatedStorage (boss chưa spawn vào)
    for _, v in pairs(ReplicatedStorage:GetChildren()) do
        if string.find(v.Name, name, 1, true) then
            return v
        end
    end
    return nil
end

local function isBossAlive(boss)
    if not boss or not boss.Parent then return false end
    local hum = boss:FindFirstChild("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function isBossInWorkspace(name)
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if string.find(v.Name, name, 1, true) then
            local hum = v:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                return true, v
            end
        end
    end
    return false, nil
end

-- Quét toàn bộ boss trong server một lần, trả về map {shortName -> object}
local function scanAllLiveBosses()
    local found = {}
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        local hum = v:FindFirstChild("Humanoid")
        local hrp = v:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and hrp then
            -- Lấy tên ngắn (trước dấu [)
            local short = v.Name:match("^([^%[]+)") or v.Name
            short = short:gsub("%s+$", "")
            found[short] = v
            found[v.Name] = v  -- cả tên đầy đủ
        end
    end
    return found
end

-- ─── Server Hop: không trùng, chỉ 8-10 người ───
local _visitedServers = {}  -- lưu server đã từng vào để không bị trùng

local function Hop()
    pcall(function()
        -- Đánh dấu server hiện tại là đã thăm
        _visitedServers[JobId] = true

        local servers = {}
        local cursor = ""

        -- Quét tối đa 3 trang để tìm đủ server
        for _page = 1, 3 do
            local url = "https://games.roblox.com/v1/games/" .. PlaceId
                .. "/servers/Public?sortOrder=Asc&limit=100"
                .. (cursor ~= "" and ("&cursor=" .. cursor) or "")

            local ok, data = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            if not ok or not data or not data.data then break end

            for _, s in pairs(data.data) do
                local playing = tonumber(s.playing) or 0
                local maxP    = tonumber(s.maxPlayers) or 0
                -- Chỉ lấy server 8-10 người, chưa đầy, và chưa từng vào
                if playing >= 8 and playing <= 10
                    and playing < maxP
                    and not _visitedServers[s.id]
                then
                    table.insert(servers, s.id)
                end
            end

            if #servers >= 5 then break end  -- đủ lựa chọn rồi dừng

            if data.nextPageCursor and data.nextPageCursor ~= "" and data.nextPageCursor ~= "null" then
                cursor = data.nextPageCursor
            else
                break
            end
        end

        if #servers > 0 then
            -- Chọn ngẫu nhiên trong danh sách để tránh luôn vào 1 server
            local pick = servers[math.random(1, #servers)]
            _visitedServers[pick] = true  -- đánh dấu trước khi teleport
            TeleportService:TeleportToPlaceInstance(PlaceId, pick, Plr)
        else
            -- Không tìm được → reset lịch sử và thử lại (trừ server hiện tại)
            _visitedServers = { [JobId] = true }
            TeleportService:Teleport(PlaceId, Plr)
        end
    end)
end

-- ─── Anti AFK ───
Plr.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ─── Auto Rejoin khi bị văng ───
task.spawn(function()
    while task.wait(15) do
        pcall(function()
            if not game:IsLoaded() then
                TeleportService:Teleport(PlaceId, Plr)
            end
        end)
    end
end)

-- ─── NoClip ───
RunService.Stepped:Connect(function()
    if _G.KaitunAllBoss then
        pcall(function()
            local char = Plr.Character
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end)

-- ════════════════════════════
-- ─────── BUILD UI ───────────
-- ════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KaitunBossUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Plr.PlayerGui

-- Blur màn hình (làm mờ chứ không làm đen)
local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "KaitunBlur"
blurEffect.Size = 12
blurEffect.Parent = game:GetService("Lighting")

-- Info card giữa màn hình (không có khung, trong suốt hoàn toàn)
local card = Instance.new("Frame")
card.Name = "Card"
card.Size = UDim2.new(0, 380, 0, 140)
card.Position = UDim2.new(0.5, -190, 0.5, -70)
card.BackgroundTransparency = 1
card.BorderSizePixel = 0
card.ZIndex = 5
card.Parent = screenGui

-- Title: "Kaitun Boss ( All )"
local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, 0, 0, 60)
titleLbl.Position = UDim2.new(0, 0, 0, 4)
titleLbl.BackgroundTransparency = 1
titleLbl.Font = Enum.Font.GothamBold
titleLbl.Text = "Kaitun Boss ( All )"
titleLbl.TextColor3 = Color3.fromRGB(90, 200, 255)
titleLbl.TextSize = 42
titleLbl.ZIndex = 6
titleLbl.Parent = card

-- Boss label
local bossLbl = Instance.new("TextLabel")
bossLbl.Size = UDim2.new(1, -24, 0, 30)
bossLbl.Position = UDim2.new(0, 12, 0, 68)
bossLbl.BackgroundTransparency = 1
bossLbl.Font = Enum.Font.Gotham
bossLbl.Text = "Boss: Searching..."
bossLbl.TextColor3 = Color3.fromRGB(240, 240, 255)
bossLbl.TextSize = 20
bossLbl.TextXAlignment = Enum.TextXAlignment.Left
bossLbl.ZIndex = 6
bossLbl.Parent = card

-- Distance label
local distLbl = Instance.new("TextLabel")
distLbl.Size = UDim2.new(1, -24, 0, 26)
distLbl.Position = UDim2.new(0, 12, 0, 103)
distLbl.BackgroundTransparency = 1
distLbl.Font = Enum.Font.Gotham
distLbl.Text = "Distance: --"
distLbl.TextColor3 = Color3.fromRGB(200, 220, 255)
distLbl.TextSize = 17
distLbl.TextXAlignment = Enum.TextXAlignment.Left
distLbl.ZIndex = 6
distLbl.Parent = card

-- Toggle button (top left, dưới nút avatar roblox ~64px)
local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0, 46, 0, 46)
toggleBtn.Position = UDim2.new(0, 8, 0, 66)
toggleBtn.BackgroundTransparency = 1
toggleBtn.BorderSizePixel = 0
toggleBtn.Image = "rbxassetid://16060333448"
toggleBtn.ZIndex = 10
toggleBtn.Parent = screenGui

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

toggleBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    card.Visible = uiVisible
    blurEffect.Size = uiVisible and 12 or 0
end)

-- ─── UI Update loop ───
task.spawn(function()
    while _G.KaitunAllBoss do
        task.wait(0.25)
        pcall(function()
            bossLbl.Text = "Boss: " .. tostring(currentBossName)
            distLbl.Text = "Distance: " .. tostring(math.floor(currentDistance))
        end)
    end
end)

-- ═══════════════════════════════
-- ─── MAIN BOSS FARM LOOP ───────
-- ═══════════════════════════════
task.spawn(function()
    -- Bật buso ngay khi start
    AutoHaki()

    while _G.KaitunAllBoss do
        task.wait(0.3)
        pcall(function()
            local bossList = getBossList()
            local anyNotKilled = false

            -- Quét một lần tất cả boss đang sống trong server
            local liveMap = scanAllLiveBosses()

            for _, bossName in ipairs(bossList) do
                if not _G.KaitunAllBoss then break end

                -- Bỏ qua boss bị exclude
                if SkipBoss[bossName] then continue end

                -- Đã giết rồi
                if killedBosses[bossName] then continue end

                anyNotKilled = true

                -- Tra trong liveMap (đã quét sẵn)
                local bossObj = liveMap[bossName]
                local alive = bossObj ~= nil
                    and bossObj.Parent ~= nil
                    and bossObj:FindFirstChild("Humanoid") ~= nil
                    and bossObj.Humanoid.Health > 0

                if not alive then
                    -- Boss chưa spawn → bỏ qua, thử con tiếp theo
                    currentBossName = bossName .. " (Not Spawned)"
                    task.wait(0.05)
                    continue
                end

                -- Boss đang sống, bắt đầu farm
                currentBossName = bossName

                repeat
                    task.wait(0.1)
                    pcall(function()
                        -- Refresh boss object
                        local _, freshBoss = isBossInWorkspace(bossName)
                        if not freshBoss then return end
                        bossObj = freshBoss

                        local bossHRP = bossObj:FindFirstChild("HumanoidRootPart")
                        if not bossHRP then return end

                        local charHRP = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
                        if not charHRP then return end

                        currentDistance = (bossHRP.Position - charHRP.Position).Magnitude

                        -- Bay lên đầu boss và ghim ở đó
                        local targetPos = bossHRP.Position + Vector3.new(0, 18, 0)
                        if currentDistance > 5 then
                            tweenTo(targetPos)
                        else
                            holdAboveBoss(bossHRP)
                        end

                        -- Buso + tấn công
                        AutoHaki()
                        AttackTarget(bossObj)

                        -- Hack boss (disable collision, freeze)
                        pcall(function()
                            bossHRP.CanCollide = false
                            bossHRP.Size = Vector3.new(60, 60, 60)
                            if bossObj.Humanoid then
                                bossObj.Humanoid.WalkSpeed = 0
                                bossObj.Humanoid.JumpPower = 0
                            end
                            sethiddenproperty(Plr, "SimulationRadius", math.huge)
                        end)
                    end)

                until not _G.KaitunAllBoss
                    or not isBossInWorkspace(bossName)

                -- Boss đã chết → bỏ ghim
                local stillAlive, _ = isBossInWorkspace(bossName)
                if not stillAlive then
                    pcall(function()
                        local hrp = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then clearBodyForces(hrp) end
                    end)
                    killedBosses[bossName] = true
                    currentBossName = bossName .. " ✓ Killed"
                    task.wait(0.8)
                end
            end

            -- Kiểm tra xem có boss nào spawn không
            local anySpawned = false
            for _, bossName in ipairs(bossList) do
                if not SkipBoss[bossName] and not killedBosses[bossName] then
                    local alive, _ = isBossInWorkspace(bossName)
                    if alive then anySpawned = true break end
                end
            end

            -- Không có boss nào spawn → đổi server ngay
            if not anySpawned then
                -- Kiểm tra còn boss chưa kill không
                local hasRemaining = false
                for _, bossName in ipairs(bossList) do
                    if not SkipBoss[bossName] and not killedBosses[bossName] then
                        hasRemaining = true break
                    end
                end
                if hasRemaining then
                    currentBossName = "No Boss Spawned! Hopping..."
                    task.wait(1)
                    killedBosses = {}
                    Hop()
                    task.wait(12)
                else
                    -- Tất cả đã kill hết
                    currentBossName = "All Boss Done! Hopping..."
                    task.wait(1)
                    killedBosses = {}
                    Hop()
                    task.wait(12)
                end
            end
        end)
    end
end)

print("[Kaitun] ✓ Auto Boss All Farm - STARTED!")
print("[Kaitun] Sea: " .. (World1 and "First Sea" or World2 and "Second Sea" or World3 and "Third Sea" or "Unknown"))
