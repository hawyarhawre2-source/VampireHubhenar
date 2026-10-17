-- Vampire Hub X4 Lite | standalone mobile controls | 2026-10-17
-- Lightweight Luau; no remote code and no executor-specific APIs.
-- Local changes to speed are not authoritative on Roblox servers.
local function start()
    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local player = Players.LocalPlayer
    if not player then return end
    local parent = player:WaitForChild("PlayerGui", 15)
    if not parent then return end
    if _G.VampireX4 and type(_G.VampireX4.Destroy) == "function" then
        pcall(_G.VampireX4.Destroy)
    end

    local state = {running=true, speed=false, dynamic=false, jump=false, lowFX=false, value=60}
    local originalSpeed, boundHumanoid = nil, nil
    local originalShadows = Lighting.GlobalShadows
    local events = {}
    local function connect(signal, fn)
        local c = signal:Connect(fn)
        table.insert(events, c)
        return c
    end
    local function hum()
        local char = player.Character
        return char and char:FindFirstChildOfClass("Humanoid")
    end
    local function restore()
        if boundHumanoid and boundHumanoid.Parent and originalSpeed then
            pcall(function() boundHumanoid.WalkSpeed = originalSpeed end)
        end
    end
    local function updateSpeed()
        local h = hum()
        if not h then return end
        if h ~= boundHumanoid then
            boundHumanoid = h
            originalSpeed = h.WalkSpeed
        end
        if state.speed then
            local requested = state.value
            if state.dynamic and h.MoveDirection.Magnitude < 0.05 then
                requested = originalSpeed or 16
            end
            if math.abs(h.WalkSpeed - requested) > 0.1 then
                h.WalkSpeed = requested
            end
        end
    end
    local C = {
        bg=Color3.fromRGB(17,18,29), card=Color3.fromRGB(38,40,58),
        pink=Color3.fromRGB(223,68,116), green=Color3.fromRGB(54,145,108),
        white=Color3.fromRGB(245,245,249), muted=Color3.fromRGB(177,178,193)
    }
    local gui=Instance.new("ScreenGui")
    gui.Name="VampireHubX4Lite"
    gui.ResetOnSpawn=false
    gui.DisplayOrder=9900
    gui.Parent=parent
    local function round(o, radius)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,radius or 12)
        c.Parent=o
    end
    local function label(parentObj, text, size, height)
        local t=Instance.new("TextLabel")
        t.BackgroundTransparency=1
        t.Text=text
        t.Size=UDim2.new(1,-24,0,height or 30)
        t.TextSize=size or 15
        t.Font=Enum.Font.GothamBold
        t.TextColor3=C.white
        t.TextXAlignment=Enum.TextXAlignment.Left
        t.Parent=parentObj
        return t
    end
    local root=Instance.new("Frame")
    root.Name="Panel"
    root.Size=UDim2.new(0,310,0,365)
    root.Position=UDim2.new(.5,-155,.5,-182)
    root.BackgroundColor3=C.bg
    root.BorderSizePixel=0
    root.Active=true
    root.Parent=gui
    round(root,16)
    local cap=label(root,"  VAMPIRE HUB X4  |  LITE",17,43)
    cap.Size=UDim2.new(1,-12,0,43)
    cap.TextColor3=C.pink
    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,-20,1,-91)
    scroll.Position=UDim2.new(0,10,0,48)
    scroll.BackgroundTransparency=1
    scroll.ScrollBarThickness=3
    scroll.CanvasSize=UDim2.new(0,0,0,340)
    scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.Parent=root
    local layout=Instance.new("UIListLayout")
    layout.Padding=UDim.new(0,7)
    layout.Parent=scroll
    local function button(text, fn)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(1,-5,0,41)
        b.BackgroundColor3=C.card
        b.BorderSizePixel=0
        b.Text=text
        b.TextSize=15
        b.Font=Enum.Font.GothamBold
        b.TextColor3=C.white
        b.Parent=scroll
        round(b,9)
        connect(b.Activated, function() if state.running then fn() end end)
        return b
    end
    local speedB, dynamicB, jumpB, fxB
    local valueB=button("TARGET SPEED: 60   [- / + BELOW]",function() end)
    speedB=button("SPEED: OFF",function() state.speed=not state.speed if not state.speed then restore() end end)
    dynamicB=button("DYNAMIC: OFF",function() state.dynamic=not state.dynamic end)
    button("- 5 SPEED",function() state.value=math.max(16,state.value-5) end)
    button("+ 5 SPEED",function() state.value=math.min(100,state.value+5) end)
    jumpB=button("INFINITE JUMP: OFF",function() state.jump=not state.jump end)
    fxB=button("LOW SHADOWS: OFF",function()
        state.lowFX=not state.lowFX
        Lighting.GlobalShadows=state.lowFX and false or originalShadows
    end)
    local status=Instance.new("TextLabel")
    status.BackgroundTransparency=1
    status.Size=UDim2.new(1,-15,0,27)
    status.Position=UDim2.new(0,10,1,-32)
    status.Text="FPS: --  |  Engine: ready"
    status.TextColor3=C.muted
    status.Font=Enum.Font.Gotham
    status.TextSize=12
    status.TextXAlignment=Enum.TextXAlignment.Left
    status.Parent=root
    local bubble=Instance.new("TextButton")
    bubble.Size=UDim2.new(0,60,0,56)
    bubble.Position=UDim2.new(0,12,.55,0)
    bubble.Text="X4"
    bubble.Font=Enum.Font.GothamBlack
    bubble.TextSize=19
    bubble.TextColor3=C.white
    bubble.BackgroundColor3=C.pink
    bubble.Visible=false
    bubble.Parent=gui
    round(bubble,16)
    local hide=Instance.new("TextButton")
    hide.Size=UDim2.new(0,50,0,31)
    hide.Position=UDim2.new(1,-59,0,6)
    hide.Text="HIDE"
    hide.TextColor3=C.white
    hide.BackgroundColor3=C.card
    hide.Font=Enum.Font.GothamBold
    hide.TextSize=12
    hide.Parent=root
    round(hide,8)
    connect(hide.Activated,function() root.Visible=false bubble.Visible=true end)
    connect(bubble.Activated,function() root.Visible=true bubble.Visible=false end)
    local stop=Instance.new("TextButton")
    stop.Size=UDim2.new(0,66,0,31)
    stop.Position=UDim2.new(1,-132,0,6)
    stop.Text="STOP"
    stop.BackgroundColor3=C.pink
    stop.TextColor3=C.white
    stop.TextSize=12
    stop.Font=Enum.Font.GothamBold
    stop.Parent=root
    round(stop,8)
    local function stopEverything()
        state.speed=false
        state.jump=false
        state.dynamic=false
        restore()
        Lighting.GlobalShadows=originalShadows
        state.lowFX=false
    end
    connect(stop.Activated,stopEverything)
    connect(UIS.JumpRequest,function()
        if state.running and state.jump then
            local h=hum()
            if h and h.Health>0 then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
    connect(player.CharacterAdded,function()
        boundHumanoid=nil
        originalSpeed=nil
    end)
    local samples=0
    local elapsed=0
    connect(RunService.Heartbeat,function(dt)
        if not state.running then return end
        samples=samples+1
        elapsed=elapsed+dt
        if elapsed<0.4 then return end
        local fps=math.floor(samples/elapsed+0.5)
        elapsed=0
        samples=0
        updateSpeed()
        speedB.Text="SPEED: "..(state.speed and "ON" or "OFF")
        dynamicB.Text="DYNAMIC: "..(state.dynamic and "ON" or "OFF")
        jumpB.Text="INFINITE JUMP: "..(state.jump and "ON" or "OFF")
        fxB.Text="LOW SHADOWS: "..(state.lowFX and "ON" or "OFF")
        valueB.Text="TARGET SPEED: "..state.value
        status.Text="FPS: "..fps.."  |  Engine: ready"
    end)
    local moving=false
    local dragStart, panelStart
    connect(root.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            moving=true
            dragStart=input.Position
            panelStart=root.Position
        end
    end)
    connect(UIS.InputChanged,function(input)
        if moving and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then
            local delta=input.Position-dragStart
            root.Position=UDim2.new(panelStart.X.Scale,panelStart.X.Offset+delta.X,panelStart.Y.Scale,panelStart.Y.Offset+delta.Y)
        end
    end)
    connect(UIS.InputEnded,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then moving=false end
    end)
    local function destroy()
        state.running=false
        stopEverything()
        for _,c in ipairs(events) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
        if _G.VampireX4 then _G.VampireX4=nil end
    end
    _G.VampireX4={Destroy=destroy,Stop=stopEverything}
    print("[Vampire X4 Lite] Loaded. Mobile UI ready.")
end
local ok,err=pcall(start)
if not ok then warn("[Vampire X4 Lite] "..tostring(err)) end
