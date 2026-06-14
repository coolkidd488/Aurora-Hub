--[[
    ╔═══════════════════════════════════════╗
    ║           AURORA HUB v1.0.0           ║
    ║      Azul Neon + Ciano | Glass UI     ║
    ╚═══════════════════════════════════════╝
]]

local VERSION = "1.0.0"

-- ============================================================
--  SERVICES
-- ============================================================
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer
local PG           = LP:WaitForChild("PlayerGui")

-- ============================================================
--  UTILS
-- ============================================================
local function tw(obj, t, props) TweenService:Create(obj, t, props):Play() end
local TF  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TM  = TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TS  = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function mkCorner(p, r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p end
local function mkStroke(p, col, th, tr)
    local s=Instance.new("UIStroke") s.Color=col s.Thickness=th or 1.2
    s.Transparency=tr or 0 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s
end
local function mkList(p, pad, dir)
    local l=Instance.new("UIListLayout") l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Padding=UDim.new(0,pad or 6)
    l.FillDirection=dir or Enum.FillDirection.Vertical l.Parent=p return l
end
local function mkPad(p, h, v)
    local pd=Instance.new("UIPadding")
    pd.PaddingLeft=UDim.new(0,h) pd.PaddingRight=UDim.new(0,h)
    pd.PaddingTop=UDim.new(0,v) pd.PaddingBottom=UDim.new(0,v) pd.Parent=p
end
local function mkGrad(p, c0, c1, rot)
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,c0),ColorSequenceKeypoint.new(1,c1)}
    g.Rotation=rot or 135 g.Parent=p return g
end

-- ============================================================
--  THEME  — Neon Blue + Cyan Glassmorphism
-- ============================================================
local T = {
    -- Glass panels
    Glass       = Color3.fromRGB(8,  18,  36),   -- deep navy base
    GlassPanel  = Color3.fromRGB(10, 22,  44),
    GlassCard   = Color3.fromRGB(14, 28,  54),
    GlassHover  = Color3.fromRGB(18, 36,  68),

    -- Neons
    Neon        = Color3.fromRGB(0,   200, 255),  -- ciano neon principal
    NeonBlue    = Color3.fromRGB(30,  100, 255),  -- azul neon
    NeonGlow    = Color3.fromRGB(0,   230, 255),  -- brilho ciano
    NeonDim     = Color3.fromRGB(0,   120, 180),  -- ciano apagado

    -- Borders
    BorderNeon  = Color3.fromRGB(0,   180, 255),
    BorderFaint = Color3.fromRGB(20,  60,  100),

    -- Text
    TextBright  = Color3.fromRGB(200, 240, 255),
    TextMid     = Color3.fromRGB(100, 170, 210),
    TextDim     = Color3.fromRGB(50,  100, 140),

    -- States
    Green       = Color3.fromRGB(0,   230, 120),
    Yellow      = Color3.fromRGB(255, 210, 0  ),
    Red         = Color3.fromRGB(255, 55,  80 ),
    White       = Color3.fromRGB(255, 255, 255),

    -- Glass transparency levels
    PanelTR     = 0.55,
    CardTR      = 0.65,
    StrokeTR    = 0.30,
}

-- ============================================================
--  PROFILES
-- ============================================================
local Profiles = { _mem={}, _current="Default" }
local function fileOk() return type(writefile)=="function" and type(readfile)=="function" end
local function jE(v)
    local t=type(v)
    if t=="nil" then return "null" elseif t=="boolean" or t=="number" then return tostring(v)
    elseif t=="string" then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"')..'"'
    elseif t=="table" then
        if #v>0 then local p={} for _,x in ipairs(v) do p[#p+1]=jE(x) end return "["..table.concat(p,",").."]"
        else local p={} for k,x in pairs(v) do p[#p+1]='"'..k..'":'..jE(x) end return "{"..table.concat(p,",").."}" end
    end return "null"
end
local function jD(s)
    local i=1
    local function sk() while i<=#s and s:sub(i,i):match"%s" do i=i+1 end end
    local function ch() sk() return s:sub(i,i) end
    local pv
    local function pS() i=i+1 local r=""
        while i<=#s do local c=s:sub(i,i)
            if c=='"' then i=i+1 return r end
            if c=="\\" then i=i+1 c=s:sub(i,i) if c=="n" then r=r.."\n" else r=r..c end
            else r=r..c end i=i+1 end return r end
    local function pA() i=i+1 local t={} sk() if ch()=="]" then i=i+1 return t end
        while true do t[#t+1]=pv() sk() if ch()=="]" then i=i+1 return t end i=i+1 end end
    local function pO() i=i+1 local t={} sk() if ch()=="}" then i=i+1 return t end
        while true do sk() local k=pS() sk() i=i+1 t[k]=pv() sk()
            if ch()=="}" then i=i+1 return t end i=i+1 end end
    pv=function() sk() local c=ch()
        if c=='"' then return pS() elseif c=="[" then return pA() elseif c=="{" then return pO()
        elseif c=="t" then i=i+4 return true elseif c=="f" then i=i+5 return false
        elseif c=="n" then i=i+4 return nil
        else local n=s:match("^-?%d+%.?%d*",i) i=i+#n return tonumber(n) end end
    return pv()
end
local FOLDER="AuroraHub/"
local function ensureFolder() if fileOk() and type(makefolder)=="function" then pcall(function() if not isfolder(FOLDER) then makefolder(FOLDER) end end) end end
function Profiles.save(n,d) Profiles._mem[n]=d if fileOk() then ensureFolder() pcall(writefile,FOLDER..n..".json",jE(d)) end end
function Profiles.load(n)
    if fileOk() then local ok,c=pcall(readfile,FOLDER..n..".json") if ok and c then local ok2,d=pcall(jD,c) if ok2 then return d end end end
    return Profiles._mem[n] end
function Profiles.delete(n) Profiles._mem[n]=nil if fileOk() then pcall(function() if isfile(FOLDER..n..".json") then delfile(FOLDER..n..".json") end end) end end
function Profiles.list()
    local names={} for k in pairs(Profiles._mem) do names[k]=true end
    if fileOk() and type(listfiles)=="function" then local ok,files=pcall(listfiles,FOLDER) if ok then for _,f in ipairs(files) do local n=f:match("([^/\\]+)%.json$") if n then names[n]=true end end end end
    local out={} for k in pairs(names) do out[#out+1]=k end table.sort(out) return out end

-- ============================================================
--  STATE
-- ============================================================
local State = {
    machines = {
        complete   = {enabled=true, colors={{R=0,  G=230,B=120}}},
        completing = {enabled=true, colors={{R=255,G=210,B=0  }}},
        incomplete = {enabled=true, colors={{R=0,  G=200,B=255}}},
    },
    monsters={}, items={},
}
local function c3(t) return Color3.fromRGB(t.R or 255,t.G or 255,t.B or 255) end

-- ============================================================
--  ESP — MACHINES
-- ============================================================
local COL_RED=Color3.fromRGB(167,0,0)
local COL_YEL=Color3.fromRGB(255,215,130)
local COL_GRN=Color3.fromRGB(58,165,56)
local machineESPs={}
local function colorMatch(a,b,tol) tol=tol or 28
    return math.abs(a.R*255-b.R*255)<=tol and math.abs(a.G*255-b.G*255)<=tol and math.abs(a.B*255-b.B*255)<=tol end

local function setupMachine(obj)
    if obj.Name~="BaseMachine" or machineESPs[obj] then return end
    local light=obj:FindFirstChild("Light",true) if not light then return end
    local part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") if not part then return end
    local hl=Instance.new("Highlight") hl.Name="AuroraM" hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.OutlineColor=T.White hl.Parent=obj
    local bb=Instance.new("BillboardGui") bb.Name="AuroraM" bb.Adornee=part bb.Size=UDim2.new(0,170,0,26)
    bb.StudsOffset=Vector3.new(0,3,0) bb.AlwaysOnTop=true bb.MaxDistance=500 bb.Parent=obj
    local lbl=Instance.new("TextLabel") lbl.Size=UDim2.fromScale(1,1) lbl.BackgroundTransparency=1
    lbl.TextSize=13 lbl.Font=Enum.Font.GothamBold lbl.TextStrokeTransparency=0 lbl.Parent=bb
    local curState="incomplete"
    local function apply(state)
        curState=state local cfg=State.machines[state]
        local en=cfg and cfg.enabled~=false hl.Enabled=en bb.Enabled=en
        local col=cfg and cfg.colors and cfg.colors[1] and c3(cfg.colors[1]) or T.White
        hl.FillColor=col
        if state=="complete" then lbl.TextColor3=col lbl.Text="✔ Completed"
        elseif state=="completing" then lbl.TextColor3=col lbl.Text="⚙ Completing..."
        else lbl.TextColor3=T.White end
    end
    local function eval(color)
        if colorMatch(color,COL_GRN) then apply("complete")
        elseif colorMatch(color,COL_YEL) then apply("completing")
        else apply("incomplete") end
    end
    eval(light.Color)
    light:GetPropertyChangedSignal("Color"):Connect(function() eval(light.Color) end)
    machineESPs[obj]=true
    task.spawn(function()
        while obj.Parent do
            if curState=="incomplete" then
                local ch=LP.Character local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
                if hrp then lbl.Text=string.format("⚙ %d studs",math.floor((hrp.Position-part.Position).Magnitude)) end
            end task.wait(0.1) end machineESPs[obj]=nil end)
end

-- ============================================================
--  ESP — MONSTERS
-- ============================================================
local monsterESPs={}
local function getMonCfg(name) if not State.monsters[name] then State.monsters[name]={enabled=true,colors={{R=255,G=0,B=0}}} end return State.monsters[name] end
local function setupMonster(obj)
    if not obj.Name:match("Monster$") or not obj:IsA("Model") or monsterESPs[obj] then return end
    monsterESPs[obj]=true
    task.spawn(function()
        local part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        local w=0 while not part and obj.Parent and w<5 do task.wait(0.1) w=w+0.1 part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") end
        if not part or not obj.Parent then monsterESPs[obj]=nil return end
        local cfg=getMonCfg(obj.Name) local dn=obj.Name:gsub("Monster$","")
        local hl=Instance.new("Highlight") hl.Name="AuroraT" hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        hl.OutlineColor=T.White hl.FillColor=c3(cfg.colors[1]) hl.Enabled=cfg.enabled hl.Parent=obj
        local bb=Instance.new("BillboardGui") bb.Name="AuroraT" bb.Adornee=part
        bb.Size=UDim2.new(0,200,0,28) bb.StudsOffset=Vector3.new(0,4.5,0) bb.AlwaysOnTop=true bb.MaxDistance=math.huge bb.Enabled=cfg.enabled bb.Parent=obj
        local lbl=Instance.new("TextLabel") lbl.Size=UDim2.fromScale(1,1) lbl.BackgroundTransparency=1
        lbl.TextSize=14 lbl.Font=Enum.Font.GothamBold lbl.TextStrokeTransparency=0
        lbl.TextColor3=c3(cfg.colors[1]) lbl.Text="⚠ "..dn lbl.Parent=bb
        local idx=1 monsterESPs[obj]={hl=hl,bb=bb,lbl=lbl}
        task.spawn(function() while obj.Parent do local cols=cfg.colors
            if #cols>1 then idx=(idx%#cols)+1 local col=c3(cols[idx])
                tw(hl,TweenInfo.new(0.6),{FillColor=col}) tw(lbl,TweenInfo.new(0.6),{TextColor3=col}) end
            task.wait(0.8) end monsterESPs[obj]=nil end)
    end)
end

-- ============================================================
--  ESP — ITEMS
-- ============================================================
local ITEM_DEFS={
    ResearchCapsule={icon="🧪",label="Capsule", color={R=0,G=200,B=255}},
    Bandage         ={icon="🩹",label="Bandage", color={R=255,G=255,B=255}},
    MedKit          ={icon="➕",label="Med Kit", color={R=255,G=80,B=80}},
    FirstAidKit     ={icon="➕",label="Med Kit", color={R=255,G=80,B=80}},
    Valve           ={icon="🔧",label="Valve",   color={R=200,G=150,B=50}},
    PipeValve       ={icon="🔧",label="Valve",   color={R=200,G=150,B=50}},
}
local itemESPs={}
local function getItemCfg(name) local def=ITEM_DEFS[name]
    if not State.items[name] then State.items[name]={enabled=true,colors={def and def.color or {R=0,G=200,B=255}}} end return State.items[name] end
local function setupItem(obj)
    if not(obj:IsA("Model") or obj:IsA("BasePart")) or not ITEM_DEFS[obj.Name] or itemESPs[obj] then return end
    itemESPs[obj]=true local def=ITEM_DEFS[obj.Name]
    task.spawn(function()
        local part=obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        local w=0 while not part and obj.Parent and w<5 do task.wait(0.1) w=w+0.1 part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") end
        if not part or not obj.Parent then itemESPs[obj]=nil return end
        local cfg=getItemCfg(obj.Name)
        local hl=Instance.new("Highlight") hl.Name="AuroraI" hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        hl.OutlineColor=T.White hl.FillColor=c3(cfg.colors[1]) hl.Enabled=cfg.enabled hl.Parent=obj
        local bb=Instance.new("BillboardGui") bb.Name="AuroraI" bb.Adornee=part
        bb.Size=UDim2.new(0,170,0,26) bb.StudsOffset=Vector3.new(0,2.5,0) bb.AlwaysOnTop=true bb.MaxDistance=math.huge bb.Enabled=cfg.enabled bb.Parent=obj
        local lbl=Instance.new("TextLabel") lbl.Size=UDim2.fromScale(1,1) lbl.BackgroundTransparency=1
        lbl.TextSize=13 lbl.Font=Enum.Font.GothamBold lbl.TextStrokeTransparency=0
        lbl.TextColor3=c3(cfg.colors[1]) lbl.Text=def.icon.." "..def.label lbl.Parent=bb
        local idx=1 itemESPs[obj]={hl=hl,bb=bb,lbl=lbl}
        task.spawn(function() while obj.Parent do local cols=cfg.colors
            if #cols>1 then idx=(idx%#cols)+1 local col=c3(cols[idx])
                tw(hl,TweenInfo.new(0.6),{FillColor=col}) tw(lbl,TweenInfo.new(0.6),{TextColor3=col}) end
            task.wait(0.8) end itemESPs[obj]=nil end)
    end)
end

-- ============================================================
--  WORKSPACE WATCHERS
-- ============================================================
for _,v in ipairs(workspace:GetDescendants()) do setupMachine(v) end
workspace.DescendantAdded:Connect(setupMachine)
local function watchRoom(room)
    for _,d in ipairs(room:GetDescendants()) do setupMonster(d) setupItem(d) end
    room.DescendantAdded:Connect(function(d) setupMonster(d) setupItem(d) end)
end
local cr=workspace:FindFirstChild("CurrentRoom")
if cr then watchRoom(cr) else
    local wc; wc=workspace.ChildAdded:Connect(function(c)
        if c.Name=="CurrentRoom" then wc:Disconnect() watchRoom(c) end end) end

-- ============================================================
--  GUI — GLASSMORPHISM NEON
-- ============================================================
local old=PG:FindFirstChild("AuroraHub") if old then old:Destroy() end
local SG=Instance.new("ScreenGui")
SG.Name="AuroraHub" SG.ResetOnSpawn=false SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling SG.Parent=PG

-- ── F Button ──
local FB=Instance.new("TextButton")
FB.Size=UDim2.new(0,44,0,44) FB.Position=UDim2.new(0,14,0.5,-22)
FB.BackgroundColor3=T.Glass FB.BackgroundTransparency=0.3
FB.Text="F" FB.TextColor3=T.Neon FB.TextSize=20 FB.Font=Enum.Font.GothamBold
FB.ZIndex=20 FB.Parent=SG
mkCorner(FB,10) mkStroke(FB,T.Neon,2,0.1)
mkGrad(FB,Color3.fromRGB(5,20,50),Color3.fromRGB(0,10,30),135)

-- Neon glow pulse on F button
task.spawn(function()
    while FB.Parent do
        tw(FB,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{TextColor3=T.NeonDim})
        task.wait(1.2)
        tw(FB,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{TextColor3=T.NeonGlow})
        task.wait(1.2)
    end
end)

-- ── Window ──
local WIN=Instance.new("Frame")
WIN.Name="Win" WIN.Size=UDim2.new(0.88,0,0.72,0) WIN.Position=UDim2.new(0.06,0,0.14,0)
WIN.BackgroundColor3=T.Glass WIN.BackgroundTransparency=T.PanelTR
WIN.BorderSizePixel=0 WIN.ZIndex=10 WIN.Parent=SG
mkCorner(WIN,14) mkStroke(WIN,T.BorderNeon,1.5,T.StrokeTR)
mkGrad(WIN,Color3.fromRGB(5,20,50),Color3.fromRGB(2,10,28),135)

-- Glass scanline texture effect
local scan=Instance.new("Frame") scan.Size=UDim2.fromScale(1,1) scan.BackgroundTransparency=1
scan.ZIndex=10 scan.Parent=WIN
mkGrad(scan,Color3.fromRGB(0,180,255),Color3.fromRGB(0,0,0),90)
local scanStroke=Instance.new("UIStroke") scanStroke.Transparency=0.97 scanStroke.Thickness=0 scanStroke.Parent=scan

-- ── Title Bar ──
local TB=Instance.new("Frame")
TB.Size=UDim2.new(1,0,0,48) TB.BackgroundColor3=T.GlassPanel
TB.BackgroundTransparency=0.4 TB.BorderSizePixel=0 TB.ZIndex=11 TB.Parent=WIN
mkCorner(TB,14)
-- patch bottom corners
local tbpatch=Instance.new("Frame") tbpatch.Size=UDim2.new(1,0,0.5,0) tbpatch.Position=UDim2.new(0,0,0.5,0)
tbpatch.BackgroundColor3=T.GlassPanel tbpatch.BackgroundTransparency=0.4 tbpatch.BorderSizePixel=0 tbpatch.ZIndex=11 tbpatch.Parent=TB
-- bottom border line (neon separator)
local sep=Instance.new("Frame") sep.Size=UDim2.new(1,-20,0,1) sep.Position=UDim2.new(0,10,1,-1)
sep.BackgroundColor3=T.Neon sep.BackgroundTransparency=0.5 sep.BorderSizePixel=0 sep.ZIndex=12 sep.Parent=TB

-- Accent bar left
local accentBar=Instance.new("Frame") accentBar.Size=UDim2.new(0,3,0.7,0) accentBar.Position=UDim2.new(0,0,0.15,0)
accentBar.BackgroundColor3=T.Neon accentBar.BackgroundTransparency=0.1 accentBar.BorderSizePixel=0 accentBar.ZIndex=13 accentBar.Parent=TB
mkCorner(accentBar,2)

local TitleLbl=Instance.new("TextLabel")
TitleLbl.Size=UDim2.new(1,-105,0,24) TitleLbl.Position=UDim2.new(0,14,0,4)
TitleLbl.BackgroundTransparency=1 TitleLbl.Text="Aurora Hub"
TitleLbl.TextColor3=T.Neon TitleLbl.TextSize=16 TitleLbl.Font=Enum.Font.GothamBold
TitleLbl.TextXAlignment=Enum.TextXAlignment.Left TitleLbl.ZIndex=12 TitleLbl.Parent=TB

local SubLbl=Instance.new("TextLabel")
SubLbl.Size=UDim2.new(1,-105,0,14) SubLbl.Position=UDim2.new(0,14,0,28)
SubLbl.BackgroundTransparency=1 SubLbl.Text="v"..VERSION.."  ·  Profile: "..Profiles._current
SubLbl.TextColor3=T.NeonDim SubLbl.TextSize=10 SubLbl.Font=Enum.Font.Gotham
SubLbl.TextXAlignment=Enum.TextXAlignment.Left SubLbl.ZIndex=12 SubLbl.Parent=TB

-- Window control buttons
local function winBtn(icon, xOff, col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,26,0,26) b.Position=UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3=col b.BackgroundTransparency=0.3
    b.Text=icon b.TextColor3=T.White b.TextSize=12 b.Font=Enum.Font.GothamBold
    b.ZIndex=13 b.BorderSizePixel=0 b.Parent=TB
    mkCorner(b,6) mkStroke(b,col,1,0.5) return b
end
local BMin   = winBtn("─", -62, T.NeonBlue)
local BClose = winBtn("✕", -32, T.Red)

-- ── Tab Bar ──
local TABH=38
local TabRow=Instance.new("Frame")
TabRow.Size=UDim2.new(1,0,0,TABH) TabRow.Position=UDim2.new(0,0,0,48)
TabRow.BackgroundColor3=T.GlassCard TabRow.BackgroundTransparency=0.5
TabRow.BorderSizePixel=0 TabRow.ZIndex=11 TabRow.Parent=WIN
mkList(TabRow,0,Enum.FillDirection.Horizontal)

-- neon line below tabs
local tabLine=Instance.new("Frame") tabLine.Size=UDim2.new(1,0,0,1) tabLine.Position=UDim2.new(0,0,1,-1)
tabLine.BackgroundColor3=T.Neon tabLine.BackgroundTransparency=0.6 tabLine.BorderSizePixel=0 tabLine.ZIndex=12 tabLine.Parent=TabRow

-- ── Content ──
local Content=Instance.new("Frame")
Content.Size=UDim2.new(1,0,1,-(48+TABH)) Content.Position=UDim2.new(0,0,0,48+TABH)
Content.BackgroundTransparency=1 Content.ClipsDescendants=true Content.ZIndex=10 Content.Parent=WIN

-- ============================================================
--  TAB SYSTEM
-- ============================================================
local tabDefs={{name="Machines",icon="⚙"},{name="Monsters",icon="👾"},{name="Items",icon="🎒"},{name="Profiles",icon="👤"}}
local tabPages={} local activeTab=nil
local TABW=1/#tabDefs

for _,def in ipairs(tabDefs) do
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(TABW,0,1,0) btn.BackgroundTransparency=1
    btn.Text=def.icon.." " btn.TextSize=17 btn.Font=Enum.Font.GothamBold
    btn.TextColor3=T.TextDim btn.BorderSizePixel=0 btn.ZIndex=12 btn.Parent=TabRow

    local bar=Instance.new("Frame")
    bar.Size=UDim2.new(0.5,0,0,2) bar.Position=UDim2.new(0.25,0,1,-2)
    bar.BackgroundColor3=T.Neon bar.BorderSizePixel=0 bar.BackgroundTransparency=1 bar.ZIndex=13 bar.Parent=btn

    local page=Instance.new("ScrollingFrame")
    page.Size=UDim2.fromScale(1,1) page.BackgroundTransparency=1 page.BorderSizePixel=0
    page.ScrollBarThickness=3 page.ScrollBarImageColor3=T.Neon
    page.CanvasSize=UDim2.new(0,0,0,0) page.AutomaticCanvasSize=Enum.AutomaticSize.Y
    page.Visible=false page.ZIndex=11 page.Parent=Content
    local ll=mkList(page,5) ll.HorizontalAlignment=Enum.HorizontalAlignment.Center
    mkPad(page,10,8)

    tabPages[def.name]={page=page,btn=btn,bar=bar}

    btn.MouseButton1Click:Connect(function()
        if activeTab==def.name then return end
        if activeTab then
            local o2=tabPages[activeTab]
            o2.page.Visible=false
            tw(o2.bar,TF,{BackgroundTransparency=1})
            tw(o2.btn,TF,{TextColor3=T.TextDim})
        end
        activeTab=def.name page.Visible=true
        tw(bar,TF,{BackgroundTransparency=0})
        tw(btn,TF,{TextColor3=T.Neon})
    end)
end

-- ============================================================
--  UI COMPONENTS
-- ============================================================
local function sectionHdr(parent, text, order)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,30) f.BackgroundColor3=T.GlassCard
    f.BackgroundTransparency=0.4 f.BorderSizePixel=0 f.LayoutOrder=order f.Parent=parent
    mkCorner(f,7) mkStroke(f,T.BorderNeon,1,0.6)
    -- left accent
    local a=Instance.new("Frame") a.Size=UDim2.new(0,3,0.6,0) a.Position=UDim2.new(0,0,0.2,0)
    a.BackgroundColor3=T.Neon a.BackgroundTransparency=0 a.BorderSizePixel=0 a.ZIndex=12 a.Parent=f
    mkCorner(a,2)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-14,1,0) l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1 l.Text=text l.TextColor3=T.Neon
    l.TextSize=12 l.Font=Enum.Font.GothamBold l.TextXAlignment=Enum.TextXAlignment.Left l.ZIndex=12 l.Parent=f
    return f
end

local function divider(parent, order)
    local d=Instance.new("Frame") d.Size=UDim2.new(1,0,0,1)
    d.BackgroundColor3=T.BorderFaint d.BackgroundTransparency=0.3
    d.BorderSizePixel=0 d.LayoutOrder=order d.Parent=parent
end

local function toggleRow(parent, ltext, initVal, order, onChange)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,38) row.BackgroundColor3=T.GlassCard
    row.BackgroundTransparency=0.55 row.BorderSizePixel=0 row.LayoutOrder=order row.Parent=parent
    mkCorner(row,7) mkStroke(row,T.BorderFaint,1,0.5)

    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-62,1,0) l.Position=UDim2.new(0,12,0,0)
    l.BackgroundTransparency=1 l.Text=ltext l.TextColor3=T.TextBright
    l.TextSize=12 l.Font=Enum.Font.Gotham l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=row

    -- Toggle pill
    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(0,40,0,20) bg.Position=UDim2.new(1,-50,0.5,-10)
    bg.BackgroundColor3=initVal and T.Neon or T.GlassHover
    bg.BackgroundTransparency=initVal and 0.1 or 0.4
    bg.BorderSizePixel=0 bg.Parent=row
    mkCorner(bg,10)
    if initVal then mkStroke(bg,T.Neon,1,0.2) end

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,14,0,14)
    knob.Position=initVal and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3=T.White knob.BorderSizePixel=0 knob.Parent=bg
    mkCorner(knob,7)

    local state=initVal
    local hit=Instance.new("TextButton")
    hit.Size=UDim2.fromScale(1,1) hit.BackgroundTransparency=1 hit.Text="" hit.Parent=row
    hit.MouseButton1Click:Connect(function()
        state=not state
        tw(bg,TF,{BackgroundColor3=state and T.Neon or T.GlassHover, BackgroundTransparency=state and 0.1 or 0.4})
        tw(knob,TF,{Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
        if onChange then onChange(state) end
    end)
    return row
end

local function colorListWidget(parent, initColors, order, onChange)
    local colors={} for _,c in ipairs(initColors) do colors[#colors+1]={R=c.R,G=c.G,B=c.B} end

    local wrap=Instance.new("Frame")
    wrap.Size=UDim2.new(1,0,0,0) wrap.AutomaticSize=Enum.AutomaticSize.Y
    wrap.BackgroundColor3=T.GlassCard wrap.BackgroundTransparency=0.55
    wrap.BorderSizePixel=0 wrap.LayoutOrder=order wrap.Parent=parent
    mkCorner(wrap,7) mkStroke(wrap,T.BorderFaint,1,0.6)

    local inner=Instance.new("Frame")
    inner.Size=UDim2.new(1,0,0,0) inner.AutomaticSize=Enum.AutomaticSize.Y
    inner.BackgroundTransparency=1 inner.Parent=wrap
    mkList(inner,4) mkPad(inner,8,6)

    local hdr=Instance.new("TextLabel")
    hdr.Size=UDim2.new(1,0,0,16) hdr.BackgroundTransparency=1
    hdr.Text="COLORS" hdr.TextColor3=T.NeonDim hdr.TextSize=10
    hdr.Font=Enum.Font.GothamBold hdr.TextXAlignment=Enum.TextXAlignment.Left
    hdr.LayoutOrder=0 hdr.Parent=inner

    local rows={} local addB

    local function makeChannel(parent2, ch, xOff, initVal, onChange2)
        local f=Instance.new("Frame")
        f.Size=UDim2.new(0,58,0,24) f.Position=UDim2.new(0,xOff,0.5,-12)
        f.BackgroundColor3=T.Glass f.BackgroundTransparency=0.3 f.BorderSizePixel=0 f.Parent=parent2
        mkCorner(f,5) mkStroke(f,T.BorderNeon,1,0.7)
        local pl=Instance.new("TextLabel")
        pl.Size=UDim2.new(0,14,1,0) pl.BackgroundTransparency=1
        pl.Text=ch pl.TextColor3=T.Neon pl.TextSize=10 pl.Font=Enum.Font.GothamBold pl.Parent=f
        local tb=Instance.new("TextBox")
        tb.Size=UDim2.new(1,-15,1,0) tb.Position=UDim2.new(0,15,0,0)
        tb.BackgroundTransparency=1 tb.Text=tostring(initVal)
        tb.TextColor3=T.TextBright tb.TextSize=11 tb.Font=Enum.Font.Gotham
        tb.ClearTextOnFocus=false tb.Parent=f
        tb.FocusLost:Connect(function()
            local v=tonumber(tb.Text)
            if v then v=math.clamp(math.floor(v),0,255) tb.Text=tostring(v) if onChange2 then onChange2(ch,v) end
            else tb.Text=tostring(initVal) end
        end)
        return tb
    end

    local function rebuild()
        for _,r in ipairs(rows) do r:Destroy() end rows={}
        for i,col in ipairs(colors) do
            local ii=i
            local rf=Instance.new("Frame")
            rf.Size=UDim2.new(1,0,0,30) rf.BackgroundTransparency=1 rf.LayoutOrder=i rf.Parent=inner

            local preview=Instance.new("Frame")
            preview.Size=UDim2.new(0,16,0,16) preview.Position=UDim2.new(0,0,0.5,-8)
            preview.BackgroundColor3=c3(col) preview.BorderSizePixel=0 preview.Parent=rf
            mkCorner(preview,4) mkStroke(preview,T.Neon,1,0.3)

            local function onCh(ch,v)
                colors[ii][ch]=v preview.BackgroundColor3=c3(colors[ii])
                if onChange then onChange(colors) end
            end
            makeChannel(rf,"R",22,col.R,onCh)
            makeChannel(rf,"G",84,col.G,onCh)
            makeChannel(rf,"B",146,col.B,onCh)

            if #colors>1 then
                local rb=Instance.new("TextButton")
                rb.Size=UDim2.new(0,20,0,20) rb.Position=UDim2.new(1,-20,0.5,-10)
                rb.BackgroundColor3=T.Red rb.BackgroundTransparency=0.3
                rb.Text="✕" rb.TextColor3=T.White rb.TextSize=10 rb.Font=Enum.Font.GothamBold
                rb.BorderSizePixel=0 rb.Parent=rf mkCorner(rb,5)
                rb.MouseButton1Click:Connect(function()
                    table.remove(colors,ii) rebuild() if onChange then onChange(colors) end
                end)
            end
            rows[#rows+1]=rf
        end
        if addB then addB.LayoutOrder=#colors+2 end
    end

    addB=Instance.new("TextButton")
    addB.Size=UDim2.new(1,0,0,26) addB.BackgroundColor3=T.Glass addB.BackgroundTransparency=0.3
    addB.Text="＋  Add Color" addB.TextColor3=T.Neon addB.TextSize=12 addB.Font=Enum.Font.GothamBold
    addB.BorderSizePixel=0 addB.LayoutOrder=999 addB.Parent=inner
    mkCorner(addB,6) mkStroke(addB,T.Neon,1,0.5)
    addB.MouseButton1Click:Connect(function()
        colors[#colors+1]={R=0,G=200,B=255} rebuild() if onChange then onChange(colors) end
    end)
    rebuild() return wrap
end

-- ============================================================
--  POPULATE TABS
-- ============================================================

-- ── MACHINES ──
do
    local pg=tabPages["Machines"].page local o=0
    local function ms(key,title)
        local cfg=State.machines[key]
        o=o+1 sectionHdr(pg,title,o)
        o=o+1 toggleRow(pg,"Enable ESP",cfg.enabled,o,function(v) cfg.enabled=v end)
        o=o+1 colorListWidget(pg,cfg.colors,o,function(cols) cfg.colors=cols end)
        o=o+1 divider(pg,o)
    end
    ms("complete",  "✔  Machine Complete")
    ms("completing","⚙  Machine Completing")
    ms("incomplete","⚙  Machine Incomplete")
end

-- ── MONSTERS ──
local monsterRowAdded={}
local function addMonsterUIRow(name)
    if monsterRowAdded[name] then return end monsterRowAdded[name]=true
    local pg=tabPages["Monsters"].page
    local base=0 for _ in pairs(monsterRowAdded) do base=base+4 end
    local dn=name:gsub("Monster$","") local cfg=getMonCfg(name)
    sectionHdr(pg,"⚠  "..dn,base)
    toggleRow(pg,"Enable ESP",cfg.enabled,base+1,function(v)
        cfg.enabled=v
        for obj,data in pairs(monsterESPs) do
            if type(obj)~="string" and obj.Name==name and type(data)=="table" then data.hl.Enabled=v data.bb.Enabled=v end
        end
    end)
    colorListWidget(pg,cfg.colors,base+2,function(cols) cfg.colors=cols end)
    divider(pg,base+3)
end
local function onMonDet(obj) if obj.Name:match("Monster$") and obj:IsA("Model") then addMonsterUIRow(obj.Name) end end
local crM=workspace:FindFirstChild("CurrentRoom")
if crM then for _,d in ipairs(crM:GetDescendants()) do onMonDet(d) end crM.DescendantAdded:Connect(onMonDet) end
workspace.ChildAdded:Connect(function(c) if c.Name=="CurrentRoom" then c.DescendantAdded:Connect(onMonDet) end end)

-- ── ITEMS ──
do
    local pg=tabPages["Items"].page local o=0
    for name,def in pairs(ITEM_DEFS) do
        local cfg=getItemCfg(name)
        o=o+1 sectionHdr(pg,def.icon.."  "..name,o)
        o=o+1 toggleRow(pg,"Enable ESP",cfg.enabled,o,function(v)
            cfg.enabled=v
            for obj,data in pairs(itemESPs) do
                if type(data)=="table" and obj.Name==name then data.hl.Enabled=v data.bb.Enabled=v end
            end
        end)
        o=o+1 colorListWidget(pg,cfg.colors,o,function(cols) cfg.colors=cols end)
        o=o+1 divider(pg,o)
    end
end

-- ── PROFILES ──
local profListFrame
do
    local pg=tabPages["Profiles"].page local o=0
    o=o+1 sectionHdr(pg,"👤  Profile Manager",o)

    local inputF=Instance.new("Frame")
    inputF.Size=UDim2.new(1,0,0,38) inputF.BackgroundColor3=T.GlassCard
    inputF.BackgroundTransparency=0.5 inputF.BorderSizePixel=0 inputF.LayoutOrder=o+1 inputF.Parent=pg
    mkCorner(inputF,7) mkStroke(inputF,T.BorderFaint,1,0.5)

    local nameBox=Instance.new("TextBox")
    nameBox.Size=UDim2.new(1,-84,1,-10) nameBox.Position=UDim2.new(0,8,0,5)
    nameBox.BackgroundColor3=T.Glass nameBox.BackgroundTransparency=0.3
    nameBox.PlaceholderText="Profile name..." nameBox.PlaceholderColor3=T.TextDim
    nameBox.Text="" nameBox.TextColor3=T.TextBright nameBox.TextSize=12 nameBox.Font=Enum.Font.Gotham
    nameBox.BorderSizePixel=0 nameBox.ClearTextOnFocus=false nameBox.Parent=inputF
    mkCorner(nameBox,5) mkStroke(nameBox,T.BorderNeon,1,0.6)

    local createB=Instance.new("TextButton")
    createB.Size=UDim2.new(0,70,1,-10) createB.Position=UDim2.new(1,-74,0,5)
    createB.BackgroundColor3=T.NeonBlue createB.BackgroundTransparency=0.2
    createB.Text="＋ New" createB.TextColor3=T.White createB.TextSize=11 createB.Font=Enum.Font.GothamBold
    createB.BorderSizePixel=0 createB.Parent=inputF
    mkCorner(createB,5) mkStroke(createB,T.Neon,1,0.3)

    o=o+2 divider(pg,o)

    profListFrame=Instance.new("Frame")
    profListFrame.Size=UDim2.new(1,0,0,0) profListFrame.AutomaticSize=Enum.AutomaticSize.Y
    profListFrame.BackgroundTransparency=1 profListFrame.LayoutOrder=o+1 profListFrame.Parent=pg
    mkList(profListFrame,5)

    local function refreshProfiles()
        for _,c in ipairs(profListFrame:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
        local names=Profiles.list()
        if #names==0 then
            local empty=Instance.new("TextLabel")
            empty.Size=UDim2.new(1,0,0,40) empty.BackgroundTransparency=1
            empty.Text="No profiles yet.\nCreate one above!" empty.TextColor3=T.TextDim
            empty.TextSize=11 empty.Font=Enum.Font.Gotham empty.LayoutOrder=1 empty.Parent=profListFrame
            return
        end
        for i,name in ipairs(names) do
            local row=Instance.new("Frame")
            row.Size=UDim2.new(1,0,0,40) row.BackgroundColor3=T.GlassCard
            row.BackgroundTransparency=name==Profiles._current and 0.2 or 0.55
            row.BorderSizePixel=0 row.LayoutOrder=i row.Parent=profListFrame
            mkCorner(row,7)
            if name==Profiles._current then mkStroke(row,T.Neon,1.5,0.1) else mkStroke(row,T.BorderFaint,1,0.6) end

            local nl=Instance.new("TextLabel")
            nl.Size=UDim2.new(1,-120,1,0) nl.Position=UDim2.new(0,12,0,0)
            nl.BackgroundTransparency=1 nl.Text=(name==Profiles._current and "▶ " or "  ")..name
            nl.TextColor3=name==Profiles._current and T.Neon or T.TextBright
            nl.TextSize=12 nl.Font=Enum.Font.GothamBold nl.TextXAlignment=Enum.TextXAlignment.Left nl.Parent=row

            local function sb(txt,xOff,col,cb)
                local b=Instance.new("TextButton")
                b.Size=UDim2.new(0,32,0,26) b.Position=UDim2.new(1,xOff,0.5,-13)
                b.BackgroundColor3=col b.BackgroundTransparency=0.3
                b.Text=txt b.TextColor3=T.White b.TextSize=10 b.Font=Enum.Font.GothamBold
                b.BorderSizePixel=0 b.Parent=row
                mkCorner(b,5) mkStroke(b,col,1,0.4) b.MouseButton1Click:Connect(cb) return b
            end
            sb("Load",-110,T.NeonBlue,function()
                local data=Profiles.load(name) if data then State=data Profiles._current=name
                    SubLbl.Text="v"..VERSION.."  ·  Profile: "..name refreshProfiles() end end)
            sb("Save",-74,T.Green,function() Profiles.save(name,State) end)
            sb("Del",-38,T.Red,function()
                local cf=Instance.new("Frame")
                cf.Size=UDim2.new(1,0,0,54) cf.BackgroundColor3=T.GlassCard cf.BackgroundTransparency=0.2
                cf.BorderSizePixel=0 cf.LayoutOrder=i+0.5 cf.Parent=profListFrame
                mkCorner(cf,7) mkStroke(cf,T.Red,1.5,0.3)
                local ql=Instance.new("TextLabel")
                ql.Size=UDim2.new(1,0,0,26) ql.BackgroundTransparency=1
                ql.Text='Delete "'..name..'"?' ql.TextColor3=T.Red ql.TextSize=12 ql.Font=Enum.Font.GothamBold ql.Parent=cf
                local function cfBtn(txt,xOff,col,cb)
                    local b=Instance.new("TextButton")
                    b.Size=UDim2.new(0,60,0,22) b.Position=UDim2.new(0,xOff,0,28)
                    b.BackgroundColor3=col b.BackgroundTransparency=0.2 b.Text=txt
                    b.TextColor3=T.White b.TextSize=11 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0 b.Parent=cf
                    mkCorner(b,5) b.MouseButton1Click:Connect(cb)
                end
                cfBtn("Yes",10,T.Red,function() Profiles.delete(name) cf:Destroy() refreshProfiles() end)
                cfBtn("No",76,T.GlassHover,function() cf:Destroy() end)
            end)
        end
    end

    createB.MouseButton1Click:Connect(function()
        local n=nameBox.Text:match("^%s*(.-)%s*$")
        if n and #n>0 then Profiles.save(n,State) nameBox.Text="" refreshProfiles() end
    end)
    refreshProfiles()
end

-- ============================================================
--  DRAG
-- ============================================================
do
    local drag,ds,sp=false,nil,nil
    TB.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true ds=inp.Position sp=WIN.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then drag=false end end)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds
            WIN.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- ============================================================
--  WINDOW CONTROLS
-- ============================================================
local isOpen=true local isMin=false
local fullSize=WIN.Size local minSize=UDim2.new(WIN.Size.X.Scale,WIN.Size.X.Offset,0,48)

local function open()
    isOpen=true isMin=false WIN.Visible=true Content.Visible=true TabRow.Visible=true
    WIN.Size=UDim2.new(fullSize.X.Scale,fullSize.X.Offset,0,0)
    tw(WIN,TS,{Size=fullSize})
end
local function minimize()
    isMin=true Content.Visible=false TabRow.Visible=false tw(WIN,TF,{Size=minSize})
end
local function restore()
    isMin=false Content.Visible=true TabRow.Visible=true tw(WIN,TF,{Size=fullSize})
end
local function close()
    isOpen=false tw(WIN,TF,{Size=UDim2.new(fullSize.X.Scale,fullSize.X.Offset,0,0)})
    task.delay(0.25,function() WIN.Visible=false end)
end

BMin.MouseButton1Click:Connect(function() if isMin then restore() else minimize() end end)
BClose.MouseButton1Click:Connect(close)
FB.MouseButton1Click:Connect(function()
    if not isOpen then open() elseif isMin then restore() else minimize() end
end)

-- ── Activate first tab & open animation ──
tabPages["Machines"].btn.MouseButton1Click:Fire()
WIN.Size=UDim2.new(fullSize.X.Scale,fullSize.X.Offset,0,0)
task.wait(0.05)
tw(WIN,TS,{Size=fullSize})

print("[AuroraHub] v"..VERSION.." — Neon Glass carregado!")
