-- ╔══════════════════════════════════════════════════════╗
-- ║           KAITUN BOSS (ALL)  v3.0                   ║
-- ║     Auto Farm All Boss In Server  – by Kaitun       ║
-- ║  ✦ Stable Fly (no bounce/jitter)                    ║
-- ║  ✦ Smart Hop (8-10 players, 100% no duplicate)      ║
-- ║  ✦ Full Boss Scan – skip if not spawned, no repeat  ║
-- ║  ✦ Fly-to-Boss from any location                    ║
-- ╚══════════════════════════════════════════════════════╝

local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local TweenService  = game:GetService("TweenService")
local TeleportSvc   = game:GetService("TeleportService")
local HttpService   = game:GetService("HttpService")
local RunService    = game:GetService("RunService")
local VirtualUser   = game:GetService("VirtualUser")

local Plr     = Players.LocalPlayer
local PlaceId = game.PlaceId

_G.KaitunAllBoss = true

-- ─── World Detection ───
local World1 = PlaceId == 2753915549 or PlaceId == 85211729168715
local World2 = PlaceId == 4442272183 or PlaceId == 79091703265657
local World3 = PlaceId == 7449423635 or PlaceId == 100117331123089

-- ─── Boss Lists (theo thứ tự ưu tiên) ───
local BossListW1 = {
    "The Gorilla King","Bobby","Yeti","Mob Leader","Vice Admiral",
    "Warden","Chief Warden","Swan","Magma Admiral","Fishman Lord",
    "Wysper","Thunder God","Cyborg","Saber Expert"
}
local BossListW2 = {
    "Diamond","Jeremy","Fajita","Don Swan","Smoke Admiral",
    "Cursed Captain","Darkbeard","Order","Awakened Ice Admiral","Tide Keeper"
}
local BossListW3 = {
    "Terrorshark","Stone","Island Empress","Kilo Admiral","Captain Elephant",
    "Beautiful Pirate","rip_indra True Form","Longma","Soul Reaper",
    "Cake Queen","Tyrant of the Skies"
}
local SkipBoss = {["Ice Admiral"]=true}

local function getBossList()
    if World1 then return BossListW1
    elseif World2 then return BossListW2
    elseif World3 then return BossListW3
    end
    return BossListW1
end

-- ─── State ───
local killedBosses    = {}      -- boss đã farm xong trong server này
local scannedBosses   = {}      -- boss đã quét (không spawn) → bỏ qua, không lặp
local currentBossName = "Starting..."
local currentDist     = 0
local uiVisible       = true
local flyAnchor       = nil     -- BodyPosition hiện tại để ghim vị trí

-- ─── Join Marines ───
pcall(function()
    RS:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam","Marines")
end)

-- ─── Auto Buso ───
local function AutoHaki()
    pcall(function()
        local c = Plr.Character
        if c and not c:FindFirstChild("HasBuso") then
            RS.Remotes.CommF_:InvokeServer("Buso")
        end
    end)
end

-- ─── Equip Melee ───
local function EquipMelee()
    pcall(function()
        for _, t in ipairs(Plr.Backpack:GetChildren()) do
            if t:IsA("Tool") then
                local wt = t:GetAttribute("WeaponType")
                if wt == "Melee" or wt == "Sword" or t.ToolTip == "Melee" or t.Name == "Combat" then
                    Plr.Character.Humanoid:EquipTool(t)
                    return
                end
            end
        end
    end)
end

-- ─── Attack (RegisterHit) ───
local _u4, _u5 = nil, nil
pcall(function()
    local folders = {
        RS:FindFirstChild("Util"), RS:FindFirstChild("Common"),
        RS:FindFirstChild("Remotes"), RS:FindFirstChild("Assets"), RS:FindFirstChild("FX"),
    }
    for _, f in pairs(folders) do
        if not f then continue end
        for _, c in pairs(f:GetChildren()) do
            if c:IsA("RemoteEvent") and c:GetAttribute("Id") then
                _u5 = c:GetAttribute("Id"); _u4 = c
            end
        end
        f.ChildAdded:Connect(function(c)
            if c:IsA("RemoteEvent") and c:GetAttribute("Id") then
                _u5 = c:GetAttribute("Id"); _u4 = c
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if not _G.KaitunAllBoss then continue end
        pcall(function()
            local char = Plr.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local tool = char:FindFirstChildOfClass("Tool")
            if not tool then return end
            local wt = tool:GetAttribute("WeaponType")
            if wt ~= "Melee" and wt ~= "Sword" then return end

            local hits = {}
            for _, cont in ipairs({workspace.Enemies, workspace.Characters}) do
                if not cont then continue end
                for _, e in ipairs(cont:GetChildren()) do
                    local eh = e:FindFirstChild("HumanoidRootPart")
                    local em = e:FindFirstChild("Humanoid")
                    if e ~= char and eh and em and em.Health > 0
                        and (eh.Position - hrp.Position).Magnitude <= 60 then
                        for _, p in ipairs(e:GetChildren()) do
                            if p:IsA("BasePart") then
                                hits[#hits+1] = {e, p}
                            end
                        end
                    end
                end
            end

            if #hits == 0 then return end

            pcall(function()
                require(RS.Modules.Net):RemoteEvent("RegisterHit", true)
                RS.Modules.Net["RE/RegisterAttack"]:FireServer()
                local head = hits[1][1]:FindFirstChild("Head")
                if head and _u4 then
                    RS.Modules.Net["RE/RegisterHit"]:FireServer(
                        head, hits, {},
                        tostring(Plr.UserId):sub(2,4)..tostring(coroutine.running()):sub(11,15)
                    )
                    cloneref(_u4):FireServer(
                        string.gsub("RE/RegisterHit",".",function(c)
                            return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow()/10%10)+1))
                        end),
                        bit32.bxor(_u5+909090, RS.Modules.Net.seed:InvokeServer()*2),
                        head, hits
                    )
                end
            end)
        end)
    end
end)

-- ─── NoClip ───
RunService.Stepped:Connect(function()
    if not _G.KaitunAllBoss then return end
    pcall(function()
        local c = Plr.Character
        if not c then return end
        for _, p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end)

-- ─── Anti AFK ───
Plr.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ─── Find Boss ───
local function findBoss(name)
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name:find(name, 1, true) then
            local h = v:FindFirstChild("Humanoid")
            if h and h.Health > 0 then return v end
        end
    end
    return nil
end

-- ─── Quét toàn bộ boss đang sống trong server ───
local function scanLiveBosses()
    local found = {}
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        local h = v:FindFirstChild("Humanoid")
        local r = v:FindFirstChild("HumanoidRootPart")
        if h and h.Health > 0 and r then
            found[v.Name] = v
            local short = v.Name:match("^([^%[]+)") or v.Name
            short = short:gsub("%s+$","")
            found[short] = v
        end
    end
    return found
end

-- ════════════════════════════════════════════════════════
-- ─── FLY STABLE – Không rớt, không giật, không bounce ──
-- ════════════════════════════════════════════════════════
-- Duy trì 1 BodyPosition suốt quá trình farm
-- chỉ cập nhật .Position khi target thay đổi > threshold

local FLY_HEIGHT   = 12    -- chiều cao bay trên đầu boss
local FLY_SPEED    = 300   -- studs/s khi di chuyển xa
local FLY_MAXFORCE = 1e6
local FLY_P        = 45000 -- spring stiffness
local FLY_D        = 3500  -- damping (càng cao càng ít bounce)

local function getOrCreateAnchor()
    local char = Plr.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    -- Tái sử dụng anchor cũ nếu còn
    local bp = hrp:FindFirstChild("KaitunFlyBP")
    if bp and bp:IsA("BodyPosition") then return bp end

    -- Xoá mọi force cũ trước
    for _, o in pairs(hrp:GetChildren()) do
        if o:IsA("BodyVelocity") or o:IsA("BodyPosition")
        or o:IsA("BodyGyro")    or o:IsA("AlignPosition") then
            o:Destroy()
        end
    end

    local newBP = Instance.new("BodyPosition")
    newBP.Name      = "KaitunFlyBP"
    newBP.MaxForce  = Vector3.new(FLY_MAXFORCE, FLY_MAXFORCE, FLY_MAXFORCE)
    newBP.P         = FLY_P
    newBP.D         = FLY_D
    newBP.Position  = hrp.Position   -- khởi đầu tại chỗ đứng
    newBP.Parent    = hrp
    flyAnchor = newBP
    return newBP
end

-- Xoá anchor khi không còn cần bay
local function stopFly()
    flyAnchor = nil
    pcall(function()
        local char = Plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local bp = hrp:FindFirstChild("KaitunFlyBP")
        if bp then bp:Destroy() end
    end)
end

--[[
    flyTo(targetPos)
    ─────────────────
    Di chuyển nhân vật đến targetPos một cách mượt mà.
    - Nếu xa > 80 studs: tween nhanh theo tốc độ FLY_SPEED
    - Nếu gần: chỉ cập nhật Position, D cao → không rung
    - Sau khi đến, anchor ghim vị trí → không rớt
--]]
local function flyTo(targetPos)
    local bp = getOrCreateAnchor()
    if not bp then return end

    local hrp = bp.Parent
    if not hrp then return end

    local dist = (targetPos - hrp.Position).Magnitude
    if dist < 2 then
        bp.Position = targetPos   -- ghim tại chỗ
        return
    end

    -- Tween BodyPosition.Position để di chuyển mượt
    local dur = math.clamp(dist / FLY_SPEED, 0.05, 6)
    local tw  = TweenService:Create(bp, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = targetPos})
    tw:Play()
    tw.Completed:Wait()
    -- Sau tween, đặt lại Position chính xác để BodyPosition không drift
    bp.Position = targetPos
end

--[[
    hoverOver(bossHRP)
    ──────────────────
    Liên tục cập nhật vị trí treo phía trên boss.
    Chỉ cập nhật khi boss di chuyển > 4 studs → tránh jitter.
--]]
local function hoverOver(bossHRP)
    local bp = getOrCreateAnchor()
    if not bp then return end

    local lastTarget = bp.Position
    local target = bossHRP.Position + Vector3.new(0, FLY_HEIGHT, 0)

    if (target - lastTarget).Magnitude > 4 then
        bp.Position = target
    end
end

-- ════════════════════════════════════════════════════════
-- ─── HOP SERVER – 100% không trùng, ưu tiên 8-10 người ─
-- ════════════════════════════════════════════════════════
--[[
    Thuật toán:
    1. Thu thập tối đa 500 server qua nhiều trang API
    2. Lọc: playing 8-10, còn slot, chưa thăm
    3. Nếu không còn server mới → xoá lịch sử (reset), thử lại 1 lần
    4. Nếu sau reset vẫn không có → nới rộng điều kiện (6-12 người)
    5. Nếu vẫn không có → TeleportToPlaceInstance ngẫu nhiên
--]]
local _visited   = {}
local _hopCount  = 0

local function fetchServers(minP, maxP, limit)
    local results = {}
    local cursor  = ""
    local curJob  = tostring(game.JobId)
    local pages   = 0
    local maxPages = 10   -- tối đa 10 trang × 100 = 1000 servers

    repeat
        pages = pages + 1
        local url = ("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100%s"):format(
            PlaceId, cursor ~= "" and ("&cursor="..cursor) or ""
        )
        local ok, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if not ok or not data or not data.data then break end

        for _, s in pairs(data.data) do
            local id  = tostring(s.id)
            local p   = tonumber(s.playing) or 0
            local mx  = tonumber(s.maxPlayers) or 0
            if p >= minP and p <= maxP and p < mx
                and id ~= curJob and not _visited[id]
            then
                results[#results+1] = {id=id, playing=p}
            end
        end

        local nc = data.nextPageCursor
        if nc and nc ~= "" and nc ~= "null" then
            cursor = tostring(nc)
        else
            break
        end

        if #results >= limit then break end
        task.wait(0.05)   -- nhẹ tải HTTP
    until pages >= maxPages

    return results
end

local function Hop()
    _hopCount = _hopCount + 1
    pcall(function()
        local curJob = tostring(game.JobId)
        _visited[curJob] = true

        -- Lần 1: 8-10 người
        local servers = fetchServers(8, 10, 30)

        -- Lần 2: reset visited rồi thử lại 8-10
        if #servers == 0 then
            _visited = {[curJob]=true}
            servers = fetchServers(8, 10, 30)
        end

        -- Lần 3: nới rộng 6-12
        if #servers == 0 then
            servers = fetchServers(6, 12, 30)
        end

        if #servers > 0 then
            -- Ưu tiên server có ít người hơn (farm nhanh hơn)
            table.sort(servers, function(a,b) return a.playing < b.playing end)
            -- Chọn ngẫu nhiên trong top-5 để tránh tất cả hop cùng 1 server
            local top = math.min(5, #servers)
            local pick = servers[math.random(1, top)]
            _visited[pick.id] = true
            TeleportSvc:TeleportToPlaceInstance(PlaceId, pick.id, Plr)
        else
            -- Fallback cuối: hop bất kỳ
            TeleportSvc:Teleport(PlaceId, Plr)
        end
    end)
end

-- ─── UI ───
local gui = Instance.new("ScreenGui")
gui.Name = "KaitunUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = Plr.PlayerGui

local blur = Instance.new("BlurEffect")
blur.Size = 10
blur.Parent = game:GetService("Lighting")

-- Shadow card
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(0, 410, 0, 160)
shadow.Position = UDim2.new(0.5, -203, 0.5, -78)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel = 0
shadow.Parent = gui
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 18)

local card = Instance.new("Frame")
card.Size = UDim2.new(0, 400, 0, 148)
card.Position = UDim2.new(0.5, -200, 0.5, -74)
card.BackgroundColor3 = Color3.fromRGB(8, 14, 30)
card.BackgroundTransparency = 0.08
card.BorderSizePixel = 0
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

-- Gradient stripe
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 80, 200)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 80, 200)),
}
grad.Rotation = 90
local stripe = Instance.new("Frame")
stripe.Size = UDim2.new(1, 0, 0, 3)
stripe.Position = UDim2.new(0, 0, 0, 0)
stripe.BackgroundColor3 = Color3.new(1,1,1)
stripe.BorderSizePixel = 0
stripe.Parent = card
Instance.new("UICorner", stripe).CornerRadius = UDim.new(0, 2)
grad.Parent = stripe

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -20, 0, 52)
titleLbl.Position = UDim2.new(0, 10, 0, 8)
titleLbl.BackgroundTransparency = 1
titleLbl.Font = Enum.Font.GothamBold
titleLbl.Text = "⚡ Kaitun Boss ( All )"
titleLbl.TextColor3 = Color3.fromRGB(90, 200, 255)
titleLbl.TextSize = 36
titleLbl.TextStrokeTransparency = 0.4
titleLbl.TextStrokeColor3 = Color3.fromRGB(0, 60, 140)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = card

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 62)
divider.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel = 0
divider.Parent = card

local bossLbl = Instance.new("TextLabel")
bossLbl.Size = UDim2.new(1, -20, 0, 38)
bossLbl.Position = UDim2.new(0, 10, 0, 68)
bossLbl.BackgroundTransparency = 1
bossLbl.Font = Enum.Font.GothamBold
bossLbl.Text = "🎯 Boss: Starting..."
bossLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
bossLbl.TextSize = 20
bossLbl.TextStrokeTransparency = 0.6
bossLbl.TextXAlignment = Enum.TextXAlignment.Left
bossLbl.Parent = card

local distLbl = Instance.new("TextLabel")
distLbl.Size = UDim2.new(1, -20, 0, 28)
distLbl.Position = UDim2.new(0, 10, 0, 108)
distLbl.BackgroundTransparency = 1
distLbl.Font = Enum.Font.Gotham
distLbl.Text = "📍 Distance: --  |  🔁 Hops: 0"
distLbl.TextColor3 = Color3.fromRGB(160, 210, 255)
distLbl.TextSize = 16
distLbl.TextStrokeTransparency = 0.6
distLbl.TextXAlignment = Enum.TextXAlignment.Left
distLbl.Parent = card

-- Toggle button
local btn = Instance.new("ImageButton")
btn.Size = UDim2.new(0, 44, 0, 44)
btn.Position = UDim2.new(0, 8, 0, 8)
btn.BackgroundColor3 = Color3.fromRGB(10, 30, 80)
btn.BackgroundTransparency = 0.3
btn.Image = "rbxassetid://16060333448"
btn.ZIndex = 10
btn.Parent = gui
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

btn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    card.Visible = uiVisible
    shadow.Visible = uiVisible
    blur.Size = uiVisible and 10 or 0
end)

task.spawn(function()
    while _G.KaitunAllBoss do
        task.wait(0.25)
        pcall(function()
            bossLbl.Text = "🎯 Boss: " .. currentBossName
            distLbl.Text = ("📍 Distance: %d  |  🔁 Hops: %d"):format(math.floor(currentDist), _hopCount)
        end)
    end
end)

-- ════════════════════════════════════════════════════════
-- ─── MAIN LOOP ──────────────────────────────────────────
-- ════════════════════════════════════════════════════════
task.spawn(function()
    AutoHaki()
    task.wait(5)

    -- Kiểm tra nhanh ngay khi vào server
    local initScan = scanLiveBosses()
    local hasBoss  = false
    for _, n in ipairs(getBossList()) do
        if not SkipBoss[n] and initScan[n] then hasBoss = true; break end
    end
    if not hasBoss then
        currentBossName = "No Boss → Hopping..."
        task.wait(1)
        Hop()
        task.wait(14)
    end

    -- ── MAIN ──
    while _G.KaitunAllBoss do
        task.wait(0.15)

        local bossList  = getBossList()
        local liveMap   = scanLiveBosses()

        -- ── Đếm boss còn lại chưa farm ──
        local remaining = 0
        for _, n in ipairs(bossList) do
            if not SkipBoss[n] and not killedBosses[n] then
                remaining = remaining + 1
            end
        end

        -- ── Tất cả boss đã farm → Hop ──
        if remaining == 0 then
            stopFly()
            currentBossName = "All Done! Hopping..."
            killedBosses  = {}
            scannedBosses = {}
            task.wait(1)
            Hop()
            task.wait(14)
            continue
        end

        -- ── Duyệt từng boss ──
        local farmedAny = false

        for _, bossName in ipairs(bossList) do
            if not _G.KaitunAllBoss then break end
            if SkipBoss[bossName]   then continue end
            if killedBosses[bossName] then continue end

            local bossObj = liveMap[bossName]

            -- Boss không có mặt trong server này → đánh dấu đã quét, bỏ qua
            if not bossObj then
                if not scannedBosses[bossName] then
                    scannedBosses[bossName] = true
                    currentBossName = bossName .. " (Not Spawned – Skipped)"
                end
                -- Đánh dấu đã "xử lý" (không có) để không chờ vô hạn
                killedBosses[bossName] = "skipped"
                continue
            end

            -- ── Farm boss này ──
            farmedAny = true
            currentBossName = bossName
            scannedBosses[bossName] = true   -- đã quét lần này

            -- Tạo anchor fly ngay từ đầu
            getOrCreateAnchor()

            -- Bay đến boss từ bất kỳ đâu
            local bHRP0 = bossObj:FindFirstChild("HumanoidRootPart")
            if bHRP0 then
                flyTo(bHRP0.Position + Vector3.new(0, FLY_HEIGHT, 0))
            end

            EquipMelee()
            AutoHaki()

            -- ── Farm loop: treo trên đầu boss, không rớt ──
            while _G.KaitunAllBoss do
                local fresh = findBoss(bossName)
                if not fresh then break end

                local bHRP = fresh:FindFirstChild("HumanoidRootPart")
                if not bHRP then break end

                local cHRP = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
                if not cHRP then task.wait(0.3); continue end

                currentDist = (bHRP.Position - cHRP.Position).Magnitude

                -- Hover ổn định trên đầu boss
                hoverOver(bHRP)

                -- Freeze boss
                pcall(function()
                    bHRP.CanCollide = false
                    bHRP.Size = Vector3.new(60, 60, 60)
                    local bHum = fresh:FindFirstChild("Humanoid")
                    if bHum then
                        bHum.WalkSpeed = 0
                        bHum.JumpPower = 0
                    end
                    sethiddenproperty(Plr, "SimulationRadius", math.huge)
                end)

                task.wait(0.08)
            end

            -- Boss đã chết → giữ nguyên anchor (không stopFly),
            -- chỉ update target khi sang boss tiếp theo
            killedBosses[bossName] = true
            currentBossName = bossName .. " ✓"
            task.wait(0.4)
        end

        -- ── Không boss nào spawn cả → Hop ──
        if not farmedAny then
            stopFly()
            currentBossName = "No Boss Spawned → Hopping..."
            task.wait(1.5)
            killedBosses  = {}
            scannedBosses = {}
            Hop()
            task.wait(14)
        end
    end
end)

-- ─── Dọn dẹp khi script bị tắt ───
game:GetService("Players").PlayerRemoving:Connect(function(p)
    if p == Plr then stopFly() end
end)

print(("[Kaitun v3] Started | Sea: %s | PlaceId: %s"):format(
    World1 and "1" or World2 and "2" or World3 and "3" or "?",
    tostring(PlaceId)
))
