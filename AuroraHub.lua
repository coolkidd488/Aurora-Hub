--[[
    ╔═══════════════════════════════════════╗
    ║           AURORA HUB v1.0.0           ║
    ║         Dandy's World ESP Hub         ║
    ╚═══════════════════════════════════════╝
    Modules: Main | UI | Theme | Utils |
             Machines | Monsters | Items | Profiles
]]

-- ============================================================
--  UTILS
-- ============================================================
local Utils = {}

function Utils.tween(obj, info, props)
    local TweenService = game:GetService("TweenService")
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

function Utils.round(n) return math.floor(n + 0.5) end

function Utils.colorToTable(c)
    return {
        R = Utils.round(c.R * 255),
        G = Utils.round(c.G * 255),
        B = Utils.round(c.B * 255)
    }
end

function Utils.tableToColor(t)
    return Color3.fromRGB(t.R or 255, t.G or 255, t.B or 255)
end

function Utils.encodeJSON(val, indent)
    indent = indent or 0
    local t = type(val)
    if t == "nil" then return "null"
    elseif t == "boolean" then return tostring(val)
    elseif t == "number" then return tostring(val)
    elseif t == "string" then
        return '"' .. val:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n') .. '"'
    elseif t == "table" then
        local isArray = #val > 0
        local parts = {}
        local pad = string.rep("  ", indent + 1)
        local closePad = string.rep("  ", indent)
        if isArray then
            for _, v in ipairs(val) do
                parts[#parts+1] = pad .. Utils.encodeJSON(v, indent+1)
            end
            return "[\n" .. table.concat(parts, ",\n") .. "\n" .. closePad .. "]"
        else
            for k, v in pairs(val) do
                parts[#parts+1] = pad .. '"' .. tostring(k) .. '": ' .. Utils.encodeJSON(v, indent+1)
            end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. closePad .. "}"
        end
    end
    return "null"
end

function Utils.decodeJSON(s)
    -- Simple JSON decoder (covers arrays, objects, strings, numbers, booleans, null)
    local pos = 1
    local function skip() while pos <= #s and s:sub(pos,pos):match("%s") do pos=pos+1 end end
    local function peek() skip() return s:sub(pos,pos) end
    local function consume(c) skip() assert(s:sub(pos,pos)==c,"Expected "..c.." at "..pos) pos=pos+1 end
    local parseVal
    local function parseStr()
        consume('"')
        local r = ""
        while pos <= #s do
            local c = s:sub(pos,pos)
            if c == '"' then pos=pos+1 return r end
            if c == '\\' then
                pos=pos+1
                local e = s:sub(pos,pos)
                if e=='n' then r=r..'\n'
                elseif e=='t' then r=r..'\t'
                elseif e=='"' then r=r..'"'
                elseif e=='\\' then r=r..'\\'
                else r=r..e end
            else r=r..c end
            pos=pos+1
        end
        return r
    end
    local function parseArr()
        consume('[') local t={}
        skip()
        if peek()==']' then pos=pos+1 return t end
        while true do
            t[#t+1]=parseVal()
            skip()
            if peek()==']' then pos=pos+1 return t end
            consume(',')
        end
    end
    local function parseObj()
        consume('{') local t={}
        skip()
        if peek()=='}' then pos=pos+1 return t end
        while true do
            skip() local k=parseStr()
            consume(':') t[k]=parseVal()
            skip()
            if peek()=='}' then pos=pos+1 return t end
            consume(',')
        end
    end
    parseVal = function()
        skip()
        local c = peek()
        if c=='"' then return parseStr()
        elseif c=='[' then return parseArr()
        elseif c=='{' then return parseObj()
        elseif c=='t' then pos=pos+4 return true
        elseif c=='f' then pos=pos+5 return false
        elseif c=='n' then pos=pos+4 return nil
        else
            local n = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
            if n then pos=pos+#n return tonumber(n) end
        end
        error("Unexpected char: "..c.." at pos "..pos)
    end
    return parseVal()
end

-- ============================================================
--  THEME
-- ============================================================
local Theme = {
    BG          = Color3.fromRGB(12, 12, 18),
    BG2         = Color3.fromRGB(18, 18, 28),
    BG3         = Color3.fromRGB(24, 24, 38),
    Accent      = Color3.fromRGB(120, 80, 255),
    AccentDark  = Color3.fromRGB(80, 50, 180),
    Text        = Color3.fromRGB(230, 230, 255),
    TextDim     = Color3.fromRGB(140, 140, 170),
    Border      = Color3.fromRGB(60, 60, 90),
    Success     = Color3.fromRGB(60, 200, 100),
    Warning     = Color3.fromRGB(255, 200, 60),
    Danger      = Color3.fromRGB(220, 60, 60),
    White       = Color3.fromRGB(255, 255, 255),
    CornerS     = UDim.new(0, 6),
    CornerM     = UDim.new(0, 10),
    CornerL     = UDim.new(0, 14),
    FontTitle   = Enum.Font.GothamBold,
    FontBody    = Enum.Font.Gotham,
    TweenFast   = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenMed    = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenSlow   = TweenInfo.new(0.4,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

-- ============================================================
--  PROFILES
-- ============================================================
local Profiles = {}
local FOLDER = "AuroraHub/"

local function fileAvail()
    return type(writefile) == "function" and type(readfile) == "function"
end

local function ensureFolder()
    if fileAvail() and type(makefolder) == "function" then
        pcall(function()
            if not isfolder(FOLDER) then makefolder(FOLDER) end
        end)
    end
end

function Profiles.save(name, data)
    if fileAvail() then
        ensureFolder()
        pcall(writefile, FOLDER .. name .. ".json", Utils.encodeJSON(data))
    end
    Profiles._memory[name] = data
end

function Profiles.load(name)
    if fileAvail() then
        local ok, content = pcall(readfile, FOLDER .. name .. ".json")
        if ok and content then
            local ok2, data = pcall(Utils.decodeJSON, content)
            if ok2 then return data end
        end
    end
    return Profiles._memory[name]
end

function Profiles.delete(name)
    Profiles._memory[name] = nil
    if fileAvail() then
        pcall(function()
            if isfile(FOLDER .. name .. ".json") then
                delfile(FOLDER .. name .. ".json")
            end
        end)
    end
end

function Profiles.list()
    local names = {}
    -- from memory
    for k in pairs(Profiles._memory) do names[k] = true end
    -- from files
    if fileAvail() and type(listfiles) == "function" then
        local ok, files = pcall(listfiles, FOLDER)
        if ok then
            for _, f in ipairs(files) do
                local n = f:match("([^/\\]+)%.json$")
                if n then names[n] = true end
            end
        end
    end
    local out = {}
    for k in pairs(names) do out[#out+1] = k end
    table.sort(out)
    return out
end

Profiles._memory    = {}
Profiles._current   = "Default"
Profiles._state     = {
    machines = {
        complete   = { enabled=true,  colors={{R=0,G=220,B=0}}   },
        completing = { enabled=true,  colors={{R=255,G=200,B=0}} },
        incomplete = { enabled=true,  colors={{R=0,G=170,B=255}} },
    },
    monsters = {},
    items    = {},
}

-- ============================================================
--  ESP CORE
-- ============================================================
local ESP = {}
ESP._connections = {}

local function addConn(tag, conn)
    if not ESP._connections[tag] then ESP._connections[tag] = {} end
    table.insert(ESP._connections[tag], conn)
end

local function clearConns(tag)
    if ESP._connections[tag] then
        for _, c in ipairs(ESP._connections[tag]) do
            pcall(function() c:Disconnect() end)
        end
        ESP._connections[tag] = nil
    end
end

-- ============================================================
--  MACHINES ESP
-- ============================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function colorsMatch(c1, c2, tol)
    tol = tol or 25
    return math.abs(c1.R*255 - c2.R*255) <= tol
        and math.abs(c1.G*255 - c2.G*255) <= tol
        and math.abs(c1.B*255 - c2.B*255) <= tol
end

local COL_RED    = Color3.fromRGB(167, 0,   0)
local COL_YELLOW = Color3.fromRGB(255, 215, 130)
local COL_GREEN  = Color3.fromRGB(58,  165, 56)

local function getMachineState()
    return Profiles._state.machines
end

local function setupMachine(Machine)
    if Machine.Name ~= "BaseMachine" then return end
    if Machine:FindFirstChild("AuroraESP_M") then return end

    local LightPart = Machine:FindFirstChild("Light", true)
    if not LightPart then return end
    local Part = Machine.PrimaryPart or Machine:FindFirstChildWhichIsA("BasePart")
    if not Part then return end

    local tag = "machine_" .. Machine:GetDebugId()

    local hl = Instance.new("Highlight")
    hl.Name = "AuroraESP_M"
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.OutlineColor = Color3.fromRGB(255,255,255)
    hl.Parent = Machine

    local bb = Instance.new("BillboardGui")
    bb.Name = "AuroraESP_M"
    bb.Adornee = Part
    bb.Size = UDim2.new(0, 170, 0, 26)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    bb.Parent = Machine

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.TextSize = 14
    lbl.Font = Theme.FontTitle
    lbl.TextStrokeTransparency = 0
    lbl.Parent = bb

    local curState = "incomplete"

    local function applyState(state)
        local ms = getMachineState()
        curState = state
        local cfg = ms[state]
        local col = cfg and cfg.colors and cfg.colors[1]
            and Utils.tableToColor(cfg.colors[1])
            or Color3.fromRGB(200,200,200)
        local enabled = cfg and cfg.enabled ~= false

        hl.Enabled = enabled
        bb.Enabled = enabled

        if state == "complete" then
            hl.FillColor = col
            lbl.TextColor3 = col
            lbl.Text = "✔ Completed"
        elseif state == "completing" then
            hl.FillColor = col
            lbl.TextColor3 = col
            lbl.Text = "⚙ Completing..."
        else
            hl.FillColor = col
            lbl.TextColor3 = Theme.White
        end
    end

    local function evalColor(color)
        if colorsMatch(color, COL_GREEN) then
            applyState("complete")
        elseif colorsMatch(color, COL_YELLOW) then
            applyState("completing")
        else
            applyState("incomplete")
        end
    end

    evalColor(LightPart.Color)

    local conn = LightPart:GetPropertyChangedSignal("Color"):Connect(function()
        evalColor(LightPart.Color)
    end)
    addConn(tag, conn)

    task.spawn(function()
        while Machine.Parent do
            if curState == "incomplete" then
                local ch = LocalPlayer.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = math.floor((hrp.Position - Part.Position).Magnitude)
                    lbl.Text = string.format("⚙ %d studs", d)
                end
            end
            task.wait(0.1)
        end
        clearConns(tag)
    end)
end

-- ============================================================
--  MONSTERS ESP
-- ============================================================
local monsterESPs = {} -- [name] = { hl, bb, lbl, colorIdx, thread }

local function getMonsterCfg(name)
    if not Profiles._state.monsters[name] then
        Profiles._state.monsters[name] = {
            enabled = true,
            colors  = {{R=255,G=0,B=0}},
        }
    end
    return Profiles._state.monsters[name]
end

local function setupMonster(obj)
    if not obj.Name:match("Monster$") then return end
    if not obj:IsA("Model") then return end
    if monsterESPs[obj] then return end

    task.spawn(function()
        local Part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        local w = 0
        while not Part and obj.Parent and w < 5 do
            task.wait(0.1) w=w+0.1
            Part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        end
        if not Part or not obj.Parent then return end

        local displayName = obj.Name:gsub("Monster$","")
        local cfg = getMonsterCfg(obj.Name)

        local hl = Instance.new("Highlight")
        hl.Name = "AuroraESP_T"
        hl.OutlineColor = Color3.fromRGB(255,255,255)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = Utils.tableToColor(cfg.colors[1])
        hl.Enabled = cfg.enabled
        hl.Parent = obj

        local bb = Instance.new("BillboardGui")
        bb.Name = "AuroraESP_T"
        bb.Adornee = Part
        bb.Size = UDim2.new(0, 200, 0, 28)
        bb.StudsOffset = Vector3.new(0, 4.5, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = math.huge
        bb.Enabled = cfg.enabled
        bb.Parent = obj

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromScale(1,1)
        lbl.BackgroundTransparency = 1
        lbl.TextSize = 15
        lbl.Font = Theme.FontTitle
        lbl.TextStrokeTransparency = 0
        lbl.TextColor3 = Utils.tableToColor(cfg.colors[1])
        lbl.Text = "⚠ " .. displayName
        lbl.Parent = bb

        local idx = 1
        local thread = task.spawn(function()
            while obj.Parent do
                local c = cfg.colors
                if #c > 1 then
                    idx = (idx % #c) + 1
                    local col = Utils.tableToColor(c[idx])
                    Utils.tween(hl, TweenInfo.new(0.6), {FillColor=col})
                    Utils.tween(lbl, TweenInfo.new(0.6), {TextColor3=col})
                end
                task.wait(0.8)
            end
        end)

        monsterESPs[obj] = { hl=hl, bb=bb, lbl=lbl, thread=thread }
    end)
end

-- ============================================================
--  ITEMS ESP
-- ============================================================
local ITEM_DEFS = {
    ResearchCapsule = { icon="🧪", label="Capsule",    color={R=0,  G=200,B=255} },
    Bandage         = { icon="🩹", label="Bandage",    color={R=255,G=255,B=255} },
    MedKit          = { icon="➕", label="Med Kit",    color={R=255,G=80, B=80}  },
    FirstAidKit     = { icon="➕", label="Med Kit",    color={R=255,G=80, B=80}  },
    Valve           = { icon="🔧", label="Valve",      color={R=200,G=150,B=50}  },
    PipeValve       = { icon="🔧", label="Valve",      color={R=200,G=150,B=50}  },
}

local itemESPs = {}

local function getItemCfg(name)
    local def = ITEM_DEFS[name]
    if not Profiles._state.items[name] then
        Profiles._state.items[name] = {
            enabled = true,
            colors  = { def and def.color or {R=255,G=255,B=0} },
        }
    end
    return Profiles._state.items[name]
end

local function setupItem(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
    local def = ITEM_DEFS[obj.Name]
    if not def then return end
    if itemESPs[obj] then return end
    if obj:FindFirstChild("AuroraESP_I") then return end

    task.spawn(function()
        local Part = obj:IsA("BasePart") and obj
            or obj.PrimaryPart
            or obj:FindFirstChildWhichIsA("BasePart")
        local w = 0
        while not Part and obj.Parent and w < 5 do
            task.wait(0.1) w=w+0.1
            Part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        end
        if not Part or not obj.Parent then return end

        local cfg = getItemCfg(obj.Name)

        local hl = Instance.new("Highlight")
        hl.Name = "AuroraESP_I"
        hl.FillColor = Utils.tableToColor(cfg.colors[1])
        hl.OutlineColor = Color3.fromRGB(255,255,255)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled = cfg.enabled
        hl.Parent = obj

        local bb = Instance.new("BillboardGui")
        bb.Name = "AuroraESP_I"
        bb.Adornee = Part
        bb.Size = UDim2.new(0, 170, 0, 24)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = math.huge
        bb.Enabled = cfg.enabled
        bb.Parent = obj

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromScale(1,1)
        lbl.BackgroundTransparency = 1
        lbl.TextSize = 14
        lbl.Font = Theme.FontTitle
        lbl.TextStrokeTransparency = 0
        lbl.TextColor3 = Utils.tableToColor(cfg.colors[1])
        lbl.Text = def.icon .. " " .. def.label
        lbl.Parent = bb

        local idx = 1
        local thread = task.spawn(function()
            while obj.Parent do
                local c = cfg.colors
                if #c > 1 then
                    idx = (idx % #c) + 1
                    local col = Utils.tableToColor(c[idx])
                    Utils.tween(hl, TweenInfo.new(0.6), {FillColor=col})
                    Utils.tween(lbl, TweenInfo.new(0.6), {TextColor3=col})
                end
                task.wait(0.8)
            end
        end)

        itemESPs[obj] = { hl=hl, bb=bb, lbl=lbl, thread=thread }
    end)
end

-- ============================================================
--  WORKSPACE WATCHERS
-- ============================================================
-- Machines
for _, v in ipairs(workspace:GetDescendants()) do setupMachine(v) end
workspace.DescendantAdded:Connect(setupMachine)

-- Monsters + Items via CurrentRoom
local function watchCurrentRoom(room)

	-- Monstros
	for _, obj in ipairs(room:GetDescendants()) do
		setupMonster(obj)
	end

	local function watchItemsFolder(folder)

		-- Itens já existentes
		for _, item in ipairs(folder:GetDescendants()) do
			setupItem(item)
		end

		-- Novos itens
		folder.DescendantAdded:Connect(function(item)
			setupItem(item)
		end)
	end

	-- Procura TODAS as pastas chamadas "Items"
	for _, obj in ipairs(room:GetDescendants()) do
		if obj:IsA("Folder") and obj.Name == "Items" then
			watchItemsFolder(obj)
		end
	end

	-- Monitora novos monstros e novas pastas Items
	room.DescendantAdded:Connect(function(obj)

		setupMonster(obj)

		if obj:IsA("Folder") and obj.Name == "Items" then
			watchItemsFolder(obj)
		end
	end)
end

-- ============================================================
--  UI — AURORA HUB
-- ============================================================
local VERSION = "1.0.0"

local Players2  = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local LP        = Players2.LocalPlayer
local PG        = LP:WaitForChild("PlayerGui")

-- Remove old instance
local old = PG:FindFirstChild("AuroraHub")
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AuroraHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PG

-- ── F Button (always visible) ──
local FBtn = Instance.new("TextButton")
FBtn.Name = "FButton"
FBtn.Size = UDim2.new(0, 44, 0, 44)
FBtn.Position = UDim2.new(0, 16, 0.5, -22)
FBtn.BackgroundColor3 = Theme.Accent
FBtn.Text = "F"
FBtn.TextColor3 = Theme.White
FBtn.TextSize = 20
FBtn.Font = Theme.FontTitle
FBtn.ZIndex = 10
FBtn.Parent = ScreenGui
do
    local c = Instance.new("UICorner") c.CornerRadius = Theme.CornerM c.Parent = FBtn
    local s = Instance.new("UIStroke") s.Color=Theme.AccentDark s.Thickness=2 s.Parent = FBtn
end

-- ── Main Window ──
local WIN_W, WIN_H = 320, 500
local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, WIN_W, 0, WIN_H)
Window.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Window.BackgroundColor3 = Theme.BG
Window.BorderSizePixel = 0
Window.ClipsDescendants = true
Window.ZIndex = 5
Window.Parent = ScreenGui
do
    local c = Instance.new("UICorner") c.CornerRadius = Theme.CornerL c.Parent = Window
    local s = Instance.new("UIStroke") s.Color=Theme.Border s.Thickness=1.5 s.Parent = Window
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20,16,40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,20)),
    }
    g.Rotation = 135
    g.Parent = Window
end

-- ── Title Bar ──
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 52)
TitleBar.BackgroundColor3 = Theme.BG2
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 6
TitleBar.Parent = Window
do
    local c = Instance.new("UICorner") c.CornerRadius = Theme.CornerL c.Parent = TitleBar
    -- patch bottom corners
    local p = Instance.new("Frame")
    p.Size = UDim2.new(1,0,0.5,0) p.Position = UDim2.new(0,0,0.5,0)
    p.BackgroundColor3 = Theme.BG2 p.BorderSizePixel=0 p.ZIndex=6 p.Parent = TitleBar
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30,20,60)),
        ColorSequenceKeypoint.new(1, Theme.BG2),
    }
    g.Rotation = 90 g.Parent = TitleBar
end

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -90, 1, 0)
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Aurora Hub"
TitleText.TextColor3 = Theme.White
TitleText.TextSize = 16
TitleText.Font = Theme.FontTitle
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.ZIndex = 7
TitleText.Parent = TitleBar

local SubText = Instance.new("TextLabel")
SubText.Size = UDim2.new(1, -90, 0, 14)
SubText.Position = UDim2.new(0, 12, 0, 30)
SubText.BackgroundTransparency = 1
SubText.Text = "Version " .. VERSION .. "  |  Profile: " .. Profiles._current
SubText.TextColor3 = Theme.TextDim
SubText.TextSize = 11
SubText.Font = Theme.FontBody
SubText.TextXAlignment = Enum.TextXAlignment.Left
SubText.ZIndex = 7
SubText.Parent = TitleBar

-- Window controls
local function makeWinBtn(icon, posX, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,26,0,26)
    b.Position = UDim2.new(1, posX, 0.5, -13)
    b.BackgroundColor3 = col
    b.Text = icon
    b.TextColor3 = Theme.White
    b.TextSize = 13
    b.Font = Theme.FontTitle
    b.ZIndex = 8
    b.Parent = TitleBar
    Instance.new("UICorner").CornerRadius = UDim.new(0,6)
    Instance.new("UICorner").Parent = b
    return b
end
local BtnMin   = makeWinBtn("─", -62, Theme.Warning)
local BtnClose = makeWinBtn("✕", -32, Theme.Danger)

-- ── Tab Bar ──
local TAB_H = 36
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1,0,0,TAB_H)
TabBar.Position = UDim2.new(0,0,0,52)
TabBar.BackgroundColor3 = Theme.BG2
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 6
TabBar.Parent = Window
do
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Horizontal
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = TabBar
end

-- ── Content Area ──
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1,0,1,-(52+TAB_H))
ContentArea.Position = UDim2.new(0,0,0,52+TAB_H)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.ZIndex = 5
ContentArea.Parent = Window

-- ── Tab system ──
local tabs = {}
local activeTab = nil

local function createTab(name, icon)
    local tabW = WIN_W / 4 -- 4 tabs
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, tabW, 1, 0)
    TabBtn.BackgroundColor3 = Theme.BG2
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = icon
    TabBtn.TextColor3 = Theme.TextDim
    TabBtn.TextSize = 15
    TabBtn.Font = Theme.FontTitle
    TabBtn.ZIndex = 7
    TabBtn.Parent = TabBar

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0.7,0,0,2)
    Indicator.Position = UDim2.new(0.15,0,1,-2)
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.BorderSizePixel = 0
    Indicator.BackgroundTransparency = 1
    Indicator.ZIndex = 8
    Indicator.Parent = TabBtn

    -- Page
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.fromScale(1,1)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.CanvasSize = UDim2.new(0,0,0,0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    Page.ZIndex = 5
    Page.Parent = ContentArea
    do
        local l = Instance.new("UIListLayout")
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0,6)
        l.Parent = Page
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0,10)
        p.PaddingRight = UDim.new(0,10)
        p.PaddingTop = UDim.new(0,8)
        p.PaddingBottom = UDim.new(0,8)
        p.Parent = Page
    end

    local tab = { btn=TabBtn, page=Page, indicator=Indicator, name=name }
    tabs[name] = tab

    TabBtn.MouseButton1Click:Connect(function()
        if activeTab == name then return end
        -- deactivate old
        if activeTab and tabs[activeTab] then
            local old2 = tabs[activeTab]
            old2.page.Visible = false
            Utils.tween(old2.indicator, Theme.TweenFast, {BackgroundTransparency=1})
            Utils.tween(old2.btn, Theme.TweenFast, {TextColor3=Theme.TextDim})
        end
        activeTab = name
        Page.Visible = true
        Utils.tween(Indicator, Theme.TweenFast, {BackgroundTransparency=0})
        Utils.tween(TabBtn, Theme.TweenFast, {TextColor3=Theme.White})
    end)

    return Page
end

-- ── UI Helpers ──
local function makeDivider(parent, order)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1,0,0,1)
    d.BackgroundColor3 = Theme.Border
    d.BorderSizePixel = 0
    d.LayoutOrder = order or 0
    d.Parent = parent
    return d
end

local function makeLabel(parent, text, order, size)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0, size or 22)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Theme.TextDim
    l.TextSize = 12
    l.Font = Theme.FontBody
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 0
    l.Parent = parent
    return l
end

local function makeSectionHeader(parent, text, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,28)
    f.BackgroundColor3 = Theme.BG3
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 0
    f.Parent = parent
    Instance.new("UICorner").CornerRadius = Theme.CornerS
    Instance.new("UICorner").Parent = f
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-10,1,0)
    l.Position = UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1
    l.Text = text
    l.TextColor3 = Theme.Accent
    l.TextSize = 13
    l.Font = Theme.FontTitle
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    return f
end

local function makeToggleRow(parent, labelText, initVal, order, onChange)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,34)
    row.BackgroundColor3 = Theme.BG2
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 0
    row.Parent = parent
    Instance.new("UICorner").CornerRadius = Theme.CornerS
    Instance.new("UICorner").Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-56,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text = labelText
    lbl.TextColor3 = Theme.Text
    lbl.TextSize = 13
    lbl.Font = Theme.FontBody
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local ToggleBG = Instance.new("Frame")
    ToggleBG.Size = UDim2.new(0,38,0,20)
    ToggleBG.Position = UDim2.new(1,-48,0.5,-10)
    ToggleBG.BackgroundColor3 = initVal and Theme.Accent or Theme.BG3
    ToggleBG.BorderSizePixel = 0
    ToggleBG.Parent = row
    Instance.new("UICorner").CornerRadius = UDim.new(0,10)
    Instance.new("UICorner").Parent = ToggleBG

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0,14,0,14)
    Knob.Position = initVal and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
    Knob.BackgroundColor3 = Theme.White
    Knob.BorderSizePixel = 0
    Knob.Parent = ToggleBG
    Instance.new("UICorner").CornerRadius = UDim.new(0,7)
    Instance.new("UICorner").Parent = Knob

    local state = initVal
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1,1)
    btn.BackgroundTransparency=1
    btn.Text=""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        state = not state
        Utils.tween(ToggleBG, Theme.TweenFast, {BackgroundColor3 = state and Theme.Accent or Theme.BG3})
        Utils.tween(Knob, Theme.TweenFast, {Position = state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
        if onChange then onChange(state) end
    end)
    return row, function() return state end
end

local function makeRGBRow(parent, labelText, initColor, order, onChange)
    -- initColor = {R,G,B}
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1,0,0,58)
    wrap.BackgroundColor3 = Theme.BG2
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = order or 0
    wrap.Parent = parent
    Instance.new("UICorner").CornerRadius = Theme.CornerS
    Instance.new("UICorner").Parent = wrap

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextDim
    lbl.TextSize = 11
    lbl.Font = Theme.FontBody
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = wrap

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0,16,0,16)
    preview.Position = UDim2.new(1,-26,0,4)
    preview.BackgroundColor3 = Utils.tableToColor(initColor)
    preview.BorderSizePixel = 0
    preview.Parent = wrap
    Instance.new("UICorner").CornerRadius = UDim.new(0,4)
    Instance.new("UICorner").Parent = preview

    local cur = {R=initColor.R, G=initColor.G, B=initColor.B}

    local function makeChannel(ch, xOff)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0,72,0,26)
        f.Position = UDim2.new(0, xOff, 0, 26)
        f.BackgroundColor3 = Theme.BG3
        f.BorderSizePixel = 0
        f.Parent = wrap
        Instance.new("UICorner").CornerRadius = Theme.CornerS
        Instance.new("UICorner").Parent = f

        local prefix = Instance.new("TextLabel")
        prefix.Size = UDim2.new(0,14,1,0)
        prefix.BackgroundTransparency=1
        prefix.Text = ch
        prefix.TextColor3 = Theme.TextDim
        prefix.TextSize = 11
        prefix.Font = Theme.FontTitle
        prefix.Parent = f

        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(1,-16,1,0)
        tb.Position = UDim2.new(0,14,0,0)
        tb.BackgroundTransparency=1
        tb.Text = tostring(initColor[ch])
        tb.TextColor3 = Theme.White
        tb.TextSize = 12
        tb.Font = Theme.FontBody
        tb.ClearTextOnFocus = false
        tb.Parent = f
        tb.FocusLost:Connect(function()
            local v = tonumber(tb.Text)
            if v then
                v = math.clamp(math.floor(v), 0, 255)
                cur[ch] = v
                tb.Text = tostring(v)
                preview.BackgroundColor3 = Utils.tableToColor(cur)
                if onChange then onChange(cur) end
            else
                tb.Text = tostring(cur[ch])
            end
        end)
        return tb
    end

    makeChannel("R", 8)
    makeChannel("G", 88)
    makeChannel("B", 168)

    return wrap
end

local function makeColorListRow(parent, labelText, initColors, order, onChange)
    -- Multi-color list with [+] button
    local colors = {}
    for _, c in ipairs(initColors) do colors[#colors+1] = {R=c.R,G=c.G,B=c.B} end

    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1,0,0,10) -- auto-sized
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.BackgroundColor3 = Theme.BG2
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = order or 0
    wrap.Parent = parent
    Instance.new("UICorner").CornerRadius = Theme.CornerS
    Instance.new("UICorner").Parent = wrap

    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(1,0,0,0)
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.BackgroundTransparency=1
    inner.Parent = wrap
    do
        local l = Instance.new("UIListLayout")
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0,2)
        l.Parent = inner
        local p = Instance.new("UIPadding")
        p.PaddingLeft=UDim.new(0,8) p.PaddingRight=UDim.new(0,8)
        p.PaddingTop=UDim.new(0,6) p.PaddingBottom=UDim.new(0,6)
        p.Parent = inner
    end

    local hdr = Instance.new("TextLabel")
    hdr.Size = UDim2.new(1,0,0,18)
    hdr.BackgroundTransparency=1
    hdr.Text = labelText .. " Colors"
    hdr.TextColor3 = Theme.TextDim
    hdr.TextSize = 11
    hdr.Font = Theme.FontBody
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.LayoutOrder = 0
    hdr.Parent = inner

    local colorRows = {}
    local addBtn

    local function rebuild()
        for _, r in ipairs(colorRows) do r:Destroy() end
        colorRows = {}
        for i, c in ipairs(colors) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1,0,0,26)
            row.BackgroundTransparency=1
            row.LayoutOrder = i
            row.Parent = inner
            local ii = i
            local preview2 = Instance.new("Frame")
            preview2.Size = UDim2.new(0,14,0,14)
            preview2.Position = UDim2.new(0,0,0.5,-7)
            preview2.BackgroundColor3 = Utils.tableToColor(c)
            preview2.BorderSizePixel=0
            preview2.Parent = row
            Instance.new("UICorner").CornerRadius = UDim.new(0,3)
            Instance.new("UICorner").Parent = preview2

            local function makeSmallCh(ch, xOff)
                local f2 = Instance.new("Frame")
                f2.Size = UDim2.new(0,55,0,20)
                f2.Position = UDim2.new(0,xOff,0.5,-10)
                f2.BackgroundColor3 = Theme.BG3
                f2.BorderSizePixel=0
                f2.Parent = row
                Instance.new("UICorner").CornerRadius = Theme.CornerS
                Instance.new("UICorner").Parent = f2
                local px = Instance.new("TextLabel")
                px.Size = UDim2.new(0,12,1,0)
                px.BackgroundTransparency=1
                px.Text=ch px.TextColor3=Theme.TextDim px.TextSize=10 px.Font=Theme.FontTitle px.Parent=f2
                local tb2 = Instance.new("TextBox")
                tb2.Size=UDim2.new(1,-13,1,0) tb2.Position=UDim2.new(0,13,0,0)
                tb2.BackgroundTransparency=1 tb2.Text=tostring(c[ch])
                tb2.TextColor3=Theme.White tb2.TextSize=11 tb2.Font=Theme.FontBody
                tb2.ClearTextOnFocus=false tb2.Parent=f2
                tb2.FocusLost:Connect(function()
                    local v2 = tonumber(tb2.Text)
                    if v2 then
                        v2 = math.clamp(math.floor(v2),0,255)
                        colors[ii][ch] = v2 tb2.Text=tostring(v2)
                        preview2.BackgroundColor3 = Utils.tableToColor(colors[ii])
                        if onChange then onChange(colors) end
                    else tb2.Text=tostring(colors[ii][ch]) end
                end)
            end
            makeSmallCh("R", 20)
            makeSmallCh("G", 80)
            makeSmallCh("B", 140)

            -- Remove button (only if more than 1 color)
            if #colors > 1 then
                local rb = Instance.new("TextButton")
                rb.Size=UDim2.new(0,18,0,18) rb.Position=UDim2.new(1,-18,0.5,-9)
                rb.BackgroundColor3=Theme.Danger rb.Text="✕" rb.TextColor3=Theme.White
                rb.TextSize=10 rb.Font=Theme.FontTitle rb.BorderSizePixel=0 rb.Parent=row
                Instance.new("UICorner").CornerRadius=UDim.new(0,4)
                Instance.new("UICorner").Parent=rb
                rb.MouseButton1Click:Connect(function()
                    table.remove(colors, ii)
                    rebuild()
                    if onChange then onChange(colors) end
                end)
            end

            colorRows[#colorRows+1] = row
        end
        if addBtn then addBtn.LayoutOrder = #colors+1 end
    end

    addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(1,0,0,24)
    addBtn.BackgroundColor3 = Theme.BG3
    addBtn.Text = "+ Add Color"
    addBtn.TextColor3 = Theme.Accent
    addBtn.TextSize = 12
    addBtn.Font = Theme.FontTitle
    addBtn.BorderSizePixel = 0
    addBtn.LayoutOrder = 999
    addBtn.Parent = inner
    Instance.new("UICorner").CornerRadius = Theme.CornerS
    Instance.new("UICorner").Parent = addBtn
    addBtn.MouseButton1Click:Connect(function()
        colors[#colors+1] = {R=255,G=255,B=255}
        rebuild()
        if onChange then onChange(colors) end
    end)

    rebuild()
    return wrap, function() return colors end
end

-- ============================================================
--  TAB PAGES
-- ============================================================
local pageMachines = createTab("Machines", "⚙")
local pageMonsters = createTab("Monsters", "👾")
local pageItems    = createTab("Items",    "🎒")
local pageProfiles = createTab("Profiles", "👤")

-- Activate first tab
tabs["Machines"].btn.MouseButton1Click:Fire()

-- ── MACHINES PAGE ──
do
    local ms = Profiles._state.machines
    local order = 0

    local function machineBlock(key, label, initCfg)
        order=order+1 makeSectionHeader(pageMachines, label, order)
        order=order+1
        makeToggleRow(pageMachines, "Enable ESP", initCfg.enabled, order, function(v)
            ms[key].enabled = v
        end)
        order=order+1
        makeColorListRow(pageMachines, label, initCfg.colors, order, function(cols)
            ms[key].colors = cols
        end)
        order=order+1 makeDivider(pageMachines, order)
    end

    machineBlock("complete",   "✔ Machine Complete",   ms.complete)
    machineBlock("completing", "⚙ Machine Completing", ms.completing)
    machineBlock("incomplete", "⚙ Machine Incomplete", ms.incomplete)
end

-- ── MONSTERS PAGE ──
local monsterRows = {}
local function addMonsterRow(name)
    if monsterRows[name] then return end
    local displayName = name:gsub("Monster$","")
    local cfg = getMonsterCfg(name)
    local order = #monsterRows + 1

    local sec = makeSectionHeader(pageMonsters, "⚠ " .. displayName, order*3-2)
    local _, getToggle = makeToggleRow(pageMonsters, "Enable ESP", cfg.enabled, order*3-1, function(v)
        cfg.enabled = v
        if monsterESPs[name] then
            -- update all existing ESPs with this name
            for obj, data in pairs(monsterESPs) do
                if type(obj)~="string" and obj.Name==name then
                    data.hl.Enabled = v
                    data.bb.Enabled = v
                end
            end
        end
    end)
    makeColorListRow(pageMonsters, displayName, cfg.colors, order*3, function(cols)
        cfg.colors = cols
    end)
    monsterRows[name] = true
end

-- Watch for new monsters to auto-add rows
local function onMonsterDetected(obj)
    if obj.Name:match("Monster$") and obj:IsA("Model") then
        addMonsterRow(obj.Name)
    end
end
local cr2 = workspace:FindFirstChild("CurrentRoom")
if cr2 then
    for _, d in ipairs(cr2:GetDescendants()) do onMonsterDetected(d) end
    cr2.DescendantAdded:Connect(onMonsterDetected)
end
workspace.DescendantAdded:Connect(function(child)
    if child.Name == "CurrentRoom" then
        child.DescendantAdded:Connect(onMonsterDetected)
    end
end)

-- ── ITEMS PAGE ──
do
    local order = 0
    for name, def in pairs(ITEM_DEFS) do
        local cfg = getItemCfg(name)
        order=order+1
        makeSectionHeader(pageItems, def.icon .. " " .. def.label .. " (" .. name .. ")", order*3-2)
        makeToggleRow(pageItems, "Enable ESP", cfg.enabled, order*3-1, function(v)
            cfg.enabled = v
            for obj, data in pairs(itemESPs) do
                if obj.Name==name then
                    data.hl.Enabled=v data.bb.Enabled=v
                end
            end
        end)
        makeColorListRow(pageItems, def.label, cfg.colors, order*3, function(cols)
            cfg.colors = cols
        end)
        order=order+1 makeDivider(pageItems, order*3+1)
    end
end

-- ── PROFILES PAGE ──
local profileListFrame
local currentProfileLabel

local function refreshProfileList()
    if not profileListFrame then return end
    for _, c in ipairs(profileListFrame:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            c:Destroy()
        end
    end
    local names = Profiles.list()
    for i, name in ipairs(names) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,0,0,36)
        row.BackgroundColor3 = name==Profiles._current and Theme.BG3 or Theme.BG2
        row.BorderSizePixel=0
        row.LayoutOrder=i
        row.Parent=profileListFrame
        Instance.new("UICorner").CornerRadius=Theme.CornerS
        Instance.new("UICorner").Parent=row

        local nl = Instance.new("TextLabel")
        nl.Size=UDim2.new(1,-130,1,0) nl.Position=UDim2.new(0,10,0,0)
        nl.BackgroundTransparency=1 nl.Text=name
        nl.TextColor3= name==Profiles._current and Theme.Accent or Theme.Text
        nl.TextSize=13 nl.Font=Theme.FontBody nl.TextXAlignment=Enum.TextXAlignment.Left
        nl.Parent=row

        local function smallBtn(txt, xOff, col, cb)
            local b=Instance.new("TextButton")
            b.Size=UDim2.new(0,36,0,24) b.Position=UDim2.new(1,xOff,0.5,-12)
            b.BackgroundColor3=col b.Text=txt b.TextColor3=Theme.White
            b.TextSize=11 b.Font=Theme.FontTitle b.BorderSizePixel=0 b.Parent=row
            Instance.new("UICorner").CornerRadius=UDim.new(0,5)
            Instance.new("UICorner").Parent=b
            b.MouseButton1Click:Connect(cb)
            return b
        end

        smallBtn("Load", -120, Theme.Accent, function()
            local data = Profiles.load(name)
            if data then
                Profiles._state = data
                Profiles._current = name
                if currentProfileLabel then
                    currentProfileLabel.Text = "Version "..VERSION.."  |  Profile: "..name
                end
                refreshProfileList()
            end
        end)
        smallBtn("Save", -80, Theme.Success, function()
            Profiles.save(name, Profiles._state)
        end)
        smallBtn("Del", -40, Theme.Danger, function()
            -- Confirmation
            local confirm = Instance.new("Frame")
            confirm.Size=UDim2.new(1,0,0,50) confirm.BackgroundColor3=Theme.BG3
            confirm.BorderSizePixel=0 confirm.LayoutOrder=i+0.5 confirm.Parent=profileListFrame
            Instance.new("UICorner").CornerRadius=Theme.CornerS
            Instance.new("UICorner").Parent=confirm
            local ql=Instance.new("TextLabel")
            ql.Size=UDim2.new(1,0,0,24) ql.BackgroundTransparency=1
            ql.Text="Delete \""..name.."\"?" ql.TextColor3=Theme.Danger
            ql.TextSize=12 ql.Font=Theme.FontTitle ql.Parent=confirm
            local yb=Instance.new("TextButton")
            yb.Size=UDim2.new(0,60,0,22) yb.Position=UDim2.new(0,10,0,26)
            yb.BackgroundColor3=Theme.Danger yb.Text="Yes" yb.TextColor3=Theme.White
            yb.TextSize=12 yb.Font=Theme.FontTitle yb.BorderSizePixel=0 yb.Parent=confirm
            Instance.new("UICorner").CornerRadius=UDim.new(0,4)
            Instance.new("UICorner").Parent=yb
            local nb=Instance.new("TextButton")
            nb.Size=UDim2.new(0,60,0,22) nb.Position=UDim2.new(0,78,0,26)
            nb.BackgroundColor3=Theme.BG2 nb.Text="No" nb.TextColor3=Theme.White
            nb.TextSize=12 nb.Font=Theme.FontTitle nb.BorderSizePixel=0 nb.Parent=confirm
            Instance.new("UICorner").CornerRadius=UDim.new(0,4)
            Instance.new("UICorner").Parent=nb
            yb.MouseButton1Click:Connect(function()
                Profiles.delete(name)
                confirm:Destroy()
                refreshProfileList()
            end)
            nb.MouseButton1Click:Connect(function() confirm:Destroy() end)
        end)
    end
end

do
    makeSectionHeader(pageProfiles, "👤 Profile Manager", 1)

    -- Create profile input
    local inputRow = Instance.new("Frame")
    inputRow.Size=UDim2.new(1,0,0,34) inputRow.BackgroundColor3=Theme.BG2
    inputRow.BorderSizePixel=0 inputRow.LayoutOrder=2 inputRow.Parent=pageProfiles
    Instance.new("UICorner").CornerRadius=Theme.CornerS
    Instance.new("UICorner").Parent=inputRow

    local tb = Instance.new("TextBox")
    tb.Size=UDim2.new(1,-80,1,-8) tb.Position=UDim2.new(0,8,0,4)
    tb.BackgroundColor3=Theme.BG3 tb.PlaceholderText="Profile name..."
    tb.PlaceholderColor3=Theme.TextDim tb.Text=""
    tb.TextColor3=Theme.White tb.TextSize=12 tb.Font=Theme.FontBody
    tb.BorderSizePixel=0 tb.Parent=inputRow
    Instance.new("UICorner").CornerRadius=Theme.CornerS
    Instance.new("UICorner").Parent=tb

    local createBtn=Instance.new("TextButton")
    createBtn.Size=UDim2.new(0,66,1,-8) createBtn.Position=UDim2.new(1,-70,0,4)
    createBtn.BackgroundColor3=Theme.Accent createBtn.Text="+ Create"
    createBtn.TextColor3=Theme.White createBtn.TextSize=12 createBtn.Font=Theme.FontTitle
    createBtn.BorderSizePixel=0 createBtn.Parent=inputRow
    Instance.new("UICorner").CornerRadius=Theme.CornerS
    Instance.new("UICorner").Parent=createBtn
    createBtn.MouseButton1Click:Connect(function()
        local n = tb.Text:match("^%s*(.-)%s*$")
        if n and #n > 0 then
            Profiles.save(n, Profiles._state)
            tb.Text=""
            refreshProfileList()
        end
    end)

    makeDivider(pageProfiles, 3)

    profileListFrame = Instance.new("Frame")
    profileListFrame.Size=UDim2.new(1,0,0,0)
    profileListFrame.AutomaticSize=Enum.AutomaticSize.Y
    profileListFrame.BackgroundTransparency=1
    profileListFrame.LayoutOrder=4 profileListFrame.Parent=pageProfiles
    do
        local l=Instance.new("UIListLayout")
        l.SortOrder=Enum.SortOrder.LayoutOrder l.Padding=UDim.new(0,4) l.Parent=profileListFrame
    end

    currentProfileLabel = SubText
    refreshProfileList()
end

-- ============================================================
--  DRAG (PC + Mobile)
-- ============================================================
do
    local dragging, dragStart, startPos
    local function onInput(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end
    TitleBar.InputBegan:Connect(onInput)
    UIS.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
--  WINDOW CONTROLS (minimize / close / F button)
-- ============================================================
local isOpen = true
local isMin  = false

local function openWindow()
    isOpen = true isMin = false
    Window.Visible = true
    Window.Size = UDim2.new(0,WIN_W,0,0)
    Window:TweenSize(UDim2.new(0,WIN_W,0,WIN_H), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
    Utils.tween(Window, Theme.TweenMed, {BackgroundTransparency=0})
end

local function minimizeWindow()
    isMin = true
    Window:TweenSize(UDim2.new(0,WIN_W,0,52), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    ContentArea.Visible = false
    TabBar.Visible = false
end

local function restoreWindow()
    isMin = false
    ContentArea.Visible = true
    TabBar.Visible = true
    Window:TweenSize(UDim2.new(0,WIN_W,0,WIN_H), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
end

local function closeWindow()
    isOpen = false
    Utils.tween(Window, Theme.TweenMed, {BackgroundTransparency=1})
    Window:TweenSize(UDim2.new(0,WIN_W,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true, function()
        Window.Visible = false
    end)
end

BtnMin.MouseButton1Click:Connect(function()
    if isMin then restoreWindow() else minimizeWindow() end
end)

BtnClose.MouseButton1Click:Connect(closeWindow)

FBtn.MouseButton1Click:Connect(function()
    if not isOpen then
        openWindow()
    elseif isMin then
        restoreWindow()
    else
        minimizeWindow()
    end
end)

-- Initial open animation
Window.Size = UDim2.new(0,WIN_W,0,0)
Window.Visible = true
task.wait(0.05)
openWindow()

print("[AuroraHub] v"..VERSION.." loaded!")
