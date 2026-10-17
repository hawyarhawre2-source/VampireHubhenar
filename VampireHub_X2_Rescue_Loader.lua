-- Vampire Hub X2 Rescue Loader v1.0
-- Shows a mobile status window before attempting the existing X2 script.
-- Does not attempt to bypass game restrictions; requires an environment supporting HttpGet/loadstring.
local URL = "https://raw.githubusercontent.com/hawyarhawre2-source/VampireHubhenar/main/VampireHub_X2_Ultimate_Android.lua"
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
if not player then warn("[VHX Rescue] LocalPlayer unavailable; run client-side."); return end
local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then warn("[VHX Rescue] PlayerGui unavailable."); return end
local old = playerGui:FindFirstChild("VHX2Rescue")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "VHX2Rescue"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 100000
gui.Parent = playerGui
local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(.5,.5)
frame.Position = UDim2.fromScale(.5,.45)
frame.Size = UDim2.fromOffset(310,226)
frame.BackgroundColor3 = Color3.fromRGB(19,21,32)
frame.BorderSizePixel = 0
frame.Parent = gui
local scale = Instance.new("UIScale")
scale.Scale = math.clamp((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 400)/360,.68,1)
scale.Parent = frame
local corner = Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,14)
corner.Parent=frame
local stroke=Instance.new("UIStroke")
stroke.Color=Color3.fromRGB(215,57,85)
stroke.Thickness=1.5
stroke.Parent=frame
local heading=Instance.new("TextLabel")
heading.BackgroundTransparency=1
heading.Size=UDim2.new(1,-24,0,36)
heading.Position=UDim2.fromOffset(12,8)
heading.Font=Enum.Font.GothamBold
heading.Text="VAMPIRE X2  |  RESCUE"
heading.TextSize=17
heading.TextColor3=Color3.fromRGB(255,115,141)
heading.Parent=frame
local status=Instance.new("TextLabel")
status.BackgroundTransparency=1
status.Position=UDim2.fromOffset(14,46)
status.Size=UDim2.new(1,-28,0,103)
status.Font=Enum.Font.Code
status.TextSize=13
status.TextWrapped=true
status.TextYAlignment=Enum.TextYAlignment.Top
status.TextColor3=Color3.fromRGB(230,233,244)
status.Text="READY\nPress LOAD to check the hosted X2 file."
status.Parent=frame
local function button(text,x)
    local b=Instance.new("TextButton")
    b.Position=UDim2.fromOffset(x,157)
    b.Size=UDim2.fromOffset(132,44)
    b.BackgroundColor3=Color3.fromRGB(117,39,64)
    b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold
    b.TextSize=14
    b.Text=text
    b.Parent=frame
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,9)
    c.Parent=b
    return b
end
local loadButton=button("LOAD X2",14)
local closeButton=button("CLOSE",164)
local busy=false
local lastError=""
local function report(message)
    status.Text=message
    print("[VHX Rescue] "..message)
end
closeButton.Activated:Connect(function() gui:Destroy() end)
loadButton.Activated:Connect(function()
    if busy then return end
    busy=true
    loadButton.Text="LOADING..."
    report("1/3 Downloading X2 ...")
    task.spawn(function()
        local okFetch,source=pcall(function()
            if type(game.HttpGet)~="function" then error("game:HttpGet is unavailable") end
            return game:HttpGet(URL)
        end)
        if not okFetch then
            lastError="DOWNLOAD ERROR: "..tostring(source)
            report(lastError); loadButton.Text="RETRY";busy=false;return
        end
        if type(source)~="string" or #source<100 then
            lastError="INVALID DOWNLOAD / empty source"
            report(lastError);loadButton.Text="RETRY";busy=false;return
        end
        report("2/3 Download OK ("..tostring(#source).." bytes). Compiling ...")
        if type(loadstring)~="function" then
            lastError="COMPILER ERROR: loadstring is unavailable"
            report(lastError);loadButton.Text="RETRY";busy=false;return
        end
        local okCompile,fn=pcall(loadstring,source)
        if not okCompile or type(fn)~="function" then
            lastError="COMPILE ERROR: "..tostring(fn)
            report(lastError);loadButton.Text="RETRY";busy=false;return
        end
        report("3/3 Compiled. Running X2 ...")
        task.wait(.15)
        local finished=false
        task.delay(12,function()
            if gui.Parent and not finished then report("X2 is still running after 12s. It may be waiting on game objects or initialization. This is NOT a confirmed crash.") end
        end)
        local okRun,runErr=pcall(fn)
        finished=true
        if okRun then
            report("X2 returned without a top-level error. Check whether its GUI appeared.")
        else
            lastError="RUNTIME ERROR: "..tostring(runErr)
            report(lastError)
        end
        busy=false
        loadButton.Text="RETRY"
    end)
end)
print("[VHX Rescue] Mobile diagnostic launcher ready")
