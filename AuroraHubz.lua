--[[  AURORA HUB v0.3.2.2  ]]

local VERSION = "0.3.2.2 fix"
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local LP           = game:GetService("Players").LocalPlayer
local PG           = LP:WaitForChild("PlayerGui")

local function tw(o,t,p) TweenService:Create(o,t,p):Play() end
local TF = TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

local NEON  = Color3.fromRGB(0,210,255)
local BLUE  = Color3.fromRGB(20,80,200)
local BG    = Color3.fromRGB(8,16,32)
local CARD  = Color3.fromRGB(15,28,52)
local GREEN = Color3.fromRGB(0,210,100)
local RED   = Color3.fromRGB(220,50,70)
local WHITE = Color3.fromRGB(255,255,255)
local GRAY  = Color3.fromRGB(80,120,160)
local DGRAY = Color3.fromRGB(30,50,80)

local function mkCorner(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p end
local function mkStroke(p,col,th) local s=Instance.new("UIStroke") s.Color=col or NEON s.Thickness=th or 1.5 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p end
local function mkList(p,gap,dir) local l=Instance.new("UIListLayout") l.SortOrder=Enum.SortOrder.LayoutOrder l.Padding=UDim.new(0,gap or 5) l.FillDirection=dir or Enum.FillDirection.Vertical l.Parent=p return l end
local function mkPad(p,x,y) local u=Instance.new("UIPadding") u.PaddingLeft=UDim.new(0,x) u.PaddingRight=UDim.new(0,x) u.PaddingTop=UDim.new(0,y) u.PaddingBottom=UDim.new(0,y) u.Parent=p end

-- ============================================================
-- STATE
-- ============================================================
local State={
    machines={
        complete  ={enabled=true, colors={{R=0,  G=210,B=100}}},
        completing={enabled=true, colors={{R=255,G=200,B=0  }}},
        incomplete={enabled=true, colors={{R=0,  G=210,B=255}}},
    },
    monsters={}, items={},
}
local function c3(t) return Color3.fromRGB(t.R or 0,t.G or 0,t.B or 0) end

-- ============================================================
-- PROFILES
-- ============================================================
local Profiles={_mem={},_current="Default"}
local function fOk() return type(writefile)=="function" and type(readfile)=="function" end
local function jE(v) local t=type(v)
    if t=="nil" then return "null" elseif t=="boolean" or t=="number" then return tostring(v)
    elseif t=="string" then return'"'..v:gsub('\\','\\\\'):gsub('"','\\"')..'"'
    elseif t=="table" then if #v>0 then local p={} for _,x in ipairs(v) do p[#p+1]=jE(x) end return"["..table.concat(p,",").."]"
        else local p={} for k,x in pairs(v) do p[#p+1]='"'..k..'":'..jE(x) end return"{"..table.concat(p,",").."}" end
    end return"null" end
local function jD(s) local i=1
    local function sk() while i<=#s and s:sub(i,i):match"%s" do i=i+1 end end
    local function ch() sk() return s:sub(i,i) end
    local pv
    local function pS() i=i+1 local r="" while i<=#s do local c=s:sub(i,i) if c=='"' then i=i+1 return r end
        if c=="\\" then i=i+1 c=s:sub(i,i) if c=="n" then r=r.."\n" else r=r..c end else r=r..c end i=i+1 end return r end
    local function pA() i=i+1 local t={} sk() if ch()=="]" then i=i+1 return t end
        while true do t[#t+1]=pv() sk() if ch()=="]" then i=i+1 return t end i=i+1 end end
    local function pO() i=i+1 local t={} sk() if ch()=="}" then i=i+1 return t end
        while true do sk() local k=pS() sk() i=i+1 t[k]=pv() sk() if ch()=="}" then i=i+1 return t end i=i+1 end end
    pv=function() sk() local c=ch()
        if c=='"' then return pS() elseif c=="[" then return pA() elseif c=="{" then return pO()
        elseif c=="t" then i=i+4 return true elseif c=="f" then i=i+5 return false
        elseif c=="n" then i=i+4 return nil
        else local n=s:match("^-?%d+%.?%d*",i) if n then i=i+#n return tonumber(n) end end end
    return pv() end
local FOLDER="AuroraHub/"
local function mkF() if fOk() and type(makefolder)=="function" then pcall(function() if not isfolder(FOLDER) then makefolder(FOLDER) end end) end end
function Profiles.save(n,d) Profiles._mem[n]=d if fOk() then mkF() pcall(writefile,FOLDER..n..".json",jE(d)) end end
function Profiles.load(n) if fOk() then local ok,c=pcall(readfile,FOLDER..n..".json") if ok and c then local ok2,d=pcall(jD,c) if ok2 then return d end end end return Profiles._mem[n] end
function Profiles.delete(n) Profiles._mem[n]=nil if fOk() then pcall(function() if isfile(FOLDER..n..".json") then delfile(FOLDER..n..".json") end end) end end
function Profiles.list() local out={} for k in pairs(Profiles._mem) do out[k]=true end
    if fOk() and type(listfiles)=="function" then local ok,fs=pcall(listfiles,FOLDER) if ok then for _,f in ipairs(fs) do local n=f:match("([^/\\]+)%.json$") if n then out[n]=true end end end end
    local r={} for k in pairs(out) do r[#r+1]=k end table.sort(r) return r end

-- ============================================================
-- ESP — MACHINES
-- FIX: loop reaplicar estado a cada 0.15s → reflete toggle/cor mudados na UI
-- ============================================================
local COL_R=Color3.fromRGB(167,0,0)
local COL_Y=Color3.fromRGB(255,215,130)
local COL_G=Color3.fromRGB(58,165,56)
local function cM(a,b,t) t=t or 28
    return math.abs(a.R*255-b.R*255)<=t and math.abs(a.G*255-b.G*255)<=t and math.abs(a.B*255-b.B*255)<=t end

local mESP={}
local function setupMachine(obj)
    if obj.Name~="BaseMachine" or mESP[obj] then return end
    local light=obj:FindFirstChild("Light",true) if not light then return end
    local part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") if not part then return end

    local hl=Instance.new("Highlight") hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.OutlineColor=WHITE hl.Parent=obj
    local bb=Instance.new("BillboardGui") bb.Adornee=part bb.Size=UDim2.new(0,170,0,26)
    bb.StudsOffset=Vector3.new(0,3,0) bb.AlwaysOnTop=true bb.MaxDistance=500 bb.Parent=obj
    local lbl=Instance.new("TextLabel") lbl.Size=UDim2.fromScale(1,1) lbl.BackgroundTransparency=1
    lbl.TextSize=13 lbl.Font=Enum.Font.GothamBold lbl.TextStrokeTransparency=0 lbl.Parent=bb

    local cur="incomplete"

    -- apply sempre lê State atual → reflete mudanças feitas na UI
    local function apply(s)
        cur=s
        local cfg=State.machines[s]
        local en=cfg.enabled~=false
        hl.Enabled=en bb.Enabled=en
        local col=cfg.colors[1] and c3(cfg.colors[1]) or WHITE
        hl.FillColor=col
        if s=="complete" then lbl.TextColor3=col lbl.Text="✔ Completed"
        elseif s=="completing" then lbl.TextColor3=col lbl.Text="⚙ Completing..."
        else lbl.TextColor3=WHITE end
    end

    local function eval(color)
        if cM(color,COL_G) then apply("complete")
        elseif cM(color,COL_Y) then apply("completing")
        else apply("incomplete") end
    end

    eval(light.Color)
    light:GetPropertyChangedSignal("Color"):Connect(function() eval(light.Color) end)
    mESP[obj]=true

    task.spawn(function()
        while obj.Parent do
            -- atualiza enable e cor continuamente (reflete mudanças da UI)
            local cfg2=State.machines[cur]
            local en=cfg2.enabled~=false
            hl.Enabled=en bb.Enabled=en
            local col2=cfg2.colors[1] and c3(cfg2.colors[1]) or WHITE
            hl.FillColor=col2
            if cur=="incomplete" then
                lbl.TextColor3=WHITE
                local ch=LP.Character
                local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
                if hrp then
                    lbl.Text=("⚙ %d studs"):format(math.floor((hrp.Position-part.Position).Magnitude))
                end
            elseif cur=="complete" then
                lbl.TextColor3=col2 lbl.Text="✔ Completed"
            elseif cur=="completing" then
                lbl.TextColor3=col2 lbl.Text="⚙ Completing..."
            end
            task.wait(0.15)
        end
        mESP[obj]=nil
    end)
end

-- ============================================================
-- ============================================================
-- PLAYER SYSTEMS
-- ============================================================
local RS = game:GetService("ReplicatedStorage")

-- Remove CheckPlayerSpeed em background
task.spawn(function()
    pcall(function()
        local events = RS:WaitForChild("Events", 3)
        if not events then return end
        local check = events:FindFirstChild("CheckPlayerSpeed")
        if check then pcall(function() check:Destroy() end) end
        events.ChildAdded:Connect(function(c)
            if c.Name == "CheckPlayerSpeed" then
                task.wait() pcall(function() c:Destroy() end)
            end
        end)
    end)
end)

-- ============================================================
-- WALKSPEED / RUNSPEED v2 — Aurora Hub
-- Monitoramento contínuo via GetPropertyChangedSignal + loop de
-- segurança a cada 0.25s. Se o jogo reduzir WalkSpeed abaixo do
-- valor configurado enquanto o toggle estiver ativo, restaura
-- imediatamente. Funciona após respawn. Leve e otimizado.
-- ============================================================
local walkSpeedVal = 16
local runSpeedVal  = 32
local walkEnabled  = false
local runEnabled   = false
local baseSpeed    = 16  -- velocidade original capturada na inicialização

-- Conexões ativas (limpas a cada respawn ou toggle off)
local _wsSignalConn   = nil
local _wsRespawnConn  = nil

-- Captura velocidade base real do personagem na inicialização
pcall(function()
    local ch  = LP.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if hum then
        baseSpeed    = hum.WalkSpeed
        walkSpeedVal = baseSpeed
        runSpeedVal  = baseSpeed * 2
    end
end)

-- ── Velocidade alvo atual ─────────────────────────────────────────────────
local function targetSpeed()
    if runEnabled  then return runSpeedVal  end
    if walkEnabled then return walkSpeedVal end
    return nil
end

-- ── Corrige se o jogo reduziu abaixo do configurado ──────────────────────
local function enforceSpeed(hum)
    local tgt = targetSpeed()
    if not tgt then return end
    -- Só age se estiver ABAIXO — nunca reduz velocidade maior
    if hum.WalkSpeed < tgt then
        pcall(function() hum.WalkSpeed = tgt end)
    end
end

-- ── Conecta GetPropertyChangedSignal no Humanoid atual ───────────────────
-- Dispara toda vez que WalkSpeed muda — custo zero entre disparos.
local function hookHumanoidWS(hum)
    if _wsSignalConn then _wsSignalConn:Disconnect() _wsSignalConn = nil end
    _wsSignalConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        enforceSpeed(hum)
    end)
    -- Aplica imediatamente ao conectar
    local tgt = targetSpeed()
    if tgt then pcall(function() hum.WalkSpeed = tgt end) end
end

-- ── Loop de segurança (backup contra scripts que bypassam o signal) ───────
-- 0.25s entre verificações — verifica apenas 1 propriedade, custo mínimo.
local _wsBackupTimer = 0
game:GetService("RunService").Heartbeat:Connect(function(dt)
    _wsBackupTimer = _wsBackupTimer + dt
    if _wsBackupTimer < 0.25 then return end
    _wsBackupTimer = 0
    if not walkEnabled and not runEnabled then return end
    pcall(function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then enforceSpeed(hum) end
    end)
end)

-- ── Reconecta o sinal após respawn ────────────────────────────────────────
local function hookRespawnWS()
    if _wsRespawnConn then _wsRespawnConn:Disconnect() end
    _wsRespawnConn = LP.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        local hum = newChar:FindFirstChildOfClass("Humanoid")
        if hum then
            baseSpeed = hum.WalkSpeed  -- atualiza base após respawn
            if walkEnabled or runEnabled then hookHumanoidWS(hum) end
        end
    end)
end
hookRespawnWS()

-- ── Funções usadas pelos toggles da UI ───────────────────────────────────
local function setHumSpeed(speed)
    pcall(function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = speed end
    end)
end

local function applyWalkSpeed()
    pcall(function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hookHumanoidWS(hum) end
    end)
end

local function disableWalkSpeed()
    if _wsSignalConn then _wsSignalConn:Disconnect() _wsSignalConn = nil end
    pcall(function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = baseSpeed end
    end)
end

-- Intercepta SprintEvent via hookmetamethod (compatível com Delta)
task.spawn(function()
    pcall(function()
        local events = RS:WaitForChild("Events", 5)
        if not events then return end
        local sprintEvent = events:WaitForChild("SprintEvent", 5)
        if not sprintEvent then return end

        -- hookmetamethod é suportado pelo Delta
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and self == sprintEvent then
                local args = {...}
                local isSprinting = args[1] == true
                task.defer(function()
                    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    if isSprinting then
                        -- Começou a correr: aplica runSpeed se ativo, senão enforceSpeed cuida
                        if runEnabled then
                            pcall(function() hum.WalkSpeed = runSpeedVal end)
                        end
                    else
                        -- Parou de correr: volta para walkSpeed ou base
                        if walkEnabled then
                            pcall(function() hum.WalkSpeed = walkSpeedVal end)
                        elseif not runEnabled then
                            pcall(function() hum.WalkSpeed = baseSpeed end)
                        end
                    end
                    -- enforceSpeed garante o mínimo configurado em qualquer caso
                    enforceSpeed(hum)
                end)
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
end)

-- ============================================================
-- TELEPORT TO ELEVATOR (TTE) — Aurora Hub
-- Monitora todas as BaseMachine. Quando 100% estiverem Completed,
-- teleporta o jogador UMA ÚNICA VEZ por rodada.
-- Sem Fly, sem Tween. Teleporte instantâneo.
-- ============================================================
local TTE_ENABLED   = false
local TTE_DEST      = Vector3.new(-746.562, 99.799, 94.962)
local _tteDone      = false   -- trava por rodada
local _tteConn      = nil     -- conexão do loop

-- Detecta início de nova rodada (todas as máquinas voltam ao estado inicial)
-- → reseta a trava automaticamente
local function tteCheckReset()
    -- Se qualquer máquina não estiver Completed, a rodada recomeçou
    local currentRoom = workspace:FindFirstChild("CurrentRoom")
    if not currentRoom then return end
    for _, obj in ipairs(currentRoom:GetDescendants()) do
        if obj.Name == "BaseMachine" or obj:IsA("Model") and obj:FindFirstChild("State") then
            local state = obj:FindFirstChild("State") or obj:FindFirstChild("Completed")
            if state and (state.Value == false or state.Value == 0 or state.Value == "") then
                _tteDone = false  -- nova rodada detectada, libera trava
                return
            end
        end
    end
end

local function tteAllComplete()
    local currentRoom = workspace:FindFirstChild("CurrentRoom")
    if not currentRoom then return false end
    local total, done = 0, 0
    -- Busca por BaseMachine (objetos ou atributos que indiquem máquinas)
    for _, obj in ipairs(currentRoom:GetDescendants()) do
        local isMachine = (obj.Name == "BaseMachine") or
                          (obj:IsA("Model") and (obj:FindFirstChild("BaseMachine") or
                           obj:FindFirstChild("Completed") or obj:FindFirstChild("State")))
        if isMachine then
            total = total + 1
            -- Considera completa se: Completed=true, State=true/1/"Completed"
            local comp = obj:FindFirstChild("Completed") or obj:FindFirstChild("State")
            if comp then
                local v = comp.Value
                if v == true or v == 1 or tostring(v):lower() == "completed" then
                    done = done + 1
                end
            end
        end
    end
    return total > 0 and done >= total
end

local function tteTeleport()
    pcall(function()
        local ch  = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(TTE_DEST) end
    end)
end

local function startTTE()
    if _tteConn then _tteConn:Disconnect() end
    _tteDone = false
    local timer = 0
    _tteConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not TTE_ENABLED then return end
        timer = timer + dt
        if timer < 1.5 then return end  -- verifica a cada 1.5s (muito leve)
        timer = 0
        tteCheckReset()
        if _tteDone then return end
        if tteAllComplete() then
            _tteDone = true
            tteTeleport()
        end
    end)
end

local function stopTTE()
    if _tteConn then _tteConn:Disconnect() _tteConn = nil end
    _tteDone = false
end

-- ============================================================
-- FRONT FLIP & BACK FLIP TOOLS — Aurora Hub
-- Cria Tools na Backpack. Compatível com R6 e R15.
-- Mortal via manipulação de CFrame do HRP por frames.
-- Visível para outros jogadores. Sem matar o personagem.
-- ============================================================
local _frontFlipTool = nil
local _backFlipTool  = nil

-- ── Utilitário: aguarda a Backpack existir (até 5s) ──────────────────────
local function waitForBackpack()
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then return bp end
    local found = nil
    local t = 0
    repeat
        task.wait(0.1)
        t = t + 0.1
        found = LP:FindFirstChildOfClass("Backpack")
    until found or t >= 5
    return found
end

-- ── Executa o flip: dir=1 frente, dir=-1 trás ────────────────────────────
local function doFlip(direction)
    local ch  = LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if hum.Health <= 0 then return end

    -- Impulso para dar altura e profundidade ao flip
    local lv = hrp.CFrame.LookVector
    local bv = Instance.new("LinearVelocity")
    bv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    bv.FreeLength = 0
    bv.PlaneVelocity = Vector2.new(0, 0)
    bv.Velocity = Vector3.new(lv.X * 14 * direction, 30, lv.Z * 14 * direction)
    bv.MaxForce = 8000
    bv.Attachment0 = hrp:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", hrp)
    bv.Parent = hrp

    -- Destrói o impulso após 0.15s
    task.delay(0.15, function() pcall(function() bv:Destroy() end) end)

    -- Rotação de 360° em 20 steps (~0.55s total)
    local STEPS    = 20
    local ROT_STEP = (math.pi * 2 / STEPS) * direction
    local step     = 0
    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        step = step + 1
        pcall(function()
            hrp.CFrame = hrp.CFrame * CFrame.Angles(ROT_STEP, 0, 0)
        end)
        if step >= STEPS then
            conn:Disconnect()
            -- Normaliza para evitar drift de rotação acumulado
            pcall(function()
                local p  = hrp.Position
                local lv2 = hrp.CFrame.LookVector
                hrp.CFrame = CFrame.new(p, p + Vector3.new(lv2.X, 0, lv2.Z))
            end)
        end
    end)
end

-- ── Cria a Tool corretamente ──────────────────────────────────────────────
-- BUG CORRIGIDO: Handle deve ser uma Part (BasePart), não TextLabel.
-- Com RequiresHandle=false o jogo aceita a tool sem handle físico,
-- mas alguns jogos ainda exigem a Part para renderizar na Backpack.
local function createFlipTool(name, direction)
    local tool = Instance.new("Tool")
    tool.Name           = name
    tool.RequiresHandle = false   -- não precisa de handle físico para funcionar
    tool.CanBeDropped   = false
    tool.ToolTip        = name .. " — toque para executar"

    -- Handle como Part vazia invisível (OBRIGATÓRIO para a tool aparecer na Backpack)
    local handle = Instance.new("Part")
    handle.Name          = "Handle"
    handle.Size          = Vector3.new(0.1, 0.1, 0.1)
    handle.Transparency  = 1
    handle.CanCollide    = false
    handle.Anchored      = false
    handle.Massless      = true
    handle.CastShadow    = false
    handle.Parent        = tool

    -- Debounce: impede flip duplo antes do cooldown
    local debounce = false

    -- Activated: compatível com PC e Mobile (toque na tela com tool equipada)
    tool.Activated:Connect(function()
        if debounce then return end
        debounce = true
        doFlip(direction)
        task.wait(1.2)
        debounce = false
    end)

    return tool
end

-- ── Coloca a tool na Backpack de forma segura ─────────────────────────────
local function placeInBackpack(tool)
    task.spawn(function()
        local bp = waitForBackpack()
        if bp then
            -- Remove instância antiga com mesmo nome se existir
            local old = bp:FindFirstChild(tool.Name)
            if old then old:Destroy() end
            tool.Parent = bp
        end
    end)
end

local function enableFrontFlip()
    if _frontFlipTool then pcall(function() _frontFlipTool:Destroy() end) end
    _frontFlipTool = createFlipTool("Front Flip", 1)
    placeInBackpack(_frontFlipTool)
end

local function disableFrontFlip()
    if _frontFlipTool then
        pcall(function() _frontFlipTool:Destroy() end)
        _frontFlipTool = nil
    end
end

local function enableBackFlip()
    if _backFlipTool then pcall(function() _backFlipTool:Destroy() end) end
    _backFlipTool = createFlipTool("Back Flip", -1)
    placeInBackpack(_backFlipTool)
end

local function disableBackFlip()
    if _backFlipTool then
        pcall(function() _backFlipTool:Destroy() end)
        _backFlipTool = nil
    end
end

-- ── Recoloca tools na Backpack após respawn ───────────────────────────────
LP.CharacterAdded:Connect(function(newChar)
    task.wait(0.6)
    if TTE_ENABLED then _tteDone = false end
    if _frontFlipTool then
        pcall(function() _frontFlipTool:Destroy() end)
        _frontFlipTool = createFlipTool("Front Flip", 1)
        placeInBackpack(_frontFlipTool)
    end
    if _backFlipTool then
        pcall(function() _backFlipTool:Destroy() end)
        _backFlipTool = createFlipTool("Back Flip", -1)
        placeInBackpack(_backFlipTool)
    end
end)

-- ============================================================
-- SAFE NOCLIP v3 — Aurora Hub
-- Estratégia:
--   1. Remove colisão das partes do PERSONAGEM (nunca mexe no mapa inteiro).
--   2. Usa CurrentRoom (atualizado automaticamente pelo jogo a cada sala)
--      como fonte para identificar partes de chão/escada pelo nome.
--   3. Raycast descendente confirma a superfície real sob o jogador.
--   4. Partes identificadas como chão/rampa/escada ficam com CanCollide=true
--      no mapa, garantindo que o personagem não caia.
-- Sem Fly · Sem teleporte · Sem alterar gravidade · Sem HumanoidState.
-- Compatível com Delta Executor Mobile.
-- ============================================================
local noclipEnabled    = false
local RS2              = game:GetService("RunService")

-- ── Cache de colisões originais das partes do PERSONAGEM ─────────────────
-- { [BasePart] = bool original }
local charPartCache    = {}

-- ── Conexão de respawn ────────────────────────────────────────────────────
local noclipRespawnConn = nil

-- ── Padrões de nome que indicam superfície pisável ───────────────────────
-- Testado em lowercase; basta um padrão dar match para a parte ser "chão".
local FLOOR_PATTERNS = {
    "floor", "chao", "chão", "ground", "stair", "escada", "ramp",
    "rampa", "step", "degrau", "plat", "base", "walk", "path",
    "corredor", "hall", "tile", "sidewalk", "road", "bridge",
}

local function isFloorName(name)
    local low = name:lower()
    for _, pat in ipairs(FLOOR_PATTERNS) do
        if low:find(pat, 1, true) then return true end
    end
    return false
end

-- ── RaycastParams — exclui o personagem do cast ──────────────────────────
local NC_RAY = RaycastParams.new()
NC_RAY.FilterType = Enum.RaycastFilterType.Exclude

-- ── Raycast: verifica se há chão sob o HRP ───────────────────────────────
-- Retorna a BasePart que está sustentando o personagem, ou nil.
local DOWN   = Vector3.new(0, -1, 0)
local CAST_L = 3.8   -- comprimento do raio (studs); cobre personagem + pequena margem
local OFFSETS = {    -- 4 bordas + centro para detectar escadas/rampas
    Vector3.new( 0,    0,  0   ),
    Vector3.new( 0.45, 0,  0   ),
    Vector3.new(-0.45, 0,  0   ),
    Vector3.new( 0,    0,  0.45),
    Vector3.new( 0,    0, -0.45),
}

local function getGroundPart(hrp, character)
    NC_RAY.FilterDescendantsInstances = { character }
    local origin = hrp.Position
    for _, off in ipairs(OFFSETS) do
        local result = workspace:Raycast(origin + off, DOWN * CAST_L, NC_RAY)
        if result and result.Instance then
            return result.Instance  -- BasePart real sob o jogador
        end
    end
    return nil
end

-- ── Obtém partes do personagem (lista rápida ~15-20 itens) ────────────────
local function getCharParts(character)
    local list = {}
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then list[#list+1] = obj end
    end
    return list
end

-- ── Aplica noclip no personagem ───────────────────────────────────────────
local function applyNoclipToChar(character)
    if not character then return end
    charPartCache = {}
    for _, part in ipairs(getCharParts(character)) do
        charPartCache[part] = part.CanCollide
        pcall(function() part.CanCollide = false end)
    end
end

-- ── Restaura colisões originais do personagem ─────────────────────────────
local function restoreCharCollision()
    for part, original in pairs(charPartCache) do
        pcall(function()
            if part and part.Parent then part.CanCollide = original end
        end)
    end
    charPartCache = {}
end

-- ── Manter noclip após respawn ────────────────────────────────────────────
local function hookRespawn()
    if noclipRespawnConn then noclipRespawnConn:Disconnect() end
    noclipRespawnConn = LP.CharacterAdded:Connect(function(newChar)
        if not noclipEnabled then return end
        task.wait(0.6)
        if noclipEnabled then applyNoclipToChar(newChar) end
    end)
end

-- ── Loop principal ────────────────────────────────────────────────────────
-- Intervalo generoso: 0.1s (~10×/s).
-- Custo por tick: percorre ~15-20 partes do personagem + 5 raycasts curtos.
-- NÃO percorre o Workspace nem o CurrentRoom — apenas o personagem + raycast pontual.
local NC_INTERVAL = 0.1
local _ncT = 0

RS2.Heartbeat:Connect(function(dt)
    if not noclipEnabled then
        if next(charPartCache) ~= nil then restoreCharCollision() end
        return
    end

    _ncT = _ncT + dt
    if _ncT < NC_INTERVAL then return end
    _ncT = 0

    local ch  = LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not ch or not hrp then return end

    -- 1. Descobre qual parte do MAPA está sustentando o jogador agora.
    --    CurrentRoom é gerenciado pelo jogo — sempre reflete a sala atual.
    --    O raycast vai direto na parte real, sem percorrer CurrentRoom.
    local groundPart = getGroundPart(hrp, ch)

    -- 2. Mantém CanCollide=false em todas as partes do personagem.
    --    Se o jogo forçou CanCollide=true em alguma, desfaz.
    for _, part in ipairs(getCharParts(ch)) do
        if part.CanCollide then
            if charPartCache[part] == nil then charPartCache[part] = true end
            pcall(function() part.CanCollide = false end)
        end
    end

    -- 3. Garante que a parte do mapa sob o jogador (chão real) continue
    --    com CanCollide=true — dupla proteção contra queda.
    --    Só age se o nome bate com padrão de chão/escada OU se o raycast
    --    confirmou que é a superfície de suporte.
    if groundPart then
        local ok, _ = pcall(function()
            -- Preserva a colisão da superfície real, independente do nome
            groundPart.CanCollide = true
        end)
        -- Se o nome também indica chão, protege a parte pai (ex: modelo de escada)
        if ok and groundPart.Parent and isFloorName(groundPart.Name) then
            for _, sibling in ipairs(groundPart.Parent:GetChildren()) do
                if sibling:IsA("BasePart") and isFloorName(sibling.Name) then
                    pcall(function() sibling.CanCollide = true end)
                end
            end
        end
    end
end)

-- ── Funções públicas de toggle ────────────────────────────────────────────
local function enableNoclip()
    noclipEnabled = true
    local ch = LP.Character
    if ch then applyNoclipToChar(ch) end
    hookRespawn()
end

local function disableNoclip()
    noclipEnabled = false
    restoreCharCollision()
    if noclipRespawnConn then
        noclipRespawnConn:Disconnect()
        noclipRespawnConn = nil
    end
end

for _,v in ipairs(workspace:GetDescendants()) do setupMachine(v) end
workspace.DescendantAdded:Connect(setupMachine)

-- ============================================================
-- ESP — MONSTERS
-- Lista predefinida de todos os monstros do jogo + detecção automática
-- ============================================================
local tESP={}

-- Lista completa de monstros
local ALL_MONSTERS = {
    "ShrimpoMonster","ToodlesMonster","YattaMonster","FinnMonster","PebbleMonster",
    "RodgerMonster","GoobMonster","ShellyMonster","BoxtenMonster","CosmoMonster",
    "GingerMonster","TeaganMonster","LooeyMonster","SproutMonster","AstroMonster",
    "BrightneyMonster","ConnieMonster","FlutterMonster","PoppyMonster","RudieMonster",
    "ScrapsMonster","TishaMonster","VeeMonster","BobetteMonster","JesterMonster",
    "CoalMonster","RazzleDazzleMonster","DandyMonster","GlitchMonster",
}

local function getMonCfg(n)
    if not State.monsters[n] then State.monsters[n]={enabled=true,colors={{R=255,G=50,B=50}}} end
    return State.monsters[n]
end

local function setupMonster(obj)
    if not obj.Name:match("Monster$") or not obj:IsA("Model") or tESP[obj] then return end
    tESP[obj]=true
    task.spawn(function()
        local part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        local w=0
        while not part and obj.Parent and w<5 do task.wait(0.1) w=w+0.1 part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") end
        if not part or not obj.Parent then tESP[obj]=nil return end
        local cfg=getMonCfg(obj.Name)
        local hl=Instance.new("Highlight") hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        hl.OutlineColor=WHITE hl.FillColor=c3(cfg.colors[1]) hl.Enabled=cfg.enabled hl.Parent=obj
        local bb=Instance.new("BillboardGui") bb.Adornee=part bb.Size=UDim2.new(0,200,0,28)
        bb.StudsOffset=Vector3.new(0,4.5,0) bb.AlwaysOnTop=true bb.MaxDistance=math.huge bb.Enabled=cfg.enabled bb.Parent=obj
        local lbl=Instance.new("TextLabel") lbl.Size=UDim2.fromScale(1,1) lbl.BackgroundTransparency=1
        lbl.TextSize=14 lbl.Font=Enum.Font.GothamBold lbl.TextStrokeTransparency=0
        lbl.TextColor3=c3(cfg.colors[1]) lbl.Text="⚠ "..obj.Name:gsub("Monster$","") lbl.Parent=bb
        tESP[obj]={hl=hl,bb=bb,lbl=lbl}
        local idx=1
        task.spawn(function()
            while obj.Parent do
                -- atualiza enable e cor da UI continuamente
                hl.Enabled=cfg.enabled bb.Enabled=cfg.enabled
                if #cfg.colors>1 then
                    idx=(idx%#cfg.colors)+1
                    local col=c3(cfg.colors[idx])
                    tw(hl,TweenInfo.new(0.7),{FillColor=col})
                    tw(lbl,TweenInfo.new(0.7),{TextColor3=col})
                else
                    local col=cfg.colors[1] and c3(cfg.colors[1]) or RED
                    hl.FillColor=col lbl.TextColor3=col
                end
                task.wait(0.9)
            end
            tESP[obj]=nil
        end)
    end)
end

-- ============================================================
-- ESP — ITEMS
-- FIX: busca SOMENTE dentro de CurrentRoom → Room → pasta Items
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

local function getItemCfg(n)
    local d=IDEFS[n]
    if not State.items[n] then State.items[n]={enabled=true,colors={d and d.color or {R=0,G=210,B=255}}} end
    return State.items[n]
end

local function setupItem(obj)
    -- só aceita se o pai direto (ou avô) for a pasta "Items"
    local parent=obj.Parent
    if not parent or parent.Name~="Items" then return end
    if not(obj:IsA("Model") or obj:IsA("BasePart")) or not IDEFS[obj.Name] or iESP[obj] then return end
    iESP[obj]=true
    local def=IDEFS[obj.Name]
    task.spawn(function()
        local part=(obj:IsA("BasePart") and obj) or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        local w=0
        while not part and obj.Parent and w<5 do task.wait(0.1) w=w+0.1 part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") end
        if not part or not obj.Parent then iESP[obj]=nil return end
        local cfg=getItemCfg(obj.Name)
        local hl=Instance.new("Highlight") hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        hl.OutlineColor=WHITE hl.FillColor=c3(cfg.colors[1]) hl.Enabled=cfg.enabled hl.Parent=obj
        local bb=Instance.new("BillboardGui") bb.Adornee=part bb.Size=UDim2.new(0,170,0,26)
        bb.StudsOffset=Vector3.new(0,2.5,0) bb.AlwaysOnTop=true bb.MaxDistance=math.huge bb.Enabled=cfg.enabled bb.Parent=obj
        local lbl=Instance.new("TextLabel") lbl.Size=UDim2.fromScale(1,1) lbl.BackgroundTransparency=1
        lbl.TextSize=13 lbl.Font=Enum.Font.GothamBold lbl.TextStrokeTransparency=0
        lbl.TextColor3=c3(cfg.colors[1]) lbl.Text=def.icon.." "..def.label lbl.Parent=bb
        iESP[obj]={hl=hl,bb=bb,lbl=lbl}
        local idx=1
        task.spawn(function()
            while obj.Parent do
                hl.Enabled=cfg.enabled bb.Enabled=cfg.enabled
                if #cfg.colors>1 then
                    idx=(idx%#cfg.colors)+1
                    local col=c3(cfg.colors[idx])
                    tw(hl,TweenInfo.new(0.7),{FillColor=col})
                    tw(lbl,TweenInfo.new(0.7),{TextColor3=col})
                else
                    local col=cfg.colors[1] and c3(cfg.colors[1]) or NEON
                    hl.FillColor=col lbl.TextColor3=col
                end
                task.wait(0.9)
            end
            iESP[obj]=nil
        end)
    end)
end

-- Watcher: só olha dentro da pasta Items de cada Room
local function watchItemsFolder(folder)
    for _,obj in ipairs(folder:GetChildren()) do setupItem(obj) end
    folder.ChildAdded:Connect(function(obj) setupItem(obj) end)
end

local function watchRoom(room)
    -- monsters
    for _,d in ipairs(room:GetDescendants()) do setupMonster(d) end
    room.DescendantAdded:Connect(function(d) setupMonster(d) end)
    -- items — apenas pasta Items dentro da room
    local itemsFolder=room:FindFirstChild("Items")
    if itemsFolder then watchItemsFolder(itemsFolder) end
    room.ChildAdded:Connect(function(child)
        if child.Name=="Items" then watchItemsFolder(child) end
    end)
end

local function watchCurrentRoom(cr)
    for _,room in ipairs(cr:GetChildren()) do
        if room:IsA("Model") then watchRoom(room) end
    end
    cr.ChildAdded:Connect(function(room)
        if room:IsA("Model") then
            task.wait(0.1)
            watchRoom(room)
        end
    end)
end

local cr=workspace:FindFirstChild("CurrentRoom")
if cr then watchCurrentRoom(cr)
else
    local wc; wc=workspace.ChildAdded:Connect(function(c)
        if c.Name=="CurrentRoom" then wc:Disconnect() watchCurrentRoom(c) end
    end)
end

-- ============================================================
-- GUI
-- ============================================================
print("[AuroraHub] Iniciando GUI...")
local old=PG:FindFirstChild("AuroraHub") if old then old:Destroy() end
local SG=Instance.new("ScreenGui") SG.Name="AuroraHub" SG.ResetOnSpawn=false
SG.IgnoreGuiInset=true SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling SG.Parent=PG

-- F Button
local FB=Instance.new("TextButton")
FB.Size=UDim2.new(0,50,0,50) FB.Position=UDim2.new(0,10,0.5,-25)
FB.BackgroundColor3=BG FB.Text="F" FB.TextColor3=NEON FB.TextSize=22 FB.Font=Enum.Font.GothamBold
FB.BorderSizePixel=0 FB.ZIndex=20 FB.Parent=SG mkCorner(FB,10) mkStroke(FB,NEON,2)

-- Window
local WIN=Instance.new("Frame")
WIN.Size=UDim2.new(0,450,0,340) WIN.Position=UDim2.new(0.5,-225,0.5,-170)
WIN.BackgroundColor3=BG WIN.BorderSizePixel=0 WIN.ZIndex=10 WIN.Parent=SG
mkCorner(WIN,10) mkStroke(WIN,NEON,2)

-- Title bar
local TB=Instance.new("Frame")
TB.Size=UDim2.new(1,0,0,48) TB.BackgroundColor3=CARD TB.BorderSizePixel=0 TB.ZIndex=11 TB.Parent=WIN
mkCorner(TB,10)
local tbp=Instance.new("Frame") tbp.Size=UDim2.new(1,0,0.5,0) tbp.Position=UDim2.new(0,0,0.5,0)
tbp.BackgroundColor3=CARD tbp.BorderSizePixel=0 tbp.ZIndex=11 tbp.Parent=TB

local titleLbl=Instance.new("TextLabel") titleLbl.Size=UDim2.new(0,180,0,26) titleLbl.Position=UDim2.new(0,12,0,2)
titleLbl.BackgroundTransparency=1 titleLbl.Text="Aurora Hub" titleLbl.TextColor3=NEON
titleLbl.TextSize=16 titleLbl.Font=Enum.Font.GothamBold titleLbl.TextXAlignment=Enum.TextXAlignment.Left
titleLbl.ZIndex=12 titleLbl.Parent=TB

local subLbl=Instance.new("TextLabel") subLbl.Size=UDim2.new(0,200,0,14) subLbl.Position=UDim2.new(0,12,0,30)
subLbl.BackgroundTransparency=1 subLbl.Text="v"..VERSION.."  ·  "..Profiles._current
subLbl.TextColor3=GRAY subLbl.TextSize=10 subLbl.Font=Enum.Font.Gotham
subLbl.TextXAlignment=Enum.TextXAlignment.Left subLbl.ZIndex=12 subLbl.Parent=TB

local function winBtn(icon,xOff,col)
    local b=Instance.new("TextButton") b.Size=UDim2.new(0,30,0,30) b.Position=UDim2.new(1,xOff,0.5,-15)
    b.BackgroundColor3=col b.Text=icon b.TextColor3=WHITE b.TextSize=15 b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0 b.ZIndex=13 b.Parent=TB mkCorner(b,6) return b end
local BMin   = winBtn("─",-68,BLUE)
local BClose = winBtn("✕",-34,RED)  -- posição relativa à direita (UDim2 scale=1)

-- Tab bar
local TABH=40
local TabBar=Instance.new("Frame") TabBar.Size=UDim2.new(1,0,0,TABH) TabBar.Position=UDim2.new(0,0,0,48)
TabBar.BackgroundColor3=CARD TabBar.BackgroundTransparency=0.3 TabBar.BorderSizePixel=0 TabBar.ZIndex=11 TabBar.Parent=WIN
do local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal l.SortOrder=Enum.SortOrder.LayoutOrder l.Parent=TabBar end

-- ScrollingFrame
local SF=Instance.new("ScrollingFrame")
SF.Size=UDim2.new(1,0,0,340-48-TABH) SF.Position=UDim2.new(0,0,0,48+TABH)
SF.BackgroundColor3=BG SF.BackgroundTransparency=0 SF.BorderSizePixel=0
SF.ScrollBarThickness=4 SF.ScrollBarImageColor3=NEON SF.ScrollingDirection=Enum.ScrollingDirection.Y
SF.CanvasSize=UDim2.new(1,0,0,0) SF.AutomaticCanvasSize=Enum.AutomaticSize.Y
SF.ZIndex=11 SF.Parent=WIN
mkList(SF,4) mkPad(SF,8,8)

-- ============================================================
-- TABS
-- ============================================================
local TNAMES={"Machines","Monsters","Items","Profiles","Player","Fun"}
local TICONS={"⚙","👾","🎒","👤","🏃","🎉"}
local pages={} local activeTab=nil

for i,name in ipairs(TNAMES) do
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1/#TNAMES,0,1,0) btn.BackgroundTransparency=1 btn.BorderSizePixel=0
    btn.Text=TICONS[i] btn.TextSize=20 btn.Font=Enum.Font.GothamBold
    btn.TextColor3=GRAY btn.ZIndex=12 btn.LayoutOrder=i btn.Parent=TabBar

    local ul=Instance.new("Frame") ul.Size=UDim2.new(0.7,0,0,2) ul.Position=UDim2.new(0.15,0,1,-2)
    ul.BackgroundColor3=NEON ul.BorderSizePixel=0 ul.BackgroundTransparency=1 ul.ZIndex=13 ul.Parent=btn

    local page=Instance.new("Frame")
    page.Size=UDim2.new(1,0,0,0) page.AutomaticSize=Enum.AutomaticSize.Y
    page.BackgroundTransparency=1 page.BorderSizePixel=0
    page.Visible=false page.LayoutOrder=i page.ZIndex=12 page.Parent=SF
    mkList(page,4)

    pages[name]={page=page,btn=btn,ul=ul}

    btn.MouseButton1Click:Connect(function()
        if activeTab==name then return end
        if activeTab and pages[activeTab] then
            pages[activeTab].page.Visible=false
            pages[activeTab].ul.BackgroundTransparency=1
            pages[activeTab].btn.TextColor3=GRAY
        end
        activeTab=name page.Visible=true
        ul.BackgroundTransparency=0 btn.TextColor3=NEON
        SF.CanvasPosition=Vector2.new(0,0)
    end)
end

-- ============================================================
-- WIDGETS
-- ============================================================
local function secHdr(parent,text,order)
    local f=Instance.new("Frame") f.Size=UDim2.new(1,0,0,30) f.BackgroundColor3=CARD
    f.BorderSizePixel=0 f.LayoutOrder=order f.Parent=parent mkCorner(f,6) mkStroke(f,NEON,1.5)
    local l=Instance.new("TextLabel") l.Size=UDim2.new(1,-10,1,0) l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1 l.Text=text l.TextColor3=NEON l.TextSize=13 l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left l.ZIndex=13 l.Parent=f return f end

local function divider(parent,order)
    local d=Instance.new("Frame") d.Size=UDim2.new(1,0,0,1) d.BackgroundColor3=DGRAY
    d.BorderSizePixel=0 d.LayoutOrder=order d.Parent=parent end

local function toggleRow(parent,text,init,order,cb)
    local row=Instance.new("Frame") row.Size=UDim2.new(1,0,0,38) row.BackgroundColor3=CARD
    row.BackgroundTransparency=0.2 row.BorderSizePixel=0 row.LayoutOrder=order row.Parent=parent mkCorner(row,6)
    local lbl=Instance.new("TextLabel") lbl.Size=UDim2.new(1,-58,1,0) lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1 lbl.Text=text lbl.TextColor3=WHITE lbl.TextSize=13 lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Parent=row
    local pill=Instance.new("Frame") pill.Size=UDim2.new(0,42,0,22) pill.Position=UDim2.new(1,-52,0.5,-11)
    pill.BackgroundColor3=init and NEON or DGRAY pill.BorderSizePixel=0 pill.Parent=row mkCorner(pill,11)
    local knob=Instance.new("Frame") knob.Size=UDim2.new(0,16,0,16) knob.BackgroundColor3=WHITE
    knob.BorderSizePixel=0 knob.Position=init and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    knob.Parent=pill mkCorner(knob,8)
    local state=init
    local hit=Instance.new("TextButton") hit.Size=UDim2.fromScale(1,1) hit.BackgroundTransparency=1 hit.Text="" hit.ZIndex=14 hit.Parent=row
    hit.MouseButton1Click:Connect(function()
        state=not state
        tw(pill,TF,{BackgroundColor3=state and NEON or DGRAY})
        tw(knob,TF,{Position=state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)})
        if cb then cb(state) end
    end) end

local function colorWidget(parent,initColors,order,cb)
    local colors={} for _,c in ipairs(initColors) do colors[#colors+1]={R=c.R,G=c.G,B=c.B} end
    local wrap=Instance.new("Frame") wrap.Size=UDim2.new(1,0,0,0) wrap.AutomaticSize=Enum.AutomaticSize.Y
    wrap.BackgroundColor3=CARD wrap.BackgroundTransparency=0.3 wrap.BorderSizePixel=0
    wrap.LayoutOrder=order wrap.Parent=parent mkCorner(wrap,6) mkStroke(wrap,DGRAY,1)
    local inner=Instance.new("Frame") inner.Size=UDim2.new(1,0,0,0) inner.AutomaticSize=Enum.AutomaticSize.Y
    inner.BackgroundTransparency=1 inner.Parent=wrap mkList(inner,4) mkPad(inner,8,6)
    local lh=Instance.new("TextLabel") lh.Size=UDim2.new(1,0,0,16) lh.BackgroundTransparency=1
    lh.Text="CORES" lh.TextColor3=GRAY lh.TextSize=10 lh.Font=Enum.Font.GothamBold
    lh.TextXAlignment=Enum.TextXAlignment.Left lh.LayoutOrder=0 lh.Parent=inner
    local rows={} local addB
    local function rebuild()
        for _,r in ipairs(rows) do r:Destroy() end rows={}
        for i,col in ipairs(colors) do
            local ii=i
            local rf=Instance.new("Frame") rf.Size=UDim2.new(1,0,0,32) rf.BackgroundTransparency=1 rf.LayoutOrder=i rf.Parent=inner
            local pv=Instance.new("Frame") pv.Size=UDim2.new(0,18,0,18) pv.Position=UDim2.new(0,0,0.5,-9)
            pv.BackgroundColor3=c3(col) pv.BorderSizePixel=0 pv.Parent=rf mkCorner(pv,4) mkStroke(pv,NEON,1)
            for j,ch in ipairs({"R","G","B"}) do
                local xo=(j-1)*72+24
                local ff=Instance.new("Frame") ff.Size=UDim2.new(0,64,0,26) ff.Position=UDim2.new(0,xo,0.5,-13)
                ff.BackgroundColor3=DGRAY ff.BorderSizePixel=0 ff.Parent=rf mkCorner(ff,5) mkStroke(ff,NEON,1)
                local pl=Instance.new("TextLabel") pl.Size=UDim2.new(0,14,1,0) pl.BackgroundTransparency=1
                pl.Text=ch pl.TextColor3=NEON pl.TextSize=11 pl.Font=Enum.Font.GothamBold pl.Parent=ff
                local tb=Instance.new("TextBox") tb.Size=UDim2.new(1,-15,1,0) tb.Position=UDim2.new(0,15,0,0)
                tb.BackgroundTransparency=1 tb.Text=tostring(col[ch]) tb.TextColor3=WHITE tb.TextSize=12
                tb.Font=Enum.Font.Gotham tb.ClearTextOnFocus=false tb.Parent=ff
                tb.FocusLost:Connect(function()
                    local v=tonumber(tb.Text) if v then
                        v=math.clamp(math.floor(v),0,255) colors[ii][ch]=v tb.Text=tostring(v)
                        pv.BackgroundColor3=c3(colors[ii]) if cb then cb(colors) end
                    else tb.Text=tostring(colors[ii][ch]) end end)
            end
            if #colors>1 then
                local rb=Instance.new("TextButton") rb.Size=UDim2.new(0,24,0,24) rb.Position=UDim2.new(1,-24,0.5,-12)
                rb.BackgroundColor3=RED rb.Text="✕" rb.TextColor3=WHITE rb.TextSize=12 rb.Font=Enum.Font.GothamBold
                rb.BorderSizePixel=0 rb.Parent=rf mkCorner(rb,5)
                rb.MouseButton1Click:Connect(function() table.remove(colors,ii) rebuild() if cb then cb(colors) end end) end
            rows[#rows+1]=rf end
        if addB then addB.LayoutOrder=#colors+2 end end
    addB=Instance.new("TextButton") addB.Size=UDim2.new(1,0,0,28) addB.BackgroundColor3=DGRAY
    addB.Text="＋  Add Color" addB.TextColor3=NEON addB.TextSize=12 addB.Font=Enum.Font.GothamBold
    addB.BorderSizePixel=0 addB.LayoutOrder=999 addB.Parent=inner mkCorner(addB,5) mkStroke(addB,NEON,1)
    addB.MouseButton1Click:Connect(function() colors[#colors+1]={R=0,G=210,B=255} rebuild() if cb then cb(colors) end end)
    rebuild() return wrap end

-- ============================================================
-- POPULATE PAGES
-- ============================================================

-- MACHINES
do
    local pg=pages["Machines"].page local o=0
    local function sec(key,title)
        local cfg=State.machines[key]
        o=o+1 secHdr(pg,title,o)
        o=o+1 toggleRow(pg,"Ativar ESP",cfg.enabled,o,function(v) cfg.enabled=v end)
        o=o+1 colorWidget(pg,cfg.colors,o,function(cols) cfg.colors=cols end)
        o=o+1 divider(pg,o)
    end
    sec("complete",  "✔  Máquina Completa")
    sec("completing","⚙  Máquina Completando")
    sec("incomplete","⚙  Máquina Incompleta")
end

-- MONSTERS — lista predefinida + detecção automática
local monAdded={}
local function addMonRow(name)
    if monAdded[name] then return end
    local count=0 for _ in pairs(monAdded) do count=count+1 end
    monAdded[name]=true
    local pg=pages["Monsters"].page
    local o=count*4
    local dn=name:gsub("Monster$","")
    local cfg=getMonCfg(name)
    secHdr(pg,"⚠  "..dn,o+1)
    toggleRow(pg,"Ativar ESP",cfg.enabled,o+2,function(v) cfg.enabled=v end)
    colorWidget(pg,cfg.colors,o+3,function(cols) cfg.colors=cols end)
    divider(pg,o+4)
end

-- Adiciona lista predefinida imediatamente na UI
for _,name in ipairs(ALL_MONSTERS) do
    getMonCfg(name) -- inicializa config
    addMonRow(name)
end

-- Detecção automática de novos monstros não listados
local function onMon(obj)
    if obj.Name:match("Monster$") and obj:IsA("Model") then
        setupMonster(obj)
        addMonRow(obj.Name) -- adiciona na UI se ainda não tiver
    end
end
local crM=workspace:FindFirstChild("CurrentRoom")
if crM then for _,d in ipairs(crM:GetDescendants()) do onMon(d) end crM.DescendantAdded:Connect(onMon) end
workspace.ChildAdded:Connect(function(c) if c.Name=="CurrentRoom" then c.DescendantAdded:Connect(onMon) end end)

-- ITEMS
do
    local pg=pages["Items"].page local o=0
    for name,def in pairs(IDEFS) do
        local cfg=getItemCfg(name)
        o=o+1 secHdr(pg,def.icon.."  "..name,o)
        o=o+1 toggleRow(pg,"Ativar ESP",cfg.enabled,o,function(v) cfg.enabled=v end)
        o=o+1 colorWidget(pg,cfg.colors,o,function(cols) cfg.colors=cols end)
        o=o+1 divider(pg,o)
    end
end

-- PROFILES
local profList
do
    local pg=pages["Profiles"].page local o=0
    o=o+1 secHdr(pg,"👤  Perfis",o)
    local inp=Instance.new("Frame") inp.Size=UDim2.new(1,0,0,40) inp.BackgroundColor3=CARD
    inp.BackgroundTransparency=0.2 inp.BorderSizePixel=0 inp.LayoutOrder=o+1 inp.Parent=pg mkCorner(inp,6) mkStroke(inp,DGRAY,1)
    local nb=Instance.new("TextBox") nb.Size=UDim2.new(1,-88,1,-10) nb.Position=UDim2.new(0,8,0,5)
    nb.BackgroundColor3=DGRAY nb.PlaceholderText="Nome do perfil..." nb.PlaceholderColor3=GRAY nb.Text=""
    nb.TextColor3=WHITE nb.TextSize=12 nb.Font=Enum.Font.Gotham nb.BorderSizePixel=0 nb.ClearTextOnFocus=false
    nb.Parent=inp mkCorner(nb,5) mkStroke(nb,NEON,1)
    local cb2=Instance.new("TextButton") cb2.Size=UDim2.new(0,74,1,-10) cb2.Position=UDim2.new(1,-78,0,5)
    cb2.BackgroundColor3=BLUE cb2.Text="＋ Criar" cb2.TextColor3=WHITE cb2.TextSize=11 cb2.Font=Enum.Font.GothamBold
    cb2.BorderSizePixel=0 cb2.Parent=inp mkCorner(cb2,5) mkStroke(cb2,NEON,1)
    o=o+2 divider(pg,o)
    profList=Instance.new("Frame") profList.Size=UDim2.new(1,0,0,0) profList.AutomaticSize=Enum.AutomaticSize.Y
    profList.BackgroundTransparency=1 profList.LayoutOrder=o+1 profList.Parent=pg mkList(profList,4)
    local function refresh()
        for _,c in ipairs(profList:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
        local names=Profiles.list()
        if #names==0 then
            local e=Instance.new("TextLabel") e.Size=UDim2.new(1,0,0,36) e.BackgroundTransparency=1
            e.Text="Nenhum perfil ainda." e.TextColor3=GRAY e.TextSize=12 e.Font=Enum.Font.Gotham e.LayoutOrder=1 e.Parent=profList return end
        for i,name in ipairs(names) do
            local row=Instance.new("Frame") row.Size=UDim2.new(1,0,0,42) row.BackgroundColor3=CARD
            row.BackgroundTransparency=name==Profiles._current and 0 or 0.3 row.BorderSizePixel=0 row.LayoutOrder=i row.Parent=profList mkCorner(row,6)
            if name==Profiles._current then mkStroke(row,NEON,1.5) else mkStroke(row,DGRAY,1) end
            local nl=Instance.new("TextLabel") nl.Size=UDim2.new(1,-116,1,0) nl.Position=UDim2.new(0,10,0,0) nl.BackgroundTransparency=1
            nl.Text=(name==Profiles._current and "▶ " or "")..name nl.TextColor3=name==Profiles._current and NEON or WHITE
            nl.TextSize=12 nl.Font=Enum.Font.GothamBold nl.TextXAlignment=Enum.TextXAlignment.Left nl.Parent=row
            local function sb(txt,xo,col,fn)
                local b=Instance.new("TextButton") b.Size=UDim2.new(0,34,0,28) b.Position=UDim2.new(1,xo,0.5,-14)
                b.BackgroundColor3=col b.Text=txt b.TextColor3=WHITE b.TextSize=10 b.Font=Enum.Font.GothamBold
                b.BorderSizePixel=0 b.Parent=row mkCorner(b,5) b.MouseButton1Click:Connect(fn) end
            sb("Load",-112,BLUE,function()
                local d=Profiles.load(name)
                if d then
                    -- copiar campos sem quebrar referência do State (closures de ESP usam State)
                    if d.machines then
                        for k,v in pairs(d.machines) do State.machines[k]=v end
                    end
                    if d.monsters then State.monsters=d.monsters end
                    if d.items then State.items=d.items end
                    Profiles._current=name
                    subLbl.Text="v"..VERSION.."  ·  "..name
                    refresh()
                end
            end)
            sb("Save",-74,GREEN,function() Profiles.save(name,State) end)
            sb("Del",-36,RED,function()
                local cf=Instance.new("Frame") cf.Size=UDim2.new(1,0,0,56) cf.BackgroundColor3=CARD cf.BorderSizePixel=0 cf.LayoutOrder=i+0.5 cf.Parent=profList mkCorner(cf,6) mkStroke(cf,RED,1.5)
                local ql=Instance.new("TextLabel") ql.Size=UDim2.new(1,0,0,28) ql.BackgroundTransparency=1 ql.Text='Deletar "'..name..'"?' ql.TextColor3=RED ql.TextSize=12 ql.Font=Enum.Font.GothamBold ql.Parent=cf
                local function cfb(t2,xo2,col2,fn2)
                    local b=Instance.new("TextButton") b.Size=UDim2.new(0,64,0,24) b.Position=UDim2.new(0,xo2,0,28)
                    b.BackgroundColor3=col2 b.Text=t2 b.TextColor3=WHITE b.TextSize=11 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0 b.Parent=cf mkCorner(b,5) b.MouseButton1Click:Connect(fn2) end
                cfb("Sim",8,RED,function() Profiles.delete(name) cf:Destroy() refresh() end)
                cfb("Não",78,DGRAY,function() cf:Destroy() end) end) end end
    cb2.MouseButton1Click:Connect(function()
        local n=nb.Text:match("^%s*(.-)%s*$") if n and #n>0 then Profiles.save(n,State) nb.Text="" refresh() end end)
    refresh()
end

-- ============================================================
-- POPULATE — PLAYER PAGE
-- ============================================================
do
    local pg=pages["Player"].page local o=0

    -- ── WalkSpeed ──
    o=o+1 secHdr(pg,"🚶  Walk Speed",o)

    local wsRow=Instance.new("Frame") wsRow.Size=UDim2.new(1,0,0,38) wsRow.BackgroundColor3=CARD
    wsRow.BackgroundTransparency=0.2 wsRow.BorderSizePixel=0 wsRow.LayoutOrder=o+1 wsRow.Parent=pg mkCorner(wsRow,6)
    local wsLbl=Instance.new("TextLabel") wsLbl.Size=UDim2.new(0,100,1,0) wsLbl.Position=UDim2.new(0,10,0,0)
    wsLbl.BackgroundTransparency=1 wsLbl.Text="Speed valor:" wsLbl.TextColor3=WHITE wsLbl.TextSize=12
    wsLbl.Font=Enum.Font.Gotham wsLbl.TextXAlignment=Enum.TextXAlignment.Left wsLbl.Parent=wsRow
    local wsBox=Instance.new("TextBox") wsBox.Size=UDim2.new(0,70,0,26) wsBox.Position=UDim2.new(0,110,0.5,-13)
    wsBox.BackgroundColor3=DGRAY wsBox.Text=tostring(walkSpeedVal) wsBox.TextColor3=WHITE
    wsBox.TextSize=12 wsBox.Font=Enum.Font.Gotham wsBox.ClearTextOnFocus=false wsBox.BorderSizePixel=0 wsBox.Parent=wsRow
    mkCorner(wsBox,5) mkStroke(wsBox,NEON,1)
    wsBox.FocusLost:Connect(function()
        local v=tonumber(wsBox.Text) if v then walkSpeedVal=math.clamp(math.floor(v),1,500) wsBox.Text=tostring(walkSpeedVal)
        else wsBox.Text=tostring(walkSpeedVal) end end)

    o=o+2 toggleRow(pg,"Walk Speed",walkEnabled,o,function(v)
        walkEnabled=v
        if v then applyWalkSpeed() else disableWalkSpeed() end
    end)
    o=o+1 divider(pg,o)

    -- ── RunSpeed ──
    o=o+1 secHdr(pg,"🏃  Run Speed",o)

    local rsRow=Instance.new("Frame") rsRow.Size=UDim2.new(1,0,0,38) rsRow.BackgroundColor3=CARD
    rsRow.BackgroundTransparency=0.2 rsRow.BorderSizePixel=0 rsRow.LayoutOrder=o+1 rsRow.Parent=pg mkCorner(rsRow,6)
    local rsLbl=Instance.new("TextLabel") rsLbl.Size=UDim2.new(0,100,1,0) rsLbl.Position=UDim2.new(0,10,0,0)
    rsLbl.BackgroundTransparency=1 rsLbl.Text="Speed valor:" rsLbl.TextColor3=WHITE rsLbl.TextSize=12
    rsLbl.Font=Enum.Font.Gotham rsLbl.TextXAlignment=Enum.TextXAlignment.Left rsLbl.Parent=rsRow
    local rsBox=Instance.new("TextBox") rsBox.Size=UDim2.new(0,70,0,26) rsBox.Position=UDim2.new(0,110,0.5,-13)
    rsBox.BackgroundColor3=DGRAY rsBox.Text=tostring(runSpeedVal) rsBox.TextColor3=WHITE
    rsBox.TextSize=12 rsBox.Font=Enum.Font.Gotham rsBox.ClearTextOnFocus=false rsBox.BorderSizePixel=0 rsBox.Parent=rsRow
    mkCorner(rsBox,5) mkStroke(rsBox,NEON,1)
    rsBox.FocusLost:Connect(function()
        local v=tonumber(rsBox.Text) if v then runSpeedVal=math.clamp(math.floor(v),1,500) rsBox.Text=tostring(runSpeedVal)
        else rsBox.Text=tostring(runSpeedVal) end end)

    o=o+2 toggleRow(pg,"Ativar Run Speed",runEnabled,o,function(v) runEnabled=v end)
    o=o+1 divider(pg,o)

    -- ── SafeNoclip ──
    o=o+1 secHdr(pg,"👻  Safe Noclip",o)
    local ncDesc=Instance.new("TextLabel") ncDesc.Size=UDim2.new(1,0,0,44) ncDesc.BackgroundTransparency=1
    ncDesc.Text="Atravessa paredes, portas e obstáculos laterais.\nContinua andando normalmente sobre chão e escadas.\nSem fly · Sem teleporte · Sem alterar gravidade."
    ncDesc.TextColor3=GRAY ncDesc.TextSize=10 ncDesc.Font=Enum.Font.Gotham
    ncDesc.TextWrapped=true ncDesc.LayoutOrder=o+1 ncDesc.Parent=pg
    o=o+2 toggleRow(pg,"Safe Noclip",false,o,function(v)
        if v then enableNoclip() else disableNoclip() end
    end)
    o=o+1 divider(pg,o)

    -- ── Teleport To Elevator ──
    o=o+1 secHdr(pg,"🛗  Teleport To Elevator",o)
    local tteDesc=Instance.new("TextLabel") tteDesc.Size=UDim2.new(1,0,0,44) tteDesc.BackgroundTransparency=1
    tteDesc.Text="Teleporta ao elevador quando 100% das máquinas estiverem\ncompletas. Uma vez por rodada. Resetado automaticamente."
    tteDesc.TextColor3=GRAY tteDesc.TextSize=10 tteDesc.Font=Enum.Font.Gotham
    tteDesc.TextWrapped=true tteDesc.LayoutOrder=o+1 tteDesc.Parent=pg
    o=o+2 toggleRow(pg,"Teleport To Elevator",false,o,function(v)
        TTE_ENABLED=v
        if v then startTTE() else stopTTE() end
    end)
    o=o+1 divider(pg,o)
end


-- ============================================================
-- POPULATE — FUN PAGE
-- ============================================================
do
    local pg=pages["Fun"].page local o=0

    -- ── Front Flip ──
    o=o+1 secHdr(pg,"🔄  Front Flip",o)
    local ffDesc=Instance.new("TextLabel") ffDesc.Size=UDim2.new(1,0,0,44) ffDesc.BackgroundTransparency=1
    ffDesc.Text="Adiciona uma Tool \"Front Flip\" à Backpack.\nEquipe e clique para executar um mortal para frente.\nCompatível com R6 e R15."
    ffDesc.TextColor3=GRAY ffDesc.TextSize=10 ffDesc.Font=Enum.Font.Gotham
    ffDesc.TextWrapped=true ffDesc.LayoutOrder=o+1 ffDesc.Parent=pg
    o=o+2 toggleRow(pg,"Front Flip Tool",false,o,function(v)
        if v then enableFrontFlip() else disableFrontFlip() end
    end)
    o=o+1 divider(pg,o)

    -- ── Back Flip ──
    o=o+1 secHdr(pg,"🔃  Back Flip",o)
    local bfDesc=Instance.new("TextLabel") bfDesc.Size=UDim2.new(1,0,0,44) bfDesc.BackgroundTransparency=1
    bfDesc.Text="Adiciona uma Tool \"Back Flip\" à Backpack.\nEquipe e clique para executar um mortal para trás.\nCompatível com R6 e R15."
    bfDesc.TextColor3=GRAY bfDesc.TextSize=10 bfDesc.Font=Enum.Font.Gotham
    bfDesc.TextWrapped=true bfDesc.LayoutOrder=o+1 bfDesc.Parent=pg
    o=o+2 toggleRow(pg,"Back Flip Tool",false,o,function(v)
        if v then enableBackFlip() else disableBackFlip() end
    end)
    o=o+1 divider(pg,o)
end

-- ============================================================
-- DRAG
-- ============================================================
do
    local drag,ds,sp=false,nil,nil
    TB.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true ds=inp.Position sp=WIN.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then drag=false end end) end end)
    UIS.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds WIN.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)
end

-- ============================================================
-- WINDOW CONTROLS
-- FIX: F fecha/abre (toggle visibilidade), ─ minimiza/restaura
-- ============================================================
local isOpen=true
local isMin=false

BMin.MouseButton1Click:Connect(function()
    if isMin then
        isMin=false TabBar.Visible=true SF.Visible=true
        tw(WIN,TF,{Size=UDim2.new(0,450,0,340)})
    else
        isMin=true TabBar.Visible=false SF.Visible=false
        tw(WIN,TF,{Size=UDim2.new(0,450,0,48)})
    end
end)

BClose.MouseButton1Click:Connect(function()
    isOpen=false isMin=false
    tw(WIN,TF,{Size=UDim2.new(0,450,0,0)})
    task.delay(0.25,function() WIN.Visible=false end)
end)

-- FIX: F abre se fechado, fecha se aberto
FB.MouseButton1Click:Connect(function()
    if not isOpen then
        -- abrir
        isOpen=true isMin=false
        WIN.Visible=true TabBar.Visible=true SF.Visible=true
        tw(WIN,TF,{Size=UDim2.new(0,450,0,340)})
    else
        -- fechar
        isOpen=false isMin=false
        tw(WIN,TF,{Size=UDim2.new(0,450,0,0)})
        task.delay(0.25,function() WIN.Visible=false end)
    end
end)

-- Ativa aba Machines diretamente
activeTab="Machines"
pages["Machines"].page.Visible=true
pages["Machines"].ul.BackgroundTransparency=0
pages["Machines"].btn.TextColor3=NEON

print("[AuroraHub] v"..VERSION.." carregado com sucesso!")
