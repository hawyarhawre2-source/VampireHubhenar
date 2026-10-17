--[[
 VAMPIRE HUB V3 | POWER CONTROL CENTER
 Optional client-side dashboard. No external network requests or game remotes.
 Hotkeys: F8 dashboard, F7 HUD, F9 restore visual settings + hide dashboard.
]]
local function VH3_Start()
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local TweenService=game:GetService("TweenService")
    local Lighting=game:GetService("Lighting")
    local Stats=game:GetService("Stats")
    local HttpService=game:GetService("HttpService")
    local player=Players.LocalPlayer
    if not player then return end
    local pg=player:WaitForChild("PlayerGui", 20)
    if not pg then return end
    if _G.VH3_ControlCenter and _G.VH3_ControlCenter.Cleanup then
        pcall(_G.VH3_ControlCenter.Cleanup)
    end
    local alive=true
    local connections={}
    local originals={}
    local watched={}
    local gui=Instance.new("ScreenGui")
    gui.Name="VH3_ControlCenter"
    gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=false
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder=9900
    gui.Parent=pg
    local configs={crimson=Color3.fromRGB(230,53,80),violet=Color3.fromRGB(155,96,255),cyan=Color3.fromRGB(53,205,231)}
    local settings={theme="crimson",hud=true,lowFX=false,shadows=false,compact=false}
    local cfgFile="VampireHubV3_Settings.json"
    pcall(function()
        if type(readfile)=="function" then
            local data=HttpService:JSONDecode(readfile(cfgFile))
            if type(data)=="table" then
                for k,v in pairs(settings) do
                    if type(data[k])==type(v) then settings[k]=data[k] end
                end
            end
        end
    end)
    if not configs[settings.theme] then settings.theme="crimson" end
    local function save()
        pcall(function()
            if type(writefile)=="function" then writefile(cfgFile,HttpService:JSONEncode(settings)) end
        end)
    end
    local function conn(c) table.insert(connections,c) return c end
    local function make(kind,parent,props)
        local ob=Instance.new(kind)
        for k,v in pairs(props or {}) do ob[k]=v end
        ob.Parent=parent
        return ob
    end
    local function rounded(item,r)
        make("UICorner",item,{CornerRadius=UDim.new(0,r or 12)})
    end
    local function stroke(item,color)
        return make("UIStroke",item,{Color=color,Thickness=1,Transparency=.35})
    end
    local function accent() return configs[settings.theme] end
    local panel=make("Frame",gui,{Name="Panel",Size=UDim2.fromOffset(360,365),Position=UDim2.new(.5,-180,.5,-182),BackgroundColor3=Color3.fromRGB(15,17,24),BorderSizePixel=0,Active=true})
    rounded(panel,14)
    local panelStroke=stroke(panel,accent())
    local gradient=make("UIGradient",panel,{Color=ColorSequence.new(Color3.fromRGB(25,27,37),Color3.fromRGB(10,12,18)),Rotation=90})
    local header=make("Frame",panel,{BackgroundTransparency=1,Size=UDim2.new(1,-30,0,65),Position=UDim2.fromOffset(15,10),Active=true})
    make("TextLabel",header,{Text="VAMPIRE HUB  |  V3",Font=Enum.Font.GothamBold,TextSize=20,TextColor3=Color3.fromRGB(245,246,250),TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,Size=UDim2.new(1,0,0,29)})
    make("TextLabel",header,{Text="POWER CONTROL CENTER  •  CLIENT TOOLS",Font=Enum.Font.Gotham,TextSize=10,TextColor3=Color3.fromRGB(155,158,171),TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,Position=UDim2.fromOffset(0,28),Size=UDim2.new(1,0,0,22)})
    local status=make("TextLabel",panel,{Text="Starting diagnostics…",Font=Enum.Font.Code,TextSize=12,TextColor3=Color3.fromRGB(213,219,230),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,BackgroundColor3=Color3.fromRGB(27,30,39),Size=UDim2.new(1,-30,0,92),Position=UDim2.fromOffset(15,76)})
    rounded(status,8)
    local hud=make("TextLabel",gui,{Name="MiniHUD",BackgroundColor3=Color3.fromRGB(15,17,24),BorderSizePixel=0,TextColor3=Color3.fromRGB(243,243,245),Font=Enum.Font.Code,TextSize=12,Text="VH3 | loading",Position=UDim2.new(0,14,0,80),Size=UDim2.fromOffset(238,32),Visible=settings.hud,Active=true})
    rounded(hud,7)
    local hudStroke=stroke(hud,accent())
    local buttons={}
    local function button(text,x,y,w,callback)
        local b=make("TextButton",panel,{Text=text,Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=Color3.fromRGB(236,238,241),BackgroundColor3=Color3.fromRGB(37,40,52),AutoButtonColor=true,BorderSizePixel=0,Size=UDim2.fromOffset(w,36),Position=UDim2.fromOffset(x,y)})
        rounded(b,7)
        conn(b.Activated:Connect(callback))
        table.insert(buttons,b)
        return b
    end
    local visualOriginal={}
    local function saveVisual(ob,prop)
        local item=visualOriginal[ob]
        if not item then item={} visualOriginal[ob]=item end
        if item[prop]==nil then
            local ok,val=pcall(function() return ob[prop] end)
            if ok then item[prop]=val end
        end
    end
    local function restoreVisual()
        for ob,props in pairs(visualOriginal) do
            pcall(function()
                if ob.Parent then
                    for prop,val in pairs(props) do ob[prop]=val end
                end
            end)
        end
        table.clear(visualOriginal)
    end
    local function reduceEffect(ob)
        if ob:IsA("ParticleEmitter") or ob:IsA("Trail") or ob:IsA("Beam") or ob:IsA("Fire") or ob:IsA("Smoke") or ob:IsA("Sparkles") then
            saveVisual(ob,"Enabled")
            pcall(function() ob.Enabled=false end)
        elseif ob:IsA("PostEffect") then
            saveVisual(ob,"Enabled")
            pcall(function() ob.Enabled=false end)
        end
    end
    local function applyVisuals()
        restoreVisual()
        if settings.lowFX then
            for _,ob in ipairs(workspace:GetDescendants()) do reduceEffect(ob) end
            for _,ob in ipairs(Lighting:GetDescendants()) do reduceEffect(ob) end
        end
        if settings.shadows then
            saveVisual(Lighting,"GlobalShadows")
            Lighting.GlobalShadows=false
        end
    end
    local lowButton,shadowButton,hudButton,compactButton
    local function labels()
        lowButton.Text="LOW FX: "..(settings.lowFX and "ON" or "OFF")
        shadowButton.Text="SHADOWS OFF: "..(settings.shadows and "ON" or "OFF")
        hudButton.Text="MINI HUD: "..(settings.hud and "ON" or "OFF")
        compactButton.Text="COMPACT: "..(settings.compact and "ON" or "OFF")
        hud.Visible=settings.hud
        hud.Size=settings.compact and UDim2.fromOffset(205,27) or UDim2.fromOffset(238,32)
        panel.Size=settings.compact and UDim2.fromOffset(360,326) or UDim2.fromOffset(360,365)
    end
    lowButton=button("LOW FX",15,180,158,function() settings.lowFX=not settings.lowFX;applyVisuals();save();labels() end)
    shadowButton=button("SHADOWS",187,180,158,function() settings.shadows=not settings.shadows;applyVisuals();save();labels() end)
    hudButton=button("HUD",15,224,158,function() settings.hud=not settings.hud;save();labels() end)
    compactButton=button("COMPACT",187,224,158,function() settings.compact=not settings.compact;save();labels() end)
    local themeButton=button("THEME: CRIMSON",15,268,158,function()
        local names={"crimson","violet","cyan"}
        local nextIdx=1
        for i,name in ipairs(names) do if settings.theme==name then nextIdx=i%#names+1 end end
        settings.theme=names[nextIdx]
        panelStroke.Color=accent();hudStroke.Color=accent()
        themeButton.Text="THEME: "..string.upper(settings.theme)
        save()
    end)
    local resetButton=button("RESET VISUALS",187,268,158,function()
        settings.lowFX=false;settings.shadows=false
        restoreVisual();save();labels()
    end)
    local hint=make("TextLabel",panel,{Text="F8 dashboard  •  F7 mini HUD  •  F9 restore + hide",Font=Enum.Font.Gotham,TextSize=11,TextColor3=Color3.fromRGB(161,167,181),TextXAlignment=Enum.TextXAlignment.Center,BackgroundTransparency=1,Position=UDim2.fromOffset(15,315),Size=UDim2.new(1,-30,0,26)})
    local function drag(target,handle)
        local dragging=false;local beginPoint;local beginPos
        conn(handle.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                dragging=true;beginPoint=input.Position;beginPos=target.Position
            end
        end))
        conn(UIS.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
        end))
        conn(UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
                local delta=input.Position-beginPoint
                target.Position=UDim2.new(beginPos.X.Scale,beginPos.X.Offset+delta.X,beginPos.Y.Scale,beginPos.Y.Offset+delta.Y)
            end
        end))
    end
    drag(panel,header)
    drag(hud,hud)
    local fpsCount=0; local elapsed=0;local fps=0;local started=os.clock()
    conn(RunService.RenderStepped:Connect(function(dt)
        fpsCount=fpsCount+1;elapsed=elapsed+dt
        if elapsed>=.6 then fps=math.floor(fpsCount/elapsed+.5);fpsCount=0;elapsed=0 end
    end))
    local function ping()
        local ok,ms=pcall(function() return math.floor(player:GetNetworkPing()*1000+.5) end)
        return ok and tostring(ms).."ms" or "N/A"
    end
    local function memory()
        local ok,mb=pcall(function() return math.floor(Stats:GetTotalMemoryUsageMb()+.5) end)
        return ok and tostring(mb).." MB" or "N/A"
    end
    local function update()
        local seconds=math.floor(os.clock()-started)
        local users=#Players:GetPlayers()
        local text=string.format("FPS: %d    PING: %s\nPLAYERS: %d    MEMORY: %s\nSESSION: %02d:%02d    GRAPHICS: %s",fps,ping(),users,memory(),math.floor(seconds/60),seconds%60,settings.lowFX and "LOW FX" or "NORMAL")
        status.Text=text
        hud.Text=string.format("VH3  |  %d FPS  |  %s  |  %d PLAYERS",fps,ping(),users)
    end
    conn(UIS.InputBegan:Connect(function(input,processed)
        if processed then return end
        if input.KeyCode==Enum.KeyCode.F8 then panel.Visible=not panel.Visible
        elseif input.KeyCode==Enum.KeyCode.F7 then settings.hud=not settings.hud;save();labels()
        elseif input.KeyCode==Enum.KeyCode.F9 then
            settings.lowFX=false;settings.shadows=false;restoreVisual();save();labels();panel.Visible=false
        end
    end))
    conn(workspace.DescendantAdded:Connect(function(ob)
        if alive and settings.lowFX then reduceEffect(ob) end
    end))
    conn(Lighting.DescendantAdded:Connect(function(ob)
        if alive and settings.lowFX then reduceEffect(ob) end
    end))
    local function cleanup()
        if not alive then return end
        alive=false
        restoreVisual()
        for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        pcall(function() gui:Destroy() end)
        if _G.VH3_ControlCenter and _G.VH3_ControlCenter.Cleanup==cleanup then _G.VH3_ControlCenter=nil end
    end
    _G.VH3_ControlCenter={Cleanup=cleanup,GetSettings=function() return table.clone(settings) end,SetVisible=function(v) panel.Visible=not not v end}
    conn(gui.Destroying:Connect(cleanup))
    themeButton.Text="THEME: "..string.upper(settings.theme)
    labels()
    applyVisuals()
    task.spawn(function()
        while alive and gui.Parent do
            pcall(update)
            task.wait(1)
        end
    end)
    print("[VH3] Control Center loaded | F8 panel, F7 HUD, F9 restore")
end
-- Start independently so errors in the legacy main script cannot prevent dashboard startup.
task.defer(function()
    local ok,err=pcall(VH3_Start)
    if not ok then warn("[VH3] Dashboard setup error: "..tostring(err)) end
end)


-- Vampire Hub V2 - Stability / Security Patch
-- Based on user-provided source. Original gameplay routines remain otherwise unchanged.
-- Changes: scoped skip handler, bounded audio load, duplicate intro cleanup, remote-load removal.
-- Important: Unverified exploit-specific APIs may still fail or violate game rules.

-- ============================================================================
-- LEAKED BY /printed • NUMBER 1
-- Branding pass: readable source markers, console signature, UI micro-watermarks.
-- Original gameplay logic is intentionally left unchanged by this branding pass.
-- ============================================================================
print("[ /printed ] LEAKED BY /printed • NUMBER 1 | VampireHub")

local W = {}
repeat
	task.wait()
until game:IsLoaded()
local bt = game:GetService("Players")
local pt = game:GetService("RunService")
local Mt = game:GetService("UserInputService")
pcall(function()
	if _G._VH_uncapFps then
		_G._VH_uncapFps(999)
	end
end)
local gt = game:GetService("TweenService")
local Ht = game:GetService("HttpService")
local Ft = game:GetService("Lighting")
local Rt = bt.LocalPlayer
local Pt = setmetatable({}, { __mode = "k" })
local ht = 0
local lt
lt = pt.Heartbeat:Connect(function(lt)
	ht = ht + (lt or 0)
	if ht < 0.03333333333333333 then
		return
	end

	ht = 0
	local ht = Rt.Character
	local lt = ht and ht:FindFirstChild("HumanoidRootPart")
	if not lt then
		return
	end

	local ht = os.clock()
	for Dt, Dt in ipairs(bt:GetPlayers()) do
		if Dt ~= Rt then
			local zt = Dt.Character
			local vt = zt and zt:FindFirstChild("HumanoidRootPart")
			local qt = zt and zt:FindFirstChildOfClass("Humanoid")
			if vt and qt and qt.Health > 0 then
				local qt = vt.Position
				local Zt = vt.AssemblyLinearVelocity
				local Et = vt.AssemblyAngularVelocity
				local vt = qt.X == qt.X
					and qt.Y == qt.Y
					and qt.Z == qt.Z
					and math.abs(qt.X) < 1000000
					and math.abs(qt.Y) < 1000000
					and math.abs(qt.Z) < 1000000
				local rt = vt and (lt.Position - qt).Magnitude or math.huge
				local lt = vt
					and qt.Y > -30.0
					and qt.Y < 350
					and rt <= 300
					and Zt.Magnitude <= 180
					and Et.Magnitude <= 45
				local Zt = Pt[Dt]
				if not Zt or Zt.character ~= zt then
					Zt = { character = zt, locked = false, candidate = nil, candidateAt = nil, candidateCount = 0 }
					Pt[Dt] = Zt
				end

				if vt and Zt.lastObserved and (qt - Zt.lastObserved).Magnitude >= 8 then
					Zt.locked = true
				end

				if not lt then
					Zt.locked = true
					Zt.candidate = nil
					Zt.candidateAt = nil
					Zt.candidateCount = 0
				elseif not Zt.locked then
					if Zt.candidate and (qt - Zt.candidate).Magnitude <= 7 then
						Zt.candidate = Zt.candidate:Lerp(qt, 0.35)
						Zt.candidateCount = (Zt.candidateCount or 0) + 1
						if Zt.candidateCount >= 4 and ht - (Zt.candidateAt or ht) >= 0.1 then
							Zt.position = Zt.candidate
							Zt.positionAt = ht
							Zt.confirmed = true
						end
					else
						Zt.candidate = qt
						Zt.candidateAt = ht
						Zt.candidateCount = 1
					end
				end

				if vt then
					Zt.lastObserved = qt
				end
			end
		end
	end
end)
-- [ /printed ] INTRO / BRAND PRESENTATION
local function runIntro()
	local _I, _U, _C, _TI, _Us, _tw, _ts, _UD, _mc, _mf, _ma, _mh, _mx, _mn, _ti, _tr, _EGB, _ESQ, _ESB, _EDO, _EDI, _BgT, _BgC, _BSP, _TC3, _ZI, _TSz =
		Instance.new,
		UDim2.new,
		Color3.fromRGB,
		TweenInfo.new,
		UDim2.fromScale,
		task.wait,
		task.spawn,
		UDim.new,
		math.clamp,
		math.floor,
		math.abs,
		math.huge,
		math.max,
		math.min,
		table.insert,
		table.remove,
		Enum.Font.GothamBold,
		Enum.EasingStyle.Quad,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out,
		Enum.EasingDirection.InOut,
		"BackgroundTransparency",
		"BackgroundColor3",
		"BorderSizePixel",
		"TextColor3",
		"ZIndex",
		"TextSize"
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local Lighting = game:GetService("Lighting")
	local UserInputService = game:GetService("UserInputService")
	local TextService = game:GetService("TextService")
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local previousIntro = playerGui:FindFirstChild("VampireIntro")
	if previousIntro then
		previousIntro:Destroy()
	end
	local screenGui = _I("ScreenGui")
	screenGui.Name = "VampireIntro"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	local introSkipped = false
	local skipIntro -- forward declaration; never leak to shared globals
	local skipConnection = nil
	local introSound = nil
	local SOUND_ID = (_G and _G.__VioletteIntroSoundId and tonumber(_G.__VioletteIntroSoundId)) or 120267378058133
	local SKIP_SECONDS = 10
	local _theme = (_G and _G._VH_introTheme) or "original"
	local _isMono = (_theme ~= "original")
	local _isGreen = (
		_theme == "forest"
		or _theme == "jungle"
		or _theme == "16948826915"
		or _theme == "102609114992392"
	)
	local _isBlue = (_theme == "ocean" or _theme == "79809183056960")
	local _isBlack = (_theme == "79455822331118" or _theme == "8180153808" or _theme == "11761613059")
	local _isPurple = (_theme == "123540425987418" or _theme == "122195659108931")
	local _isBrown = (_theme == "6457947928")
	local _isGray = (_theme == "vampire" or _theme == "139546609567893")
	local _isPink = (_theme == "14430330747" or _theme == "17256388271")
	local _isYellow = (_theme == "golden" or _theme == "132372803152269")
	local PURPLE_MAIN = _isBlack and _C(22, 22, 22)
		or _isGray and _C(155, 155, 155)
		or _isYellow and _C(235, 185, 20)
		or _isGreen and _C(50, 195, 80)
		or _isBlue and _C(50, 130, 255)
		or _isPurple and _C(165, 75, 235)
		or _isBrown and _C(155, 98, 55)
		or _isPink and _C(235, 85, 165)
		or _C(220, 45, 45)
	local PURPLE_GLOW = _isBlack and _C(8, 8, 8)
		or _isGray and _C(100, 100, 100)
		or _isYellow and _C(180, 140, 10)
		or _isGreen and _C(30, 145, 55)
		or _isBlue and _C(30, 90, 210)
		or _isPurple and _C(110, 40, 180)
		or _isBrown and _C(105, 62, 30)
		or _isPink and _C(180, 45, 120)
		or _C(170, 25, 25)
	local PURPLE_LIGHT = _isBlack and _C(58, 58, 58)
		or _isGray and _C(195, 195, 195)
		or _isYellow and _C(255, 220, 70)
		or _isGreen and _C(100, 230, 125)
		or _isBlue and _C(100, 175, 255)
		or _isPurple and _C(210, 140, 255)
		or _isBrown and _C(205, 150, 95)
		or _isPink and _C(255, 145, 205)
		or _C(255, 90, 90)
	local blur = _I("BlurEffect")
	blur.Size = 0
	blur.Parent = Lighting
	local overlay = _I("Frame")
	overlay.Size = _Us(1, 1)
	overlay[_BgC] = _C(0, 0, 0)
	overlay[_BgT] = 0.3
	overlay[_BSP] = 0
	overlay[_ZI] = 1
	overlay.Parent = screenGui
	local darkOverlay = _I("Frame")
	darkOverlay.Size = _Us(1, 1)
	darkOverlay[_BgC] = (_isBlack or _isGray) and _C(8, 8, 8)
		or _isYellow and _C(15, 12, 0)
		or _isGreen and _C(0, 15, 5)
		or _isBlue and _C(0, 6, 18)
		or _isPurple and _C(10, 3, 18)
		or _isBrown and _C(16, 8, 3)
		or _isPink and _C(18, 3, 10)
		or _C(15, 0, 0)
	darkOverlay[_BgT] = 0.5
	darkOverlay[_BSP] = 0
	darkOverlay[_ZI] = 1
	darkOverlay.Parent = screenGui
	local vignette = _I("ImageLabel")
	vignette.Size = _Us(1, 1)
	vignette[_BgT] = 1
	vignette.Image = "rbxassetid://195611797"
	vignette.ImageColor3 = _C(0, 0, 0)
	vignette.ImageTransparency = 0.35
	vignette[_ZI] = 2
	vignette.Parent = screenGui
	local container = _I("Frame")
	container.Size = _U(0, 850, 0, 130)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = _U(0.5, 0, 0.5, 0)
	container[_BgT] = 1
	container[_BSP] = 0
	container.ClipsDescendants = false
	container[_ZI] = 5
	container.Parent = screenGui
	local mainLabel = _I("TextLabel")
	mainLabel.Size = _U(1, 0, 1, 0)
	mainLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	mainLabel.Position = _U(0.5, 0, 0.5, 0)
	mainLabel[_BgT] = 1
	mainLabel.Text = "VAMPIRE"
	mainLabel[_TC3] = _C(255, 255, 255)
	mainLabel.TextStrokeColor3 = _C(0, 0, 0)
	mainLabel.TextStrokeTransparency = 0
	mainLabel.Font = Enum.Font.GothamBlack
	mainLabel[_TSz] = 88
	mainLabel.TextXAlignment = Enum.TextXAlignment.Center
	mainLabel.TextTransparency = 1
	mainLabel[_ZI] = 5
	mainLabel.Parent = container
	local leftLabel = _I("TextLabel")
	leftLabel.Size = _U(0, 480, 1, 0)
	leftLabel.AnchorPoint = Vector2.new(1, 0.5)
	leftLabel.Position = _U(0.5, -8, 0.5, 0)
	leftLabel[_BgT] = 1
	leftLabel.Text = "VAMP"
	leftLabel[_TC3] = _C(255, 255, 255)
	leftLabel.TextStrokeColor3 = _C(0, 0, 0)
	leftLabel.TextStrokeTransparency = 0
	leftLabel.Font = Enum.Font.GothamBlack
	leftLabel[_TSz] = 88
	leftLabel.TextXAlignment = Enum.TextXAlignment.Right
	leftLabel.TextTransparency = 1
	leftLabel[_ZI] = 5
	leftLabel.Visible = true
	leftLabel.Parent = container
	local rightLabel = _I("TextLabel")
	rightLabel.Size = _U(0, 200, 1, 0)
	rightLabel.AnchorPoint = Vector2.new(0, 0.5)
	rightLabel.Position = _U(0.5, -8, 0.5, 0)
	rightLabel[_BgT] = 1
	rightLabel.Text = "IRE"
	rightLabel[_TC3] = _C(255, 255, 255)
	rightLabel.TextStrokeColor3 = _C(0, 0, 0)
	rightLabel.TextStrokeTransparency = 0
	rightLabel.Font = Enum.Font.GothamBlack
	rightLabel[_TSz] = 88
	rightLabel.TextXAlignment = Enum.TextXAlignment.Left
	rightLabel.TextTransparency = 1
	rightLabel[_ZI] = 5
	rightLabel.Visible = true
	rightLabel.Parent = container
	local lightBeam = _I("Frame")
	lightBeam.Size = _U(0, 0, 1.1, 0)
	lightBeam.AnchorPoint = Vector2.new(0, 0.5)
	lightBeam.Position = _U(0, -20, 0.5, 0)
	lightBeam[_BgC] = PURPLE_MAIN
	lightBeam[_BgT] = 0.5
	lightBeam[_BSP] = 0
	lightBeam[_ZI] = 6
	lightBeam.Parent = container
	local beamGlow = _I("Frame")
	beamGlow.Size = _U(0, 0, 1.3, 0)
	beamGlow.AnchorPoint = Vector2.new(0, 0.5)
	beamGlow.Position = _U(0, -20, 0.5, 0)
	beamGlow[_BgC] = PURPLE_GLOW
	beamGlow[_BgT] = 0.7
	beamGlow[_BSP] = 0
	beamGlow[_ZI] = 5
	beamGlow.Parent = container
	local beamSparkles = _I("Frame")
	beamSparkles.Size = _U(0, 0, 1, 0)
	beamSparkles.AnchorPoint = Vector2.new(0, 0.5)
	beamSparkles.Position = _U(0, -20, 0.5, 0)
	beamSparkles[_BgC] = _C(255, 255, 255)
	beamSparkles[_BgT] = 0.8
	beamSparkles[_BSP] = 0
	beamSparkles[_ZI] = 7
	beamSparkles.Parent = container
	local subLabel = _I("TextLabel")
	subLabel.Size = _U(1, 0, 0, 40)
	subLabel.AnchorPoint = Vector2.new(0.5, 0)
	subLabel.Position = _U(0.5, 0, 0.5, 70)
	subLabel[_BgT] = 1
	subLabel.Text = "vampire hub  •  LEAKED BY /printed #1"
	subLabel[_TC3] = PURPLE_MAIN
	subLabel.Font = _EGB
	subLabel[_TSz] = 14
	subLabel.TextXAlignment = Enum.TextXAlignment.Center
	subLabel.TextTransparency = 1
	subLabel[_ZI] = 5
	subLabel.Parent = screenGui
	local subLabel2 = _I("TextLabel")
	subLabel2.Size = _U(1, 0, 0, 25)
	subLabel2.AnchorPoint = Vector2.new(0.5, 0)
	subLabel2.Position = _U(0.5, 0, 0.5, 105)
	subLabel2[_BgT] = 1
	subLabel2.Text = "DOUBLE TAP TO SKIP"
	subLabel2[_TC3] = _isMono and _C(140, 140, 140) or _C(160, 70, 70)
	subLabel2.Font = Enum.Font.Gotham
	subLabel2[_TSz] = 11
	subLabel2.TextXAlignment = Enum.TextXAlignment.Center
	subLabel2.TextTransparency = 1
	subLabel2[_ZI] = 5
	subLabel2.Parent = screenGui
	local accentBar = _I("Frame")
	accentBar.Size = _U(0, 0, 0, 2)
	accentBar.AnchorPoint = Vector2.new(0.5, 0)
	accentBar.Position = _U(0.5, 0, 0.5, 62)
	accentBar[_BgC] = PURPLE_MAIN
	accentBar[_BgT] = 0
	accentBar[_BSP] = 0
	accentBar[_ZI] = 5
	accentBar.Parent = screenGui
	local flashFrame = _I("Frame")
	flashFrame.Size = _Us(1, 1)
	flashFrame[_BgC] = _C(255, 255, 255)
	flashFrame[_BgT] = 1
	flashFrame[_BSP] = 0
	flashFrame[_ZI] = 10
	flashFrame.Parent = screenGui
	local glitchContainer = _I("Frame")
	glitchContainer.Size = _U(1, 0, 1, 0)
	glitchContainer[_BgT] = 1
	glitchContainer[_ZI] = 6
	glitchContainer.Parent = screenGui
	local dripContainer = _I("Frame")
	dripContainer.Size = _U(1, 0, 1, 0)
	dripContainer[_BgT] = 1
	dripContainer[_ZI] = 7
	dripContainer.Parent = screenGui
	local skipBtnFrame = _I("Frame")
	skipBtnFrame.Size = _U(0, 90, 0, 34)
	skipBtnFrame.AnchorPoint = Vector2.new(1, 1)
	skipBtnFrame.Position = _U(1, -18, 1, -18)
	skipBtnFrame[_BgC] = _isMono and _C(30, 30, 30) or _C(50, 8, 8)
	skipBtnFrame[_BgT] = 0.25
	skipBtnFrame[_BSP] = 0
	skipBtnFrame[_ZI] = 15
	skipBtnFrame.Parent = screenGui
	local _skipCorner = _I("UICorner")
	_skipCorner.CornerRadius = _UD(0, 8)
	_skipCorner.Parent = skipBtnFrame
	local _skipStroke = _I("UIStroke")
	_skipStroke.Color = PURPLE_MAIN
	_skipStroke.Thickness = 1.5
	_skipStroke.Transparency = 0.3
	_skipStroke.Parent = skipBtnFrame
	local tapToRemoveLabel = _I("TextButton")
	tapToRemoveLabel.Size = _Us(1, 1)
	tapToRemoveLabel[_BgT] = 1
	tapToRemoveLabel.Text = "SKIP  ›"
	tapToRemoveLabel[_TC3] = PURPLE_MAIN
	tapToRemoveLabel.Font = _EGB
	tapToRemoveLabel[_TSz] = 13
	tapToRemoveLabel.TextXAlignment = Enum.TextXAlignment.Center
	tapToRemoveLabel.TextTransparency = 0
	tapToRemoveLabel[_ZI] = 16
	tapToRemoveLabel.Parent = skipBtnFrame
	tapToRemoveLabel.Activated:Connect(function()
		skipIntro()
	end)
	local function doFlash(color, alpha, duration)
		flashFrame[_BgC] = color or Color3.new(1, 1, 1)
		flashFrame[_BgT] = 1 - (alpha or 0.85)
		task.delay(duration or 0.06, function()
			if not introSkipped then
				TweenService:Create(flashFrame, _TI(0.1, _ESQ), { BackgroundTransparency = 1 }):Play()
			else
				flashFrame[_BgT] = 1
			end
		end)
	end
	local function runLightBeam()
		lightBeam.Size = _U(0, 45, 1.1, 0)
		beamGlow.Size = _U(0, 65, 1.3, 0)
		beamSparkles.Size = _U(0, 45, 1, 0)
		lightBeam[_BgT] = 0.35
		beamGlow[_BgT] = 0.55
		beamSparkles[_BgT] = 0.75
		local beamTween = TweenService:Create(lightBeam, _TI(0.8, _ESQ, _EDI), { Position = _U(1, 20, 0.5, 0) })
		beamTween:Play()
		TweenService:Create(beamGlow, _TI(0.8, _ESQ, _EDI), { Position = _U(1, 20, 0.5, 0) }):Play()
		TweenService:Create(beamSparkles, _TI(0.8, _ESQ, _EDI), { Position = _U(1, 20, 0.5, 0) }):Play()
		local pulseCount = 0
		local pulseConnection
		pulseConnection = game:GetService("RunService").Heartbeat:Connect(function()
			if introSkipped then
				if pulseConnection then
					pulseConnection:Disconnect()
				end
				return
			end
			pulseCount = pulseCount + 1
			if pulseCount % 3 == 0 then
				local p = 0.3 + math.sin(pulseCount * 0.5) * 0.15
				lightBeam[_BgT] = 0.3 - (p * 0.2)
				beamGlow[_BgT] = 0.5 - (p * 0.1)
				beamSparkles[_BgT] = 0.7 - (p * 0.15)
			end
		end)
		beamTween.Completed:Wait()
		if pulseConnection then
			pulseConnection:Disconnect()
		end
		TweenService:Create(lightBeam, _TI(0.25), { BackgroundTransparency = 1, Size = _U(0, 0, 1.1, 0) }):Play()
		TweenService:Create(beamGlow, _TI(0.25), { BackgroundTransparency = 1, Size = _U(0, 0, 1.3, 0) }):Play()
		TweenService:Create(beamSparkles, _TI(0.25), { BackgroundTransparency = 1, Size = _U(0, 0, 1, 0) }):Play()
	end
	local function changeToPurple()
		_tw(0.2)
		TweenService
			:Create(mainLabel, _TI(0.4, _ESQ), { TextColor3 = _isMono and _C(180, 180, 180) or _C(220, 40, 40) })
			:Play()
	end
	local glitchChars = { "!", "#", "%", "/", "[", "]", "░", "▒", "▓", "—", "=", "*", "^", "~", "¦", "¤" }
	local function glitchText(lbl, original)
		if introSkipped then
			return
		end
		for i = 1, 4 do
			if introSkipped then
				break
			end
			local s = ""
			for c in original:gmatch(".") do
				s = s .. (math.random() < 0.35 and glitchChars[math.random(#glitchChars)] or c)
			end
			lbl.Text = s
			_tw(0.03)
		end
		if not introSkipped then
			lbl.Text = original
		end
	end
	local function addGlitchBar()
		local bar = _I("Frame")
		bar.Size = _U(1, 0, 0, math.random(2, 12))
		bar.Position = _U(0, 0, math.random(10, 90) / 100, 0)
		bar[_BgC] = PURPLE_MAIN
		bar[_BgT] = math.random(45, 70) / 100
		bar[_BSP] = 0
		bar[_ZI] = 6
		bar.Parent = glitchContainer
		task.delay(0.1, function()
			if bar then
				TweenService:Create(bar, _TI(0.1), { BackgroundTransparency = 1 }):Play()
				task.delay(0.1, function()
					bar:Destroy()
				end)
			end
		end)
	end
	local function shakeScreen(intensity, duration)
		if introSkipped then
			return
		end
		local startTime = tick()
		local steps = math.ceil(duration / 0.05)
		for _ = 1, steps do
			if introSkipped then
				break
			end
			local elapsed = tick() - startTime
			local cur = intensity * (1 - (elapsed / duration))
			if cur < 1 then
				cur = 1
			end
			local ox = math.random(-_mf(cur), _mf(cur))
			local oy = math.random(-_mf(cur * 0.5), _mf(cur * 0.5))
			leftLabel.Position = _U(0.5, -8 + ox, 0.5, oy)
			rightLabel.Position = _U(0.5, 8 + ox, 0.5, oy)
			_tw(0.05)
		end
		if not introSkipped then
			TweenService:Create(leftLabel, _TI(0.05), { Position = _U(0.5, -8, 0.5, 0) }):Play()
			TweenService:Create(rightLabel, _TI(0.05), { Position = _U(0.5, 8, 0.5, 0) }):Play()
		end
	end
	local function setupAudio()
		introSound = _I("Sound")
		introSound.SoundId = "rbxassetid://" .. SOUND_ID
		introSound.Volume = 0.7
		introSound.PlayOnRemove = false
		introSound.Parent = screenGui
		-- Audio is optional. Never block the full UI when an asset fails to load.
		local deadline = os.clock() + 3
		while not introSound.IsLoaded and not introSkipped and os.clock() < deadline do
			task.wait(0.05)
		end
		if introSkipped or not introSound.IsLoaded then
			return nil
		end
		local ok, err = pcall(function()
			introSound.TimePosition = SKIP_SECONDS
			introSound:Play()
		end)
		if not ok then
			warn("[VampireHub] Intro audio unavailable: " .. tostring(err))
		end
		return introSound
	end
	local function fadeOutAudio(duration)
		if not introSound then
			return
		end
		local startVolume = introSound.Volume
		local steps = 10
		for i = 1, steps do
			if introSkipped or not introSound then
				break
			end
			introSound.Volume = startVolume * (1 - (i / steps))
			_tw(duration / steps)
		end
		if introSound then
			introSound.Volume = 0
			introSound:Stop()
		end
	end
	local function stopAudio()
		if introSound then
			introSound:Stop()
			introSound:Destroy()
		end
	end
	local activeDrips = 0
	local function createDrip(startX, startY, width, height, duration, delay)
		_tw(delay)
		if introSkipped then
			return
		end
		activeDrips = activeDrips + 1
		local drip = _I("Frame")
		drip.Size = _U(0, width, 0, height)
		drip.Position = _U(0.5, startX, 0.5, startY)
		drip[_BgC] = PURPLE_MAIN
		drip[_BgT] = 0.25
		drip[_BSP] = 0
		drip[_ZI] = 7
		drip.Parent = dripContainer
		local stretch = TweenService:Create(
			drip,
			_TI(duration * 0.35),
			{ Size = _U(0, width, 0, height + 22), BackgroundTransparency = 0.1 }
		)
		stretch:Play()
		_tw(duration * 0.35)
		if introSkipped then
			drip:Destroy()
			activeDrips = activeDrips - 1
			return
		end
		local fall = TweenService:Create(drip, _TI(duration * 0.65, _ESQ, Enum.EasingDirection.In), {
			Position = _U(0.5, startX + math.random(-3, 3), 0.5, startY + 80),
			BackgroundTransparency = 1,
		})
		fall:Play()
		fall.Completed:Connect(function()
			drip:Destroy()
			activeDrips = activeDrips - 1
		end)
	end
	local function startDripping()
		if introSkipped then
			return
		end
		local fullText = "VAMPIRE"
		local font = Enum.Font.GothamBlack
		local textSize = 88
		local textBoundsFull = TextService:GetTextSize(fullText, textSize, font, Vector2.new(_mh, _mh))
		local textHeight = textBoundsFull.Y
		local delayCounter = 0
		local drips = {}
		for i = 1, #fullText do
			local char = fullText:sub(i, i)
			local charBounds = TextService:GetTextSize(char, textSize, font, Vector2.new(_mh, _mh))
			local charWidth = charBounds.X
			local precedingWidth = 0
			if i > 1 then
				precedingWidth =
					TextService:GetTextSize(fullText:sub(1, i - 1), textSize, font, Vector2.new(_mh, _mh)).X
			end
			local totalTextWidth = textBoundsFull.X
			local charCenterX = -totalTextWidth / 2 + precedingWidth + charWidth / 2
			local startY = textHeight / 2 + 3
			local dripWidth = _mc(_mf(charWidth * 0.35), 3, 7)
			local dripHeight = math.random(4, 7)
			local dur = 0.5 + math.random() * 0.2
			local del = delayCounter * 0.07
			_ti(drips, {
				startX = charCenterX + math.random(-2, 2),
				startY = startY + math.random(0, 4),
				width = dripWidth,
				height = dripHeight,
				duration = dur,
				delay = del,
			})
			delayCounter = delayCounter + 1
		end
		for _, d in ipairs(drips) do
			if introSkipped then
				break
			end
			createDrip(d.startX, d.startY, d.width, d.height, d.duration, d.delay)
		end
	end
	skipIntro = function()
		if introSkipped then
			return
		end
		introSkipped = true
		stopAudio()
		if skipConnection then
			skipConnection:Disconnect()
		end
		doFlash(_isMono and _C(200, 200, 200) or _C(255, 100, 100), 0.8, 0.1)
		mainLabel.Text = "VAMPIRE"
		local fadeInfo = _TI(0.25, _ESQ, Enum.EasingDirection.In)
		TweenService:Create(mainLabel, fadeInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(leftLabel, fadeInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(rightLabel, fadeInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(subLabel, fadeInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(subLabel2, fadeInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(accentBar, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(overlay, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(darkOverlay, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(blur, _TI(0.25), { Size = 0 }):Play()
		_tw(0.3)
		screenGui:Destroy()
		blur:Destroy()
	end
	local function playIntro()
		setupAudio()
		local _lastTapTime = 0
		skipConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				local now = tick()
				if now - _lastTapTime <= 0.4 then
					skipIntro()
				else
					_lastTapTime = now
				end
			end
		end)
		_ts(function()
			while not introSkipped and skipBtnFrame.Parent do
				for t = 0.25, 0.6, 0.05 do
					if introSkipped then
						break
					end
					skipBtnFrame[_BgT] = t
					_tw(0.06)
				end
				for t = 0.6, 0.25, -0.05 do
					if introSkipped then
						break
					end
					skipBtnFrame[_BgT] = t
					_tw(0.06)
				end
			end
		end)
		leftLabel.Position = _U(-0.9, 0, -0.6, 0)
		rightLabel.Position = _U(1.9, 0, 1.6, 0)
		leftLabel.Rotation = -30
		rightLabel.Rotation = 30
		mainLabel.TextTransparency = 1
		TweenService:Create(blur, _TI(0.7), { Size = 18 }):Play()
		TweenService:Create(overlay, _TI(0.7), { BackgroundTransparency = 0.2 }):Play()
		TweenService:Create(darkOverlay, _TI(0.7), { BackgroundTransparency = 0.4 }):Play()
		_tw(0.35)
		if introSkipped then
			return
		end
		TweenService:Create(leftLabel, _TI(0.45), { TextTransparency = 0 }):Play()
		TweenService:Create(rightLabel, _TI(0.45), { TextTransparency = 0 }):Play()
		TweenService:Create(
			leftLabel,
			_TI(0.55, Enum.EasingStyle.Elastic, _EDO),
			{ Position = _U(0.5, -220, 0.5, -80), Rotation = -15 }
		):Play()
		TweenService:Create(
			rightLabel,
			_TI(0.55, Enum.EasingStyle.Elastic, _EDO),
			{ Position = _U(0.5, 120, 0.5, 80), Rotation = 15 }
		):Play()
		_tw(0.45)
		if introSkipped then
			return
		end
		local smooth = _TI(0.4, _ESQ, _EDO)
		TweenService:Create(leftLabel, smooth, { Position = _U(0.5, -170, 0.5, -50), Rotation = -8 }):Play()
		TweenService:Create(rightLabel, smooth, { Position = _U(0.5, 80, 0.5, 50), Rotation = 8 }):Play()
		_tw(0.35)
		if introSkipped then
			return
		end
		TweenService:Create(leftLabel, smooth, { Position = _U(0.5, -120, 0.5, -25), Rotation = -4 }):Play()
		TweenService:Create(rightLabel, smooth, { Position = _U(0.5, 40, 0.5, 25), Rotation = 4 }):Play()
		_tw(0.3)
		if introSkipped then
			return
		end
		TweenService:Create(leftLabel, smooth, { Position = _U(0.5, -60, 0.5, -10), Rotation = -2 }):Play()
		TweenService:Create(rightLabel, smooth, { Position = _U(0.5, -10, 0.5, 10), Rotation = 2 }):Play()
		_tw(0.25)
		if introSkipped then
			return
		end
		local glitchEnd = tick() + 0.9
		while tick() < glitchEnd and not introSkipped do
			local ox = math.random(-20, 20)
			local oy = math.random(-10, 10)
			leftLabel.Position = _U(0.5, -60 + ox, 0.5, -10 + oy)
			rightLabel.Position = _U(0.5, -10 + ox, 0.5, 10 + oy)
			if math.random() < 0.35 then
				_ts(glitchText, leftLabel, "VAMP")
			end
			if math.random() < 0.35 then
				_ts(glitchText, rightLabel, "IRE")
			end
			if math.random() < 0.4 then
				addGlitchBar()
			end
			if math.random() < 0.1 then
				doFlash(PURPLE_MAIN, 0.2, 0.03)
			end
			_tw(0.045)
		end
		if introSkipped then
			return
		end
		leftLabel.Visible = false
		rightLabel.Visible = false
		mainLabel.TextTransparency = 0
		mainLabel[_TC3] = _C(255, 255, 255)
		doFlash(PURPLE_MAIN, 0.5, 0.05)
		_tw(0.08)
		if introSkipped then
			return
		end
		TweenService
			:Create(
				mainLabel,
				_TI(0.12, _ESB, Enum.EasingDirection.In),
				{ Position = _U(0.5, 0, 0.5, 0), TextSize = 92 }
			)
			:Play()
		_tw(0.12)
		if introSkipped then
			return
		end
		TweenService:Create(mainLabel, _TI(0.1), { TextSize = 88 }):Play()
		doFlash(_C(255, 255, 255), 0.95, 0.05)
		_tw(0.02)
		doFlash(PURPLE_MAIN, 0.65, 0.08)
		_ts(shakeScreen, 10, 0.25)
		runLightBeam()
		changeToPurple()
		TweenService:Create(accentBar, _TI(0.5, Enum.EasingStyle.Elastic, _EDO), { Size = _U(0, 420, 0, 2) }):Play()
		_tw(0.18)
		if introSkipped then
			return
		end
		TweenService:Create(subLabel, _TI(0.4), { TextTransparency = 0.05 }):Play()
		TweenService:Create(subLabel2, _TI(0.4), { TextTransparency = 0.15 }):Play()
		_tw(0.1)
		doFlash(_C(255, 255, 255), 0.3, 0.04)
		TweenService:Create(subLabel, _TI(0.2), { TextSize = 15 }):Play()
		_tw(0.2)
		TweenService:Create(subLabel, _TI(0.2), { TextSize = 14 }):Play()
		_tw(0.65)
		if introSkipped then
			return
		end
		startDripping()
		while activeDrips > 0 and not introSkipped do
			_tw(0.1)
		end
		if introSkipped then
			return
		end
		_tw(0.45)
		fadeOutAudio(1.2)
		local fadeInfo = _TI(0.85, _ESQ, Enum.EasingDirection.In)
		TweenService:Create(mainLabel, fadeInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(subLabel, fadeInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(subLabel2, fadeInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(accentBar, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(overlay, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(darkOverlay, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(blur, _TI(0.85), { Size = 0 }):Play()
		TweenService:Create(dripContainer, fadeInfo, { BackgroundTransparency = 1 }):Play()
		_tw(0.9)
		stopAudio()
		if skipConnection then
			skipConnection:Disconnect()
		end
		screenGui:Destroy()
		blur:Destroy()
	end
	playIntro()
end
local kt = false
do
	local function Ct(ht)
		local lt
		pcall(function()
			if readfile then
				lt = readfile(ht)
			end
		end)
		return lt
	end

	local function ht(lt)
		local Dt = false
		pcall(function()
			if isfile then
				Dt = isfile(lt)
			elseif readfile then
				local zt = readfile(lt)
				Dt = (zt ~= nil)
			end
		end)
		return Dt
	end

	local lt = {
		original = true,
		vampire = true,
		golden = true,
		forest = true,
		jungle = true,
		ocean = true,
		["79809183056960"] = true,
		["79455822331118"] = true,
		["16948826915"] = true,
		["101793424727240"] = true,
		["123540425987418"] = true,
		["122195659108931"] = true,
		["6457947928"] = true,
		["102609114992392"] = true,
		["8180153808"] = true,
		["11761613059"] = true,
		["139546609567893"] = true,
		["14430330747"] = true,
		["17256388271"] = true,
		["132372803152269"] = true,
	}
	_G._VH_introTheme = "original"
	if ht("VampireHubConfig.json") then
		local ht = Ct("VampireHubConfig.json")
		if ht then
			local Dt, zt = pcall(function()
				return game:GetService("HttpService"):JSONDecode(ht)
			end)
			if Dt and type(zt) == "table" then
				if zt.showIntro == false then
					kt = true
				end

				if type(zt.activeBgImg) == "string" and lt[zt.activeBgImg] then
					_G._VH_introTheme = zt.activeBgImg
				end

				_G._VH_monoIntro = (_G._VH_introTheme ~= "original")
				local ht = {}
				if type(zt.favoriteBackgrounds) == "table" then
					for Dt, vt in pairs(zt.favoriteBackgrounds) do
						local zt = type(Dt) == "number" and vt or Dt
						local qt = type(Dt) == "number" or vt == true
						if qt and type(zt) == "string" and lt[zt] then
							ht[zt] = true
						end
					end
				end

				_G._VH_bgFavorites = ht
			end
		end
	end

	local ht = Ct("VampireHubIntro.state")
	if ht == "off" then
		kt = true
	elseif ht == "on" then
		kt = false
	end
end

_G.__VioletteIntroSoundId = 120267378058133
if not kt then
	task.spawn(runIntro)
end

task.wait()
local function It(Ct)
	return Ct == Enum.UserInputType.Gamepad1
		or Ct == Enum.UserInputType.Gamepad2
		or Ct == Enum.UserInputType.Gamepad3
		or Ct == Enum.UserInputType.Gamepad4
end

local function Ct(ht)
	return ht.UserInputType == Enum.UserInputType.Keyboard or It(ht.UserInputType)
end

local function ht(lt, Dt)
	local zt = false
	pcall(function()
		if writefile then
			writefile(lt, Dt)
			zt = true
		end
	end)
	return zt
end

local function lt(Dt)
	local zt = nil
	pcall(function()
		if readfile then
			zt = readfile(Dt)
		end
	end)
	return zt
end

local function Dt(zt)
	local vt = false
	pcall(function()
		if isfile then
			vt = isfile(zt)
		elseif readfile then
			local qt = readfile(zt)
			vt = (qt ~= nil)
		end
	end)
	return vt
end

-- [ /printed ] FEATURE STATE AND CONTROL CONFIGURATION
local zt = {
	normalSpeed = 60,
	carrySpeed = 30,
	speedToggled = false,
	autoBatToggled = false,
	autoBatVersion = "v1",
	speedChangeMethod = "v2",
	speedChangeMethodSaved = "v2",
	hittingCooldown = false,
	infJumpEnabled = false,
	antiRagdollEnabled = false,
	fpsBoostEnabled = false,
	guiVisible = true,
	safeModeEnabled = true,
	safeCarryLock = false,
	dropBrainrotMode = false,
	stopOnCountdown = false,
	countdownSafetyActive = false,
	stealBarPos = nil,
	isStealing = false,
	stealStartTime = nil,
	lastStealTick = 0,
	stealPausedUntil = 0,
	lastKnownHealth = 100,
	autoLeftEnabled = false,
	autoRightEnabled = false,
	autoLeftPhase = 1,
	autoRightPhase = 1,
	medusaLastUsed = 0,
	medusaDebounce = false,
	medusaCounterEnabled = false,
	_tpInProgress = false,
	lastMoveDir = Vector3.new(0, 0, 0),
	unwalkEnabled = false,
	headlessEnabled = false,
	korbloxEnabled = false,
	dropEnabled = false,
	dropType = "Jump Drop",
	holdInfJumpEnabled = true,
	jumpType = "hold",
	jumpPower = 45,
	batCounterEnabled = false,
	autoSwingEnabled = true,
	burstNormalSpeed = 15,
	burstCarrySpeed = 24.5,
	bypassNormalSpeed = 45,
	bypassCarrySpeed = 18,
	laggerMode = 0,
	_prevCarry = nil,
	_prevSpeed = false,
	burstPreset = "lagger",
	autoBatSpeed = 58,
	mirrorTPDownEnabled = false,
	desyncAimbotEnabled = false,
	desyncAimbotVersion = "v1",
	desyncStopAfterHit = false,
	antiDieEnabled = false,
	disablePredictionAt180 = true,
	lockedFOV = workspace.CurrentCamera.FieldOfView,
	stretchRezEnabled = false,
	stretchedResEnabled = false,
	stretchFOV = 120,
	activeSky = "default",
	activeBgImg = "original",
	bgFavorites = _G._VH_bgFavorites or {},
	stealMode = "semi",
	normalV2StopAt = 75,
	semiVersion = "v2",
	animEnabled = false,
	autoTpDownEnabled = false,
	tpDownHeight = 20,
	sideButtonsVisible = true,
	guiScale = 0.75,
	progressBarSize = 1,
	showProgressBar = true,
	stopOnHitEnabled = true,
	showProgressFPS = true,
	showProgressPing = true,
	sideButtonPositions = {},
	sideButtonSizes = {},
	sideButtonScale = 0.85,
	sideButtonType = "square",
	sideButtonLook = "black",
	sideButtonDragMode = "one",
	sideButtonDragModeSaved = "one",
	sideButtonsLocked = false,
	showButtonOutline = false,
	hiddenSideButtons = {},
	safetyLocked = false,
	kickWarningEnabled = true,
	autoCarryOnGrab = false,
	autoCarryVersion = "v2",
	autoPlayMode = "normal",
	introEnabled = not kt,
	lineEspEnabled = false,
	lineEspColor = "red",
	selectedAnim = "None",
	espAuraEnabled = true,
	espLineEnabled = true,
	espHitboxEnabled = true,
	espPanelOpen = false,
}
do
	if _G.SafeMode and type(_G.SafeMode.Stop) == "function" then
		pcall(_G.SafeMode.Stop)
	end

	_G.SafeMode = nil
end

local vt, qt, Zt, rt, jt
local et
local Tt
local Nt
local Kt = {}
local ct
local At, ut
local Ut
local Lt = false
local function Yt(Ot)
	if not pbFrame then
		return
	end

	local Bt = math.clamp(zt.progressBarSize or 1, 0.6, 1.4)
	local St = zt.showProgressFPS or zt.showProgressPing
	local tt = zt.showProgressFPS and zt.showProgressPing and 116
		or zt.showProgressFPS and 58
		or zt.showProgressPing and 76
		or 0
	local Xt = St and 236 + tt or 210
	pbFrame.Size = UDim2.new(0, Xt * Bt, 0, 35 * Bt)
	if Ot or not Lt then
		if zt.stealBarPos then
			local Ot, wt, ot, yt = zt.stealBarPos:match("([^,]+),([^,]+),([^,]+),([^,]+)")
			if Ot then
				pbFrame.Position = UDim2.new(tonumber(Ot), tonumber(wt), tonumber(ot), tonumber(yt))
			else
				pbFrame.Position = UDim2.new(0.5, -(Xt * Bt) / 2, 1, -60.0)
			end
		else
			pbFrame.Position = UDim2.new(0.5, -(Xt * Bt) / 2, 1, -60.0)
		end

		Lt = true
	end

	pbFrame.Visible = zt.showProgressBar == true
	if pbBg then
		pbBg.Size = UDim2.new(0, 210 * Bt, 1, 0)
		pbBg.Position = UDim2.new(0, 0, 0, 0)
	end

	if stealLbl then
		stealLbl.TextSize = 13 * Bt
	end

	if progressPct then
		progressPct.TextSize = 12 * Bt
	end

	if _prl then
		_prl.Visible = St
		_prl.Size = UDim2.new(0, tt * Bt, 1, 0)
		_prl.Position = UDim2.new(0, 222 * Bt, 0, 0)
		_prl.TextSize = 12 * Bt
	end
end

local Lt = {
	autoBat = Enum.KeyCode.E,
	speed = Enum.KeyCode.Q,
	lagger = Enum.KeyCode.Unknown,
	antiDie = Enum.KeyCode.Unknown,
	guiHide = Enum.KeyCode.LeftControl,
	autoLeft = Enum.KeyCode.Z,
	autoRight = Enum.KeyCode.C,
	dropBrainrot = Enum.KeyCode.H,
	tpDown = Enum.KeyCode.T,
	desyncAimbot = Enum.KeyCode.X,
	burst = Enum.KeyCode.C,
}
local Ot = {
	{ key = "drop", label = "DROP" },
	{ key = "autoLeft", label = "AUTO\nLEFT" },
	{ key = "aimbot", label = "AIMBOT" },
	{ key = "autoRight", label = "AUTO\nRIGHT" },
	{ key = "tpDown", label = "TP\nDOWN" },
	{ key = "carrySpeed", label = "CARRY\nSPEED" },
	{ key = "laggerCarry", label = "LAGGER\nCARRY" },
	{ key = "lagger", label = "LAGGER\nSPEED" },
	{ key = "tpDesync", label = "TP\nDESYNC" },
}
W.SIDE_BUTTON_LAYOUT_VERSION = 2
local Bt = {}
W.SIDE_BUTTON_BASE_SIZE = 58
W.SIDE_BUTTON_BASE_GAP = 8
W.SIDE_BUTTON_MIN_WIDTH = 36
W.SIDE_BUTTON_MAX_WIDTH = 220
W.SIDE_BUTTON_MIN_HEIGHT = 32
W.SIDE_BUTTON_MAX_HEIGHT = 130
local function St(tt)
	local Xt = math.clamp(tonumber(zt.sideButtonScale) or 1, 0.5, 1.5)
	local wt = math.floor(W.SIDE_BUTTON_BASE_SIZE * Xt + 0.5)
	local ot = wt
	if tt and tt.wide then
		ot = math.floor(W.SIDE_BUTTON_BASE_SIZE * 2 * Xt + W.SIDE_BUTTON_BASE_GAP + 0.5)
	end

	return ot, wt
end

local function tt(Xt)
	local wt, ot = St(Xt)
	local yt = Xt and zt.sideButtonSizes and zt.sideButtonSizes[Xt.key]
	local Xt = type(yt) == "table" and tonumber(yt.width) or wt
	local dt = type(yt) == "table" and tonumber(yt.height) or ot
	Xt = math.clamp(math.floor((Xt or wt) + 0.5), W.SIDE_BUTTON_MIN_WIDTH, W.SIDE_BUTTON_MAX_WIDTH)
	dt = math.clamp(math.floor((dt or ot) + 0.5), W.SIDE_BUTTON_MIN_HEIGHT, W.SIDE_BUTTON_MAX_HEIGHT)
	if zt.sideButtonType == "circle" then
		local wt = math.min(W.SIDE_BUTTON_MIN_WIDTH, W.SIDE_BUTTON_MIN_HEIGHT)
		local ot = math.max(W.SIDE_BUTTON_MAX_WIDTH, W.SIDE_BUTTON_MAX_HEIGHT)
		local yt = math.clamp(math.floor((Xt + dt) / 2 + 0.5), wt, ot)
		return yt, yt
	end

	return Xt, dt
end

local function Xt(wt)
	local ot = Bt[wt]
	if not (ot and ot.frame) then
		return
	end

	for yt, yt in ipairs(Ot) do
		if yt.key == wt then
			local wt, dt = tt(yt)
			ot.frame.Size = UDim2.new(0, wt, 0, dt)
			return
		end
	end
end

local function wt()
	local ot = zt.sideButtonType == "circle"
	for yt, yt in ipairs(Ot) do
		Xt(yt.key)
		local dt = Bt[yt.key]
		if dt and dt.frame then
			local yt = dt.frame:FindFirstChildOfClass("UICorner")
			if yt then
				yt.CornerRadius = ot and UDim.new(1, 0) or UDim.new(0, 12)
			end
		end
	end

	if _G._VH_refreshMobileSizeUI then
		pcall(_G._VH_refreshMobileSizeUI)
	end
end

local function ot()
	zt.sideButtonSizes = {}
	for yt, yt in ipairs(Ot) do
		Xt(yt.key)
	end

	if _G._VH_refreshMobileSizeUI then
		pcall(_G._VH_refreshMobileSizeUI)
	end
end

local yt = {
	AutoStealEnabled = false,
	StealRadius = 61,
	StealDuration = 1.3,
	NormalRadius = 61,
	NormalDuration = 1.3,
	SemiRadius = 61,
	SemiDuration = 1.3,
	Data = {},
	plotCache = {},
	plotCacheTime = {},
	cachedPrompts = {},
	promptCacheTime = 0,
}
local dt = {
	[Enum.KeyCode.W] = true,
	[Enum.KeyCode.A] = true,
	[Enum.KeyCode.S] = true,
	[Enum.KeyCode.D] = true,
	[Enum.KeyCode.Up] = true,
	[Enum.KeyCode.Left] = true,
	[Enum.KeyCode.Down] = true,
	[Enum.KeyCode.Right] = true,
}
W.PLOT_CACHE_DURATION = 2
W.PROMPT_CACHE_REFRESH = Mt.TouchEnabled and not Mt.KeyboardEnabled and 0.3 or 0.15
W.STEAL_COOLDOWN = 0.1
W.AUTO_START_DELAY = 0.7
W.MEDUSA_COOLDOWN = 25
W.DROP_AUTO_OFF_DELAY = 0.15
local W1 = {
	L1 = Vector3.new(-476.48, -6.28, 92.73),
	L2 = Vector3.new(-483.12, -4.95, 94.8),
	R1 = Vector3.new(-476.16, -6.52, 25.62),
	R2 = Vector3.new(-483.04, -5.09, 23.14),
}
local x1 = {
	autoSteal = nil,
	antiRag = nil,
	autoLeft = nil,
	autoRight = nil,
	anchor = {},
	progress = nil,
	batAimbot = nil,
	autoTpDown = nil,
	desyncAimbot = nil,
}
local m1 = RaycastParams.new()
m1.FilterType = Enum.RaycastFilterType.Exclude
m1.IgnoreWater = true
pcall(function()
	m1.RespectCanCollide = true
end)
local Q1 = Mt.TouchEnabled and not Mt.KeyboardEnabled
W._AUTO_WALK_UPDATE_INTERVAL = 0
W._AUTO_WALK_COLLISION_INTERVAL = Q1 and 0.03333333333333333 or 0.022222222222222223
local a1 = nil
local function s1()
	return false
end

local function n1(V1, _1, f1, J1)
	local G1 = Vector3.new(_1.X, 0, _1.Z)
	if not (V1 and V1.Parent) or G1.Magnitude < 0.01 then
		return G1, false
	end

	local _1 = G1.Magnitude
	local i1 = Rt.Character
	m1.FilterDescendantsInstances = i1 and { i1 } or {}
	local b1 = math.clamp(
		math.max(f1 or 0.016666666666666666, 0.011111111111111112),
		0.011111111111111112,
		0.06666666666666667
	)
	local f1 = math.clamp(math.max(V1.Size.X, V1.Size.Z) * 0.5, 0.78, 0.92)
	local p1 = 0.09 + math.max(tonumber(J1) or 0, 0)
	local J1 = false
	local M1 = nil
	local g1 = math.huge
	local H1 = false
	local F1 = G1.Magnitude * b1
	local F1, R1 = s1()
	if F1 and a1 then
		a1(V1, R1)
	end

	for F1 = 1, 3 do
		if G1.Magnitude < 0.02 then
			break
		end

		local F1 = G1.Magnitude * b1
		local R1 = G1.Unit * (F1 + p1)
		local I1 = nil
		local k1 = pcall(function()
			I1 = workspace:Spherecast(V1.Position, f1, R1, m1)
		end)
		if not k1 then
			I1 = workspace:Raycast(V1.Position, G1.Unit * (F1 + f1 + p1), m1)
		end

		if not I1 then
			break
		end

		local f1 = i1 and i1:FindFirstChildOfClass("Humanoid")
		local i1 = f1 and f1.MaxSlopeAngle or 45
		local F1 = math.cos(math.rad(math.clamp(i1, 0, 89)))
		if I1.Normal.Y >= F1 then
			local i1 = f1 and f1.FloorMaterial == Enum.Material.Air
			local f1 = V1.Position.Y - V1.Size.Y * 0.5
			if i1 and I1.Position.Y > f1 + 0.15 and G1.Magnitude > 26 then
				G1 = G1.Unit * 26
				J1 = true
			end

			break
		end

		local f1, i1 = s1()
		if f1 then
			if a1 then
				a1(V1, i1)
			end

			break
		end

		local s1 = Vector3.new(I1.Normal.X, 0, I1.Normal.Z)
		if s1.Magnitude < 0.05 and I1.Position then
			local f1 = V1.Position - I1.Position
			s1 = Vector3.new(f1.X, 0, f1.Z)
		end

		if s1.Magnitude < 0.05 then
			J1 = true
			H1 = true
			G1 = Vector3.zero
			break
		end

		s1 = s1.Unit
		local V1 = G1:Dot(s1)
		if V1 >= 0 then
			break
		end

		J1 = true
		if M1 and M1:Dot(s1) < 0.55 then
			H1 = true
			G1 = Vector3.zero
			break
		end

		M1 = M1 or s1
		local f1 = G1 - s1 * V1
		local i1 = math.max((I1.Distance or 0) - p1, 0)
		if i1 < g1 then
			g1 = i1
		end

		local F1 = (I1.Distance or 0) <= p1 * 0.5
		if F1 then
			G1 = f1
		else
			local p1 = math.min(-V1 * 0.1, i1 / b1)
			G1 = f1 - s1 * p1
		end
	end

	if G1.Magnitude < 0.04 then
		G1 = Vector3.zero
	end

	if G1.Magnitude > _1 then
		G1 = G1.Unit * _1
	end

	return G1, J1, H1, M1, g1
end

local s1 = setmetatable({}, { __mode = "k" })
local function V1(_1)
	if not (_1 and _1.Parent) then
		return false
	end

	local f1 = _1.Parent
	if f1 ~= Rt.Character or s1[f1] then
		return false
	end

	local _1 = f1:FindFirstChildOfClass("Humanoid")
	return _1 ~= nil and _1.Health > 0 and _1:GetState() ~= Enum.HumanoidStateType.Dead
end

local function _1(f1)
	if not f1 or s1[f1] then
		return
	end

	s1[f1] = true
	for s1, s1 in ipairs(f1:GetDescendants()) do
		local f1 = s1.Name:sub(1, 7) == "Vampire" or s1.Name:sub(1, 4) == "WAVE"
		if s1:IsA("LinearVelocity") and f1 then
			pcall(function()
				s1.Enabled = false
			end)
			pcall(function()
				s1.VectorVelocity = Vector3.zero
			end)
			pcall(function()
				s1.PlaneVelocity = Vector2.zero
			end)
			pcall(function()
				s1.LineVelocity = 0
			end)
			pcall(function()
				s1:Destroy()
			end)
		elseif s1:IsA("Attachment") and f1 then
			pcall(function()
				s1:Destroy()
			end)
		elseif s1:IsA("BasePart") then
			pcall(function()
				s1.AssemblyLinearVelocity = Vector3.zero
				s1.AssemblyAngularVelocity = Vector3.zero
				s1.Anchored = true
			end)
		end
	end
end

local s1 = setmetatable({}, { __mode = "k" })
local f1 = setmetatable({}, { __mode = "k" })
local function J1(G1, i1)
	if not V1(G1) then
		return nil
	end

	local b1 = f1[G1]
	local p1 = b1 and b1[i1]
	if p1 and p1.attachment.Parent == G1 and p1.velocity.Parent == G1 then
		return p1.velocity
	end

	local p1 = i1 .. "Attachment"
	local M1 = i1 .. "LinearVelocity"
	local g1 = G1:FindFirstChild(p1)
	if not (g1 and g1:IsA("Attachment")) then
		g1 = Instance.new("Attachment")
		g1.Name = p1
		g1.Parent = G1
	end

	local p1 = G1:FindFirstChild(M1)
	if not (p1 and p1:IsA("LinearVelocity")) then
		p1 = Instance.new("LinearVelocity")
		p1.Name = M1
		p1.Parent = G1
	end

	p1.Attachment0 = g1
	p1.RelativeTo = Enum.ActuatorRelativeTo.World
	pcall(function()
		p1.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	end)
	pcall(function()
		p1.ForceLimitsEnabled = false
	end)
	if not b1 then
		b1 = {}
		f1[G1] = b1
	end

	b1[i1] = { attachment = g1, velocity = p1 }
	return p1
end

local function G1(i1, b1, p1)
	local M1 = J1(i1, b1)
	if not M1 then
		return nil
	end

	s1[M1] = nil
	M1.VectorVelocity = p1 or Vector3.zero
	M1.Enabled = true
	return M1
end

local function i1(b1, p1)
	if not b1 then
		return
	end

	local M1 = f1[b1]
	if M1 then
		M1[p1] = nil
	end

	local f1 = b1:FindFirstChild(p1 .. "LinearVelocity")
	if f1 and f1:IsA("LinearVelocity") then
		s1[f1] = nil
		pcall(function()
			f1.Enabled = false
			f1.VectorVelocity = Vector3.zero
			f1.LineVelocity = 0
			f1:Destroy()
		end)
	end

	local f1 = b1:FindFirstChild(p1 .. "Attachment")
	if f1 and f1:IsA("Attachment") then
		pcall(function()
			f1:Destroy()
		end)
	end
end

local function f1(b1, p1, M1, g1)
	local H1 = J1(b1, p1)
	if not H1 then
		return nil
	end

	local F1 = {}
	s1[H1] = F1
	H1.VectorVelocity = M1 or Vector3.zero
	H1.Enabled = true
	task.delay(g1 or 0.1, function()
		if s1[H1] ~= F1 then
			return
		end

		s1[H1] = nil
		if H1.Parent then
			i1(b1, p1)
		end
	end)
	return H1
end

local function b1(p1, M1)
	if not V1(p1) then
		return nil
	end

	local g1 = M1 .. "Attachment"
	local H1 = M1 .. "LinearVelocity"
	local M1 = p1:FindFirstChild(g1)
	if not (M1 and M1:IsA("Attachment")) then
		M1 = Instance.new("Attachment")
		M1.Name = g1
		M1.Parent = p1
	end

	local g1 = p1:FindFirstChild(H1)
	if not (g1 and g1:IsA("LinearVelocity")) then
		g1 = Instance.new("LinearVelocity")
		g1.Name = H1
		g1.Parent = p1
	end

	g1.Attachment0 = M1
	g1.RelativeTo = Enum.ActuatorRelativeTo.World
	g1.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
	g1.LineDirection = Vector3.new(0, 1, 0)
	pcall(function()
		g1.ForceLimitsEnabled = false
	end)
	return g1
end

local function p1(M1, g1, H1, F1)
	local R1 = b1(M1, g1)
	if not R1 then
		return nil
	end

	local I1 = {}
	s1[R1] = I1
	R1.LineVelocity = H1 or 0
	R1.Enabled = true
	task.delay(F1 or 0.1, function()
		if s1[R1] ~= I1 then
			return
		end

		s1[R1] = nil
		if R1.Parent then
			i1(M1, g1)
		end
	end)
	return R1
end

local function s1(M1)
	if not (M1 and M1.Parent) then
		return Vector3.zero
	end

	local g1, H1 = pcall(function()
		return M1:GetVelocityAtPosition(M1.Position)
	end)
	return g1 and H1 or Vector3.zero
end

local M1 = setmetatable({}, { __mode = "k" })
a1 = function(a1, g1)
	if not V1(a1) or type(g1) ~= "number" or g1 <= a1.Position.Y + 0.05 then
		return
	end

	local H1 = tick()
	local F1 = M1[a1]
	if F1 then
		F1.targetY = math.max(F1.targetY, g1)
		F1.expires = math.max(F1.expires, H1 + 0.32)
		return
	end

	local F1 = { targetY = g1, expires = H1 + 0.32 }
	M1[a1] = F1
	task.spawn(function()
		while M1[a1] == F1 and V1(a1) and tick() < F1.expires do
			local g1 = F1.targetY - a1.Position.Y
			if g1 <= 0.05 then
				break
			end

			local H1 = a1.Parent
			m1.FilterDescendantsInstances = { H1 }
			if a1.AssemblyLinearVelocity.Y > 9 then
				break
			end

			if workspace:Raycast(a1.Position, Vector3.new(0, 3.05 + math.min(g1, 2.35), 0), m1) then
				break
			end

			local H1 = b1(a1, "VampireStep")
			if not H1 then
				break
			end

			H1.LineVelocity = math.clamp(g1 * 9, 5, 12)
			H1.Enabled = true
			pt.Heartbeat:Wait()
		end

		if M1[a1] == F1 then
			M1[a1] = nil
		end

		i1(a1, "VampireStep")
	end)
end

batCounterDebounce = false
NORMAL_STRETCH_FOV = 70
W.LOGO_ID = "rbxassetid://14640607134"
W.IMG_BG = "rbxassetid://14640607134"
-- [ /printed ] THEME AND MAIN UI CONFIGURATION
local a1 = {
	idle1 = "rbxassetid://133806214992291",
	idle2 = "rbxassetid://94970088341563",
	walk = "rbxassetid://707897309",
	run = "rbxassetid://707861613",
	jump = "rbxassetid://116936326516985",
	fall = "rbxassetid://116936326516985",
	climb = "rbxassetid://116936326516985",
	swim = "rbxassetid://116936326516985",
	swimidle = "rbxassetid://116936326516985",
}
local b1 = {
	["Tryhard"] = a1,
	["Adidas Community"] = {
		idle1 = "rbxassetid://122257458498464",
		idle2 = "rbxassetid://102357151005774",
		walk = "rbxassetid://122150855457006",
		run = "rbxassetid://82598234841035",
		jump = "rbxassetid://75290611992385",
		fall = "rbxassetid://98600215928904",
		climb = "rbxassetid://88763136693023",
		swim = "rbxassetid://133308483266208",
		swimidle = "rbxassetid://109346520324160",
	},
	["Vampire"] = {
		idle1 = "rbxassetid://10921315373",
		idle2 = "rbxassetid://10921315373",
		walk = "rbxassetid://10921326949",
		run = "rbxassetid://10921320299",
		jump = "rbxassetid://10921322186",
		fall = "rbxassetid://10921321317",
		climb = "rbxassetid://10921314188",
		swim = "rbxassetid://10921324408",
		swimidle = "rbxassetid://10921325443",
	},
	["Catwalk Glam"] = {
		idle1 = "rbxassetid://133806214992291",
		idle2 = "rbxassetid://94970088341563",
		walk = "rbxassetid://109168724482748",
		run = "rbxassetid://81024476153754",
		jump = "rbxassetid://116936326516985",
		fall = "rbxassetid://92294537340807",
		climb = "rbxassetid://119377220967554",
		swim = "rbxassetid://134591743181628",
		swimidle = "rbxassetid://98854111361360",
	},
	["Astronaut"] = {
		idle1 = "rbxassetid://10921034824",
		idle2 = "rbxassetid://10921036806",
		walk = "rbxassetid://10921046031",
		run = "rbxassetid://10921039308",
		jump = "rbxassetid://10921042494",
		fall = "rbxassetid://10921040576",
		climb = "rbxassetid://10921032124",
		swim = "rbxassetid://10921044000",
		swimidle = "rbxassetid://10921045006",
	},
	["Elder"] = {
		idle1 = "rbxassetid://10921101664",
		idle2 = "rbxassetid://10921102574",
		walk = "rbxassetid://10921111375",
		run = "rbxassetid://10921104374",
		jump = "rbxassetid://10921107367",
		fall = "rbxassetid://10921105765",
		climb = "rbxassetid://10921100400",
		swim = "rbxassetid://10921108971",
		swimidle = "rbxassetid://10921110146",
	},
	["Mage"] = {
		idle1 = "rbxassetid://10921144709",
		idle2 = "rbxassetid://10921145797",
		walk = "rbxassetid://10921152678",
		run = "rbxassetid://10921148209",
		jump = "rbxassetid://10921149743",
		fall = "rbxassetid://10921148939",
		climb = "rbxassetid://10921143404",
		swim = "rbxassetid://10921150788",
		swimidle = "rbxassetid://10921151661",
	},
	["Amazon Unboxed"] = {
		idle1 = "rbxassetid://98281136301627",
		idle2 = "rbxassetid://98281136301627",
		walk = "rbxassetid://90478085024465",
		run = "rbxassetid://134824450619865",
		jump = "rbxassetid://121454505477205",
		fall = "rbxassetid://94788218468396",
		climb = "rbxassetid://121145883950231",
		swim = "rbxassetid://105962919001086",
		swimidle = "rbxassetid://129126268464847",
	},
}
local M1 =
	{ "None", "Tryhard", "Adidas Community", "Vampire", "Catwalk Glam", "Astronaut", "Elder", "Mage", "Amazon Unboxed" }
local g1 = nil
local H1 = nil
local F1 = nil
do
	local function R1(I1)
		if not I1 then
			return false
		end

		for k1, k1 in pairs(a1) do
			if k1 == I1 then
				return true
			end
		end

		return false
	end

	local function I1(k1)
		local C1 = k1:FindFirstChild("Animate")
		if not C1 then
			return
		end

		local function k1(P1)
			return P1 and P1.AnimationId or nil
		end

		local P1 = {
			idle1 = k1(C1.idle and C1.idle.Animation1),
			idle2 = k1(C1.idle and C1.idle.Animation2),
			walk = k1(C1.walk and C1.walk.WalkAnim),
			run = k1(C1.run and C1.run.RunAnim),
			jump = k1(C1.jump and C1.jump.JumpAnim),
			fall = k1(C1.fall and C1.fall.FallAnim),
			climb = k1(C1.climb and C1.climb.ClimbAnim),
			swim = k1(C1.swim and C1.swim.Swim),
			swimidle = k1(C1.swimidle and C1.swimidle.SwimIdle),
		}
		if not R1(P1.walk) then
			H1 = P1
		end
	end

	local function R1(k1)
		local C1 = k1:FindFirstChild("Animate")
		if not C1 then
			return
		end

		local function k1(P1, h1)
			if P1 then
				P1.AnimationId = h1
			end
		end

		k1(C1.idle and C1.idle.Animation1, a1.idle1)
		k1(C1.idle and C1.idle.Animation2, a1.idle2)
		k1(C1.walk and C1.walk.WalkAnim, a1.walk)
		k1(C1.run and C1.run.RunAnim, a1.run)
		k1(C1.jump and C1.jump.JumpAnim, a1.jump)
		k1(C1.fall and C1.fall.FallAnim, a1.fall)
		k1(C1.climb and C1.climb.ClimbAnim, a1.climb)
		k1(C1.swim and C1.swim.Swim, a1.swim)
		k1(C1.swimidle and C1.swimidle.SwimIdle, a1.swimidle)
	end

	local function a1(k1)
		if not H1 then
			return
		end

		local C1 = k1:FindFirstChild("Animate")
		if not C1 then
			return
		end

		local function P1(h1, l1)
			if h1 and l1 then
				h1.AnimationId = l1
			end
		end

		P1(C1.idle and C1.idle.Animation1, H1.idle1)
		P1(C1.idle and C1.idle.Animation2, H1.idle2)
		P1(C1.walk and C1.walk.WalkAnim, H1.walk)
		P1(C1.run and C1.run.RunAnim, H1.run)
		P1(C1.jump and C1.jump.JumpAnim, H1.jump)
		P1(C1.fall and C1.fall.FallAnim, H1.fall)
		P1(C1.climb and C1.climb.ClimbAnim, H1.climb)
		P1(C1.swim and C1.swim.Swim, H1.swim)
		P1(C1.swimidle and C1.swimidle.SwimIdle, H1.swimidle)
		local C1 = k1:FindFirstChildOfClass("Humanoid")
		if C1 then
			for k1, k1 in ipairs(C1:GetPlayingAnimationTracks()) do
				k1:Stop(0)
			end

			C1:ChangeState(Enum.HumanoidStateType.Running)
		end
	end

	startUnwalk = function()
		if zt.unwalkEnabled then
			return
		end

		zt.unwalkEnabled = true
		local k1 = Rt.Character
		if not k1 then
			return
		end

		local C1 = k1:FindFirstChildOfClass("Humanoid")
		if C1 then
			for P1, P1 in ipairs(C1:GetPlayingAnimationTracks()) do
				P1:Stop()
			end
		end

		local C1 = k1:FindFirstChild("Animate")
		if C1 then
			g1 = C1:Clone()
			C1:Destroy()
		end
	end

	stopUnwalk = function()
		if not zt.unwalkEnabled then
			return
		end

		zt.unwalkEnabled = false
		local k1 = Rt.Character
		if k1 and g1 then
			g1.Parent = k1
			g1.Disabled = false
			g1 = nil
		end

		task.spawn(function()
			task.wait(0.15)
			local g1 = Rt.Character
			if not g1 then
				return
			end

			if zt.animEnabled then
				I1(g1)
				R1(g1)
			else
				a1(g1)
			end
		end)
	end

	local g1 = Color3.fromRGB(64, 64, 64)
	local function k1(C1)
		local P1 = C1:FindFirstChild("face")
		if P1 then
			P1:Destroy()
		end
	end

	applyHeadlessToChar = function(C1, P1)
		if not C1 then
			return
		end

		local h1 = C1:FindFirstChild("Head")
		if not h1 then
			return
		end

		if P1 then
			h1.Transparency = 1
			h1.CanCollide = false
			k1(h1)
			if h1:FindFirstChild("HeadlessMesh") then
				return
			end

			for C1, C1 in ipairs(h1:GetChildren()) do
				if C1:IsA("SpecialMesh") and C1.MeshId == "rbxassetid://1095708" then
					C1:Destroy()
				end
			end

			local C1 = Instance.new("SpecialMesh")
			C1.MeshType = Enum.MeshType.FileMesh
			C1.MeshId = "rbxassetid://1095708"
			C1.Scale = Vector3.new(0.001, 0.001, 0.001)
			C1.Name = "HeadlessMesh"
			C1.Parent = h1
			h1:GetPropertyChangedSignal("Transparency"):Connect(function()
				if zt.headlessEnabled and h1.Transparency ~= 1 then
					h1.Transparency = 1
				end
			end)
			h1.ChildAdded:Connect(function(C1)
				if zt.headlessEnabled and C1.Name == "face" and C1:IsA("Decal") then
					C1:Destroy()
				end
			end)
		else
			h1.Transparency = 0
			h1.CanCollide = true
			for C1, C1 in ipairs(h1:GetChildren()) do
				if C1:IsA("SpecialMesh") and C1.Name == "HeadlessMesh" then
					C1:Destroy()
				end
			end

			k1(h1)
		end
	end

	applyKorbloxToChar = function(k1, C1)
		if not k1 then
			return
		end

		local P1 = k1:FindFirstChildOfClass("Humanoid")
		if not P1 then
			return
		end

		if C1 then
			if P1.RigType == Enum.HumanoidRigType.R6 then
				local C1 = k1:FindFirstChild("Right Leg")
				if C1 then
					if C1:FindFirstChild("KorbloxMesh") then
						return
					end

					for h1, h1 in ipairs(C1:GetChildren()) do
						if h1:IsA("SpecialMesh") or h1:IsA("CharacterMesh") then
							h1:Destroy()
						end
					end

					C1.Color = g1
					C1:GetPropertyChangedSignal("Color"):Connect(function()
						if zt.korbloxEnabled and C1.Color ~= g1 then
							C1.Color = g1
						end
					end)
					local h1 = Instance.new("SpecialMesh")
					h1.MeshType = Enum.MeshType.FileMesh
					h1.MeshId = "rbxassetid://101851696"
					h1.TextureId = "rbxassetid://101851254"
					h1.Scale = Vector3.new(1, 1, 1)
					h1.Name = "KorbloxMesh"
					h1.Parent = C1
				end
			elseif P1.RigType == Enum.HumanoidRigType.R15 then
				local C1 = k1:FindFirstChild("RightUpperLeg")
				if C1 then
					if k1:FindFirstChild("KorbloxLeg") then
						return
					end

					C1.Transparency = 1
					local h1 = k1:FindFirstChild("RightLowerLeg")
					local l1 = k1:FindFirstChild("RightFoot")
					if h1 then
						h1.Transparency = 1
					end

					if l1 then
						l1.Transparency = 1
					end

					local h1 = k1:FindFirstChild("KorbloxLeg")
					if h1 then
						h1:Destroy()
					end

					local h1 = Instance.new("Part")
					h1.Name = "KorbloxLeg"
					h1.Size = Vector3.new(1, 2, 1)
					h1.Anchored = false
					h1.CanCollide = false
					h1.Color = g1
					h1.Parent = k1
					local g1 = Instance.new("SpecialMesh")
					g1.MeshType = Enum.MeshType.FileMesh
					g1.MeshId = "rbxassetid://101851696"
					g1.TextureId = "rbxassetid://101851254"
					g1.Scale = Vector3.new(1, 1, 1)
					g1.Name = "KorbloxMesh"
					g1.Parent = h1
					local g1 = Instance.new("Weld")
					g1.Part0 = C1
					g1.Part1 = h1
					g1.C0 = CFrame.new(0, -0.8, 0)
					g1.Name = "KorbloxWeld"
					g1.Parent = h1
				end
			end
		else
			if P1.RigType == Enum.HumanoidRigType.R6 then
				local g1 = k1:FindFirstChild("Right Leg")
				if g1 then
					for C1, C1 in ipairs(g1:GetChildren()) do
						if C1:IsA("SpecialMesh") and C1.Name == "KorbloxMesh" then
							C1:Destroy()
						end
					end

					g1.Color = Color3.fromRGB(255, 255, 255)
				end
			elseif P1.RigType == Enum.HumanoidRigType.R15 then
				local g1 = k1:FindFirstChild("RightUpperLeg")
				if g1 then
					g1.Transparency = 0
					local g1 = k1:FindFirstChild("RightLowerLeg")
					local C1 = k1:FindFirstChild("RightFoot")
					if g1 then
						g1.Transparency = 0
					end

					if C1 then
						C1.Transparency = 0
					end

					local g1 = k1:FindFirstChild("KorbloxLeg")
					if g1 then
						g1:Destroy()
					end
				end
			end
		end
	end

	applyCharterToChar = function(g1)
		if not g1 then
			return
		end

		applyHeadlessToChar(g1, zt.headlessEnabled)
		applyKorbloxToChar(g1, zt.korbloxEnabled)
	end

	startAnim = function()
		if zt.animEnabled then
			return
		end

		zt.animEnabled = true
		if F1 then
			F1:Disconnect()
			F1 = nil
		end

		local g1 = Rt.Character
		if g1 then
			I1(g1)
			R1(g1)
			local k1 = g1:FindFirstChildOfClass("Humanoid")
			if k1 then
				for g1, g1 in ipairs(k1:GetPlayingAnimationTracks()) do
					g1:Stop(0)
				end

				k1:ChangeState(Enum.HumanoidStateType.Running)
			end
		end

		local g1 = 0
		F1 = game:GetService("RunService").Heartbeat:Connect(function(k1)
			if not zt.animEnabled then
				return
			end

			g1 = g1 + (k1 or 0)
			if g1 < (Mt.TouchEnabled and not Mt.KeyboardEnabled and 0.75 or 0.35) then
				return
			end

			g1 = 0
			local g1 = Rt.Character
			if g1 then
				R1(g1)
			end
		end)
	end

	stopAnim = function()
		if not zt.animEnabled then
			return
		end

		zt.animEnabled = false
		if F1 then
			F1:Disconnect()
			F1 = nil
		end

		local g1 = Rt.Character
		if g1 then
			a1(g1)
		end
	end

	local function g1(R1)
		local k1 = b1[zt.selectedAnim]
		if not k1 then
			return
		end

		local C1 = R1:FindFirstChild("Animate")
		if not C1 then
			return
		end

		local function R1(P1, h1)
			if P1 and h1 then
				P1.AnimationId = h1
			end
		end

		R1(C1.idle and C1.idle.Animation1, k1.idle1)
		R1(C1.idle and C1.idle.Animation2, k1.idle2)
		R1(C1.walk and C1.walk.WalkAnim, k1.walk)
		R1(C1.run and C1.run.RunAnim, k1.run)
		R1(C1.jump and C1.jump.JumpAnim, k1.jump)
		R1(C1.fall and C1.fall.FallAnim, k1.fall)
		R1(C1.climb and C1.climb.ClimbAnim, k1.climb)
		R1(C1.swim and C1.swim.Swim, k1.swim)
		R1(C1.swimidle and C1.swimidle.SwimIdle, k1.swimidle)
	end

	setSelectedAnim = function(R1)
		zt.selectedAnim = R1
		local k1 = Rt.Character
		if R1 == "None" then
			zt.animEnabled = false
			if F1 then
				F1:Disconnect()
				F1 = nil
			end

			if k1 then
				a1(k1)
			end

			return
		end

		zt.animEnabled = true
		if F1 then
			F1:Disconnect()
			F1 = nil
		end

		if k1 then
			I1(k1)
			g1(k1)
			local a1 = k1:FindFirstChildOfClass("Humanoid")
			if a1 then
				for R1, R1 in ipairs(a1:GetPlayingAnimationTracks()) do
					R1:Stop(0)
				end

				a1:ChangeState(Enum.HumanoidStateType.Running)
			end
		end

		local a1 = 0
		F1 = game:GetService("RunService").Heartbeat:Connect(function(F1)
			if not zt.animEnabled then
				return
			end

			a1 = a1 + (F1 or 0)
			if a1 < (Mt.TouchEnabled and not Mt.KeyboardEnabled and 0.75 or 0.35) then
				return
			end

			a1 = 0
			local a1 = Rt.Character
			if a1 then
				g1(a1)
			end
		end)
	end
end

for a1, a1 in pairs({ "VAMPIRE HUB", "VampireHub", "VHub" }) do
	local g1 = game:GetService("CoreGui"):FindFirstChild(a1)
	if g1 then
		g1:Destroy()
	end
end

if _G._VH_ESP and _G._VH_ESP.cleanup then
	pcall(_G._VH_ESP.cleanup)
end

local a1 = {
	void = Color3.fromRGB(0, 0, 0),
	ink = Color3.fromRGB(0, 0, 0),
	card = Color3.fromRGB(0, 0, 0),
	row = Color3.fromRGB(55, 55, 55),
	purple = Color3.fromRGB(220, 45, 45),
	dpurple = Color3.fromRGB(170, 25, 25),
	lpurple = Color3.fromRGB(255, 90, 90),
	white = Color3.fromRGB(245, 245, 245),
	dim = Color3.fromRGB(120, 120, 120),
	gold = Color3.fromRGB(180, 180, 180),
	border = Color3.fromRGB(0, 0, 0),
	on = Color3.fromRGB(220, 45, 45),
	off = Color3.fromRGB(0, 0, 0),
	stkBg = Color3.fromRGB(18, 4, 4),
	stkBrd = Color3.fromRGB(80, 22, 22),
	stkAct = Color3.fromRGB(132, 20, 20),
}
local g1 = {}
do
	tw = function(F1, R1, I1, k1, C1)
		gt:Create(F1, TweenInfo.new(R1, k1 or Enum.EasingStyle.Quad, C1 or Enum.EasingDirection.Out), I1):Play()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "VampireHub"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
	if not pcall(function()
		gui.Parent = game:GetService("CoreGui")
	end) then
		gui.Parent = Rt:WaitForChild("PlayerGui")
	end

	root = Instance.new("CanvasGroup", gui)
	root.Name = "VampireHub_Root"
	root.Size = UDim2.new(0, 448, 0, 538)
	root.Position = UDim2.new(0, 20, 0, 20)
	root.Visible = false
	root.BackgroundColor3 = a1.ink
	root.BackgroundTransparency = 0
	root.BorderSizePixel = 0
	-- /printed branding is placed in the dedicated screen-corner overlay below.
	root.Active = true
	root.Active = true
	Instance.new("UICorner", root).CornerRadius = UDim.new(0, 40)
	local F1 = Instance.new("UIScale", root)
	F1.Scale = zt.guiScale
	makeDraggable = function(R1, I1, k1)
		local k1, C1, P1, h1 = false, nil, nil, nil
		local l1, D1
		R1.InputBegan:Connect(function(D1)
			if
				D1.UserInputType == Enum.UserInputType.MouseButton1
				or D1.UserInputType == Enum.UserInputType.MouseButton2
			then
				k1 = true
				P1 = D1.Position
				h1 = R1.Position
				if I1 then
					l1 = I1.Position
				end

				D1.Changed:Connect(function()
					if D1.UserInputState == Enum.UserInputState.End then
						k1 = false
					end
				end)
			end
		end)
		R1.InputChanged:Connect(function(D1)
			if D1.UserInputType == Enum.UserInputType.Touch or D1.UserInputType == Enum.UserInputType.MouseButton2 then
				C1 = D1
			end
		end)
		Mt.InputChanged:Connect(function(D1)
			if D1 == C1 and k1 then
				local k1 = D1.Position.X - P1.X
				local C1 = D1.Position.Y - P1.Y
				R1.Position = UDim2.new(h1.X.Scale, h1.X.Offset + k1, h1.Y.Scale, h1.Y.Offset + C1)
				if I1 and l1 then
					I1.Position = UDim2.new(l1.X.Scale, l1.X.Offset + k1, l1.Y.Scale, l1.Y.Offset + C1)
				end
			end
		end)
	end

	makeDraggable(root, nil, true)
	local R1
	local I1 = Instance.new("Frame", root)
	I1.Size = UDim2.new(0, 178, 1, 0)
	I1.Position = UDim2.new(0, 0, 0, 0)
	I1.BackgroundColor3 = a1.ink
	I1.BackgroundTransparency = 1
	I1.BorderSizePixel = 0
	I1.Active = true
	I1.ZIndex = 1
	Instance.new("UICorner", I1).CornerRadius = UDim.new(0, 40)
	do
		local k1 = Instance.new("Frame", I1)
		k1.Size = UDim2.new(0, 40, 1, 0)
		k1.Position = UDim2.new(1, -40.0, 0, 0)
		k1.BackgroundColor3 = a1.ink
		k1.BorderSizePixel = 0
		k1.ZIndex = 1
		Instance.new("UICorner", k1).CornerRadius = UDim.new(0, 40)
		R1 = Instance.new("ImageLabel", I1)
		R1.Size = UDim2.new(1, 0, 1, 0)
		R1.AnchorPoint = Vector2.new(0.5, 0.5)
		R1.Position = UDim2.new(0.5, 0, 0.5, 0)
		R1.BackgroundTransparency = 1
		R1.Image = W.IMG_BG
		R1.ScaleType = Enum.ScaleType.Crop
		R1.ImageTransparency = 0
		R1.ZIndex = 1
		R1.BorderSizePixel = 0
		R1.Active = true
		Instance.new("UICorner", R1).CornerRadius = UDim.new(0, 40)
		local l = Instance.new("Frame", I1)
		l.Size = UDim2.new(0.55, 0, 1, 0)
		l.Position = UDim2.new(0.45, 0, 0, 0)
		l.BackgroundColor3 = a1.void
		l.BorderSizePixel = 0
		l.ZIndex = 2
		local k1 = Instance.new("UIGradient", l)
		k1.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
		})
		k1.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		local l = Instance.new("Frame", I1)
		l.Size = UDim2.new(1, 0, 0.4, 0)
		l.Position = UDim2.new(0, 0, 0.6, 0)
		l.BackgroundColor3 = a1.void
		l.BorderSizePixel = 0
		l.ZIndex = 2
		Instance.new("UICorner", l).CornerRadius = UDim.new(0, 40)
		local k1 = Instance.new("UIGradient", l)
		k1.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15) })
		k1.Rotation = 90
		local l = Instance.new("TextLabel", I1)
		l.Size = UDim2.new(1, -8.0, 0, 22)
		l.Position = UDim2.new(0, 16, 1, -46.0)
		l.BackgroundTransparency = 1
		l.Text = "Vampire Hub"
		l.TextColor3 = a1.white
		l.Font = Enum.Font.Gotham
		l.TextSize = 12
		l.TextStrokeTransparency = 0
		l.ZIndex = 3
		local l = Instance.new("Frame", I1)
		l.Size = UDim2.new(0, 95, 0, 2)
		l.Position = UDim2.new(0, 16, 1, -26.0)
		l.BackgroundColor3 = a1.purple
		l.BorderSizePixel = 0
		l.ZIndex = 3
		local k1 = Instance.new("UIGradient", l)
		k1.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, a1.dpurple),
			ColorSequenceKeypoint.new(0.6, a1.lpurple),
			ColorSequenceKeypoint.new(1, a1.dpurple),
		})
		local l = Instance.new("TextLabel", I1)
		l.Size = UDim2.new(1, -8.0, 0, 14)
		l.Position = UDim2.new(0, 16, 1, -24.0)
		l.BackgroundTransparency = 1
		l.Text = "LEAKED BY /printed  •  NUMBER 1"
		l.TextColor3 = a1.dim
		l.Font = Enum.Font.GothamMedium
		l.TextSize = 8
		l.TextStrokeTransparency = 0
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.ZIndex = 3
		local l = Instance.new("Frame", I1)
		l.Size = UDim2.new(1, -12.0, 0, 20)
		l.Position = UDim2.new(0, 6, 0, 6)
		l.BackgroundColor3 = a1.void
		l.BackgroundTransparency = 0.45
		l.BorderSizePixel = 0
		l.ZIndex = 3
		l.Visible = false
		Instance.new("UICorner", l).CornerRadius = UDim.new(0, 7)
		statsLbl = Instance.new("TextLabel", l)
		statsLbl.Size = UDim2.new(1, -8.0, 1, 0)
		statsLbl.Position = UDim2.new(0, 4, 0, 0)
		statsLbl.BackgroundTransparency = 1
		statsLbl.Text = "FPS: -- | PING: --"
		statsLbl.TextColor3 = a1.purple
		statsLbl.Font = Enum.Font.GothamBold
		statsLbl.TextSize = 10
		statsLbl.TextStrokeTransparency = 0
		statsLbl.TextTransparency = 0.6
		statsLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		statsLbl.ZIndex = 4
	end

	ctrl = Instance.new("Frame", root)
	ctrl.Size = UDim2.new(0, 270, 1, 0)
	ctrl.Position = UDim2.new(0, 178, 0, 0)
	ctrl.BackgroundColor3 = a1.card
	ctrl.BackgroundTransparency = 0.05
	ctrl.BorderSizePixel = 0
	ctrl.Active = true
	Instance.new("UICorner", ctrl).CornerRadius = UDim.new(0, 40)
	local l = Instance.new("Frame", ctrl)
	l.Size = UDim2.new(0, 40, 1, 0)
	l.Position = UDim2.new(0, 0, 0, 0)
	l.BackgroundColor3 = a1.card
	l.BackgroundTransparency = 0.05
	l.BorderSizePixel = 0
	l.ZIndex = 0
	local l = { "Main", "Move", "Custom", "Config" }
	local k1 = {}
	local C1 = nil
	tabStack = Instance.new("Frame", I1)
	tabStack.Size = UDim2.new(0, 118, 0, 280)
	tabStack.Position = UDim2.new(1, -122.0, 0.5, -150.0)
	tabStack.BackgroundTransparency = 1
	tabStack.BorderSizePixel = 0
	tabStack.ZIndex = 8
	local I1 = Instance.new("UIListLayout", tabStack)
	I1.FillDirection = Enum.FillDirection.Vertical
	I1.SortOrder = Enum.SortOrder.LayoutOrder
	I1.HorizontalAlignment = Enum.HorizontalAlignment.Right
	I1.Padding = UDim.new(0, 32)
	pageHost = Instance.new("Frame", ctrl)
	pageHost.Size = UDim2.new(1, 0, 1, -52.0)
	pageHost.Position = UDim2.new(0, 0, 0, 12)
	pageHost.BackgroundTransparency = 1
	pageHost.BorderSizePixel = 0
	pageHost.Active = true
	pageHost.ZIndex = 4
	local function I1()
		local P1 = Instance.new("ScrollingFrame", pageHost)
		P1.Size = UDim2.new(1, 0, 1, 0)
		P1.BackgroundTransparency = 1
		P1.BorderSizePixel = 0
		P1.ScrollBarThickness = 0
		P1.ScrollBarImageColor3 = a1.purple
		P1.ScrollBarImageTransparency = 1
		P1.AutomaticCanvasSize = Enum.AutomaticSize.Y
		P1.CanvasSize = UDim2.new(0, 0, 0, 0)
		P1.Visible = false
		P1.ZIndex = 4
		local h1 = Instance.new("UIListLayout", P1)
		h1.SortOrder = Enum.SortOrder.LayoutOrder
		h1.Padding = UDim.new(0, 4)
		local h1 = Instance.new("UIPadding", P1)
		h1.PaddingLeft = UDim.new(0, 10)
		h1.PaddingRight = UDim.new(0, 16)
		h1.PaddingTop = UDim.new(0, 10)
		h1.PaddingBottom = UDim.new(0, 52)
		return P1
	end

	local P1 = {}
	for h1, h1 in ipairs(l) do
		P1[h1] = I1()
	end

	local function I1(h1)
		if C1 then
			C1.Visible = false
		end

		C1 = P1[h1]
		C1.Visible = true
		for l1, D1 in pairs(k1) do
			if l1 == h1 then
				tw(D1, 0.15, { BackgroundColor3 = a1.purple, BackgroundTransparency = 0.25 })
				D1.TextColor3 = a1.void
				local h1 = D1:FindFirstChildOfClass("UIStroke")
				if h1 then
					tw(h1, 0.15, { Color = a1.purple })
				end
			else
				tw(D1, 0.15, { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.4 })
				D1.TextColor3 = a1.white
				local h1 = D1:FindFirstChildOfClass("UIStroke")
				if h1 then
					tw(h1, 0.15, { Color = a1.border })
				end
			end
		end
	end

	g1 = {}
	local function h1(l1)
		if not P1 then
			return false
		end

		for D1, D1 in pairs(P1) do
			if l1:IsDescendantOf(D1) then
				return D1 ~= C1
			end
		end

		return false
	end

	pcall(function()
		game:GetService("ContextActionService"):BindActionAtPriority("VH_GlobalTap", function(l1, l1, D1)
			if l1 ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end

			local l1, z1 = D1.Position.X, D1.Position.Y
			local D1 = false
			if root and root.Visible then
				local v1 = root.AbsolutePosition
				local q1 = root.AbsoluteSize
				D1 = (l1 >= v1.X and l1 <= v1.X + q1.X and z1 >= v1.Y and z1 <= v1.Y + q1.Y)
			end

			for v1, v1 in ipairs(g1) do
				if not v1.cd and not v1.ibFired and v1.btn.AbsoluteSize.X > 0 and not h1(v1.btn) then
					if D1 and not v1.btn:IsDescendantOf(root) then
					else
						local D1 = v1.btn.AbsolutePosition
						local q1 = v1.btn.AbsoluteSize
						if l1 >= D1.X and l1 <= D1.X + q1.X and z1 >= D1.Y and z1 <= D1.Y + q1.Y then
							if v1.fire then
								task.spawn(v1.fire)
							end
						end
					end
				end
			end

			return Enum.ContextActionResult.Pass
		end, false, 2001, Enum.UserInputType.MouseButton2)
	end)
	local function P(l1)
		if not l1 then
			return
		end

		local D1, z1 = pcall(function()
			return l1:IsA("GuiObject")
		end)
		if not D1 or not z1 then
			return
		end

		local D1, z1 = pcall(function()
			return l1.Text
		end)
		if l1.BackgroundTransparency >= 1 and (not D1 or z1 == nil or z1 == "") then
			return
		end

		local D1 = l1:FindFirstChild("VHPop")
		if not D1 then
			D1 = Instance.new("UIScale")
			D1.Name = "VHPop"
			D1.Parent = l1
		end

		D1.Scale = 0.93
		tw(D1, 0.13, { Scale = 1 }, Enum.EasingStyle.Quad)
	end

	local function l1(D1, z1)
		local v1 = { btn = D1, cb = z1, cd = false, ibFired = false }
		local function q1()
			if v1.cd then
				return
			end

			if h1(D1) then
				return
			end

			if not (D1 and D1.Parent) then
				return
			end

			if D1.AbsoluteSize.X <= 0 or D1.AbsoluteSize.Y <= 0 then
				return
			end

			v1.cd = true
			task.delay(0.1, function()
				v1.cd = false
				v1.ibFired = false
			end)
			P(D1)
			local callbackSucceeded, callbackError = pcall(z1)
			if not callbackSucceeded then
				warn("[VampireHub] control callback error:", callbackError)
			end
		end

		v1.fire = q1
		table.insert(g1, v1)
		if D1:IsA("GuiButton") then
			D1.Activated:Connect(q1)
		end

		local P = false
		D1.InputBegan:Connect(function(h1)
			if
				h1.UserInputType == Enum.UserInputType.MouseButton1
				or h1.UserInputType == Enum.UserInputType.MouseButton2
			then
				local z1 = D1.AbsolutePosition
				local Z1 = D1.AbsoluteSize
				local E1, r1 = h1.Position.X, h1.Position.Y
				if E1 >= z1.X and E1 <= z1.X + Z1.X and r1 >= z1.Y and r1 <= z1.Y + Z1.Y then
					P = true
				end
			end
		end)
		D1.InputEnded:Connect(function(h1)
			if
				h1.UserInputType == Enum.UserInputType.MouseButton1
				or h1.UserInputType == Enum.UserInputType.MouseButton2
			then
				if P then
					local z1 = D1.AbsolutePosition
					local Z1 = D1.AbsoluteSize
					local D1, E1 = h1.Position.X, h1.Position.Y
					if D1 >= z1.X and D1 <= z1.X + Z1.X and E1 >= z1.Y and E1 <= z1.Y + Z1.Y then
						v1.ibFired = true
						q1()
					end
				end

				P = false
			end
		end)
	end

	local P = 0
	local h1 = {
		Enum.KeyCode.ButtonA,
		Enum.KeyCode.ButtonB,
		Enum.KeyCode.ButtonX,
		Enum.KeyCode.ButtonY,
		Enum.KeyCode.ButtonL1,
		Enum.KeyCode.ButtonR1,
		Enum.KeyCode.ButtonL2,
		Enum.KeyCode.ButtonR2,
		Enum.KeyCode.ButtonL3,
		Enum.KeyCode.ButtonR3,
		Enum.KeyCode.ButtonSelect,
		Enum.KeyCode.ButtonStart,
		Enum.KeyCode.DPadLeft,
		Enum.KeyCode.DPadRight,
		Enum.KeyCode.DPadUp,
		Enum.KeyCode.DPadDown,
	}
	local function D1(z1, v1)
		P = P + 1
		local q1 = "VH_Bind_" .. P
		local P = true
		local Z1
		local function E1(r1, j1)
			if not P then
				return
			end

			P = false
			if Z1 then
				Z1:Disconnect()
				Z1 = nil
			end

			pcall(function()
				game:GetService("ContextActionService"):UnbindAction(q1)
			end)
			if j1 then
				if v1 then
					v1()
				end
			elseif z1 then
				z1(r1)
			end
		end

		local z1 = tick()
		Z1 = Mt.InputBegan:Connect(function(v1)
			if not P then
				return
			end

			if tick() - z1 < 0.03 then
				return
			end

			if v1.UserInputType == Enum.UserInputType.Keyboard then
				if v1.KeyCode == Enum.KeyCode.Escape then
					E1(nil, true)
				else
					E1(v1.KeyCode, false)
				end
			elseif It(v1.UserInputType) then
				local It = v1.KeyCode
				if It ~= Enum.KeyCode.Thumbstick1 and It ~= Enum.KeyCode.Thumbstick2 then
					E1(It, false)
				end
			end
		end)
		pcall(function()
			game:GetService("ContextActionService"):BindActionAtPriority(q1, function(It, It, z1)
				if P and It == Enum.UserInputState.Begin then
					E1(z1.KeyCode, false)
				end

				return Enum.ContextActionResult.Sink
			end, false, 3000, table.unpack(h1))
		end)
		return function()
			E1(nil, true)
		end
	end

	do
		Mt.TouchStarted:Connect(function(P)
			local It = P.Position
			for P, P in ipairs(g1) do
				if not P.cd and P.btn and P.btn.Parent and P.btn.AbsoluteSize.X > 0 and P.btn.AbsoluteSize.Y > 0 then
					local h1 = P.btn.AbsolutePosition
					local z1 = P.btn.AbsoluteSize
					if It.X >= h1.X and It.X <= h1.X + z1.X and It.Y >= h1.Y and It.Y <= h1.Y + z1.Y then
						if P.fire then
							task.spawn(P.fire)
						end

						break
					end
				end
			end
		end)
	end

	local P = { Main = "Main", Move = "Other", Config = "Config", Custom = "Customization" }
	for It, h1 in ipairs(l) do
		local l = Instance.new("TextButton", tabStack)
		l.Size = UDim2.new(0, 116, 0, 40)
		l.BackgroundColor3 = h1 == "Main" and a1.purple or Color3.fromRGB(0, 0, 0)
		l.BackgroundTransparency = h1 == "Main" and 0.25 or 0.4
		l.BorderSizePixel = 0
		l.Text = P[h1] or h1
		l.TextColor3 = h1 == "Main" and a1.void or a1.white
		l.Font = Enum.Font.GothamBold
		l.TextSize = 12
		l.LayoutOrder = It
		l.ZIndex = 9
		l.RichText = false
		Instance.new("UICorner", l).CornerRadius = UDim.new(0, 10)
		local P = Instance.new("UIStroke", l)
		P.Color = h1 == "Main" and a1.purple or a1.border
		P.Thickness = 1.5
		k1[h1] = l
		l1(l, function()
			I1(h1)
		end)
	end

	C1 = P1.Main
	C1.Visible = true
	local P = { Main = 0, Move = 0, Config = 0, Custom = 0 }
	local function l(It)
		P[It] = P[It] + 1
		return P[It]
	end

	local function P(It, I1)
		local h1 = Instance.new("Frame", P1[It])
		h1.Size = UDim2.new(1, 0, 0, I1 or 5)
		h1.BackgroundTransparency = 1
		h1.BorderSizePixel = 0
		h1.LayoutOrder = l(It)
	end

	local function It(I1, h1)
		local z1 = Instance.new("Frame", P1[I1])
		z1.Size = UDim2.new(1, 0, 0, 23)
		z1.BackgroundTransparency = 1
		z1.BorderSizePixel = 0
		z1.LayoutOrder = l(I1)
		local I1 = Instance.new("Frame", z1)
		I1.Size = UDim2.new(0, 3, 1, 0)
		I1.BackgroundColor3 = a1.purple
		I1.BorderSizePixel = 0
		Instance.new("UICorner", I1).CornerRadius = UDim.new(1, 0)
		local I1 = Instance.new("TextLabel", z1)
		I1.Size = UDim2.new(1, -12.0, 1, 0)
		I1.Position = UDim2.new(0, 10, 0, 0)
		I1.BackgroundTransparency = 1
		I1.Text = h1:upper()
		I1.TextColor3 = a1.lpurple
		I1.Font = Enum.Font.GothamBold
		I1.TextSize = 11
		I1.TextStrokeTransparency = 0
		return I1
	end

	local function I1(h1)
		local z1 = Instance.new("Frame", P1[h1])
		z1.Size = UDim2.new(0.85, 0, 0, 1)
		z1.Position = UDim2.new(0.075, 0, 0, 0)
		z1.BackgroundColor3 = a1.border
		z1.BorderSizePixel = 0
		z1.LayoutOrder = l(h1)
		local h1 = Instance.new("UIGradient", z1)
		h1.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, a1.card),
			ColorSequenceKeypoint.new(0.3, a1.border),
			ColorSequenceKeypoint.new(0.7, a1.border),
			ColorSequenceKeypoint.new(1, a1.card),
		})
	end

	local function h1(z1, v1)
		local q1 = Instance.new("Frame", P1[z1])
		q1.Size = UDim2.new(1, 0, 0, v1 or 38)
		q1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		q1.BackgroundTransparency = 0
		q1.BorderSizePixel = 0
		q1.LayoutOrder = l(z1)
		Instance.new("UICorner", q1).CornerRadius = UDim.new(0, 12)
		local z1 = Instance.new("UIStroke", q1)
		z1.Color = a1.border
		z1.Thickness = 1.5
		q1.MouseEnter:Connect(function()
			tw(q1, 0.1, { BackgroundTransparency = 0 })
			tw(z1, 0.1, { Color = a1.purple })
		end)
		q1.MouseLeave:Connect(function()
			tw(q1, 0.1, { BackgroundTransparency = 0 })
			tw(z1, 0.1, { Color = a1.border })
		end)
		return q1, z1
	end

	local function z1(v1, q1, Z1, E1, r1, j1, e1, T1, N1, K1)
		local c1 = Instance.new("TextLabel", v1)
		c1.Size = UDim2.new(r1 or 0.55, 0, 0, j1 or 42)
		c1.Position = UDim2.new(0, Z1 or 10, 0, E1 or 0)
		c1.BackgroundTransparency = 1
		c1.Text = q1
		c1.TextColor3 = T1 or a1.white
		c1.Font = N1 or Enum.Font.GothamBold
		c1.TextSize = e1 or 11
		c1.TextStrokeTransparency = K1 or 0
		return c1
	end

	local function v1(q1, Z1, E1, r1, j1, e1)
		local T1, N1 = h1(q1, 42)
		z1(T1, Z1, 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local q1 = nil
		if E1 then
			q1 = Instance.new("TextButton", T1)
			q1.Size = UDim2.new(0, 54, 0, 25)
			q1.Position = UDim2.new(1, -130.0, 0.5, -12.5)
			q1.BackgroundColor3 = a1.void
			q1.BorderSizePixel = 0
			q1.Text = E1.Name
			q1.TextColor3 = a1.dim
			q1.Font = Enum.Font.GothamBold
			q1.TextSize = 9
			q1.ZIndex = 5
			Instance.new("UICorner", q1).CornerRadius = UDim.new(0, 7)
			local Z1 = Instance.new("UIStroke", q1)
			Z1.Color = a1.border
			Z1.Thickness = 1.5
			local E1 = false
			local N1
			local function K1()
				tw(Z1, 0.1, { Color = a1.border })
				q1.TextColor3 = a1.dim
			end

			local function c1(A1)
				E1 = false
				if N1 then
					local u1 = N1
					N1 = nil
					u1()
				end

				K1()
				if A1 then
					q1.Text = A1.Name
					if e1 then
						e1(A1)
					end
				end
			end

			local function e1()
				if E1 then
					c1(nil)
					return
				end

				E1 = true
				q1.Text = "..."
				q1.TextColor3 = a1.purple
				tw(Z1, 0.1, { Color = a1.purple })
				N1 = D1(function(Z1)
					N1 = nil
					c1(Z1)
				end, function()
					N1 = nil
					E1 = false
					K1()
				end)
			end

			l1(q1, e1)
		end

		local Z1 = Instance.new("Frame", T1)
		Z1.Size = UDim2.new(0, 47, 0, 23)
		Z1.Position = UDim2.new(1, -67.0, 0.5, -13.0)
		Z1.BackgroundColor3 = r1 and a1.on or a1.off
		Z1.BorderSizePixel = 0
		Z1.ZIndex = 5
		Instance.new("UICorner", Z1).CornerRadius = UDim.new(1, 0)
		local E1 = Instance.new("UIStroke", Z1)
		E1.Color = r1 and a1.purple or a1.border
		E1.Thickness = 1.5
		local e1 = Instance.new("Frame", Z1)
		e1.Size = UDim2.new(0, 18, 0, 18)
		e1.Position = r1 and UDim2.new(1, -23.0, 0.5, -10.0) or UDim2.new(0, 3, 0.5, -9.0)
		e1.BackgroundColor3 = r1 and a1.white or a1.dim
		e1.BorderSizePixel = 0
		e1.ZIndex = 6
		Instance.new("UICorner", e1).CornerRadius = UDim.new(1, 0)
		local N1 = r1 or false
		local function r1(K1)
			N1 = K1
			tw(Z1, 0.16, { BackgroundColor3 = K1 and a1.on or a1.off })
			tw(E1, 0.16, { Color = K1 and a1.purple or a1.border })
			tw(e1, 0.18, {
				Position = K1 and UDim2.new(1, -23.0, 0.5, -10.0) or UDim2.new(0, 3, 0.5, -9.0),
				BackgroundColor3 = K1 and a1.white or a1.dim,
			}, Enum.EasingStyle.Quad)
		end

		local E1 = Instance.new("TextButton", T1)
		E1.Size = UDim2.new(0, 47, 0, 23)
		E1.Position = UDim2.new(1, -67.0, 0.5, -13.0)
		E1.BackgroundTransparency = 1
		E1.Text = ""
		E1.ZIndex = 7
		l1(E1, function()
			N1 = not N1
			r1(N1)
			if j1 then
				pcall(j1, N1)
			end
		end)
		if q1 then
			q1.ZIndex = 6
		end

		Z1.ZIndex = 5
		e1.ZIndex = 6
		return r1, q1, T1
	end

	local function q1(Z1, E1, r1, j1)
		local e1 = h1(Z1, 42)
		z1(e1, E1, 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local Z1 = Instance.new("TextBox", e1)
		Z1.Size = UDim2.new(0, 88, 0, 32)
		Z1.Position = UDim2.new(1, -96.0, 0.5, -16.0)
		Z1.BackgroundColor3 = a1.void
		Z1.BackgroundTransparency = 0
		Z1.BorderSizePixel = 0
		Z1.Text = tostring(r1)
		Z1.TextColor3 = a1.purple
		Z1.Font = Enum.Font.GothamBold
		Z1.TextSize = 12
		Z1.ClearTextOnFocus = true
		Z1.MultiLine = false
		Instance.new("UICorner", Z1).CornerRadius = UDim.new(0, 8)
		local E1 = Instance.new("UIStroke", Z1)
		E1.Color = a1.border
		E1.Thickness = 1.5
		local e1 = tostring(r1)
		Z1.Focused:Connect(function()
			tw(E1, 0.1, { Color = a1.purple })
		end)
		Z1.FocusLost:Connect(function()
			tw(E1, 0.1, { Color = a1.border })
			if j1 then
				local E1 = tonumber(Z1.Text)
				if E1 then
					j1(Z1.Text)
					e1 = Z1.Text
				else
					Z1.Text = e1
				end
			end
		end)
		Z1.TouchTap:Connect(function()
			Z1:CaptureFocus()
		end)
		return Z1
	end

	local function Z1(E1, r1, j1)
		local e1 = h1(E1, 42)
		z1(e1, r1, 10, 0, 0.5, 42, 10, a1.white, Enum.Font.GothamBold)
		local E1 = Instance.new("TextLabel", e1)
		E1.Size = UDim2.new(0.45, -8.0, 1, 0)
		E1.Position = UDim2.new(0.52, 0, 0, 0)
		E1.BackgroundTransparency = 1
		E1.Text = j1
		E1.TextColor3 = a1.purple
		E1.Font = Enum.Font.Gotham
		E1.TextSize = 12
		E1.TextStrokeTransparency = 0
		return E1
	end

	local function E1(r1, j1, e1, T1)
		local N1 = h1(r1, 42)
		z1(N1, j1, 10, 0, 0.55, 42, 10, a1.white, Enum.Font.GothamBold)
		local r1 = Instance.new("TextButton", N1)
		r1.Size = UDim2.new(0, 76, 0, 25)
		r1.Position = UDim2.new(1, -84.0, 0.5, -12.5)
		r1.BackgroundColor3 = a1.void
		r1.BorderSizePixel = 0
		r1.Text = e1.Name
		r1.TextColor3 = a1.lpurple
		r1.Font = Enum.Font.GothamBold
		r1.TextSize = 10
		Instance.new("UICorner", r1).CornerRadius = UDim.new(0, 8)
		local j1 = Instance.new("UIStroke", r1)
		j1.Color = a1.border
		j1.Thickness = 1.5
		local e1 = false
		local N1
		local function K1()
			tw(j1, 0.1, { Color = a1.border })
			r1.TextColor3 = a1.lpurple
		end

		local function c1(A1)
			e1 = false
			if N1 then
				local u1 = N1
				N1 = nil
				u1()
			end

			K1()
			if A1 then
				r1.Text = A1.Name
				if T1 then
					T1(A1)
				end
			end
		end

		local function T1()
			if e1 then
				c1(nil)
				return
			end

			e1 = true
			r1.Text = "..."
			r1.TextColor3 = a1.purple
			tw(j1, 0.1, { Color = a1.purple })
			N1 = D1(function(D1)
				N1 = nil
				c1(D1)
			end, function()
				N1 = nil
				e1 = false
				K1()
			end)
		end

		l1(r1, T1)
		return r1
	end

	_VH_btnTxt = function()
		local D1 = a1.purple
		return D1.R * 0.299 + D1.G * 0.587 + D1.B * 0.114 < 0.35 and Color3.fromRGB(255, 255, 255) or a1.void
	end

	local function D1(r1, j1, e1)
		local T1 = Instance.new("TextButton", P1[r1])
		T1.Size = UDim2.new(1, 0, 0, 42)
		T1.BorderSizePixel = 0
		T1.LayoutOrder = l(r1)
		T1.Text = j1
		T1.TextColor3 = _VH_btnTxt()
		T1.Font = Enum.Font.Gotham
		T1.TextSize = 12
		T1.BackgroundColor3 = a1.purple
		Instance.new("UICorner", T1).CornerRadius = UDim.new(0, 12)
		local r1 = Instance.new("UIGradient", T1)
		r1.Color =
			ColorSequence.new({ ColorSequenceKeypoint.new(0, a1.dpurple), ColorSequenceKeypoint.new(1, a1.purple) })
		r1.Rotation = 90
		l1(T1, function()
			tw(T1, 0.07, { BackgroundColor3 = a1.lpurple })
			task.delay(0.18, function()
				tw(T1, 0.14, { BackgroundColor3 = a1.purple })
			end)
			if e1 then
				pcall(e1)
			end
		end)
		T1.MouseEnter:Connect(function()
			tw(T1, 0.1, { BackgroundColor3 = a1.lpurple })
			T1.TextColor3 = _VH_btnTxt()
		end)
		T1.MouseLeave:Connect(function()
			tw(T1, 0.1, { BackgroundColor3 = a1.purple })
			T1.TextColor3 = _VH_btnTxt()
		end)
		return T1
	end

	task.wait()
	It("Main", "Speed")
	normalBox = q1("Main", "Normal Speed", zt.normalSpeed, function(r1)
		local j1 = tonumber(r1)
		if j1 and j1 > 0 and j1 <= 500 then
			zt.normalSpeed = j1
		end
	end)
	carryBox = q1("Main", "Carry Speed", zt.carrySpeed, function(r1)
		local j1 = tonumber(r1)
		if j1 and j1 > 0 and j1 <= 500 then
			zt.carrySpeed = j1
		end
	end)
	P("Main", 6)
	do
		setBurstPreset = function(r1)
			zt.burstPreset = "lagger"
		end

		local function r1()
			if Bt and Bt.lagger then
				Bt.lagger.setOn(zt.laggerMode == 1)
			end

			if Bt and Bt.laggerCarry then
				Bt.laggerCarry.setOn(zt.laggerMode == 2)
			end

			if Bt and Bt.carrySpeed then
				Bt.carrySpeed.setOn(zt.laggerMode == 0 and zt.speedToggled)
			end
		end

		_VH_speedToNormal = function()
			zt.speedToggled = false
			zt._prevSpeed = false
			zt._prevCarry = zt.carrySpeed
			if zt.laggerMode ~= 0 then
				zt.laggerMode = 0
				zt.carrySpeed = zt._prevCarry or zt.carrySpeed
			end

			if carryBox then
				carryBox.Text = tostring(zt.normalSpeed)
			end

			if modeValLbl then
				modeValLbl.Text = "Normal"
			end

			if Bt then
				if Bt.lagger then
					Bt.lagger.setOn(false)
				end

				if Bt.laggerCarry then
					Bt.laggerCarry.setOn(false)
				end

				if Bt.carrySpeed then
					Bt.carrySpeed.setOn(false)
				end
			end
		end

		setLaggerMode = function(j1)
			if j1 == 1 and zt.safeModeEnabled and zt.speedToggled and _G._VH_hbCached and _G._VH_hbCached() then
				j1 = 2
			end

			if j1 == zt.laggerMode then
				return
			end

			local e1 = zt.laggerMode
			if j1 == 0 then
				zt.carrySpeed = zt._prevCarry or 30
				zt.speedToggled = zt._prevSpeed or false
				if carryBox then
					carryBox.Text = tostring(zt.speedToggled and zt.carrySpeed or zt.normalSpeed)
				end

				if modeValLbl then
					modeValLbl.Text = zt.speedToggled and "Carry" or "Normal"
				end
			elseif j1 == 1 then
				if e1 == 0 then
					zt._prevCarry = zt.carrySpeed
					zt._prevSpeed = zt.speedToggled
				end

				zt.speedToggled = false
				if modeValLbl then
					modeValLbl.Text = "Lagger"
				end

				if carryBox then
					carryBox.Text = tostring(zt.burstNormalSpeed)
				end
			elseif j1 == 2 then
				if e1 == 0 then
					zt._prevCarry = zt.carrySpeed
					zt._prevSpeed = zt.speedToggled
				end

				zt.speedToggled = false
				if modeValLbl then
					modeValLbl.Text = "Lagger Carry"
				end

				if carryBox then
					carryBox.Text = tostring(zt.burstCarrySpeed)
				end
			end

			zt.laggerMode = j1
			r1()
		end
	end

	toggleLaggerMode = function()
		if zt.laggerMode == 0 then
			setLaggerMode(1)
		elseif zt.laggerMode == 1 then
			setLaggerMode(2)
		else
			setLaggerMode(1)
		end
	end

	burstNormalBox = q1("Main", "Lagger Normal", zt.burstNormalSpeed, function(r1)
		local j1 = tonumber(r1)
		if j1 and j1 > 0 and j1 <= 500 then
			zt.burstNormalSpeed = j1
		end
	end)
	burstCarryBox = q1("Main", "Lagger Carry", zt.burstCarrySpeed, function(r1)
		local j1 = tonumber(r1)
		if j1 and j1 > 0 and j1 <= 500 then
			zt.burstCarrySpeed = j1
		end
	end)
	P("Main", 2)
	modeValLbl = Z1("Main", "Mode", "Normal")
	P("Main", 5)
	speedKeyBtn = E1("Main", "Speed Key", Lt.speed, function(r1)
		Lt.speed = r1
	end)
	do
		local r1, j1
		_lkb = E1("Main", "Lagger Key", Lt.lagger, function(e1)
			Lt.lagger = e1
			Lt.burst = e1
		end)
		j1 = _lkb.Parent
		_bkb = _lkb
		r1 = j1
		P("Main", 5)
		local r1 = h1("Main", 42)
		z1(r1, "Speed Change Method", 10, 0, 0, 42, 8, a1.white, Enum.Font.GothamBold)
		local e1 = Instance.new("TextButton", r1)
		e1.Size = UDim2.new(0, 52, 0, 28)
		e1.Position = UDim2.new(1, -132.0, 0.5, -14.0)
		e1.BorderSizePixel = 0
		e1.Text = "V1"
		e1.Font = Enum.Font.GothamBold
		e1.TextSize = 11
		e1.RichText = false
		e1.ZIndex = 5
		Instance.new("UICorner", e1).CornerRadius = UDim.new(0, 9)
		local T1 = Instance.new("UIStroke", e1)
		T1.Thickness = 1.5
		local N1 = Instance.new("TextButton", r1)
		N1.Size = UDim2.new(0, 52, 0, 28)
		N1.Position = UDim2.new(1, -72.0, 0.5, -14.0)
		N1.BorderSizePixel = 0
		N1.Text = "V2"
		N1.Font = Enum.Font.GothamBold
		N1.TextSize = 11
		N1.RichText = false
		N1.ZIndex = 5
		Instance.new("UICorner", N1).CornerRadius = UDim.new(0, 9)
		local r1 = Instance.new("UIStroke", N1)
		r1.Thickness = 1.5
		local function K1()
			local c1 = zt.speedChangeMethod == "v1"
			tw(e1, 0.15, { BackgroundColor3 = c1 and a1.purple or a1.void })
			e1.TextColor3 = c1 and a1.void or a1.dim
			tw(T1, 0.15, { Color = c1 and a1.purple or a1.border })
			tw(N1, 0.15, { BackgroundColor3 = not c1 and a1.purple or a1.void })
			N1.TextColor3 = not c1 and a1.void or a1.dim
			tw(r1, 0.15, { Color = not c1 and a1.purple or a1.border })
			if j1 then
				j1.Visible = true
			end
		end

		setSpeedChangeMethod = function(r1)
			if r1 == "v2" and burstActive then
				zt.normalSpeed = savedNormalSpeed or zt.normalSpeed
				zt.carrySpeed = savedCarrySpeed or zt.carrySpeed
				if normalBox then
					normalBox.Text = tostring(zt.normalSpeed)
				end

				if carryBox then
					carryBox.Text = tostring(zt.carrySpeed)
				end

				burstActive = false
				_G._VH_burstActive = false
			elseif r1 == "v1" and zt.laggerMode ~= 0 then
				setLaggerMode(0)
			end

			zt.speedChangeMethod = r1
			K1()
		end

		l1(e1, function()
			setSpeedChangeMethod("v1")
		end)
		l1(N1, function()
			setSpeedChangeMethod("v2")
		end)
		K1()
	end

	P("Main", 3)
	I1("Main")
	P("Main", 3)
	It("Main", "Combat")
	do
		local r1 = h1("Main", 42)
		z1(r1, "Aimbot Version", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local j1 = Instance.new("TextButton", r1)
		j1.Size = UDim2.new(0, 46, 0, 28)
		j1.Position = UDim2.new(1, -160.0, 0.5, -14.0)
		j1.BorderSizePixel = 0
		j1.Text = "V1"
		j1.Font = Enum.Font.GothamBold
		j1.TextSize = 11
		j1.RichText = false
		j1.ZIndex = 5
		Instance.new("UICorner", j1).CornerRadius = UDim.new(0, 9)
		local e1 = Instance.new("UIStroke", j1)
		e1.Thickness = 1.5
		local T1 = Instance.new("TextButton", r1)
		T1.Size = UDim2.new(0, 46, 0, 28)
		T1.Position = UDim2.new(1, -108.0, 0.5, -14.0)
		T1.BorderSizePixel = 0
		T1.Text = "V2"
		T1.Font = Enum.Font.GothamBold
		T1.TextSize = 11
		T1.RichText = false
		T1.ZIndex = 5
		Instance.new("UICorner", T1).CornerRadius = UDim.new(0, 9)
		local N1 = Instance.new("UIStroke", T1)
		N1.Thickness = 1.5
		local K1 = Instance.new("TextButton", r1)
		K1.Size = UDim2.new(0, 46, 0, 28)
		K1.Position = UDim2.new(1, -56.0, 0.5, -14.0)
		K1.BorderSizePixel = 0
		K1.Text = "V3"
		K1.Font = Enum.Font.GothamBold
		K1.TextSize = 11
		K1.RichText = false
		K1.ZIndex = 5
		Instance.new("UICorner", K1).CornerRadius = UDim.new(0, 9)
		local r1 = Instance.new("UIStroke", K1)
		r1.Thickness = 1.5
		local function c1()
			local A1 = zt.autoBatVersion == "v1"
			local u1 = zt.autoBatVersion == "v2"
			local U1 = zt.autoBatVersion == "v3"
			tw(j1, 0.15, { BackgroundColor3 = A1 and a1.purple or a1.void })
			j1.TextColor3 = A1 and a1.void or a1.dim
			tw(e1, 0.15, { Color = A1 and a1.purple or a1.border })
			tw(T1, 0.15, { BackgroundColor3 = u1 and a1.purple or a1.void })
			T1.TextColor3 = u1 and a1.void or a1.dim
			tw(N1, 0.15, { Color = u1 and a1.purple or a1.border })
			tw(K1, 0.15, { BackgroundColor3 = U1 and a1.purple or a1.void })
			K1.TextColor3 = U1 and a1.void or a1.dim
			tw(r1, 0.15, { Color = U1 and a1.purple or a1.border })
		end

		setAimbotVersion = function(r1)
			if zt.autoBatToggled then
				stopBatAimbot()
			end

			zt.autoBatVersion = r1
			c1()
			if zt.autoBatToggled then
				startBatAimbot()
			end
		end

		c1()
		l1(j1, function()
			setAimbotVersion("v1")
		end)
		l1(T1, function()
			setAimbotVersion("v2")
		end)
		l1(K1, function()
			setAimbotVersion("v3")
		end)
	end

	setAutoSwingVisual = v1("Main", "Auto Swing", nil, zt.autoSwingEnabled, function(r1)
		zt.autoSwingEnabled = r1
	end)
	et, _ = v1("Main", "Mirror TP Down", nil, zt.mirrorTPDownEnabled, function(r1)
		zt.mirrorTPDownEnabled = r1
	end)
	setAutoBat, autoBatKeyBtn = v1("Main", "Auto Bat", Lt.autoBat, false, function(r1)
		zt.autoBatToggled = r1
		if r1 then
			_VH_forceDesyncOff()
			startBatAimbot()
		else
			stopBatAimbot()
		end

		if Bt and Bt.aimbot then
			Bt.aimbot.setOn(r1)
		end
	end, function(r1)
		Lt.autoBat = r1
	end)
	autoBatSpeedBox = q1("Main", "Aimbot Speed", zt.autoBatSpeed, function(r1)
		local j1 = tonumber(r1)
		if j1 and j1 > 0 and j1 <= 500 then
			zt.autoBatSpeed = j1
		end
	end)
	predictionStatusLbl = Z1("Main", "Prediction", "ACTIVE")
	v1("Main", "Disable at 180+", nil, zt.disablePredictionAt180, function(Z1)
		zt.disablePredictionAt180 = Z1
	end)
	setBatCounterVisual = v1("Main", "Bat Counter", nil, false, function(Z1)
		zt.batCounterEnabled = Z1
		if Z1 then
			startBatCounter()
		else
			stopBatCounter()
		end
	end)
	P("Main", 3)
	I1("Main")
	P("Main", 3)
	It("Main", "Mechanics")
	setInstaGrab = v1("Main", "Insta Grab", nil, false, function(Z1)
		if Z1 then
			yt.AutoStealEnabled = true
			pcall(function()
				if type(startAutoSteal) == "function" then
					startAutoSteal()
				end
			end)
		else
			yt.AutoStealEnabled = false
			pcall(function()
				if type(stopAutoSteal) == "function" then
					stopAutoSteal()
				end
			end)
		end
	end)
	do
		local Z1 = v1("Main", "Kick Warning", nil, zt.kickWarningEnabled, function(r1)
			zt.kickWarningEnabled = r1
			if not r1 and _G._VH_hideKickWarning then
				pcall(_G._VH_hideKickWarning)
			end
		end)
		_G._VH_setKickWarning = Z1
	end

	do
		local Z1 = h1("Main", 42)
		z1(Z1, "Jump Type", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local r1 = Instance.new("TextButton", Z1)
		r1.Size = UDim2.new(0, 72, 0, 28)
		r1.Position = UDim2.new(1, -156.0, 0.5, -14.0)
		r1.BorderSizePixel = 0
		r1.Text = "Hold"
		r1.Font = Enum.Font.GothamBold
		r1.TextSize = 10
		r1.RichText = false
		r1.ZIndex = 5
		Instance.new("UICorner", r1).CornerRadius = UDim.new(0, 9)
		local j1 = Instance.new("UIStroke", r1)
		j1.Thickness = 1.5
		local e1 = Instance.new("TextButton", Z1)
		e1.Size = UDim2.new(0, 72, 0, 28)
		e1.Position = UDim2.new(1, -80.0, 0.5, -14.0)
		e1.BorderSizePixel = 0
		e1.Text = "Manual"
		e1.Font = Enum.Font.GothamBold
		e1.TextSize = 10
		e1.RichText = false
		e1.ZIndex = 5
		Instance.new("UICorner", e1).CornerRadius = UDim.new(0, 9)
		local Z1 = Instance.new("UIStroke", e1)
		Z1.Thickness = 1.5
		setJumpTypeUI = function(T1, N1)
			if T1 ~= "manual" then
				T1 = "hold"
			end

			zt.jumpType = T1
			local K1 = T1 == "hold"
			tw(r1, 0.15, { BackgroundColor3 = K1 and a1.purple or a1.void })
			r1.TextColor3 = K1 and a1.void or a1.dim
			tw(j1, 0.15, { Color = K1 and a1.purple or a1.border })
			tw(e1, 0.15, { BackgroundColor3 = not K1 and a1.purple or a1.void })
			e1.TextColor3 = not K1 and a1.void or a1.dim
			tw(Z1, 0.15, { Color = not K1 and a1.purple or a1.border })
			zt.holdInfJumpEnabled = K1
			zt.infJumpEnabled = not K1
			if N1 then
				return
			end

			if K1 then
				if startHoldInfJump then
					startHoldInfJump()
				end
			else
				if stopHoldInfJump then
					stopHoldInfJump()
				end
			end
		end

		l1(r1, function()
			setJumpTypeUI("hold")
		end)
		l1(e1, function()
			setJumpTypeUI("manual")
		end)
		setJumpTypeUI(zt.jumpType, true)
	end

	jumpPowerBox = q1("Main", "Jump Power", zt.jumpPower, function(Z1)
		local r1 = tonumber(Z1)
		if r1 then
			r1 = math.clamp(math.floor(r1 + 0.5), 45, 50)
			zt.jumpPower = r1
			if jumpPowerBox then
				jumpPowerBox.Text = tostring(r1)
			end

			if applyJumpPower then
				applyJumpPower()
			end
		end
	end)
	setAntiRag = function(Z1)
		zt.antiRagdollEnabled = Z1
		if Z1 then
			startAntiRagdoll()
		else
			stopAntiRagdoll()
		end
	end

	antiRagToggleSet, _ = v1("Main", "Anti Ragdoll", nil, false, function(Z1)
		setAntiRag(Z1)
	end)
	setFps = v1("Main", "FPS Boost", nil, false, function(Z1)
		zt.fpsBoostEnabled = Z1
		if Z1 then
			pcall(applyFPSBoost)
			pcall(enableAntiLag)
		else
			pcall(disableFPSBoost)
			pcall(disableAntiLag)
		end
	end)
	setMedusaCounter = v1("Main", "Medusa Counter", nil, false, function(Z1)
		zt.medusaCounterEnabled = Z1
		if Z1 then
			setupMedusaCounter(Rt.Character)
		else
			stopMedusaCounter()
		end
	end)
	setAutoCarryOnGrab = v1("Main", "Auto Carry on Grab", nil, false, function(Z1)
		zt.autoCarryOnGrab = Z1
		if not Z1 and _G._VH_resetAutoCarryRuntime then
			_G._VH_resetAutoCarryRuntime()
		end
	end)
	do
		local Z1 = h1("Main", 42)
		z1(Z1, "Auto Carry Version", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local r1 = Instance.new("TextButton", Z1)
		r1.Size = UDim2.new(0, 52, 0, 28)
		r1.Position = UDim2.new(1, -132.0, 0.5, -14.0)
		r1.Text = "V1"
		r1.Font = Enum.Font.GothamBold
		r1.TextSize = 12
		r1.RichText = false
		r1.BorderSizePixel = 0
		r1.ZIndex = 5
		Instance.new("UICorner", r1).CornerRadius = UDim.new(0, 8)
		local j1 = Instance.new("UIStroke", r1)
		j1.Thickness = 1.5
		local e1 = Instance.new("TextButton", Z1)
		e1.Size = UDim2.new(0, 52, 0, 28)
		e1.Position = UDim2.new(1, -72.0, 0.5, -14.0)
		e1.Text = "V2"
		e1.Font = Enum.Font.GothamBold
		e1.TextSize = 12
		e1.RichText = false
		e1.BorderSizePixel = 0
		e1.ZIndex = 5
		Instance.new("UICorner", e1).CornerRadius = UDim.new(0, 8)
		local Z1 = Instance.new("UIStroke", e1)
		Z1.Thickness = 1.5
		local function T1()
			local N1 = zt.autoCarryVersion == "v1"
			r1.BackgroundColor3 = N1 and a1.purple or a1.void
			r1.TextColor3 = N1 and a1.white or a1.dim
			j1.Color = N1 and a1.lpurple or a1.border
			e1.BackgroundColor3 = not N1 and a1.purple or a1.void
			e1.TextColor3 = not N1 and a1.white or a1.dim
			Z1.Color = not N1 and a1.lpurple or a1.border
		end

		_G._VH_setAutoCarryVersionUI = function(Z1)
			Z1 = Z1 == "v1" and "v1" or "v2"
			if zt.autoCarryVersion ~= Z1 and _G._VH_resetAutoCarryRuntime then
				_G._VH_resetAutoCarryRuntime()
			end

			zt.autoCarryVersion = Z1
			T1()
		end

		l1(r1, function()
			_G._VH_setAutoCarryVersionUI("v1")
		end)
		l1(e1, function()
			_G._VH_setAutoCarryVersionUI("v2")
		end)
		T1()
	end

	setUnwalkToggle = v1("Main", "Unwalk", nil, false, function(Z1)
		if Z1 then
			startUnwalk()
		else
			stopUnwalk()
		end
	end)
	do
		local Z1 = h1("Main", 42)
		z1(Z1, "Customize ESP", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local r1 = Instance.new("TextButton", Z1)
		r1.Size = UDim2.new(0, 40, 0, 40)
		r1.Position = UDim2.new(1, -48.0, 0.5, -20.0)
		r1.BackgroundColor3 = a1.void
		r1.BorderSizePixel = 0
		r1.Text = "\226\150\182"
		r1.TextColor3 = a1.lpurple
		r1.Font = Enum.Font.GothamBold
		r1.TextSize = 20
		r1.RichText = false
		r1.ZIndex = 5
		Instance.new("UICorner", r1).CornerRadius = UDim.new(0, 10)
		local Z1 = Instance.new("UIStroke", r1)
		Z1.Color = a1.border
		Z1.Thickness = 1.5
		local function Z1(j1, e1, T1)
			local N1, K1 = h1("Main", 40)
			z1(N1, "  \226\128\162 " .. j1, 10, 0, 0, 40, 10, a1.dim, Enum.Font.GothamBold)
			local j1 = Instance.new("Frame", N1)
			j1.Size = UDim2.new(0, 47, 0, 23)
			j1.Position = UDim2.new(1, -67.0, 0.5, -13.0)
			j1.BackgroundColor3 = e1 and a1.on or a1.off
			j1.BorderSizePixel = 0
			j1.ZIndex = 5
			Instance.new("UICorner", j1).CornerRadius = UDim.new(1, 0)
			local K1 = Instance.new("UIStroke", j1)
			K1.Color = e1 and a1.purple or a1.border
			K1.Thickness = 1.5
			local c1 = Instance.new("Frame", j1)
			c1.Size = UDim2.new(0, 18, 0, 18)
			c1.Position = e1 and UDim2.new(1, -23.0, 0.5, -10.0) or UDim2.new(0, 3, 0.5, -9.0)
			c1.BackgroundColor3 = e1 and a1.white or a1.dim
			c1.BorderSizePixel = 0
			c1.ZIndex = 6
			Instance.new("UICorner", c1).CornerRadius = UDim.new(1, 0)
			local A1 = e1 or false
			local function e1(u1)
				A1 = u1
				tw(j1, 0.16, { BackgroundColor3 = u1 and a1.on or a1.off })
				tw(K1, 0.16, { Color = u1 and a1.purple or a1.border })
				tw(c1, 0.18, {
					Position = u1 and UDim2.new(1, -23.0, 0.5, -10.0) or UDim2.new(0, 3, 0.5, -9.0),
					BackgroundColor3 = u1 and a1.white or a1.dim,
				}, Enum.EasingStyle.Quad)
			end

			local j1 = Instance.new("TextButton", N1)
			j1.Size = UDim2.new(0, 47, 0, 23)
			j1.Position = UDim2.new(1, -67.0, 0.5, -13.0)
			j1.BackgroundTransparency = 1
			j1.Text = ""
			j1.ZIndex = 7
			l1(j1, function()
				A1 = not A1
				e1(A1)
				if T1 then
					pcall(T1, A1)
				end
			end)
			return N1, e1
		end

		local j1, e1 = Z1("Aura (Highlight)", zt.espAuraEnabled, function(T1)
			if _seA then
				_seA(T1)
			else
				zt.espAuraEnabled = T1
			end
		end)
		local T1, N1 = Z1("Line ESP", zt.espLineEnabled, function(K1)
			if _seL then
				_seL(K1)
			else
				zt.espLineEnabled = K1
			end
		end)
		local K1, c1 = Z1("Hitbox", zt.espHitboxEnabled, function(Z1)
			if _seH then
				_seH(Z1)
			else
				zt.espHitboxEnabled = Z1
			end
		end)
		_G._VH_setEspUI = function()
			e1(zt.espAuraEnabled)
			N1(zt.espLineEnabled)
			c1(zt.espHitboxEnabled)
		end

		local function Z1()
			local e1 = zt.espPanelOpen
			j1.Visible = e1
			T1.Visible = e1
			K1.Visible = e1
			r1.Text = e1 and "\226\150\188" or "\226\150\182"
		end

		zt.espPanelOpen = false
		Z1()
		l1(r1, function()
			zt.espPanelOpen = not zt.espPanelOpen
			Z1()
		end)
	end

	do
		local Z1 = h1("Main", 42)
		z1(Z1, "Animations", 10, 0, 0.6, 42, 10, a1.white, Enum.Font.GothamBold)
		local r1 = Instance.new("TextLabel", Z1)
		r1.Size = UDim2.new(0, 100, 1, 0)
		r1.Position = UDim2.new(1, -158.0, 0, 0)
		r1.BackgroundTransparency = 1
		r1.Text = zt.selectedAnim
		r1.TextColor3 = a1.purple
		r1.Font = Enum.Font.GothamBold
		r1.TextSize = 11
		r1.TextStrokeTransparency = 0
		r1.ZIndex = 5
		local j1 = Instance.new("TextButton", Z1)
		j1.Size = UDim2.new(0, 40, 0, 40)
		j1.Position = UDim2.new(1, -48.0, 0.5, -20.0)
		j1.BackgroundColor3 = a1.void
		j1.BorderSizePixel = 0
		j1.Text = "\226\150\182"
		j1.TextColor3 = a1.lpurple
		j1.Font = Enum.Font.GothamBold
		j1.TextSize = 20
		j1.RichText = false
		j1.ZIndex = 5
		Instance.new("UICorner", j1).CornerRadius = UDim.new(0, 10)
		local e1 = Instance.new("UIStroke", j1)
		e1.Color = a1.border
		e1.Thickness = 1.5
		local e1 = {}
		local T1 = false
		local function N1()
			for K1, c1 in pairs(e1) do
				local A1 = K1 == zt.selectedAnim
				c1.frame.BackgroundColor3 = A1 and a1.stkAct or a1.void
				local K1 = c1.frame:FindFirstChildOfClass("UIStroke")
				if K1 then
					K1.Color = A1 and a1.purple or a1.border
				end
			end
		end

		for K1, K1 in ipairs(M1) do
			local M1 = Instance.new("TextButton", P1.Main)
			M1.Size = UDim2.new(1, -14.0, 0, 32)
			M1.Position = UDim2.new(0, 7, 0, 0)
			M1.BackgroundColor3 = a1.void
			M1.BorderSizePixel = 0
			M1.Text = K1
			M1.TextColor3 = a1.white
			M1.Font = Enum.Font.GothamBold
			M1.TextSize = 10
			M1.RichText = false
			M1.LayoutOrder = l("Main")
			M1.Visible = false
			M1.ZIndex = 8
			Instance.new("UICorner", M1).CornerRadius = UDim.new(0, 9)
			local c1 = Instance.new("UIStroke", M1)
			c1.Color = a1.border
			c1.Thickness = 1.5
			e1[K1] = { frame = M1 }
			l1(M1, function()
				setSelectedAnim(K1)
				r1.Text = K1
				N1()
				_scfg()
			end)
		end

		setAnimDropdown = function(M1)
			r1.Text = M1
			N1()
		end

		local function M1()
			T1 = not T1
			j1.Text = T1 and "\226\150\188" or "\226\150\182"
			for r1, r1 in pairs(e1) do
				r1.frame.Visible = T1
			end
		end

		local r1 = Instance.new("TextButton", Z1)
		r1.Size = UDim2.new(1, 0, 1, 0)
		r1.BackgroundTransparency = 1
		r1.Text = ""
		r1.ZIndex = 6
		l1(r1, M1)
		N1()
	end

	task.wait()
	It("Move", "Teleport")
	tpDownKeyBtn = E1("Move", "TP Down", Lt.tpDown, function(M1)
		Lt.tpDown = M1
	end)
	setAutoTpDown = v1("Move", "Auto TP Down", nil, false, function(M1)
		zt.autoTpDownEnabled = M1
		if M1 then
			startAutoTpDown()
		else
			stopAutoTpDown()
		end
	end)
	autoTpHeightBox = q1("Move", "TP Down Height", zt.tpDownHeight, function(M1)
		local q1 = tonumber(M1)
		if q1 and q1 >= 5 and q1 <= 200 then
			zt.tpDownHeight = q1
		end
	end)
	dropBrainrotKeyBtn = E1("Move", "Drop Brainrot", Lt.dropBrainrot, function(M1)
		Lt.dropBrainrot = M1
	end)
	do
		local M1 = h1("Move", 42)
		z1(M1, "Drop Type", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local q1 = Instance.new("TextButton", M1)
		q1.Size = UDim2.new(0, 72, 0, 28)
		q1.Position = UDim2.new(1, -156.0, 0.5, -14.0)
		q1.BorderSizePixel = 0
		q1.Text = "Stand Drop"
		q1.Font = Enum.Font.GothamBold
		q1.TextSize = 10
		q1.RichText = false
		q1.ZIndex = 5
		local Z1 = Instance.new("UICorner", q1)
		Z1.CornerRadius = UDim.new(0, 9)
		local Z1 = Instance.new("UIStroke", q1)
		Z1.Thickness = 1.5
		local r1 = Instance.new("TextButton", M1)
		r1.Size = UDim2.new(0, 72, 0, 28)
		r1.Position = UDim2.new(1, -80.0, 0.5, -14.0)
		r1.BorderSizePixel = 0
		r1.Text = "Jump Drop"
		r1.Font = Enum.Font.GothamBold
		r1.TextSize = 10
		r1.RichText = false
		r1.ZIndex = 5
		local M1 = Instance.new("UICorner", r1)
		M1.CornerRadius = UDim.new(0, 9)
		local M1 = Instance.new("UIStroke", r1)
		M1.Thickness = 1.5
		setDropType = function(j1)
			zt.dropType = j1
			local e1 = j1 == "Stand Drop"
			tw(q1, 0.15, { BackgroundColor3 = e1 and a1.purple or a1.void })
			q1.TextColor3 = e1 and a1.void or a1.dim
			tw(Z1, 0.15, { Color = e1 and a1.purple or a1.border })
			tw(r1, 0.15, { BackgroundColor3 = not e1 and a1.purple or a1.void })
			r1.TextColor3 = not e1 and a1.void or a1.dim
			tw(M1, 0.15, { Color = not e1 and a1.purple or a1.border })
		end

		l1(q1, function()
			setDropType("Stand Drop")
		end)
		l1(r1, function()
			setDropType("Jump Drop")
		end)
	end

	P("Move", 3)
	I1("Move")
	P("Move", 3)
	It("Move", "Auto Left / Right")
	setAutoLeft, autoLeftKeyBtn = v1("Move", "Auto Left", Lt.autoLeft, false, function(M1)
		zt.autoLeftEnabled = M1
		if M1 then
			_VH_forceAimbotOff()
			_VH_forceDesyncOff()
			zt.autoRightEnabled = false
			stopAutoRight()
			if Bt and Bt.autoRight then
				Bt.autoRight.setOn(false)
			end

			if setAutoRight then
				setAutoRight(false)
			end

			startAutoLeft()
		else
			stopAutoLeft()
		end

		if Bt and Bt.autoLeft then
			Bt.autoLeft.setOn(M1)
		end
	end, function(M1)
		Lt.autoLeft = M1
	end)
	setAutoRight, autoRightKeyBtn = v1("Move", "Auto Right", Lt.autoRight, false, function(M1)
		zt.autoRightEnabled = M1
		if M1 then
			_VH_forceAimbotOff()
			_VH_forceDesyncOff()
			zt.autoLeftEnabled = false
			stopAutoLeft()
			if Bt and Bt.autoLeft then
				Bt.autoLeft.setOn(false)
			end

			if setAutoLeft then
				setAutoLeft(false)
			end

			startAutoRight()
		else
			stopAutoRight()
		end

		if Bt and Bt.autoRight then
			Bt.autoRight.setOn(M1)
		end
	end, function(M1)
		Lt.autoRight = M1
	end)
	do
		local M1 = h1("Move", 42)
		z1(M1, "Auto Play Mode", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local q1 = Instance.new("TextButton", M1)
		q1.Size = UDim2.new(0, 72, 0, 28)
		q1.Position = UDim2.new(1, -156.0, 0.5, -14.0)
		q1.BorderSizePixel = 0
		q1.Text = "Normal"
		q1.Font = Enum.Font.GothamBold
		q1.TextSize = 10
		q1.RichText = false
		q1.ZIndex = 5
		Instance.new("UICorner", q1).CornerRadius = UDim.new(0, 9)
		local Z1 = Instance.new("UIStroke", q1)
		Z1.Thickness = 1.5
		local r1 = Instance.new("TextButton", M1)
		r1.Size = UDim2.new(0, 72, 0, 28)
		r1.Position = UDim2.new(1, -80.0, 0.5, -14.0)
		r1.BorderSizePixel = 0
		r1.Text = "Full Auto"
		r1.Font = Enum.Font.GothamBold
		r1.TextSize = 10
		r1.RichText = false
		r1.ZIndex = 5
		Instance.new("UICorner", r1).CornerRadius = UDim.new(0, 9)
		local M1 = Instance.new("UIStroke", r1)
		M1.Thickness = 1.5
		setAutoPlayModeUI = function(j1)
			zt.autoPlayMode = j1
			local e1 = j1 == "normal"
			tw(q1, 0.15, { BackgroundColor3 = e1 and a1.purple or a1.void })
			q1.TextColor3 = e1 and a1.void or a1.dim
			tw(Z1, 0.15, { Color = e1 and a1.purple or a1.border })
			tw(r1, 0.15, { BackgroundColor3 = not e1 and a1.purple or a1.void })
			r1.TextColor3 = not e1 and a1.void or a1.dim
			tw(M1, 0.15, { Color = not e1 and a1.purple or a1.border })
			if zt.autoLeftEnabled then
				stopAutoLeft()
				startAutoLeft()
			end

			if zt.autoRightEnabled then
				stopAutoRight()
				startAutoRight()
			end
		end

		l1(q1, function()
			setAutoPlayModeUI("normal")
		end)
		l1(r1, function()
			setAutoPlayModeUI("full")
		end)
		setAutoPlayModeUI(zt.autoPlayMode)
	end

	P("Move", 3)
	I1("Move")
	P("Move", 3)
	It("Move", "Anti Die")
	Kt.setVisual, _ = v1("Move", "Anti Die", nil, zt.antiDieEnabled, function(M1)
		zt.antiDieEnabled = M1
		if Kt.refresh then
			Kt.refresh()
		elseif M1 and Kt.start then
			Kt.start()
		elseif Kt.stop then
			Kt.stop()
		end
	end)
	Kt.keyButton = E1("Move", "Anti Die Key", Lt.antiDie, function(M1)
		Lt.antiDie = M1
		if Kt.keyButton then
			Kt.keyButton.Text = M1 == Enum.KeyCode.Unknown and "None" or M1.Name
		end
	end)
	Kt.keyButton.Text = Lt.antiDie == Enum.KeyCode.Unknown and "None" or Lt.antiDie.Name
	P("Move", 3)
	It("Move", "Desync Aimbot")
	setDesyncAimbot, desyncAimbotKeyBtn = v1("Move", "Desync Aimbot", Lt.desyncAimbot, false, function(M1)
		zt.desyncAimbotEnabled = M1
		if M1 then
			_VH_forceAimbotOff()
			startDesyncAimbot()
		else
			stopDesyncAimbot()
		end
	end, function(M1)
		Lt.desyncAimbot = M1
	end)
	do
		local M1 = h1("Move", 42)
		z1(M1, "Desync Version", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local q1 = Instance.new("TextButton", M1)
		q1.Size = UDim2.new(0, 72, 0, 28)
		q1.Position = UDim2.new(1, -156.0, 0.5, -14.0)
		q1.BorderSizePixel = 0
		q1.Text = "V1"
		q1.Font = Enum.Font.GothamBold
		q1.TextSize = 10
		q1.RichText = false
		q1.ZIndex = 5
		Instance.new("UICorner", q1).CornerRadius = UDim.new(0, 9)
		local Z1 = Instance.new("UIStroke", q1)
		Z1.Thickness = 1.5
		local r1 = Instance.new("TextButton", M1)
		r1.Size = UDim2.new(0, 72, 0, 28)
		r1.Position = UDim2.new(1, -80.0, 0.5, -14.0)
		r1.BorderSizePixel = 0
		r1.Text = "V2"
		r1.Font = Enum.Font.GothamBold
		r1.TextSize = 10
		r1.RichText = false
		r1.ZIndex = 5
		Instance.new("UICorner", r1).CornerRadius = UDim.new(0, 9)
		local M1 = Instance.new("UIStroke", r1)
		M1.Thickness = 1.5
		local function j1()
			local e1 = zt.desyncAimbotVersion ~= "v2"
			local T1 = not e1
			tw(q1, 0.15, { BackgroundColor3 = e1 and a1.purple or a1.void })
			q1.TextColor3 = e1 and a1.void or a1.dim
			tw(Z1, 0.15, { Color = e1 and a1.purple or a1.border })
			tw(r1, 0.15, { BackgroundColor3 = T1 and a1.purple or a1.void })
			r1.TextColor3 = T1 and a1.void or a1.dim
			tw(M1, 0.15, { Color = T1 and a1.purple or a1.border })
		end

		Nt = function(M1)
			if M1 ~= "v2" then
				M1 = "v1"
			end

			if zt.desyncAimbotVersion == M1 then
				j1()
				return
			end

			local Z1 = zt.desyncAimbotEnabled == true
			if Z1 and stopDesyncAimbot then
				stopDesyncAimbot()
			end

			zt.desyncAimbotVersion = M1
			j1()
			if Z1 and startDesyncAimbot then
				startDesyncAimbot()
			end
		end

		l1(q1, function()
			Nt("v1")
		end)
		l1(r1, function()
			Nt("v2")
		end)
		j1()
	end

	jt, _ = v1("Move", "Turn Desync Aimbot Off After Hit", nil, zt.desyncStopAfterHit, function(M1)
		zt.desyncStopAfterHit = M1
	end)
	task.wait()
	P("Move", 6)
	It("Config", "Interface")
	guiHideKeyBtn = E1("Config", "Hide GUI", Lt.guiHide, function(M1)
		Lt.guiHide = M1
	end)
	local M1
	M1, _ = v1("Config", "Show Intro", nil, not kt, function(kt)
		zt.introEnabled = kt
		ht("VampireHubIntro.state", kt and "on" or "off")
		_scfg()
	end)
	_G._VH_setIntroToggle = M1
	P("Config", 4)
	I1("Config")
	P("Config", 4)
	P("Config", 4)
	I1("Config")
	P("Config", 4)
	It("Config", "Steal Mode")
	do
		local kt = h1("Config", 42)
		z1(kt, "Steal Mode", 10, 0, 0.38, 42, 10, a1.white, Enum.Font.GothamBold)
		local M1 = Instance.new("TextButton", kt)
		M1.Size = UDim2.new(0, 58, 0, 28)
		M1.Position = UDim2.new(1, -190.0, 0.5, -14.0)
		M1.BorderSizePixel = 0
		M1.Text = "Normal"
		M1.Font = Enum.Font.GothamBold
		M1.TextSize = 9
		M1.RichText = false
		M1.ZIndex = 5
		Instance.new("UICorner", M1).CornerRadius = UDim.new(0, 9)
		local q1 = Instance.new("UIStroke", M1)
		q1.Thickness = 1.5
		local Z1 = Instance.new("TextButton", kt)
		Z1.Size = UDim2.new(0, 52, 0, 28)
		Z1.Position = UDim2.new(1, -126.0, 0.5, -14.0)
		Z1.BorderSizePixel = 0
		Z1.Text = "Semi"
		Z1.Font = Enum.Font.GothamBold
		Z1.TextSize = 9
		Z1.RichText = false
		Z1.ZIndex = 5
		Instance.new("UICorner", Z1).CornerRadius = UDim.new(0, 9)
		local E1 = Instance.new("UIStroke", Z1)
		E1.Thickness = 1.5
		local r1 = Instance.new("TextButton", kt)
		r1.Size = UDim2.new(0, 62, 0, 28)
		r1.Position = UDim2.new(1, -68.0, 0.5, -14.0)
		r1.BorderSizePixel = 0
		r1.Text = "Normal V2"
		r1.Font = Enum.Font.GothamBold
		r1.TextSize = 8
		r1.RichText = false
		r1.ZIndex = 5
		Instance.new("UICorner", r1).CornerRadius = UDim.new(0, 9)
		local kt = Instance.new("UIStroke", r1)
		kt.Thickness = 1.5
		zt.semiVersion = "v2"
		setSemiVersion = function(j1)
			zt.semiVersion = "v2"
		end

		local j1 = h1("Config", 42)
		j1.Visible = false
		z1(j1, "Stop At", 10, 0, 0.32, 42, 10, a1.dim, Enum.Font.GothamBold)
		local e1 = { 75, 80, 85, 90 }
		local T1 = {}
		local N1 = {}
		local function K1()
			for c1, A1 in ipairs(e1) do
				local u1 = zt.normalV2StopAt == A1
				local A1 = T1[c1]
				local U1 = N1[c1]
				if A1 then
					tw(A1, 0.12, { BackgroundColor3 = u1 and a1.purple or a1.void })
					A1.TextColor3 = u1 and a1.void or a1.dim
				end

				if U1 then
					tw(U1, 0.12, { Color = u1 and a1.purple or a1.border })
				end
			end
		end

		for c1, A1 in ipairs(e1) do
			local u1 = Instance.new("TextButton", j1)
			u1.Size = UDim2.new(0, 38, 0, 28)
			u1.Position = UDim2.new(1, -46.0 - (#e1 - c1) * 42, 0.5, -14.0)
			u1.BorderSizePixel = 0
			u1.Text = tostring(A1)
			u1.Font = Enum.Font.GothamBold
			u1.TextSize = 9
			u1.RichText = false
			u1.ZIndex = 5
			Instance.new("UICorner", u1).CornerRadius = UDim.new(0, 9)
			local e1 = Instance.new("UIStroke", u1)
			e1.Thickness = 1.5
			T1[c1] = u1
			N1[c1] = e1
			l1(u1, function()
				zt.normalV2StopAt = A1
				K1()
			end)
		end

		K1()
		local e1 = h1("Config", 44)
		z1(e1, "Radius", 10, 0, 0, 44, 10, a1.dim, Enum.Font.GothamBold)
		local T1 = Instance.new("TextButton", e1)
		T1.Size = UDim2.new(0, 100, 0, 30)
		T1.Position = UDim2.new(1, -108.0, 0.5, -15.0)
		T1.BackgroundColor3 = a1.void
		T1.BorderSizePixel = 0
		T1.Text = tostring(yt.StealRadius)
		T1.TextColor3 = Color3.fromRGB(255, 100, 100)
		T1.Font = Enum.Font.GothamBold
		T1.TextSize = 13
		Instance.new("UICorner", T1).CornerRadius = UDim.new(0, 10)
		Instance.new("UIStroke", T1).Color = a1.purple
		stealRadBtn = T1
		local N1 = false
		local function c1()
			if N1 then
				return
			end

			N1 = true
			local A1 = Instance.new("TextBox", e1)
			A1.Size = T1.Size
			A1.Position = T1.Position
			A1.BackgroundColor3 = a1.void
			A1.BorderSizePixel = 0
			A1.Text = T1.Text
			A1.TextColor3 = a1.purple
			A1.Font = Enum.Font.Gotham
			A1.TextSize = 13
			A1.ClearTextOnFocus = false
			Instance.new("UICorner", A1).CornerRadius = UDim.new(0, 10)
			Instance.new("UIStroke", A1).Color = a1.purple
			A1:CaptureFocus()
			A1.FocusLost:Connect(function()
				local e1 = tonumber(A1.Text)
				if e1 and e1 >= 5 and e1 <= 300 then
					yt.StealRadius = math.floor(e1)
					if zt.stealMode == "normal" or zt.stealMode == "normalv2" then
						yt.NormalRadius = yt.StealRadius
					else
						yt.SemiRadius = yt.StealRadius
					end

					T1.Text = tostring(yt.StealRadius)
					yt.cachedPrompts = {}
					yt.promptCacheTime = 0
					if zt.stealMode == "semi" then
						_G.AceStealRadii = _G.AceStealRadii or { Normal = 62, Semi = 9 }
						_G.AceStealRadii.Semi = math.floor(e1)
						if _G.AceSemiAutoStealSetRadius then
							_G.AceSemiAutoStealSetRadius(math.floor(e1))
						end
					end
				end

				A1:Destroy()
				N1 = false
			end)
		end

		l1(T1, c1)
		local e1 = h1("Config", 44)
		z1(e1, "Duration (s)", 10, 0, 0, 44, 10, a1.dim, Enum.Font.GothamBold)
		local N1 = Instance.new("TextButton", e1)
		N1.Size = UDim2.new(0, 100, 0, 30)
		N1.Position = UDim2.new(1, -108.0, 0.5, -15.0)
		N1.BackgroundColor3 = a1.void
		N1.BorderSizePixel = 0
		N1.Text = tostring(yt.StealDuration)
		N1.TextColor3 = Color3.fromRGB(255, 100, 100)
		N1.Font = Enum.Font.GothamBold
		N1.TextSize = 13
		Instance.new("UICorner", N1).CornerRadius = UDim.new(0, 10)
		Instance.new("UIStroke", N1).Color = a1.purple
		stealDurBtn = N1
		local c1 = false
		local function A1()
			if c1 then
				return
			end

			c1 = true
			local u1 = Instance.new("TextBox", e1)
			u1.Size = N1.Size
			u1.Position = N1.Position
			u1.BackgroundColor3 = a1.void
			u1.BorderSizePixel = 0
			u1.Text = N1.Text
			u1.TextColor3 = a1.purple
			u1.Font = Enum.Font.Gotham
			u1.TextSize = 13
			u1.ClearTextOnFocus = false
			Instance.new("UICorner", u1).CornerRadius = UDim.new(0, 10)
			Instance.new("UIStroke", u1).Color = a1.purple
			u1:CaptureFocus()
			u1.FocusLost:Connect(function()
				local e1 = tonumber(u1.Text)
				if e1 and e1 >= 0.01 and e1 <= 5 then
					yt.StealDuration = e1
					if zt.stealMode == "normal" or zt.stealMode == "normalv2" then
						yt.NormalDuration = yt.StealDuration
					else
						yt.SemiDuration = yt.StealDuration
					end

					N1.Text = tostring(yt.StealDuration)
				end

				u1:Destroy()
				c1 = false
			end)
		end

		l1(N1, A1)
		refreshStealUI = function()
			if T1 then
				T1.Text = tostring(yt.StealRadius)
			end

			if N1 then
				N1.Text = tostring(yt.StealDuration)
			end

			K1()
		end

		setStealModeUI = function(e1, c1)
			if not c1 then
				if zt.stealMode == "normal" or zt.stealMode == "normalv2" then
					yt.NormalRadius = yt.StealRadius
					yt.NormalDuration = yt.StealDuration
				else
					yt.SemiRadius = yt.StealRadius
					yt.SemiDuration = yt.StealDuration
				end
			end

			zt.stealMode = e1
			if e1 == "normal" or e1 == "normalv2" then
				yt.StealRadius = yt.NormalRadius
				yt.StealDuration = yt.NormalDuration
			else
				yt.StealRadius = yt.SemiRadius
				yt.StealDuration = yt.SemiDuration
			end

			T1.Text = tostring(yt.StealRadius)
			N1.Text = tostring(yt.StealDuration)
			local T1 = e1 == "normal"
			local N1 = e1 == "semi"
			local c1 = e1 == "normalv2"
			j1.Visible = c1
			K1()
			tw(M1, 0.15, { BackgroundColor3 = T1 and a1.purple or a1.void })
			M1.TextColor3 = T1 and a1.void or a1.dim
			tw(q1, 0.15, { Color = T1 and a1.purple or a1.border })
			tw(Z1, 0.15, { BackgroundColor3 = N1 and a1.purple or a1.void })
			Z1.TextColor3 = N1 and a1.void or a1.dim
			tw(E1, 0.15, { Color = N1 and a1.purple or a1.border })
			tw(r1, 0.15, { BackgroundColor3 = c1 and a1.purple or a1.void })
			r1.TextColor3 = c1 and a1.void or a1.dim
			tw(kt, 0.15, { Color = c1 and a1.purple or a1.border })
			if yt.AutoStealEnabled then
				stopAutoSteal()
				startAutoSteal()
			end
		end

		setStealModeUI(zt.stealMode, true)
		l1(M1, function()
			setStealModeUI("normal")
		end)
		l1(Z1, function()
			setStealModeUI("semi")
		end)
		l1(r1, function()
			setStealModeUI("normalv2")
		end)
	end

	P("Config", 4)
	I1("Config")
	P("Config", 4)
	It("Config", "Stretch Rez")
	setStretchRezVisual = v1("Config", "Stretch Rez", nil, false, function(kt)
		if kt then
			enableStretchRez()
		else
			disableStretchRez()
		end
	end)
	do
		local kt = { "Normal", 90, 120 }
		local M1 = {}
		local q1 = {}
		local Z1 = h1("Config", 42)
		z1(Z1, "Stretch FOV", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local E1 = #kt
		for r1, j1 in ipairs(kt) do
			local e1 = Instance.new("TextButton", Z1)
			e1.Size = UDim2.new(0, 40, 0, 28)
			local Z1 = (E1 - r1) * 46
			e1.Position = UDim2.new(1, -48.0 - Z1, 0.5, -14.0)
			e1.BorderSizePixel = 0
			e1.Text = j1 == "Normal" and "Norm" or tostring(j1)
			e1.Font = Enum.Font.GothamBold
			e1.TextSize = 10
			e1.RichText = false
			e1.ZIndex = 5
			Instance.new("UICorner", e1).CornerRadius = UDim.new(0, 9)
			local Z1 = Instance.new("UIStroke", e1)
			Z1.Thickness = 1.5
			M1[r1] = e1
			q1[r1] = Z1
			l1(e1, function()
				setStretchFOV(j1)
			end)
		end

		setStretchFOVVisual = function(Z1)
			for E1, r1 in ipairs(kt) do
				local kt = r1 == "Normal"
				local j1
				if kt then
					j1 = (Z1 == "Normal" or Z1 == NORMAL_STRETCH_FOV)
				else
					j1 = (tonumber(Z1) == r1)
				end

				tw(M1[E1], 0.15, { BackgroundColor3 = j1 and a1.purple or a1.void })
				M1[E1].TextColor3 = j1 and a1.void or a1.dim
				tw(q1[E1], 0.15, { Color = j1 and a1.purple or a1.border })
			end
		end
	end

	do
		local kt, M1, q1 = 70, 120, 10
		local Z1 = h1("Config", 42)
		z1(Z1, "Normal FOV", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local E1 = Instance.new("TextButton", Z1)
		E1.Size = UDim2.new(0, 28, 0, 28)
		E1.Position = UDim2.new(1, -118.0, 0.5, -14.0)
		E1.BackgroundColor3 = a1.void
		E1.BorderSizePixel = 0
		E1.Text = "-"
		E1.TextColor3 = a1.lpurple
		E1.Font = Enum.Font.Gotham
		E1.TextSize = 16
		E1.ZIndex = 5
		Instance.new("UICorner", E1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", E1).Color = a1.border
		local r1 = Instance.new("TextLabel", Z1)
		r1.Size = UDim2.new(0, 42, 0, 28)
		r1.Position = UDim2.new(1, -86.0, 0.5, -14.0)
		r1.BackgroundColor3 = a1.void
		r1.BorderSizePixel = 0
		r1.Text = tostring(math.floor(zt.lockedFOV))
		r1.TextColor3 = a1.purple
		r1.Font = Enum.Font.Gotham
		r1.TextSize = 13
		r1.ZIndex = 5
		Instance.new("UICorner", r1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", r1).Color = a1.border
		local j1 = Instance.new("TextButton", Z1)
		j1.Size = UDim2.new(0, 28, 0, 28)
		j1.Position = UDim2.new(1, -40.0, 0.5, -14.0)
		j1.BackgroundColor3 = a1.void
		j1.BorderSizePixel = 0
		j1.Text = "+"
		j1.TextColor3 = a1.lpurple
		j1.Font = Enum.Font.Gotham
		j1.TextSize = 16
		j1.ZIndex = 5
		Instance.new("UICorner", j1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", j1).Color = a1.border
		local function Z1()
			zt.lockedFOV = math.clamp(zt.lockedFOV, kt, M1)
			r1.Text = tostring(math.floor(zt.lockedFOV))
			if not zt.stretchedResEnabled then
				pcall(function()
					workspace.CurrentCamera.FieldOfView = zt.lockedFOV
				end)
			end

			if fovBox then
				fovBox.Text = tostring(math.floor(zt.lockedFOV))
			end
		end

		Z1()
		l1(E1, function()
			zt.lockedFOV = math.clamp(zt.lockedFOV - q1, kt, M1)
			Z1()
		end)
		l1(j1, function()
			zt.lockedFOV = math.clamp(zt.lockedFOV + q1, kt, M1)
			Z1()
		end)
	end

	P("Config", 4)
	I1("Config")
	P("Config", 4)
	local kt = {
		purple = a1.purple,
		dpurple = a1.dpurple,
		lpurple = a1.lpurple,
		on = a1.on,
		stkBg = a1.stkBg,
		stkBrd = a1.stkBrd,
		stkAct = a1.stkAct,
	}
	local M1 = {
		purple = Color3.fromRGB(155, 155, 155),
		dpurple = Color3.fromRGB(100, 100, 100),
		lpurple = Color3.fromRGB(195, 195, 195),
		on = Color3.fromRGB(155, 155, 155),
		stkBg = Color3.fromRGB(20, 20, 20),
		stkBrd = Color3.fromRGB(60, 60, 60),
		stkAct = Color3.fromRGB(120, 120, 120),
	}
	local q1 = {
		purple = Color3.fromRGB(235, 185, 20),
		dpurple = Color3.fromRGB(180, 140, 10),
		lpurple = Color3.fromRGB(255, 220, 70),
		on = Color3.fromRGB(235, 185, 20),
		stkBg = Color3.fromRGB(18, 15, 4),
		stkBrd = Color3.fromRGB(80, 65, 15),
		stkAct = Color3.fromRGB(140, 110, 20),
	}
	local Z1 = {
		purple = Color3.fromRGB(50, 195, 80),
		dpurple = Color3.fromRGB(30, 145, 55),
		lpurple = Color3.fromRGB(100, 230, 125),
		on = Color3.fromRGB(50, 195, 80),
		stkBg = Color3.fromRGB(5, 18, 8),
		stkBrd = Color3.fromRGB(20, 70, 30),
		stkAct = Color3.fromRGB(30, 120, 50),
	}
	local E1 = {
		purple = Color3.fromRGB(50, 130, 255),
		dpurple = Color3.fromRGB(30, 90, 210),
		lpurple = Color3.fromRGB(100, 175, 255),
		on = Color3.fromRGB(50, 130, 255),
		stkBg = Color3.fromRGB(4, 10, 22),
		stkBrd = Color3.fromRGB(15, 40, 85),
		stkAct = Color3.fromRGB(25, 70, 160),
	}
	local r1 = {
		purple = Color3.fromRGB(23, 23, 23),
		dpurple = Color3.fromRGB(7, 7, 7),
		lpurple = Color3.fromRGB(59, 59, 59),
		on = Color3.fromRGB(23, 23, 23),
		stkBg = Color3.fromRGB(5, 5, 5),
		stkBrd = Color3.fromRGB(25, 25, 25),
		stkAct = Color3.fromRGB(49, 49, 49),
	}
	local j1 = {
		purple = Color3.fromRGB(165, 75, 235),
		dpurple = Color3.fromRGB(110, 40, 180),
		lpurple = Color3.fromRGB(210, 140, 255),
		on = Color3.fromRGB(165, 75, 235),
		stkBg = Color3.fromRGB(14, 6, 22),
		stkBrd = Color3.fromRGB(65, 28, 95),
		stkAct = Color3.fromRGB(120, 50, 175),
	}
	local e1 = {
		purple = Color3.fromRGB(155, 98, 55),
		dpurple = Color3.fromRGB(105, 62, 30),
		lpurple = Color3.fromRGB(205, 150, 95),
		on = Color3.fromRGB(155, 98, 55),
		stkBg = Color3.fromRGB(18, 10, 5),
		stkBrd = Color3.fromRGB(70, 42, 22),
		stkAct = Color3.fromRGB(120, 72, 35),
	}
	local T1 = {
		purple = Color3.fromRGB(235, 85, 165),
		dpurple = Color3.fromRGB(180, 45, 120),
		lpurple = Color3.fromRGB(255, 145, 205),
		on = Color3.fromRGB(235, 85, 165),
		stkBg = Color3.fromRGB(22, 5, 13),
		stkBrd = Color3.fromRGB(90, 25, 60),
		stkAct = Color3.fromRGB(165, 45, 105),
	}
	local N1
	do
		local K1 = {
			{ id = "original", img = "rbxassetid://14640607134" },
			{ id = "vampire", img = "rbxassetid://114138477258742" },
			{ id = "golden", img = "rbxassetid://113621109176868" },
			{ id = "forest", img = "rbxassetid://15108586724" },
			{ id = "jungle", img = "rbxassetid://11850170603" },
			{ id = "ocean", img = "rbxassetid://116893313684229" },
			{ id = "79809183056960", img = "rbxassetid://79809183056960" },
			{ id = "79455822331118", img = "rbxassetid://79455822331118" },
			{ id = "16948826915", img = "rbxassetid://16948826915" },
			{ id = "101793424727240", img = "rbxassetid://101793424727240" },
			{ id = "123540425987418", img = "rbxassetid://123540425987418" },
			{ id = "122195659108931", img = "rbxassetid://122195659108931" },
			{ id = "6457947928", img = "rbxassetid://6457947928" },
			{ id = "102609114992392", img = "rbxassetid://102609114992392" },
			{ id = "8180153808", img = "rbxassetid://8180153808" },
			{ id = "11761613059", img = "rbxassetid://11761613059" },
			{ id = "139546609567893", img = "rbxassetid://139546609567893" },
			{ id = "14430330747", img = "rbxassetid://14430330747" },
			{ id = "17256388271", img = "rbxassetid://17256388271" },
			{ id = "132372803152269", img = "rbxassetid://132372803152269" },
		}
		local c1 = {}
		local A1 = {}
		local u1 = {}
		local U1, L1, Y1 = 67, 51, 9
		local O1 = math.floor((#K1 + 3 - 1) / 3)
		local B1 = O1 * L1 + (O1 - 1) * Y1 + 10
		local O1, S1 = 246, 299
		local t1 = Instance.new("Frame", gui)
		t1.Name = "VH_BgPicker"
		t1.AnchorPoint = Vector2.new(0.5, 0.5)
		t1.Size = UDim2.new(0, O1, 0, S1)
		t1.Position = UDim2.new(0.5, 0, 0.5, 0)
		t1.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
		t1.BackgroundTransparency = 0.04
		t1.BorderSizePixel = 0
		t1.ZIndex = 50
		t1.Visible = false
		t1.Active = true
		Instance.new("UICorner", t1).CornerRadius = UDim.new(0, 18)
		local X1 = Instance.new("UIStroke", t1)
		X1.Thickness = 1.5
		X1.Transparency = 0.3
		local w1 = Instance.new("TextLabel", t1)
		w1.Size = UDim2.new(1, -92.0, 0, 32)
		w1.Position = UDim2.new(0, 16, 0, 6)
		w1.BackgroundTransparency = 1
		w1.Text = "Change Background"
		w1.TextColor3 = a1.white
		w1.Font = Enum.Font.GothamBold
		w1.TextSize = 15
		w1.TextStrokeTransparency = 0
		w1.ZIndex = 51
		local w1 = Instance.new("Frame", t1)
		w1.Size = UDim2.new(0, 51, 0, 2)
		w1.Position = UDim2.new(0, 16, 0, 35)
		w1.BorderSizePixel = 0
		w1.ZIndex = 51
		Instance.new("UICorner", w1).CornerRadius = UDim.new(1, 0)
		local o1 = Instance.new("TextButton", t1)
		o1.Size = UDim2.new(0, 67, 0, 28)
		o1.Position = UDim2.new(1, -76.0, 0, 8)
		o1.BackgroundColor3 = Color3.fromRGB(22, 6, 6)
		o1.BorderSizePixel = 0
		o1.Text = "Close"
		o1.TextColor3 = a1.white
		o1.Font = Enum.Font.GothamBold
		o1.TextSize = 13
		o1.RichText = false
		o1.ZIndex = 51
		Instance.new("UICorner", o1).CornerRadius = UDim.new(0, 9)
		local y1 = Instance.new("UIStroke", o1)
		y1.Thickness = 1.5
		local d1 = Instance.new("ScrollingFrame", t1)
		d1.Size = UDim2.new(1, -16.0, 1, -52.0)
		d1.Position = UDim2.new(0, 7, 0, 44)
		d1.BackgroundTransparency = 1
		d1.BorderSizePixel = 0
		d1.Active = true
		d1.ScrollingEnabled = true
		d1.ScrollingDirection = Enum.ScrollingDirection.Y
		d1.ElasticBehavior = Enum.ElasticBehavior.Always
		d1.CanvasSize = UDim2.new(0, 0, 0, B1)
		d1.ScrollBarThickness = 8
		d1.ScrollBarImageColor3 = a1.purple
		d1.ScrollBarImageTransparency = 1
		d1.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		d1.ZIndex = 51
		local B1 = 3 * U1 + 2 * Y1
		local function WT(xT)
			local mT = {}
			for QT, aT in ipairs(K1) do
				if zt.bgFavorites[aT.id] then
					table.insert(mT, QT)
				end
			end

			for QT, aT in ipairs(K1) do
				if not zt.bgFavorites[aT.id] then
					table.insert(mT, QT)
				end
			end

			for QT, aT in ipairs(mT) do
				local mT = (QT - 1) % 3
				local sT = math.floor((QT - 1) / 3)
				local QT = c1[aT]
				if QT then
					QT.Position = UDim2.new(0.5, -B1 / 2 + mT * (U1 + Y1), 0, sT * (L1 + Y1))
				end

				local Y1 = u1[aT]
				if Y1 then
					Y1.TextColor3 = zt.bgFavorites[K1[aT].id] and Color3.fromRGB(255, 215, 45)
						or Color3.fromRGB(235, 235, 235)
				end
			end

			if xT then
				d1.CanvasPosition = Vector2.new(0, 0)
			end
		end

		_G._VH_refreshBgFavorites = WT
		for Y1, B1 in ipairs(K1) do
			local xT = Instance.new("ImageButton", d1)
			xT.Size = UDim2.new(0, U1, 0, L1)
			xT.Image = B1.img
			xT.ScaleType = Enum.ScaleType.Crop
			xT.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			xT.BorderSizePixel = 0
			xT.ZIndex = 52
			Instance.new("UICorner", xT).CornerRadius = UDim.new(0, 8)
			local Z = Instance.new("UIStroke", xT)
			Z.Thickness = 2
			Z.Color = a1.border
			c1[Y1] = xT
			A1[Y1] = Z
			local Z = Instance.new("TextButton", xT)
			Z.Name = "FavoriteStar"
			Z.AnchorPoint = Vector2.new(1, 1)
			Z.Size = UDim2.new(0, 28, 0, 28)
			Z.Position = UDim2.new(1, -3.0, 1, -3.0)
			Z.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Z.BackgroundTransparency = 0.22
			Z.BorderSizePixel = 0
			Z.Text = "\226\152\133"
			Z.TextColor3 = Color3.fromRGB(235, 235, 235)
			Z.Font = Enum.Font.Gotham
			Z.TextSize = 21
			Z.RichText = false
			Z.ZIndex = 54
			Instance.new("UICorner", Z).CornerRadius = UDim.new(1, 0)
			local c1 = Instance.new("UIStroke", Z)
			c1.Color = Color3.fromRGB(0, 0, 0)
			c1.Thickness = 1.5
			c1.Transparency = 0.15
			u1[Y1] = Z
			Z.Activated:Connect(function()
				if zt.bgFavorites[B1.id] then
					zt.bgFavorites[B1.id] = nil
				else
					zt.bgFavorites[B1.id] = true
				end

				WT(true)
				if _scfg then
					_scfg(true)
				end
			end)
			xT.Activated:Connect(function()
				zt.activeBgImg = B1.id
				if setBgImgVisual then
					setBgImgVisual(B1.id)
				end

				_scfg()
			end)
		end

		WT(false)
		local Z = false
		local function c1()
			if Z then
				return
			end

			Z = true
			t1.Size = UDim2.new(0, O1 * 0.82, 0, S1 * 0.82)
			t1.BackgroundTransparency = 1
			t1.Visible = true
			gt:Create(
				t1,
				TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, O1, 0, S1) }
			):Play()
			gt:Create(t1, TweenInfo.new(0.18), { BackgroundTransparency = 0.04 }):Play()
			task.delay(0.28, function()
				Z = false
			end)
		end

		local function u1()
			if Z then
				return
			end

			Z = true
			gt:Create(
				t1,
				TweenInfo.new(0.16),
				{ Size = UDim2.new(0, O1 * 0.82, 0, S1 * 0.82), BackgroundTransparency = 1 }
			):Play()
			task.delay(0.16, function()
				t1.Visible = false
				t1.Size = UDim2.new(0, O1, 0, S1)
				t1.BackgroundTransparency = 0.04
				Z = false
			end)
		end

		l1(o1, u1)
		_G._VH_openBgPicker = c1
		local function Z(c1)
			X1.Color = c1
			w1.BackgroundColor3 = c1
			y1.Color = c1
			d1.ScrollBarImageColor3 = c1
			d1.ScrollBarImageTransparency = 1
		end

		_G._VH_bgPickerSetTheme = Z
		Z(a1.purple)
		local Z = {
			purple = kt.purple,
			dpurple = kt.dpurple,
			lpurple = kt.lpurple,
			on = kt.on,
			stkBg = kt.stkBg,
			stkBrd = kt.stkBrd,
			stkAct = kt.stkAct,
		}
		local function c1(u1)
			return u1.R * 0.299 + u1.G * 0.587 + u1.B * 0.114
		end

		local function u1(U1)
			local L1 = U1
			while L1 and L1 ~= gui do
				local U1, Y1 = pcall(function()
					return L1.BackgroundTransparency
				end)
				if U1 and Y1 ~= nil and Y1 < 0.5 then
					local U1, Y1 = pcall(function()
						return L1.BackgroundColor3
					end)
					if U1 and typeof(Y1) == "Color3" then
						return Y1
					end
				end

				L1 = L1.Parent
			end

			return a1.card
		end

		_VH_fixTextContrast = function()
			if not gui then
				return
			end

			local U1 = c1(a1.purple) < 0.35
			for L1, L1 in ipairs(gui:GetDescendants()) do
				if L1:IsA("TextLabel") or L1:IsA("TextButton") or L1:IsA("TextBox") then
					local Y1, O1 = pcall(function()
						return L1.TextTransparency
					end)
					if Y1 and O1 < 0.95 then
						if U1 then
							if L1.TextColor3 ~= Color3.fromRGB(255, 255, 255) then
								L1.TextColor3 = Color3.fromRGB(255, 255, 255)
							end
						else
							local U1 = L1.TextColor3
							local Y1 = u1(L1)
							if math.abs(c1(U1) - c1(Y1)) < 0.25 then
								L1.TextColor3 = c1(Y1) < 0.5 and Color3.fromRGB(255, 255, 255)
									or Color3.fromRGB(15, 15, 15)
							end
						end
					end
				end
			end
		end

		task.spawn(function()
			while true do
				task.wait(0.75)
				if gui and c1(a1.purple) < 0.35 then
					pcall(_VH_fixTextContrast)
				end
			end
		end)
		local function c1()
			if not k1 then
				return
			end

			for u1, U1 in pairs(k1) do
				local k1 = P1 and P1[u1] == C1
				U1.BackgroundColor3 = k1 and a1.purple or Color3.fromRGB(0, 0, 0)
				U1.BackgroundTransparency = k1 and 0.25 or 0.4
				U1.TextColor3 = k1 and a1.void or a1.white
				local C1 = U1:FindFirstChildOfClass("UIStroke")
				if C1 then
					C1.Color = k1 and a1.purple or a1.border
				end
			end
		end

		local k1 = "original"
		local C1 = setmetatable({}, { __mode = "k" })
		N1 = function(P1)
			if P1 == true then
				P1 = "vampire"
			elseif P1 == false then
				P1 = "original"
			end

			if P1 == k1 then
				return
			end

			local u1 = P1 == "forest" or P1 == "jungle" or P1 == "16948826915" or P1 == "102609114992392"
			local U1 = P1 == "ocean" or P1 == "79809183056960"
			local L1 = P1 == "79455822331118" or P1 == "8180153808" or P1 == "11761613059"
			local Y1 = P1 == "vampire" or P1 == "139546609567893"
			local O1 = P1 == "golden" or P1 == "132372803152269"
			local B1 = P1 == "123540425987418" or P1 == "122195659108931"
			local S1 = P1 == "6457947928"
			local t1 = P1 == "14430330747" or P1 == "17256388271"
			local X1 = Y1 and M1
				or O1 and q1
				or u1 and Z1
				or U1 and E1
				or L1 and r1
				or B1 and j1
				or S1 and e1
				or t1 and T1
				or kt
			local kt = X1.purple
			local M1 = Y1 and Color3.fromRGB(180, 180, 180) or X1.purple
			local M1 = Y1 and Color3.fromRGB(160, 160, 160) or X1.lpurple
			local M1 = {
				purple = X1.purple,
				dpurple = X1.dpurple,
				lpurple = X1.lpurple,
				on = X1.on,
				stkBg = X1.stkBg,
				stkBrd = X1.stkBrd,
				stkAct = X1.stkAct,
			}
			local q1 = k1 == "79455822331118" or k1 == "8180153808" or k1 == "11761613059"
			local Z1 = q1 and 0.001 or 0.05
			local function q1(E1, r1)
				return math.abs(E1.R - r1.R) < Z1 and math.abs(E1.G - r1.G) < Z1 and math.abs(E1.B - r1.B) < Z1
			end

			local function Z1(E1)
				for r1, j1 in pairs(Z) do
					if q1(E1, j1) then
						return r1
					end
				end

				return nil
			end

			local q1 = gui:GetDescendants()
			for E1, E1 in ipairs(q1) do
				local r1 = C1[E1]
				local j1 = pbFrame and (E1 == pbFrame or E1:IsDescendantOf(pbFrame))
				if j1 then
					C1[E1] = nil
				elseif E1:IsA("UIGradient") then
					if r1 and r1.gradient then
						pcall(function()
							E1.Color = ColorSequence.new(kt)
						end)
					else
						local j1, e1 = pcall(function()
							return E1.Color
						end)
						if j1 then
							for j1, j1 in ipairs(e1.Keypoints) do
								if Z1(j1.Value) then
									r1 = { gradient = true }
									C1[E1] = r1
									pcall(function()
										E1.Color = ColorSequence.new(kt)
									end)
									break
								end
							end
						end
					end
				else
					r1 = r1 or {}
					for kt, kt in ipairs({
						"BackgroundColor3",
						"TextColor3",
						"Color",
						"ImageColor3",
						"ScrollBarImageColor3",
					}) do
						local j1 = r1[kt]
						if not j1 then
							local e1, T1 = pcall(function()
								return E1[kt]
							end)
							if e1 and typeof(T1) == "Color3" then
								j1 = Z1(T1)
								if j1 then
									r1[kt] = j1
								end
							end
						end

						if j1 then
							pcall(function()
								E1[kt] = M1[j1]
							end)
						end
					end

					if next(r1) then
						C1[E1] = r1
					end
				end
			end

			for kt, C1 in pairs(X1) do
				a1[kt] = C1
			end

			Z = M1
			k1 = P1
			if applyBillboardTheme then
				applyBillboardTheme()
			end

			if _G._VH_refreshKickWarningTheme then
				pcall(_G._VH_refreshKickWarningTheme)
			end

			c1()
			if At then
				At(zt.sideButtonLook, true)
			end

			if ut then
				ut(true)
			end

			pcall(function()
				for Z, Z in ipairs(q1) do
					if Z:IsA("ScrollingFrame") then
						Z.ScrollBarImageColor3 = a1.purple
						Z.ScrollBarImageTransparency = 1
					end
				end
			end)
			pcall(function()
				for Z, Z in ipairs(bt:GetPlayers()) do
					if Z ~= Rt and Z.Character then
						local ft = Z.Character:FindFirstChild("VampireHighlight")
						if ft then
							ft.FillColor = a1.purple
							ft.OutlineColor = a1.purple
						end
					end
				end
			end)
			q1 = nil
			if _VH_fixTextContrast then
				pcall(_VH_fixTextContrast)
			end
		end

		setBgImgVisual = function(Z)
			if Z == nil then
				Z = "original"
			end

			local ft = {
				original = "rbxassetid://14640607134",
				vampire = "rbxassetid://114138477258742",
				golden = "rbxassetid://113621109176868",
				forest = "rbxassetid://15108586724",
				jungle = "rbxassetid://11850170603",
				ocean = "rbxassetid://116893313684229",
				["79809183056960"] = "rbxassetid://79809183056960",
				["79455822331118"] = "rbxassetid://79455822331118",
				["16948826915"] = "rbxassetid://16948826915",
				["101793424727240"] = "rbxassetid://101793424727240",
				["123540425987418"] = "rbxassetid://123540425987418",
				["122195659108931"] = "rbxassetid://122195659108931",
				["6457947928"] = "rbxassetid://6457947928",
				["102609114992392"] = "rbxassetid://102609114992392",
				["8180153808"] = "rbxassetid://8180153808",
				["11761613059"] = "rbxassetid://11761613059",
				["139546609567893"] = "rbxassetid://139546609567893",
				["14430330747"] = "rbxassetid://14430330747",
				["17256388271"] = "rbxassetid://17256388271",
				["132372803152269"] = "rbxassetid://132372803152269",
			}
			local kt = ft[Z]
			if kt and R1 then
				R1.Image = kt
			end

			zt.activeBgImg = Z
			if N1 then
				N1(Z)
			end

			for ft, kt in ipairs(K1) do
				tw(A1[ft], 0.15, { Color = kt.id == Z and a1.purple or a1.border })
			end
		end
	end

	P("Config", 4)
	I1("Config")
	P("Config", 4)
	saveBtn = D1("Config", "Save Config", function()
		zt.speedChangeMethodSaved = zt.speedChangeMethod
		zt.sideButtonDragModeSaved = zt.sideButtonDragMode
		if pbFrame then
			local Z = pbFrame.Position
			zt.stealBarPos = string.format("%.4f,%.1f,%.4f,%.1f", Z.X.Scale, Z.X.Offset, Z.Y.Scale, Z.Y.Offset)
		end

		_scfg()
	end)
	task.wait()
	P("Config", 6)
	P("Custom", 8)
	It("Custom", "Side Pictures")
	D1("Custom", "Change Background", function()
		if _G._VH_openBgPicker then
			_G._VH_openBgPicker()
		end
	end)
	P("Custom", 6)
	I1("Custom")
	P("Custom", 6)
	It("Custom", "Sizes")
	do
		local Z = h1("Custom", 42)
		z1(Z, "GUI Scale", 10, 0, 0.6, 42, 10, a1.white, Enum.Font.GothamBold)
		local ft = Instance.new("TextLabel", Z)
		ft.Size = UDim2.new(0, 50, 0, 28)
		ft.Position = UDim2.new(1, -112.0, 0.5, -14.0)
		ft.BackgroundTransparency = 1
		ft.Text = string.format("%.2f", zt.guiScale)
		ft.TextColor3 = a1.purple
		ft.Font = Enum.Font.Gotham
		ft.TextSize = 13
		ft.ZIndex = 5
		ft.TextStrokeTransparency = 0
		local kt = Instance.new("TextButton", Z)
		kt.Size = UDim2.new(0, 40, 0, 40)
		kt.Position = UDim2.new(1, -48.0, 0.5, -20.0)
		kt.BackgroundColor3 = a1.void
		kt.BorderSizePixel = 0
		kt.Text = "\226\150\182"
		kt.TextColor3 = a1.lpurple
		kt.Font = Enum.Font.GothamBold
		kt.TextSize = 20
		kt.RichText = false
		kt.ZIndex = 5
		Instance.new("UICorner", kt).CornerRadius = UDim.new(0, 10)
		local M1 = Instance.new("UIStroke", kt)
		M1.Color = a1.border
		M1.Thickness = 1.5
		local M1 = h1("Custom", 42)
		M1.Visible = false
		local R1 = Instance.new("TextButton", M1)
		R1.Size = UDim2.new(0, 28, 0, 28)
		R1.Position = UDim2.new(1, -118.0, 0.5, -14.0)
		R1.BackgroundColor3 = a1.void
		R1.BorderSizePixel = 0
		R1.Text = "-"
		R1.TextColor3 = a1.lpurple
		R1.Font = Enum.Font.Gotham
		R1.TextSize = 16
		R1.ZIndex = 5
		Instance.new("UICorner", R1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", R1).Color = a1.border
		local k1 = Instance.new("TextLabel", M1)
		k1.Size = UDim2.new(0, 42, 0, 28)
		k1.Position = UDim2.new(1, -86.0, 0.5, -14.0)
		k1.BackgroundColor3 = a1.void
		k1.BorderSizePixel = 0
		k1.Text = string.format("%.2f", zt.guiScale)
		k1.TextColor3 = a1.purple
		k1.Font = Enum.Font.Gotham
		k1.TextSize = 13
		k1.ZIndex = 5
		Instance.new("UICorner", k1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", k1).Color = a1.border
		local C1 = Instance.new("TextButton", M1)
		C1.Size = UDim2.new(0, 28, 0, 28)
		C1.Position = UDim2.new(1, -40.0, 0.5, -14.0)
		C1.BackgroundColor3 = a1.void
		C1.BorderSizePixel = 0
		C1.Text = "+"
		C1.TextColor3 = a1.lpurple
		C1.Font = Enum.Font.Gotham
		C1.TextSize = 16
		C1.ZIndex = 5
		Instance.new("UICorner", C1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", C1).Color = a1.border
		local P1 = false
		local function q1()
			zt.guiScale = math.clamp(zt.guiScale, 0.5, 1.5)
			F1.Scale = zt.guiScale
			k1.Text = string.format("%.2f", zt.guiScale)
			ft.Text = string.format("%.2f", zt.guiScale)
		end

		local Z1 = Instance.new("TextButton", Z)
		Z1.Size = UDim2.new(1, 0, 1, 0)
		Z1.BackgroundTransparency = 1
		Z1.Text = ""
		Z1.ZIndex = 6
		l1(Z1, function()
			P1 = not P1
			kt.Text = P1 and "\226\150\188" or "\226\150\182"
			M1.Visible = P1
		end)
		l1(R1, function()
			zt.guiScale = math.clamp(zt.guiScale - 0.05, 0.5, 1.5)
			q1()
		end)
		l1(C1, function()
			zt.guiScale = math.clamp(zt.guiScale + 0.05, 0.5, 1.5)
			q1()
		end)
		_G._applyGUIScaleLabel = function()
			k1.Text = string.format("%.2f", zt.guiScale)
			ft.Text = string.format("%.2f", zt.guiScale)
		end

		_G._applyGUIScale = q1
	end

	P("Custom", 4)
	local Z, ft, kt
	do
		local M1 = h1("Custom", 42)
		Z = M1
		ft = nil
		z1(M1, "Progress Bar Size", 10, 0, 0.6, 42, 10, a1.white, Enum.Font.GothamBold)
		local R1 = Instance.new("TextButton", M1)
		R1.Size = UDim2.new(0, 28, 0, 28)
		R1.Position = UDim2.new(1, -118.0, 0.5, -14.0)
		R1.BackgroundColor3 = a1.void
		R1.BorderSizePixel = 0
		R1.Text = "-"
		R1.TextColor3 = a1.lpurple
		R1.Font = Enum.Font.Gotham
		R1.TextSize = 16
		R1.ZIndex = 5
		Instance.new("UICorner", R1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", R1).Color = a1.border
		local k1 = Instance.new("TextLabel", M1)
		k1.Size = UDim2.new(0, 42, 0, 28)
		k1.Position = UDim2.new(1, -86.0, 0.5, -14.0)
		k1.BackgroundColor3 = a1.void
		k1.BorderSizePixel = 0
		k1.Text = string.format("%.2f", zt.progressBarSize)
		k1.TextColor3 = a1.purple
		k1.Font = Enum.Font.Gotham
		k1.TextSize = 13
		k1.ZIndex = 5
		Instance.new("UICorner", k1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", k1).Color = a1.border
		local C1 = Instance.new("TextButton", M1)
		C1.Size = UDim2.new(0, 28, 0, 28)
		C1.Position = UDim2.new(1, -40.0, 0.5, -14.0)
		C1.BackgroundColor3 = a1.void
		C1.BorderSizePixel = 0
		C1.Text = "+"
		C1.TextColor3 = a1.lpurple
		C1.Font = Enum.Font.Gotham
		C1.TextSize = 16
		C1.ZIndex = 5
		Instance.new("UICorner", C1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", C1).Color = a1.border
		local function M1()
			zt.progressBarSize = math.clamp(zt.progressBarSize, 0.6, 1.4)
			k1.Text = string.format("%.2f", zt.progressBarSize)
			Yt()
		end

		l1(R1, function()
			zt.progressBarSize = math.clamp(zt.progressBarSize - 0.05, 0.6, 1.4)
			M1()
		end)
		l1(C1, function()
			zt.progressBarSize = math.clamp(zt.progressBarSize + 0.05, 0.6, 1.4)
			M1()
		end)
		_G._applyProgressBarSize = M1
	end

	P("Custom", 4)
	kt = D1("Custom", "Reset Bar Position", function()
		zt.stealBarPos = nil
		if Yt then
			Yt(true)
		end
	end)
	local M1, R1
	do
		local k1 = h1("Custom", 42)
		M1 = k1
		z1(k1, "Side Button Scale", 10, 0, 0.6, 42, 10, a1.white, Enum.Font.GothamBold)
		local C1 = Instance.new("TextLabel", k1)
		C1.Size = UDim2.new(0, 50, 0, 28)
		C1.Position = UDim2.new(1, -112.0, 0.5, -14.0)
		C1.BackgroundTransparency = 1
		C1.Text = string.format("%.2f", zt.sideButtonScale)
		C1.TextColor3 = a1.purple
		C1.Font = Enum.Font.Gotham
		C1.TextSize = 13
		C1.ZIndex = 5
		C1.TextStrokeTransparency = 0
		local P1 = Instance.new("TextButton", k1)
		P1.Size = UDim2.new(0, 40, 0, 40)
		P1.Position = UDim2.new(1, -48.0, 0.5, -20.0)
		P1.BackgroundColor3 = a1.void
		P1.BorderSizePixel = 0
		P1.Text = "\226\150\182"
		P1.TextColor3 = a1.lpurple
		P1.Font = Enum.Font.GothamBold
		P1.TextSize = 20
		P1.RichText = false
		P1.ZIndex = 5
		Instance.new("UICorner", P1).CornerRadius = UDim.new(0, 10)
		local q1 = Instance.new("UIStroke", P1)
		q1.Color = a1.border
		q1.Thickness = 1.5
		local q1 = h1("Custom", 42)
		R1 = q1
		q1.Visible = false
		local Z1 = Instance.new("TextButton", q1)
		Z1.Size = UDim2.new(0, 28, 0, 28)
		Z1.Position = UDim2.new(1, -118.0, 0.5, -14.0)
		Z1.BackgroundColor3 = a1.void
		Z1.BorderSizePixel = 0
		Z1.Text = "-"
		Z1.TextColor3 = a1.lpurple
		Z1.Font = Enum.Font.Gotham
		Z1.TextSize = 16
		Z1.ZIndex = 5
		Instance.new("UICorner", Z1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", Z1).Color = a1.border
		local E1 = Instance.new("TextLabel", q1)
		E1.Size = UDim2.new(0, 42, 0, 28)
		E1.Position = UDim2.new(1, -86.0, 0.5, -14.0)
		E1.BackgroundColor3 = a1.void
		E1.BorderSizePixel = 0
		E1.Text = string.format("%.2f", zt.sideButtonScale)
		E1.TextColor3 = a1.purple
		E1.Font = Enum.Font.Gotham
		E1.TextSize = 13
		E1.ZIndex = 5
		Instance.new("UICorner", E1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", E1).Color = a1.border
		local r1 = Instance.new("TextButton", q1)
		r1.Size = UDim2.new(0, 28, 0, 28)
		r1.Position = UDim2.new(1, -40.0, 0.5, -14.0)
		r1.BackgroundColor3 = a1.void
		r1.BorderSizePixel = 0
		r1.Text = "+"
		r1.TextColor3 = a1.lpurple
		r1.Font = Enum.Font.Gotham
		r1.TextSize = 16
		r1.ZIndex = 5
		Instance.new("UICorner", r1).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", r1).Color = a1.border
		local j1 = false
		local function e1()
			zt.sideButtonScale = math.clamp(zt.sideButtonScale, 0.5, 1.5)
			E1.Text = string.format("%.2f", zt.sideButtonScale)
			C1.Text = string.format("%.2f", zt.sideButtonScale)
			if not Ot then
				return
			end

			local C1 = zt.sideButtonPositions and next(zt.sideButtonPositions) ~= nil
			for E1, T1 in ipairs(Ot) do
				local N1 = Bt[T1.key]
				if N1 and N1.frame then
					local K1 = N1.frame
					Xt(T1.key)
					K1.TextSize = T1.wide and 14 * zt.sideButtonScale or 11 * zt.sideButtonScale
					if not C1 then
						K1.Position = sideDefaultPos(E1)
					end
				end
			end
		end

		local C1 = Instance.new("TextButton", k1)
		C1.Size = UDim2.new(1, 0, 1, 0)
		C1.BackgroundTransparency = 1
		C1.Text = ""
		C1.ZIndex = 6
		l1(C1, function()
			j1 = not j1
			P1.Text = j1 and "\226\150\188" or "\226\150\182"
			q1.Visible = j1
		end)
		l1(Z1, function()
			zt.sideButtonScale = math.clamp(zt.sideButtonScale - 0.05, 0.5, 1.5)
			e1()
		end)
		l1(r1, function()
			zt.sideButtonScale = math.clamp(zt.sideButtonScale + 0.05, 0.5, 1.5)
			e1()
		end)
		_G._applySideButtonScale = e1
	end

	P("Custom", 2)
	I1("Custom")
	P("Custom", 2)
	It("Custom", "Sky Colors")
	do
		local k1 = {
			{ id = "default", label = "Def" },
			{ id = "blue", label = "Blue" },
			{ id = "night", label = "Night" },
			{
				id = "day",
				label = "Day",
			},
		}
		local C1 = { default = "Def", blue = "Blue", night = "Night", day = "Day" }
		local P1 = h1("Custom", 42)
		z1(P1, "Sky Mode", 10, 0, 0.6, 42, 10, a1.white, Enum.Font.GothamBold)
		local q1 = Instance.new("TextLabel", P1)
		q1.Size = UDim2.new(0, 50, 0, 28)
		q1.Position = UDim2.new(1, -112.0, 0.5, -14.0)
		q1.BackgroundTransparency = 1
		q1.Text = C1[zt.activeSky] or "Def"
		q1.TextColor3 = a1.purple
		q1.Font = Enum.Font.Gotham
		q1.TextSize = 13
		q1.ZIndex = 5
		q1.TextStrokeTransparency = 0
		local Z1 = Instance.new("TextButton", P1)
		Z1.Size = UDim2.new(0, 40, 0, 40)
		Z1.Position = UDim2.new(1, -48.0, 0.5, -20.0)
		Z1.BackgroundColor3 = a1.void
		Z1.BorderSizePixel = 0
		Z1.Text = "\226\150\182"
		Z1.TextColor3 = a1.lpurple
		Z1.Font = Enum.Font.GothamBold
		Z1.TextSize = 20
		Z1.RichText = false
		Z1.ZIndex = 5
		Instance.new("UICorner", Z1).CornerRadius = UDim.new(0, 10)
		local E1 = Instance.new("UIStroke", Z1)
		E1.Color = a1.border
		E1.Thickness = 1.5
		local E1 = h1("Custom", 42)
		E1.Visible = false
		z1(E1, "Sky", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local r1 = {}
		local j1 = {}
		for e1, T1 in ipairs(k1) do
			local N1 = Instance.new("TextButton", E1)
			N1.Size = UDim2.new(0, 40, 0, 28)
			local K1 = (#k1 - e1) * 46
			N1.Position = UDim2.new(1, -48.0 - K1, 0.5, -14.0)
			N1.BorderSizePixel = 0
			N1.Text = T1.label
			N1.Font = Enum.Font.GothamBold
			N1.TextSize = 10
			N1.RichText = false
			N1.ZIndex = 5
			Instance.new("UICorner", N1).CornerRadius = UDim.new(0, 9)
			local K1 = Instance.new("UIStroke", N1)
			K1.Thickness = 1.5
			r1[e1] = N1
			j1[e1] = K1
			l1(N1, function()
				applySky(T1.id)
			end)
		end

		local e1 = _ssv
		_ssv = function(T1)
			if e1 then
				e1(T1)
			end

			if T1 == nil then
				T1 = "default"
			end

			q1.Text = C1[T1] or "Def"
			for C1, q1 in ipairs(k1) do
				local k1 = q1.id == T1
				tw(r1[C1], 0.15, { BackgroundColor3 = k1 and a1.purple or a1.void })
				r1[C1].TextColor3 = k1 and a1.void or a1.dim
				tw(j1[C1], 0.15, { Color = k1 and a1.purple or a1.border })
			end
		end

		local k1 = false
		local C1 = Instance.new("TextButton", P1)
		C1.Size = UDim2.new(1, 0, 1, 0)
		C1.BackgroundTransparency = 1
		C1.Text = ""
		C1.ZIndex = 6
		l1(C1, function()
			k1 = not k1
			Z1.Text = k1 and "\226\150\188" or "\226\150\182"
			E1.Visible = k1
		end)
		_ssv(zt.activeSky)
	end

	task.wait()
	P("Custom", 2)
	I1("Custom")
	P("Custom", 2)
	It("Custom", "Avatar Items")
	setKorbloxToggle = v1("Custom", "Korblox", nil, false, function(k1)
		zt.korbloxEnabled = k1
		applyKorbloxToChar(Rt.Character, k1)
	end)
	setHeadlessToggle = v1("Custom", "Headless", nil, false, function(k1)
		zt.headlessEnabled = k1
		applyHeadlessToChar(Rt.Character, k1)
	end)
	task.wait()
	P("Custom", 2)
	I1("Custom")
	P("Custom", 2)
	It("Custom", "Safe Mode")
	do
		local k1, C1, P1
		local q1
		k1, _, C1 = v1("Custom", "Safe Mode", nil, zt.safeModeEnabled, function(Z1)
			q1(Z1)
		end)
		for Z1, Z1 in ipairs(C1:GetChildren()) do
			if Z1:IsA("Frame") or Z1:IsA("TextButton") then
				local E1 = Z1.Position
				if E1.X.Scale == 1 and E1.X.Offset == -70.0 then
					Z1.Position = UDim2.new(1, -108.0, E1.Y.Scale, E1.Y.Offset)
				end
			end
		end

		local Z1 = Instance.new("TextButton", C1)
		Z1.Size = UDim2.new(0, 34, 0, 34)
		Z1.Position = UDim2.new(1, -44.0, 0.5, -17.0)
		Z1.BackgroundColor3 = a1.void
		Z1.BackgroundTransparency = 0.15
		Z1.BorderSizePixel = 0
		Z1.Text = "\226\150\182"
		Z1.TextColor3 = a1.lpurple
		Z1.Font = Enum.Font.GothamBold
		Z1.TextSize = 17
		Z1.RichText = false
		Z1.ZIndex = 8
		Instance.new("UICorner", Z1).CornerRadius = UDim.new(0, 10)
		local C1 = Instance.new("UIStroke", Z1)
		C1.Color = a1.border
		C1.Thickness = 1.4
		setDropBrainrotMode, _, P1 = v1("Custom", "Drop Brainrot", nil, zt.dropBrainrotMode, function(E1)
			zt.dropBrainrotMode = E1
		end)
		local E1
		Tt, _, E1 = v1("Custom", "Stop on Countdown", nil, zt.stopOnCountdown, function(r1)
			zt.stopOnCountdown = r1
		end)
		P1.Visible = false
		E1.Visible = false
		local r1 = false
		local function j1()
			P1.Visible = r1
			E1.Visible = r1
			Z1.Text = r1 and "\226\150\188" or "\226\150\182"
			tw(Z1, 0.15, { BackgroundTransparency = r1 and 0 or 0.15 })
			tw(C1, 0.15, { Color = r1 and a1.purple or a1.border })
		end

		j1()
		l1(Z1, function()
			r1 = not r1
			j1()
		end)
		q1 = function(C1)
			C1 = C1 and true or false
			zt.safeModeEnabled = C1
			if k1 then
				k1(C1)
			end
		end

		setSafeMode = function(k1)
			q1(k1)
		end
	end

	task.wait()
	P("Custom", 2)
	P("Custom", 2)
	I1("Custom")
	P("Custom", 2)
	It("Custom", "Mobile Buttons")
	local k1, C1
	do
		local P1 = h1("Custom", 42)
		k1 = P1
		z1(P1, "Button Type", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local q1 = Instance.new("TextButton", P1)
		q1.Size = UDim2.new(0, 62, 0, 28)
		q1.Position = UDim2.new(1, -138.0, 0.5, -14.0)
		q1.BorderSizePixel = 0
		q1.Text = "Square"
		q1.Font = Enum.Font.GothamBold
		q1.TextSize = 10
		q1.RichText = false
		q1.ZIndex = 5
		Instance.new("UICorner", q1).CornerRadius = UDim.new(0, 9)
		local Z1 = Instance.new("UIStroke", q1)
		Z1.Thickness = 1.5
		local E1 = Instance.new("TextButton", P1)
		E1.Size = UDim2.new(0, 62, 0, 28)
		E1.Position = UDim2.new(1, -70.0, 0.5, -14.0)
		E1.BorderSizePixel = 0
		E1.Text = "Circle"
		E1.Font = Enum.Font.GothamBold
		E1.TextSize = 10
		E1.RichText = false
		E1.ZIndex = 5
		Instance.new("UICorner", E1).CornerRadius = UDim.new(0, 9)
		local P1 = Instance.new("UIStroke", E1)
		P1.Thickness = 1.5
		ct = function(r1)
			if r1 ~= "circle" then
				r1 = "square"
			end

			zt.sideButtonType = r1
			local j1 = r1 == "square"
			tw(q1, 0.15, { BackgroundColor3 = j1 and a1.purple or a1.void })
			q1.TextColor3 = j1 and a1.void or a1.dim
			tw(Z1, 0.15, { Color = j1 and a1.purple or a1.border })
			tw(E1, 0.15, { BackgroundColor3 = not j1 and a1.purple or a1.void })
			E1.TextColor3 = not j1 and a1.void or a1.dim
			tw(P1, 0.15, { Color = not j1 and a1.purple or a1.border })
			wt()
		end

		l1(q1, function()
			ct("square")
		end)
		l1(E1, function()
			ct("circle")
		end)
		ct(zt.sideButtonType)
		local wt = h1("Custom", 42)
		C1 = wt
		z1(wt, "Looks", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
		local P1 = Instance.new("TextButton", wt)
		P1.Size = UDim2.new(0, 62, 0, 28)
		P1.Position = UDim2.new(1, -138.0, 0.5, -14.0)
		P1.BorderSizePixel = 0
		P1.Text = "Black"
		P1.Font = Enum.Font.GothamBold
		P1.TextSize = 10
		P1.RichText = false
		P1.ZIndex = 5
		Instance.new("UICorner", P1).CornerRadius = UDim.new(0, 9)
		local q1 = Instance.new("UIStroke", P1)
		q1.Thickness = 1.5
		local Z1 = Instance.new("TextButton", wt)
		Z1.Size = UDim2.new(0, 62, 0, 28)
		Z1.Position = UDim2.new(1, -70.0, 0.5, -14.0)
		Z1.BorderSizePixel = 0
		Z1.Text = "Clear"
		Z1.Font = Enum.Font.GothamBold
		Z1.TextSize = 10
		Z1.RichText = false
		Z1.ZIndex = 5
		Instance.new("UICorner", Z1).CornerRadius = UDim.new(0, 9)
		local wt = Instance.new("UIStroke", Z1)
		wt.Thickness = 1.5
		At = function(E1, r1)
			if E1 ~= "clear" then
				E1 = "black"
			end

			zt.sideButtonLook = E1
			local j1 = E1 == "black"
			tw(P1, 0.12, { BackgroundColor3 = j1 and a1.purple or a1.void })
			P1.TextColor3 = j1 and a1.void or a1.dim
			tw(q1, 0.12, { Color = j1 and a1.purple or a1.border })
			tw(Z1, 0.12, { BackgroundColor3 = not j1 and a1.purple or a1.void })
			Z1.TextColor3 = not j1 and a1.void or a1.dim
			tw(wt, 0.12, { Color = not j1 and a1.purple or a1.border })
			if not r1 and ut then
				ut(true)
			end
		end

		l1(P1, function()
			At("black")
		end)
		l1(Z1, function()
			At("clear")
		end)
		At(zt.sideButtonLook, true)
	end

	local wt
	local P1
	wt, _, P1 = v1("Custom", "Side Buttons", nil, true, function(wt)
		if type(setSideVisible) == "function" then
			setSideVisible(wt)
		end
	end)
	local wt = h1("Custom", 42)
	z1(wt, "Drag", 10, 0, 0, 42, 10, a1.white, Enum.Font.GothamBold)
	local q1 = Instance.new("TextButton", wt)
	q1.Size = UDim2.new(0, 62, 0, 28)
	q1.Position = UDim2.new(1, -138.0, 0.5, -14.0)
	q1.BorderSizePixel = 0
	q1.Text = "One"
	q1.Font = Enum.Font.GothamBold
	q1.TextSize = 10
	q1.RichText = false
	q1.ZIndex = 5
	Instance.new("UICorner", q1).CornerRadius = UDim.new(0, 9)
	local Z1 = Instance.new("UIStroke", q1)
	Z1.Thickness = 1.5
	local E1 = Instance.new("TextButton", wt)
	E1.Size = UDim2.new(0, 62, 0, 28)
	E1.Position = UDim2.new(1, -70.0, 0.5, -14.0)
	E1.BorderSizePixel = 0
	E1.Text = "All"
	E1.Font = Enum.Font.GothamBold
	E1.TextSize = 10
	E1.RichText = false
	E1.ZIndex = 5
	Instance.new("UICorner", E1).CornerRadius = UDim.new(0, 9)
	local r1 = Instance.new("UIStroke", E1)
	r1.Thickness = 1.5
	Ut = function(j1)
		if j1 ~= "all" then
			j1 = "one"
		end

		zt.sideButtonDragMode = j1
		local e1 = j1 == "one"
		tw(q1, 0.12, { BackgroundColor3 = e1 and a1.purple or a1.void })
		q1.TextColor3 = e1 and a1.void or a1.dim
		tw(Z1, 0.12, { Color = e1 and a1.purple or a1.border })
		tw(E1, 0.12, { BackgroundColor3 = not e1 and a1.purple or a1.void })
		E1.TextColor3 = not e1 and a1.void or a1.dim
		tw(r1, 0.12, { Color = not e1 and a1.purple or a1.border })
	end

	l1(q1, function()
		Ut("one")
	end)
	l1(E1, function()
		Ut("all")
	end)
	Ut(zt.sideButtonDragMode)
	if P1 and k1 and C1 then
		local q1 = k1.LayoutOrder
		P1.LayoutOrder = q1
		wt.LayoutOrder = q1 + 1
		k1.LayoutOrder = q1 + 2
		C1.LayoutOrder = q1 + 3
	end

	if M1 and R1 then
		M1.LayoutOrder = l("Custom")
		R1.LayoutOrder = l("Custom")
	end

	D1("Custom", "Reset Button Positions", function()
		for wt, M1 in ipairs(Ot) do
			if Bt[M1.key] and Bt[M1.key].frame then
				Bt[M1.key].frame.Position = sideDefaultPos(wt)
			end
		end

		zt.sideButtonPositions = {}
		_scfg()
	end)
	setLockButtons, _ = v1("Custom", "Lock Buttons", nil, false, function(wt)
		zt.sideButtonsLocked = wt
	end)
	zt._setButtonOutlineVisual = function()
		zt.showButtonOutline = false
	end

	P("Custom", 4)
	do
		local wt = {
			{ key = "autoLeft", label = "Auto Left" },
			{ key = "autoRight", label = "Auto Right" },
			{ key = "aimbot", label = "Aimbot" },
			{ key = "lagger", label = "Lagger Speed" },
			{ key = "laggerCarry", label = "Lagger Carry" },
			{ key = "drop", label = "Drop" },
			{ key = "carrySpeed", label = "Carry Speed" },
			{ key = "tpDown", label = "TP Down" },
			{ key = "tpDesync", label = "TP Desync" },
		}
		local M1 = {}
		local R1 = {}
		local k1 = h1("Custom", 42)
		z1(k1, "Choose Mobile Buttons", 10, 0, 0.75, 42, 10, a1.white, Enum.Font.GothamBold)
		local C1 = Instance.new("TextButton", k1)
		C1.Size = UDim2.new(0, 40, 0, 40)
		C1.Position = UDim2.new(1, -48.0, 0.5, -20.0)
		C1.BackgroundColor3 = a1.void
		C1.BorderSizePixel = 0
		C1.Text = "\226\150\182"
		C1.TextColor3 = a1.lpurple
		C1.Font = Enum.Font.GothamBold
		C1.TextSize = 20
		C1.RichText = false
		C1.ZIndex = 5
		Instance.new("UICorner", C1).CornerRadius = UDim.new(0, 10)
		local P1 = Instance.new("UIStroke", C1)
		P1.Color = a1.border
		P1.Thickness = 1.5
		if not _G._VH_mbSetVis then
			_G._VH_mbSetVis = {}
		end

		for P1, q1 in ipairs(wt) do
			local wt = false
			for Z1, Z1 in ipairs(zt.hiddenSideButtons or {}) do
				if Z1 == q1.key then
					wt = true
					break
				end
			end

			M1[q1.key] = not wt
			local Z1 = h1("Custom", 36)
			Z1.Visible = false
			R1[P1] = Z1
			z1(Z1, q1.label, 12, 0, 0.6, 36, 9, a1.white, Enum.Font.GothamMedium)
			local y = Instance.new("TextButton", Z1)
			y.Size = UDim2.new(0, 66, 0, 24)
			y.Position = UDim2.new(1, -76.0, 0.5, -12.0)
			local P1 = not wt
			y.BackgroundColor3 = P1 and a1.purple or a1.void
			y.BorderSizePixel = 0
			y.Text = P1 and "ON" or "OFF"
			y.TextColor3 = P1 and a1.void or a1.dim
			y.Font = Enum.Font.GothamBold
			y.TextSize = 11
			y.RichText = false
			y.ZIndex = 5
			Instance.new("UICorner", y).CornerRadius = UDim.new(0, 8)
			local wt = Instance.new("UIStroke", y)
			wt.Thickness = 1.5
			wt.Color = P1 and a1.purple or a1.border
			local P1 = q1.key
			local function q1(Z1)
				M1[P1] = Z1
				local E1 = zt.hiddenSideButtons or {}
				local r1 = false
				for j1, e1 in ipairs(E1) do
					if e1 == P1 then
						r1 = j1
						break
					end
				end

				if Z1 and r1 then
					UDim2.fromScale(E1, r1)
				elseif not Z1 and not r1 then
					table.insert(E1, P1)
				end

				zt.hiddenSideButtons = E1
				tw(y, 0.12, { BackgroundColor3 = Z1 and a1.purple or a1.void })
				y.TextColor3 = Z1 and a1.void or a1.dim
				tw(wt, 0.12, { Color = Z1 and a1.purple or a1.border })
				y.Text = Z1 and "ON" or "OFF"
				if Bt[P1] and Bt[P1].frame then
					Bt[P1].frame.Visible = Z1
				end
			end

			_G._VH_mbSetVis[P1] = q1
			l1(y, function()
				q1(not M1[P1])
			end)
		end

		local y = false
		local wt = Instance.new("TextButton", k1)
		wt.Size = UDim2.new(1, 0, 1, 0)
		wt.BackgroundTransparency = 1
		wt.Text = ""
		wt.ZIndex = 6
		l1(wt, function()
			y = not y
			C1.Text = y and "\226\150\188" or "\226\150\182"
			for wt, wt in ipairs(R1) do
				wt.Visible = y
			end
		end)
	end

	P("Custom", 2)
	do
		local y = {
			{ key = "autoLeft", label = "Auto Left" },
			{ key = "autoRight", label = "Auto Right" },
			{ key = "aimbot", label = "Aimbot" },
			{ key = "lagger", label = "Lagger Speed" },
			{ key = "laggerCarry", label = "Lagger Carry" },
			{ key = "drop", label = "Drop" },
			{ key = "carrySpeed", label = "Carry Speed" },
			{ key = "tpDown", label = "TP Down" },
			{ key = "tpDesync", label = "TP Desync" },
		}
		local wt = false
		local M1 = nil
		local R1 = {}
		local k1 = {}
		local C1 = {}
		local P1 = h1("Custom", 42)
		z1(P1, "Resize Mobile Buttons", 10, 0, 0.72, 42, 10, a1.white, Enum.Font.GothamBold)
		local q1 = Instance.new("TextButton", P1)
		q1.Size = UDim2.new(0, 40, 0, 40)
		q1.Position = UDim2.new(1, -48.0, 0.5, -20.0)
		q1.BackgroundColor3 = a1.void
		q1.BorderSizePixel = 0
		q1.Text = ">"
		q1.TextColor3 = a1.lpurple
		q1.Font = Enum.Font.GothamBold
		q1.TextSize = 20
		q1.RichText = false
		q1.ZIndex = 5
		Instance.new("UICorner", q1).CornerRadius = UDim.new(0, 10)
		local Z1 = Instance.new("UIStroke", q1)
		Z1.Color = a1.border
		Z1.Thickness = 1.5
		local Z1
		for E1, r1 in ipairs(y) do
			local j1, e1 = h1("Custom", 36)
			j1.Visible = false
			R1[E1] = j1
			C1[E1] = e1
			local e1 = Instance.new("TextButton", j1)
			e1.Size = UDim2.fromScale(1, 1)
			e1.BackgroundTransparency = 1
			e1.BorderSizePixel = 0
			e1.Text = r1.label
			e1.TextColor3 = a1.white
			e1.Font = Enum.Font.GothamBold
			e1.TextSize = 10
			e1.TextStrokeTransparency = 0
			e1.RichText = false
			e1.ZIndex = 5
			local j1 = Instance.new("UIPadding", e1)
			j1.PaddingLeft = UDim.new(0, 12)
			k1[E1] = e1
			l1(e1, function()
				Z1(r1)
			end)
		end

		local E1 = h1("Custom", 42)
		E1.Visible = false
		local r1 = z1(E1, "Select a mobile button above", 10, 0, 0.8, 42, 10, a1.lpurple, Enum.Font.GothamBold)
		local function j1(e1, T1, N1, K1, c1)
			z1(e1, T1, 10, 0, 0.25, 42, 10, a1.white, Enum.Font.GothamBold)
			local T1 = Instance.new("TextLabel", e1)
			T1.Size = UDim2.new(0, 48, 0, 28)
			T1.Position = UDim2.new(1, -56.0, 0.5, -14.0)
			T1.BackgroundTransparency = 1
			T1.TextColor3 = a1.purple
			T1.Font = Enum.Font.Gotham
			T1.TextSize = 10
			T1.TextStrokeTransparency = 0
			T1.ZIndex = 5
			local A1 = Instance.new("Frame", e1)
			A1.Size = UDim2.new(0, 118, 0, 6)
			A1.Position = UDim2.new(1, -182.0, 0.5, -3.0)
			A1.BackgroundColor3 = a1.void
			A1.BorderSizePixel = 0
			A1.ZIndex = 5
			Instance.new("UICorner", A1).CornerRadius = UDim.new(1, 0)
			local e1 = Instance.new("UIStroke", A1)
			e1.Color = a1.border
			e1.Thickness = 1
			local e1 = Instance.new("Frame", A1)
			e1.Size = UDim2.new(0, 0, 1, 0)
			e1.BackgroundColor3 = a1.purple
			e1.BorderSizePixel = 0
			e1.ZIndex = 6
			Instance.new("UICorner", e1).CornerRadius = UDim.new(1, 0)
			local u1 = Instance.new("Frame", A1)
			u1.Size = UDim2.new(0, 14, 0, 14)
			u1.Position = UDim2.new(0, -7.0, 0.5, -7.0)
			u1.BackgroundColor3 = a1.white
			u1.BorderSizePixel = 0
			u1.ZIndex = 7
			Instance.new("UICorner", u1).CornerRadius = UDim.new(1, 0)
			local U1 = Instance.new("UIStroke", u1)
			U1.Color = a1.purple
			U1.Thickness = 1.5
			local U1 = Instance.new("TextButton", A1)
			U1.Size = UDim2.new(1, 18, 1, 22)
			U1.Position = UDim2.new(0, -9.0, 0.5, -11.0)
			U1.BackgroundTransparency = 1
			U1.BorderSizePixel = 0
			U1.Text = ""
			U1.RichText = false
			U1.ZIndex = 8
			local L1 = N1
			local Y1 = false
			local O1 = nil
			local function B1(S1, t1)
				L1 = math.clamp(math.floor((tonumber(S1) or L1) + 0.5), N1, K1)
				local S1 = (L1 - N1) / (K1 - N1)
				e1.Size = UDim2.new(S1, 0, 1, 0)
				u1.Position = UDim2.new(S1, -7.0, 0.5, -7.0)
				T1.Text = string.format("%d px", L1)
				if t1 and c1 then
					c1(L1)
				end
			end

			local function e1(T1)
				if A1.AbsoluteSize.X <= 0 then
					return
				end

				local c1 = math.clamp((T1 - A1.AbsolutePosition.X) / A1.AbsoluteSize.X, 0, 1)
				B1(N1 + (K1 - N1) * c1, true)
			end

			U1.InputBegan:Connect(function(T1)
				if
					T1.UserInputType ~= Enum.UserInputType.MouseButton1
					and T1.UserInputType ~= Enum.UserInputType.MouseButton2
				then
					return
				end

				Y1 = true
				O1 = T1
				e1(T1.Position.X)
				T1.Changed:Connect(function()
					if T1.UserInputState == Enum.UserInputState.End then
						Y1 = false
						O1 = nil
					end
				end)
			end)
			U1.InputEnded:Connect(function(T1)
				if T1 == O1 then
					Y1 = false
					O1 = nil
				end
			end)
			Mt.InputChanged:Connect(function(T1)
				if not Y1 then
					return
				end

				local N1 = O1
					and O1.UserInputType == Enum.UserInputType.MouseButton1
					and T1.UserInputType == Enum.UserInputType.Touch
				if T1 == O1 or N1 then
					e1(T1.Position.X)
				end
			end)
			return {
				getValue = function()
					return L1
				end,
				setVisual = function(e1)
					B1(e1, false)
				end,
			}
		end

		local e1 = h1("Custom", 42)
		e1.Visible = false
		local T1 = h1("Custom", 42)
		T1.Visible = false
		local N1, K1
		local function c1(A1, A1)
			if not M1 or not N1 or not K1 then
				return
			end

			local u1 = N1.getValue()
			local U1 = K1.getValue()
			if zt.sideButtonType == "circle" then
				local L1 = math.min(W.SIDE_BUTTON_MIN_WIDTH, W.SIDE_BUTTON_MIN_HEIGHT)
				local Y1 = math.max(W.SIDE_BUTTON_MAX_WIDTH, W.SIDE_BUTTON_MAX_HEIGHT)
				local O1 = math.clamp(math.floor((tonumber(A1) or u1) + 0.5), L1, Y1)
				u1 = O1
				U1 = O1
				N1.setVisual(O1)
				K1.setVisual(O1)
			end

			zt.sideButtonSizes = zt.sideButtonSizes or {}
			zt.sideButtonSizes[M1] = { width = u1, height = U1 }
			Xt(M1)
		end

		N1 = j1(e1, "Width", W.SIDE_BUTTON_MIN_WIDTH, W.SIDE_BUTTON_MAX_WIDTH, function(A1)
			c1("width", A1)
		end)
		K1 = j1(T1, "Height", W.SIDE_BUTTON_MIN_HEIGHT, W.SIDE_BUTTON_MAX_HEIGHT, function(j1)
			c1("height", j1)
		end)
		local j1 = D1("Custom", "Reset Button Size", function()
			ot()
			if M1 then
				for ot, ot in ipairs(y) do
					if ot.key == M1 then
						Z1(ot, true)
						break
					end
				end
			end

			_scfg()
		end)
		j1.Visible = false
		local function ot()
			local D1 = M1 ~= nil
			for c1, A1 in ipairs(R1) do
				local R1 = y[c1].key == M1
				A1.Visible = wt and (not D1 or R1)
				k1[c1].TextColor3 = R1 and a1.lpurple or a1.white
				k1[c1].Text = R1 and y[c1].label .. "  (tap to change)" or y[c1].label
				C1[c1].Color = R1 and a1.purple or a1.border
			end

			E1.Visible = wt and D1
			e1.Visible = wt and D1
			T1.Visible = wt and D1
			j1.Visible = wt
		end

		Z1 = function(R1, k1)
			if M1 == R1.key and not k1 then
				M1 = nil
				ot()
				return
			end

			M1 = R1.key
			local k1
			for C1, C1 in ipairs(Ot) do
				if C1.key == M1 then
					k1 = C1
					break
				end
			end

			local C1, D1 = tt(k1)
			r1.Text = "Resize: " .. R1.label
			N1.setVisual(C1)
			K1.setVisual(D1)
			ot()
		end

		_G._VH_refreshMobileSizeUI = function()
			if not M1 then
				return
			end

			for R1, R1 in ipairs(y) do
				if R1.key == M1 then
					Z1(R1, true)
					return
				end
			end
		end

		local y = Instance.new("TextButton", P1)
		y.Size = UDim2.fromScale(1, 1)
		y.BackgroundTransparency = 1
		y.Text = ""
		y.ZIndex = 6
		l1(y, function()
			wt = not wt
			q1.Text = wt and "v" or ">"
			ot()
		end)
	end

	task.wait()
	P("Custom", 4)
	I1("Custom")
	P("Custom", 4)
	It("Custom", "Progress Bar")
	vt, _ = v1("Custom", "Show Bar", nil, zt.showProgressBar, function(y)
		zt.showProgressBar = y
		Yt()
	end)
	rt, _ = v1("Custom", "Stop On Hit", nil, zt.stopOnHitEnabled, function(y)
		zt.stopOnHitEnabled = y
	end)
	do
		local y = h1("Custom", 42)
		z1(y, "Customize Steal Bar", 10, 0, 0.7, 42, 10, a1.white, Enum.Font.GothamBold)
		local It = Instance.new("TextButton", y)
		It.Size = UDim2.new(0, 40, 0, 40)
		It.Position = UDim2.new(1, -48.0, 0.5, -20.0)
		It.BackgroundColor3 = a1.void
		It.BorderSizePixel = 0
		It.Text = ">"
		It.TextColor3 = a1.lpurple
		It.Font = Enum.Font.GothamBold
		It.TextSize = 20
		It.RichText = false
		It.ZIndex = 5
		Instance.new("UICorner", It).CornerRadius = UDim.new(0, 10)
		local wt = Instance.new("UIStroke", It)
		wt.Color = a1.border
		wt.Thickness = 1.5
		local wt, ot
		qt, _, wt = v1("Custom", "Show FPS", nil, zt.showProgressFPS, function(M1)
			zt.showProgressFPS = M1
			Yt()
		end)
		Zt, _, ot = v1("Custom", "Show Ping", nil, zt.showProgressPing, function(M1)
			zt.showProgressPing = M1
			Yt()
		end)
		if Z then
			Z.LayoutOrder = l("Custom")
			Z.Visible = false
		end

		if kt then
			kt.LayoutOrder = l("Custom")
			kt.Visible = false
		end

		local l = false
		local function M1()
			wt.Visible = l
			ot.Visible = l
			if Z then
				Z.Visible = l
			end

			if kt then
				kt.Visible = l
			end

			if not l and ft then
				ft.Visible = false
			end
		end

		M1()
		local Z = Instance.new("TextButton", y)
		Z.Size = UDim2.fromScale(1, 1)
		Z.BackgroundTransparency = 1
		Z.Text = ""
		Z.ZIndex = 6
		l1(Z, function()
			l = not l
			It.Text = l and "v" or ">"
			M1()
		end)
	end

	P("Custom", 6)
	local function P(l)
		local Z = Instance.new("UICorner", l)
		Z.CornerRadius = UDim.new(1, 0)
		return Z
	end

	local function l(Z, r, y)
		local ft = Instance.new("UIStroke", Z)
		ft.Color = r
		ft.Thickness = y
		return ft
	end

	pbFrame = Instance.new("Frame", gui)
	pbFrame.Visible = false
	pbFrame.Size = UDim2.new(0, 380, 0, 35)
	pbFrame.Position = UDim2.new(0.5, -190.0, 1, -56.0)
	pbFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	pbFrame.BorderSizePixel = 0
	pbFrame.Active = true
	P(pbFrame)
	l(pbFrame, Color3.fromRGB(0, 0, 0), 1.5)
	makeDraggable(pbFrame)
	pbBg = Instance.new("Frame", pbFrame)
	pbBg.Size = UDim2.new(0, 210, 1, 0)
	pbBg.Position = UDim2.new(0, 0, 0, 0)
	pbBg.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	pbBg.BorderSizePixel = 0
	pbBg.Active = true
	P(pbBg)
	l(pbBg, Color3.fromRGB(0, 0, 0), 1.5)
	progressFill = Instance.new("Frame", pbBg)
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(220, 45, 45)
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = 2
	P(progressFill)
	_pbContrastColor = function(P)
		local l = pbBg and pbBg.BackgroundColor3or
		Color3.fromRGB(22, 22, 22)
		local Z = P.R * 0.299 + P.G * 0.587 + P.B * 0.114
		local r = l.R * 0.299 + l.G * 0.587 + l.B * 0.114
		if math.abs(Z - r) >= 0.16 then
			return P
		end

		local l = r < 0.5 and 1 or 0
		return Color3.new(P.R + (l - P.R) * 0.6, P.G + (l - P.G) * 0.6, P.B + (l - P.B) * 0.6)
	end

	_pbFill = function(P)
		if not (progressFill and progressFill.Parent) then
			return
		end

		P = math.clamp(tonumber(P) or 0, 0, 1)
		progressFill.Visible = true
		if progressFill.ZIndex < 2 then
			progressFill.ZIndex = 2
		end

		if P <= 0.0005 then
			progressFill.Position = UDim2.new(0, 0, 0, 0)
			progressFill.Size = UDim2.new(0, 0, 1, 0)
			return
		end

		local l = pbBg and pbBg.AbsoluteSize.X or 0
		local Z = pbBg and pbBg.AbsoluteSize.Y or 0
		local r = 0
		local y = math.max(Z, 18)
		if y < 8 then
			y = 8
		end

		if l > 0 then
			local ft = P * l
			if ft < y then
				r = y - ft
			end
		end

		local ft = math.clamp(Z * 0.06, 1, 2)
		progressFill.Position = UDim2.new(0, ft, 0, 0)
		local Z = P * l + r - ft
		if Z < y then
			Z = y
		end

		progressFill.Size = UDim2.new(0, Z, 1, 0)
	end

	do
		local P = Instance.new("UIGradient", progressFill)
		P.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 25, 25)),
		})
	end

	do
		stealLbl = Instance.new("TextLabel", pbBg)
		stealLbl.Size = UDim2.new(1, -16.0, 1, 0)
		stealLbl.Position = UDim2.new(0, 12, 0, 0)
		stealLbl.BackgroundTransparency = 1
		stealLbl.Text = "STEAL"
		stealLbl.TextColor3 = Color3.fromRGB(255, 235, 235)
		stealLbl.Font = Enum.Font.Gotham
		stealLbl.TextSize = 13
		stealLbl.TextStrokeTransparency = 0
		stealLbl.ZIndex = 3
		stealLbl.TextTransparency = 0.5
		stealLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	end

	progressPct = Instance.new("TextLabel", pbBg)
	progressPct.Size = UDim2.new(1, -14.0, 1, 0)
	progressPct.Position = UDim2.new(0, 0, 0, 0)
	progressPct.BackgroundTransparency = 1
	progressPct.Text = ""
	progressPct.TextColor3 = Color3.fromRGB(255, 235, 235)
	progressPct.Font = Enum.Font.GothamBold
	progressPct.TextSize = 12
	progressPct.TextStrokeTransparency = 0
	progressPct.ZIndex = 3
	progressPct.TextTransparency = 0.5
	progressPct.TextStrokeColor3 = Color3.new(0, 0, 0)
	do
		local i = progressFill and progressFill:FindFirstChildOfClass("UIGradient")
		local function P(l, Z)
			if not progressFill then
				return
			end

			l = _pbContrastColor(l)
			Z = _pbContrastColor(Z)
			progressFill.BackgroundColor3 = l
			if i then
				i.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, l), ColorSequenceKeypoint.new(1, Z) })
			end
		end

		local function i()
			return a1.purple
		end

		local function l()
			local Z = a1.purple
			return Color3.new(Z.R * 0.62, Z.G * 0.62, Z.B * 0.62)
		end

		_G.StealBar = {
			SetProgress = function(Z)
				Z = math.clamp(tonumber(Z) or 0, 0, 1)
				if progressFill then
					_pbFill(Z)
				end

				if progressPct then
					progressPct.Text = math.floor(Z * 100 + 0.5) .. "%"
				end

				if Z >= 1 then
					P(Color3.fromRGB(245, 220, 195), Color3.fromRGB(220, 190, 160))
				else
					P(i(), l())
				end
			end,
			SetState = function(Z) end,
			Reset = function()
				if progressFill then
					_pbFill(0)
				end

				if progressPct then
					progressPct.Text = ""
				end

				P(i(), l())
			end,
		}
	end

	_prl = Instance.new("TextLabel", pbFrame)
	_prl.Size = UDim2.new(0, 135, 1, 0)
	_prl.Position = UDim2.new(0, 222, 0, 0)
	_prl.BackgroundTransparency = 1
	_prl.Text = "FPS:-- PING:--"
	_prl.TextColor3 = Color3.fromRGB(245, 245, 245)
	_prl.Font = Enum.Font.GothamBold
	_prl.TextSize = 12
	_prl.TextStrokeTransparency = 0
	_prl.ZIndex = 3
	_prl.RichText = true
	Yt()
	mini = Instance.new("TextButton", gui)
	mini.Name = "VampireMini"
	mini.Size = UDim2.new(0, 145, 0, 42)
	mini.Position = UDim2.new(0, 26, 0, 26)
	mini.BackgroundColor3 = a1.card
	mini.BorderSizePixel = 0
	mini.Text = ""
	mini.ZIndex = 20
	mini.Visible = true
	Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 15)
	do
		local i = Instance.new("UIStroke", mini)
		i.Color = a1.purple
		i.Thickness = 2
		local i = Instance.new("Frame", mini)
		i.Size = UDim2.new(0, 12, 0, 12)
		i.Position = UDim2.new(0, 12, 0.5, -6.0)
		i.BackgroundColor3 = a1.purple
		i.BorderSizePixel = 0
		i.ZIndex = 21
		Instance.new("UICorner", i).CornerRadius = UDim.new(1, 0)
		local i = Instance.new("TextLabel", mini)
		i.Size = UDim2.new(1, -40.0, 1, 0)
		i.Position = UDim2.new(0, 32, 0, 0)
		i.BackgroundTransparency = 1
		i.Text = "Vampire Hub  •  /printed #1"
		i.TextColor3 = a1.white
		i.Font = Enum.Font.GothamBold
		i.TextSize = 10
		i.TextStrokeTransparency = 0
		i.TextTruncate = Enum.TextTruncate.AtEnd
		i.ZIndex = 21
	end

	l1(mini, function()
		toggleGuiVis()
	end)
	makeDraggable(mini)
	resetProgressBar = function()
		progressPct.Text = ""
		_pbFill(0)
	end

	toggleGuiVis = function()
		zt.guiVisible = not zt.guiVisible
		if zt.guiVisible then
			local i = root:GetAttribute("_hiddenPos")
			if i then
				local P = {}
				for l in i:gmatch("[^,]+") do
					P[#P + 1] = tonumber(l)
				end

				if #P == 4 then
					root.Position = UDim2.new(P[1], P[2], P[3], P[4])
				end
			end

			root.Visible = true
			root.Active = true
			F1.Scale = zt.guiScale * 0.85
			root.BackgroundTransparency = 1
			tw(root, 0.22, { BackgroundTransparency = 0.02 }, Enum.EasingStyle.Quad)
			gt:Create(F1, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = zt.guiScale })
				:Play()
		else
			local i = root.Position
			root:SetAttribute(
				"_hiddenPos",
				string.format("%.4f,%.4f,%.4f,%.4f", i.X.Scale, i.X.Offset, i.Y.Scale, i.Y.Offset)
			)
			root.Active = false
			tw(root, 0.16, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
			local i = gt:Create(
				F1,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Scale = zt.guiScale * 0.85 }
			)
			i:Play()
			i.Completed:Connect(function()
				if not zt.guiVisible then
					root.Position = UDim2.new(0, -99999.0, 0, -99999.0)
					root.Visible = false
					F1.Scale = zt.guiScale
				end
			end)
		end

		Yt()
	end
end

local i, P, l = W.SIDE_BUTTON_BASE_SIZE, W.SIDE_BUTTON_BASE_GAP, 2
local Z = {}
ut = function(E)
	local r = zt.sideButtonLook == "clear"
	local L = Color3.fromRGB(0, 0, 0)
	for y, y in ipairs(Ot) do
		local Qt = Bt[y.key]
		if Qt and Qt.frame then
			local ft = Z[y.key] == true
			local y = r and (ft and a1.purple or L) or (ft and a1.stkAct or a1.card)
			local L = r and (ft and 0.2 or 0.46) or 0
			local r = Qt.frame:FindFirstChildOfClass("UIStroke")
			if r then
				pcall(function()
					r:Destroy()
				end)
			end

			if E then
				Qt.frame.BackgroundColor3 = y
				Qt.frame.BackgroundTransparency = L
			else
				tw(Qt.frame, 0.12, { BackgroundColor3 = y, BackgroundTransparency = L })
			end
		end
	end
end

sideDefaultPos = function(E)
	local r = zt.sideButtonScale or 1
	local L = i * r
	local y = i * r
	local i = P
	local P = 14 * r
	local Qt = 0
	for ft, ft in ipairs(Ot) do
		if not ft.wide then
			Qt = Qt + 1
		end
	end

	local ft = math.ceil(Qt / l)
	local Qt = ft * (y + i) - i
	local ft = l * (L + i) - i
	local It = Ot[E]
	if It and It.wide and It.key == "tpDesync" then
		local kt = 2 * L + i
		local wt = Qt / 2 + 4 * r
		return UDim2.new(1, -(kt + P), 0.43, wt)
	end

	local r = 0
	for kt = 1, E - 1 do
		if not Ot[kt].wide then
			r = r + 1
		end
	end

	if It.wide then
		return UDim2.new(1, -(2 * L + i + P), 0.43, -y / 2)
	end

	local E = r % l
	local It = math.floor(r / l)
	return UDim2.new(1, -(ft + P) + E * (L + i), 0.43, -Qt / 2 + It * (y + i))
end

local i = nil
local function P()
	if i then
		i:Disconnect()
	end

	i = task.delay(0.5, function()
		zt.sideButtonPositions = {}
		for l, E in pairs(Bt) do
			if E and E.frame then
				local r = E.frame.Position
				zt.sideButtonPositions[l] =
					string.format("%.3f,%.3f,%.3f,%.3f", r.X.Scale, r.X.Offset, r.Y.Scale, r.Y.Offset)
			end
		end

		_scfg()
		i = nil
	end)
end

for i, l in ipairs(Ot) do
	local E = Instance.new("TextButton", gui)
	E.Name = "SideBtn_" .. l.key
	local G, r = tt(l)
	E.Size = UDim2.new(0, G, 0, r)
	E.Position = sideDefaultPos(i)
	E.BackgroundColor3 = a1.card
	E.BorderSizePixel = 0
	E.RichText = false
	E.Text = l.label
	E.TextColor3 = a1.white
	E.TextSize = l.wide and 14 or 11
	E.Font = Enum.Font.GothamBold
	E.TextWrapped = true
	E.LineHeight = 1.2
	E.ZIndex = 15
	E.Visible = zt.sideButtonsVisible
	local G = Instance.new("UICorner", E)
	G.CornerRadius = zt.sideButtonType == "circle" and UDim.new(1, 0) or UDim.new(0, 12)
	Z[l.key] = false
	local function G(i)
		Z[l.key] = i
		if ut then
			ut(false)
		end
	end

	Bt[l.key] = { setOn = G, frame = E }
	local i, r, L, y = nil, nil, false, false
	local d = false
	local Qt = false
	local ft = nil
	local It = false
	local kt = nil
	local tt = 0
	local function wt()
		tt = tt + 1
		local ot = tt
		G(true)
		task.delay(0.15, function()
			if ot == tt then
				G(false)
			end
		end)
	end

	Bt[l.key].flash = wt
	local function tt()
		if l.key == "tpDown" then
			if not d then
				wt()
				doTpDown()
			end

			return
		end

		if l.key == "tpDesync" then
			zt.desyncAimbotEnabled = not zt.desyncAimbotEnabled
			if setDesyncAimbot then
				setDesyncAimbot(zt.desyncAimbotEnabled)
			end

			if zt.desyncAimbotEnabled then
				_VH_forceAimbotOff()
				startDesyncAimbot()
			else
				stopDesyncAimbot()
			end

			G(zt.desyncAimbotEnabled)
			return
		end

		if l.key == "drop" then
			G(true)
			runDropBrainrot()
			task.wait(0.15)
			G(false)
			return
		end

		if l.key == "lagger" then
			if zt.laggerMode == 1 then
				_VH_speedToNormal()
			else
				_VH_speedToNormal()
				setLaggerMode(1)
			end

			return
		end

		if l.key == "laggerCarry" then
			if zt.laggerMode == 2 then
				_VH_speedToNormal()
			else
				_VH_speedToNormal()
				setLaggerMode(2)
			end

			return
		end

		local ot = not Z[l.key]
		G(ot)
		if l.key == "autoLeft" then
			if ot then
				_VH_forceAimbotOff()
				_VH_forceDesyncOff()
			end

			zt.autoLeftEnabled = ot
			if setAutoLeft then
				setAutoLeft(ot)
			end

			if ot then
				startAutoLeft()
			else
				stopAutoLeft()
			end
		elseif l.key == "autoRight" then
			if ot then
				_VH_forceAimbotOff()
				_VH_forceDesyncOff()
			end

			zt.autoRightEnabled = ot
			if setAutoRight then
				setAutoRight(ot)
			end

			if ot then
				startAutoRight()
			else
				stopAutoRight()
			end
		elseif l.key == "aimbot" then
			zt.autoBatToggled = ot
			if setAutoBat then
				setAutoBat(ot)
			end

			if ot then
				_VH_forceDesyncOff()
				startBatAimbot()
			else
				stopBatAimbot()
			end
		elseif l.key == "carrySpeed" then
			if zt.laggerMode == 0 and zt.speedToggled then
				_VH_speedToNormal()
				return
			end

			_VH_speedToNormal()
			zt.speedToggled = true
			if carryBox then
				carryBox.Text = tostring(zt.carrySpeed)
			end

			if modeValLbl then
				modeValLbl.Text = "Carry"
			end

			if Bt and Bt.carrySpeed then
				Bt.carrySpeed.setOn(true)
			end
		end
	end

	local G = { btn = E, cd = false, ibFired = false }
	G.fire = function()
		if l.key ~= "tpDown" and G.cd then
			return
		end

		if not (E and E.Parent) then
			return
		end

		if E.AbsoluteSize.X <= 0 or E.AbsoluteSize.Y <= 0 then
			return
		end

		if l.key ~= "tpDown" then
			G.cd = true
			task.delay(0.1, function()
				G.cd = false
				G.ibFired = false
			end)
		end

		if _ppop then pcall(_ppop, E) end
		if l.key == "tpDown" then
			if not d then
				wt()
				doTpDown()
				d = true
			end
		else
			if not Qt then
				Qt = true
				task.delay(0.1, function()
					Qt = false
				end)
				task.spawn(tt)
			end
		end
	end

	table.insert(g1, G)
	E.InputBegan:Connect(function(G)
		if
			G.UserInputType ~= Enum.UserInputType.MouseButton1
			and G.UserInputType ~= Enum.UserInputType.MouseButton2
		then
			return
		end

		local Z = E.AbsolutePosition
		local ot = E.AbsoluteSize
		local M1, g1 = G.Position.X, G.Position.Y
		if not (M1 >= Z.X and M1 <= Z.X + ot.X and g1 >= Z.Y and g1 <= Z.Y + ot.Y) then
			return
		end

		if root and root.Visible then
			local Z = root.AbsolutePosition
			local ot = root.AbsoluteSize
			local M1, g1 = G.Position.X, G.Position.Y
			if M1 >= Z.X and M1 <= Z.X + ot.X and g1 >= Z.Y and g1 <= Z.Y + ot.Y then
				return
			end
		end

		ft = G
		i = G.Position
		r = E.Position
		L = true
		y = false
		d = false
		It = zt.sideButtonDragMode == "all"
		kt = nil
		if It then
			kt = {}
			for G, Z in pairs(Bt) do
				if Z and Z.frame then
					kt[G] = Z.frame.Position
				end
			end
		end
	end)
	Mt.InputChanged:Connect(function(G)
		if not L or not ft then
			return
		end

		local Z = ft.UserInputType == Enum.UserInputType.MouseButton1 and G.UserInputType == Enum.UserInputType.Touch
		local f = ft.UserInputType == Enum.UserInputType.MouseButton2 and G == ft
		if not (Z or f) then
			return
		end

		local f = G.Position - i
		if f.Magnitude > 20 then
			y = true
		end

		if y and not zt.sideButtonsLocked then
			if It and kt then
				for G, i in pairs(kt) do
					local Z = Bt[G]
					if Z and Z.frame then
						Z.frame.Position = UDim2.new(i.X.Scale, i.X.Offset + f.X, i.Y.Scale, i.Y.Offset + f.Y)
					end
				end
			else
				E.Position = UDim2.new(r.X.Scale, r.X.Offset + f.X, r.Y.Scale, r.Y.Offset + f.Y)
			end
		end
	end)
	local function f(G)
		if not L or not ft then
			return
		end

		local i = ft.UserInputType == Enum.UserInputType.MouseButton1
			and G.UserInputType == Enum.UserInputType.MouseButton1
		local s = ft.UserInputType == Enum.UserInputType.MouseButton2 and G == ft
		if not (i or s) then
			return
		end

		L = false
		ft = nil
		It = false
		kt = nil
		if y then
			P()
			return
		end

		local s = E.AbsolutePosition
		local n = E.AbsoluteSize
		local i, I = G.Position.X, G.Position.Y
		if not (i >= s.X and i <= s.X + n.X and I >= s.Y and I <= s.Y + n.Y) then
			return
		end

		if l.key == "tpDown" then
			if not d then
				wt()
				doTpDown()
				d = true
			end

			return
		end

		if Qt then
			return
		end

		Qt = true
		task.delay(0.1, function()
			Qt = false
		end)
		tt()
	end

	E.InputEnded:Connect(f)
	Mt.InputEnded:Connect(f)
end

setSideVisible = function(s)
	zt.sideButtonsVisible = s
	for n, f in pairs(Bt) do
		if f and f.frame then
			local G = false
			for i, i in ipairs(zt.hiddenSideButtons or {}) do
				if i == n then
					G = true
					break
				end
			end

			f.frame.Visible = s and not G
		end
	end
end

setSideVisible(zt.sideButtonsVisible)
if ut then
	ut(true)
end

if _G._applySideButtonScale then
	_G._applySideButtonScale()
end

local s = { Enabled = false, Connection = nil, ResetCooldown = 0 }
startAntiRagdoll = function()
	if s.Connection then
		return
	end

	s.Enabled = true
	s.Connection = game:GetService("RunService").Heartbeat:Connect(function()
		if not s.Enabled then
			return
		end

		local n = Rt.Character
		if not n then
			return
		end

		local f = n:FindFirstChildOfClass("Humanoid")
		local G = n:FindFirstChild("HumanoidRootPart")
		if not f or not G or f.Health <= 0 then
			return
		end

		local i = f:GetState()
		local I = tick()
		if
			i == Enum.HumanoidStateType.Physics
			or i == Enum.HumanoidStateType.Ragdoll
			or i == Enum.HumanoidStateType.FallingDown
		then
			if I - s.ResetCooldown > 0.15 then
				s.ResetCooldown = I
				pcall(function()
					f:ChangeState(Enum.HumanoidStateType.GettingUp)
					f1(G, "VampireBrake", Vector3.zero, 0.12)
					G.AssemblyAngularVelocity = Vector3.zero
					for G, G in ipairs(n:GetDescendants()) do
						if G:IsA("Motor6D") then
							G.Enabled = true
						end

						if G:IsA("Constraint") then
							G.Enabled = true
						end
					end

					workspace.CurrentCamera.CameraSubject = f
					local n = Rt.PlayerScripts:FindFirstChild("PlayerModule")
					if n then
						local G = require(n:FindFirstChild("ControlModule"))
						if G then
							G:Enable()
						end
					end

					f.AutoRotate = true
					f.PlatformStand = false
					f.Sit = false
				end)
			end
		end
	end)
end

stopAntiRagdoll = function()
	s.Enabled = false
	if s.Connection then
		s.Connection:Disconnect()
		s.Connection = nil
	end
end

W._batHitNames = {
	bat = true,
	slap = true,
	["iron slap"] = true,
	["gold slap"] = true,
	["diamond slap"] = true,
	["emerald slap"] = true,
	["ruby slap"] = true,
	["dark matter slap"] = true,
	["flame slap"] = true,
	["nuclear slap"] = true,
	["galaxy slap"] = true,
	["glitched slap"] = true,
}
W._batHitSequence = 0
W._batHitTime = 0
W._batHitLastTouch = 0
W._batHitLastImpact = 0
W._batHitLastVelocity = nil
W._batHitConns = {}
W._batHitBoundParts = {}
local function s(n)
	if not (n and n:IsA("Tool")) then
		return false
	end

	local f = n.Name:lower()
	return W._batHitNames[f] == true or f:find("bat", 1, true) ~= nil or f:find("slap", 1, true) ~= nil
end

local function n(f)
	if not f then
		return false
	end

	for G, G in ipairs(bt:GetPlayers()) do
		if G ~= Rt and G.Character then
			local i = G.Character:FindFirstChild("HumanoidRootPart")
			if i and (i.Position - f.Position).Magnitude <= 24 then
				for f, f in ipairs(G.Character:GetChildren()) do
					if s(f) then
						return true
					end
				end
			end
		end
	end

	return false
end

local function f()
	local G = tick()
	if G - W._batHitTime < 0.55 then
		return
	end

	W._batHitTime = G
	W._batHitSequence = W._batHitSequence + 1
	if not zt.stopOnHitEnabled then
		return
	end

	zt.stealPausedUntil = tick() + 1.27
	zt.isStealing = false
	zt.stealStartTime = nil
	pcall(function()
		if x1.progress then
			x1.progress:Disconnect()
			x1.progress = nil
		end
	end)
	if progressFill then
		_pbFill(0)
	end

	if progressPct then
		progressPct.Text = ""
	end

	if _G._VH_abortSteal then
		pcall(_G._VH_abortSteal)
	end
end

local function G()
	for i, i in ipairs(W._batHitConns) do
		pcall(function()
			i:Disconnect()
		end)
	end

	W._batHitConns = {}
	W._batHitBoundParts = {}
end

local function i(I, P)
	if not I:IsA("BasePart") or W._batHitBoundParts[I] then
		return
	end

	W._batHitBoundParts[I] = true
	table.insert(
		W._batHitConns,
		I.Touched:Connect(function(I)
			local l = I and I:FindFirstAncestorOfClass("Tool")
			if l and not l:IsDescendantOf(P) and s(l) then
				W._batHitLastTouch = tick()
			end
		end)
	)
end

local function s(I)
	G()
	W._batHitLastTouch = 0
	W._batHitLastImpact = 0
	W._batHitLastVelocity = nil
	for G, G in ipairs(I:GetDescendants()) do
		i(G, I)
	end

	table.insert(
		W._batHitConns,
		I.DescendantAdded:Connect(function(G)
			i(G, I)
		end)
	)
	local G = I:FindFirstChildOfClass("Humanoid") or I:WaitForChild("Humanoid", 5)
	if G then
		table.insert(
			W._batHitConns,
			G.StateChanged:Connect(function(i, i)
				if
					i ~= Enum.HumanoidStateType.Physics
					and i ~= Enum.HumanoidStateType.Ragdoll
					and i ~= Enum.HumanoidStateType.FallingDown
				then
					return
				end

				task.spawn(function()
					task.wait(0.05)
					if not G.Parent then
						return
					end

					local G = I:FindFirstChild("HumanoidRootPart")
					local i = tick()
					local I = i - W._batHitLastTouch <= 0.75
					local P = i - W._batHitLastImpact <= 0.4 or G and s1(G).Magnitude >= 20
					if I or P and n(G) then
						f()
					end
				end)
			end)
		)
	end
end

if Rt.Character then
	s(Rt.Character)
end

Rt.CharacterAdded:Connect(function(n)
	s(n)
end)
local s = 0
pt.Heartbeat:Connect(function(n)
	s = s + (n or 0)
	if s < (Q1 and 0.03333333333333333 or 0.016666666666666666) then
		return
	end

	s = 0
	local s = Rt.Character
	local n = s and s:FindFirstChild("HumanoidRootPart")
	if not n then
		W._batHitLastVelocity = nil
		return
	end

	local s = s1(n)
	if W._batHitLastVelocity and (s - W._batHitLastVelocity).Magnitude >= 18 then
		W._batHitLastImpact = tick()
	end

	W._batHitLastVelocity = s
end)
do
	local s = false
	local function n()
		local f = Rt.Character
		if not f then
			return nil, nil
		end

		local G = f:FindFirstChild("Head")
		if not G then
			return nil, nil
		end

		local f = Rt.PlayerGui
		local i = f:FindFirstChild("RagCountdownBillboard")
		if i then
			i:Destroy()
		end

		local i = Instance.new("BillboardGui")
		i.Name = "RagCountdownBillboard"
		i.Size = UDim2.new(0, 84, 0, 42)
		i.StudsOffset = Vector3.new(0, 0.5, 0)
		i.AlwaysOnTop = true
		i.Adornee = G
		i.Parent = f
		local f = Instance.new("TextLabel")
		f.Size = UDim2.new(1, 0, 1, 0)
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.new(0.5, 0, 0.5, 0)
		f.BackgroundTransparency = 1
		f.Font = Enum.Font.Gotham
		f.TextScaled = true
		f.TextColor3 = a1.purple
		f.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		f.TextTransparency = 0
		f.Text = ""
		f.Parent = i
		return i, f
	end

	local function f(G, i)
		if not (G and G.Parent) then
			return
		end

		G.Text = i
	end

	local function G()
		if s then
			return
		end

		s = true
		task.spawn(function()
			local i, I = n()
			if not i then
				s = false
				return
			end

			local n = 2.5
			while n > 0 and i.Parent do
				f(I, string.format("%.1f", n))
				task.wait(0.1)
				n = n - 0.1
			end

			if i and i.Parent then
				f(I, "READY!")
				task.wait(0.5)
				if i and i.Parent then
					i:Destroy()
				end
			end

			s = false
		end)
	end

	local s = W._batHitSequence
	game:GetService("RunService").Heartbeat:Connect(function()
		if W._batHitSequence == s then
			return
		end

		s = W._batHitSequence
		G()
	end)
end

local s = {}
local n = false
local f = false
local G = nil
W._lastJumpTime = 0
W._jumpWasGrounded = true
W._JUMP_COOLDOWN = 0.08
W._INF_JUMP_PULSE = 0.06
local function i()
	return math.clamp((zt.jumpPower or 45) * 0.76, 34, 54)
end

local function I(k, P, l)
	if not (k and P) or not V1(k) then
		return false
	end

	local Z = tick()
	if P.FloorMaterial ~= Enum.Material.Air then
		W._jumpWasGrounded = true
		W._lastJumpTime = 0
		return false
	end

	if W._jumpWasGrounded then
		W._jumpWasGrounded = false
		return false
	end

	if Z - W._lastJumpTime < W._JUMP_COOLDOWN then
		return false
	end

	if not l and s1(k).Y > i() * 0.85 then
		return false
	end

	W._lastJumpTime = Z
	local P = k.AssemblyLinearVelocity
	k.AssemblyLinearVelocity = Vector3.new(P.X, i(), P.Z)
	return true
end

startHoldInfJump = function()
	if s.loop then
		return
	end

	s.jumpReq = Mt.JumpRequest:Connect(function()
		if not zt.holdInfJumpEnabled then
			return
		end

		local i = Rt.Character
		if not i then
			return
		end

		local k = i:FindFirstChild("HumanoidRootPart")
		local P = i:FindFirstChildOfClass("Humanoid")
		if k and P then
			I(k, P, true)
		end
	end)
	s.loop = game:GetService("RunService").Heartbeat:Connect(function()
		if not zt.holdInfJumpEnabled then
			return
		end

		local i = Rt.Character
		if not i then
			return
		end

		local k = i:FindFirstChild("HumanoidRootPart")
		if not k then
			return
		end

		local P = i:FindFirstChildOfClass("Humanoid")
		if not P then
			return
		end

		if P.FloorMaterial ~= Enum.Material.Air then
			W._jumpWasGrounded = true
			W._lastJumpTime = 0
			if k:FindFirstChild("VampireInfJumpLinearVelocity") then
				i1(k, "VampireInfJump")
			end

			return
		end

		if W._jumpWasGrounded then
			W._jumpWasGrounded = false
		end

		local i = Mt:IsKeyDown(Enum.KeyCode.Space) or P and P.Jump == true
		local l = s1(k).Y
		if l < -120.0 then
			p1(k, "VampireInfJump", -120.0, 0.08)
		elseif i then
			I(k, P, false)
		end
	end)
end

applyJumpPower = function()
	local i = Rt.Character
	local k = i and i:FindFirstChildOfClass("Humanoid")
	if not k then
		return
	end

	local i = math.clamp(tonumber(zt.jumpPower) or 45, 45, 50)
	pcall(function()
		if k.UseJumpPower == false then
			k.UseJumpPower = true
		end

		if k.JumpPower ~= i then
			k.JumpPower = i
		end

		local P = workspace.Gravity
		if P and P > 0 then
			local l = i * i / (2 * P)
			if math.abs((k.JumpHeight or 0) - l) > 0.05 then
				k.JumpHeight = l
			end
		end
	end)
end

do
	local i = 0
	pt.Heartbeat:Connect(function(k)
		i = i + (k or 0)
		if i < 0.2 then
			return
		end

		i = 0
		applyJumpPower()
	end)
end

stopHoldInfJump = function()
	if s.jumpReq then
		s.jumpReq:Disconnect()
	end

	if s.inputBegan then
		s.inputBegan:Disconnect()
	end

	if s.inputEnded then
		s.inputEnded:Disconnect()
	end

	if s.touchStarted then
		s.touchStarted:Disconnect()
	end

	if s.touchEnded then
		s.touchEnded:Disconnect()
	end

	if s.loop then
		s.loop:Disconnect()
	end

	local i = Rt.Character
	local k = i and i:FindFirstChild("HumanoidRootPart")
	if k then
		i1(k, "VampireInfJump")
	end

	s = {}
	n = false
	f = false
	G = nil
	W._lastJumpTime = 0
	W._jumpWasGrounded = true
end

do
	local s, n = nil, nil
	local function f(G)
		local i = workspace.CurrentCamera
		if i then
			pcall(function()
				i.FieldOfView = G
			end)
		end
	end

	enableStretchRez = function()
		zt.stretchRezEnabled = true
		zt.stretchedResEnabled = true
		local G = workspace.CurrentCamera
		if not G then
			return
		end

		if s then
			s:Disconnect()
		end

		if n then
			n:Disconnect()
		end

		n = pt.RenderStepped:Connect(function()
			if zt.stretchRezEnabled then
				f(zt.stretchFOV)
			end
		end)
		s = pt.RenderStepped:Connect(function()
			if not zt.stretchRezEnabled then
				if s then
					s:Disconnect()
					s = nil
				end

				return
			end

			local G = workspace.CurrentCamera
			if G then
				G.CFrame = G.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, 0.7, 0, 0, 0, 1)
			end
		end)
	end

	disableStretchRez = function()
		zt.stretchRezEnabled = false
		zt.stretchedResEnabled = false
		if s then
			s:Disconnect()
			s = nil
		end

		if n then
			n:Disconnect()
			n = nil
		end

		pcall(function()
			workspace.CurrentCamera.FieldOfView = zt.lockedFOV or NORMAL_STRETCH_FOV
		end)
	end

	setStretchFOV = function(s)
		local n
		if s == "Normal" or s == nil then
			n = NORMAL_STRETCH_FOV
		else
			n = tonumber(s)
		end

		if not n then
			return
		end

		zt.stretchFOV = n
		if zt.stretchedResEnabled then
			f(n)
		end

		if setStretchFOVVisual then
			setStretchFOVVisual(s)
		end
	end
end

do
	local s = {
		Ambient = Ft.Ambient,
		Brightness = Ft.Brightness,
		ClockTime = Ft.ClockTime,
		FogColor = Ft.FogColor,
		FogEnd = Ft.FogEnd,
		GlobalShadows = Ft.GlobalShadows,
		EnvironmentDiffuseScale = Ft.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = Ft.EnvironmentSpecularScale,
	}
	local n = nil
	local function f()
		if n then
			pcall(function()
				n:Destroy()
			end)
			n = nil
		end
	end

	local function G()
		f()
		pcall(function()
			Ft.Ambient = s.Ambient
			Ft.Brightness = s.Brightness
			Ft.ClockTime = s.ClockTime
			Ft.FogColor = s.FogColor
			Ft.FogEnd = s.FogEnd
			Ft.GlobalShadows = s.GlobalShadows
			Ft.EnvironmentDiffuseScale = s.EnvironmentDiffuseScale
			Ft.EnvironmentSpecularScale = s.EnvironmentSpecularScale
		end)
	end

	applySky = function(s)
		if s == nil or s == "default" then
			G()
			zt.activeSky = "default"
			if _ssv then
				_ssv("default")
			end

			return
		end

		f()
		local f = Instance.new("ColorCorrectionEffect")
		f.Parent = Ft
		n = f
		if s == "blue" then
			Ft.Ambient = Color3.fromRGB(30, 60, 120)
			Ft.FogColor = Color3.fromRGB(40, 80, 160)
			f.TintColor = Color3.fromRGB(140, 180, 255)
			f.Saturation = 0.4
			f.Contrast = 0.1
		elseif s == "night" then
			Ft.ClockTime = 0
			Ft.Brightness = 0.2
			Ft.Ambient = Color3.fromRGB(20, 20, 35)
			f.TintColor = Color3.fromRGB(180, 180, 220)
			f.Saturation = -0.2
			f.Contrast = 0.1
		elseif s == "day" then
			Ft.ClockTime = 14
			Ft.Brightness = 2
			Ft.Ambient = Color3.fromRGB(140, 140, 140)
			f.TintColor = Color3.fromRGB(255, 255, 255)
			f.Saturation = 0.1
			f.Contrast = 0
		end

		zt.activeSky = s
		if _ssv then
			_ssv(s)
		end
	end
end

do
	local s = false
	local n = nil
	local f = { defB = nil, defC = nil, defA = nil }
	local function G(i)
		pcall(function()
			if i:IsA("Accessory") or i:IsA("Hat") then
				i:Destroy()
			elseif i:IsA("BasePart") then
				i.Material = Enum.Material.Plastic
				i.Reflectance = 0
				i.CastShadow = false
			elseif i:IsA("Decal") or i:IsA("Texture") then
				i.Transparency = 1
			elseif
				i:IsA("ParticleEmitter")
				or i:IsA("Trail")
				or i:IsA("Beam")
				or i:IsA("Fire")
				or i:IsA("Smoke")
				or i:IsA("Sparkles")
			then
				i.Enabled = false
			elseif i:IsA("AnimationController") or i:IsA("Animator") then
				for k, k in ipairs(i:GetPlayingAnimationTracks()) do
					pcall(function()
						k:Stop(0)
					end)
				end
			end
		end)
	end

	enableAntiLag = function()
		s = true
		_G._VH_antiLag = true
		f.defB = f.defB or 2
		f.defC = f.defC or 14
		f.defA = f.defA or Color3.fromRGB(70, 70, 70)
		Ft.GlobalShadows = false
		Ft.FogEnd = 10000000000
		Ft.Brightness = 1
		Ft.EnvironmentDiffuseScale = 0
		Ft.EnvironmentSpecularScale = 0
		for i, i in pairs(Ft:GetChildren()) do
			pcall(function()
				if
					i:IsA("BlurEffect")
					or i:IsA("SunRaysEffect")
					or i:IsA("ColorCorrectionEffect")
					or i:IsA("BloomEffect")
					or i:IsA("DepthOfFieldEffect")
				then
					i.Enabled = false
				end
			end)
		end

		local i = workspace:GetDescendants()
		for k, P in ipairs(i) do
			G(P)
			if k % 180 == 0 then
				task.wait()
			end
		end

		i = nil
		if n then
			n:Disconnect()
		end

		n = workspace.DescendantAdded:Connect(function(i)
			if s then
				G(i)
			end
		end)
	end

	disableAntiLag = function()
		s = false
		_G._VH_antiLag = false
		if n then
			n:Disconnect()
			n = nil
		end

		pcall(function()
			if f.defB then
				Ft.Brightness = f.defB
			end

			if f.defC then
				Ft.ClockTime = f.defC
			end

			if f.defA then
				Ft.OutdoorAmbient = f.defA
			end

			Ft.ExposureCompensation = 0
		end)
	end
end

do
	local s = {}
	local n = nil
	local function f()
		for G, G in ipairs(bt:GetPlayers()) do
			if G ~= Rt and G.Character then
				for i, i in ipairs(G.Character:GetChildren()) do
					if i:IsA("BasePart") then
						i.CanCollide = false
					end
				end
			end
		end
	end

	local function G()
		if zt.dropEnabled then
			return
		end

		zt.dropEnabled = true
		local i = nil
		do
			local k = Rt.Character
			local P = k and k:FindFirstChild("HumanoidRootPart")
			if P and P.Position.Y > -50.0 then
				i = P.CFrame
			end
		end

		local k = pt.Stepped:Connect(function()
			if not zt.dropEnabled then
				return
			end

			f()
		end)
		table.insert(s, k)
		local f = coroutine.create(function()
			while zt.dropEnabled do
				pt.Heartbeat:Wait()
				local k = Rt.Character
				local P = k and k:FindFirstChild("HumanoidRootPart")
				if not P then
					break
				end

				local k = s1(P)
				G1(P, "VampireStandDrop", k * 10000 + Vector3.new(0, 10000, 0))
				pt.RenderStepped:Wait()
				if P and P.Parent then
					G1(P, "VampireStandDrop", k)
				end

				pt.Stepped:Wait()
				if P and P.Parent then
					G1(P, "VampireStandDrop", k + Vector3.new(0, 0.1, 0))
				end
			end
		end)
		table.insert(s, f)
		coroutine.resume(f)
		task.delay(0.1, function()
			zt.dropEnabled = false
			for f, f in ipairs(s) do
				if typeof(f) == "RBXScriptConnection" then
					f:Disconnect()
				elseif type(f) == "thread" then
					pcall(coroutine.close, f)
				end
			end

			s = {}
			task.spawn(function()
				local f = Rt.Character
				local k = f and f:FindFirstChild("HumanoidRootPart")
				if k then
					i1(k, "VampireStandDrop")
				end

				if k and i and k.Position.Y < -80.0 then
					k.CFrame = i + Vector3.new(0, 5, 0)
					f1(k, "VampireBrake", Vector3.zero, 0.12)
				end
			end)
		end)
	end

	local f = { active = false }
	local function i()
		if n then
			n:Disconnect()
			n = nil
		end

		f.active = false
		zt.dropEnabled = false
		if Bt.drop then
			Bt.drop.setOn(false)
		end
	end

	local function k()
		if f.active then
			return
		end

		f.active = true
		zt.dropEnabled = true
		if Bt.drop then
			Bt.drop.setOn(true)
		end

		_G._RaVeDropToken = (_G._RaVeDropToken or 0) + 1
		local P = _G._RaVeDropToken
		local l = Rt.Character
		local Z = l and l:FindFirstChild("HumanoidRootPart")
		if not l or not Z then
			i()
			return
		end

		local E = _G._RaVeDropRayParams
		if not E then
			E = RaycastParams.new()
			E.FilterType = Enum.RaycastFilterType.Exclude
			E.RespectCanCollide = true
			_G._RaVeDropRayParams = E
		end

		E.FilterDescendantsInstances = { l }
		local r = workspace:Raycast(Z.Position + Vector3.new(0, 0.35, 0), Vector3.new(0, -2000.0, 0), E)
		if not r then
			i()
			return
		end

		local L = Z.CFrame.Rotation
		local y, d = Z.Position.X, Z.Position.Z
		local Z = tick()
		n = pt.Heartbeat:Connect(function()
			local Qt = l and l:FindFirstChild("HumanoidRootPart")
			local ft = l and l:FindFirstChildOfClass("Humanoid")
			if P ~= _G._RaVeDropToken or not Qt or not ft or ft.Health <= 0 then
				i()
				return
			end

			if tick() - Z >= 0.18 then
				if n then
					n:Disconnect()
					n = nil
				end

				E.FilterDescendantsInstances = { l }
				local n = workspace:Raycast(Qt.Position + Vector3.new(0, 0.35, 0), Vector3.new(0, -2000.0, 0), E)
				local P = n or r
				if P then
					local n = ft.HipHeight + Qt.Size.Y * 0.5 + 0.2
					Qt.CFrame = CFrame.new(y, P.Position.Y + n, d) * L
					Qt.AssemblyLinearVelocity = Vector3.zero
					Qt.AssemblyAngularVelocity = Vector3.zero
				end

				f.active = false
				zt.dropEnabled = false
				if Bt.drop then
					Bt.drop.setOn(false)
				end

				return
			end

			Qt.AssemblyLinearVelocity = Vector3.new(0, 155, 0)
		end)
	end

	runDropBrainrot = function()
		if _G._VH_suppressKickWarning then
			pcall(_G._VH_suppressKickWarning, 2.3)
		end

		local n = zt.autoTpDownEnabled == true
		if n then
			zt.autoTpDownEnabled = false
		end

		task.delay(0.35, function()
			if n then
				zt.autoTpDownEnabled = true
			end
		end)
		if zt.dropType == "Jump Drop" then
			k()
		else
			G()
		end
	end

	stopDropBrainrot = function()
		_G._RaVeDropToken = (_G._RaVeDropToken or 0) + 1
		i()
		for n, n in ipairs(s) do
			if typeof(n) == "RBXScriptConnection" then
				n:Disconnect()
			elseif type(n) == "thread" then
				pcall(coroutine.close, n)
			end
		end

		s = {}
		local s = Rt.Character
		local n = s and s:FindFirstChild("HumanoidRootPart")
		if n then
			i1(n, "VampireStandDrop")
		end
	end

	Rt.CharacterRemoving:Connect(stopDropBrainrot)
	local s = game:GetService("Players")
	local n = s.LocalPlayer
	doTpDown = function()
		pcall(function()
			local s = Rt.Character
			if not s then
				return
			end

			local n = s:FindFirstChild("HumanoidRootPart")
			if not n then
				return
			end

			n.CFrame = CFrame.new(n.Position.X, -7.0, n.Position.Z)
				* CFrame.Angles(0, select(2, n.CFrame:ToEulerAnglesYXZ()), 0)
			n.Velocity = Vector3.zero
		end)
	end

	local s = {}
	local n = 0
	local f = 0
	local G = setmetatable({}, { __mode = "k" })
	local i = RaycastParams.new()
	i.FilterType = Enum.RaycastFilterType.Exclude
	i.IgnoreWater = true
	local function k()
		return zt.autoBatToggled == true or zt.desyncAimbotEnabled == true
	end

	local function P(l)
		if not l then
			return
		end

		for Z, Z in ipairs(l:GetDescendants()) do
			if Z:IsA("BasePart") then
				if G[Z] == nil then
					G[Z] = Z.CanCollide
				end

				Z.CanCollide = false
			end
		end
	end

	local function l()
		for Z, E in pairs(G) do
			if Z and Z.Parent then
				pcall(function()
					Z.CanCollide = E
				end)
			end

			G[Z] = nil
		end
	end

	local function G(Z)
		local E = Rt.Character
		local r = E and E:FindFirstChild("HumanoidRootPart")
		local L = E and E:FindFirstChildOfClass("Humanoid")
		if not r or not L or L.Health <= 0 then
			return
		end

		local L = tick()
		if L - n < 0.08 then
			return
		end

		n = L
		local n = -8.8
		if type(Z) == "number" and Z == Z then
			n = math.max(n, Z - 0.25)
		end

		i.FilterDescendantsInstances = { E }
		local Z = nil
		pcall(function()
			local y = Vector3.new(r.Position.X, math.min(r.Position.Y, n) + 8, r.Position.Z)
			Z = workspace:Raycast(y, Vector3.new(0, -64.0, 0), i)
		end)
		if Z then
			n = math.max(n, Z.Position.Y - r.Size.Y * 0.5 - 1.25)
		end

		n = math.clamp(n, -22.0, -8.8)
		f = L + 0.35
		zt._tpInProgress = true
		P(E)
		pcall(function()
			local i, i = r.CFrame:ToEulerAnglesYXZ()
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
			r.CFrame = CFrame.new(r.Position.X, n, r.Position.Z) * CFrame.Angles(0, i, 0)
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
		end)
		task.delay(0.35, function()
			zt._tpInProgress = false
		end)
	end

	pt.Stepped:Connect(function()
		local n = Rt.Character
		local i = n and n:FindFirstChild("HumanoidRootPart")
		local Z = zt.mirrorTPDownEnabled and k() and i and (i.Position.Y < -5.5 or tick() < f)
		if Z then
			P(n)
		else
			l()
		end
	end)
	local n = 0
	pt.Heartbeat:Connect(function(f)
		if not zt.mirrorTPDownEnabled or not k() then
			table.clear(s)
			return
		end

		n = n + (f or 0)
		if n < (Q1 and 0.06 or 0.03) then
			return
		end

		n = 0
		for n, n in ipairs(bt:GetPlayers()) do
			if n ~= Rt and n.Character then
				local f = n.Character:FindFirstChild("HumanoidRootPart")
				if f then
					local i = f.Position.Y
					local f = s[n.UserId]
					if f and f - i >= 3 then
						pcall(G, i)
						table.clear(s)
						return
					end

					s[n.UserId] = i
				end
			end
		end
	end)
	startAutoTpDown = function()
		if x1.autoTpDown then
			x1.autoTpDown:Disconnect()
			x1.autoTpDown = nil
		end

		x1.autoTpDown = pt.Heartbeat:Connect(function()
			if not zt.autoTpDownEnabled then
				return
			end

			local s = Rt.Character
			local n = s and s:FindFirstChild("HumanoidRootPart")
			if not n then
				return
			end

			if n.Position.Y >= math.abs(zt.tpDownHeight) then
				n.CFrame = CFrame.new(n.Position.X, -8.8, n.Position.Z)
				local _wlv = n:FindFirstChild("VampireWalkLinearVelocity")
				if _wlv then _wlv:Destroy() end
				f1(n, "VampireBrake", Vector3.zero, 0.12)
				n.AssemblyAngularVelocity = Vector3.zero
			end
		end)
	end

	stopAutoTpDown = function()
		zt.autoTpDownEnabled = false
		if x1.autoTpDown then
			x1.autoTpDown:Disconnect()
			x1.autoTpDown = nil
		end
	end
end

do
	local s = {
		"Bat",
		"Slap",
		"Iron Slap",
		"Gold Slap",
		"Diamond Slap",
		"Emerald Slap",
		"Ruby Slap",
		"Dark Matter Slap",
		"Flame Slap",
		"Nuclear Slap",
		"Galaxy Slap",
		"Glitched Slap",
	}
	local function n()
		local f = Rt.Character
		if not f then
			return nil
		end

		local G = Rt:FindFirstChildOfClass("Backpack")
		for i, i in ipairs(s) do
			local s = f:FindFirstChild(i) or G and G:FindFirstChild(i)
			if s then
				return s
			end
		end

		for s, s in ipairs(f:GetChildren()) do
			if s:IsA("Tool") and s.Name:lower():find("bat") then
				return s
			end
		end

		if G then
			for s, s in ipairs(G:GetChildren()) do
				if s:IsA("Tool") and s.Name:lower():find("bat") then
					return s
				end
			end
		end

		return nil
	end

	local function s(f)
		local G, i = nil, math.huge
		for k, k in ipairs(bt:GetPlayers()) do
			if k ~= Rt and k.Character then
				local P = k.Character:FindFirstChild("HumanoidRootPart")
				local l = k.Character:FindFirstChildOfClass("Humanoid")
				if P and l and l.Health > 0 then
					local l = (P.Position - f).Magnitude
					if l < i then
						G = k
						i = l
					end
				end
			end
		end

		return G
	end

	local f = { enabled = false, cooldown = 0.1, turnHoldTime = 0.2 }
	local G = nil
	local i = nil
	local k = false
	local P = 0
	local l = 0
	local function Z(E)
		local r = n()
		if not r or r.Parent ~= E then
			return
		end

		pcall(function()
			r:Activate()
			local E = r:FindFirstChildWhichIsA("RemoteEvent")
			if E then
				E:FireServer()
			end
		end)
	end

	local function E()
		if not f.enabled or k or os.clock() - P < f.cooldown then
			return
		end

		k = true
		batCounterDebounce = true
		P = os.clock()
		local P = l
		task.spawn(function()
			local r = Rt.Character
			local L = r and r:FindFirstChild("HumanoidRootPart")
			local y = r and r:FindFirstChildOfClass("Humanoid")
			if not r or not L or not y then
				k = false
				batCounterDebounce = false
				return
			end

			local d = s(L.Position)
			if not d then
				k = false
				batCounterDebounce = false
				return
			end

			local s = n()
			if s and s.Parent ~= r then
				pcall(function()
					y:EquipTool(s)
				end)
				task.wait(0.02)
			end

			if P ~= l or not f.enabled then
				k = false
				batCounterDebounce = false
				return
			end

			r = Rt.Character
			L = r and r:FindFirstChild("HumanoidRootPart")
			y = r and r:FindFirstChildOfClass("Humanoid")
			local s = d.Character
			local n = s and s:FindFirstChild("HumanoidRootPart")
			if not r or not L or not y or not n then
				k = false
				batCounterDebounce = false
				return
			end

			y.AutoRotate = false
			local s = n.Position
			local n = Vector3.new(s.X, L.Position.Y, s.Z)
			if (n - L.Position).Magnitude > 0.001 then
				pcall(function()
					L.RotVelocity = Vector3.zero
					L.AssemblyAngularVelocity = Vector3.zero
					L.CFrame = CFrame.lookAt(L.Position, n)
				end)
			end

			task.wait(0.03)
			if P == l and f.enabled then
				Z(r)
			end

			task.wait(f.turnHoldTime)
			if L and L.Parent then
				L.RotVelocity = Vector3.zero
				L.AssemblyAngularVelocity = Vector3.zero
			end

			if y and y.Parent then
				y.AutoRotate = true
			end

			k = false
			batCounterDebounce = false
		end)
	end

	local function s(n)
		if G then
			G:Disconnect()
			G = nil
		end

		local P = n:FindFirstChildOfClass("Humanoid") or n:WaitForChild("Humanoid", 5)
		if not P then
			return
		end

		local Z = false
		local r = 0
		G = pt.Heartbeat:Connect(function(L)
			if not f.enabled or P.Parent ~= n then
				Z = false
				return
			end

			r = r + (L or 0)
			if r < (Q1 and 0.04 or 0.02) then
				return
			end

			r = 0
			local n = P:GetState() == Enum.HumanoidStateType.Physics
			if n and not Z and not k then
				E()
			end

			Z = n
		end)
	end

	function f.start()
		if f.enabled then
			return
		end

		f.enabled = true
		l = l + 1
		k = false
		batCounterDebounce = false
		if Rt.Character then
			s(Rt.Character)
		end

		if not i then
			i = Rt.CharacterAdded:Connect(function(n)
				if f.enabled then
					task.wait(0.3)
					s(n)
				end
			end)
		end
	end

	function f.stop()
		f.enabled = false
		l = l + 1
		k = false
		batCounterDebounce = false
		if G then
			G:Disconnect()
			G = nil
		end

		if i then
			i:Disconnect()
			i = nil
		end

		local s = Rt.Character
		local n = s and s:FindFirstChildOfClass("Humanoid")
		local G = s and s:FindFirstChild("HumanoidRootPart")
		if G then
			G.RotVelocity = Vector3.zero
			G.AssemblyAngularVelocity = Vector3.zero
		end

		if n then
			n.AutoRotate = true
		end
	end

	function f.toggle()
		if f.enabled then
			f.stop()
		else
			f.start()
		end

		return f.enabled
	end

	startBatCounter = function()
		f.start()
	end

	stopBatCounter = function()
		f.stop()
	end

	local s = getgenv and getgenv() or _G
	s.VX7BatCounter = f
end

do
	local s = {
		"Bat",
		"Slap",
		"Iron Slap",
		"Gold Slap",
		"Diamond Slap",
		"Emerald Slap",
		"Ruby Slap",
		"Dark Matter Slap",
		"Flame Slap",
		"Nuclear Slap",
		"Galaxy Slap",
		"Glitched Slap",
	}
	local n = false
	local function f()
		local G = Rt.Character
		if not G then
			return nil
		end

		for i, i in ipairs(s) do
			local k = G:FindFirstChild(i)
			if k and k:IsA("Tool") then
				return k
			end
		end

		local i = Rt:FindFirstChild("Backpack")
		if i then
			for k, k in ipairs(s) do
				local s = i:FindFirstChild(k)
				if s and s:IsA("Tool") then
					local i = G:FindFirstChildOfClass("Humanoid")
					if i then
						pcall(function()
							i:EquipTool(s)
						end)
					end

					return s
				end
			end
		end

		for s, s in ipairs(G:GetChildren()) do
			if s:IsA("Tool") and (s.Name:lower():find("bat") or s.Name:lower():find("slap")) then
				return s
			end
		end

		return nil
	end

	local s = 0
	pt.Heartbeat:Connect(function()
		if not zt.autoSwingEnabled then
			return
		end

		if not zt.autoBatToggled then
			return
		end

		local G = tick()
		if G - s < 0.08 then
			return
		end

		local i = Rt.Character
		local k = i and i:FindFirstChildOfClass("Humanoid")
		if not i or not k or k.Health <= 0 then
			return
		end

		local P = f()
		if not P then
			return
		end

		if P.Parent ~= i then
			pcall(function()
				k:EquipTool(P)
			end)
		end

		s = G
		pcall(function()
			P:Activate()
		end)
	end)
	local function s()
		if n then
			return
		end

		n = true
		pcall(function()
			local G = Rt.Character
			if G then
				local i = f()
				if i then
					if i.Parent ~= G then
						local k = G:FindFirstChildOfClass("Humanoid")
						if k then
							pcall(function()
								k:EquipTool(i)
							end)
						end
					end

					pcall(function()
						i:Activate()
					end)
				end
			end
		end)
		task.delay(0.35, function()
			n = false
		end)
	end

	local G = nil
	local i = 0
	local k = Q1 and 0.12 or 0.08
	local P = Q1 and 0.016666666666666666 or 0
	local l = Q1 and 0.03333333333333333 or 0.022222222222222223
	local Z = setmetatable({}, { __mode = "k" })
	local function E(r, L, y)
		local d = os.clock()
		local Qt = Z[r]
		if Qt and d < Qt.expires then
			local ft = Qt.desired.Magnitude
			local Ft = L.Magnitude
			local It = math.abs(ft - Ft) < 4
			local kt = ft < 0.01 or Ft < 0.01 or Qt.desired.Unit:Dot(L.Unit) > 0.985
			if It and kt then
				return Qt.safe, Qt.blocked
			end
		end

		local Qt, ft = n1(r, L, math.min(y, l))
		Z[r] = { desired = L, safe = Qt, blocked = ft, expires = d + l }
		return Qt, ft
	end

	local function l()
		local Z = Rt.Character and Rt.Character:FindFirstChild("HumanoidRootPart")
		if not Z then
			G = nil
			return nil, math.huge
		end

		local r = os.clock()
		if r < i and G and G.Parent then
			return G, (G.Position - Z.Position).Magnitude
		end

		local L, y = nil, math.huge
		for d, d in ipairs(bt:GetPlayers()) do
			if d ~= Rt and d.Character then
				local Qt = d.Character:FindFirstChild("HumanoidRootPart")
				local ft = d.Character:FindFirstChildOfClass("Humanoid")
				if Qt and ft and ft.Health > 0 then
					local d = (Qt.Position - Z.Position).Magnitude
					if d < y then
						y = d
						L = Qt
					end
				end
			end
		end

		G = L
		i = r + k
		return L, y
	end

	local G
	local function i()
		local k = G
		if k and k.Parent then
			pcall(function()
				k.Jump = false
			end)
		end

		G = nil
	end

	local function k(Z)
		if not Z then
			return
		end

		if G == Z then
			Z.Jump = false
			return
		end

		i()
		G = Z
		Z.Jump = false
	end

	local function G()
		if x1.batAimbot then
			x1.batAimbot:Disconnect()
		end

		local Z = Rt.Character and Rt.Character:FindFirstChildOfClass("Humanoid")
		if Z then
			Z.AutoRotate = false
			k(Z)
		end

		local Z = 0
		x1.batAimbot = pt.RenderStepped:Connect(function(r)
			Z = Z + r
			if Z < P then
				return
			end

			r = Z
			Z = 0
			if not zt.autoBatToggled then
				return
			end

			local Z = Rt.Character
			if not Z then
				return
			end

			local L = Z:FindFirstChild("HumanoidRootPart")
			if not L then
				return
			end

			local y = Z:FindFirstChildOfClass("Humanoid")
			if not y then
				return
			end

			k(y)
			if not Z:FindFirstChildOfClass("Tool") then
				local Z = f()
				if Z then
					pcall(function()
						y:EquipTool(Z)
					end)
				end
			end

			local Z, d = l()
			if not Z then
				G1(L, "VampireBat", Vector3.zero)
				return
			end

			local Qt = L.Position
			local ft = Z.Position
			local Z = ft - Qt
			local Ft = Vector3.new(Z.X, 0, Z.Z)
			if Ft.Magnitude > 0 then
				Ft = Ft.Unit
			else
				Ft = Vector3.zero
			end

			local Z = zt.autoBatSpeed
			local It = ft.Y + 3.7
			local kt = (It - Qt.Y) * 19.5
			if y.FloorMaterial ~= Enum.Material.Air then
				kt = math.min(kt, 13)
			end

			kt = math.clamp(kt, -70.0, 110)
			local y, It = E(L, Vector3.new(Ft.X * Z, 0, Ft.Z * Z), r)
			local Z = Vector3.new(y.X, kt, y.Z)
			local r = J1(L, "VampireBat")
			if r then
				local y = It and Z or r.VectorVelocity:Lerp(Z, 0.8)
				G1(L, "VampireBat", y)
			end

			local Z = ft - Qt
			if Z.Magnitude > 0.1 then
				local Z = CFrame.lookAt(Qt, ft)
				local r = L.CFrame:Inverse() * Z
				local Z, y, Qt = r:ToEulerAnglesXYZ()
				Z = math.clamp(Z, -2.5, 2.5)
				y = math.clamp(y, -2.5, 2.5)
				Qt = math.clamp(Qt, -2.5, 2.5)
				L.AssemblyAngularVelocity = L.CFrame:VectorToWorldSpace(
					It and Vector3.new(0, y * 42, 0) or Vector3.new(Z * 42, y * 42, Qt * 42)
				)
			end

			if zt.autoSwingEnabled and d <= 8 then
				s()
			end
		end)
	end

	local function Z()
		if x1.batAimbot then
			x1.batAimbot:Disconnect()
			x1.batAimbot = nil
		end

		local r = Rt.Character
		local L = r and r:FindFirstChild("HumanoidRootPart")
		if L then
			i1(L, "VampireBat")
			f1(L, "VampireBrake", Vector3.zero, 0.12)
			L.AssemblyAngularVelocity = Vector3.zero
		end

		local L = r and r:FindFirstChildOfClass("Humanoid")
		if L then
			L.AutoRotate = true
			L.PlatformStand = false
			pcall(function()
				L:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end

		n = false
		i()
	end

	local r, L
	local y, d
	local Qt
	local function ft()
		local Ft = l()
		return Ft
	end

	local function Ft()
		if Qt then
			Qt:Destroy()
		end

		Qt = Instance.new("Part")
		Qt.Shape = Enum.PartType.Ball
		Qt.Size = Vector3.new(2, 2, 2)
		Qt.Anchored = true
		Qt.CanCollide = false
		Qt.Material = Enum.Material.Neon
		Qt.Color = Color3.fromRGB(0, 150, 255)
		Qt.Transparency = 1
		Qt.Parent = workspace
		return Qt
	end

	local function It()
		if x1.batAimbot then
			x1.batAimbot:Disconnect()
		end

		local kt = Rt.Character
		if not kt then
			return
		end

		local tt = kt:FindFirstChildOfClass("Humanoid")
		local wt = kt:FindFirstChild("HumanoidRootPart")
		if not tt or not wt then
			return
		end

		y = tt.WalkSpeed
		d = nil
		tt.WalkSpeed = 0
		k(tt)
		if not Qt then
			Ft()
		end

		r = nil
		L = nil
		local Ft = 0
		x1.batAimbot = pt.RenderStepped:Connect(function(kt)
			Ft = Ft + kt
			if Ft < P then
				return
			end

			kt = Ft
			Ft = 0
			if not zt.autoBatToggled then
				return
			end

			local Ft = Rt.Character
			if not Ft then
				return
			end

			local tt = Ft:FindFirstChild("HumanoidRootPart")
			if not tt then
				return
			end

			local wt = Ft:FindFirstChildOfClass("Humanoid")
			if not wt then
				return
			end

			k(wt)
			local Ft = ft()
			if not Ft then
				G1(tt, "VampireBat", Vector3.zero)
				return
			end

			local ft = Ft.Position
			local Ft = tt.Position
			if r then
				L = (ft - r) / kt
			end

			r = ft
			local ot = Rt.CameraMode == Enum.CameraMode.LockFirstPerson
			wt.AutoRotate = ot
			local wt = ft + (L or Vector3.zero) * 0.22
			if not ot then
				local ot = wt - Ft
				if ot.Magnitude > 0.1 then
					local M1 = ot.Unit
					local ot = tt.CFrame.LookVector
					local g1 = ot:Cross(M1)
					local ot = math.clamp(g1.Magnitude, 0, 1)
					if g1.Magnitude > 0.01 then
						tt.AssemblyAngularVelocity = g1.Unit * ot * 80
					else
						tt.AssemblyAngularVelocity = Vector3.zero
					end
				end
			else
				tt.AssemblyAngularVelocity = Vector3.zero
			end

			local p = wt - Ft
			if p.Magnitude > 1 then
				local wt = p.Unit * zt.autoBatSpeed
				local p = E(tt, Vector3.new(wt.X, 0, wt.Z), kt)
				G1(tt, "VampireBat", Vector3.new(p.X, wt.Y, p.Z))
			else
				local p = J1(tt, "VampireBat")
				G1(tt, "VampireBat", Vector3.new(0, p and p.VectorVelocity.Y * 0.5 or 0, 0))
			end

			local p = (ft - Ft).Magnitude
			if zt.autoSwingEnabled and p <= 8 then
				s()
			end
		end)
	end

	local function p()
		if x1.batAimbot then
			x1.batAimbot:Disconnect()
			x1.batAimbot = nil
		end

		if Qt then
			Qt:Destroy()
			Qt = nil
		end

		local Qt = Rt.Character
		if Qt then
			local ft = Qt:FindFirstChildOfClass("Humanoid")
			if ft then
				ft.AutoRotate = true
				if y then
					ft.WalkSpeed = y
				end

				if d then
					ft.JumpPower = d
				end

				y = nil
				d = nil
			end

			local y = Qt:FindFirstChild("HumanoidRootPart")
			if y then
				i1(y, "VampireBat")
				f1(y, "VampireBrake", Vector3.zero, 0.12)
				y.AssemblyAngularVelocity = Vector3.zero
			end
		end

		r = nil
		L = nil
		i()
	end

	local r = game:GetService("Stats")
	local function L()
		if x1.batAimbot then
			x1.batAimbot:Disconnect()
			x1.batAimbot = nil
		end

		local y = Rt.Character and Rt.Character:FindFirstChildOfClass("Humanoid")
		if y then
			y.AutoRotate = false
			k(y)
		end

		local y = 0
		local d = 0
		local Qt = 0
		x1.batAimbot = pt.Heartbeat:Connect(function(ft)
			if not zt.autoBatToggled then
				return
			end

			y = y + (ft or 0)
			if y < P then
				return
			end

			ft = y
			y = 0
			local P = Rt.Character
			if not P then
				return
			end

			local y = P:FindFirstChild("HumanoidRootPart")
			local Ft = P:FindFirstChildOfClass("Humanoid")
			if not y or not Ft or Ft.Health <= 0 then
				return
			end

			k(Ft)
			local k = P:FindFirstChildOfClass("Tool")
			local kt = k and k.Name:lower() or ""
			if not k or not kt:find("bat") and not kt:find("slap") then
				local k = f()
				if k and k.Parent ~= P then
					pcall(function()
						Ft:EquipTool(k)
					end)
				end
			end

			local f, k = l()
			if not f then
				Ft.AutoRotate = true
				G1(y, "VampireBat", Vector3.zero)
				y.AssemblyAngularVelocity = Vector3.zero
				return
			end

			Ft.AutoRotate = false
			local P = f.AssemblyLinearVelocity
			local l = y.Position
			local kt = f.Position
			local tt = os.clock()
			if tt >= Qt then
				pcall(function()
					d = r.Network.ServerStatsItem["Data Ping"]:GetValue()
				end)
				d = math.clamp(d, 0, 300)
				Qt = tt + 0.25
			end

			local r = d
			local d = kt + P * (0.14 + r / 1000) + f.CFrame.LookVector * 0.4
			local f = d - l
			local r = Vector3.new(f.X, 0, f.Z)
			if r.Magnitude > 0.001 then
				r = r.Unit
			else
				r = Vector3.zero
			end

			local f = kt.Y + 3.7
			local d = (f - l.Y) * 19.5 + P.Y * 0.8
			if Ft.FloorMaterial ~= Enum.Material.Air then
				d = math.min(d, 13)
			end

			d = math.clamp(d, -70.0, 110)
			local f = zt.autoBatSpeed or 58
			local Qt = Vector3.new(r.X * f, 0, r.Z * f)
			local f, r = E(y, Qt, ft)
			local E = Vector3.new(f.X, d, f.Z)
			local f = J1(y, "VampireBat")
			local d = r and E or (f and f.VectorVelocity:Lerp(E, 0.85) or E)
			G1(y, "VampireBat", d)
			local f = P.Magnitude
			local E = math.clamp(f / 150, 0.05, 0.22)
			local f = kt + P * E
			local P = f - l
			if P.Magnitude > 0.1 then
				local P = CFrame.lookAt(l, f)
				local f = y.CFrame:Inverse() * P
				local P, l, E = f:ToEulerAnglesXYZ()
				P = math.clamp(P, -2.6, 2.6)
				l = math.clamp(l, -2.6, 2.6)
				E = math.clamp(E, -2.6, 2.6)
				y.AssemblyAngularVelocity =
					y.CFrame:VectorToWorldSpace(r and Vector3.new(0, l * 45, 0) or Vector3.new(P * 45, l * 45, E * 45))
			end

			if zt.autoSwingEnabled and k <= 8 then
				s()
			end
		end)
	end

	local function s()
		if x1.batAimbot then
			x1.batAimbot:Disconnect()
			x1.batAimbot = nil
		end

		local f = Rt.Character
		local k = f and f:FindFirstChild("HumanoidRootPart")
		local P = f and f:FindFirstChildOfClass("Humanoid")
		if k then
			i1(k, "VampireBat")
			f1(k, "VampireBrake", Vector3.zero, 0.12)
			k.AssemblyAngularVelocity = Vector3.zero
		end

		if P then
			P.AutoRotate = true
			P.PlatformStand = false
			pcall(function()
				P:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end

		n = false
		i()
	end

	startBatAimbot = function(n)
		if zt.countdownSafetyActive then
			return
		end

		if not n and isHoldingBrainrot and isHoldingBrainrot() then
			if zt.dropBrainrotMode then
				if runDropBrainrot then
					pcall(runDropBrainrot)
				end

				task.spawn(function()
					task.wait(0.22)
					if zt.autoBatToggled then
						startBatAimbot(true)
					end
				end)
				return
			end
		end

		if Kt.setAuto then
			Kt.setAuto("bat", true)
		end

		if zt.autoBatVersion == "v1" then
			L()
		elseif zt.autoBatVersion == "v2" then
			It()
		else
			G()
		end
	end

	stopBatAimbot = function()
		if Kt.setAuto then
			Kt.setAuto("bat", false)
		end

		if zt.autoBatVersion == "v1" then
			s()
		elseif zt.autoBatVersion == "v2" then
			p()
		else
			Z()
		end
	end
end

do
	local s = {}
	s._desyncCooldown = false
	s._desyncMyFloor = nil
	s._desyncTpFrom = nil
	s._desyncTpAt = -math.huge
	s._desyncFarArrivalTarget = nil
	s._desyncFarArrivalAt = -math.huge
	s._desyncSafeCFrame = nil
	s._desyncAimProxy = nil
	s._desyncBoundTarget = nil
	s._desyncBoundHumanoid = nil
	s._desyncTargetDiedConn = nil
	s._desyncTargetHealthConn = nil
	s._desyncTargetStateConn = nil
	s._desyncTargetPlatformConn = nil
	s._desyncPendingHitTarget = nil
	s._desyncLastSwingAt = -math.huge
	s._desyncPendingRoot = nil
	s._desyncBaselineVelocity = Vector3.zero
	s._desyncBaselinePosition = nil
	s._desyncWasRagdolledAtSwing = false
	s._desyncRagdollConfirmToken = 0
	s.DESYNC_MIN_Y = -30.0
	s.DESYNC_MAX_Y = 350
	s.DESYNC_MAX_TARGET_DISTANCE = 2500
	s.DESYNC_MAX_LOCKED_DISTANCE = 3000
	s.DESYNC_FAR_SETTLE_WINDOW = 0.25
	s.DESYNC_TRACK_RADIUS = 10
	s.DESYNC_TRACK_CONFIRM = 3
	s.DESYNC_TRACK_MAX_SPEED = 125
	s.DESYNC_TRACK_PREDICTION = 0.055
	s.DESYNC_TRACK_WINDOW = 0.9
	s.DESYNC_TRACK_MAX_SAMPLES = 48
	s.DESYNC_TRACK_MISSING_HOLD = 30
	s.DESYNC_TRACK_SAMPLE_INTERVAL = 0.022222222222222223
	s.DESYNC_TRACK_STABLE_TIME = 0.1
	s.DESYNC_TRACK_BOOTSTRAP_TIME = 0.18
	s.DESYNC_TRACK_LOCKED_MAX_STEP = 12
	s.DESYNC_TRACK_REP_RECOVER_TIME = 0.1
	s.DESYNC_TRACK_BODY_RECOVER_TIME = 0.3
	s.DESYNC_NORMAL_RECOVER_TIME = 0.28
	s.DESYNC_NORMAL_MAX_SPEED = 185
	s.DESYNC_NORMAL_MAX_ANGULAR = 55
	s.DESYNC_CHAOS_MIN_SAMPLES = 8
	s.DESYNC_CHAOS_JUMP = 18
	s._desyncTargetTracks = setmetatable({}, { __mode = "k" })
	local function n(f)
		return type(f) == "number" and f == f and math.abs(f) < 1000000
	end

	local function f(G)
		return typeof(G) == "Vector3" and n(G.X) and n(G.Y) and n(G.Z) and G.Y > s.DESYNC_MIN_Y and G.Y < s.DESYNC_MAX_Y
	end

	local function n(G)
		if not G then
			return nil
		end

		local i = G.Character
		if i then
			return i
		end

		local i = workspace:FindFirstChild(G.Name)
		if i and i:IsA("Model") and i:FindFirstChildOfClass("Humanoid") then
			return i
		end

		return nil
	end

	local function G(i)
		if not i then
			return nil
		end

		for p, p in ipairs({ "HumanoidRootPart", "LowerTorso", "UpperTorso", "Torso", "Head" }) do
			local k = i:FindFirstChild(p)
			if k and k:IsA("BasePart") then
				return k
			end
		end

		local p = i:FindFirstChildOfClass("Humanoid")
		if p and p.RootPart and p.RootPart:IsA("BasePart") then
			return p.RootPart
		end

		if i.PrimaryPart and i.PrimaryPart:IsA("BasePart") then
			return i.PrimaryPart
		end

		return i:FindFirstChildWhichIsA("BasePart", true)
	end

	s.AV_MAX_COORD = 20000
	s.AV_STEP = 45
	s.AV_HOLD = 0.35
	s.AV_HOLD_TOL = 6
	s.AV_MAX_VEL = 400
	s.AV_MAX_SPIN = 50
	s.AV_PROBE = 300
	s.AV_STAND_LO = 4
	s.AV_STAND_HI = 40
	s._avE = setmetatable({}, { __mode = "k" })
	s._avRay = RaycastParams.new()
	s._avRay.FilterType = Enum.RaycastFilterType.Exclude
	pcall(function()
		s._avRay.RespectCanCollide = true
	end)
	s.AV_PARTS = {
		"HumanoidRootPart",
		"UpperTorso",
		"LowerTorso",
		"Torso",
		"Head",
		"LeftUpperArm",
		"RightUpperArm",
		"LeftUpperLeg",
		"RightUpperLeg",
		"Left Arm",
		"Right Arm",
		"Left Leg",
		"Right Leg",
	}
	local function i(p, k)
		local P = nil
		pcall(function()
			s._avRay.FilterDescendantsInstances = k or {}
			P = workspace:Raycast(p + Vector3.new(0, 8, 0), Vector3.new(0, -s.AV_PROBE, 0), s._avRay)
		end)
		return P and P.Position.Y or nil
	end

	local function p(k)
		if typeof(k) ~= "Vector3" then
			return false
		end

		if k.X ~= k.X or k.Y ~= k.Y or k.Z ~= k.Z then
			return false
		end

		return math.abs(k.X) < s.AV_MAX_COORD and math.abs(k.Y) < s.AV_MAX_COORD and math.abs(k.Z) < s.AV_MAX_COORD
	end

	local function k(P)
		if not P then
			return nil
		end

		local l, Z = nil, 0
		for E, E in ipairs(s.AV_PARTS) do
			local r = P:FindFirstChild(E)
			if r and r:IsA("BasePart") then
				Z = Z + 1
				l = l or {}
				l[Z] = r.Position
			end
		end

		if not l then
			return nil
		end

		local P, E = nil, 0
		for r = 1, Z do
			local L, y = 0, Vector3.zero
			for d = 1, Z do
				if (l[d] - l[r]).Magnitude <= 9 then
					L = L + 1
					y = y + l[d]
				end
			end

			if L > E then
				E = L
				P = y / L
			end
		end

		return P
	end

	local function P(l, Z)
		if not p(l) then
			return false
		end

		local E = i(l, Z and { Z } or nil)
		if not E then
			return false
		end

		if l.Y < E - s.AV_STAND_LO then
			return false
		end

		if l.Y > E + s.AV_STAND_HI then
			return false
		end

		return true
	end

	_G._BD_avStanding = P
	local function l(Z, E)
		if not Z then
			return nil, false
		end

		local r = os.clock()
		local L = n(Z)
		local y = s._avE[Z]
		if not y or y.character ~= L then
			y = { character = L, good = nil, goodAt = 0, cand = nil, candAt = 0 }
			s._avE[Z] = y
		end

		if not L then
			return y.good, false
		end

		local Z = L:FindFirstChildOfClass("Humanoid")
		if Z and Z.Health <= 0 then
			return nil, false
		end

		E = E or G(L)
		local Z = k(L) or E and E.Position
		if Z then
			local k = E and E.AssemblyLinearVelocity or Vector3.zero
			local d = E and E.AssemblyAngularVelocity or Vector3.zero
			local Qt = p(Z) and k.Magnitude <= s.AV_MAX_VEL and d.Magnitude <= s.AV_MAX_SPIN and P(Z, L)
			if Qt then
				if y.good and (Z - y.good).Magnitude > s.AV_STEP then
					if y.cand and (Z - y.cand).Magnitude <= s.AV_HOLD_TOL then
						if r - y.candAt >= s.AV_HOLD then
							y.good = Z
							y.goodAt = r
							y.cand = nil
						end
					else
						y.cand = Z
						y.candAt = r
					end
				else
					y.good = Z
					y.goodAt = r
					y.cand = nil
				end
			else
				y.cand = nil
			end
		end

		if not y.good then
			return nil, false
		end

		local p = E ~= nil and (E.Position - y.good).Magnitude <= 4
		return y.good, p
	end

	pt.Heartbeat:Connect(function()
		local p = Rt.Character
		local k = p and p:FindFirstChild("HumanoidRootPart")
		if not k then
			return
		end

		local Z = k.Position
		local E = i(Z, { p })
		if E and Z.Y > E - 4 and Z.Y < E + 50 then
			s._desyncMyFloor = Z
		end

		pcall(function()
			if k.AssemblyAngularVelocity.Magnitude > 40 then
				k.AssemblyAngularVelocity = Vector3.zero
			end

			local i = k.AssemblyLinearVelocity
			if i.Magnitude > 300 then
				k.AssemblyLinearVelocity = Vector3.new(0, math.min(i.Y, 0), 0)
			end
		end)
	end)
	s._desyncPassiveTrackElapsed = 0
	pt.Heartbeat:Connect(function(i)
		if zt.desyncAimbotEnabled then
			s._desyncPassiveTrackElapsed = 0
			return
		end

		s._desyncPassiveTrackElapsed = s._desyncPassiveTrackElapsed + (i or 0)
		local i = Q1 and 0.05 or 0.03333333333333333
		if s._desyncPassiveTrackElapsed < i then
			return
		end

		s._desyncPassiveTrackElapsed = 0
		local i = Rt.Character
		local p = i and i:FindFirstChild("HumanoidRootPart")
		if not p then
			return
		end

		for i, i in ipairs(bt:GetPlayers()) do
			if i ~= Rt then
				local p = n(i)
				l(i, G(p))
			end
		end
	end)
	local function i(p)
		if sethiddenproperty and p then
			pcall(function()
				sethiddenproperty(p, "PhysicsRepRootPart", p)
			end)
		end
	end

	s._desyncGroundParams = RaycastParams.new()
	s._desyncGroundParams.FilterType = Enum.RaycastFilterType.Exclude
	s._desyncGroundParams.IgnoreWater = false
	local function p(k, Z)
		i(k)
		local i = s._desyncSafeCFrame
		if not (k and k.Parent and i) then
			return
		end

		k.AssemblyLinearVelocity = Vector3.zero
		k.AssemblyAngularVelocity = Vector3.zero
		k.CFrame = i + Vector3.new(0, 2.5, 0)
		f1(k, "VampireBrake", Vector3.zero, 0.35)
		if Z and Z.Parent then
			pcall(function()
				Z:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end

		local k = workspace.CurrentCamera
		if k and Z then
			pcall(function()
				k.CameraSubject = Z
			end)
		end

		task.spawn(function()
			pcall(function()
				Rt:RequestStreamAroundAsync(i.Position)
			end)
		end)
	end

	local function i(k)
		if not k then
			return false
		end

		local Z = k:GetState()
		return k.PlatformStand
			or Z == Enum.HumanoidStateType.Physics
			or Z == Enum.HumanoidStateType.Ragdoll
			or Z == Enum.HumanoidStateType.FallingDown
			or Z == Enum.HumanoidStateType.PlatformStanding
	end

	local function k(Z)
		if not Z then
			return false
		end

		for E, E in ipairs({ "Ragdolled", "Ragdoll", "IsRagdolled", "Knocked", "KnockedDown", "Stunned" }) do
			if Z:GetAttribute(E) == true then
				return true
			end

			local r = Z:FindFirstChild(E, true)
			if r and r:IsA("BoolValue") and r.Value then
				return true
			end
		end

		return false
	end

	local function Z(E, r, L)
		if i(r) or k(E) then
			return true
		end

		local i = 0
		local k = 0
		for r, r in ipairs(E and E:GetDescendants() or {}) do
			if r:IsA("BallSocketConstraint") and r.Enabled then
				i = i + 1
				if i >= 2 then
					return true
				end
			elseif r:IsA("Motor6D") and r.Enabled == false then
				k = k + 1
				if k >= 2 then
					return true
				end
			end
		end

		if L then
			local i = s1(L)
			local k = L.AssemblyAngularVelocity
			if k.Magnitude >= 7 and i.Magnitude >= 10 then
				return true
			end
		end

		return false
	end

	local function i(k)
		if not (k and k.Parent and s._desyncBaselinePosition) then
			return false
		end

		local E = k.Position
		if not f(E) then
			return false
		end

		local k = E - s._desyncBaselinePosition
		local E = Vector3.new(k.X, 0, k.Z).Magnitude
		if math.abs(k.Y) > 7.5 or E > 12 then
			return false
		end

		return true
	end

	local function k(E)
		if not i(E) then
			return false
		end

		local r = s1(E)
		local L = (r - s._desyncBaselineVelocity).Magnitude
		local y = (E.Position - s._desyncBaselinePosition).Magnitude
		local d = E.AssemblyAngularVelocity.Magnitude
		return L >= 24 and (r.Magnitude >= 24 or d >= 4) or d >= 8 and r.Magnitude >= 10 or y >= 3 and r.Magnitude >= 28
	end

	local function E(r, L, y)
		if not (zt.desyncStopAfterHit and zt.desyncAimbotEnabled) then
			return
		end

		if s._desyncBoundTarget ~= r or s._desyncPendingHitTarget ~= r or s._desyncWasRagdolledAtSwing then
			return
		end

		local d = n(r)
		local Qt = G(d)
		local ft = os.clock() - s._desyncLastSwingAt
		if ft < 0 or ft > 0.9 or not i(Qt) or not (Z(d, L, Qt) or y == true) then
			return
		end

		s._desyncRagdollConfirmToken = s._desyncRagdollConfirmToken + 1
		local y = s._desyncRagdollConfirmToken
		task.spawn(function()
			pt.Heartbeat:Wait()
			pt.Heartbeat:Wait()
			if y ~= s._desyncRagdollConfirmToken or not (zt.desyncStopAfterHit and zt.desyncAimbotEnabled) then
				return
			end

			local y = n(r)
			local d = G(y)
			if
				s._desyncBoundTarget == r
				and s._desyncPendingHitTarget == r
				and not s._desyncWasRagdolledAtSwing
				and os.clock() - s._desyncLastSwingAt <= 1
				and i(d)
				and (Z(y, L, d) or k(d))
			then
				if _VH_forceDesyncOff then
					_VH_forceDesyncOff()
				end
			end
		end)
	end

	local function r()
		if
			not (
				zt.desyncStopAfterHit
				and zt.desyncAimbotEnabled
				and s._desyncPendingHitTarget
				and s._desyncPendingRoot
			) or s._desyncWasRagdolledAtSwing
		then
			return
		end

		if os.clock() - s._desyncLastSwingAt > 0.9 then
			s._desyncPendingHitTarget = nil
			s._desyncPendingRoot = nil
			return
		end

		local L = s._desyncPendingHitTarget
		local y = n(L)
		local d = y and y:FindFirstChildOfClass("Humanoid")
		local Qt = G(y)
		if Qt ~= s._desyncPendingRoot or not d then
			return
		end

		if not i(Qt) then
			s._desyncRagdollConfirmToken = s._desyncRagdollConfirmToken + 1
			s._desyncPendingHitTarget = nil
			s._desyncPendingRoot = nil
			s._desyncBaselinePosition = nil
			return
		end

		local i = k(Qt)
		if Z(y, d, Qt) or i then
			E(L, d, i)
		end
	end

	local function i(k)
		if
			s._desyncBoundTarget == k
			and s._desyncBoundHumanoid
			and s._desyncBoundHumanoid.Parent
			and s._desyncTargetDiedConn
			and s._desyncTargetHealthConn
			and s._desyncTargetStateConn
			and s._desyncTargetPlatformConn
		then
			return
		end

		if s._desyncTargetDiedConn then
			s._desyncTargetDiedConn:Disconnect()
			s._desyncTargetDiedConn = nil
		end

		if s._desyncTargetHealthConn then
			s._desyncTargetHealthConn:Disconnect()
			s._desyncTargetHealthConn = nil
		end

		if s._desyncTargetStateConn then
			s._desyncTargetStateConn:Disconnect()
			s._desyncTargetStateConn = nil
		end

		if s._desyncTargetPlatformConn then
			s._desyncTargetPlatformConn:Disconnect()
			s._desyncTargetPlatformConn = nil
		end

		s._desyncBoundTarget = k
		s._desyncBoundHumanoid = nil
		s._desyncPendingHitTarget = nil
		s._desyncPendingRoot = nil
		s._desyncBaselinePosition = nil
		local L = n(k)
		local y = L and L:FindFirstChildOfClass("Humanoid")
		if not y then
			return
		end

		s._desyncBoundHumanoid = y
		local function L()
			if zt.desyncAimbotEnabled and s._desyncBoundTarget == k and s._desyncBoundHumanoid == y then
				task.spawn(function()
					if _VH_forceDesyncOff then
						_VH_forceDesyncOff()
					end
				end)
			end
		end

		s._desyncTargetDiedConn = y.Died:Connect(function()
			L()
		end)
		s._desyncTargetHealthConn = y:GetPropertyChangedSignal("Health"):Connect(function()
			if y.Health <= 0 then
				L()
			end
		end)
		s._desyncTargetStateConn = y.StateChanged:Connect(function(d, d)
			if d == Enum.HumanoidStateType.Dead then
				L()
				return
			end

			if
				d == Enum.HumanoidStateType.Physics
				or d == Enum.HumanoidStateType.Ragdoll
				or d == Enum.HumanoidStateType.FallingDown
				or d == Enum.HumanoidStateType.PlatformStanding
			then
				E(k, y)
			end
		end)
		s._desyncTargetPlatformConn = y:GetPropertyChangedSignal("PlatformStand"):Connect(function()
			if y.PlatformStand then
				E(k, y)
			end
		end)
	end

	local function k()
		if not s._desyncBoundTarget then
			return false
		end

		if s._desyncBoundTarget.Parent ~= bt then
			return true
		end

		local E = s._desyncBoundHumanoid
		if E then
			if not E.Parent or E.Health <= 0 then
				return true
			end

			local L, y = pcall(function()
				return E:GetState()
			end)
			if L and y == Enum.HumanoidStateType.Dead then
				return true
			end
		end

		local E = n(s._desyncBoundTarget)
		local L = E and E:FindFirstChildOfClass("Humanoid")
		return L ~= nil and L.Health <= 0
	end

	local function E()
		local L = Rt.Character
		if not L then
			return nil
		end

		local y = L:FindFirstChild("Bat")
		if y then
			return y
		end

		local d = Rt:FindFirstChild("Backpack")
		if d then
			y = d:FindFirstChild("Bat")
			if y then
				y.Parent = L
				return y
			end
		end

		return nil
	end

	local function L(y, d, Qt)
		if s._desyncCooldown then
			return
		end

		s._desyncCooldown = true
		local ft = false
		local Ft = n(y)
		local It = Ft and Ft:FindFirstChildOfClass("Humanoid")
		local kt = d and s1(d) or Vector3.zero
		local tt = d and d.Position or nil
		local wt = Z(Ft, It, d)
		pcall(function()
			local Z = E()
			if Z then
				ft = true
				Z:Activate()
				local E = Z:FindFirstChildWhichIsA("RemoteEvent")
				if E then
					E:FireServer()
				end
			end
		end)
		if
			ft
			and zt.desyncStopAfterHit
			and not wt
			and y
			and d
			and Qt
			and (d.Position - Qt.Position).Magnitude <= 18
		then
			s._desyncPendingHitTarget = y
			s._desyncPendingRoot = d
			s._desyncBaselineVelocity = kt
			s._desyncBaselinePosition = tt
			s._desyncWasRagdolledAtSwing = false
			s._desyncLastSwingAt = os.clock()
		end

		task.delay(0.08, function()
			s._desyncCooldown = false
		end)
	end

	local function Z()
		if not hrp then
			return nil, math.huge, nil, nil
		end

		local E, y, d, Qt = nil, math.huge, nil, nil
		for ft, ft in pairs(bt:GetPlayers()) do
			if ft ~= Rt then
				local Ft = n(ft)
				local n = G(Ft)
				if n then
					local G = l(ft, n)
					if G then
						local l = (hrp.Position - G).Magnitude
						if l < y then
							y = l
							E = ft
							d = G
							Qt = n
						end
					end
				end
			end
		end

		return E, y, d, Qt
	end

	local function n(G)
		if zt.countdownSafetyActive then
			return
		end

		if not G and isHoldingBrainrot and isHoldingBrainrot() then
			if zt.dropBrainrotMode then
				if runDropBrainrot then
					pcall(runDropBrainrot)
				end

				task.spawn(function()
					task.wait(0.22)
					if zt.desyncAimbotEnabled then
						startDesyncAimbot(true)
					end
				end)
				return
			end
		end

		if Kt.setAuto then
			Kt.setAuto("desync", true)
		end

		if x1.desyncAimbot then
			return
		end

		if _G.VHSetAntiCollisionSuspended then
			pcall(_G.VHSetAntiCollisionSuspended, true)
		end

		local G = Rt.Character and Rt.Character:FindFirstChild("HumanoidRootPart")
		if G and f(G.Position) then
			s._desyncSafeCFrame = G.CFrame
		end

		x1.desyncAimbot = pt.Heartbeat:Connect(function()
			if not zt.desyncAimbotEnabled then
				return
			end

			local G = Rt.Character
			local l = G and G:FindFirstChildOfClass("Humanoid")
			local E = G and G:FindFirstChild("HumanoidRootPart")
			if not (l and E) or l.Health <= 0 then
				return
			end

			h = l
			hrp = E
			if not f(E.Position) then
				p(E, l)
				return
			end

			if s._desyncTpFrom and os.clock() - s._desyncTpAt < 0.6 then
				if not P(E.Position, G) then
					pcall(function()
						E.CFrame = CFrame.new(s._desyncTpFrom)
						E.AssemblyLinearVelocity = Vector3.zero
						E.AssemblyAngularVelocity = Vector3.zero
					end)
					s._desyncTpFrom = nil
					return
				end
			elseif s._desyncTpFrom then
				s._desyncTpFrom = nil
			end

			if k() then
				task.spawn(function()
					if _VH_forceDesyncOff then
						_VH_forceDesyncOff()
					end
				end)
				return
			end

			r()
			local f, G, G, p = Z()
			if f and G and p then
				i(f)
				if sethiddenproperty and (p.Position - G).Magnitude <= 4 then
					pcall(function()
						sethiddenproperty(hrp, "PhysicsRepRootPart", p)
					end)
				end

				local i = G + Vector3.new(0, 0.9, 0)
				local k = (hrp.Position - i).Magnitude
				local l = k > 8
				local k = os.clock()
				local Z = s._desyncFarArrivalTarget == f and k - s._desyncFarArrivalAt <= s.DESYNC_FAR_SETTLE_WINDOW
				if l then
					if P(i, Rt.Character) then
						s._desyncTpFrom = s._desyncMyFloor
							or s._desyncSafeCFrame and s._desyncSafeCFrame.Position
							or hrp.Position
						s._desyncTpAt = k
						hrp.CFrame = CFrame.new(i)
						if Z then
							s._desyncFarArrivalTarget = nil
						else
							s._desyncFarArrivalTarget = f
							s._desyncFarArrivalAt = k
						end
					else
						s._desyncFarArrivalTarget = nil
					end
				else
					s._desyncFarArrivalTarget = nil
				end

				local i = workspace.CurrentCamera
				if i then
					i.CFrame = CFrame.new(i.CFrame.Position, G)
				end

				if not l or Z then
					L(f, p, E)
				end
			else
				s._desyncFarArrivalTarget = nil
			end
		end)
	end

	local function f()
		if Kt.setAuto then
			Kt.setAuto("desync", false)
		end

		if x1.desyncAimbot then
			x1.desyncAimbot:Disconnect()
			x1.desyncAimbot = nil
		end

		if s._desyncTargetDiedConn then
			s._desyncTargetDiedConn:Disconnect()
			s._desyncTargetDiedConn = nil
		end

		if s._desyncTargetHealthConn then
			s._desyncTargetHealthConn:Disconnect()
			s._desyncTargetHealthConn = nil
		end

		if s._desyncTargetStateConn then
			s._desyncTargetStateConn:Disconnect()
			s._desyncTargetStateConn = nil
		end

		if s._desyncTargetPlatformConn then
			s._desyncTargetPlatformConn:Disconnect()
			s._desyncTargetPlatformConn = nil
		end

		s._desyncRagdollConfirmToken = s._desyncRagdollConfirmToken + 1
		s._desyncPendingHitTarget = nil
		s._desyncPendingRoot = nil
		s._desyncBaselinePosition = nil
		s._desyncWasRagdolledAtSwing = false
		s._desyncBoundTarget = nil
		s._desyncBoundHumanoid = nil
		s._desyncCooldown = false
		s._desyncFarArrivalTarget = nil
		s._desyncFarArrivalAt = -math.huge
		if s._desyncAimProxy then
			pcall(function()
				s._desyncAimProxy:Destroy()
			end)
			s._desyncAimProxy = nil
		end

		s._desyncSafeCFrame = nil
		if _G.VHSetAntiCollisionSuspended then
			pcall(_G.VHSetAntiCollisionSuspended, false)
		end
	end

	s._desyncV2Conn = nil
	s._desyncV2HitCooldown = false
	s._desyncV2LastSafeCF = nil
	s._desyncV2LastSafeAt = 0
	s.DESYNC_V2_VOID_Y = -35.0
	local function G(i, p)
		if i and p and i.Position.Y > s.DESYNC_V2_VOID_Y + 10 and p.FloorMaterial ~= Enum.Material.Air then
			s._desyncV2LastSafeCF = i.CFrame
			s._desyncV2LastSafeAt = tick()
		end
	end

	local function i(p)
		if not p then
			return false
		end

		local k = p.Position.Y < s.DESYNC_V2_VOID_Y or p.AssemblyLinearVelocity.Y < -210.0
		if not k then
			return false
		end

		local k = nil
		if s._desyncV2LastSafeCF and tick() - s._desyncV2LastSafeAt < 5 then
			k = s._desyncV2LastSafeCF
		end

		if k then
			p.CFrame = k + Vector3.new(0, 3, 0)
		else
			p.CFrame = CFrame.new(p.Position.X, 12, p.Position.Z)
		end

		p.AssemblyLinearVelocity = Vector3.zero
		p.AssemblyAngularVelocity = Vector3.zero
		return true
	end

	local function p()
		local k = Rt.Character
		if not k then
			return nil
		end

		local P = k:FindFirstChild("Bat")
		if P then
			return P
		end

		local l = Rt:FindFirstChild("Backpack")
		P = l and l:FindFirstChild("Bat") or nil
		if P then
			pcall(function()
				P.Parent = k
			end)
		end

		return P
	end

	local function k(P)
		if s._desyncV2HitCooldown or not P then
			return
		end

		s._desyncV2HitCooldown = true
		pcall(function()
			P:Activate()
			local l = P:FindFirstChildWhichIsA("RemoteEvent")
			if l then
				l:FireServer()
			end
		end)
		task.delay(0.08, function()
			s._desyncV2HitCooldown = false
		end)
	end

	local function P()
		if not zt.desyncAimbotEnabled or zt.desyncAimbotVersion ~= "v2" then
			return
		end

		local l = Rt.Character
		if not l then
			return
		end

		local Z = l:FindFirstChild("HumanoidRootPart")
		local E = l:FindFirstChildOfClass("Humanoid")
		if not (Z and E) or E.Health <= 0 then
			return
		end

		G(Z, E)
		if i(Z) then
			return
		end

		local i = p()
		local p, l = nil, math.huge
		for E, E in ipairs(bt:GetPlayers()) do
			if E ~= Rt and E.Character then
				local r = E.Character:FindFirstChild("HumanoidRootPart")
				if r then
					local E = (Z.Position - r.Position).Magnitude
					if E < l then
						p = r
						l = E
					end
				end
			end
		end

		if not p or l > 100 then
			return
		end

		if sethiddenproperty then
			pcall(sethiddenproperty, Z, "PhysicsRepRootPart", p)
		end

		local l = p.Position + Vector3.new(0, 0.9, 0)
		if (Z.Position - l).Magnitude > 8 then
			Z.AssemblyLinearVelocity = Vector3.zero
			Z.AssemblyAngularVelocity = Vector3.zero
			Z.CFrame = CFrame.new(l)
			Z.AssemblyLinearVelocity = Vector3.zero
			Z.AssemblyAngularVelocity = Vector3.zero
		end

		local l = workspace.CurrentCamera
		if l and not (zt.tpBatCameraShake and Mt.MouseBehavior == Enum.MouseBehavior.LockCenter) then
			l.CFrame = CFrame.new(l.CFrame.Position, p.Position)
		end

		if i then
			k(i)
		end
	end

	local function i(p)
		if zt.countdownSafetyActive then
			return
		end

		if not p and isHoldingBrainrot and isHoldingBrainrot() and zt.dropBrainrotMode then
			if runDropBrainrot then
				pcall(runDropBrainrot)
			end

			task.spawn(function()
				task.wait(0.22)
				if zt.desyncAimbotEnabled then
					startDesyncAimbot(true)
				end
			end)
			return
		end

		if Kt.setAuto then
			Kt.setAuto("desync", true)
		end

		if s._desyncV2Conn then
			return
		end

		if _G.VHSetAntiCollisionSuspended then
			pcall(_G.VHSetAntiCollisionSuspended, true)
		end

		local p = Rt.Character
		local k = p and p:FindFirstChild("HumanoidRootPart")
		local l = p and p:FindFirstChildOfClass("Humanoid")
		G(k, l)
		s._desyncV2Conn = pt.Heartbeat:Connect(P)
		x1.desyncAimbot = s._desyncV2Conn
	end

	local function G()
		if Kt.setAuto then
			Kt.setAuto("desync", false)
		end

		if s._desyncV2Conn then
			s._desyncV2Conn:Disconnect()
			s._desyncV2Conn = nil
		end

		x1.desyncAimbot = nil
		local p = Rt.Character
		local k = p and p:FindFirstChild("HumanoidRootPart")
		if k then
			if sethiddenproperty then
				pcall(sethiddenproperty, k, "PhysicsRepRootPart", nil)
			end

			k.AssemblyLinearVelocity = Vector3.zero
			k.AssemblyAngularVelocity = Vector3.zero
		end

		local k = p and p:FindFirstChildOfClass("Humanoid")
		if k then
			k.AutoRotate = true
			k.PlatformStand = false
			pcall(function()
				k:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end

		s._desyncV2HitCooldown = false
		s._desyncV2LastSafeCF = nil
		s._desyncV2LastSafeAt = 0
		if _G.VHSetAntiCollisionSuspended then
			pcall(_G.VHSetAntiCollisionSuspended, false)
		end
	end

	s._desyncRunningVersion = nil
	startDesyncAimbot = function(...)
		local p = zt.desyncAimbotVersion == "v2" and "v2" or "v1"
		s._desyncRunningVersion = p
		if p == "v2" then
			return i(...)
		end

		return n(...)
	end

	stopDesyncAimbot = function()
		local n = s._desyncRunningVersion or (zt.desyncAimbotVersion == "v2" and "v2" or "v1")
		s._desyncRunningVersion = nil
		if n == "v2" then
			return G()
		end

		return f()
	end
end

function _VH_forceAimbotOff()
	if zt.autoBatToggled then
		zt.autoBatToggled = false
		if setAutoBat then
			setAutoBat(false)
		end

		if Bt and Bt.aimbot then
			Bt.aimbot.setOn(false)
		end

		stopBatAimbot()
	end
end

function _VH_forceDesyncOff()
	if zt.desyncAimbotEnabled then
		zt.desyncAimbotEnabled = false
		if setDesyncAimbot then
			setDesyncAimbot(false)
		end

		if Bt and Bt.tpDesync then
			Bt.tpDesync.setOn(false)
		end

		stopDesyncAimbot()
	end
end

do
	local s = {
		enabled = false,
		loop = nil,
		healthConn = nil,
		charConn = nil,
		lastHealTime = 0,
		invincibleUntil = 0,
		config = {
			healthThreshold = 50,
			invincibilityFrames = 0.75,
			fallDamageProtection = false,
			ragdollProtection = true,
			autoRevive = true,
		},
	}
	local function n(f)
		if not (f and f.Parent) then
			return
		end

		local G = f.MaxHealth or 100
		if G <= 0 then
			G = 100
		end

		pcall(function()
			f.Health = G
			if f.MaxHealth < G then
				f.MaxHealth = G
			end
		end)
		s.invincibleUntil = tick() + s.config.invincibilityFrames
		s.lastHealTime = tick()
		pcall(function()
			local i = f.Parent
			if not i then
				return
			end

			for f, f in ipairs(i:GetChildren()) do
				if f:IsA("NumberValue") then
					local i = f.Name:lower()
					if i:find("health") or i:find("hp") or i:find("life") then
						f.Value = G
					end
				end

				if f:IsA("BoolValue") and f.Name:lower():find("dead") then
					f.Value = false
				end
			end
		end)
	end

	local function f(G, i)
		if not i then
			return
		end

		if i.Health < (i.MaxHealth or 100) then
			n(i)
		end

		if tick() < s.invincibleUntil and i.Health < (i.MaxHealth or 100) then
			i.Health = i.MaxHealth or 100
		end

		if s.config.ragdollProtection then
			local p = i:GetState()
			if
				p == Enum.HumanoidStateType.Physics
				or p == Enum.HumanoidStateType.Ragdoll
				or p == Enum.HumanoidStateType.FallingDown
				or p == Enum.HumanoidStateType.Dead
			then
				pcall(function()
					i:ChangeState(Enum.HumanoidStateType.GettingUp)
					i:ChangeState(Enum.HumanoidStateType.Running)
				end)
				n(i)
				if G then
					pcall(function()
						G.AssemblyAngularVelocity = Vector3.zero
					end)
				end
			end
		end

		if i.Health <= 0 then
			n(i)
			pcall(function()
				i:ChangeState(Enum.HumanoidStateType.GettingUp)
				i:ChangeState(Enum.HumanoidStateType.Running)
			end)
			if G then
				pcall(function()
					G.CFrame = CFrame.new(G.Position + Vector3.new(0, 2, 0))
					G.AssemblyLinearVelocity = Vector3.zero
				end)
			end
		end
	end

	local function G()
		if not s.config.autoRevive then
			return
		end

		local i = Rt.Character
		if not i then
			return
		end

		local p = i:FindFirstChildOfClass("Humanoid")
		local k = i:FindFirstChild("HumanoidRootPart")
		if not p then
			return
		end

		if p.Health <= 0 then
			n(p)
			pcall(function()
				p:ChangeState(Enum.HumanoidStateType.GettingUp)
				p:ChangeState(Enum.HumanoidStateType.Running)
			end)
			if k then
				pcall(function()
					k.CFrame = CFrame.new(k.Position + Vector3.new(0, 3, 0))
					k.AssemblyLinearVelocity = Vector3.zero
				end)
			end
		end
	end

	Kt.start = function()
		s.enabled = true
		if s.loop then
			s.loop:Disconnect()
			s.loop = nil
		end

		if s.healthConn then
			s.healthConn:Disconnect()
			s.healthConn = nil
		end

		if s.charConn then
			s.charConn:Disconnect()
			s.charConn = nil
		end

		s.loop = pt.Heartbeat:Connect(function()
			if not s.enabled then
				return
			end

			local i = Rt.Character
			if not i then
				return
			end

			local p = i:FindFirstChildOfClass("Humanoid")
			local k = i:FindFirstChild("HumanoidRootPart")
			if not p then
				return
			end

			if p.Health <= 0 then
				G()
			elseif p.Health <= s.config.healthThreshold then
				n(p)
			elseif p.Health < (p.MaxHealth or 100) then
				n(p)
			end

			f(k, p)
		end)
		local function f(i)
			if s.healthConn then
				s.healthConn:Disconnect()
				s.healthConn = nil
			end

			local p = i and i:FindFirstChildOfClass("Humanoid")
			if not p then
				p = i and i:WaitForChild("Humanoid", 3)
			end

			if not p then
				return
			end

			s.healthConn = p:GetPropertyChangedSignal("Health"):Connect(function()
				if not s.enabled then
					return
				end

				if p.Health < (p.MaxHealth or 100) then
					n(p)
				end

				if p.Health <= 0 then
					G()
				end
			end)
			if p.Health < (p.MaxHealth or 100) then
				n(p)
			end
		end

		if Rt.Character then
			f(Rt.Character)
		end

		s.charConn = Rt.CharacterAdded:Connect(function(G)
			if not s.enabled then
				return
			end

			task.wait(0.05)
			f(G)
			local f = G:FindFirstChildOfClass("Humanoid")
			if f then
				n(f)
			end
		end)
	end

	Kt.stop = function()
		s.enabled = false
		if s.loop then
			s.loop:Disconnect()
			s.loop = nil
		end

		if s.healthConn then
			s.healthConn:Disconnect()
			s.healthConn = nil
		end

		if s.charConn then
			s.charConn:Disconnect()
			s.charConn = nil
		end
	end

	local n, f, G = false, false, false
	Kt.refresh = function()
		local i = zt.antiDieEnabled or n or f or G
		if i then
			if not s.enabled then
				Kt.start()
			end
		elseif s.enabled then
			Kt.stop()
		end

		if Kt.setVisual then
			Kt.setVisual(i)
		end
	end

	Kt.setAuto = function(s, i)
		i = i == true
		if s == "bat" then
			n = i
		elseif s == "desync" then
			f = i
		elseif s == "wall" then
			G = i
		end

		Kt.refresh()
	end
end

do
	local function s()
		local n = Rt.Character
		if not n then
			return nil
		end

		for f, f in ipairs(n:GetChildren()) do
			if f:IsA("Tool") then
				local n = f.Name:lower()
				if n:find("medusa") or n:find("head") or n:find("stone") then
					return f
				end
			end
		end

		local n = Rt:FindFirstChild("Backpack")
		if n then
			for f, f in ipairs(n:GetChildren()) do
				if f:IsA("Tool") then
					local n = f.Name:lower()
					if n:find("medusa") or n:find("head") or n:find("stone") then
						return f
					end
				end
			end
		end

		return nil
	end

	local function n()
		if zt.medusaDebounce then
			return
		end

		if tick() - zt.medusaLastUsed < W.MEDUSA_COOLDOWN then
			return
		end

		local f = Rt.Character
		if not f then
			return
		end

		zt.medusaDebounce = true
		local G = s()
		if not G then
			zt.medusaDebounce = false
			return
		end

		if G.Parent ~= f then
			local s = f:FindFirstChildOfClass("Humanoid")
			if s then
				s:EquipTool(G)
			end
		end

		pcall(function()
			G:Activate()
		end)
		zt.medusaLastUsed = tick()
		zt.medusaDebounce = false
	end

	local function s(f)
		return f:GetPropertyChangedSignal("Anchored"):Connect(function()
			if f.Anchored and f.Transparency == 1 and zt.medusaCounterEnabled then
				n()
			end
		end)
	end

	setupMedusaCounter = function(n)
		stopMedusaCounter()
		if not n then
			return
		end

		for f, f in ipairs(n:GetDescendants()) do
			if f:IsA("BasePart") then
				table.insert(x1.anchor, s(f))
			end
		end

		table.insert(
			x1.anchor,
			n.DescendantAdded:Connect(function(n)
				if n:IsA("BasePart") then
					table.insert(x1.anchor, s(n))
				end
			end)
		)
	end

	stopMedusaCounter = function()
		for s, s in pairs(x1.anchor) do
			pcall(function()
				s:Disconnect()
			end)
		end

		x1.anchor = {}
	end
end

local s = {
	Vector3.new(-475.25999755859374, -9.140000343322754, 92.94999694824219),
	Vector3.new(-485.0200134277344, -7.889999866485596, 93.62000274658203),
	Vector3.new(-477.010009765625, -8.930000305175781, 93.06999969482422),
	Vector3.new(-475.2699890136719, -6.579999923706055, 21.549999237060547),
}
local n = {
	Vector3.new(-475.2299865722656, -9.010000228881836, 28.510000228881836),
	Vector3.new(-485.0299987792969, -7.889999866485596, 27.790000915527344),
	Vector3.new(-476.9200134277344, -8.970000267028809, 28.030000686645508),
	Vector3.new(-476.17999267578125, -6.099999904632568, 97.7300033569336),
}
W.ARRIVAL_DISTANCE = 1
W.CHECKPOINT_3_WAIT = 0.1
local f, G = nil, nil
local i = 0
local function p()
	i = i + 1
	local k = Rt.Character
	local P = k and k:FindFirstChildOfClass("Humanoid")
	if not P then
		return
	end

	if f ~= P then
		if f and f.Parent and G ~= nil then
			f.AutoRotate = G
		end

		f = P
		G = P.AutoRotate
	end

	P.AutoRotate = false
end

local function k()
	i = i + 1
	local P = i
	local l = f
	local Z = G
	task.spawn(function()
		if P ~= i or l ~= f then
			return
		end

		if l and l.Parent then
			local i = l.Parent:FindFirstChild("HumanoidRootPart")
			if i then
				i.AssemblyAngularVelocity = Vector3.zero
			end

			l.AutoRotate = Z == nil and true or Z
		end

		f = nil
		G = nil
	end)
end

local f = nil
local G = nil
local function i(P)
	if not V1(P) then
		return nil
	end

	if G ~= P or not (f and f.Parent == P) then
		if f and f.Parent then
			pcall(function()
				f.Enabled = false
				f:Destroy()
			end)
		end

		local l = P:FindFirstChild("VampireWalkAttachment")
		if not (l and l:IsA("Attachment")) then
			l = Instance.new("Attachment")
			l.Name = "VampireWalkAttachment"
			l.Parent = P
		end

		local Z = P:FindFirstChild("VampireWalkLinearVelocity")
		if not (Z and Z:IsA("LinearVelocity")) then
			Z = Instance.new("LinearVelocity")
			Z.Name = "VampireWalkLinearVelocity"
			Z.Parent = P
		end

		Z.Attachment0 = l
		Z.RelativeTo = Enum.ActuatorRelativeTo.World
		Z.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		Z.PrimaryTangentAxis = Vector3.new(1, 0, 0)
		Z.SecondaryTangentAxis = Vector3.new(0, 0, 1)
		pcall(function()
			Z.ForceLimitsEnabled = false
		end)
		Z.PlaneVelocity = Vector2.zero
		Z.Enabled = true
		f = Z
		G = P
	end

	return f
end

local function P(l, Z)
	local E = Rt.Character
	if not (E and l and l.Parent) then
		return false
	end

	local r = l:FindFirstChild("VampireRoofLinearVelocity")
	if r then
		pcall(function()
			r.Enabled = false
			r:Destroy()
		end)
	end

	local r = l:FindFirstChild("VampireRoofAttachment")
	if r then
		pcall(function()
			r:Destroy()
		end)
	end

	m1.FilterDescendantsInstances = { E }
	local r = math.max(s1(l).Y, 0)
	if r <= 0.25 then
		return false
	end

	local c = math.clamp(Z or 0.016666666666666666, 0.004166666666666667, 0.06666666666666667)
	local Z = 3.05 + math.min(r * c, 0.9)
	local r = workspace:Raycast(l.Position, Vector3.new(0, Z, 0), m1)
	if not r then
		return false
	end

	local Z = E:FindFirstChildOfClass("Humanoid")
	if Z then
		Z.Jump = false
	end

	local Z = l.AssemblyLinearVelocity
	local E = l:FindFirstChild("VampireInfJumpLinearVelocity") ~= nil
	if Z.Y > 0 and (E or Z.Y > 60) then
		l.AssemblyLinearVelocity = Vector3.new(Z.X, 0, Z.Z)
	end

	if l:FindFirstChild("VampireInfJumpLinearVelocity") then
		i1(l, "VampireInfJump")
	end

	if l:FindFirstChild("VampireStepLinearVelocity") then
		i1(l, "VampireStep")
	end

	return true
end

local function l(Z)
	if f and f.Parent then
		pcall(function()
			f.PlaneVelocity = Vector2.zero
			f.Enabled = false
			f:Destroy()
		end)
	end

	f = nil
	G = nil
	if Z then
		local f = Z:FindFirstChild("VampireWalkLinearVelocity")
		if f then
			pcall(function()
				f.Enabled = false
				f:Destroy()
			end)
		end
	end
end

local f = setmetatable({}, { __mode = "k" })
local function G(Z, E, r)
	local c = os.clock()
	local L = f[Z]
	if L and c < L.expires then
		local y = L.desired.Magnitude
		local d = E.Magnitude
		local Qt = math.abs(y - d) < 4
		local ft = y < 0.01 or d < 0.01 or L.desired.Unit:Dot(E.Unit) > 0.985
		if Qt and ft then
			return L.safe
		end
	end

	local L = math.min(r, W._AUTO_WALK_COLLISION_INTERVAL)
	P(Z, L)
	local r = n1(Z, E, L)
	f[Z] = { desired = E, safe = r, expires = c + W._AUTO_WALK_COLLISION_INTERVAL }
	return r
end

local f = {}
f.__index = f
function f.new(Z, E)
	local r = setmetatable({}, f)
	r.waypoints = table.clone(Z)
	r.name = E or "path"
	r.active = false
	r.index = 1
	r.useCarry = false
	r.pauseTime = 0
	r.connection = nil
	r.onComplete = nil
	r.updateAccumulator = 0
	return r
end

function f:start()
	if self.active then
		return
	end

	if #self.waypoints == 0 then
		return
	end

	self.active = true
	self.index = 1
	self.useCarry = false
	self.pauseTime = 0
	self.connection = pt.RenderStepped:Connect(function(Z)
		if not self.active then
			return
		end

		self.updateAccumulator = self.updateAccumulator + Z
		if self.updateAccumulator < W._AUTO_WALK_UPDATE_INTERVAL then
			return
		end

		Z = self.updateAccumulator
		self.updateAccumulator = 0
		local E = Rt.Character
		if not E then
			self:stop()
			return
		end

		local r = E:FindFirstChild("HumanoidRootPart")
		if not r then
			return
		end

		if self.index > #self.waypoints then
			self:stop()
			if self.onComplete then
				self.onComplete()
			end

			return
		end

		local E = self.waypoints[self.index]
		local c = r.Position
		local L = (Vector3.new(E.X - c.X, 0, E.Z - c.Z)).Magnitude
		if L <= W.ARRIVAL_DISTANCE then
			if self.index == 2 then
				self.pauseTime = W.CHECKPOINT_3_WAIT
			end

			self.index = self.index + 1
			if self.index > 2 and not self.useCarry then
				self.useCarry = true
			end

			return
		end

		if self.pauseTime > 0 then
			self.pauseTime = self.pauseTime - Z
			local y = i(r)
			if y then
				y.PlaneVelocity = Vector2.zero
			end

			return
		end

		local y = (E - c) * Vector3.new(1, 0, 1)
		y = y.Unit
		local E = (self.useCarry or zt.speedToggled) and zt.carrySpeed or zt.normalSpeed
		local c = math.max(E, L / math.min(Z, 0.004166666666666667) * 0.8)
		local E = G(r, y * c, Z)
		local Z = i(r)
		if Z then
			Z.PlaneVelocity = Vector2.new(E.X, E.Z)
		end
	end)
end

function f:stop()
	self.active = false
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	self.index = 1
	self.useCarry = false
	self.pauseTime = 0
	self.updateAccumulator = 0
	local Z = Rt.Character
	if Z then
		local E = Z:FindFirstChild("HumanoidRootPart")
		if E then
			l(E)
			f1(E, "VampireBrake", Vector3.zero, 0.12)
			E.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local Z = f.new(s, "left")
Z.onComplete = function()
	zt.autoLeftEnabled = false
	if setAutoLeft then
		setAutoLeft(false)
	end

	if Bt and Bt.autoLeft then
		Bt.autoLeft.setOn(false)
	end

	k()
end

local s = f.new(n, "right")
s.onComplete = function()
	zt.autoRightEnabled = false
	if setAutoRight then
		setAutoRight(false)
	end

	if Bt and Bt.autoRight then
		Bt.autoRight.setOn(false)
	end

	k()
end

local function n(f, E, r)
	local c = nil
	local L = false
	local y = 0
	c = pt.RenderStepped:Connect(function(d)
		if L then
			if c then
				c:Disconnect()
			end

			return
		end

		y = y + d
		if y < W._AUTO_WALK_UPDATE_INTERVAL then
			return
		end

		d = y
		y = 0
		local y = Rt.Character
		if not y then
			if c then
				c:Disconnect()
			end

			return
		end

		local Qt = y:FindFirstChild("HumanoidRootPart")
		if not Qt then
			if c then
				c:Disconnect()
			end

			return
		end

		local y = Qt.Position
		local ft = (Vector3.new(f.X - y.X, 0, f.Z - y.Z)).Magnitude
		if ft <= W.ARRIVAL_DISTANCE then
			L = true
			if r then
				local r = i(Qt)
				if r then
					r.PlaneVelocity = Vector2.zero
				end
			else
				l(Qt)
				f1(Qt, "VampireBrake", Vector3.zero, 0.12)
				Qt.AssemblyAngularVelocity = Vector3.zero
			end

			if E then
				E()
			end

			if c then
				c:Disconnect()
			end

			return
		end

		local E = (f - y) * Vector3.new(1, 0, 1)
		E = E.Unit
		local f
		if zt.laggerMode == 2 then
			f = zt.burstCarrySpeed
		elseif zt.laggerMode == 1 then
			f = zt.burstNormalSpeed
		else
			f = zt.normalSpeed
		end

		local r = math.max(f, ft / math.min(d, 0.004166666666666667) * 0.8)
		local f = G(Qt, E * r, d)
		local G = i(Qt)
		if G then
			G.PlaneVelocity = Vector2.new(f.X, f.Z)
		end
	end)
	return c
end

local f = nil
local G = nil
local i = 1
local E = 1
W._savedWalkSpeed = nil
local function r()
	local c = Rt.Character
	local L = c and c:FindFirstChildOfClass("Humanoid")
	if L then
		if W._savedWalkSpeed == nil then
			W._savedWalkSpeed = L.WalkSpeed
		end

		L.WalkSpeed = 0
	end
end

local function c()
	local L = Rt.Character
	local y = L and L:FindFirstChildOfClass("Humanoid")
	if y and W._savedWalkSpeed ~= nil then
		y.WalkSpeed = W._savedWalkSpeed
	end

	W._savedWalkSpeed = nil
end

startAutoLeft = function(L)
	if zt.countdownSafetyActive then
		return
	end

	if not L and isHoldingBrainrot and isHoldingBrainrot() then
		if zt.dropBrainrotMode then
			if runDropBrainrot then
				pcall(runDropBrainrot)
			end

			task.spawn(function()
				task.wait(0.22)
				if zt.autoLeftEnabled then
					startAutoLeft(true)
				end
			end)
			return
		end
	end

	r()
	p()
	if zt.autoPlayMode == "full" then
		oldStopAutoLeft()
		if zt.autoRightEnabled then
			zt.autoRightEnabled = false
			if setAutoRight then
				setAutoRight(false)
			end

			if Bt and Bt.autoRight then
				Bt.autoRight.setOn(false)
			end

			stopAutoRight()
		end

		Z:start()
		return
	end

	if f then
		return
	end

	i = 1
	local function L()
		if f then
			f:Disconnect()
			f = nil
		end

		zt.autoLeftEnabled = false
		i = 1
		if setAutoLeft then
			setAutoLeft(false)
		end

		if Bt and Bt.autoLeft then
			Bt.autoLeft.setOn(false)
		end

		local y = Rt.Character
		if y then
			local d = y:FindFirstChild("HumanoidRootPart")
			if d then
				l(d)
				f1(d, "VampireBrake", Vector3.zero, 0.12)
				d.AssemblyAngularVelocity = Vector3.zero
			end
		end

		k()
	end

	local function y()
		f = n(Vector3.new(W1.L1.X, 0, W1.L1.Z), function()
			i = 2
			if f then
				f:Disconnect()
			end

			f = n(Vector3.new(W1.L2.X, 0, W1.L2.Z), function()
				L()
			end)
		end, true)
	end

	y()
end

stopAutoLeft = function()
	if zt.autoPlayMode == "full" then
		Z:stop()
	else
		if f then
			f:Disconnect()
			f = nil
		end

		zt.autoLeftEnabled = false
		i = 1
		local f = Rt.Character
		if f then
			local i = f:FindFirstChild("HumanoidRootPart")
			if i then
				l(i)
				f1(i, "VampireBrake", Vector3.zero, 0.12)
				i.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end

	if not zt.autoRightEnabled then
		c()
		k()
	end
end

startAutoRight = function(f)
	if zt.countdownSafetyActive then
		return
	end

	if not f and isHoldingBrainrot and isHoldingBrainrot() then
		if zt.dropBrainrotMode then
			if runDropBrainrot then
				pcall(runDropBrainrot)
			end

			task.spawn(function()
				task.wait(0.22)
				if zt.autoRightEnabled then
					startAutoRight(true)
				end
			end)
			return
		end
	end

	r()
	p()
	if zt.autoPlayMode == "full" then
		oldStopAutoRight()
		if zt.autoLeftEnabled then
			zt.autoLeftEnabled = false
			if setAutoLeft then
				setAutoLeft(false)
			end

			if Bt and Bt.autoLeft then
				Bt.autoLeft.setOn(false)
			end

			stopAutoLeft()
		end

		s:start()
		return
	end

	if G then
		return
	end

	E = 1
	local function f()
		if G then
			G:Disconnect()
			G = nil
		end

		zt.autoRightEnabled = false
		E = 1
		if setAutoRight then
			setAutoRight(false)
		end

		if Bt and Bt.autoRight then
			Bt.autoRight.setOn(false)
		end

		local i = Rt.Character
		if i then
			local p = i:FindFirstChild("HumanoidRootPart")
			if p then
				l(p)
				f1(p, "VampireBrake", Vector3.zero, 0.12)
				p.AssemblyAngularVelocity = Vector3.zero
			end
		end

		k()
	end

	local function i()
		G = n(Vector3.new(W1.R1.X, 0, W1.R1.Z), function()
			E = 2
			if G then
				G:Disconnect()
			end

			G = n(Vector3.new(W1.R2.X, 0, W1.R2.Z), function()
				f()
			end)
		end, true)
	end

	i()
end

stopAutoRight = function()
	if zt.autoPlayMode == "full" then
		s:stop()
	else
		if G then
			G:Disconnect()
			G = nil
		end

		zt.autoRightEnabled = false
		E = 1
		local s = Rt.Character
		if s then
			local n = s:FindFirstChild("HumanoidRootPart")
			if n then
				l(n)
				f1(n, "VampireBrake", Vector3.zero, 0.12)
				n.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end

	if not zt.autoLeftEnabled then
		c()
		k()
	end
end

oldStartAutoLeft = function() end

oldStopAutoLeft = function() end

oldStartAutoRight = function() end

oldStopAutoRight = function() end

do
	local s = { descConn = nil, lightCache = nil, terrainCache = nil, baseParts = {}, effectsDisabled = {} }
	local function n(f)
		pcall(function()
			if f:IsA("Model") then
				f.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
				f.ModelStreamingMode = Enum.ModelStreamingMode.Nonatomic
			elseif f:IsA("MeshPart") then
				if s.baseParts[f] == nil then
					s.baseParts[f] = { Material = f.Material, Reflectance = f.Reflectance, CastShadow = f.CastShadow }
				end

				f.CastShadow = false
				f.DoubleSided = false
				f.RenderFidelity = Enum.RenderFidelity.Performance
			elseif f:IsA("BasePart") then
				if s.baseParts[f] == nil then
					s.baseParts[f] = { Material = f.Material, Reflectance = f.Reflectance, CastShadow = f.CastShadow }
				end

				f.CastShadow = false
				f.Material = Enum.Material.Plastic
				f.Reflectance = 0
			elseif
				f:IsA("Fire")
				or f:IsA("SpotLight")
				or f:IsA("Smoke")
				or f:IsA("Sparkles")
				or f:IsA("ParticleEmitter")
				or f:IsA("Trail")
				or f:IsA("Beam")
			then
				if f.Enabled then
					table.insert(s.effectsDisabled, f)
				end

				f.Enabled = false
			elseif f:IsA("Explosion") then
				f.BlastPressure = 1
				f.BlastRadius = 1
			elseif f:IsA("Attachment") then
				f.Visible = false
			end
		end)
	end

	applyFPSBoost = function()
		pcall(function()
			if _G._VH_uncapFps then
				_G._VH_uncapFps(999)
			end
		end)
		local f = workspace:GetDescendants()
		for G, i in ipairs(f) do
			n(i)
			if G % 180 == 0 then
				task.wait()
			end
		end

		f = nil
		pcall(function()
			local f = game:GetService("Lighting")
			if not s.lightCache then
				s.lightCache = { GlobalShadows = f.GlobalShadows, FogEnd = f.FogEnd, Brightness = f.Brightness }
			end

			for G, G in pairs(f:GetDescendants()) do
				pcall(function()
					if
						G:IsA("BloomEffect")
						or G:IsA("BlurEffect")
						or G:IsA("SunRaysEffect")
						or G:IsA("DepthOfFieldEffect")
						or G:IsA("ColorCorrectionEffect")
					then
						if G.Enabled then
							table.insert(s.effectsDisabled, G)
						end

						G.Enabled = false
					end
				end)
			end

			f.GlobalShadows = false
			f.FogEnd = 9000000000
			f.Brightness = 0
			local f = workspace:FindFirstChildOfClass("Terrain")
			if f then
				if not s.terrainCache then
					s.terrainCache = {
						WaterReflectance = f.WaterReflectance,
						WaterTransparency = f.WaterTransparency,
						WaterWaveSize = f.WaterWaveSize,
						WaterWaveSpeed = f.WaterWaveSpeed,
					}
				end

				f.WaterReflectance = 0
				f.WaterTransparency = 0.7
				f.WaterWaveSize = 0
				f.WaterWaveSpeed = 0
			end
		end)
		if s.descConn then
			s.descConn:Disconnect()
		end

		s.descConn = workspace.DescendantAdded:Connect(function(f)
			if zt.fpsBoostEnabled then
				task.spawn(n, f)
			end
		end)
	end

	disableFPSBoost = function()
		zt.fpsBoostEnabled = false
		if s.descConn then
			s.descConn:Disconnect()
			s.descConn = nil
		end

		for n, f in pairs(s.baseParts) do
			pcall(function()
				if n and n.Parent then
					n.Material = f.Material
					n.Reflectance = f.Reflectance
					n.CastShadow = f.CastShadow
				end
			end)
		end

		s.baseParts = {}
		for n, n in ipairs(s.effectsDisabled) do
			pcall(function()
				if n and n.Parent then
					n.Enabled = true
				end
			end)
		end

		s.effectsDisabled = {}
		pcall(function()
			local n = game:GetService("Lighting")
			if s.lightCache then
				n.GlobalShadows = s.lightCache.GlobalShadows
				n.FogEnd = s.lightCache.FogEnd
				n.Brightness = s.lightCache.Brightness
				s.lightCache = nil
			end

			local n = workspace:FindFirstChildOfClass("Terrain")
			if n and s.terrainCache then
				n.WaterReflectance = s.terrainCache.WaterReflectance
				n.WaterTransparency = s.terrainCache.WaterTransparency
				n.WaterWaveSize = s.terrainCache.WaterWaveSize
				n.WaterWaveSpeed = s.terrainCache.WaterWaveSpeed
				s.terrainCache = nil
			end
		end)
	end
end

_G.AceStealRadii = _G.AceStealRadii or { Normal = 62, Semi = 9 }
do
	_G.__AceSetupSemiAutoSteal = function()
		_G.AceSemiSteal = _G.AceSemiSteal or {}
		local s = _G.AceSemiSteal
		if s.conn then
			pcall(function()
				s.conn:Disconnect()
			end)
			s.conn = nil
		end

		s.enabled = false
		s.holdMin = 1.3
		s.holdMax = 2.6
		s.entryDelay = 0.3
		s.cooldown = 0.05
		s.primeRange = 80
		s.radius = tonumber(_G.AceStealRadii and _G.AceStealRadii.Semi) or 9
		s.conn = s.conn
		s.scanThread = s.scanThread
		s.plotSync = s.plotSync or { caches = {}, connections = {} }
		s.animals = s.animals or {}
		s.promptCache = s.promptCache or {}
		s.internalCache = s.internalCache or {}
		s.state = s.state
			or { active = false, startTime = 0, phase = "idle", label = "", lastResult = "", lastResultTime = 0 }
		local function n(f, G)
			pcall(function()
				if _G.StealBar then
					_G.StealBar.SetState(G or "STEALING")
					_G.StealBar.SetProgress(math.clamp(tonumber(f) or 0, 0, 1))
				end
			end)
		end

		local function f()
			pcall(function()
				if _G.StealBar then
					_G.StealBar.Reset()
				end
			end)
		end

		local function G()
			local i = Rt.Character
			return i and (i:FindFirstChild("HumanoidRootPart") or i:FindFirstChild("UpperTorso")) or nil
		end

		local function i(p)
			if typeof(p) == "table" then
				return p
			end

			local k = {}
			for l in string.gmatch(tostring(p), "[^%.]+") do
				table.insert(k, tonumber(l) or l)
			end

			return k
		end

		local function p(k, l)
			local Z, E, r = l, nil, nil
			for l, l in ipairs(i(k)) do
				E = Z
				r = l
				Z = Z and Z[l] or nil
			end

			return Z, E, r
		end

		local function i(k, l)
			local Z = s.plotSync.caches[k]
			if typeof(Z) ~= "table" then
				return
			end

			local k, E, r, c = l[1], l[2], l[3], l[4]
			local l, L, y = p(k, Z)
			if E == "Changed" then
				if L ~= nil then
					L[y] = r
				end
			elseif E == "ArrayInsert" then
				if l ~= nil then
					table.insert(l, c, r)
				end
			elseif E == "ArrayRemoved" then
				if l ~= nil then
					UDim2.fromScale(l, c)
				end
			elseif E == "DictionaryInsert" then
				if l ~= nil then
					l[c] = r
				end
			elseif E == "DictionaryRemoved" then
				if l ~= nil then
					l[c] = nil
				end
			end
		end

		local function p(k, l, Z)
			if s.plotSync.connections[k] then
				return
			end

			local E = tostring(k.Name)
			if not l:FindFirstChild(E) then
				return
			end

			if Z and s.plotSync.caches[E] == nil then
				local l, r = pcall(function()
					return Z:InvokeServer(E)
				end)
				s.plotSync.caches[E] = l and typeof(r) == "table" and r or {}
			elseif s.plotSync.caches[E] == nil then
				s.plotSync.caches[E] = {}
			end

			s.plotSync.connections[k] = k.OnClientEvent:Connect(function(k)
				for l, l in ipairs(k) do
					i(E, l)
				end
			end)
		end

		local function i()
			if s.syncReady then
				return true
			end

			local k = pcall(function()
				local l = game:GetService("ReplicatedStorage")
				s.packages = l:WaitForChild("Packages", 10)
				s.datas = l:WaitForChild("Datas", 10)
				s.plots = workspace:WaitForChild("Plots", 10)
				if not (s.packages and s.datas and s.plots) then
					return
				end

				s.animalsData = require(s.datas:WaitForChild("Animals", 10))
				local l = s.packages:WaitForChild("Synchronizer", 10)
				s.channelFolder = l:WaitForChild("Channel", 10)
				s.routeRemote = l:WaitForChild("CommunicationRoute", 10)
				s.requestData = l:FindFirstChild("RequestData")
				for l, l in ipairs(s.channelFolder:GetChildren()) do
					if l:IsA("RemoteEvent") then
						p(l, s.plots, s.requestData)
					end
				end

				s.channelFolder.ChildAdded:Connect(function(l)
					if l:IsA("RemoteEvent") then
						p(l, s.plots, s.requestData)
					end
				end)
				s.routeRemote.OnClientEvent:Connect(function(l)
					for Z, Z in ipairs(l) do
						local l, E = Z[1], tostring(Z[2])
						if s.plots and s.plots:FindFirstChild(E) then
							if l == "ListenerAdded" then
								local Z = s.channelFolder and s.channelFolder:FindFirstChild(E)
								if Z and Z:IsA("RemoteEvent") then
									p(Z, s.plots, s.requestData)
								end
							elseif l == "ListenerRemoved" then
								for p, l in pairs(s.plotSync.connections) do
									if tostring(p.Name) == E then
										pcall(function()
											l:Disconnect()
										end)
										s.plotSync.connections[p] = nil
										s.plotSync.caches[E] = nil
										break
									end
								end
							end
						end
					end
				end)
				s.syncReady = true
			end)
			return k and s.syncReady == true
		end

		local function p(k)
			if not k or not k.plot or not s.plots then
				return false
			end

			local l = s.plots:FindFirstChild(k.plot)
			if not l then
				return false
			end

			local k = l:FindFirstChild("PlotSign")
			local l = k and k:FindFirstChild("YourBase")
			return l and l:IsA("BillboardGui") and l.Enabled == true
		end

		local function k(l)
			local Z = s.plots and s.plots:FindFirstChild(l.plot)
			local E = Z and Z:FindFirstChild("AnimalPodiums")
			return E and E:FindFirstChild(l.slot) or nil
		end

		local function l(Z)
			local E = k(Z)
			return E and E:GetPivot().Position or nil
		end

		local function Z(E)
			local r = G()
			local c = l(E)
			return r and c and (r.Position - c).Magnitude or math.huge
		end

		local function E(r)
			if not r then
				return nil
			end

			local c = s.promptCache[r.uid]
			if c and c.Parent then
				return c
			end

			local c = k(r)
			local k = c and c:FindFirstChild("Base")
			local c = k and k:FindFirstChild("Spawn")
			local k = c and c:FindFirstChild("PromptAttachment")
			if not k then
				return nil
			end

			for c, c in ipairs(k:GetChildren()) do
				if c:IsA("ProximityPrompt") then
					s.promptCache[r.uid] = c
					return c
				end
			end

			return nil
		end

		local function k()
			if not i() then
				return 0
			end

			local r = {}
			for c, c in ipairs(s.plots:GetChildren()) do
				local L = s.plotSync.caches[c.Name]
				local y = L and L.AnimalList
				if typeof(y) == "table" then
					for L, d in pairs(y) do
						if type(d) == "table" then
							local y = d.Index
							local d = s.animalsData and s.animalsData[y]
							if d then
								table.insert(r, {
									name = d.DisplayName or y,
									plot = c.Name,
									slot = tostring(L),
									uid = c.Name .. "_" .. tostring(L),
								})
							end
						end
					end
				end
			end

			s.animals = r
			return #r
		end

		local function r()
			local c = G()
			if not c then
				return nil
			end

			local G, L = nil, math.huge
			for y, y in ipairs(s.animals) do
				if not p(y) then
					local p = l(y)
					local l = p and (c.Position - p).Magnitude or math.huge
					if l <= (s.primeRange or 80) and l < L then
						G, L = y, l
					end
				end
			end

			return G
		end

		local function G(p)
			if s.internalCache[p] then
				return
			end

			local l = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
			local c, L = pcall(getconnections, p.PromptButtonHoldBegan)
			if c and type(L) == "table" then
				for c, c in ipairs(L) do
					if type(c.Function) == "function" then
						table.insert(l.holdCallbacks, c.Function)
					end
				end
			end

			local c, L = pcall(getconnections, p.Triggered)
			if c and type(L) == "table" then
				for c, c in ipairs(L) do
					if type(c.Function) == "function" then
						table.insert(l.triggerCallbacks, c.Function)
					end
				end
			end

			if #l.holdCallbacks > 0 or #l.triggerCallbacks > 0 then
				s.internalCache[p] = l
			end
		end

		local function p(l, c)
			if tick() < zt.stealPausedUntil then
				return false
			end

			if not l or not l.Parent or not c then
				return false
			end

			G(l)
			local G = s.internalCache[l]
			if not G or not G.ready then
				return false
			end

			G.ready = false
			s.state.active = true
			s.state.startTime = tick()
			s.state.phase = "holding"
			s.state.label = c.name or "Animal"
			task.spawn(function()
				local L = s.state.startTime
				for y, y in ipairs(G.holdCallbacks) do
					task.spawn(function()
						pcall(y)
					end)
				end

				while
					s.enabled
					and s.run == true
					and tick() >= zt.stealPausedUntil
					and tick() - L < (s.holdMin or 1.3)
				do
					n((tick() - L) / (s.holdMax or 2.6), "STEALING")
					task.wait()
				end

				s.state.phase = "waitingRange"
				local y = Z(c) <= (tonumber(s.radius) or 10)
				local d = false
				while s.enabled and s.run == true and tick() >= zt.stealPausedUntil and l.Parent do
					local l = tick() - L
					if l > (s.holdMax or 2.6) then
						break
					end

					n(l / (s.holdMax or 2.6), "STEALING")
					if Z(c) <= (tonumber(s.radius) or 10) then
						if not y then
							task.wait(s.entryDelay or 0.3)
						end

						if s.enabled and s.run == true then
							for l, l in ipairs(G.triggerCallbacks) do
								task.spawn(function()
									pcall(l)
								end)
							end

							pcall(function()
								if _G.AutoCarrySpeed and _G.AutoCarrySpeed.WatchPickup then
									_G.AutoCarrySpeed.WatchPickup(1.25)
								end
							end)
							d = true
						end

						break
					end

					task.wait()
				end

				s.state.lastResult = d and "Stole " .. tostring(s.state.label)
					or "Missed window: " .. tostring(s.state.label)
				s.state.active = false
				s.state.phase = "idle"
				s.state.lastResultTime = tick()
				if d then
					n(1, "STEALING")
				end

				task.wait(s.cooldown or 0.05)
				G.ready = true
				f()
			end)
			return true
		end

		local function n()
			if s.scanThread then
				return
			end

			s.scanThread = task.spawn(function()
				while _G.AceSemiSteal do
					if s.enabled or s.run == true then
						pcall(k)
					end

					task.wait(5)
				end
			end)
		end

		_G.AceSemiAutoStealSetRadius = function(G)
			local l = tonumber(G)
			if l then
				s.radius = l
			end
		end

		_G.AceSemiAutoStealStop = function()
			s.run = false
			s.enabled = false
			if s.conn then
				s.conn:Disconnect()
				s.conn = nil
			end

			s.state.active = false
			s.state.phase = "idle"
			f()
		end

		_G._VH_abortSteal = function()
			pcall(function()
				s.state.active = false
				s.state.phase = "idle"
				for G, G in pairs(s.internalCache or {}) do
					if type(G) == "table" then
						G.ready = true
					end
				end

				f()
			end)
			pcall(function()
				if StealState then
					StealState.active = false
					StealState.phase = "idle"
				end
			end)
		end

		_G.AceSemiAutoStealStart = function()
			s.run = true
			s.radius = tonumber(_G.AceStealRadii and _G.AceStealRadii.Semi) or s.radius or 9
			s.enabled = true
			i()
			n()
			pcall(k)
			if s.conn then
				s.conn:Disconnect()
				s.conn = nil
			end

			s.conn = game:GetService("RunService").Heartbeat:Connect(function()
				if not s.enabled then
					return
				end

				if s.run ~= true then
					_G.AceSemiAutoStealStop()
					return
				end

				if s.state.active then
					return
				end

				if tick() < zt.stealPausedUntil then
					return
				end

				local n = r()
				if not n then
					return
				end

				local f = E(n)
				if f then
					p(f, n)
				end
			end)
		end

		_G.AceSemiAutoStealSync = function()
			if s.run == true and yt.AutoStealEnabled then
				_G.AceSemiAutoStealStart()
			else
				_G.AceSemiAutoStealStop()
			end
		end
	end

	_G.__AceSetupSemiAutoSteal()
end

do
	local s = game:GetService("ReplicatedStorage")
	local n = {}
	local f = workspace:FindFirstChild("Plots") or workspace:WaitForChild("Plots", 10)
	local G = nil
	local i = { caches = {}, connections = {} }
	local p = false
	pcall(function()
		local k = s:WaitForChild("Packages", 10)
		local l = s:WaitForChild("Datas", 10)
		if l then
			local Z = l:FindFirstChild("Animals")
			if Z then
				n = require(Z)
			end
		end

		if k then
			local l = k:FindFirstChild("Synchronizer")
			if l then
				G = {
					channelFolder = l:WaitForChild("Channel", 10),
					routeRemote = l:WaitForChild("CommunicationRoute", 10),
					requestData = l:FindFirstChild("RequestData"),
				}
				if G.channelFolder and G.routeRemote then
					p = true
				end
			end
		end
	end)
	local function k(l)
		if typeof(l) == "table" then
			return l
		end

		local Z = {}
		for E in string.gmatch(tostring(l), "[^%.]+") do
			table.insert(Z, tonumber(E) or E)
		end

		return Z
	end

	local function l(Z, E)
		local r, c, L = E, nil, nil
		for E, E in ipairs(k(Z)) do
			c = r
			L = E
			r = r and r[E] or nil
		end

		return r, c, L
	end

	local function k(Z, E)
		local r = i.caches[Z]
		if typeof(r) ~= "table" then
			return
		end

		local Z, c, L, y = E[1], E[2], E[3], E[4]
		local E, d, Qt = l(Z, r)
		if c == "Changed" then
			if d ~= nil then
				d[Qt] = L
			end
		elseif c == "ArrayInsert" then
			if E ~= nil then
				table.insert(E, y, L)
			end
		elseif c == "ArrayRemoved" then
			if E ~= nil then
				UDim2.fromScale(E, y)
			end
		elseif c == "DictionaryInsert" then
			if E ~= nil then
				E[y] = L
			end
		elseif c == "DictionaryRemoved" then
			if E ~= nil then
				E[y] = nil
			end
		end
	end

	local function l(Z)
		if i.connections[Z] then
			return
		end

		local E = tostring(Z.Name)
		if not f:FindFirstChild(E) then
			return
		end

		if G.requestData and i.caches[E] == nil then
			local r, c = pcall(function()
				return G.requestData:InvokeServer(E)
			end)
			i.caches[E] = r and typeof(c) == "table" and c or {}
		elseif i.caches[E] == nil then
			i.caches[E] = {}
		end

		i.connections[Z] = Z.OnClientEvent:Connect(function(Z)
			for r, r in ipairs(Z) do
				k(E, r)
			end
		end)
	end

	local function k(Z)
		for E, r in pairs(i.connections) do
			if tostring(E.Name) == tostring(Z) then
				r:Disconnect()
				i.connections[E] = nil
				i.caches[tostring(Z)] = nil
				break
			end
		end
	end

	if p then
		for p, p in ipairs(G.channelFolder:GetChildren()) do
			if p:IsA("RemoteEvent") then
				l(p)
			end
		end

		G.channelFolder.ChildAdded:Connect(function(p)
			if p:IsA("RemoteEvent") then
				l(p)
			end
		end)
		G.routeRemote.OnClientEvent:Connect(function(p)
			for Z, Z in ipairs(p) do
				local p, E = Z[1], tostring(Z[2])
				if not f:FindFirstChild(E) then
					continue
				end

				if p == "ListenerAdded" then
					local Z = G.channelFolder:FindFirstChild(E)
					if Z and Z:IsA("RemoteEvent") then
						l(Z)
					end
				elseif p == "ListenerRemoved" then
					k(E)
				end
			end
		end)
	end

	local function G(p)
		return i.caches[p]
	end

	local i = {}
	local p = {}
	local k = {}
	local l = {
		active = false,
		startTime = 0,
		phase = "idle",
		label = "",
		lastResult = "",
		lastResultTime = 0,
		totalSteals = 0,
		failedSteals = 0,
	}
	local function Z(E)
		local r = E:FindFirstChild("PlotSign")
		local E = r and r:FindFirstChild("SurfaceGui") and r.SurfaceGui:FindFirstChild("Frame")
		local r = E and E:FindFirstChild("TextLabel")
		if not r or r.Text == "Empty Base" then
			return nil
		end

		return r.Text:gsub("'s [Bb]ase$", ""):gsub("%s+$", "")
	end

	local function E(E)
		if not E or not E.plot then
			return false
		end

		local r = f:FindFirstChild(E.plot)
		if not r then
			return false
		end

		return Z(r) == Rt.DisplayName
	end

	local function Z(E)
		local r = workspace.Plots:FindFirstChild(E.plot)
		if not r then
			return nil
		end

		local c = r:FindFirstChild("AnimalPodiums")
		if not c then
			return nil
		end

		local r = c:FindFirstChild(E.slot)
		if not r then
			return nil
		end

		return r:GetPivot().Position
	end

	local function E(r)
		local c = Rt.Character
		if not c then
			return math.huge
		end

		local L = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")
		if not L then
			return math.huge
		end

		local c = Z(r)
		return c and (L.Position - c).Magnitude or math.huge
	end

	local function Z(Z)
		if k[Z] then
			return
		end

		local r = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
		local c, L = pcall(getconnections, Z.PromptButtonHoldBegan)
		if c and type(L) == "table" then
			for c, c in ipairs(L) do
				if type(c.Function) == "function" then
					table.insert(r.holdCallbacks, c.Function)
				end
			end
		end

		local c, L = pcall(getconnections, Z.Triggered)
		if c and type(L) == "table" then
			for c, c in ipairs(L) do
				if type(c.Function) == "function" then
					table.insert(r.triggerCallbacks, c.Function)
				end
			end
		end

		if #r.holdCallbacks > 0 or #r.triggerCallbacks > 0 then
			k[Z] = r
		end
	end

	local function Z(Z, r)
		local c = k[Z]
		if not c or not c.ready then
			return false
		end

		c.ready = false
		local L = r.name or "Animal"
		l.active = true
		l.startTime = tick()
		l.phase = "holding"
		l.label = L
		task.spawn(function()
			for w, w in ipairs(c.holdCallbacks) do
				task.spawn(w)
			end

			task.wait(yt.StealDuration)
			l.phase = "waitingRange"
			local w = E(r) <= 9
			local y = false
			while true do
				if tick() - l.startTime > yt.StealDuration * 2 then
					break
				end

				if not Z.Parent then
					break
				end

				if E(r) <= 9 then
					if not w then
						task.wait(0.3)
					end

					for Z, Z in ipairs(c.triggerCallbacks) do
						task.spawn(Z)
					end

					y = true
					break
				end

				task.wait()
			end

			if y then
				l.totalSteals = l.totalSteals + 1
				l.lastResult = "Stole " .. L
			else
				l.failedSteals = l.failedSteals + 1
				l.lastResult = "Missed: " .. L
			end

			l.active = false
			l.phase = "idle"
			l.lastResultTime = tick()
			task.wait(0.05)
			c.ready = true
		end)
		return true
	end

	local function Z()
		local E = {}
		for r, r in ipairs(f:GetChildren()) do
			local f = G(r.Name)
			if not f then
				continue
			end

			local G = f.AnimalList
			if typeof(G) ~= "table" then
				continue
			end

			for f, c in pairs(G) do
				if type(c) == "table" then
					local G = n[c.Index]
					if not G then
						continue
					end

					table.insert(E, {
						name = G.DisplayName or c.Index,
						plot = r.Name,
						slot = tostring(f),
						uid = r.Name .. "_" .. tostring(f),
					})
				end
			end
		end

		i = E
	end

	local n = progressFill and progressFill:FindFirstChildOfClass("UIGradient")
	local function f(G, i)
		local E = zt.activeBgImg
		if E == "vampire" or E == "139546609567893" then
			local function r(c)
				local L = c.R * 0.299 + c.G * 0.587 + c.B * 0.114
				local c = math.min(0.48, L)
				return Color3.new(c, c, c)
			end

			G = r(G)
			i = r(i)
		elseif E == "golden" or E == "132372803152269" then
			local r = G.G > 0.5
			if r then
				G = Color3.fromRGB(255, 150, 30)
				i = Color3.fromRGB(215, 110, 15)
			else
				G = Color3.fromRGB(250, 210, 20)
				i = Color3.fromRGB(200, 160, 10)
			end
		elseif E == "forest" or E == "jungle" or E == "16948826915" or E == "102609114992392" then
			local r = G.G > 0.5
			if r then
				G = Color3.fromRGB(67, 139, 83)
				i = Color3.fromRGB(49, 115, 68)
			else
				G = Color3.fromRGB(60, 210, 90)
				i = Color3.fromRGB(30, 155, 55)
			end
		elseif E == "ocean" or E == "79809183056960" then
			local r = G.G > 0.5
			if r then
				G = Color3.fromRGB(139, 199, 255)
				i = Color3.fromRGB(111, 175, 255)
			else
				G = Color3.fromRGB(50, 130, 255)
				i = Color3.fromRGB(30, 90, 210)
			end
		elseif E == "79455822331118" or E == "8180153808" or E == "11761613059" then
			local r = G.G > 0.5
			if r then
				G = Color3.fromRGB(235, 235, 235)
				i = Color3.fromRGB(170, 170, 170)
			else
				G = Color3.fromRGB(150, 150, 150)
				i = Color3.fromRGB(95, 95, 95)
			end
		elseif E == "123540425987418" or E == "122195659108931" then
			local r = G.G > 0.5
			if r then
				G = Color3.fromRGB(210, 140, 255)
				i = Color3.fromRGB(165, 75, 235)
			else
				G = Color3.fromRGB(165, 75, 235)
				i = Color3.fromRGB(110, 40, 180)
			end
		elseif E == "6457947928" then
			local r = G.G > 0.5
			if r then
				G = Color3.fromRGB(205, 150, 95)
				i = Color3.fromRGB(155, 98, 55)
			else
				G = Color3.fromRGB(155, 98, 55)
				i = Color3.fromRGB(105, 62, 30)
			end
		elseif E == "14430330747" or E == "17256388271" then
			local E = G.G > 0.5
			if E then
				G = Color3.fromRGB(255, 145, 205)
				i = Color3.fromRGB(235, 85, 165)
			else
				G = Color3.fromRGB(235, 85, 165)
				i = Color3.fromRGB(180, 45, 120)
			end
		end

		G = _pbContrastColor(G)
		i = _pbContrastColor(i)
		progressFill.BackgroundColor3 = G
		if n then
			n.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, G), ColorSequenceKeypoint.new(1, i) })
		end
	end

	local n = nil
	local G = 0
	game:GetService("RunService").Heartbeat:Connect(function(i)
		if not progressFill or not progressPct then
			return
		end

		if zt.stealMode == "semi" then
			return
		end

		G = G + (i or 0)
		if G < 0.016666666666666666 then
			return
		end

		G = 0
		if zt.stealMode == "normal" or zt.stealMode == "normalv2" then
			if zt.isStealing and zt.stealStartTime then
				local G = zt.stealMode == "normalv2" and (zt.normalV2Progress or 0)
					or math.clamp((tick() - zt.stealStartTime) / math.min(yt.StealDuration, 0.01), 0, 1)
				_pbFill(G)
				progressPct.Text = math.floor(G * 100) .. "%"
				f(Color3.fromRGB(255, 80, 80), Color3.fromRGB(190, 25, 25))
				n = "active"
			elseif n ~= "idle" then
				_pbFill(0)
				progressPct.Text = ""
				n = "idle"
			end

			return
		end

		local G = l.active
		local i = l.lastResultTime > 0 and tick() - l.lastResultTime < 1.4
		if not G and not i then
			if n ~= "idle" then
				_pbFill(0)
				f(Color3.fromRGB(255, 80, 80), Color3.fromRGB(190, 25, 25))
				progressPct.Text = ""
				n = "idle"
			end

			return
		end

		n = "busy"
		if G then
			local n = (tick() - l.startTime) / math.min(yt.StealDuration, 0.01)
			local G
			if n <= 1 then
				G = n * 0.5
				f(Color3.fromRGB(255, 80, 80), Color3.fromRGB(190, 25, 25))
			else
				G = math.clamp(0.5 + (n - 1) * 0.5, 0.5, 1)
				f(Color3.fromRGB(245, 220, 195), Color3.fromRGB(220, 190, 160))
			end

			_pbFill(G)
			progressPct.Text = math.max(math.floor(n * 100), 100) .. "%"
		elseif i then
			_pbFill(1)
			local n = string.find(l.lastResult, "Stole") ~= nil
			if n then
				f(Color3.fromRGB(245, 220, 195), Color3.fromRGB(220, 190, 160))
			else
				f(Color3.fromRGB(255, 80, 80), Color3.fromRGB(190, 25, 25))
			end

			progressPct.Text = n and "Got it!" or "Missed"
		else
			_pbFill(0)
			f(Color3.fromRGB(255, 80, 80), Color3.fromRGB(190, 25, 25))
			progressPct.Text = ""
		end
	end)
	task.spawn(function()
		while task.wait(5) do
			Z()
		end
	end)
	Z()
	local function n(G)
		local i = tick()
		if yt.plotCache[G] and i - (yt.plotCacheTime[G] or 0) < W.PLOT_CACHE_DURATION then
			return yt.plotCache[G]
		end

		local Z = workspace:FindFirstChild("Plots")
		if not Z then
			yt.plotCache[G] = false
			yt.plotCacheTime[G] = i
			return false
		end

		local E = Z:FindFirstChild(G)
		if not E then
			yt.plotCache[G] = false
			yt.plotCacheTime[G] = i
			return false
		end

		local Z = E:FindFirstChild("PlotSign")
		if Z then
			local E = Z:FindFirstChild("YourBase")
			if E and E:IsA("BillboardGui") then
				local Z = E.Enabled == true
				yt.plotCache[G] = Z
				yt.plotCacheTime[G] = i
				return Z
			end
		end

		yt.plotCache[G] = false
		yt.plotCacheTime[G] = i
		return false
	end

	local function G()
		local i = Rt.Character
		if not i then
			return nil
		end

		local Z = i:FindFirstChild("HumanoidRootPart")
		if not Z then
			return nil
		end

		local i = tick()
		if i - yt.promptCacheTime < W.PROMPT_CACHE_REFRESH and #yt.cachedPrompts > 0 then
			local E, r = nil, math.huge
			for c, c in ipairs(yt.cachedPrompts) do
				if c.spawn then
					local L = (c.spawn.Position - Z.Position).Magnitude
					if L <= yt.StealRadius and L < r then
						E = c.prompt
						r = L
					end
				end
			end

			if E then
				return E
			end
		end

		yt.cachedPrompts = {}
		yt.promptCacheTime = i
		local i = workspace:FindFirstChild("Plots")
		if not i then
			return nil
		end

		local E, r = nil, math.huge
		for c, c in ipairs(i:GetChildren()) do
			if n(c.Name) then
				continue
			end

			local n = c:FindFirstChild("AnimalPodiums")
			if not n then
				continue
			end

			for i, i in ipairs(n:GetChildren()) do
				pcall(function()
					local n = i:FindFirstChild("Base")
					local i = n and n:FindFirstChild("Spawn")
					if i then
						local n = i:FindFirstChild("PromptAttachment")
						if n then
							for c, c in ipairs(n:GetChildren()) do
								if c:IsA("ProximityPrompt") then
									local n = (i.Position - Z.Position).Magnitude
									table.insert(yt.cachedPrompts, { prompt = c, spawn = i })
									if n <= yt.StealRadius and n < r then
										E = c
										r = n
									end

									break
								end
							end
						end
					end
				end)
			end
		end

		return E
	end

	local function n(i)
		if tick() < zt.stealPausedUntil then
			return
		end

		local Z = tick()
		if Z - zt.lastStealTick < W.STEAL_COOLDOWN then
			return
		end

		if zt.isStealing then
			return
		end

		if not yt.Data[i] then
			yt.Data[i] = { hold = {}, trigger = {}, ready = true }
			pcall(function()
				if getconnections then
					for E, E in ipairs(getconnections(i.PromptButtonHoldBegan)) do
						if E.Function then
							table.insert(yt.Data[i].hold, E.Function)
						end
					end

					for E, E in ipairs(getconnections(i.Triggered)) do
						if E.Function then
							table.insert(yt.Data[i].trigger, E.Function)
						end
					end
				else
					yt.Data[i].useFallback = true
				end
			end)
		end

		local E = yt.Data[i]
		if not E.ready then
			return
		end

		E.ready = false
		zt.isStealing = true
		zt.stealStartTime = Z
		zt.lastStealTick = Z
		if x1.progress then
			x1.progress:Disconnect()
		end

		local Z = 0
		x1.progress = game:GetService("RunService").Heartbeat:Connect(function(r)
			if not zt.isStealing then
				x1.progress:Disconnect()
				return
			end

			Z = Z + (r or 0)
			if Z < 0.016666666666666666 then
				return
			end

			Z = 0
			local Z = math.clamp((tick() - zt.stealStartTime) / math.min(yt.StealDuration, 0.01), 0, 1)
			if progressFill then
				_pbFill(Z)
			end

			if progressPct then
				progressPct.Text = math.floor(Z * 100) .. "%"
			end

			f(Color3.fromRGB(255, 80, 80), Color3.fromRGB(190, 25, 25))
		end)
		task.spawn(function()
			local f = false
			pcall(function()
				if not E.useFallback then
					for Z, Z in ipairs(E.hold) do
						task.spawn(Z)
					end

					task.wait(yt.StealDuration)
					for Z, Z in ipairs(E.trigger) do
						task.spawn(Z)
					end

					f = true
				end
			end)
			if not f and fireproximityprompt then
				pcall(function()
					fireproximityprompt(i)
					f = true
				end)
			end

			if not f then
				pcall(function()
					i:InputHoldBegin()
					task.wait(yt.StealDuration)
					i:InputHoldEnd()
				end)
			end

			if progressFill then
				_pbFill(1)
			end

			if progressPct then
				progressPct.Text = "100%"
			end

			task.wait(math.min(yt.StealDuration * 0.08, 0.08))
			if x1.progress then
				x1.progress:Disconnect()
			end

			if progressFill then
				_pbFill(0)
			end

			if progressPct then
				progressPct.Text = ""
			end

			task.wait(0.01)
			E.ready = true
			zt.isStealing = false
		end)
	end

	local function f(i)
		local Z = Rt.Character
		local E = Z and (Z:FindFirstChild("HumanoidRootPart") or Z:FindFirstChild("UpperTorso"))
		if not E or not i or not i.Parent then
			return math.huge
		end

		local Z = i.Parent.Parent
		if Z and Z:IsA("BasePart") then
			return (E.Position - Z.Position).Magnitude
		end

		return math.huge
	end

	local function i(Z)
		if tick() < zt.stealPausedUntil then
			return
		end

		local E = tick()
		if E - zt.lastStealTick < W.STEAL_COOLDOWN then
			return
		end

		if zt.isStealing then
			return
		end

		if not yt.Data[Z] then
			yt.Data[Z] = { hold = {}, trigger = {}, ready = true }
			pcall(function()
				if getconnections then
					for r, r in ipairs(getconnections(Z.PromptButtonHoldBegan)) do
						if r.Function then
							table.insert(yt.Data[Z].hold, r.Function)
						end
					end

					for r, r in ipairs(getconnections(Z.Triggered)) do
						if r.Function then
							table.insert(yt.Data[Z].trigger, r.Function)
						end
					end
				else
					yt.Data[Z].useFallback = true
				end
			end)
		end

		local r = yt.Data[Z]
		if not r.ready then
			return
		end

		r.ready = false
		zt.isStealing = true
		zt.stealStartTime = E
		zt.lastStealTick = E
		zt.normalV2Progress = 0
		task.spawn(function()
			local E = false
			local c = false
			local L = math.min(yt.StealDuration, 0.01)
			local w = math.clamp((tonumber(zt.normalV2StopAt) or 75) / 100, 0.75, 0.9)
			local y = L * w
			local d = L * (1 - w)
			pcall(function()
				if not r.useFallback then
					for Qt, Qt in ipairs(r.hold) do
						task.spawn(Qt)
					end
				else
					Z:InputHoldBegin()
				end

				c = true
			end)
			local Qt = tick()
			while yt.AutoStealEnabled and zt.stealMode == "normalv2" and Z.Parent and tick() - Qt < y do
				zt.normalV2Progress = math.clamp((tick() - Qt) / L, 0, w)
				game:GetService("RunService").Heartbeat:Wait()
			end

			zt.normalV2Progress = w
			local y = tick()
			while yt.AutoStealEnabled and zt.stealMode == "normalv2" and Z.Parent and f(Z) > 9 and tick() - y < 1.5 do
				game:GetService("RunService").Heartbeat:Wait()
			end

			if yt.AutoStealEnabled and zt.stealMode == "normalv2" and Z.Parent then
				local f = tick()
				while yt.AutoStealEnabled and zt.stealMode == "normalv2" and Z.Parent and tick() - f < d do
					zt.normalV2Progress = math.clamp(w + (tick() - f) / L, w, 1)
					game:GetService("RunService").Heartbeat:Wait()
				end

				if yt.AutoStealEnabled and zt.stealMode == "normalv2" and Z.Parent then
					pcall(function()
						if not r.useFallback then
							for f, f in ipairs(r.trigger) do
								task.spawn(f)
							end
						else
							Z:InputHoldEnd()
						end

						E = true
					end)
					if not E and fireproximityprompt then
						pcall(function()
							fireproximityprompt(Z)
							E = true
						end)
					end
				end
			end

			if not E and r.useFallback and c then
				pcall(function()
					Z:InputHoldEnd()
				end)
			end

			if E then
				zt.normalV2Progress = 1
				if progressFill then
					_pbFill(1)
				end

				if progressPct then
					progressPct.Text = "100%"
				end

				task.wait(math.min(L * 0.08, 0.08))
			end

			if progressFill then
				_pbFill(0)
			end

			if progressPct then
				progressPct.Text = ""
			end

			task.wait(0.01)
			r.ready = true
			zt.isStealing = false
			zt.normalV2Progress = nil
		end)
	end

	startAutoSteal = function()
		if x1.autoSteal then
			pcall(function()
				x1.autoSteal:Disconnect()
			end)
			x1.autoSteal = nil
		end

		yt.AutoStealEnabled = true
		if zt.stealMode == "normal" or zt.stealMode == "normalv2" then
			local f = 0
			x1.autoSteal = game:GetService("RunService").Heartbeat:Connect(function(Z)
				if not yt.AutoStealEnabled or zt.isStealing then
					return
				end

				f = f + (Z or 0)
				if f < (Q1 and 0.06 or 0.03) then
					return
				end

				f = 0
				if tick() < zt.stealPausedUntil then
					return
				end

				local f = G()
				if f then
					if zt.stealMode == "normalv2" then
						i(f)
					else
						n(f)
					end
				end
			end)
		else
			pcall(function()
				if _G.AceSemiAutoStealStart then
					_G.AceSemiAutoStealStart()
				end
			end)
			x1.autoSteal = s.Heartbeat:Connect(function() end)
		end
	end

	stopAutoSteal = function()
		pcall(function()
			if _G.AceSemiAutoStealStop then
				_G.AceSemiAutoStealStop()
			end
		end)
		if x1.autoSteal then
			x1.autoSteal:Disconnect()
			x1.autoSteal = nil
		end

		yt.AutoStealEnabled = false
		zt.isStealing = false
		zt.normalV2Progress = nil
		zt.lastStealTick = 0
		yt.plotCache = {}
		yt.plotCacheTime = {}
		yt.cachedPrompts = {}
		l.active = false
		l.phase = "idle"
		p = {}
		k = {}
		if progressFill then
			_pbFill(0)
		end

		if progressPct then
			progressPct.Text = ""
		end
	end
end

_scfg = function(s)
	local n = {
		normalSpeed = zt.normalSpeed,
		carrySpeed = zt.carrySpeed,
		burstNormalSpeed = zt.burstNormalSpeed,
		burstCarrySpeed = zt.burstCarrySpeed,
		bypassNormalSpeed = zt.bypassNormalSpeed,
		bypassCarrySpeed = zt.bypassCarrySpeed,
		laggerMode = zt.laggerMode,
		burstPreset = zt.burstPreset,
		autoBat = zt.autoBatToggled,
		autoBatVersion = zt.autoBatVersion,
		autoSwing = zt.autoSwingEnabled,
		batCounter = zt.batCounterEnabled,
		mirrorTPDownEnabled = zt.mirrorTPDownEnabled,
		disablePredictionAt180 = zt.disablePredictionAt180,
		instaGrab = yt.AutoStealEnabled,
		kickWarningEnabled = zt.kickWarningEnabled,
		jumpType = zt.jumpType,
		jumpPower = zt.jumpPower,
		antiRagdollEnabled = zt.antiRagdollEnabled,
		fpsBoost = zt.fpsBoostEnabled,
		antiLag = _G._VH_antiLag == true,
		medusaCounter = zt.medusaCounterEnabled,
		unwalkEnabled = zt.unwalkEnabled,
		headlessEnabled = zt.headlessEnabled,
		korbloxEnabled = zt.korbloxEnabled,
		animEnabled = zt.animEnabled,
		autoTpDown = zt.autoTpDownEnabled,
		tpDownHeight = zt.tpDownHeight,
		desyncAimbotEnabled = zt.desyncAimbotEnabled,
		desyncAimbotVersion = zt.desyncAimbotVersion,
		desyncStopAfterHit = zt.desyncStopAfterHit,
		antiDieEnabled = zt.antiDieEnabled,
		autoCarryOnGrab = zt.autoCarryOnGrab,
		autoCarryVersion = zt.autoCarryVersion,
		stretchRez = zt.stretchRezEnabled,
		stretchFOV = zt.stretchFOV,
		activeSky = zt.activeSky,
		activeBgImg = zt.activeBgImg,
		favoriteBackgrounds = zt.bgFavorites,
		autoBatSpeed = zt.autoBatSpeed,
		fov = zt.lockedFOV,
		dropType = zt.dropType,
		stealMode = zt.stealMode,
		normalV2StopAt = zt.normalV2StopAt,
		semiVersion = zt.semiVersion,
		normalRadius = yt.NormalRadius,
		normalDuration = yt.NormalDuration,
		semiRadius = yt.SemiRadius,
		semiDuration = yt.SemiDuration,
		autoBatKey = Lt.autoBat.Name,
		speedKey = Lt.speed.Name,
		autoLeftKey = Lt.autoLeft.Name,
		autoRightKey = Lt.autoRight.Name,
		dropBrainrotKey = Lt.dropBrainrot.Name,
		tpDownKey = Lt.tpDown.Name,
		guiHideKey = Lt.guiHide.Name,
		desyncAimbotKey = Lt.desyncAimbot.Name,
		antiDieKey = Lt.antiDie.Name,
		burstKey = Lt.burst.Name,
		laggerKey = Lt.lagger.Name,
		sideButtonsVisible = zt.sideButtonsVisible,
		guiScale = zt.guiScale,
		progressBarSize = zt.progressBarSize,
		showProgressBar = zt.showProgressBar,
		stopOnHitEnabled = zt.stopOnHitEnabled,
		showProgressFPS = zt.showProgressFPS,
		showProgressPing = zt.showProgressPing,
		showProgressLines = zt.showProgressLines,
		sideButtonPositions = zt.sideButtonPositions,
		sideButtonLayoutVersion = W.SIDE_BUTTON_LAYOUT_VERSION,
		sideButtonSizes = zt.sideButtonSizes,
		sideButtonScale = zt.sideButtonScale,
		sideButtonType = zt.sideButtonType,
		sideButtonLook = zt.sideButtonLook,
		sideButtonDragMode = zt.sideButtonDragModeSaved,
		sideButtonsLocked = zt.sideButtonsLocked,
		showButtonOutline = zt.showButtonOutline,
		hiddenSideButtons = zt.hiddenSideButtons,
		speedChangeMethod = zt.speedChangeMethodSaved,
		stealBarPos = zt.stealBarPos,
		safeModeEnabled = zt.safeModeEnabled,
		dropBrainrotMode = zt.dropBrainrotMode,
		stopOnCountdown = zt.stopOnCountdown,
		autoPlayMode = zt.autoPlayMode,
		showIntro = zt.introEnabled,
		lineEspEnabled = zt.lineEspEnabled,
		lineEspColor = zt.lineEspColor,
		espAuraEnabled = zt.espAuraEnabled,
		espLineEnabled = zt.espLineEnabled,
		espHitboxEnabled = zt.espHitboxEnabled,
		espSchema = 3,
		selectedAnim = zt.selectedAnim,
	}
	if zt.stealMode == "normal" or zt.stealMode == "normalv2" then
		n.normalRadius = yt.StealRadius
		n.normalDuration = yt.StealDuration
	else
		n.semiRadius = yt.StealRadius
		n.semiDuration = yt.StealDuration
	end

	local f
	local G = pcall(function()
		f = Ht:JSONEncode(n)
	end)
	local n = G and f and ht("VampireHubConfig.json", f) or false
	if s then
		return n
	end

	if n then
		local s = saveBtn.Text
		saveBtn.Text = "Saved!"
		task.wait(1.5)
		saveBtn.Text = s
	else
		saveBtn.Text = "Failed!"
		task.wait(1.5)
		saveBtn.Text = "Save Config"
	end
end

local function s()
	if not Dt("VampireHubConfig.json") then
		return
	end

	local n = lt("VampireHubConfig.json")
	if not n then
		return
	end

	local f, G = pcall(function()
		return Ht:JSONDecode(n)
	end)
	if not f or type(G) ~= "table" then
		return
	end

	if type(G.favoriteBackgrounds) == "table" then
		local n = {}
		for f, i in pairs(G.favoriteBackgrounds) do
			local p = type(f) == "number" and i or f
			local k = type(f) == "number" or i == true
			if k and type(p) == "string" then
				n[p] = true
			end
		end

		zt.bgFavorites = n
		if _G._VH_refreshBgFavorites then
			_G._VH_refreshBgFavorites(false)
		end
	end

	if type(G.guiScale) == "number" then
		zt.guiScale = math.clamp(G.guiScale, 0.5, 1.5)
		if type(_G._applyGUIScale) == "function" then
			_G._applyGUIScale()
		end

		if type(_G._applyGUIScaleLabel) == "function" then
			_G._applyGUIScaleLabel()
		end
	end

	if type(G.showProgressBar) == "boolean" then
		zt.showProgressBar = G.showProgressBar
	end

	if type(G.stopOnHitEnabled) == "boolean" then
		zt.stopOnHitEnabled = G.stopOnHitEnabled
	end

	if type(G.desyncStopAfterHit) == "boolean" then
		zt.desyncStopAfterHit = G.desyncStopAfterHit
	end

	if jt then
		jt(zt.desyncStopAfterHit)
	end

	if type(G.antiDieEnabled) == "boolean" then
		zt.antiDieEnabled = G.antiDieEnabled
	end

	if Kt.refresh then
		Kt.refresh()
	elseif zt.antiDieEnabled and Kt.start then
		Kt.start()
	elseif Kt.stop then
		Kt.stop()
	end

	if rt then
		rt(zt.stopOnHitEnabled)
	end

	if type(G.showProgressFPS) == "boolean" then
		zt.showProgressFPS = G.showProgressFPS
	end

	if type(G.showProgressPing) == "boolean" then
		zt.showProgressPing = G.showProgressPing
	end

	if type(G.showProgressLines) == "boolean" then
		zt.showProgressLines = G.showProgressLines
	end

	if vt then
		vt(zt.showProgressBar)
	end

	if qt then
		qt(zt.showProgressFPS)
	end

	if Zt then
		Zt(zt.showProgressPing)
	end

	Yt()
	if type(G.progressBarSize) == "number" then
		zt.progressBarSize = math.clamp(G.progressBarSize, 0.6, 1.4)
		if type(_G._applyProgressBarSize) == "function" then
			_G._applyProgressBarSize()
		end
	end

	if G.sideButtonType == "square" or G.sideButtonType == "circle" then
		zt.sideButtonType = G.sideButtonType
		if ct then
			ct(G.sideButtonType)
		end
	end

	if G.sideButtonLook == "black" or G.sideButtonLook == "clear" then
		zt.sideButtonLook = G.sideButtonLook
		if At then
			At(G.sideButtonLook, true)
		end

		if ut then
			ut(true)
		end
	end

	if G.sideButtonDragMode == "one" or G.sideButtonDragMode == "all" then
		zt.sideButtonDragModeSaved = G.sideButtonDragMode
		zt.sideButtonDragMode = G.sideButtonDragMode
		if Ut then
			Ut(G.sideButtonDragMode)
		end
	end

	if type(G.sideButtonScale) == "number" then
		zt.sideButtonScale = math.clamp(G.sideButtonScale, 0.5, 1.5)
		if type(_G._applySideButtonScale) == "function" then
			_G._applySideButtonScale()
		end
	end

	if type(G.sideButtonSizes) == "table" then
		zt.sideButtonSizes = {}
		for n, n in ipairs(Ot) do
			local f = G.sideButtonSizes[n.key]
			if type(f) == "table" then
				local i, p = St(n)
				local k = math.clamp(
					math.floor((tonumber(f.width) or i) + 0.5),
					W.SIDE_BUTTON_MIN_WIDTH,
					W.SIDE_BUTTON_MAX_WIDTH
				)
				local i = math.clamp(
					math.floor((tonumber(f.height) or p) + 0.5),
					W.SIDE_BUTTON_MIN_HEIGHT,
					W.SIDE_BUTTON_MAX_HEIGHT
				)
				zt.sideButtonSizes[n.key] = { width = k, height = i }
			end
		end

		for n, n in ipairs(Ot) do
			Xt(n.key)
		end

		if _G._VH_refreshMobileSizeUI then
			pcall(_G._VH_refreshMobileSizeUI)
		end
	end

	if G.sideButtonLayoutVersion == W.SIDE_BUTTON_LAYOUT_VERSION and type(G.sideButtonPositions) == "table" then
		zt.sideButtonPositions = G.sideButtonPositions
		for n, f in pairs(zt.sideButtonPositions) do
			local i = Bt[n]
			if i and i.frame then
				local n = {}
				for p in string.gmatch(f, "[^,]+") do
					table.insert(n, tonumber(p))
				end

				if #n == 4 then
					i.frame.Position = UDim2.new(n[1], n[2], n[3], n[4])
				end
			end
		end
	else
		zt.sideButtonPositions = {}
		for n, f in ipairs(Ot) do
			local i = Bt[f.key]
			if i and i.frame then
				i.frame.Position = sideDefaultPos(n)
			end
		end
	end

	if G.sideButtonsLocked ~= nil then
		zt.sideButtonsLocked = G.sideButtonsLocked
		if setLockButtons then
			setLockButtons(G.sideButtonsLocked)
		end
	end

	zt.showButtonOutline = false
	if ut then
		ut(true)
	end

	if type(G.hiddenSideButtons) == "table" then
		zt.hiddenSideButtons = G.hiddenSideButtons
		if _G._VH_mbSetVis then
			for n, n in ipairs(G.hiddenSideButtons) do
				if _G._VH_mbSetVis[n] then
					_G._VH_mbSetVis[n](false)
				end
			end
		end
	end

	if type(G.jumpPower) == "number" then
		zt.jumpPower = math.clamp(math.floor(G.jumpPower + 0.5), 45, 50)
		if jumpPowerBox then
			jumpPowerBox.Text = tostring(zt.jumpPower)
		end
	end

	if G.jumpType == "hold" or G.jumpType == "manual" then
		zt.jumpType = G.jumpType
	end

	if setJumpTypeUI then
		setJumpTypeUI(zt.jumpType)
	end

	if applyJumpPower then
		applyJumpPower()
	end

	if type(G.normalSpeed) == "number" then
		zt.normalSpeed = G.normalSpeed
		if normalBox then
			normalBox.Text = tostring(G.normalSpeed)
		end
	end

	if type(G.carrySpeed) == "number" then
		zt.carrySpeed = G.carrySpeed
		if carryBox then
			carryBox.Text = tostring(G.carrySpeed)
		end
	end

	if type(G.burstNormalSpeed) == "number" then
		zt.burstNormalSpeed = G.burstNormalSpeed
		if burstNormalBox then
			burstNormalBox.Text = tostring(G.burstNormalSpeed)
		end
	end

	if type(G.burstCarrySpeed) == "number" then
		zt.burstCarrySpeed = G.burstCarrySpeed
		if burstCarryBox then
			burstCarryBox.Text = tostring(G.burstCarrySpeed)
		end
	end

	if type(G.bypassNormalSpeed) == "number" then
		zt.bypassNormalSpeed = G.bypassNormalSpeed
		if bypassNormalBox then
			bypassNormalBox.Text = tostring(G.bypassNormalSpeed)
		end
	end

	if type(G.bypassCarrySpeed) == "number" then
		zt.bypassCarrySpeed = G.bypassCarrySpeed
		if bypassCarryBox then
			bypassCarryBox.Text = tostring(G.bypassCarrySpeed)
		end
	end

	if type(G.laggerMode) == "number" then
		zt.laggerMode = G.laggerMode
		if G.laggerMode ~= 0 and setLaggerMode then
			setLaggerMode(G.laggerMode)
		end
	end

	if G.burstPreset == "lagger" or G.burstPreset == "bypass" then
		zt.burstPreset = G.burstPreset
		if setBurstPreset then
			setBurstPreset(G.burstPreset)
		end
	end

	if G.autoBatKey and Enum.KeyCode[G.autoBatKey] then
		Lt.autoBat = Enum.KeyCode[G.autoBatKey]
		if autoBatKeyBtn then
			autoBatKeyBtn.Text = G.autoBatKey
		end
	end

	if G.speedKey and Enum.KeyCode[G.speedKey] then
		Lt.speed = Enum.KeyCode[G.speedKey]
		if speedKeyBtn then
			speedKeyBtn.Text = G.speedKey
		end
	end

	if G.autoLeftKey and Enum.KeyCode[G.autoLeftKey] then
		Lt.autoLeft = Enum.KeyCode[G.autoLeftKey]
		if autoLeftKeyBtn then
			autoLeftKeyBtn.Text = G.autoLeftKey
		end
	end

	if G.autoRightKey and Enum.KeyCode[G.autoRightKey] then
		Lt.autoRight = Enum.KeyCode[G.autoRightKey]
		if autoRightKeyBtn then
			autoRightKeyBtn.Text = G.autoRightKey
		end
	end

	if G.dropBrainrotKey and Enum.KeyCode[G.dropBrainrotKey] then
		Lt.dropBrainrot = Enum.KeyCode[G.dropBrainrotKey]
		if dropBrainrotKeyBtn then
			dropBrainrotKeyBtn.Text = G.dropBrainrotKey
		end
	end

	if G.tpDownKey and Enum.KeyCode[G.tpDownKey] then
		Lt.tpDown = Enum.KeyCode[G.tpDownKey]
		if tpDownKeyBtn then
			tpDownKeyBtn.Text = G.tpDownKey
		end
	end

	if G.guiHideKey and Enum.KeyCode[G.guiHideKey] then
		Lt.guiHide = Enum.KeyCode[G.guiHideKey]
		if guiHideKeyBtn then
			guiHideKeyBtn.Text = G.guiHideKey
		end
	end

	if G.desyncAimbotKey and Enum.KeyCode[G.desyncAimbotKey] then
		Lt.desyncAimbot = Enum.KeyCode[G.desyncAimbotKey]
		if desyncAimbotKeyBtn then
			desyncAimbotKeyBtn.Text = G.desyncAimbotKey
		end
	end

	if G.burstKey and Enum.KeyCode[G.burstKey] then
		Lt.burst = Enum.KeyCode[G.burstKey]
		if _bkb then
			_bkb.Text = G.burstKey
		end
	end

	if G.antiDieKey and Enum.KeyCode[G.antiDieKey] then
		Lt.antiDie = Enum.KeyCode[G.antiDieKey]
	end

	if Kt.keyButton then
		Kt.keyButton.Text = Lt.antiDie == Enum.KeyCode.Unknown and "None" or Lt.antiDie.Name
	end

	if G.laggerKey and Enum.KeyCode[G.laggerKey] then
		Lt.lagger = Enum.KeyCode[G.laggerKey]
		Lt.burst = Enum.KeyCode[G.laggerKey]
		if _lkb then
			_lkb.Text = G.laggerKey
		end
	end

	if type(G.autoBatSpeed) == "number" then
		zt.autoBatSpeed = G.autoBatSpeed
		if autoBatSpeedBox then
			autoBatSpeedBox.Text = tostring(G.autoBatSpeed)
		end
	end

	if type(G.tpDownHeight) == "number" and G.tpDownHeight >= 5 and G.tpDownHeight <= 200 then
		zt.tpDownHeight = G.tpDownHeight
		if autoTpHeightBox then
			autoTpHeightBox.Text = tostring(G.tpDownHeight)
		end
	end

	if type(G.fov) == "number" and G.fov >= 70 and G.fov <= 150 then
		zt.lockedFOV = G.fov
		pcall(function()
			workspace.CurrentCamera.FieldOfView = G.fov
		end)
		if fovBox then
			fovBox.Text = tostring(math.floor(G.fov))
		end
	end

	if G.dropType == "Stand Drop" or G.dropType == "Jump Drop" then
		zt.dropType = G.dropType
		if setDropType then
			setDropType(G.dropType)
		end
	end

	if type(G.normalRadius) == "number" then
		yt.NormalRadius = math.floor(G.normalRadius)
	end

	if type(G.normalDuration) == "number" and G.normalDuration >= 0.01 and G.normalDuration <= 5 then
		yt.NormalDuration = G.normalDuration
	end

	if type(G.semiRadius) == "number" then
		yt.SemiRadius = math.floor(G.semiRadius)
	end

	if type(G.semiDuration) == "number" and G.semiDuration >= 0.01 and G.semiDuration <= 5 then
		yt.SemiDuration = G.semiDuration
	end

	if type(G.grabRadius) == "number" then
		yt.NormalRadius = math.floor(G.grabRadius)
		yt.SemiRadius = math.floor(G.grabRadius)
	end

	if type(G.stealDuration) == "number" then
		yt.NormalDuration = G.stealDuration
		yt.SemiDuration = G.stealDuration
	end

	local n = tonumber(G.normalV2StopAt)
	if n == 75 or n == 80 or n == 85 or n == 90 then
		zt.normalV2StopAt = n
	end

	local n = (G.stealMode == "normal" or G.stealMode == "normalv2" or G.stealMode == "semi") and G.stealMode
		or zt.stealMode
	if setStealModeUI then
		setStealModeUI(n, true)
	else
		zt.stealMode = n
		if n == "normal" or n == "normalv2" then
			yt.StealRadius = yt.NormalRadius
			yt.StealDuration = yt.NormalDuration
		else
			yt.StealRadius = yt.SemiRadius
			yt.StealDuration = yt.SemiDuration
		end
	end

	zt.semiVersion = "v2"
	if refreshStealUI then
		refreshStealUI()
	end

	if G.antiRagdollEnabled then
		zt.antiRagdollEnabled = true
		if antiRagToggleSet then
			antiRagToggleSet(true)
		end

		startAntiRagdoll()
	end

	if G.instaGrab or G.autoStealEnabled then
		yt.AutoStealEnabled = true
		if setInstaGrab then
			setInstaGrab(true)
		end

		pcall(startAutoSteal)
	end

	if G.fpsBoost then
		zt.fpsBoostEnabled = true
		if setFps then
			setFps(true)
		end

		pcall(applyFPSBoost)
		pcall(enableAntiLag)
	end

	if G.medusaCounter then
		zt.medusaCounterEnabled = true
		if setMedusaCounter then
			setMedusaCounter(true)
		end

		setupMedusaCounter(Rt.Character)
	end

	if type(G.mirrorTPDownEnabled) == "boolean" then
		zt.mirrorTPDownEnabled = G.mirrorTPDownEnabled
		if et then
			et(zt.mirrorTPDownEnabled)
		end
	end

	if G.autoBat then
		zt.autoBatToggled = true
		if setAutoBat then
			setAutoBat(true)
		end

		startBatAimbot()
	end

	if G.autoBatVersion == "v1" or G.autoBatVersion == "v2" or G.autoBatVersion == "v3" then
		zt.autoBatVersion = G.autoBatVersion
		if setAimbotVersion then
			setAimbotVersion(G.autoBatVersion)
		end
	end

	if G.speedChangeMethod == "v1" or G.speedChangeMethod == "v2" then
		zt.speedChangeMethodSaved = G.speedChangeMethod
		if setSpeedChangeMethod then
			setSpeedChangeMethod(G.speedChangeMethod)
		else
			zt.speedChangeMethod = G.speedChangeMethod
		end
	end

	if type(G.stealBarPos) == "string" then
		zt.stealBarPos = G.stealBarPos
		if Yt then
			Yt(true)
		end
	end

	if G.safeModeEnabled ~= nil then
		zt.safeModeEnabled = (G.safeModeEnabled == true)
		if setSafeMode then
			setSafeMode(zt.safeModeEnabled)
		end
	end

	if G.dropBrainrotMode ~= nil then
		zt.dropBrainrotMode = (G.dropBrainrotMode == true)
		if setDropBrainrotMode then
			setDropBrainrotMode(zt.dropBrainrotMode)
		end
	end

	if G.stopOnCountdown ~= nil then
		zt.stopOnCountdown = (G.stopOnCountdown == true)
		if Tt then
			Tt(zt.stopOnCountdown)
		end
	end

	if G.desyncAimbotVersion == "v2" then
		zt.desyncAimbotVersion = "v2"
	else
		zt.desyncAimbotVersion = "v1"
	end

	if Nt then
		Nt(zt.desyncAimbotVersion)
	end

	if G.batCounter then
		zt.batCounterEnabled = true
		if setBatCounterVisual then
			setBatCounterVisual(true)
		end

		startBatCounter()
	end

	if type(G.autoSwing) == "boolean" then
		zt.autoSwingEnabled = G.autoSwing
		if setAutoSwingVisual then
			setAutoSwingVisual(G.autoSwing)
		end
	end

	if G.disablePredictionAt180 ~= nil then
		zt.disablePredictionAt180 = G.disablePredictionAt180
	end

	if G.autoTpDown then
		zt.autoTpDownEnabled = true
		if setAutoTpDown then
			setAutoTpDown(true)
		end

		startAutoTpDown()
	end

	if type(G.kickWarningEnabled) == "boolean" then
		zt.kickWarningEnabled = G.kickWarningEnabled
		if _G._VH_setKickWarning then
			_G._VH_setKickWarning(G.kickWarningEnabled)
		end
	end

	if G.autoCarryVersion == "v1" or G.autoCarryVersion == "v2" then
		zt.autoCarryVersion = G.autoCarryVersion
	else
		zt.autoCarryVersion = "v2"
	end

	if _G._VH_setAutoCarryVersionUI then
		_G._VH_setAutoCarryVersionUI(zt.autoCarryVersion)
	end

	if G.desyncAimbotEnabled then
		zt.desyncAimbotEnabled = true
		if setDesyncAimbot then
			setDesyncAimbot(true)
		end

		startDesyncAimbot()
	end

	if G.autoCarryOnGrab then
		zt.autoCarryOnGrab = true
		if setAutoCarryOnGrab then
			setAutoCarryOnGrab(true)
		end
	end

	if G.unwalkEnabled then
		if setUnwalkToggle then
			setUnwalkToggle(true)
		end

		task.spawn(function()
			task.wait(0.5)
			zt.unwalkEnabled = false
			startUnwalk()
		end)
	end

	if G.headlessEnabled then
		zt.headlessEnabled = true
		if setHeadlessToggle then
			setHeadlessToggle(true)
		end

		if applyHeadlessToChar then
			applyHeadlessToChar(Rt.Character, true)
		end
	end

	if G.korbloxEnabled then
		zt.korbloxEnabled = true
		if setKorbloxToggle then
			setKorbloxToggle(true)
		end

		if applyKorbloxToChar then
			applyKorbloxToChar(Rt.Character, true)
		end
	end

	if type(G.selectedAnim) == "string" and b1[G.selectedAnim] then
		setSelectedAnim(G.selectedAnim)
		if setAnimDropdown then
			setAnimDropdown(G.selectedAnim)
		end
	elseif G.selectedAnim == "None" then
		zt.selectedAnim = "None"
		if setAnimDropdown then
			setAnimDropdown("None")
		end
	end

	if type(G.stretchFOV) == "number" then
		zt.stretchFOV = G.stretchFOV
		if setStretchFOVVisual then
			setStretchFOVVisual(G.stretchFOV)
		end
	end

	if G.stretchRez then
		if setStretchRezVisual then
			setStretchRezVisual(true)
		end

		enableStretchRez()
	end

	if
		type(G.activeSky) == "string"
		and (G.activeSky == "default" or G.activeSky == "blue" or G.activeSky == "night" or G.activeSky == "day")
	then
		if applySky then
			applySky(G.activeSky)
		end
	end

	if type(G.activeBgImg) == "string" then
		local n = {
			original = "rbxassetid://14640607134",
			vampire = "rbxassetid://114138477258742",
			golden = "rbxassetid://113621109176868",
			forest = "rbxassetid://15108586724",
			jungle = "rbxassetid://11850170603",
			ocean = "rbxassetid://116893313684229",
			["79809183056960"] = "rbxassetid://79809183056960",
			["79455822331118"] = "rbxassetid://79455822331118",
			["16948826915"] = "rbxassetid://16948826915",
			["101793424727240"] = "rbxassetid://101793424727240",
			["123540425987418"] = "rbxassetid://123540425987418",
			["122195659108931"] = "rbxassetid://122195659108931",
			["6457947928"] = "rbxassetid://6457947928",
			["102609114992392"] = "rbxassetid://102609114992392",
			["8180153808"] = "rbxassetid://8180153808",
			["11761613059"] = "rbxassetid://11761613059",
			["139546609567893"] = "rbxassetid://139546609567893",
			["14430330747"] = "rbxassetid://14430330747",
			["17256388271"] = "rbxassetid://17256388271",
			["132372803152269"] = "rbxassetid://132372803152269",
		}
		local f = n[G.activeBgImg]
		if f then
			if girlImg then
				girlImg.Image = f
			end

			zt.activeBgImg = G.activeBgImg
			if setBgImgVisual then
				setBgImgVisual(G.activeBgImg)
			end
		end
	end

	if G.showIntro ~= nil then
		zt.introEnabled = G.showIntro
		if _G._VH_setIntroToggle then
			_G._VH_setIntroToggle(zt.introEnabled)
		end
	end

	if type(G.sideButtonsVisible) == "boolean" then
		zt.sideButtonsVisible = G.sideButtonsVisible
		if setSideToggle then
			setSideToggle(G.sideButtonsVisible)
		end

		if type(setSideVisible) == "function" then
			setSideVisible(G.sideButtonsVisible)
		end
	end

	if G.autoPlayMode == "normal" or G.autoPlayMode == "full" then
		zt.autoPlayMode = G.autoPlayMode
		if type(setAutoPlayModeUI) == "function" then
			setAutoPlayModeUI(G.autoPlayMode)
		end
	end

	if G.lineEspColor == "red" or G.lineEspColor == "white" then
		zt.lineEspColor = G.lineEspColor
		if lineEspColorBtn then
			if G.lineEspColor == "white" then
				lineEspColorBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
				lineEspColorBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
				lineEspColorBtn.Text = "WHITE"
			else
				lineEspColorBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
				lineEspColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				lineEspColorBtn.Text = "RED"
			end
		end
	end

	if G.lineEspEnabled == true then
		if setLineEsp then
			setLineEsp(true)
		end
	end

	if G.espSchema == 3 then
		if G.espAuraEnabled ~= nil then
			zt.espAuraEnabled = (G.espAuraEnabled == true)
		end

		if G.espLineEnabled ~= nil then
			zt.espLineEnabled = (G.espLineEnabled == true)
		end

		if G.espHitboxEnabled ~= nil then
			zt.espHitboxEnabled = (G.espHitboxEnabled == true)
		end
	else
		zt.espAuraEnabled = false
		zt.espLineEnabled = false
		zt.espHitboxEnabled = false
	end

	if _seA then
		_seA(zt.espAuraEnabled)
	end

	if _seL then
		_seL(zt.espLineEnabled)
	end

	if _seH then
		_seH(zt.espHitboxEnabled)
	end

	if _G._VH_setEspUI then
		pcall(_G._VH_setEspUI)
	end
end

function applyBillboardTheme()
	local n = zt.activeBgImg
	local f = n == "forest" or n == "jungle" or n == "16948826915" or n == "102609114992392"
	local G = n == "ocean" or n == "79809183056960"
	local i = n == "79455822331118" or n == "8180153808" or n == "11761613059"
	local p = n == "vampire" or n == "139546609567893"
	local k = n == "golden" or n == "132372803152269"
	local l = n == "123540425987418" or n == "122195659108931"
	local Z = n == "6457947928"
	local E = n == "14430330747" or n == "17256388271"
	local n = p and Color3.fromRGB(180, 180, 180)
		or k and Color3.fromRGB(235, 185, 20)
		or f and Color3.fromRGB(50, 195, 80)
		or G and Color3.fromRGB(50, 130, 255)
		or i and Color3.fromRGB(22, 22, 22)
		or l and Color3.fromRGB(165, 75, 235)
		or Z and Color3.fromRGB(155, 98, 55)
		or E and Color3.fromRGB(235, 85, 165)
		or Color3.fromRGB(220, 45, 45)
	local r = p and Color3.fromRGB(160, 160, 160)
		or k and Color3.fromRGB(255, 220, 70)
		or f and Color3.fromRGB(100, 230, 125)
		or G and Color3.fromRGB(100, 175, 255)
		or i and Color3.fromRGB(58, 58, 58)
		or l and Color3.fromRGB(210, 140, 255)
		or Z and Color3.fromRGB(205, 150, 95)
		or E and Color3.fromRGB(255, 145, 205)
		or Color3.fromRGB(255, 90, 90)
	pcall(function()
		if titleLbl and titleLbl.Parent then
			titleLbl.TextColor3 = n
		end

		if speedLbl and speedLbl.Parent then
			speedLbl.TextColor3 = r
		end
	end)
end

setupChar = function(n)
	task.wait(0.1)
	H1 = nil
	h = n:WaitForChild("Humanoid", 5)
	hrp = n:WaitForChild("HumanoidRootPart", 5)
	if not h then
		h = n:FindFirstChildOfClass("Humanoid")
	end

	if not hrp then
		hrp = n:FindFirstChild("HumanoidRootPart")
	end

	if h then
		zt.lastKnownHealth = h.Health
	end

	task.spawn(function()
		task.wait(0.5)
		local f = Rt.Character
		if not f or f ~= n then
			return
		end

		local G = f:WaitForChild("Head", 5)
		if not G then
			return
		end

		local f = G:FindFirstChild("SpeedBillboard")
		if f then
			f:Destroy()
		end

		local f = Instance.new("BillboardGui", G)
		f.Name = "SpeedBillboard"
		f.Size = UDim2.new(0, 220, 0, 58)
		f.StudsOffset = Vector3.new(0, 2.2, 0)
		f.AlwaysOnTop = true
		speedBB = f
		titleLbl = Instance.new("TextLabel", f)
		titleLbl.Size = UDim2.new(1, 0, 0.55, 0)
		titleLbl.Position = UDim2.new(0, 0, 0, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = "LEAKED BY /printed • #1"
		titleLbl.Font = Enum.Font.Gotham
		titleLbl.TextScaled = true
		titleLbl.TextTransparency = 0
		speedLbl = Instance.new("TextLabel", f)
		speedLbl.Size = UDim2.new(1, 0, 0.45, 0)
		speedLbl.Position = UDim2.new(0, 0, 0.55, 0)
		speedLbl.BackgroundTransparency = 1
		speedLbl.Font = Enum.Font.GothamBold
		speedLbl.TextScaled = true
		speedLbl.TextTransparency = 0
		local f
		if zt.laggerMode == 1 then
			f = zt.burstNormalSpeed
		elseif zt.laggerMode == 2 then
			f = zt.burstCarrySpeed
		else
			f = zt.speedToggled and zt.carrySpeed or zt.normalSpeed
		end

		speedLbl.Text = string.format("%.1f", f)
		applyBillboardTheme()
	end)
	if applyJumpPower then
		applyJumpPower()
	end

	if zt.antiRagdollEnabled then
		task.wait(0.5)
		startAntiRagdoll()
	end

	if zt.medusaCounterEnabled then
		setupMedusaCounter(n)
	end

	if zt.unwalkEnabled then
		zt.unwalkEnabled = false
		task.wait(0.3)
		startUnwalk()
	end

	if zt.selectedAnim ~= "None" then
		zt.animEnabled = false
		task.wait(0.3)
		setSelectedAnim(zt.selectedAnim)
	end

	if zt.autoBatToggled then
		local f = n:FindFirstChildOfClass("Humanoid")
		if f then
			f.AutoRotate = false
		end
	end

	if zt.holdInfJumpEnabled then
		stopHoldInfJump()
		task.wait(0.2)
		startHoldInfJump()
	end

	if type(setSideVisible) == "function" then
		setSideVisible(zt.sideButtonsVisible)
	end

	if zt.headlessEnabled or zt.korbloxEnabled then
		task.wait(0.2)
		if applyCharterToChar then
			applyCharterToChar(n)
		end
	end
end

do
	local n = lt("VampireHubConfig.json")
	if n then
		local f, G = pcall(function()
			return Ht:JSONDecode(n)
		end)
		if f and type(G) == "table" then
			if type(G.activeBgImg) == "string" then
				local n = {
					original = "rbxassetid://14640607134",
					vampire = "rbxassetid://114138477258742",
					golden = "rbxassetid://113621109176868",
					forest = "rbxassetid://15108586724",
					jungle = "rbxassetid://11850170603",
					ocean = "rbxassetid://116893313684229",
					["79809183056960"] = "rbxassetid://79809183056960",
					["79455822331118"] = "rbxassetid://79455822331118",
					["16948826915"] = "rbxassetid://16948826915",
					["101793424727240"] = "rbxassetid://101793424727240",
					["123540425987418"] = "rbxassetid://123540425987418",
					["122195659108931"] = "rbxassetid://122195659108931",
					["6457947928"] = "rbxassetid://6457947928",
					["102609114992392"] = "rbxassetid://102609114992392",
					["8180153808"] = "rbxassetid://8180153808",
					["11761613059"] = "rbxassetid://11761613059",
					["139546609567893"] = "rbxassetid://139546609567893",
					["14430330747"] = "rbxassetid://14430330747",
					["17256388271"] = "rbxassetid://17256388271",
					["132372803152269"] = "rbxassetid://132372803152269",
				}
				local f = n[G.activeBgImg]
				if f then
					if girlImg then
						girlImg.Image = f
					end

					zt.activeBgImg = G.activeBgImg
				end
			end

			if type(G.sideButtonsVisible) == "boolean" then
				zt.sideButtonsVisible = G.sideButtonsVisible
			end
		end
	end
end

gui.Enabled = true
root.Visible = true
root.Active = true
Yt()
Rt.CharacterAdded:Connect(setupChar)
if Rt.Character then
	task.spawn(function()
		setupChar(Rt.Character)
		s()
	end)
else
	s()
end

task.spawn(function()
	task.wait(0.35)
	if _VH_fixTextContrast then
		pcall(_VH_fixTextContrast)
	end
end)
task.spawn(function()
	task.wait(0.5)
	if setJumpTypeUI then
		setJumpTypeUI(zt.jumpType)
	end

	if applyJumpPower then
		applyJumpPower()
	end
end)
print("[VAMPIRE HUB] Loaded!")
do
	local function s(n)
		local f = n:FindFirstChildOfClass("Humanoid") or n:WaitForChild("Humanoid", 5)
		if not f then
			return
		end

		f.Died:Connect(function()
			_1(n)
		end)
	end

	if Rt.Character then
		s(Rt.Character)
	end

	Rt.CharacterAdded:Connect(function(n)
		task.wait(0.2)
		s(n)
	end)
end

do
	local s = false
	local n = false
	local f = nil
	local G = 0
	local i = 0
	local p = nil
	local k = 0
	local function l(Z, E)
		local r = Z
		while r and r ~= E do
			if r:IsA("GuiObject") and not r.Visible then
				return false
			end

			if r:IsA("LayerCollector") and not r.Enabled then
				return false
			end

			r = r.Parent
		end

		return r == E
	end

	local function Z()
		local E = Rt:FindFirstChildOfClass("PlayerGui")
		local r = workspace.CurrentCamera
		if not (E and r) then
			return nil
		end

		local c = r.ViewportSize
		if c.X <= 0 or c.Y <= 0 then
			return nil
		end

		local r, L = nil, 0
		for w, w in ipairs(E:GetDescendants()) do
			if
				(w:IsA("TextLabel") or w:IsA("TextButton"))
				and w.TextTransparency < 0.92
				and l(w, E)
				and (not gui or not w:IsDescendantOf(gui))
			then
				local l = w.Text or ""
				if w.RichText then
					l = l:gsub("<.->", "")
				end

				l = l:gsub("%s+", "")
				local E = tonumber(l)
				if E and E >= 1 and E <= 5 and E == math.floor(E) then
					local l = w.AbsoluteSize
					local y = w.AbsolutePosition
					local d = y + l * 0.5
					local y = w.TextBounds
					local Qt = w.TextSize >= 42 or y.Y >= 44 or l.Y >= 72 and l.X >= 38
					local st = math.abs(d.X - c.X * 0.5) <= c.X * 0.27 and math.abs(d.Y - c.Y * 0.5) <= c.Y * 0.3
					if Qt and st then
						local c = math.min(w.TextSize, y.Y, l.Y * 0.55)
						if c > L then
							L = c
							r = E
						end
					end
				end
			end
		end

		return r
	end

	local function l(E)
		if s == E then
			zt.countdownSafetyActive = E
			return
		end

		s = E
		zt.countdownSafetyActive = E
		if E then
			local E = zt.autoBatToggled == true
			local r = zt.desyncAimbotEnabled == true
			local c = zt.autoLeftEnabled == true
			local L = zt.autoRightEnabled == true
			if E and stopBatAimbot then
				stopBatAimbot()
			end

			if r and stopDesyncAimbot then
				stopDesyncAimbot()
			end

			if c and stopAutoLeft then
				stopAutoLeft()
			end

			if L and stopAutoRight then
				stopAutoRight()
			end

			zt.autoBatToggled = E
			zt.desyncAimbotEnabled = r
			zt.autoLeftEnabled = c
			zt.autoRightEnabled = L
			local E = Rt.Character
			local r = E and E:FindFirstChild("HumanoidRootPart")
			if r then
				pcall(function()
					r.AssemblyLinearVelocity = Vector3.zero
					r.AssemblyAngularVelocity = Vector3.zero
				end)
				f1(r, "VampireBrake", Vector3.zero, 0.18)
			end
		else
			task.spawn(function()
				if zt.countdownSafetyActive then
					return
				end

				if zt.autoLeftEnabled and startAutoLeft then
					startAutoLeft()
				elseif zt.autoRightEnabled and startAutoRight then
					startAutoRight()
				elseif zt.desyncAimbotEnabled and startDesyncAimbot then
					startDesyncAimbot()
				elseif zt.autoBatToggled and startBatAimbot then
					startBatAimbot()
				end
			end)
		end
	end

	pt.Heartbeat:Connect(function(E)
		k = k + (E or 0)
		if k < 0.03333333333333333 then
			return
		end

		k = 0
		local k = os.clock()
		if not zt.stopOnCountdown then
			if s then
				l(false)
			end

			n = false
			f = nil
			p = nil
			return
		end

		local E = Z()
		if E then
			i = k
			p = nil
			if E ~= f then
				f = E
				G = k
			end

			if not n and not s then
				l(true)
			end

			if s and E == 1 and k - G >= 0.82 then
				n = true
				l(false)
			end
		else
			p = p or k
			if s and k - i >= 0.12 then
				n = true
				l(false)
			end

			if k - p >= 0.25 then
				n = false
				f = nil
				G = 0
			end
		end
	end)
end

do
	if _G.VX7AntiCollision and type(_G.VX7AntiCollision.Destroy) == "function" then
		pcall(_G.VX7AntiCollision.Destroy)
	end

	_G.VX7AntiCollision = nil
	if _G.VHAlwaysOnAntiCollision then
		pcall(function()
			_G.VHAlwaysOnAntiCollision:Disconnect()
		end)
	end

	_G.VHSetAntiCollisionSuspended = nil
	local s = game:GetService("Players")
	local n = game:GetService("RunService")
	local f = s.LocalPlayer
	local G = zt.desyncAimbotEnabled == true
	local i = setmetatable({}, { __mode = "k" })
	local function p()
		for k, l in pairs(i) do
			if k and k.Parent then
				pcall(function()
					k.CanCollide = l
				end)
			end

			i[k] = nil
		end
	end

	local k = setmetatable({}, { __mode = "k" })
	local l = setmetatable({}, { __mode = "k" })
	local function Z(E)
		local r = k[E]
		if r then
			return r
		end

		r = {}
		for c, c in ipairs(E:GetChildren()) do
			if c:IsA("BasePart") then
				r[#r + 1] = c
			end
		end

		k[E] = r
		if not l[E] then
			l[E] = true
			E.ChildAdded:Connect(function()
				k[E] = nil
			end)
			E.ChildRemoved:Connect(function()
				k[E] = nil
			end)
		end

		return r
	end

	local function k()
		if G then
			return
		end

		for l, l in ipairs(s:GetPlayers()) do
			if l ~= f then
				local s = l.Character
				if s then
					for f, f in ipairs(Z(s)) do
						if f.Parent then
							if i[f] == nil then
								i[f] = f.CanCollide
							end

							if f.CanCollide then
								f.CanCollide = false
							end
						end
					end
				end
			end
		end
	end

	_G.VHSetAntiCollisionSuspended = function(s)
		G = s == true and zt.desyncAimbotEnabled == true
		if G then
			p()
		else
			k()
		end
	end

	_G.VHAlwaysOnAntiCollision = n.Stepped:Connect(function()
		k()
	end)
	if G then
		p()
	else
		k()
	end
end

do
	if type(_G.VHVoidGuardConnections) == "table" then
		for s, s in ipairs(_G.VHVoidGuardConnections) do
			pcall(function()
				s:Disconnect()
			end)
		end
	end

	local s = {}
	_G.VHVoidGuardConnections = s
	local function n(f)
		if f then
			s[#s + 1] = f
		end

		return f
	end

	local function s(f)
		local G = nil
		local i = nil
		local p
		local k = 0
		local l = 0
		local Z = nil
		local E = tick()
		local r = 0
		local c = 0
		local L = false
		local w = nil
		local y = Q1 and 0.1 or 0.06
		local d = RaycastParams.new()
		d.FilterType = Enum.RaycastFilterType.Exclude
		d.IgnoreWater = true
		pcall(function()
			d.RespectCanCollide = true
		end)
		local function Qt(st)
			local ft = st.Position
			local Ht = st.CFrame.LookVector
			local st = Vector3.new(Ht.X, 0, Ht.Z)
			return st.Magnitude > 0.01 and CFrame.lookAt(ft, ft + st.Unit) or CFrame.new(ft)
		end

		local function st(ft, Ht)
			d.FilterDescendantsInstances = { f }
			return workspace:Raycast(ft.Position, Vector3.new(0, -Ht, 0), d)
		end

		local function d(ft, Ht, Ft, It)
			if ft.Position.Y <= -30.0 or Ht.Health <= 0 then
				return false
			end

			if It - r >= y then
				local Ht = st(ft, 7.5)
				L = Ht ~= nil and Ht.Normal.Y >= 0.45
				r = It
			end

			if L then
				Ft = Ft or s1(ft)
				if math.abs(Ft.Y) <= 35 and Ft.Magnitude <= 100 and ft.AssemblyAngularVelocity.Magnitude <= 12 then
					G = Qt(ft)
					i = i or G
				end
			end

			return L
		end

		local function r(L, ft, Ht)
			local Ft = G or i
			if not Ft then
				return
			end

			k = Ht + 0.45
			L.AssemblyLinearVelocity = Vector3.zero
			L.AssemblyAngularVelocity = Vector3.zero
			L.CFrame = Ft + Vector3.new(0, 3.5, 0)
			f1(L, "VampireBrake", Vector3.zero, 0.45)
			pcall(function()
				ft:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
			Z = L.Position
			E = Ht
			task.spawn(function()
				pcall(function()
					Rt:RequestStreamAroundAsync(Ft.Position)
				end)
			end)
			task.spawn(function()
				for Ht = 1, 3 do
					pt.Heartbeat:Wait()
					if not (L and L.Parent and ft and ft.Parent and ft.Health > 0) then
						break
					end

					L.AssemblyLinearVelocity = Vector3.zero
					L.AssemblyAngularVelocity = Vector3.zero
				end
			end)
		end

		local function L()
			if not f.Parent then
				if p then
					p:Disconnect()
					p = nil
				end

				return
			end

			local ft = f:FindFirstChild("HumanoidRootPart")
			local Ht = f:FindFirstChildOfClass("Humanoid")
			if not ft or not Ht or Ht.Health <= 0 then
				return
			end

			local Ft = tick()
			local It = ft.Position
			local kt = s1(ft)
			if not i and It.Y > -30.0 then
				i = Qt(ft)
			end

			if zt.autoTpDownEnabled or zt.dropEnabled or zt._tpInProgress or zt.desyncAimbotEnabled then
				l = Ft + 0.85
				Z = It
				E = Ft
				return
			end

			if Ft < k then
				ft.AssemblyLinearVelocity = Vector3.zero
				ft.AssemblyAngularVelocity = Vector3.zero
				Z = It
				E = Ft
				return
			end

			local i = d(ft, Ht, kt, Ft)
			local k = It.Y
			local d = kt.Y
			local Qt = Vector3.new(kt.X, 0, kt.Z).Magnitude
			local ht = math.min(Ft - E, 0.004166666666666667)
			local lt = Z and (It - Z).Magnitude or 0
			if i then
				w = true
			elseif c == 0 or Ft - c >= y or k < -20.0 or d < -70.0 or lt > 20 then
				w = st(ft, 2048) ~= nil
				c = Ft
			end

			local i = w == false
			local c = Ht:GetState()
			local w = (c == Enum.HumanoidStateType.Jumping or c == Enum.HumanoidStateType.Freefall)
				and Qt < 115
				and kt.Magnitude < 150
				and d > -95.0
				and lt < 24
			local c = k < -200.0
			local y = i and not w and d < -300.0
			local st = i and (Qt > 500 or kt.Magnitude > 600)
			local Qt = i and ht < 0.2 and lt > 150
			local kt = i and not w and G and k < G.Position.Y - 100 and d < -100.0
			local G = i and not w and k < -100.0 and d < -80.0
			if Ft >= l and (c or y or st or Qt or kt or G) then
				r(ft, Ht, Ft)
				return
			end

			Z = It
			E = Ft
		end

		p = n(pt.PreSimulation:Connect(L))
		n(f.AncestryChanged:Connect(function()
			if not f.Parent and p then
				p:Disconnect()
				p = nil
			end
		end))
	end

	if Rt.Character then
		s(Rt.Character)
	end

	n(Rt.CharacterAdded:Connect(function(n)
		task.wait(0.3)
		s(n)
	end))
end

Mt.JumpRequest:Connect(function()
	if not zt.infJumpEnabled or zt.holdInfJumpEnabled then
		return
	end

	local s = Rt.Character
	if not s then
		return
	end

	local n = s:FindFirstChild("HumanoidRootPart")
	local f = s:FindFirstChildOfClass("Humanoid")
	if n and f then
		I(n, f, true)
	end
end)
game:GetService("RunService").Heartbeat:Connect(function()
	if not zt.infJumpEnabled or zt.holdInfJumpEnabled then
		return
	end

	local s = Rt.Character
	if not s then
		return
	end

	local n = s:FindFirstChild("HumanoidRootPart")
	local f = s:FindFirstChildOfClass("Humanoid")
	if n and f then
		if f.FloorMaterial ~= Enum.Material.Air then
			W._jumpWasGrounded = true
			W._lastJumpTime = 0
			return
		end

		if W._jumpWasGrounded then
			W._jumpWasGrounded = false
		end

		local s = s1(n).Y
		if s < -120.0 then
			p1(n, "VampireInfJump", -120.0, 0.08)
		end
	end
end)
if _G._VH_speedControllerCleanup then
	pcall(_G._VH_speedControllerCleanup)
end

local s = {
	token = {},
	lastMoveDir = Vector3.zero,
	renderConn = nil,
	postConn = nil,
	charConn = nil,
	wallUntil = 0,
	wallNormal = nil,
	touchUntil = 0,
	touchProtected = false,
	touchCharacter = nil,
	touchOriginals = setmetatable({}, { __mode = "k" }),
	oldBreakJoints = nil,
}
_G._VH_speedControllerToken = s.token
W._lastDisplayedSpeed = nil
local function n(f)
	local G = setmetatable({}, { __mode = "k" })
	_G._VH_s2VelChecked = G
	if not f then
		return nil
	end

	local i = f:WaitForChild("HumanoidRootPart", 5)
	if i then
		G[i] = true
	end

	return i
end

local function f()
	if zt.laggerMode == 2 then
		return zt.burstCarrySpeed
	elseif zt.laggerMode == 1 then
		return zt.burstNormalSpeed
	elseif zt.speedToggled then
		return zt.carrySpeed
	else
		return zt.normalSpeed
	end
end

local function G()
	if not s.touchProtected then
		return
	end

	for i, p in pairs(s.touchOriginals) do
		if i and i.Parent then
			pcall(function()
				i.CanTouch = p
			end)
		end
	end

	local i = s.touchCharacter
	local p = i and i:FindFirstChildOfClass("Humanoid")
	if p and s.oldBreakJoints ~= nil then
		pcall(function()
			p.BreakJointsOnDeath = s.oldBreakJoints
		end)
	end

	s.touchOriginals = setmetatable({}, { __mode = "k" })
	s.touchProtected = false
	s.touchCharacter = nil
	s.oldBreakJoints = nil
	if Kt.setAuto then
		Kt.setAuto("wall", false)
	end
end

local function i(p, I)
	if not I then
		G()
		return
	end

	if not p then
		return
	end

	if s.touchProtected and s.touchCharacter ~= p then
		G()
	end

	if not s.touchProtected then
		s.touchCharacter = p
		s.touchOriginals = setmetatable({}, { __mode = "k" })
		for I, I in ipairs(p:GetChildren()) do
			if I:IsA("BasePart") then
				s.touchOriginals[I] = I.CanTouch
				pcall(function()
					I.CanTouch = false
				end)
			end
		end

		local I = p:FindFirstChildOfClass("Humanoid")
		if I then
			s.oldBreakJoints = I.BreakJointsOnDeath
			pcall(function()
				I.BreakJointsOnDeath = false
			end)
		end

		s.touchProtected = true
		if Kt.setAuto then
			Kt.setAuto("wall", true)
		end
	else
		for p in pairs(s.touchOriginals) do
			if p and p.Parent and p.CanTouch then
				pcall(function()
					p.CanTouch = false
				end)
			end
		end
	end
end

local function p(I, k, l, Z, E)
	if not (I and I.Parent) then
		return false
	end

	pcall(function()
		if I.SetNetworkOwner then
			I:SetNetworkOwner(Rt)
		end
	end)
	P(I, E)
	local P = I.AssemblyLinearVelocity
	if l and l.Magnitude > 0.05 then
		local r = l.Unit
		local l = Vector3.new(r.X * Z, 0, r.Z * Z)
		local Z, r, c, c, L = n1(I, l, E, 0)
		local l = os.clock()
		local E = r and L and L <= 0.14
		local w = r and L and L <= 0.015
		if E then
			s.touchUntil = l + 0.2
			i(I.Parent, true)
		elseif s.touchProtected and l > s.touchUntil then
			G()
		end

		if w then
			s.wallUntil = l + 0.12
			s.wallNormal = c
			local i = I.AssemblyAngularVelocity
			if math.abs(i.X) > 0.5 or math.abs(i.Z) > 0.5 then
				I.AssemblyAngularVelocity = Vector3.new(0, math.clamp(i.Y, -30.0, 30), 0)
			end
		end

		pcall(function()
			k:Move(Vector3.zero, false)
		end)
		I.AssemblyLinearVelocity = Vector3.new(Z.X, P.Y, Z.Z)
		return w
	else
		pcall(function()
			k:Move(Vector3.zero, false)
		end)
		I.AssemblyLinearVelocity = Vector3.new(0, P.Y, 0)
		return false
	end
end

local function i(I)
	if not I then
		return true
	end

	local k = I:GetState()
	return I.PlatformStand
		or k == Enum.HumanoidStateType.Physics
		or k == Enum.HumanoidStateType.Ragdoll
		or k == Enum.HumanoidStateType.FallingDown
end

if Rt.Character then
	n(Rt.Character)
end

s.charConn = Rt.CharacterAdded:Connect(function(I)
	G()
	s.lastMoveDir = Vector3.zero
	n(I)
end)
s.renderConn = pt.PreSimulation:Connect(function(n)
	if _G._VH_speedControllerToken ~= s.token then
		return
	end

	local I = Rt.Character
	local k = I and I:FindFirstChildOfClass("Humanoid")
	local P = I and I:FindFirstChild("HumanoidRootPart")
	if not (k and P) or k.Health <= 0 then
		return
	end

	if s.touchProtected and os.clock() > s.touchUntil then
		G()
	end

	local I = f()
	if speedLbl and I ~= W._lastDisplayedSpeed then
		W._lastDisplayedSpeed = I
		speedLbl.Text = string.format("%.1f", I)
	end

	if i(k) then
		s.lastMoveDir = Vector3.zero
		return
	end

	local f = P:FindFirstChild("VampireBrakeLinearVelocity")
		or P:FindFirstChild("VampireBatLinearVelocity")
		or P:FindFirstChild("VampireStandDropLinearVelocity")
	if
		zt.autoBatToggled
		or zt.autoLeftEnabled
		or zt.autoRightEnabled
		or zt.dropEnabled
		or zt._tpInProgress
		or f and f.Enabled
	then
		s.lastMoveDir = Vector3.zero
		return
	end

	local f = k.MoveDirection
	local i = nil
	if f.Magnitude > 0 then
		s.lastMoveDir = f
		i = f
	elseif s.lastMoveDir.Magnitude > 0 then
		for f in pairs(dt) do
			if Mt:IsKeyDown(f) then
				i = s.lastMoveDir
				break
			end
		end
	end

	p(P, k, i, I, n)
end)
s.postConn = pt.PostSimulation:Connect(function()
	if _G._VH_speedControllerToken ~= s.token or os.clock() > s.wallUntil then
		return
	end

	local n = Rt.Character
	local f = n and n:FindFirstChild("HumanoidRootPart")
	local i = n and n:FindFirstChildOfClass("Humanoid")
	if not (f and i) or i.Health <= 0 then
		return
	end

	local n = f.AssemblyLinearVelocity
	local p = s.wallNormal
	if p then
		local I = Vector3.new(n.X, 0, n.Z)
		local k = I:Dot(p)
		if k < 0 then
			I = I - p * k
		end

		n = Vector3.new(I.X, n.Y, I.Z)
	end

	local p = i:GetState()
	if p ~= Enum.HumanoidStateType.Jumping and n.Y > 55 then
		n = Vector3.new(n.X, 0, n.Z)
	end

	f.AssemblyLinearVelocity = n
	local n = f.AssemblyAngularVelocity
	f.AssemblyAngularVelocity = Vector3.new(0, math.clamp(n.Y, -30.0, 30), 0)
end)
_G.S2SpeedSetNormal = function()
	if _VH_speedToNormal then
		_VH_speedToNormal()
	else
		zt.speedToggled = false
		zt.laggerMode = 0
	end
end

_G.S2SpeedSetCarry = function()
	if zt.laggerMode ~= 0 and setLaggerMode then
		setLaggerMode(0)
	end

	zt.speedToggled = true
end

_G.S2SpeedSetLaggerNormal = function()
	if setLaggerMode then
		setLaggerMode(1)
	else
		zt.speedToggled = false
		zt.laggerMode = 1
	end
end

_G.S2SpeedSetLaggerCarry = function()
	if setLaggerMode then
		setLaggerMode(2)
	else
		zt.speedToggled = false
		zt.laggerMode = 2
	end
end

_G._VH_speedControllerCleanup = function()
	G()
	if s.renderConn then
		pcall(function()
			s.renderConn:Disconnect()
		end)
		s.renderConn = nil
	end

	if s.postConn then
		pcall(function()
			s.postConn:Disconnect()
		end)
		s.postConn = nil
	end

	if s.charConn then
		pcall(function()
			s.charConn:Disconnect()
		end)
		s.charConn = nil
	end

	if _G._VH_speedControllerToken == s.token then
		_G._VH_speedControllerToken = nil
	end

	_G._VH_s2VelChecked = setmetatable({}, { __mode = "k" })
end

do
	pt.PostSimulation:Connect(function()
		local s = Rt.Character
		local n = s and s:FindFirstChild("HumanoidRootPart")
		local f = s and s:FindFirstChildOfClass("Humanoid")
		if not (n and f) or f.Health <= 0 then
			return
		end

		if f.Sit or f.SeatPart then
			return
		end

		if zt.dropEnabled or zt._tpInProgress or batCounterDebounce then
			return
		end

		local s = n.AssemblyAngularVelocity
		if math.abs(s.X) > 0.5 or math.abs(s.Z) > 0.5 then
			n.AssemblyAngularVelocity = Vector3.new(0, math.clamp(s.Y, -30.0, 30), 0)
		end

		local s = n.CFrame
		if s.UpVector.Y < 0.995 then
			local G = s.LookVector
			local i = Vector3.new(G.X, 0, G.Z)
			if i.Magnitude < 0.05 then
				local G = s.RightVector
				i = Vector3.new(G.X, 0, G.Z)
			end

			if i.Magnitude > 0.05 then
				n.CFrame = CFrame.lookAt(n.Position, n.Position + i.Unit)
			end
		end

		if f:GetState() == Enum.HumanoidStateType.FallingDown then
			pcall(function()
				f:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end
	end)
end

do
	local s = nil
	local n = 0
	pt.PostSimulation:Connect(function()
		local f = Rt.Character
		local G = f and f:FindFirstChild("HumanoidRootPart")
		local i = f and f:FindFirstChildOfClass("Humanoid")
		if not (G and i) or i.Health <= 0 then
			s = nil
			return
		end

		if
			zt.autoBatToggled
			or zt.desyncAimbotEnabled
			or zt.dropEnabled
			or zt.autoTpDownEnabled
			or zt._tpInProgress
			or zt.countdownSafetyActive
		then
			s = nil
			return
		end

		if G:FindFirstChild("VampireStandDropLinearVelocity") or G:FindFirstChild("VampireBatLinearVelocity") then
			s = nil
			return
		end

		local f = i:GetState()
		if
			f == Enum.HumanoidStateType.Physics
			or f == Enum.HumanoidStateType.Ragdoll
			or f == Enum.HumanoidStateType.FallingDown
		then
			s = nil
			return
		end

		local f =
			math.min(zt.normalSpeed or 60, zt.carrySpeed or 30, zt.burstNormalSpeed or 52, zt.burstCarrySpeed or 21)
		local i = f + 999
		local f = G.AssemblyLinearVelocity
		local p = Vector3.new(f.X, 0, f.Z)
		local I = f.Y
		local k = false
		local P = tick()
		if s and P - n < 0.25 then
			if I > 70 and I - s.Y > 45 then
				I = math.min(math.max(s.Y, 70), 0)
				k = true
			end
		end

		if p.Magnitude > i then
			p = p.Unit * i
			k = true
		end

		if I > 90 then
			I = 90
			k = true
		elseif I < -200.0 then
			I = -200.0
			k = true
		end

		if G.AssemblyAngularVelocity.Magnitude > 30 then
			G.AssemblyAngularVelocity = Vector3.zero
		end

		if k then
			f = Vector3.new(p.X, I, p.Z)
			G.AssemblyLinearVelocity = f
		end

		s = f
		n = P
	end)
end

pt.RenderStepped:Connect(function()
	if zt.stretchedResEnabled then
		return
	end

	local s = workspace.CurrentCamera
	if s and math.abs(s.FieldOfView - zt.lockedFOV) > 0.01 then
		s.FieldOfView = zt.lockedFOV
	end
end)
W._BB_BASE_H = 58
W._BB_BASE_OFFSET = 2.2
W._BB_STRETCH_FACTOR = 1.4285714285714286
W._bbStretched = false
pt.RenderStepped:Connect(function()
	if not (speedBB and speedBB.Parent) then
		return
	end

	if zt.stretchedResEnabled then
		if not W._bbStretched then
			speedBB.Size = UDim2.new(0, 220, 0, math.floor(W._BB_BASE_H * W._BB_STRETCH_FACTOR))
			speedBB.StudsOffset = Vector3.new(0, W._BB_BASE_OFFSET * W._BB_STRETCH_FACTOR, 0)
			W._bbStretched = true
		end
	elseif W._bbStretched then
		speedBB.Size = UDim2.new(0, 220, 0, W._BB_BASE_H)
		speedBB.StudsOffset = Vector3.new(0, W._BB_BASE_OFFSET, 0)
		W._bbStretched = false
	end
end)
local s = false
local n = nil
local f = nil
if zt.laggerMode ~= 0 and setLaggerMode then
	setLaggerMode(zt.laggerMode)
end

if setBurstPreset then
	setBurstPreset(zt.burstPreset)
end

if setStretchFOVVisual then
	setStretchFOVVisual(zt.stretchFOV)
end

if _ssv then
	_ssv(zt.activeSky)
end

do
	local G = {
		original = "rbxassetid://14640607134",
		vampire = "rbxassetid://114138477258742",
		golden = "rbxassetid://113621109176868",
		forest = "rbxassetid://15108586724",
		jungle = "rbxassetid://11850170603",
		ocean = "rbxassetid://116893313684229",
		["79809183056960"] = "rbxassetid://79809183056960",
		["79455822331118"] = "rbxassetid://79455822331118",
		["16948826915"] = "rbxassetid://16948826915",
		["101793424727240"] = "rbxassetid://101793424727240",
		["123540425987418"] = "rbxassetid://123540425987418",
		["122195659108931"] = "rbxassetid://122195659108931",
		["6457947928"] = "rbxassetid://6457947928",
		["102609114992392"] = "rbxassetid://102609114992392",
		["8180153808"] = "rbxassetid://8180153808",
		["11761613059"] = "rbxassetid://11761613059",
		["139546609567893"] = "rbxassetid://139546609567893",
		["14430330747"] = "rbxassetid://14430330747",
		["17256388271"] = "rbxassetid://17256388271",
		["132372803152269"] = "rbxassetid://132372803152269",
	}
	local i = G[zt.activeBgImg]
	if i and girlImg then
		girlImg.Image = i
	end
end

if setBgImgVisual then
	setBgImgVisual(zt.activeBgImg)
end

Mt.InputBegan:Connect(function(G, i)
	if i and G.UserInputType == Enum.UserInputType.Keyboard then
		return
	end

	if not Ct(G) then
		return
	end

	local i = G.KeyCode
	if i == Lt.tpDown then
		if Bt and Bt.tpDown and Bt.tpDown.flash then
			Bt.tpDown.flash()
		end

		doTpDown()
	elseif i == Lt.speed then
		if zt.laggerMode ~= 0 then
			local G = zt.laggerMode == 2
			setLaggerMode(0)
			if zt.safeCarryLock and G then
				zt.speedToggled = true
			else
				zt.speedToggled = false
			end

			if Bt and Bt.carrySpeed then
				Bt.carrySpeed.setOn(zt.speedToggled)
			end

			if modeValLbl then
				modeValLbl.Text = zt.speedToggled and "Carry" or "Normal"
			end

			if zt.speedChangeMethod == "v2" and carryBox then
				carryBox.Text = tostring(zt.speedToggled and zt.carrySpeed or zt.normalSpeed)
			end
		else
			zt.speedToggled = not zt.speedToggled
			if Bt and Bt.carrySpeed then
				Bt.carrySpeed.setOn(zt.speedToggled)
			end

			modeValLbl.Text = zt.speedToggled and "Carry" or "Normal"
			if zt.speedChangeMethod == "v2" and carryBox then
				carryBox.Text = tostring(zt.speedToggled and zt.carrySpeed or zt.normalSpeed)
			end
		end
	elseif i == Lt.autoBat then
		zt.autoBatToggled = not zt.autoBatToggled
		setAutoBat(zt.autoBatToggled)
		if zt.autoBatToggled then
			_VH_forceDesyncOff()
			startBatAimbot()
		else
			stopBatAimbot()
		end
	elseif i == Lt.autoLeft then
		zt.autoLeftEnabled = not zt.autoLeftEnabled
		if setAutoLeft then
			setAutoLeft(zt.autoLeftEnabled)
		end

		if zt.autoLeftEnabled then
			_VH_forceAimbotOff()
			_VH_forceDesyncOff()
			startAutoLeft()
		else
			stopAutoLeft()
		end
	elseif i == Lt.autoRight then
		zt.autoRightEnabled = not zt.autoRightEnabled
		if setAutoRight then
			setAutoRight(zt.autoRightEnabled)
		end

		if zt.autoRightEnabled then
			_VH_forceAimbotOff()
			_VH_forceDesyncOff()
			startAutoRight()
		else
			stopAutoRight()
		end
	elseif i == Lt.dropBrainrot then
		if not zt.dropEnabled then
			runDropBrainrot()
		end
	elseif i == Lt.desyncAimbot then
		zt.desyncAimbotEnabled = not zt.desyncAimbotEnabled
		if setDesyncAimbot then
			setDesyncAimbot(zt.desyncAimbotEnabled)
		end

		if zt.desyncAimbotEnabled then
			_VH_forceAimbotOff()
			startDesyncAimbot()
		else
			stopDesyncAimbot()
		end

		if Bt and Bt.tpDesync then
			Bt.tpDesync.setOn(zt.desyncAimbotEnabled)
		end
	elseif Lt.antiDie ~= Enum.KeyCode.Unknown and i == Lt.antiDie then
		zt.antiDieEnabled = not zt.antiDieEnabled
		if Kt.refresh then
			Kt.refresh()
		end
	elseif i == Lt.guiHide then
		toggleGuiVis()
	elseif i == Lt.lagger then
		if zt.speedChangeMethod == "v2" then
			if s then
				zt.normalSpeed = n or zt.normalSpeed
				zt.carrySpeed = f or zt.carrySpeed
				if normalBox then
					normalBox.Text = tostring(zt.normalSpeed)
				end

				if carryBox then
					carryBox.Text = tostring(zt.carrySpeed)
				end

				s = false
				_G._VH_burstActive = false
			end

			toggleLaggerMode()
		else
			if zt.laggerMode ~= 0 then
				setLaggerMode(0)
			end

			if not s then
				n = zt.normalSpeed
				f = zt.carrySpeed
				zt.normalSpeed = zt.burstNormalSpeed
				zt.carrySpeed = zt.burstCarrySpeed
				if normalBox then
					normalBox.Text = tostring(n)
				end

				if carryBox then
					carryBox.Text = tostring(f)
				end

				s = true
				_G._VH_burstActive = true
			else
				zt.normalSpeed = n
				zt.carrySpeed = f
				if normalBox then
					normalBox.Text = tostring(n)
				end

				if carryBox then
					carryBox.Text = tostring(f)
				end

				s = false
				_G._VH_burstActive = false
			end
		end
	end
end)
do
	local s = -math.huge
	local n = 0
	local f = false
	local G = { "bat", "slap", "medusa", "head", "stone" }
	local function i(p)
		p = tostring(p):lower()
		for I, I in ipairs(G) do
			if p:find(I) then
				return true
			end
		end

		return false
	end

	local G = {
		["animate"] = true,
		["animsaves"] = true,
		["health"] = true,
		["rig"] = true,
		["body colors"] = true,
		["bodycolors"] = true,
		["humanoid"] = true,
		["head"] = true,
		["torso"] = true,
		["uppertorso"] = true,
		["lowertorso"] = true,
		["humanoidrootpart"] = true,
	}
	local function p(I)
		local k = I.Name:lower()
		if G[k] then
			return true
		end

		if i(k) then
			return true
		end

		if I:FindFirstChildOfClass("Humanoid") then
			return true
		end

		if I:FindFirstChildWhichIsA("Accoutrement", true) then
			return true
		end

		return false
	end

	isHoldingBrainrot = function()
		local G = Rt.Character
		if not G then
			return false
		end

		for I, I in ipairs(G:GetChildren()) do
			if I:IsA("Tool") and not i(I.Name) then
				return true, "tool", I.Name
			end
		end

		for I, I in ipairs(G:GetChildren()) do
			if I:IsA("Model") and not p(I) and I:FindFirstChildWhichIsA("BasePart") then
				return true, "model", I.Name
			end
		end

		local p = G:FindFirstChildOfClass("Humanoid")
		local I = p and (p.Sit or p.SeatPart ~= nil)
		local p = G:FindFirstChild("HumanoidRootPart") or G.PrimaryPart
		if p and not I then
			local I, k = pcall(function()
				return p:GetConnectedParts(true)
			end)
			if I and k then
				for p, p in ipairs(k) do
					if not p:IsDescendantOf(G) and not p:IsA("Seat") and not p:IsA("VehicleSeat") then
						local G = p:FindFirstAncestorWhichIsA("Tool")
						local I = G and G.Name or p.Name
						if not i(I) then
							local i = p:FindFirstAncestorOfClass("Model")
							if not (i and bt:GetPlayerFromCharacter(i)) then
								local I = i and i.Name or G and G.Name or p.Name
								return true, "weld", I
							end
						end
					end
				end
			end
		end

		return false
	end

	local G = 0
	local i = false
	_G._VH_hbCached = function()
		local p = os.clock()
		if p - G < 0.15 then
			return i
		end

		G = p
		local G, p = pcall(function()
			return isHoldingBrainrot()
		end)
		i = G and p and true or false
		return i
	end

	local G = (function()
		local i = { Range = 15 }
		local p = { active = false, previous = nil, graceUntil = 0 }
		local I = { spots = {}, nextScan = 0, latched = false, held = false, armed = true }
		local function k(P)
			local l = tostring(P or ""):lower()
			return l:find("bat", 1, true)
				or l:find("slap", 1, true)
				or l:find("medusa", 1, true)
				or l:find("head", 1, true)
				or l:find("stone", 1, true)
		end

		local function P(l)
			if not l then
				return false
			end

			if
				Rt:GetAttribute("Stealing") == true
				or Rt:GetAttribute("AntiKick") == true
				or l:GetAttribute("Stealing") == true
			then
				return true
			end

			for Z, Z in ipairs({ "Carrying", "IsCarrying", "Grabbed", "Holding", "StealHold", "HasGrab" }) do
				local E = l:FindFirstChild(Z, true)
				if
					E
					and (
						E:IsA("BoolValue") and E.Value
						or E:IsA("ObjectValue") and E.Value
						or E:IsA("StringValue") and E.Value ~= ""
					)
				then
					return true
				end
			end

			for Z, Z in ipairs(l:GetChildren()) do
				local l = Z.Name:lower()
				if Z:IsA("Tool") and not k(l) then
					return true
				end

				if
					Z:IsA("Model")
					and Z:FindFirstChildWhichIsA("BasePart", true)
					and (
						l:find("brainrot", 1, true)
						or l:find("animal", 1, true)
						or l:find("carry", 1, true)
						or l:find("grab", 1, true)
						or l:find("steal", 1, true)
						or l:find("hold", 1, true)
					)
				then
					return true
				end
			end

			return false
		end

		local function k()
			return zt.laggerMode == 0 and zt.speedToggled == true
		end

		local function l(Z)
			if zt.laggerMode ~= 0 then
				return false
			end

			Z = Z == true
			if zt.speedToggled ~= Z then
				zt.speedToggled = Z
				if modeValLbl then
					modeValLbl.Text = Z and "Carry" or "Normal"
				end

				if Bt and Bt.carrySpeed then
					Bt.carrySpeed.setOn(Z)
				end

				if zt.speedChangeMethod == "v2" and carryBox then
					carryBox.Text = tostring(Z and zt.carrySpeed or zt.normalSpeed)
				end
			end

			return true
		end

		local function Z()
			if not p.active then
				return
			end

			local E = p.previous
			p.active = false
			p.previous = nil
			l(E == true)
		end

		local function E()
			local r = {}
			local K = workspace:FindFirstChild("Plots")
			if not K then
				I.spots = r
				return
			end

			for c, c in ipairs(K:GetChildren()) do
				local K = c:FindFirstChild("PlotSign")
				local L = K and K:FindFirstChild("YourBase")
				local K = L and L:IsA("BillboardGui") and L.Enabled == true
				if not K then
					local K = c:FindFirstChild("AnimalPodiums")
					if K then
						for c, c in ipairs(K:GetChildren()) do
							local K = c:FindFirstChild("Base")
							local c = K and K:FindFirstChild("Spawn")
							if c then
								r[#r + 1] = c.Position
							end
						end
					end
				end
			end

			I.spots = r
		end

		local function r()
			if not p.active then
				p.previous = k()
				p.active = true
			end

			p.graceUntil = tick() + 0.75
			l(true)
		end

		local function l(K)
			local c = K and K:FindFirstChild("HumanoidRootPart")
			if not c then
				return false
			end

			local K = tonumber(i.Range) or 15
			local i = _G._VantaStealTargetPos or _G._RaVeStealTargetPos
			if typeof(i) == "Vector3" and (c.Position - i).Magnitude <= K then
				return true
			end

			local i = tick()
			if i >= I.nextScan then
				I.nextScan = i + 0.5
				E()
			end

			for i, i in ipairs(I.spots) do
				if (c.Position - i).Magnitude <= K then
					return true
				end
			end

			return false
		end

		local function i()
			I.latched = false
			I.held = false
			I.armed = true
			I.nextScan = 0
			Z()
		end

		local function E()
			if not zt.autoCarryOnGrab or zt.autoCarryVersion ~= "v2" then
				i()
				return
			end

			local K = Rt.Character
			local c = K and K:FindFirstChildOfClass("Humanoid")
			if not K or not c or c.Health <= 0 then
				i()
				return
			end

			local c = l(K)
			local l = P(K)
			if not c then
				I.armed = true
			end

			if not c or k() ~= true then
				I.latched = false
			end

			if c and I.armed and not I.latched then
				I.latched = true
				I.held = false
				r()
			end

			if p.active then
				if l then
					I.held = true
					p.graceUntil = tick() + 0.75
				elseif I.held then
					I.held = false
					I.latched = false
					I.armed = false
					Z()
				elseif not c and tick() > p.graceUntil then
					I.latched = false
					Z()
				end
			end
		end

		return { Step = E, Reset = i }
	end)()
	local function i()
		if zt.laggerMode == 1 then
			setLaggerMode(2)
		elseif zt.laggerMode == 0 then
			if not zt.speedToggled then
				zt.speedToggled = true
				if modeValLbl then
					modeValLbl.Text = "Carry"
				end

				if Bt and Bt.carrySpeed then
					Bt.carrySpeed.setOn(true)
				end
			end
		end
	end

	local function p()
		if zt.laggerMode == 2 then
			setLaggerMode(1)
		elseif zt.laggerMode == 0 then
			if zt.speedToggled then
				zt.speedToggled = false
				if modeValLbl then
					modeValLbl.Text = "Normal"
				end

				if Bt and Bt.carrySpeed then
					Bt.carrySpeed.setOn(false)
				end
			end
		end
	end

	pt.Heartbeat:Connect(function(I)
		n = n + I
		if n < 0.1 then
			return
		end

		n = 0
		if zt.safeModeEnabled then
			zt.safeCarryLock = _G._VH_hbCached and _G._VH_hbCached() or false
		else
			zt.safeCarryLock = false
		end

		if zt.autoCarryVersion == "v2" then
			f = false
			s = -math.huge
			G.Step()
			zt.safetyLocked = false
			return
		end

		G.Reset()
		if not zt.autoCarryOnGrab then
			f = false
			zt.safetyLocked = false
			return
		end

		local n = os.clock()
		local I = false
		pcall(function()
			I = isHoldingBrainrot()
		end)
		if I then
			s = n
		end

		local I = n - s < 0.3
		if I ~= f then
			if I then
				i()
			else
				p()
			end

			f = I
		end

		zt.safetyLocked = false
	end)
	_G._VH_resetAutoCarryRuntime = function()
		f = false
		s = -math.huge
		G.Reset()
	end

	Rt.CharacterAdded:Connect(function()
		f = false
		s = -math.huge
		G.Reset()
	end)
end

(function()
	local s = _G._VH_KickWarning
	if s and s.Cleanup then
		pcall(s.Cleanup)
	end

	local s = game:GetService("GuiService")
	local n = { Connections = {}, Token = 0, CarryWas = false, SuppressUntil = 0 }
	_G._VH_KickWarning = n
	local function f(G)
		n.Connections[#n.Connections + 1] = G
		return G
	end

	local function G()
		if gethui then
			local i, p = pcall(gethui)
			if i and p then
				return p
			end
		end

		local i, p = pcall(function()
			return game:GetService("CoreGui")
		end)
		if i and p then
			return p
		end

		return Rt:WaitForChild("PlayerGui")
	end

	local function i()
		local p = Vector2.zero
		pcall(function()
			p = s:GetGuiInset()
		end)
		return math.max(10, (p and p.Y or 0) + 8)
	end

	local s = Instance.new("ScreenGui")
	s.Name = "VampireHubKickWarning"
	s.ResetOnSpawn = false
	s.DisplayOrder = 100000
	s.IgnoreGuiInset = true
	s.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local p = G()
	local G = p:FindFirstChild(s.Name)
	if G then
		G:Destroy()
	end

	s.Parent = p
	local G = Instance.new("Frame", s)
	G.Name = "Root"
	G.AnchorPoint = Vector2.new(0.5, 0)
	G.Size = UDim2.new(0.6, -14.0, 0, 68)
	G.Position = UDim2.new(0.5, 0, 0, -84.0)
	G.BackgroundColor3 = Color3.fromRGB(5, 5, 7)
	G.BackgroundTransparency = 0.04
	G.BorderSizePixel = 0
	G.Active = true
	G.Visible = false
	G.ZIndex = 20
	local p = Instance.new("UISizeConstraint", G)
	p.MinSize = Vector2.new(200, 68)
	p.MaxSize = Vector2.new(252, 68)
	Instance.new("UICorner", G).CornerRadius = UDim.new(0, 12)
	local p = Instance.new("UIStroke", G)
	p.Thickness = 1.5
	p.Transparency = 0.12
	p.Color = a1.purple
	local I = Instance.new("UIGradient", G)
	I.Rotation = 90
	I.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 19)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 3, 5)),
	})
	local I = Instance.new("TextLabel", G)
	I.Size = UDim2.new(1, -24.0, 0, 13)
	I.Position = UDim2.new(0, 12, 0, 3)
	I.BackgroundTransparency = 1
	I.Text = "KICK WARNING  \226\128\162  2.3s"
	I.TextColor3 = a1.lpurple
	I.Font = Enum.Font.GothamBold
	I.TextSize = 10
	I.TextStrokeTransparency = 0
	I.ZIndex = 23
	local x = Instance.new("TextLabel", G)
	x.Size = UDim2.new(1, -24.0, 0, 31)
	x.Position = UDim2.new(0, 12, 0, 13)
	x.BackgroundTransparency = 1
	x.Text = "DON'T STEAL"
	x.TextColor3 = a1.white
	x.Font = Enum.Font.Gotham
	x.TextSize = 21
	x.TextStrokeTransparency = 0
	x.ZIndex = 23
	local k = Instance.new("Frame", G)
	k.Size = UDim2.new(1, -24.0, 0, 10)
	k.Position = UDim2.new(0, 12, 1, -17.0)
	k.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
	k.BorderSizePixel = 0
	k.Active = true
	k.ZIndex = 22
	Instance.new("UICorner", k).CornerRadius = UDim.new(1, 0)
	local P = Instance.new("UIStroke", k)
	P.Thickness = 1
	P.Transparency = 0.5
	P.Color = a1.border
	local l = Instance.new("Frame", k)
	l.Size = UDim2.new(0, 0, 1, 0)
	l.BackgroundColor3 = a1.purple
	l.BorderSizePixel = 0
	l.Active = true
	l.ZIndex = 23
	Instance.new("UICorner", l).CornerRadius = UDim.new(1, 0)
	local m = Instance.new("UIGradient", l)
	m.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, a1.dpurple),
		ColorSequenceKeypoint.new(0.55, a1.purple),
		ColorSequenceKeypoint.new(1, a1.lpurple),
	})
	m.Offset = Vector2.new(-1.0, 0)
	local b = Instance.new("UIStroke", l)
	b.Thickness = 1.5
	b.Transparency = 0.3
	b.Color = a1.lpurple
	local function k()
		if not (G and G.Parent) then
			return
		end

		p.Color = a1.purple
		P.Color = a1.border
		l.BackgroundColor3 = a1.purple
		b.Color = a1.lpurple
		m.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, a1.dpurple),
			ColorSequenceKeypoint.new(0.55, a1.purple),
			ColorSequenceKeypoint.new(1, a1.lpurple),
		})
		I.TextColor3 = a1.lpurple
		x.TextColor3 = a1.white
	end

	local function P()
		n.Token = n.Token + 1
		local z = n.Token
		if G and G.Parent and G.Visible then
			gt:Create(
				G,
				TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.new(0.5, 0, 0, -84.0), BackgroundTransparency = 0.18 }
			):Play()
		end

		task.spawn(function()
			task.wait(0.18)
			if z == n.Token and G and G.Parent then
				G.Visible = false
				G.BackgroundTransparency = 0.04
				l.Size = UDim2.new(0, 0, 1, 0)
			end
		end)
	end

	local function V()
		if not zt.kickWarningEnabled or tick() < n.SuppressUntil then
			return
		end

		n.Token = n.Token + 1
		local z = n.Token
		k()
		G.Visible = true
		G.Position = UDim2.new(0.5, 0, 0, -84.0)
		G.BackgroundTransparency = 0.04
		p.Transparency = 0.32
		l.Size = UDim2.new(0, 0, 1, 0)
		m.Offset = Vector2.new(-1.0, 0)
		I.Text = "KICK WARNING  \226\128\162  2.3s"
		x.Text = "DON'T STEAL"
		x.TextColor3 = a1.white
		gt:Create(
			G,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, 0, 0, i()) }
		):Play()
		task.spawn(function()
			local a = tick()
			while z == n.Token and G and G.Parent do
				local i = tick() - a
				local a = math.clamp(i / 2.3, 0, 1)
				local v = a * a * (3 - 2 * a)
				local q = math.min(0, 2.3 - i)
				l.Size = UDim2.new(v, 0, 1, 0)
				m.Offset = Vector2.new(-1.0 + a * 2, 0)
				b.Transparency = 0.38 - 0.28 * math.sin(a * 3.141592653589793)
				p.Transparency = 0.32 - 0.24 * v
				I.Text = string.format("KICK WARNING  \226\128\162  %.1fs", q)
				if a >= 1 then
					break
				end

				pt.RenderStepped:Wait()
			end

			if z == n.Token and G and G.Parent then
				l.Size = UDim2.new(1, 0, 1, 0)
				I.Text = "KICK WARNING  \226\128\162  READY"
				x.Text = "STEAL"
				x.TextColor3 = a1.lpurple
				task.wait(0.45)
				if z == n.Token then
					P()
				end
			end
		end)
	end

	local function x(m)
		n.SuppressUntil = tick() + (tonumber(m) or 2.3)
		P()
	end

	_G._VH_showKickWarning = V
	_G._VH_hideKickWarning = P
	_G._VH_suppressKickWarning = x
	_G._VH_refreshKickWarningTheme = k
	local x = 0
	f(pt.Heartbeat:Connect(function(m)
		x = x + (m or 0)
		if x < 0.05 then
			return
		end

		x = 0
		local x = false
		pcall(function()
			x = isHoldingBrainrot and isHoldingBrainrot() or false
		end)
		x = x == true
		if zt.kickWarningEnabled and x and not n.CarryWas and tick() >= n.SuppressUntil then
			V()
		elseif n.CarryWas and not x then
			n.SuppressUntil = tick() + 0.35
			P()
		end

		n.CarryWas = x
	end))
	f(Rt.CharacterAdded:Connect(function()
		n.CarryWas = false
		P()
	end))
	n.Cleanup = function()
		n.Token = n.Token + 1
		for x, x in ipairs(n.Connections) do
			pcall(function()
				x:Disconnect()
			end)
		end

		n.Connections = {}
		if s and s.Parent then
			pcall(function()
				s:Destroy()
			end)
		end

		if _G._VH_KickWarning == n then
			_G._VH_KickWarning = nil
			_G._VH_showKickWarning = nil
			_G._VH_hideKickWarning = nil
			_G._VH_suppressKickWarning = nil
			_G._VH_refreshKickWarningTheme = nil
		end
	end
end)()
local function x(m)
	if not (m and zt.disablePredictionAt180) then
		return false
	end

	local a = s1(m).Magnitude
	return a >= 180
end

local function m()
	if not hrp then
		return nil, math.huge, false
	end

	local a, s = nil, math.huge
	local Q = false
	for n, n in pairs(bt:GetPlayers()) do
		if n ~= Rt and n.Character then
			local V = n.Character:FindFirstChild("HumanoidRootPart")
			if V then
				local f = (hrp.Position - V.Position).Magnitude
				if f < s then
					s = f
					a = n
					Q = x(V)
					if predictionStatusLbl then
						if Q then
							predictionStatusLbl.Text = "DISABLED"
							predictionStatusLbl.TextColor3 = a1.dpurple
						else
							predictionStatusLbl.Text = "ACTIVE"
							predictionStatusLbl.TextColor3 = a1.purple
						end
					end
				end
			end
		end
	end

	return a, s, Q
end

W._predictionElapsed = 0
pt.Heartbeat:Connect(function(x)
	if zt.disablePredictionAt180 and zt.autoBatToggled then
		W._predictionElapsed = W._predictionElapsed + x
		if W._predictionElapsed < 0.1 then
			return
		end

		W._predictionElapsed = 0
		pcall(function()
			m()
		end)
	end
end)
task.spawn(function()
	local x = Instance.new("Sound")
	x.SoundId = "rbxassetid://77011934666860"
	x.Volume = 1
	x.Parent = game:GetService("SoundService")
	x:Play()
	game:GetService("Debris"):AddItem(x, 30)
end)
local x = game:GetService("Stats")
local m = { lastTick = tick(), frameCount = 0, fps = 0, ping = 0 }
pt.RenderStepped:Connect(function()
	m.frameCount = m.frameCount + 1
end)
task.spawn(function()
	while task.wait(0.5) do
		local Q = tick()
		local a = Q - m.lastTick
		if a > 0 then
			m.fps = math.floor(m.frameCount / a)
			m.frameCount = 0
			m.lastTick = Q
			pcall(function()
				local ping = tonumber(x.Network.ServerStatsItem["Data Ping"]:GetValue())
				if ping then
					m.ping = math.floor(ping)
				end
			end)
			if statsLbl and statsLbl.Parent then
				statsLbl.Text = string.format("FPS: %d  |  PING: %d", m.fps, m.ping)
				if m.fps >= 55 then
					statsLbl.TextColor3 = Color3.fromRGB(200, 60, 60)
				elseif m.fps >= 35 then
					statsLbl.TextColor3 = Color3.fromRGB(170, 40, 40)
				else
					statsLbl.TextColor3 = Color3.fromRGB(140, 25, 25)
				end
			end

			if _prl then
				local x = {}
				if zt.showProgressFPS then
					table.insert(x, string.format("FPS:%d", m.fps))
				end

				if zt.showProgressPing then
					table.insert(x, string.format("PING:%d", m.ping))
				end

				_prl.Text = table.concat(x, "     ")
			end
		end
	end
end)
if _G._VH_ESP and _G._VH_ESP.cleanup then
	pcall(_G._VH_ESP.cleanup)
end

_G._VH_ESP = { conns = {}, lineFrames = {}, boxFrames = {} }
local x = workspace.CurrentCamera
local m = _G._VH_ESP.conns
local function Q(a)
	table.insert(m, a)
	return a
end

local m = Instance.new("ScreenGui")
m.Name = "VH_ESP_Layer"
m.ResetOnSpawn = false
m.IgnoreGuiInset = true
m.DisplayOrder = 999
pcall(function()
	m.ZIndexBehavior = Enum.ZIndexBehavior.Global
end)
local a = gethui and gethui() or CoreGui or game:GetService("CoreGui")
pcall(function()
	local s = a:FindFirstChild("VH_ESP_Layer")
	if s then
		s:Destroy()
	end
end)
m.Parent = a
_G._VH_ESP.gui = m
local function a(s)
	if s == Rt then
		return
	end

	local n = s.Character
	if not n then
		return
	end

	local s = n:FindFirstChild("VampireHighlight")
	if not zt.espAuraEnabled then
		if s then
			s:Destroy()
		end

		return
	end

	if s then
		s.FillColor = a1.purple
		s.OutlineColor = a1.purple
		return
	end

	local s = Instance.new("Highlight")
	s.Name = "VampireHighlight"
	s.FillColor = a1.purple
	s.FillTransparency = 0.7
	s.OutlineColor = a1.purple
	s.OutlineTransparency = 0.3
	s.Parent = n
end

local function s(n)
	local V = n and n.Character
	if not V then
		return
	end

	local n = V:FindFirstChild("VampireHighlight")
	if n then
		n:Destroy()
	end
end

_seA = function(n)
	zt.espAuraEnabled = n
	for V, V in ipairs(bt:GetPlayers()) do
		if V ~= Rt then
			if n then
				a(V)
			else
				s(V)
			end
		end
	end
end

local function n(V)
	if V == Rt then
		return
	end

	if V.Character then
		task.spawn(function()
			a(V)
		end)
	end

	Q(V.CharacterAdded:Connect(function()
		task.wait(0.3)
		a(V)
	end))
end

for V, V in ipairs(bt:GetPlayers()) do
	n(V)
end

Q(bt.PlayerAdded:Connect(n))
Q(bt.PlayerRemoving:Connect(function(n)
	s(n)
end))
task.spawn(function()
	while _G._VH_ESP and _G._VH_ESP.gui == m and task.wait(2) do
		for s, s in ipairs(bt:GetPlayers()) do
			if s ~= Rt and s.Character then
				if zt.espAuraEnabled then
					if not s.Character:FindFirstChild("VampireHighlight") then
						a(s)
					end
				else
					local a = s.Character:FindFirstChild("VampireHighlight")
					if a then
						a:Destroy()
					end
				end
			end
		end
	end
end)
local a = _G._VH_ESP.lineFrames
local s = _G._VH_ESP.boxFrames
local function n()
	local V = Instance.new("Frame")
	V.Name = "ln"
	V.BorderSizePixel = 0
	V.AnchorPoint = Vector2.new(0.5, 0.5)
	V.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	V.Visible = false
	V.ZIndex = 1
	V.Parent = m
	table.insert(a, V)
	return V
end

local function V()
	local f = Instance.new("Frame")
	f.Name = "bx"
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	f.BackgroundTransparency = 0.75
	f.Visible = false
	f.ZIndex = 2
	local G = Instance.new("UIStroke", f)
	G.Thickness = 1.5
	G.Color = Color3.fromRGB(255, 255, 255)
	G.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	f.Parent = m
	table.insert(s, { frame = f, stroke = G })
	return s[#s]
end

local function m(f, G, i)
	for b = G + 1, #f do
		local G = f[b]
		local f = i and G.frame or G
		if f then
			f.Visible = false
		end
	end
end

_seL = function(f)
	zt.espLineEnabled = f
	if not f then
		for f, f in ipairs(a) do
			f.Visible = false
		end
	end
end

_seH = function(f)
	zt.espHitboxEnabled = f
	if not f then
		for f, f in ipairs(s) do
			f.frame.Visible = false
		end
	end
end

local f = {}
W.ESP_MAX_SPEED = 300
W.ESP_ACCEPT_TIME = 0.075
W.ESP_ACCEPT_DIST = 9
W.ESP_ACCEPT_SAMPLES = 3
W.ESP_VOID_Y = -35.0
W.ESP_MAX_Y = 350
W.ESP_GROUND_DEPTH = 160
W.ESP_VOID_PROBE = 0.022222222222222223
W.ESP_VOID_CACHE_MOVE = 2
local G = RaycastParams.new()
G.FilterType = Enum.RaycastFilterType.Exclude
W._espFilterAt = 0
local function i(b)
	return b.X == b.X
		and b.Y == b.Y
		and b.Z == b.Z
		and math.abs(b.X) < 1000000
		and math.abs(b.Y) < 1000000
		and math.abs(b.Z) < 1000000
end

local function b(p, H, R)
	if not i(p) or p.Y < W.ESP_VOID_Y or p.Y > W.ESP_MAX_Y then
		return true
	end

	if
		H
		and H.voidAt
		and H.voidProbePos
		and R - H.voidAt < W.ESP_VOID_PROBE
		and (p - H.voidProbePos).Magnitude <= W.ESP_VOID_CACHE_MOVE
	then
		return H.voidVal
	end

	local i = nil
	pcall(function()
		if R - W._espFilterAt > 0.5 then
			W._espFilterAt = R
			local I = {}
			for k, k in ipairs(bt:GetPlayers()) do
				if k.Character then
					I[#I + 1] = k.Character
				end
			end

			G.FilterDescendantsInstances = I
		end

		i = workspace:Raycast(p + Vector3.new(0, 4, 0), Vector3.new(0, -(W.ESP_GROUND_DEPTH + 4), 0), G)
	end)
	local G = i == nil
	if H then
		H.voidAt = R
		H.voidProbePos = p
		H.voidVal = G
	end

	return G
end

local function G(i, p, H)
	i.pos = p
	i.at = H
	i.cand = nil
	i.candAt = 0
	i.candCount = 0
	i.frozen = false
	return p
end

local function i(p, H, R, I)
	local I = H.Position
	local k = H.Parent
	local H = f[p]
	if not H or H.character ~= k then
		H = { character = k, pos = nil, at = R, cand = nil, candAt = 0, candCount = 0, frozen = false }
		f[p] = H
	end

	local P = b(I, H, R)
	if not H.pos then
		if P then
			local l = Pt[p]
			if l and l.confirmed and l.character == k and l.position and not b(l.position, H, R) then
				H.pos = l.position
				H.at = l.positionAt or R
			end

			H.frozen = true
			return H.pos
		end

		return G(H, I, R)
	end

	if P then
		H.at = R
		H.cand = nil
		H.candAt = 0
		H.candCount = 0
		H.frozen = true
		return H.pos
	end

	local b = math.min(R - (H.at or R), 0.004166666666666667)
	local p = (I - H.pos).Magnitude
	if not H.frozen and p <= W.ESP_MAX_SPEED * b then
		return G(H, I, R)
	end

	if H.frozen and p <= 12 then
		return G(H, I, R)
	end

	if H.cand and (I - H.cand).Magnitude <= W.ESP_ACCEPT_DIST then
		H.cand = H.cand:Lerp(I, 0.45)
		H.candCount = (H.candCount or 0) + 1
		if H.candCount >= W.ESP_ACCEPT_SAMPLES and R - H.candAt >= W.ESP_ACCEPT_TIME then
			return G(H, I, R)
		end
	else
		H.cand = I
		H.candAt = R
		H.candCount = 1
	end

	H.at = R
	return H.pos
end

Q(bt.PlayerRemoving:Connect(function(G)
	f[G] = nil
end))
_G._VH_realPos = function(G, b)
	if not (G and b) then
		return b and b.Position, false
	end

	local p, H = pcall(function()
		return i(G, b, tick(), true)
	end)
	local b = f[G]
	local f = b and b.frozen and true or false
	if not p then
		return nil, true
	end

	return H, f or H == nil
end

W._espRenderElapsed = 0
W._espWasActive = false
Q(pt.RenderStepped:Connect(function(Q)
	local f = zt.espLineEnabled
	local G = zt.espHitboxEnabled
	if not f and not G then
		if W._espWasActive then
			m(a, 0, false)
			m(s, 0, true)
			W._espWasActive = false
		end

		return
	end

	W._espWasActive = true
	W._espRenderElapsed = W._espRenderElapsed + (Q or 0)
	if W._espRenderElapsed < 0.016666666666666666 then
		return
	end

	W._espRenderElapsed = 0
	x = workspace.CurrentCamera or x
	if not x then
		m(a, 0, false)
		m(s, 0, true)
		return
	end

	local W = Rt.Character
	local Q = W and W:FindFirstChild("HumanoidRootPart")
	local W = f and Q ~= nil
	local b = x.ViewportSize
	local p, H
	if W then
		local F = x:WorldToViewportPoint(Q.Position)
		if F.Z > 0 then
			p, H = F.X, F.Y
		else
			p, H = b.X / 2, b.Y
		end
	elseif f then
		m(a, 0, false)
	end

	local Q = zt.lineEspColor == "white" and Color3.fromRGB(235, 235, 235) or a1.purple
	local f = a1.purple
	local g, F = 0, 0
	for R, R in ipairs(bt:GetPlayers()) do
		if R ~= Rt and R.Character then
			local I = R.Character:FindFirstChild("HumanoidRootPart")
			if I then
				local M = i(R, I, tick())
				if M then
					if W then
						local W = x:WorldToViewportPoint(M)
						local i, k = W.X, W.Y
						if W.Z < 0 then
							i = b.X - i
							k = b.Y - k
						end

						g = g + 1
						local W = a[g] or n()
						local n, b = i - p, k - H
						local P = math.sqrt(n * n + b * b)
						if P == P and P > 0 then
							W.Size = UDim2.new(0, P, 0, 2)
							W.Position = UDim2.new(0, (p + i) / 2, 0, (H + k) / 2)
							W.Rotation = math.deg(math.atan2(b, n))
							W.BackgroundColor3 = Q
							W.BackgroundTransparency = 0
							W.Visible = true
						else
							W.Visible = false
						end
					end

					if G then
						local W = R.Character:FindFirstChild("Head")
						local Q = M - I.Position
						local n = (W and W.Position or I.Position) + Q + Vector3.new(0, 1.6, 0)
						local W = M - Vector3.new(0, 3, 0)
						local Q, G = x:WorldToViewportPoint(n)
						local n, i = x:WorldToViewportPoint(W)
						if G and i and Q.Z > 0 and n.Z > 0 then
							local W = math.abs(n.Y - Q.Y)
							local x = W * 0.55
							if W == W and x == x and W > 0 then
								F = F + 1
								local J = s[F] or V()
								J.frame.Size = UDim2.new(0, x, 0, W)
								J.frame.Position = UDim2.new(0, (Q.X + n.X) / 2 - x / 2, 0, math.max(Q.Y, n.Y))
								J.frame.BackgroundColor3 = f
								J.frame.BackgroundTransparency = 0.75
								J.stroke.Color = f
								J.frame.Visible = true
							end
						end
					end
				end
			end
		end
	end

	m(a, g, false)
	m(s, F, true)
end))
_G._VH_ESP.cleanup = function()
	for W, W in ipairs(_G._VH_ESP.conns or {}) do
		pcall(function()
			W:Disconnect()
		end)
	end

	if _G._VH_ESP.gui then
		pcall(function()
			_G._VH_ESP.gui:Destroy()
		end)
	end

	for W, W in ipairs(bt:GetPlayers()) do
		local x = W.Character
		if x then
			local W = x:FindFirstChild("VampireHighlight")
			if W then
				W:Destroy()
			end
		end
	end

	_G._VH_ESP.conns = {}
	_G._VH_ESP.lineFrames = {}
	_G._VH_ESP.boxFrames = {}
end

task.spawn(function()
	task.wait(0.2)
	if _seA then
		_seA(zt.espAuraEnabled)
	end

	if _seL then
		_seL(zt.espLineEnabled)
	end

	if _seH then
		_seH(zt.espHitboxEnabled)
	end

	if _G._VH_setEspUI then
		pcall(_G._VH_setEspUI)
	end
end)

--[[
    /printed branding layer — v3
    Readable source markers and one dedicated overlay for the four screen corners.
    IMPORTANT: Do not attach a watermark to every ScreenGui; that caused stacked labels.
]]
local function _printedCreateCornerLabel(parent, name, anchor, position, alignment)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.AnchorPoint = anchor
    label.Position = position
    label.Size = UDim2.new(0, 190, 0, 16)
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = "LEAKED BY /printed  •  NUMBER 1"
    label.TextColor3 = Color3.fromRGB(205, 205, 205)
    label.TextTransparency = 0.16
    label.TextSize = 10
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = alignment
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = false
    label.TextWrapped = false
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.RichText = false
    label.Active = false
    label.Selectable = false
    label.ZIndex = 1000
    label.Parent = parent
    return label
end

local function _printedInstallCornerBranding()
    -- Keep one overlay only, even if this script is accidentally run more than once.
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    if not localPlayer then
        warn("[/printed] LocalPlayer unavailable; corner branding skipped.")
        return
    end

    local playerGui = localPlayer:WaitForChild("PlayerGui", 10)
    if not playerGui then
        warn("[/printed] PlayerGui unavailable; corner branding skipped.")
        return
    end

    local existing = playerGui:FindFirstChild("_PrintedCornerBranding")
    if existing then
        existing:Destroy()
    end

    local overlay = Instance.new("ScreenGui")
    overlay.Name = "_PrintedCornerBranding"
    overlay.ResetOnSpawn = false
    overlay.IgnoreGuiInset = true
    overlay.DisplayOrder = 10000
    overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    overlay.Parent = playerGui

    -- Each corner uses its own fixed anchor and alignment; no labels overlap one another.
    _printedCreateCornerLabel(
        overlay, "BrandTopLeft",
        Vector2.new(0, 0), UDim2.new(0, 10, 0, 8),
        Enum.TextXAlignment.Left
    )
    _printedCreateCornerLabel(
        overlay, "BrandTopRight",
        Vector2.new(1, 0), UDim2.new(1, -10, 0, 8),
        Enum.TextXAlignment.Right
    )
    _printedCreateCornerLabel(
        overlay, "BrandBottomLeft",
        Vector2.new(0, 1), UDim2.new(0, 10, 1, -8),
        Enum.TextXAlignment.Left
    )
    _printedCreateCornerLabel(
        overlay, "BrandBottomRight",
        Vector2.new(1, 1), UDim2.new(1, -10, 1, -8),
        Enum.TextXAlignment.Right
    )
end

-- [ /printed ] STARTUP BRANDING / DIAGNOSTICS
print("==================================================")
print("[/printed] LEAKED BY /printed • NUMBER 1")
print("[/printed] VampireHub branding layer initialized")
print("==================================================")

task.spawn(function()
    local ok, err = pcall(_printedInstallCornerBranding)
    if not ok then
        warn("[/printed] Corner branding failed: " .. tostring(err))
    end
end)

-- [ /printed ] END OF BRANDING LAYER
-- SECURITY: The original file executed an unverified remote script here.
-- It has been disabled by default. Audit any dependency locally before enabling.
-- No remote code is executed by this improved build.

-- ============================================================================
-- VAMPIRE HUB V4 - AUTO ROUTE EXPERIMENTAL ADD-ON
-- Uses ordinary Humanoid navigation and optional executor prompt activation.
-- No server-side inventory/storage functionality is fabricated.
-- F6 toggles the experimental route. F5 displays/hides its control panel.
-- ============================================================================
do
    local Players = game:GetService('Players')
    local PathfindingService = game:GetService('PathfindingService')
    local UserInputService = game:GetService('UserInputService')
    local RunService = game:GetService('RunService')
    local localPlayer = Players.LocalPlayer
    if localPlayer then
        local previous = _G.VH4AutoRoute
        if previous and type(previous.Stop) == 'function' then pcall(previous.Stop) end
        local active, runId, targetName, state = false, 0, '-', 'Idle'
        local totalAttempts, successfulDetections = 0, 0
        local routeSpeed = 60
        local panelGui
        local statusLabel, targetLabel, speedLabel, button
        local function message(s)
            state = s
            if statusLabel and statusLabel.Parent then statusLabel.Text = 'STATUS  •  ' .. s end
        end
        local function updateUI()
            if targetLabel and targetLabel.Parent then targetLabel.Text = 'TARGET  •  ' .. targetName end
            if speedLabel and speedLabel.Parent then speedLabel.Text = 'ROUTE SPEED  •  ' .. tostring(routeSpeed) end
            if button and button.Parent then
                button.Text = active and 'STOP AUTO ROUTE' or 'START AUTO ROUTE'
                button.BackgroundColor3 = active and Color3.fromRGB(132, 40, 52) or Color3.fromRGB(65, 139, 97)
            end
        end
        local function getCharacter()
            local character = localPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass('Humanoid')
            local root = character and character:FindFirstChild('HumanoidRootPart')
            if character and humanoid and root and humanoid.Health > 0 then return character, humanoid, root end
        end
        local function getOwnPlot()
            local plots = workspace:FindFirstChild('Plots')
            if not plots then return nil end
            for _, plot in ipairs(plots:GetChildren()) do
                local sign = plot:FindFirstChild('PlotSign')
                local own = sign and sign:FindFirstChild('YourBase')
                if own and own:IsA('BillboardGui') and own.Enabled then return plot end
            end
            return nil
        end
        local function carryDetected(character)
            for _, name in ipairs({'Carrying','IsCarrying','Grabbed','Holding','HasGrab'}) do
                local obj = character:FindFirstChild(name, true) or localPlayer:FindFirstChild(name)
                if obj and obj:IsA('BoolValue') and obj.Value then return true end
                if obj and obj:IsA('ObjectValue') and obj.Value then return true end
            end
            for _, att in ipairs({'Carrying','IsCarrying','Holding','HasGrab'}) do
                if character:GetAttribute(att) == true or localPlayer:GetAttribute(att) == true then return true end
            end
            for _, obj in ipairs(character:GetChildren()) do
                if obj:IsA('Model') and obj.Name:lower():find('brainrot',1,true) then return true end
            end
            return false
        end
        local function getTarget(root)
            local plots = workspace:FindFirstChild('Plots')
            if not plots then return nil end
            local ownPlot = getOwnPlot()
            local nearest, best = nil, math.huge
            for _, plot in ipairs(plots:GetChildren()) do
                if plot ~= ownPlot then
                    local podiums = plot:FindFirstChild('AnimalPodiums')
                    if podiums then
                        for _, podium in ipairs(podiums:GetChildren()) do
                            local base = podium:FindFirstChild('Base')
                            local spawn = base and base:FindFirstChild('Spawn')
                            local attach = spawn and spawn:FindFirstChild('PromptAttachment')
                            if spawn and spawn:IsA('BasePart') and attach then
                                local prompt = attach:FindFirstChildWhichIsA('ProximityPrompt')
                                if prompt and prompt.Enabled then
                                    local distance = (spawn.Position-root.Position).Magnitude
                                    if distance < best then
                                        best, nearest = distance, {prompt=prompt,part=spawn,plot=plot}
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return nearest
        end
        local function homeTarget(plot)
            if not plot then return nil end
            local names = {'Deposit','Delivery','DropOff','Dropoff','Sell','Home','BaseSpawn','Spawn','DeliveryZone','DepositZone'}
            for _, name in ipairs(names) do
                local item = plot:FindFirstChild(name,true)
                if item and item:IsA('BasePart') then return item end
            end
            -- Fallback is an approximate plot-center point, NOT a verified storage trigger.
            local pivotOk, pivot = pcall(function() return plot:GetPivot() end)
            return pivotOk and pivot.Position or nil
        end
        local function locationOf(item)
            if typeof(item) == 'Vector3' then return item end
            return item and item.Position
        end
        local function navigate(destination, myId, maxSeconds)
            local character, humanoid, root = getCharacter()
            local goal = locationOf(destination)
            if not character or not goal then return false end
            local start = os.clock()
            local path = PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=5})
            local ok = pcall(function() path:ComputeAsync(root.Position, goal) end)
            local waypoints = (ok and path.Status == Enum.PathStatus.Success) and path:GetWaypoints() or {{Position=goal}}
            for _, waypoint in ipairs(waypoints) do
                if not active or myId ~= runId then return false end
                local updatedChar, hum, updatedRoot = getCharacter()
                if updatedChar ~= character then return false end
                if os.clock() - start >= maxSeconds then return false end
                hum.WalkSpeed = routeSpeed
                if waypoint.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
                hum:MoveTo(waypoint.Position)
                local deadline = os.clock() + math.min(3.5, math.max(0.2, maxSeconds-(os.clock()-start)))
                while active and myId == runId and os.clock() < deadline do
                    if (updatedRoot.Position-waypoint.Position).Magnitude < 4.5 then break end
                    task.wait(0.1)
                end
                if (updatedRoot.Position-waypoint.Position).Magnitude >= 5 then return false end
            end
            return active and myId == runId
        end
        local function activatePrompt(prompt)
            if not prompt or not prompt.Parent then return false end
            if type(fireproximityprompt) == 'function' then
                return pcall(function() fireproximityprompt(prompt) end)
            end
            return false
        end
        local function run(myId)
            while active and myId == runId do
                local char, hum, root = getCharacter()
                if not char then message('Waiting for character'); task.wait(1)
                elseif carryDetected(char) then
                    local plot = getOwnPlot()
                    local destination = homeTarget(plot)
                    if not plot then message('Own base not detected'); task.wait(1.5)
                    elseif not destination then message('Home destination not detected'); task.wait(1.5)
                    else
                        targetName = 'Own base'; updateUI(); message('Returning to base')
                        local reached = navigate(destination, myId, 24)
                        if reached then
                            message('At base - checking delivery')
                            task.wait(2)
                            if not carryDetected(char) then successfulDetections = successfulDetections + 1; message('Carry cleared / possible delivery')
                            else message('Still carrying: storage interaction may be required') end
                        else message('Base navigation failed / timed out') end
                        task.wait(0.7)
                    end
                else
                    local target = getTarget(root)
                    if not target then message('No available target prompts'); task.wait(1.5)
                    else
                        targetName = target.plot.Name .. '/' .. target.part.Name; updateUI()
                        message('Traveling to target')
                        local reached = navigate(target.part.Position, myId, 24)
                        if reached then
                            message('At target - attempt pickup')
                            totalAttempts = totalAttempts + 1
                            if not activatePrompt(target.prompt) then
                                message('Press interaction manually; prompt API unavailable')
                            end
                            local untilTime = os.clock() + 4
                            while active and myId == runId and os.clock() < untilTime and not carryDetected(char) do task.wait(0.15) end
                            if carryDetected(char) then message('Pickup detected')
                            else message('Pickup not confirmed; retry later') end
                        else message('Target navigation failed / timed out') end
                        task.wait(1.5)
                    end
                end
            end
        end
        local function setActive(value)
            if value == active then return end
            active = value; runId = runId + 1
            if active then message('Starting'); task.spawn(run, runId)
            else
                message('Stopped'); targetName = '-'
                local _, hum = getCharacter()
                if hum then hum:Move(Vector3.zero,false) end
            end
            updateUI()
        end
        local function make(class, parent, props)
            local object = Instance.new(class)
            for k,v in pairs(props or {}) do object[k] = v end
            object.Parent = parent; return object
        end
        local playerGui = localPlayer:WaitForChild('PlayerGui')
        local old = playerGui:FindFirstChild('VH4AutoRouteGui'); if old then old:Destroy() end
        panelGui = make('ScreenGui',playerGui,{Name='VH4AutoRouteGui',ResetOnSpawn=false})
        local panel = make('Frame',panelGui,{Size=UDim2.fromOffset(318,246),Position=UDim2.new(1,-333,0.45,-123),BackgroundColor3=Color3.fromRGB(20,22,29),BorderSizePixel=0,Active=true,Draggable=true})
        make('UICorner',panel,{CornerRadius=UDim.new(0,12)})
        make('UIStroke',panel,{Color=Color3.fromRGB(149,47,60),Thickness=1.5})
        local function label(value,y,size,color)
            return make('TextLabel',panel,{Text=value,Position=UDim2.fromOffset(14,y),Size=UDim2.new(1,-28,0,29),BackgroundTransparency=1,TextColor3=color or Color3.fromRGB(219,223,233),TextSize=size or 14,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
        end
        label('VAMPIRE V4  |  AUTO ROUTE (BETA)',12,16,Color3.fromRGB(254,96,115))
        statusLabel = label('STATUS  •  Idle',48,12)
        targetLabel = label('TARGET  •  -',77,12)
        speedLabel = label('ROUTE SPEED  •  60',106,12)
        button = make('TextButton',panel,{Text='START AUTO ROUTE',Position=UDim2.fromOffset(14,141),Size=UDim2.new(1,-28,0,35),Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),TextSize=13,BackgroundColor3=Color3.fromRGB(65,139,97)})
        make('UICorner',button,{CornerRadius=UDim.new(0,8)})
        button.Activated:Connect(function() setActive(not active) end)
        local slower = make('TextButton',panel,{Text='−  SPEED',Position=UDim2.fromOffset(14,184),Size=UDim2.fromOffset(132,27),TextSize=12,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(47,49,62)})
        local faster = make('TextButton',panel,{Text='+  SPEED',Position=UDim2.fromOffset(172,184),Size=UDim2.fromOffset(132,27),TextSize=12,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(47,49,62)})
        for _,b in ipairs({slower,faster}) do make('UICorner',b,{CornerRadius=UDim.new(0,6)}) end
        slower.Activated:Connect(function() routeSpeed=math.max(16,routeSpeed-5);updateUI() end)
        faster.Activated:Connect(function() routeSpeed=math.min(100,routeSpeed+5);updateUI() end)
        label('F6 START/STOP    •    F5 SHOW/HIDE',213,10,Color3.fromRGB(144,149,165))
        local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.F6 then setActive(not active)
            elseif input.KeyCode == Enum.KeyCode.F5 then panel.Visible = not panel.Visible end
        end)
        _G.VH4AutoRoute = {
            Start = function() setActive(true) end,
            Stop = function() setActive(false) end,
            Destroy = function() setActive(false); if inputConn then inputConn:Disconnect() end; if panelGui then panelGui:Destroy() end end,
            Toggle = function() setActive(not active) end,
            SetSpeed = function(speed) routeSpeed=math.clamp(tonumber(speed) or 60,16,100); updateUI() end,
            Status = function() return {active=active,state=state,attempts=totalAttempts,detectedReturns=successfulDetections,speed=routeSpeed,target=targetName} end,
        }
        print('[VH4] Auto Route experimental panel ready. F6 toggle, F5 panel; movement speed 60.')
    end
end

-- ============================================================================
-- VAMPIRE HUB V5 | ANDROID TOUCH CONTROLS
-- Adds touch-first controls around the existing V4 beta route, with no external downloads.
-- Route pickup/storage remain experimental and depend on game rules and prompt support.
-- ============================================================================
do
    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer
    if player then
        local guiParent = player:WaitForChild("PlayerGui")
        if _G.VH5Mobile and type(_G.VH5Mobile.Destroy) == "function" then
            pcall(_G.VH5Mobile.Destroy)
        end
        local old = guiParent:FindFirstChild("VH5MobileGui")
        if old then old:Destroy() end
        local gui = Instance.new("ScreenGui")
        gui.Name = "VH5MobileGui"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = false
        gui.DisplayOrder = 999
        gui.Parent = guiParent

        local c = {bg=Color3.fromRGB(19,20,29), card=Color3.fromRGB(35,37,51), accent=Color3.fromRGB(227,68,94), text=Color3.fromRGB(239,239,244), muted=Color3.fromRGB(171,174,190), green=Color3.fromRGB(53,147,107)}
        local function add(kind,parent,props)
            local x=Instance.new(kind)
            for k,v in pairs(props or {}) do x[k]=v end
            x.Parent=parent
            return x
        end
        local function corner(parent, r) add("UICorner", parent, {CornerRadius=UDim.new(0,r or 10)}) end
        local function lbl(parent,t,y,h,size,col)
            return add("TextLabel",parent,{BackgroundTransparency=1,Text=t,Position=UDim2.new(0,14,0,y),Size=UDim2.new(1,-28,0,h),Font=Enum.Font.Gotham,TextSize=size or 13,TextColor3=col or c.text,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
        end
        local body=add("Frame",gui,{Name="Panel",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(320,402),BackgroundColor3=c.bg,BorderSizePixel=0,Active=true})
        corner(body,16)
        add("UIStroke",body,{Color=c.accent,Thickness=1.5,Transparency=.15})
        local scaler=add("UIScale",body,{Scale=1})
        local function rescale()
            local cam=workspace.CurrentCamera
            if not cam then return end
            local v=cam.ViewportSize
            scaler.Scale=math.clamp(math.min((v.X-22)/320,(v.Y-34)/402),0.56,1.12)
        end
        rescale()
        local viewportConn
        local function watchCamera()
            if viewportConn then viewportConn:Disconnect();viewportConn=nil end
            local cam=workspace.CurrentCamera
            if cam then viewportConn=cam:GetPropertyChangedSignal("ViewportSize"):Connect(rescale) end
            rescale()
        end
        watchCamera()
        local cameraConn=workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)

        local header=add("Frame",body,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,48),Active=true})
        lbl(header,"VAMPIRE V5  /  ANDROID",11,26,16,c.accent).Font=Enum.Font.GothamBold
        local collapse=add("TextButton",header,{Text="−",Position=UDim2.new(1,-48,0,8),Size=UDim2.fromOffset(35,33),BackgroundColor3=c.card,TextColor3=c.text,TextSize=22,Font=Enum.Font.GothamBold})
        corner(collapse,8)
        local content=add("Frame",body,{BackgroundTransparency=1,Position=UDim2.fromOffset(0,48),Size=UDim2.new(1,0,1,-48)})
        local status=lbl(content,"ROUTE  •  loading",8,25,13,c.muted)
        local target=lbl(content,"TARGET  •  -",35,24,12,c.muted)
        local stats=lbl(content,"FPS  •  --      PING  •  --",65,22,12,c.text)
        local function btn(text,x,y,w,h,col)
            local b=add("TextButton",content,{Text=text,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=col or c.card,TextColor3=c.text,TextSize=13,Font=Enum.Font.GothamBold,AutoButtonColor=true})
            corner(b,10);return b
        end
        local toggle=btn("START AUTO ROUTE",14,100,292,43,c.green)
        local slow=btn("−  SPEED",14,153,139,42)
        local fast=btn("+  SPEED",167,153,139,42)
        local speed=lbl(content,"SPEED  •  60",201,22,13,c.text)
        local preset40=btn("40",14,234,88,40)
        local preset60=btn("60",116,234,88,40)
        local preset80=btn("80",218,234,88,40)
        lbl(content,"Route is beta • Pickup / Store not guaranteed",284,26,11,c.muted)
        local stop=btn("EMERGENCY STOP",14,315,292,34,c.accent)
        local fab=add("TextButton",gui,{Name="QuickOpen",Text="V5",Size=UDim2.fromOffset(54,54),Position=UDim2.new(1,-68,0.6,0),TextSize=18,Font=Enum.Font.GothamBold,TextColor3=c.text,BackgroundColor3=c.accent,Visible=false,Active=true})
        corner(fab,16)
        local function drag(node,handle)
            local dragging=false
            local anchorPoint, originalPos, dragInput
            local began=handle.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragging=true; anchorPoint=input.Position; originalPos=node.Position;dragInput=input
                end
            end)
            local ended=UIS.InputEnded:Connect(function(input)
                if input==dragInput then dragging=false;dragInput=nil end
            end)
            local changed=UIS.InputChanged:Connect(function(input)
                if not dragging then return end
                if input.UserInputType==Enum.UserInputType.MouseMovement or input==dragInput then
                    local delta=input.Position-anchorPoint
                    node.Position=UDim2.new(originalPos.X.Scale,originalPos.X.Offset+delta.X,originalPos.Y.Scale,originalPos.Y.Offset+delta.Y)
                end
            end)
            return {began,ended,changed}
        end
        local connections={}
        for _,x in ipairs(drag(body,header)) do table.insert(connections,x) end
        for _,x in ipairs(drag(fab,fab)) do table.insert(connections,x) end
        local function route()
            return _G.VH4AutoRoute
        end
        local function setSpeed(value)
            local r=route()
            if r and type(r.SetSpeed)=="function" then r.SetSpeed(value) end
        end
        local function snapshot()
            local r=route()
            if r and type(r.Status)=="function" then
                local ok,data=pcall(r.Status)
                if ok and type(data)=="table" then return data end
            end
            return {active=false,state="V4 route not loaded",speed=60,target="-"}
        end
        toggle.Activated:Connect(function() local r=route();if r and type(r.Toggle)=="function" then r.Toggle() end end)
        stop.Activated:Connect(function() local r=route();if r and type(r.Stop)=="function" then r.Stop() end end)
        slow.Activated:Connect(function() local s=snapshot();setSpeed(math.max(16,(s.speed or 60)-5)) end)
        fast.Activated:Connect(function() local s=snapshot();setSpeed(math.min(100,(s.speed or 60)+5)) end)
        preset40.Activated:Connect(function() setSpeed(40) end)
        preset60.Activated:Connect(function() setSpeed(60) end)
        preset80.Activated:Connect(function() setSpeed(80) end)
        collapse.Activated:Connect(function() body.Visible=false;fab.Visible=true end)
        fab.Activated:Connect(function() body.Visible=true;fab.Visible=false end)
        local fpsCount, lastUpdate, fps=0,os.clock(),0
        local updateConn=RunService.RenderStepped:Connect(function()
            fpsCount=fpsCount+1
            local now=os.clock()
            if now-lastUpdate < 0.75 then return end
            fps=math.floor(fpsCount/math.max(.01,now-lastUpdate)+.5)
            fpsCount=0;lastUpdate=now
            local s=snapshot()
            status.Text="ROUTE  •  "..tostring(s.state or "-")
            target.Text="TARGET  •  "..tostring(s.target or "-")
            speed.Text="SPEED  •  "..tostring(s.speed or 60)
            toggle.Text=s.active and "STOP AUTO ROUTE" or "START AUTO ROUTE"
            toggle.BackgroundColor3=s.active and c.accent or c.green
            local ping="--"
            pcall(function()
                local item=game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
                if item then ping=tostring(math.floor(item:GetValue()+.5)) end
            end)
            stats.Text="FPS  •  "..fps.."      PING  •  "..ping.." ms"
        end)
        _G.VH5Mobile={
            Show=function() body.Visible=true;fab.Visible=false end,
            Hide=function() body.Visible=false;fab.Visible=true end,
            Destroy=function()
                if updateConn then updateConn:Disconnect() end
                if viewportConn then viewportConn:Disconnect() end
                if cameraConn then cameraConn:Disconnect() end
                for _,conn in ipairs(connections) do conn:Disconnect() end
                if gui then gui:Destroy() end
            end,
        }
        print("[VH5] Android touch panel loaded")
    end
end
