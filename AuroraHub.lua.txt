--[[
    AURORA HUB v1.0.0
    Dandy's World — Neon Glass
]]

local VERSION = "1.0.0"
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer
local PG           = LP:WaitForChild("PlayerGui")

-- ============================================================
-- HELPERS
-- ============================================================
local function tw(o,t,p) TweenService:Create(o,t,p):Play() end
local TF = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function corner(p,r)
    local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p end
local function stroke(p,col,th)
    local s=Instance.new("UIStroke") s.Color=col s.Thickness=th or 1.5
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s end
local function list(p,pad)
    local l=Instance.new("UIListLayout") l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Padding=UDim.new(0,pad or 4) l.Parent=p return l end
local function pad(p,x,y)
    local u=Instance.new("UIPadding")
    u.PaddingLeft=UDim.new(0,x) u.PaddingRight=UDim.new(0,x)
    u.PaddingTop=UDim.new(0,y) u.PaddingBottom=UDim.new(0,y) u.Parent=p end

-- ============================================================
-- THEME
-- ============================================================
local C = {
    BG       = Color3.fromRGB(6,  14,  30),
    Panel    = Color3.fromRGB(10, 22,  46),
    Card     = Color3.fromRGB(14, 30,  58),
    Hover    = Color3.fromRGB(20, 40,  75),
    Neon     = Color3.fromRGB(0,  210, 255),
    Blue     = Color3.fromRGB(30, 100, 255),
    NeonDim  = Color3.fromRGB(0,  120, 180),
    Border   = Color3.fromRGB(0,  150, 220),
    Faint    = Color3.fromRGB(20, 50,  90),
    TxtHi    = Color3.fromRGB(210,245, 255),
    TxtMid   = Color3.fromRGB(100,170, 210),
    TxtDim   = Color3.fromRGB(50, 100, 140),
    Green    = Color3.fromRGB(0,  220, 110),
    Yellow   = Color3.fromRGB(255,210, 0),
    Red      = Color3.fromRGB(255, 55,  80),
    White    = Color3.fromRGB(255,255, 255),
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
    machines = {
        complete   = {enabled=true,  colors={{R=0,  G=220,B=110}}},
        completing = {enabled=true,  colors={{R=255,G=210,B=0  }}},
        incomplete = {enabled=true,  colors={{R=0,  G=210,B=255}}},
    },
    monsters={}, items={},
}
local function c3(t) return Color3.fromRGB(t.R or 0,t.G or 0,t.B or 0) end

-- ============================================================
-- PROFILES (memory + writefile)
-- ============================================================
local Profiles={_mem={},_current="Default"}
local function fOk() return type(writefile)=="function" and type(readfile)=="function" end
local function jE(v)
    local t=type(v)
    if t=="nil" then return "null" elseif t=="boolean" or t=="number" then return tostring(v)
    elseif t=="string" then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"')..'"'
    elseif t=="table" then
        if #v>0 then local p={} for _,x in ipairs(v) do p[#p+1]=jE(x) end return"["..table.concat(p,",").."]"
        else local p={} for k,x in pairs(v) do p[#p+1]='"'..k..'":'..jE(x) end return"{"..table.concat(p,",").."}" end
    end return"null" end
local function jD(s)
    local i=1
    local function sk() while i<=#s and s:sub(i,i):match"%s" do i=i+1 end end
    local function ch() sk() return s:sub(i,i) end
    local pv
    local function pS() i=i+1 local r=""
        while i<=#s do local c=s:sub(i,i) if c=='"' then i=i+1 return r end
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
        else local n=s:match("^-?%d+%.?%d*",i) if n then i=i+#n return tonumber(n) end end end
    return pv() end
local FOLDER="AuroraHub/"
local function mkFolder() if fOk() and type(makefolder)=="function" then pcall(function() if not isfolder(FOLDER) then makefolder(FOLDER) end end) end end
function Profiles.save(n,d) Profiles._mem[n]=d if fOk() then mkFolder() pcall(writefile,FOLDER..n..".json",jE(d)) end end
function Profiles.load(n)
    if fOk() then local ok,c=pcall(readfile,FOLDER..n..".json") if ok and c then local ok2,d=pcall(jD,c) if ok2 then return d end end end
    return Profiles._mem[n] end
function Profiles.delete(n) Profiles._mem[n]=nil if fOk() then pcall(function() if isfile(FOLDER..n..".json") then delfile(FOLDER..n..".json") end end) end end
function Profiles.list()
    local out={} for k in pairs(Profiles._mem) do out[k]=true end
    if fOk() and type(listfiles)=="function" then local ok,fs=pcall(listfiles,FOLDER) if ok then for _,f in ipairs(fs) do local n=f:match("([^/\\]+)%.json$") if n then out[n]=true end end end end
    local r={} for k in pairs(out) do r[#r+1]=k end table.sort(r) return r end

-- ============================================================
-- ESP MACHINES
-- ============================================================
local COL_RED=Color3.fromRGB(167,0,0)
local COL_YEL=Color3.fromRGB(255,215,130)
local COL_GRN=Color3.fromRGB(58,165,56)
local mESP={}
local function cMatch(a,b,t) t=t or 28
    return math.abs(a.R*255-b.R*255)<=t and math.abs(a.G*255-b.G*255)<=t and math.abs(a.B*255-b.B*255)<=t end
local function setupMachine(obj)
    if obj.Name~="BaseMachine" or mESP[obj] then return end
    local light=obj:FindFirstChild("Light",true) if not light then return end
    local part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") if not part then return end
    local hl=Instance.new("Highlight") hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.OutlineColor=C.White hl.Parent=obj
    local bb=Instance.new("BillboardGui") bb.Adornee=part bb.Size=UDim2.new(0,170,0,26)
    bb.StudsOffset=Vector3.new(0,3,0) bb.AlwaysOnTop=true bb.MaxDistance=500 bb.Parent=obj
    local lbl=Instance.new("TextLabel") lbl.Size=UDim2.fromScale(1,1) lbl.BackgroundTransparency=1
    lbl.TextSize=13 lbl.Font=Enum.Font.GothamBold lbl.TextStrokeTransparency=0 lbl.Parent=bb
    local curState="incomplete"
    local function apply(s)
        curState=s local cfg=State.machines[s]
        hl.Enabled=cfg.enabled~=false bb.Enabled=cfg.enabled~=false
        local col=cfg.colors[1] and c3(cfg.colors[1]) or C.White hl.FillColor=col
        if s=="complete" then lbl.TextColor3=col lbl.Text="✔ Completed"
        elseif s=="completing" then lbl.TextColor3=col lbl.Text="⚙ Completing..."
        else lbl.TextColor3=C.White end
    end
    local function eval(color)
        if cMatch(color,COL_GRN) then apply("complete")
        elseif cMatch(color,COL_YEL) then apply("completing")
        else apply("incomplete") end
    end
    eval(light.Color)
    light:GetPropertyChangedSignal("Color"):Connect(function() eval(light.Color) end)
    mESP[obj]=true
    task.spawn(function()
        while obj.Parent do
            if curState=="incomplete" then
                local ch=LP.Character local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
                if hrp then lbl.Text=("⚙ %d studs"):format(math.floor((hrp.Position-part.Position).Magnitude)) end
            end task.wait(0.1) end mESP[obj]=nil end)
end
for _,v in ipairs(workspace:GetDescendants()) do setupMachine(v) end
workspace.DescendantAdded:Connect(setupMachine)

-- ============================================================
-- ESP MONSTERS
-- ============================================================
local tESP={}
local function getMonCfg(n) if not State.monsters[n] then State.monsters[n]={enabled=true,colors={{R=255,G=50,B=50}}} end return State.monsters[n] end
local function setupMonster(obj)
    if not obj.Name:match("Monster$") or not obj:IsA("Model") or tESP[obj] then return end
    tESP[obj]=true
    task.spawn(function()
        local part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        local w=0 while not part and obj.Parent and w<5 do task.wait(0.1) w+=0.1 part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") end
        if not part or not obj.Parent then tESP[obj]=nil return end
        local cfg=getMonCfg(obj.Name)
        local hl=Instance.new("Highlight") hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        hl.OutlineColor=C.White hl.FillColor=c3(cfg.colors[1]) hl.Enabled=cfg.enabled hl.Parent=obj
        local bb=Instance.new("BillboardGui") bb.Adornee=part bb.Size=UDim2.new(0,200,0,28)
        bb.StudsOffset=Vector3.new(0,4.5,0) bb.AlwaysOnTop=true bb.MaxDistance=math.huge bb.Enabled=cfg.enabled bb.Parent=obj
        local lbl=Instance.new("TextLabel") lbl.Size=UDim2.fromScale(1,1) lbl.BackgroundTransparency=1
        lbl.TextSize=14 lbl.Font=Enum.Font.GothamBold lbl.TextStrokeTransparency=0
        lbl.TextColor3=c3(cfg.colors[1]) lbl.Text="⚠ "..obj.Name:gsub("Monster$","") lbl.Parent=bb
        tESP[obj]={hl=hl,bb=bb,lbl=lbl}
        local idx=1 task.spawn(function() while obj.Parent do
            if #cfg.colors>1 then idx=(idx%#cfg.colors)+1 local col=c3(cfg.colors[idx])
                tw(hl,TweenInfo.new(0.7),{FillColor=col}) tw(lbl,TweenInfo.new(0.7),{TextColor3=col}) end
            task.wait(0.9) end tESP[obj]=nil end)
    end)
end

-- ============================================================
-- ESP ITEMS
-- ============================================================
local IDEFS={
    ResearchCapsule={icon="🧪",label="Capsule", color={R=0,  G=210,B=255}},
    Bandage         ={icon="🩹",label="Bandage", color={R=255,G=255,B=255}},
    MedKit          ={icon="➕",label="Med Kit", color={R=255,G=80, B=80 }},
    FirstAidKit     ={icon="➕",label="Med Kit", color={R=255,G=80, B=80 }},
    Valve           ={icon="🔧",label="Valve",   color={R=200,G=150,B=50 }},
    PipeValve       ={icon="🔧",label="Valve",   color={R=200,G=150,B=50 }},
}
local iESP={}
local function getItemCfg(n) local d=IDEFS[n]
    if not State.items[n] then State.items[n]={enabled=true,colors={d and d.color or {R=0,G=210,B=255}}} end return State.items[n] end
local function setupItem(obj)
    if not(obj:IsA("Model") or obj:IsA("BasePart")) or not IDEFS[obj.Name] or iESP[obj] then return end
    iESP[obj]=true local def=IDEFS[obj.Name]
    task.spawn(function()
        local part=(obj:IsA("BasePart") and obj) or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        local w=0 while not part and obj.Parent and w<5 do task.wait(0.1) w+=0.1 part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") end
        if not part or not obj.Parent then iESP[obj]=nil return end
        local cfg=getItemCfg(obj.Name)
        local hl=Instance.new("Highlight") hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        hl.OutlineColor=C.White hl.FillColor=c3(cfg.colors[1]) hl.Enabled=cfg.enabled hl.Parent=obj
        local bb=Instance.new("BillboardGui") bb.Adornee=part bb.Size=UDim2.new(0,170,0,26)
        bb.StudsOffset=Vector3.new(0,2.5,0) bb.AlwaysOnTop=true bb.MaxDistance=math.huge bb.Enabled=cfg.enabled bb.Parent=obj
        local lbl=Instance.new("TextLabel") lbl.Size=UDim2.fromScale(1,1) lbl.BackgroundTransparency=1
        lbl.TextSize=13 lbl.Font=Enum.Font.GothamBold lbl.TextStrokeTransparency=0
        lbl.TextColor3=c3(cfg.colors[1]) lbl.Text=def.icon.." "..def.label lbl.Parent=bb
        iESP[obj]={hl=hl,bb=bb,lbl=lbl}
        local idx=1 task.spawn(function() while obj.Parent do
            if #cfg.colors>1 then idx=(idx%#cfg.colors)+1 local col=c3(cfg.colors[idx])
                tw(hl,TweenInfo.new(0.7),{FillColor=col}) tw(lbl,TweenInfo.new(0.7),{TextColor3=col}) end
            task.wait(0.9) end iESP[obj]=nil end)
    end)
end

local function watchRoom(room)
    for _,d in ipairs(room:GetDescendants()) do setupMonster(d) setupItem(d) end
    room.DescendantAdded:Connect(function(d) setupMonster(d) setupItem(d) end)
end
local cr=workspace:FindFirstChild("CurrentRoom")
if cr then watchRoom(cr)
else local wc; wc=workspace.ChildAdded:Connect(function(c) if c.Name=="CurrentRoom" then wc:Disconnect() watchRoom(c) end end) end

-- ============================================================
-- GUI
-- ============================================================
local old=PG:FindFirstChild("AuroraHub") if old then old:Destroy() end
local SG=Instance.new("ScreenGui")
SG.Name="AuroraHub" SG.ResetOnSpawn=false SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling SG.IgnoreGuiInset=true SG.Parent=PG

-- F Button
local FB=Instance.new("TextButton")
FB.Size=UDim2.new(0,46,0,46) FB.Position=UDim2.new(0,14,0.5,-23)
FB.BackgroundColor3=C.Panel FB.Text="F" FB.TextColor3=C.Neon FB.TextSize=20 FB.Font=Enum.Font.GothamBold
FB.ZIndex=20 FB.Parent=SG corner(FB,10) stroke(FB,C.Neon,2)

-- Main Window — fixed pixel size, safe for mobile
local W,H = 310, 480
local WIN=Instance.new("Frame")
WIN.Size=UDim2.new(0,W,0,H)
WIN.Position=UDim2.new(0.5,-W/2,0.5,-H/2)
WIN.BackgroundColor3=C.BG WIN.BackgroundTransparency=0.15
WIN.BorderSizePixel=0 WIN.ZIndex=10 WIN.ClipsDescendants=true WIN.Parent=SG
corner(WIN,12) stroke(WIN,C.Border,1.5)

-- Title bar
local TB=Instance.new("Frame")
TB.Size=UDim2.new(1,0,0,50) TB.Position=UDim2.new(0,0,0,0)
TB.BackgroundColor3=C.Panel TB.BackgroundTransparency=0.2 TB.BorderSizePixel=0 TB.ZIndex=11 TB.Parent=WIN
corner(TB,12)
-- patch bottom corners of title bar
local tbp=Instance.new("Frame") tbp.Size=UDim2.new(1,0,0,20) tbp.Position=UDim2.new(0,0,1,-20)
tbp.BackgroundColor3=C.Panel tbp.BackgroundTransparency=0.2 tbp.BorderSizePixel=0 tbp.ZIndex=11 tbp.Parent=TB

-- Neon left bar
local nb=Instance.new("Frame") nb.Size=UDim2.new(0,3,0,28) nb.Position=UDim2.new(0,0,0.5,-14)
nb.BackgroundColor3=C.Neon nb.BorderSizePixel=0 nb.ZIndex=13 nb.Parent=TB corner(nb,2)

local TL=Instance.new("TextLabel")
TL.Size=UDim2.new(1,-90,0,26) TL.Position=UDim2.new(0,12,0,5)
TL.BackgroundTransparency=1 TL.Text="Aurora Hub" TL.TextColor3=C.Neon
TL.TextSize=16 TL.Font=Enum.Font.GothamBold TL.TextXAlignment=Enum.TextXAlignment.Left TL.ZIndex=12 TL.Parent=TB

local SL=Instance.new("TextLabel")
SL.Size=UDim2.new(1,-90,0,14) SL.Position=UDim2.new(0,12,0,30)
SL.BackgroundTransparency=1 SL.Text="v"..VERSION.."  ·  Profile: "..Profiles._current
SL.TextColor3=C.NeonDim SL.TextSize=10 SL.Font=Enum.Font.Gotham SL.TextXAlignment=Enum.TextXAlignment.Left SL.ZIndex=12 SL.Parent=TB

-- Min / Close buttons
local function winBtn(icon,x,col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,28,0,28) b.Position=UDim2.new(0,x,0.5,-14)
    b.BackgroundColor3=col b.BackgroundTransparency=0.2
    b.Text=icon b.TextColor3=C.White b.TextSize=14 b.Font=Enum.Font.GothamBold
    b.ZIndex=15 b.BorderSizePixel=0 b.Parent=TB corner(b,6) stroke(b,col,1) return b
end
local BMin   = winBtn("─", W-66, C.Blue)
local BClose = winBtn("✕", W-34, C.Red)

-- Separator line
local sep=Instance.new("Frame") sep.Size=UDim2.new(1,-20,0,1) sep.Position=UDim2.new(0,10,1,-1)
sep.BackgroundColor3=C.Neon sep.BackgroundTransparency=0.5 sep.BorderSizePixel=0 sep.ZIndex=12 sep.Parent=TB

-- Tab bar
local TABH=38
local TabBar=Instance.new("Frame")
TabBar.Size=UDim2.new(1,0,0,TABH) TabBar.Position=UDim2.new(0,0,0,50)
TabBar.BackgroundColor3=C.Panel TabBar.BackgroundTransparency=0.35 TabBar.BorderSizePixel=0 TabBar.ZIndex=11 TabBar.Parent=WIN
list(TabBar,0)
Instance.new("UIListLayout").FillDirection=Enum.FillDirection.Horizontal
do local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal l.SortOrder=Enum.SortOrder.LayoutOrder l.Parent=TabBar end

-- Content scroll
local CONTENT_Y = 50+TABH
local SF=Instance.new("ScrollingFrame")
SF.Size=UDim2.new(1,0,0,H-CONTENT_Y)
SF.Position=UDim2.new(0,0,0,CONTENT_Y)
SF.BackgroundTransparency=1 SF.BorderSizePixel=0
SF.ScrollBarThickness=4 SF.ScrollBarImageColor3=C.Neon
SF.CanvasSize=UDim2.new(0,0,0,0) SF.AutomaticCanvasSize=Enum.AutomaticSize.Y
SF.ZIndex=11 SF.Parent=WIN
list(SF,5) pad(SF,10,8)

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local TABS = {"⚙ Machines","👾 Monsters","🎒 Items","👤 Profiles"}
local tabBtns = {}
local pages   = {}  -- pages[name] = Frame inside SF
local activeTab = nil

-- We render all pages stacked and show/hide
for i,name in ipairs(TABS) do
    -- Button
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1/#TABS,0,1,0)
    btn.BackgroundTransparency=1 btn.BorderSizePixel=0
    btn.Text=name:match("^(..) ") -- just the icon
    btn.TextSize=18 btn.Font=Enum.Font.GothamBold
    btn.TextColor3=C.TxtDim btn.ZIndex=13 btn.LayoutOrder=i btn.Parent=TabBar

    local bar=Instance.new("Frame")
    bar.Size=UDim2.new(0.6,0,0,2) bar.Position=UDim2.new(0.2,0,1,-2)
    bar.BackgroundColor3=C.Neon bar.BorderSizePixel=0 bar.BackgroundTransparency=1 bar.ZIndex=14 bar.Parent=btn

    -- Page container (hidden by default inside SF)
    local page=Instance.new("Frame")
    page.Size=UDim2.new(1,0,0,0) page.AutomaticSize=Enum.AutomaticSize.Y
    page.BackgroundTransparency=1 page.BorderSizePixel=0
    page.Visible=false page.LayoutOrder=i page.ZIndex=12 page.Parent=SF
    list(page,5) pad(page,0,0)

    local shortName=name:gsub("^.. ","")
    pages[shortName]={page=page,btn=btn,bar=bar}
    tabBtns[i]={name=shortName,btn=btn,bar=bar,page=page}

    btn.MouseButton1Click:Connect(function()
        if activeTab==shortName then return end
        if activeTab and pages[activeTab] then
            pages[activeTab].page.Visible=false
            tw(pages[activeTab].bar,TF,{BackgroundTransparency=1})
            tw(pages[activeTab].btn,TF,{TextColor3=C.TxtDim})
        end
        activeTab=shortName
        page.Visible=true
        tw(bar,TF,{BackgroundTransparency=0})
        tw(btn,TF,{TextColor3=C.Neon})
        -- reset scroll to top
        SF.CanvasPosition=Vector2.new(0,0)
    end)
end

-- ============================================================
-- UI WIDGETS
-- ============================================================
local function hdr(parent,text,order)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,28) f.BackgroundColor3=C.Card f.BackgroundTransparency=0.3
    f.BorderSizePixel=0 f.LayoutOrder=order f.Parent=parent corner(f,6) stroke(f,C.Border,1)
    local lb=Instance.new("Frame") lb.Size=UDim2.new(0,3,0.65,0) lb.Position=UDim2.new(0,0,0.175,0)
    lb.BackgroundColor3=C.Neon lb.BorderSizePixel=0 lb.ZIndex=13 lb.Parent=f corner(lb,2)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-12,1,0) l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1 l.Text=text l.TextColor3=C.Neon
    l.TextSize=12 l.Font=Enum.Font.GothamBold l.TextXAlignment=Enum.TextXAlignment.Left l.ZIndex=13 l.Parent=f
    return f
end

local function divider(parent,order)
    local d=Instance.new("Frame") d.Size=UDim2.new(1,0,0,1) d.BackgroundColor3=C.Faint
    d.BackgroundTransparency=0.4 d.BorderSizePixel=0 d.LayoutOrder=order d.Parent=parent end

local function toggle(parent,text,init,order,cb)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,36) row.BackgroundColor3=C.Card row.BackgroundTransparency=0.45
    row.BorderSizePixel=0 row.LayoutOrder=order row.Parent=parent corner(row,6) stroke(row,C.Faint,1)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-60,1,0) l.Position=UDim2.new(0,10,0,0) l.BackgroundTransparency=1
    l.Text=text l.TextColor3=C.TxtHi l.TextSize=12 l.Font=Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=row
    local pill=Instance.new("Frame")
    pill.Size=UDim2.new(0,40,0,20) pill.Position=UDim2.new(1,-50,0.5,-10)
    pill.BackgroundColor3=init and C.Neon or C.Hover pill.BorderSizePixel=0 pill.Parent=row corner(pill,10)
    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,14,0,14) knob.BackgroundColor3=C.White knob.BorderSizePixel=0
    knob.Position=init and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7) knob.Parent=pill corner(knob,7)
    local state=init
    local hit=Instance.new("TextButton") hit.Size=UDim2.fromScale(1,1) hit.BackgroundTransparency=1 hit.Text="" hit.ZIndex=14 hit.Parent=row
    hit.MouseButton1Click:Connect(function()
        state=not state
        tw(pill,TF,{BackgroundColor3=state and C.Neon or C.Hover})
        tw(knob,TF,{Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
        if cb then cb(state) end
    end)
end

local function colorWidget(parent,initColors,order,cb)
    local colors={} for _,c in ipairs(initColors) do colors[#colors+1]={R=c.R,G=c.G,B=c.B} end
    local wrap=Instance.new("Frame")
    wrap.Size=UDim2.new(1,0,0,0) wrap.AutomaticSize=Enum.AutomaticSize.Y
    wrap.BackgroundColor3=C.Card wrap.BackgroundTransparency=0.45
    wrap.BorderSizePixel=0 wrap.LayoutOrder=order wrap.Parent=parent corner(wrap,6) stroke(wrap,C.Faint,1)
    local inner=Instance.new("Frame")
    inner.Size=UDim2.new(1,0,0,0) inner.AutomaticSize=Enum.AutomaticSize.Y
    inner.BackgroundTransparency=1 inner.Parent=wrap list(inner,4) pad(inner,8,6)
    local lh=Instance.new("TextLabel") lh.Size=UDim2.new(1,0,0,14) lh.BackgroundTransparency=1
    lh.Text="COLORS" lh.TextColor3=C.TxtDim lh.TextSize=10 lh.Font=Enum.Font.GothamBold
    lh.TextXAlignment=Enum.TextXAlignment.Left lh.LayoutOrder=0 lh.Parent=inner
    local rows={} local addB

    local function rebuild()
        for _,r in ipairs(rows) do r:Destroy() end rows={}
        for i,col in ipairs(colors) do
            local ii=i
            local rf=Instance.new("Frame")
            rf.Size=UDim2.new(1,0,0,30) rf.BackgroundTransparency=1 rf.LayoutOrder=i rf.Parent=inner
            local pv=Instance.new("Frame")
            pv.Size=UDim2.new(0,16,0,16) pv.Position=UDim2.new(0,0,0.5,-8)
            pv.BackgroundColor3=c3(col) pv.BorderSizePixel=0 pv.Parent=rf corner(pv,4) stroke(pv,C.Neon,1)

            for j,ch in ipairs({"R","G","B"}) do
                local xo=(j-1)*68+22
                local ff=Instance.new("Frame")
                ff.Size=UDim2.new(0,60,0,24) ff.Position=UDim2.new(0,xo,0.5,-12)
                ff.BackgroundColor3=C.BG ff.BackgroundTransparency=0.2 ff.BorderSizePixel=0 ff.Parent=rf
                corner(ff,5) stroke(ff,C.Border,1)
                local pl=Instance.new("TextLabel") pl.Size=UDim2.new(0,14,1,0) pl.BackgroundTransparency=1
                pl.Text=ch pl.TextColor3=C.Neon pl.TextSize=10 pl.Font=Enum.Font.GothamBold pl.Parent=ff
                local tb=Instance.new("TextBox")
                tb.Size=UDim2.new(1,-15,1,0) tb.Position=UDim2.new(0,15,0,0)
                tb.BackgroundTransparency=1 tb.Text=tostring(col[ch])
                tb.TextColor3=C.TxtHi tb.TextSize=11 tb.Font=Enum.Font.Gotham tb.ClearTextOnFocus=false tb.Parent=ff
                tb.FocusLost:Connect(function()
                    local v=tonumber(tb.Text)
                    if v then v=math.clamp(math.floor(v),0,255) colors[ii][ch]=v tb.Text=tostring(v)
                        pv.BackgroundColor3=c3(colors[ii]) if cb then cb(colors) end
                    else tb.Text=tostring(colors[ii][ch]) end
                end)
            end

            if #colors>1 then
                local rb=Instance.new("TextButton")
                rb.Size=UDim2.new(0,22,0,22) rb.Position=UDim2.new(1,-22,0.5,-11)
                rb.BackgroundColor3=C.Red rb.BackgroundTransparency=0.2 rb.Text="✕"
                rb.TextColor3=C.White rb.TextSize=11 rb.Font=Enum.Font.GothamBold rb.BorderSizePixel=0 rb.Parent=rf
                corner(rb,5)
                rb.MouseButton1Click:Connect(function() table.remove(colors,ii) rebuild() if cb then cb(colors) end end)
            end
            rows[#rows+1]=rf
        end
        if addB then addB.LayoutOrder=#colors+2 end
    end

    addB=Instance.new("TextButton")
    addB.Size=UDim2.new(1,0,0,26) addB.BackgroundColor3=C.BG addB.BackgroundTransparency=0.3
    addB.Text="＋  Add Color" addB.TextColor3=C.Neon addB.TextSize=12 addB.Font=Enum.Font.GothamBold
    addB.BorderSizePixel=0 addB.LayoutOrder=999 addB.Parent=inner corner(addB,5) stroke(addB,C.Neon,1)
    addB.MouseButton1Click:Connect(function() colors[#colors+1]={R=0,G=210,B=255} rebuild() if cb then cb(colors) end end)
    rebuild() return wrap
end

-- ============================================================
-- POPULATE PAGES
-- ============================================================

-- MACHINES
do
    local pg=pages["Machines"].page local o=0
    local function sec(key,title)
        local cfg=State.machines[key]
        o+=1 hdr(pg,title,o)
        o+=1 toggle(pg,"Enable ESP",cfg.enabled,o,function(v) cfg.enabled=v end)
        o+=1 colorWidget(pg,cfg.colors,o,function(cols) cfg.colors=cols end)
        o+=1 divider(pg,o)
    end
    sec("complete",  "✔  Machine Complete")
    sec("completing","⚙  Machine Completing")
    sec("incomplete","⚙  Machine Incomplete")
end

-- MONSTERS
local monAdded={}
local function addMonRow(name)
    if monAdded[name] then return end monAdded[name]=true
    local pg=pages["Monsters"].page
    local o=0 for _ in pairs(monAdded) do o+=4 end
    local dn=name:gsub("Monster$","") local cfg=getMonCfg(name)
    hdr(pg,"⚠  "..dn,o-3)
    toggle(pg,"Enable ESP",cfg.enabled,o-2,function(v)
        cfg.enabled=v
        for obj,data in pairs(tESP) do if type(data)=="table" and obj.Name==name then data.hl.Enabled=v data.bb.Enabled=v end end
    end)
    colorWidget(pg,cfg.colors,o-1,function(cols) cfg.colors=cols end)
    divider(pg,o)
end
local function onMon(obj) if obj.Name:match("Monster$") and obj:IsA("Model") then addMonRow(obj.Name) end end
local crM=workspace:FindFirstChild("CurrentRoom")
if crM then for _,d in ipairs(crM:GetDescendants()) do onMon(d) end crM.DescendantAdded:Connect(onMon) end
workspace.ChildAdded:Connect(function(c) if c.Name=="CurrentRoom" then c.DescendantAdded:Connect(onMon) end end)

-- ITEMS
do
    local pg=pages["Items"].page local o=0
    for name,def in pairs(IDEFS) do
        local cfg=getItemCfg(name)
        o+=1 hdr(pg,def.icon.."  "..name,o)
        o+=1 toggle(pg,"Enable ESP",cfg.enabled,o,function(v)
            cfg.enabled=v
            for obj,data in pairs(iESP) do if type(data)=="table" and obj.Name==name then data.hl.Enabled=v data.bb.Enabled=v end end
        end)
        o+=1 colorWidget(pg,cfg.colors,o,function(cols) cfg.colors=cols end)
        o+=1 divider(pg,o)
    end
end

-- PROFILES
local profList
do
    local pg=pages["Profiles"].page local o=0
    o+=1 hdr(pg,"👤  Profile Manager",o)

    local inp=Instance.new("Frame")
    inp.Size=UDim2.new(1,0,0,38) inp.BackgroundColor3=C.Card inp.BackgroundTransparency=0.4
    inp.BorderSizePixel=0 inp.LayoutOrder=2 inp.Parent=pg corner(inp,6) stroke(inp,C.Faint,1)
    local nb2=Instance.new("TextBox")
    nb2.Size=UDim2.new(1,-82,1,-10) nb2.Position=UDim2.new(0,8,0,5)
    nb2.BackgroundColor3=C.BG nb2.BackgroundTransparency=0.2 nb2.PlaceholderText="Profile name..."
    nb2.PlaceholderColor3=C.TxtDim nb2.Text="" nb2.TextColor3=C.TxtHi nb2.TextSize=12 nb2.Font=Enum.Font.Gotham
    nb2.BorderSizePixel=0 nb2.ClearTextOnFocus=false nb2.Parent=inp corner(nb2,5) stroke(nb2,C.Border,1)
    local cb2=Instance.new("TextButton")
    cb2.Size=UDim2.new(0,68,1,-10) cb2.Position=UDim2.new(1,-72,0,5)
    cb2.BackgroundColor3=C.Blue cb2.BackgroundTransparency=0.1 cb2.Text="＋ New"
    cb2.TextColor3=C.White cb2.TextSize=11 cb2.Font=Enum.Font.GothamBold cb2.BorderSizePixel=0 cb2.Parent=inp
    corner(cb2,5) stroke(cb2,C.Neon,1)

    o+=2 divider(pg,o)

    profList=Instance.new("Frame")
    profList.Size=UDim2.new(1,0,0,0) profList.AutomaticSize=Enum.AutomaticSize.Y
    profList.BackgroundTransparency=1 profList.LayoutOrder=o+1 profList.Parent=pg list(profList,5)

    local function refresh()
        for _,c in ipairs(profList:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
        local names=Profiles.list()
        if #names==0 then
            local e=Instance.new("TextLabel") e.Size=UDim2.new(1,0,0,36) e.BackgroundTransparency=1
            e.Text="Nenhum perfil criado ainda." e.TextColor3=C.TxtDim e.TextSize=11 e.Font=Enum.Font.Gotham
            e.LayoutOrder=1 e.Parent=profList return
        end
        for i,name in ipairs(names) do
            local row=Instance.new("Frame")
            row.Size=UDim2.new(1,0,0,40) row.LayoutOrder=i
            row.BackgroundColor3=C.Card row.BackgroundTransparency=name==Profiles._current and 0.1 or 0.5
            row.BorderSizePixel=0 row.Parent=profList corner(row,6)
            if name==Profiles._current then stroke(row,C.Neon,1.5) else stroke(row,C.Faint,1) end
            local nl=Instance.new("TextLabel")
            nl.Size=UDim2.new(1,-116,1,0) nl.Position=UDim2.new(0,10,0,0) nl.BackgroundTransparency=1
            nl.Text=(name==Profiles._current and "▶ " or "")..name nl.TextColor3=name==Profiles._current and C.Neon or C.TxtHi
            nl.TextSize=12 nl.Font=Enum.Font.GothamBold nl.TextXAlignment=Enum.TextXAlignment.Left nl.Parent=row
            local function sb(txt,xo,col,fn)
                local b=Instance.new("TextButton")
                b.Size=UDim2.new(0,32,0,26) b.Position=UDim2.new(1,xo,0.5,-13)
                b.BackgroundColor3=col b.BackgroundTransparency=0.2 b.Text=txt
                b.TextColor3=C.White b.TextSize=10 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0 b.Parent=row
                corner(b,5) stroke(b,col,1) b.MouseButton1Click:Connect(fn)
            end
            sb("Load",-108,C.Blue,function()
                local d=Profiles.load(name) if d then State=d Profiles._current=name
                    SL.Text="v"..VERSION.."  ·  Profile: "..name refresh() end end)
            sb("Save",-72,C.Green,function() Profiles.save(name,State) end)
            sb("Del",-36,C.Red,function()
                local cf=Instance.new("Frame")
                cf.Size=UDim2.new(1,0,0,54) cf.BackgroundColor3=C.Card cf.BackgroundTransparency=0.1
                cf.LayoutOrder=i+0.5 cf.BorderSizePixel=0 cf.Parent=profList corner(cf,6) stroke(cf,C.Red,1.5)
                local ql=Instance.new("TextLabel") ql.Size=UDim2.new(1,0,0,26) ql.BackgroundTransparency=1
                ql.Text='Deletar "'..name..'"?' ql.TextColor3=C.Red ql.TextSize=12 ql.Font=Enum.Font.GothamBold ql.Parent=cf
                local function cfb(t2,xo2,col2,fn2)
                    local b=Instance.new("TextButton") b.Size=UDim2.new(0,62,0,22) b.Position=UDim2.new(0,xo2,0,28)
                    b.BackgroundColor3=col2 b.BackgroundTransparency=0.2 b.Text=t2
                    b.TextColor3=C.White b.TextSize=11 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0 b.Parent=cf corner(b,5) b.MouseButton1Click:Connect(fn2)
                end
                cfb("Sim",8,C.Red,function() Profiles.delete(name) cf:Destroy() refresh() end)
                cfb("Não",76,C.Hover,function() cf:Destroy() end)
            end)
        end
    end
    cb2.MouseButton1Click:Connect(function()
        local n=nb2.Text:match("^%s*(.-)%s*$") if n and #n>0 then Profiles.save(n,State) nb2.Text="" refresh() end
    end)
    refresh()
end

-- ============================================================
-- DRAG
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
-- WINDOW CONTROLS
-- ============================================================
local isOpen=true local isMin=false
local fullH=H local minH=50

local function open()
    isOpen=true isMin=false WIN.Visible=true
    SF.Visible=true TabBar.Visible=true
    tw(WIN,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,W,0,fullH)})
end
local function minimize()
    isMin=true SF.Visible=false TabBar.Visible=false
    tw(WIN,TF,{Size=UDim2.new(0,W,0,minH)})
end
local function restore()
    isMin=false SF.Visible=true TabBar.Visible=true
    tw(WIN,TF,{Size=UDim2.new(0,W,0,fullH)})
end
local function close()
    isOpen=false tw(WIN,TF,{Size=UDim2.new(0,W,0,0)})
    task.delay(0.25,function() WIN.Visible=false end)
end

BMin.MouseButton1Click:Connect(function() if isMin then restore() else minimize() end end)
BClose.MouseButton1Click:Connect(close)
FB.MouseButton1Click:Connect(function()
    if not isOpen then open() elseif isMin then restore() else minimize() end
end)

-- ── Activate Machines tab directly ──
do
    local t=pages["Machines"]
    activeTab="Machines"
    t.page.Visible=true
    t.bar.BackgroundTransparency=0
    t.btn.TextColor3=C.Neon
end

-- Open animation
WIN.Size=UDim2.new(0,W,0,0)
tw(WIN,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,W,0,fullH)})

print("[AuroraHub] v"..VERSION.." carregado!")
