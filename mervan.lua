--[[
    Mervan Services v1.0
    Tabs: Listener | Pinned | Settings
    Toggle: RightShift (PC) | S button (Mobile)
]]

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UIS                = game:GetService("UserInputService")
local MPS                = game:GetService("MarketplaceService")
local HS                 = game:GetService("HttpService")

local player    = Players.LocalPlayer
local CoreGui   = game:GetService("CoreGui")

if CoreGui:FindFirstChild("MervanUI") then
    CoreGui.MervanUI:Destroy()
end

-- THEME
local C = {
    bg        = Color3.fromRGB(8,   8,   11),  -- Deep void black
    surface   = Color3.fromRGB(14,  14,  18),  -- Rich dark surface
    surfaceHi = Color3.fromRGB(22,  20,  26),  -- Elevated surface
    border    = Color3.fromRGB(50,  42,  65),  -- Purple-tinted border
    borderHi  = Color3.fromRGB(120, 90, 180),  -- Vivid purple highlight
    accent    = Color3.fromRGB(180, 120, 255), -- Mervan signature purple
    accentDim = Color3.fromRGB(90,  50, 140),  -- Dimmed purple
    green     = Color3.fromRGB(0,   255, 127), -- LiveDot green
    greenDim  = Color3.fromRGB(20,  70,  45),
    red       = Color3.fromRGB(255, 90,  90),
    redDim    = Color3.fromRGB(60,  18,  18),
    amber     = Color3.fromRGB(255, 200, 60),
    text      = Color3.fromRGB(245, 240, 255), -- Slightly purple-tinted white
    textMuted = Color3.fromRGB(160, 140, 190), -- Muted lavender
    textDim   = Color3.fromRGB(80,  65, 105),  -- Dim purple-gray
}

local isMobile = UIS.TouchEnabled
local vp       = workspace.CurrentCamera.ViewportSize
local PW       = isMobile and math.floor(vp.X * 0.92) or 780
local PH       = isMobile and math.floor(vp.Y * 0.75) or 480
local TH       = isMobile and 46 or 52
local FH       = isMobile and 46 or 50
local TABH     = isMobile and 36 or 34
local BH       = isMobile and 36 or 28
local FS       = 13
local FM       = isMobile and 15 or 14
local FL       = isMobile and 17 or 16
local autoSpeed = 100
local PINNED_FILE = "mervan_pinned.json"
local KEY_FILE    = "mervan_key.txt"
local SETTINGS_FILE_M = "mervan_settings.json"
local latestEvent = nil -- {sigType, id}
local showProductNames = false
local quickFireKey = nil -- Enum.KeyCode or nil

-- save/load extra settings
local function saveMervanSettings()
    pcall(function()
        if writefile then
            local data = {
                showNames = showProductNames,
                quickFireKey = quickFireKey and quickFireKey.Name or nil,
            }
            writefile(SETTINGS_FILE_M, HS:JSONEncode(data))
        end
    end)
end
local function loadMervanSettings()
    pcall(function()
        if isfile and isfile(SETTINGS_FILE_M) then
            local d = HS:JSONDecode(readfile(SETTINGS_FILE_M))
            if d then
                showProductNames = d.showNames == true
                if d.quickFireKey then
                    pcall(function() quickFireKey = Enum.KeyCode[d.quickFireKey] end)
                end
            end
        end
    end)
end
loadMervanSettings()

-- resolve product name from id
local nameCache = {}
local function getProductName(id, sigType)
    if nameCache[id] then return nameCache[id] end
    local name = nil
    pcall(function()
        if sigType == "Product" then
            local info = MPS:GetProductInfo(id, Enum.InfoType.Product)
            if info and info.Name then name = info.Name end
        elseif sigType == "Gamepass" then
            local info = MPS:GetProductInfo(id, Enum.InfoType.GamePass)
            if info and info.Name then name = info.Name end
        else
            local info = MPS:GetProductInfo(id, Enum.InfoType.Asset)
            if info and info.Name then name = info.Name end
        end
    end)
    if name then nameCache[id] = name end
    return name
end

local TIF = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TIM = TweenInfo.new(0.30, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TIS = TweenInfo.new(0.50, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local resizing = false -- Global flag to prevent dragging while resizing

-- HELPERS
local function corner(inst, r)
    local c = Instance.new("UICorner", inst)
    c.CornerRadius = UDim.new(0, r or 10)
    return c
end

local function stroke(inst, col, t)
    local s = Instance.new("UIStroke", inst)
    s.Color     = col or C.border
    s.Thickness = t or 1
    return s
end

local function tw(inst, info, props)
    TweenService:Create(inst, info, props):Play()
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) and not resizing then
            dragging = true
            dragStart = inp.Position
            startPos = frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- SCREEN GUI
local sg = Instance.new("ScreenGui")
sg.Name            = "MervanUI"
sg.ResetOnSpawn    = false
sg.ZIndexBehavior  = Enum.ZIndexBehavior.Global -- Use Global to ensure dock is always on top
sg.IgnoreGuiInset  = true
sg.Parent          = CoreGui

-- LOADING SCREEN
local lf = Instance.new("Frame")
lf.Size             = UDim2.new(0, PW, 0, PH)
lf.Position         = UDim2.new(0, (vp.X - PW) / 2, 0, (vp.Y - PH) / 2)
lf.BackgroundColor3 = C.bg
lf.BorderSizePixel  = 0
lf.ZIndex           = 100
lf.Parent           = sg

-- Premium glowing border on loading screen
local lfStroke = Instance.new("UIStroke")
lfStroke.Color       = Color3.fromRGB(130, 80, 210)
lfStroke.Thickness   = 1.5
lfStroke.Transparency = 0.2
lfStroke.Parent      = lf
corner(lf, 16)
stroke(lf, C.border, 1)
makeDraggable(lf) -- Make loading/key part moveable

local lglow = Instance.new("Frame")
lglow.Size             = UDim2.new(0, 0, 0, 2)
lglow.BackgroundColor3 = C.accent
lglow.BorderSizePixel  = 0
lglow.ZIndex           = 101
lglow.Parent           = lf
corner(lglow, 2)

local llogo = Instance.new("TextLabel")
llogo.Size               = UDim2.new(1, 0, 0, 60)
llogo.Position           = UDim2.new(0, 0, 0.30, 0)
llogo.BackgroundTransparency = 1
llogo.Text               = "Mervan Services"
llogo.TextColor3         = C.accent
llogo.TextSize           = 40
llogo.Font               = Enum.Font.GothamBold
llogo.ZIndex             = 101
llogo.Parent             = lf

-- Mervan Services subtitle on loading screen
local lsubtitle = Instance.new("TextLabel")
lsubtitle.Size               = UDim2.new(1, 0, 0, 22)
lsubtitle.Position           = UDim2.new(0, 0, 0.43, 0)
lsubtitle.BackgroundTransparency = 1
lsubtitle.Text               = "S E R V I C E S"
lsubtitle.TextColor3         = C.accentDim
lsubtitle.TextSize           = 11
lsubtitle.Font               = Enum.Font.GothamBold
lsubtitle.TextXAlignment     = Enum.TextXAlignment.Center
lsubtitle.ZIndex             = 101
lsubtitle.Parent             = lf

-- Decorative divider line
local ldivider = Instance.new("Frame")
ldivider.Size                = UDim2.new(0, 160, 0, 1)
ldivider.Position            = UDim2.new(0.5, -80, 0.52, 0)
ldivider.BackgroundColor3    = C.accentDim
ldivider.BorderSizePixel     = 0
ldivider.BackgroundTransparency = 0.4
ldivider.ZIndex              = 101
ldivider.Parent              = lf

local lsub = Instance.new("TextLabel")
lsub.Size               = UDim2.new(1, 0, 0, 22)
lsub.Position           = UDim2.new(0, 0, 0.30, 64)
lsub.BackgroundTransparency = 1
lsub.Text               = "Product Spoofer  ·  v3.4 BETA"
lsub.TextColor3         = C.textDim
lsub.TextSize           = 13
lsub.Font               = Enum.Font.Gotham
lsub.TextXAlignment     = Enum.TextXAlignment.Center
lsub.ZIndex             = 101
lsub.Parent             = lf

local spinF = Instance.new("Frame")
spinF.Size               = UDim2.new(0, 60, 0, 14)
spinF.Position           = UDim2.new(0.5, -30, 0.62, 0)
spinF.BackgroundTransparency = 1
spinF.ZIndex             = 101
spinF.Parent             = lf

local dots = {}
local dotRestY = {}
for i = 1, 4 do
    local d = Instance.new("Frame")
    d.Size                 = UDim2.new(0, 10, 0, 10)
    d.Position             = UDim2.new(0, (i - 1) * 18, 0.5, -5)
    d.BackgroundColor3     = C.accent
    d.BackgroundTransparency = 0.3
    d.BorderSizePixel      = 0
    d.ZIndex               = 102
    d.Parent               = spinF
    corner(d, 999)
    dots[i] = d
    dotRestY[i] = d.Position
    d.Visible = false -- Hidden until key is entered
end

local pbg = Instance.new("Frame")
pbg.Size             = UDim2.new(0, PW * 0.55, 0, 3)
pbg.Position         = UDim2.new(0.5, -PW * 0.275, 0.75, 0)
pbg.BackgroundColor3 = C.surfaceHi
pbg.BorderSizePixel  = 0
pbg.ZIndex           = 101
pbg.Visible          = false -- Hidden until key is entered
pbg.Parent           = lf
corner(pbg, 2)

local pbar = Instance.new("Frame")
pbar.Size             = UDim2.new(0, 0, 1, 0)
pbar.BackgroundColor3 = C.accent
pbar.BorderSizePixel  = 0
pbar.ZIndex           = 102
pbar.Parent           = pbg
corner(pbar, 2)

local lstat = Instance.new("TextLabel")
lstat.Size               = UDim2.new(1, 0, 0, 20)
lstat.Position           = UDim2.new(0, 0, 0.78, 10)
lstat.BackgroundTransparency = 1
lstat.Text               = "Enter your key below..."
lstat.TextColor3         = C.textMuted
lstat.TextSize           = 13
lstat.Font               = Enum.Font.Gotham
lstat.TextXAlignment     = Enum.TextXAlignment.Center
lstat.ZIndex             = 101
lstat.Parent           = lf

local ldiscord = Instance.new("TextButton")
ldiscord.Size               = UDim2.new(0, 140, 0, 24)
ldiscord.Position           = UDim2.new(1, -150, 1, -30)
ldiscord.BackgroundTransparency = 1
ldiscord.Text               = "discord.gg/mervan"
ldiscord.TextColor3         = C.textDim
ldiscord.TextSize           = 13
ldiscord.Font               = Enum.Font.Gotham
ldiscord.TextXAlignment     = Enum.TextXAlignment.Right
ldiscord.ZIndex             = 101
ldiscord.Parent             = lf

ldiscord.MouseButton1Click:Connect(function()
    pcall(setclipboard, "https://discord.gg/mervan")
    ldiscord.Text = "Copied!"
    ldiscord.TextColor3 = C.accent
    task.wait(2)
    ldiscord.Text = "discord.gg/mervan"
    ldiscord.TextColor3 = C.textDim
end)

ldiscord.MouseEnter:Connect(function() tw(ldiscord, TIF, {TextColor3 = C.textMuted}) end)
ldiscord.MouseLeave:Connect(function() if ldiscord.Text == "discord.gg/mervan" then tw(ldiscord, TIF, {TextColor3 = C.textDim}) end end)

-- KEY SYSTEM UI
local kf = Instance.new("Frame")
kf.Size             = UDim2.new(0, 320, 0, 42)
kf.Position         = UDim2.new(0.5, -160, 0.6, 0) -- Adjusted to sit below logo
kf.BackgroundColor3 = C.surfaceHi
kf.BorderSizePixel  = 0
kf.ZIndex           = 105
kf.Visible          = true
kf.Parent           = lf
corner(kf, 8)
stroke(kf, C.border, 1)

local kb = Instance.new("TextBox")
kb.Size             = UDim2.new(1, -90, 1, 0)
kb.Position         = UDim2.new(0, 12, 0, 0)
kb.BackgroundTransparency = 1
kb.PlaceholderText  = "Enter Mervan Key..."
kb.PlaceholderColor3 = C.textDim
kb.Text             = ""
pcall(function()
    if isfile and isfile(KEY_FILE) then
        local rawKey = readfile(KEY_FILE)
        kb.Text = string.gsub(rawKey or "", "%s+", "")
    end
end)
kb.TextColor3       = C.text
kb.TextSize         = 13
kb.Font             = Enum.Font.Gotham
kb.TextXAlignment   = Enum.TextXAlignment.Left
kb.ClearTextOnFocus = false
kb.ZIndex           = 106
kb.Parent           = kf

local kbtn = Instance.new("TextButton")
kbtn.Size             = UDim2.new(0, 75, 1, -10)
kbtn.Position         = UDim2.new(1, -80, 0, 5)
kbtn.BackgroundColor3 = C.bg
kbtn.Text             = "Enter"
kbtn.TextColor3       = C.accent
kbtn.TextSize         = 12
kbtn.Font             = Enum.Font.Gotham
kbtn.BorderSizePixel  = 0
kbtn.AutoButtonColor  = false
kbtn.ZIndex           = 106
kbtn.Parent           = kf
corner(kbtn, 6)
stroke(kbtn, C.accentDim, 1)

kbtn.MouseEnter:Connect(function() tw(kbtn, TIF, {BackgroundColor3 = C.accentDim, TextColor3 = C.bg}) end)
kbtn.MouseLeave:Connect(function() tw(kbtn, TIF, {BackgroundColor3 = C.bg, TextColor3 = C.accent}) end)

-- Dynamic resizing
local function updateKeyBox()
    local ts = game:GetService("TextService")
    local size = ts:GetTextSize(kb.Text, kb.TextSize, kb.Font, Vector2.new(1000, 42))
    local newWidth = math.clamp(size.X + 110, 320, 580)
    tw(kf, TIF, {Size = UDim2.new(0, newWidth, 0, 42), Position = UDim2.new(0.5, -newWidth/2, 0.6, 0)})
end
kb:GetPropertyChangedSignal("Text"):Connect(updateKeyBox)
updateKeyBox()

-- LOADING ANIMATION (Heartbeat, runs before anything else can crash)
do
    local RS = game:GetService("RunService")
    local _e,_ls,_f = 0,0,false
    local SD = 0.5
    local BOUNCE_CYCLE = 0.6 -- full wave cycle time
    local BOUNCE_DELAY = 0.12 -- stagger per dot
    local _m = {
        {t="Initializing...",p=0.1},{t="Hooking signals...",p=0.35},
        {t="Loading components...",p=0.6},{t="Almost ready...",p=0.85},{t="Done!",p=1},
    }
    local T = #_m*SD+0.3
    local _lc
    local function startLoading()
        kf.Visible = false
        pbg.Visible = true; lstat.Visible = true
        for _, d in ipairs(dots) do d.Visible = true end
        
        _lc = RS.Heartbeat:Connect(function(dt)
            if _f then return end
            _e=_e+dt
            -- Bounce dots in a wave pattern
            for i=1,4 do
                local phase = (_e - (i-1)*BOUNCE_DELAY) % BOUNCE_CYCLE
                local norm = phase / BOUNCE_CYCLE
                local bounce = math.sin(norm * math.pi) -- 0->1->0 smooth arc
                local yOff = -bounce * 8 -- bounce up 8 pixels
                local rest = dotRestY[i]
                dots[i].Position = UDim2.new(rest.X.Scale, rest.X.Offset, rest.Y.Scale, rest.Y.Offset + yOff)
                dots[i].BackgroundTransparency = 0.3 - bounce * 0.3 -- gets fully opaque at peak
                dots[i].Size = UDim2.new(0, 10 + bounce*3, 0, 10 + bounce*3) -- slight scale
            end
            -- Step through loading messages
            local c=math.min(math.floor(_e/SD)+1,#_m)
            if c~=_ls then _ls=c; lstat.Text=_m[c].t
                tw(pbar,TweenInfo.new(0.45,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(_m[c].p,0,1,0)})
            end
            if _e>=T then
                _f=true; _lc:Disconnect()
                -- Smooth fade out all loading elements
                local fadeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                tw(lf,fadeInfo,{BackgroundTransparency=1})
                tw(llogo,fadeInfo,{TextTransparency=1})
                tw(lsub,fadeInfo,{TextTransparency=1})
                tw(lstat,fadeInfo,{TextTransparency=1})
                tw(pbg,fadeInfo,{BackgroundTransparency=1})
                tw(pbar,fadeInfo,{BackgroundTransparency=1})
                tw(lglow,fadeInfo,{BackgroundTransparency=1})
                for _,d in ipairs(dots) do tw(d,fadeInfo,{BackgroundTransparency=1,Size=UDim2.new(0,0,0,0)}) end
                local _ft=0; local _fc
                _fc=RS.Heartbeat:Connect(function(d2) _ft=_ft+d2
                    if _ft<0.45 then return end; _fc:Disconnect()
                    lf.Visible=false; pcall(function() lf:Destroy() end)
                    local _p=sg:FindFirstChild("Panel")
                    if _p then
                        _p.Visible=true; _p.Size=UDim2.new(0,PW,0,PH); _p.BackgroundTransparency = 1
                        tw(_p,TweenInfo.new(0.6,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=0.15})
                        local _tt=0; local _tc
                        _tc=RS.Heartbeat:Connect(function(d3) _tt=_tt+d3
                            if _tt<0.25 then return end; _tc:Disconnect()
                            -- Welcome toast
                            pcall(function()
                                local wt=Instance.new("Frame")
                                wt.Size=UDim2.new(0,265,0,76); wt.Position=UDim2.new(1,10,1,-96)
                                wt.BackgroundColor3=C.surface; wt.BorderSizePixel=0
                                wt.ZIndex=200; wt.BackgroundTransparency=1; wt.Parent=sg
                                corner(wt,10); stroke(wt,C.accent,1)
                                local wb=Instance.new("Frame")
                                wb.Size=UDim2.new(0,3,1,-14); wb.Position=UDim2.new(0,7,0,7)
                                wb.BackgroundColor3=C.accent
                                wb.BorderSizePixel=0; wb.ZIndex=201; wb.Parent=wt; corner(wb,2)
                                local function ml(tx,y,sz,co,bo)
                                    local l=Instance.new("TextLabel")
                                    l.Size=UDim2.new(1,-20,0,sz+5); l.Position=UDim2.new(0,17,0,y)
                                    l.BackgroundTransparency=1; l.Text=tx; l.TextColor3=co
                                    l.TextSize=sz; l.ZIndex=201; l.Parent=wt
                                    l.Font=bo and Enum.Font.GothamBold or Enum.Font.Gotham
                                    l.TextXAlignment=Enum.TextXAlignment.Left
                                end
                                ml("✦ Mervan Loaded",7,14,C.accent,true)
                                ml("mervan services",30,11,C.accentDim,false)
                                ml("discord.gg/mervan",48,10,C.textDim,false)
                                tw(wt,TIM,{BackgroundTransparency=0,Position=UDim2.new(1,-275,1,-96)})
                                local _wt=0; local _wc
                                _wc=RS.Heartbeat:Connect(function(d4) _wt=_wt+d4
                                    if _wt<4 then return end; _wc:Disconnect()
                                    tw(wt,TIM,{BackgroundTransparency=1,Position=UDim2.new(1,10,1,-96)})
                                    local _x=0; local _xc
                                    _xc=RS.Heartbeat:Connect(function(d5) _x=_x+d5
                                        if _x>=0.35 then _xc:Disconnect(); pcall(function() wt:Destroy() end) end
                                    end)
                                end)
                            end)
                        end)
                    end
                end)
            end
        end)
    end

    local VALID_KEY = "bunnibunnibunnifakbunilovebuniokaybunimeowbunibunibuni"
    local function onVerify()
        local inputKey = string.gsub(kb.Text, "%s+", "")
        if inputKey == VALID_KEY then
            kb.TextEditable = false
            kbtn.Text = "Checking..."; kbtn.TextColor3 = C.textMuted
            lstat.Text = "Checking key..."
            
            -- Simple dot animation for "Checking..."
            task.spawn(function()
                local dots = ""
                while kbtn.Text:find("Checking") do
                    kbtn.Text = "Checking" .. dots
                    lstat.Text = "Checking key" .. dots
                    dots = dots .. "."
                    if #dots > 3 then dots = "" end
                    task.wait(0.4)
                end
            end)
            
            task.wait(1.2) -- Fake delay
            pcall(function() if writefile then writefile(KEY_FILE, inputKey) end end)
            kbtn.Text = "Success!"; kbtn.BackgroundColor3 = C.accent; kbtn.TextColor3 = C.bg
            task.wait(0.5)
            startLoading()
        else
            kbtn.Text = "Invalid!"; kbtn.BackgroundColor3 = C.redDim; kbtn.TextColor3 = C.red
            task.wait(0.8)
            kbtn.Text = "Enter"; kbtn.BackgroundColor3 = C.bg; kbtn.TextColor3 = C.accent
        end
    end

    kbtn.MouseButton1Click:Connect(onVerify)
    kb.FocusLost:Connect(function(enter) if enter then onVerify() end end)
    
    -- Auto-login if key is saved
    if kb.Text ~= "" then
        task.delay(0.25, onVerify)
    end
end

-- MAIN PANEL
local panel = Instance.new("Frame")
panel.Name                 = "Panel"
panel.Size                 = UDim2.new(0, PW, 0, PH)
panel.Position             = UDim2.new(0, (vp.X - PW) / 2, 0, (vp.Y - PH) / 2)
panel.BackgroundColor3     = C.bg
panel.BorderSizePixel      = 0
panel.ClipsDescendants     = false
panel.BackgroundTransparency = 1
panel.Visible              = false
panel.ZIndex               = 1
panel.Parent               = sg
corner(panel, 12)
local pst = stroke(panel, Color3.fromRGB(255, 255, 255), 1.5)
pst.Transparency = 0.85
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 120))
}
grad.Parent = pst
panel.ClipsDescendants     = false -- Ensure nothing is clipped

-- TAB BAR (floating pill at bottom)
local tabBar = Instance.new("Frame")
tabBar.Name             = "TabBar"
tabBar.Size             = UDim2.new(0.35, 0, 0, BH) -- Match button height
tabBar.Position         = UDim2.new(0.5, 0, 1, -20) -- Aligned with bottom of buttons
tabBar.AnchorPoint      = Vector2.new(0.5, 1)
tabBar.BackgroundColor3 = C.surfaceHi
tabBar.BackgroundTransparency = 1 -- Outline only as requested
tabBar.BorderSizePixel  = 0
tabBar.ClipsDescendants = false
tabBar.ZIndex           = 500
tabBar.Visible          = true
tabBar.Parent           = panel
corner(tabBar, 8)
local tst = stroke(tabBar, Color3.fromRGB(255, 255, 255), 1.5)
tst.Transparency = 0.755

-- UIListLayout removed to prevent layout bugs


-- Removed tabInner to avoid UIListLayout bugs
local countLabel = Instance.new("TextLabel")
countLabel.Size             = UDim2.new(0, 140, 0, 20)
countLabel.Position         = UDim2.new(0, 20, 1, -34) -- Vertically centered with dock (20+14)
countLabel.AnchorPoint      = Vector2.new(0, 0.5)
countLabel.BackgroundTransparency = 1
countLabel.Text             = "0 events captured"
countLabel.TextColor3       = C.textDim
countLabel.TextSize         = FS
countLabel.Font             = Enum.Font.Gotham
countLabel.TextXAlignment   = Enum.TextXAlignment.Left
countLabel.ZIndex           = 500
countLabel.Parent           = panel

-- DRAG logic handled by makeDraggable below Title Bar setup

-- RESIZE HANDLE
local h = Instance.new("Frame")
h.Size             = UDim2.new(0, 18, 0, 18)
h.Position         = UDim2.new(1, -20, 1, -25) -- Centered vertically with dock area
h.AnchorPoint      = Vector2.new(1, 1)
h.BackgroundColor3 = C.surfaceHi
h.BorderSizePixel  = 0
h.ZIndex           = 10
h.Parent           = panel
corner(h, 4)
stroke(h, C.borderHi, 1)

    for i = 1, 3 do
        local d = Instance.new("Frame")
        d.Size             = UDim2.new(0, 2, 0, 2)
        d.Position         = UDim2.new(0, 3 + (i - 1) * 4, 0, 3 + (3 - i) * 4)
        d.BackgroundColor3 = C.textDim
        d.BorderSizePixel  = 0
        d.ZIndex           = 11
        d.Parent           = h
        corner(d, 1)
    end

    local rs, ssz
    h.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            rs       = i.Position
            ssz      = panel.AbsoluteSize
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if resizing and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - rs
            panel.Size = UDim2.new(0, math.max(300, ssz.X + d.X), 0, math.max(200, ssz.Y + d.Y))
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

-- TITLE BAR
local tb = Instance.new("Frame")
tb.Name                 = "TitleBar"
tb.Size                 = UDim2.new(1, 0, 0, TH)
tb.BackgroundColor3     = C.bg
tb.BackgroundTransparency = 0
tb.BorderSizePixel      = 0
tb.ZIndex               = 400
tb.Parent               = panel
corner(tb, 12)

local tbFill = Instance.new("Frame")
tbFill.Size             = UDim2.new(1, 0, 0, 22)
tbFill.Position         = UDim2.new(0, 0, 1, -22)
tbFill.BackgroundColor3 = C.bg
tbFill.BackgroundTransparency = 0
tbFill.BorderSizePixel  = 0
tbFill.ZIndex           = tb.ZIndex
tbFill.Parent           = tb

local tbLine = Instance.new("Frame")
tbLine.Size             = UDim2.new(1, 0, 0, 1)
tbLine.Position         = UDim2.new(0, 0, 1, 0)
tbLine.BackgroundColor3 = C.border
tbLine.BorderSizePixel  = 0
tbLine.ZIndex           = tb.ZIndex + 2 -- Higher ZIndex
tbLine.Parent           = tb

tb.InputBegan:Connect(function(inp)
    -- This handles title bar drag
end)
makeDraggable(panel, tb) -- Connect dragging to title bar

local liveDot = Instance.new("Frame")
liveDot.Size             = UDim2.new(0, 9, 0, 9)
liveDot.Position         = UDim2.new(0, 18, 0.5, 0)
liveDot.AnchorPoint      = Vector2.new(0.5, 0.5)
liveDot.BackgroundColor3 = C.green
liveDot.BorderSizePixel  = 0
liveDot.ZIndex           = tb.ZIndex + 3
liveDot.Parent           = tb
corner(liveDot, 999)

local liveLabel = Instance.new("TextLabel")
liveLabel.Size               = UDim2.new(0, 46, 0, 20)
liveLabel.Position           = UDim2.new(0, 28, 0.5, -10)
liveLabel.BackgroundTransparency = 1
liveLabel.Text               = "LIVE"
liveLabel.TextColor3         = C.green
liveLabel.TextSize           = 10
liveLabel.Font               = Enum.Font.GothamBold
liveLabel.TextXAlignment     = Enum.TextXAlignment.Left
liveLabel.ZIndex             = tb.ZIndex + 2
liveLabel.Parent             = tb

-- Clean opacity-only pulse (like a broadcast indicator)
do
    local _RS2 = game:GetService("RunService")
    local _pt = 0
    _RS2.Heartbeat:Connect(function(dt)
        if not sg.Parent then return end
        _pt = _pt + dt
        -- Smooth fade: fully opaque -> 40% transparent -> back
        liveDot.BackgroundTransparency = 0.2 + 0.2 * math.sin(_pt * 3)
    end)
end

local titleText = Instance.new("TextLabel")
titleText.Size               = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text               = "Mervan Services"
titleText.TextColor3         = C.text
titleText.TextXAlignment     = Enum.TextXAlignment.Center -- Center the title
titleText.TextSize           = 17 -- Mervan Services branding
titleText.Font               = Enum.Font.GothamBold
titleText.Active             = false
titleText.Selectable         = false
titleText.ZIndex             = tb.ZIndex + 2
titleText.Parent             = tb

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 28, 0, 28)
closeBtn.Position         = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = C.surfaceHi
closeBtn.Text             = "X"
closeBtn.TextColor3       = C.textMuted
closeBtn.TextSize         = 14
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.BorderSizePixel  = 0
closeBtn.AutoButtonColor  = false
closeBtn.ZIndex           = tb.ZIndex + 3
closeBtn.Parent           = tb
corner(closeBtn, 8)
stroke(closeBtn, C.border, 1)
closeBtn.MouseEnter:Connect(function() tw(closeBtn, TIF, {BackgroundColor3 = C.surfaceHi, TextColor3 = C.text}) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn, TIF, {BackgroundColor3 = C.surfaceHi, TextColor3 = C.textMuted}) end)

local stopAllBtn = Instance.new("TextButton")
stopAllBtn.Size             = UDim2.new(0, 42, 0, BH) -- Height matched to Clear button
stopAllBtn.Position         = UDim2.new(1, -45, 1, -20) -- Aligned with dock line
stopAllBtn.AnchorPoint      = Vector2.new(1, 1)
stopAllBtn.BackgroundColor3 = C.surfaceHi
stopAllBtn.Text             = "Stop"
stopAllBtn.TextColor3       = C.textMuted
stopAllBtn.TextSize         = FS -- Text size matched to Clear button
stopAllBtn.Font             = Enum.Font.GothamBold
stopAllBtn.BorderSizePixel  = 0
stopAllBtn.AutoButtonColor  = false
stopAllBtn.ZIndex           = 500
stopAllBtn.Parent           = panel
corner(stopAllBtn, 8)
stroke(stopAllBtn, C.border, 1)

local clearBtn = Instance.new("TextButton")
clearBtn.Size             = UDim2.new(0, 76, 0, BH)
clearBtn.Position         = UDim2.new(1, -92, 1, -20) -- Positioned next to Stop button
clearBtn.AnchorPoint      = Vector2.new(1, 1)
clearBtn.BackgroundColor3 = C.surfaceHi
clearBtn.Text             = "Clear"
clearBtn.TextColor3       = C.textMuted
clearBtn.TextSize         = FS
clearBtn.Font             = Enum.Font.GothamBold
clearBtn.BorderSizePixel  = 0
clearBtn.AutoButtonColor  = false
clearBtn.ZIndex           = 500
clearBtn.Parent           = panel
corner(clearBtn, 7)
stroke(clearBtn, C.border, 1)

-- TAB SYSTEM
local tabs = {}
local activeTab = nil

local function createPage()
    local p = Instance.new("Frame")
    p.Size             = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel  = 0
    p.Visible          = false
    p.Parent           = panel
    return p
end

local function switchTab(name)
    if activeTab == name then return end
    activeTab = name
    for n, d in pairs(tabs) do
        local on = n == name
        d.page.Visible = on
        if d.btn then
            tw(d.btn, TIF, {
                BackgroundColor3       = C.surfaceHi,
                BackgroundTransparency = 1,
                TextColor3             = on and C.accent or C.textDim,
            })
            local iconImg = d.btn:FindFirstChild("Icon")
            if iconImg then
                tw(iconImg, TIF, {ImageColor3 = on and C.accent or C.textDim})
            end
            local s = d.btn:FindFirstChildOfClass("UIStroke")
            if s then tw(s, TIF, {Transparency = on and 0 or 1}) end
        end
    end
end

local function addTab(name, labelOrIcon, order)
    local btn = Instance.new("TextButton")
    btn.Name                 = name .. "Btn"
    btn.Size                 = UDim2.new(0, BH, 0, BH) -- Same height as right-side buttons
    
    if order == 1 then
        btn.Position = UDim2.new(0.38, 0, 1, -34)
    elseif order == 2 then
        btn.Position = UDim2.new(0.5, 0, 1, -34)
    else
        btn.Position = UDim2.new(0.62, 0, 1, -34)
    end
    btn.AnchorPoint          = Vector2.new(0.5, 0.5)
    btn.BackgroundColor3     = C.surfaceHi
    btn.BackgroundTransparency = 1 -- Invisible when inactive
    btn.AutoButtonColor      = false
    btn.ZIndex               = 600
    btn.LayoutOrder          = order
    btn.Visible              = true
    btn.Parent               = panel
    corner(btn, 8)
    stroke(btn, C.borderHi, 1).Transparency = 1

    local isIcon = false
    if type(labelOrIcon) == "string" and (labelOrIcon:find("rbxassetid://") or labelOrIcon:find("asset")) then
        isIcon = true
    end
    local iconImg
    if isIcon then
        btn.Text = ""
        iconImg = Instance.new("ImageLabel")
        iconImg.Name = "Icon"
        iconImg.Size = UDim2.new(0, 18, 0, 18)
        iconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = labelOrIcon
        iconImg.ImageColor3 = C.textMuted -- Using a brighter default
        iconImg.ImageTransparency = 0
        iconImg.ImageTransparency = 0
        iconImg.ScaleType = Enum.ScaleType.Fit
        iconImg.ZIndex = 700 -- Higher ZIndex
        iconImg.Parent = btn
    else
        btn.Text = labelOrIcon
        btn.TextColor3 = C.textMuted
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
    end
    btn.ClipsDescendants = false -- Ensure icons aren't clipped

    local page = createPage()
    tabs[name] = { btn = btn, page = page }

    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    btn.MouseEnter:Connect(function()
        if activeTab ~= name then 
            if isIcon then tw(iconImg, TIF, {ImageColor3 = C.text}) else tw(btn, TIF, {TextColor3 = C.text}) end
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= name then 
            if isIcon then tw(iconImg, TIF, {ImageColor3 = C.textDim}) else tw(btn, TIF, {TextColor3 = C.textDim}) end
        end
    end)

    return page
end

-- LISTENER TAB
local listenerPage = addTab("Listener", "rbxassetid://7072718840", 1) -- Reverted to first waves icon

local logArea = Instance.new("ScrollingFrame")
logArea.Size                = UDim2.new(1, 0, 1, -(TH + 60))
logArea.Position            = UDim2.new(0, 0, 0, TH)
logArea.BackgroundTransparency = 1
logArea.BorderSizePixel     = 0
logArea.ScrollBarThickness  = isMobile and 6 or 3
logArea.ScrollBarImageColor3 = C.accentDim
logArea.CanvasSize          = UDim2.new(0,0,0,0)
logArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
logArea.Parent              = listenerPage

local listL = Instance.new("UIListLayout", logArea)
listL.SortOrder           = Enum.SortOrder.LayoutOrder
listL.Padding             = UDim.new(0, isMobile and 8 or 6)
listL.VerticalAlignment   = Enum.VerticalAlignment.Top

local lpad = Instance.new("UIPadding", logArea)
lpad.PaddingTop    = UDim.new(0, 6)
lpad.PaddingBottom = UDim.new(0, 6)
lpad.PaddingLeft   = UDim.new(0, 4)
lpad.PaddingRight  = UDim.new(0, 4)

listL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    logArea.CanvasSize = UDim2.new(0, 0, 0, listL.AbsoluteContentSize.Y + 12)
end)

-- Search filter logic removed as requested

local function setEmpty(show)
    local e = logArea:FindFirstChild("EmptyState")
    if show and not e then
        local el = Instance.new("TextLabel")
        el.Name               = "EmptyState"
        el.Size               = UDim2.new(1, 0, 0, 240)
        el.BackgroundTransparency = 1
        el.Text               = "Waiting for events...\nAll marketplace signals will appear here."
        el.TextColor3         = C.textDim
        el.TextSize           = FM
        el.Font               = Enum.Font.Gotham
        el.TextWrapped        = true
        el.LayoutOrder        = 99999
        el.TextXAlignment     = Enum.TextXAlignment.Center
        el.Parent             = logArea
    elseif not show and e then
        e:Destroy()
    end
end

-- Signal type â†’ accent color
local SIG_COLOR = {
    Product  = Color3.fromRGB(100, 200, 255),  -- blue
    Gamepass = Color3.fromRGB(61,  255, 160),  -- green
    Bulk     = Color3.fromRGB(255, 190,  60),  -- amber
    Purchase = Color3.fromRGB(200, 200, 200),  -- light gray (no purple)
}

local eventCount       = 0
local pinCount         = 0
local entries          = {}
local suppressCounter  = 0
local activeAutoButtons = {}
local activeSpamButtons = {}

local activeToasts = {}
-- Toast notification
local function showToast(msg, col)
    for _, oldToast in ipairs(activeToasts) do
        if oldToast and oldToast.Parent then
            tw(oldToast, TIM, {BackgroundTransparency = 1, Position = UDim2.new(1, 10, oldToast.Position.Y.Scale, oldToast.Position.Y.Offset)})
            task.delay(0.35, function() pcall(function() oldToast:Destroy() end) end)
        end
    end
    table.clear(activeToasts)

    col = col or C.accent
    local toast = Instance.new("Frame")
    toast.Size             = UDim2.new(0, 240, 0, 36)
    toast.Position         = UDim2.new(1, -250, 1, -50)
    toast.BackgroundColor3 = C.surface
    toast.BorderSizePixel  = 0
    toast.ZIndex           = 200
    toast.BackgroundTransparency = 1
    toast.Parent           = sg
    corner(toast, 8)
    stroke(toast, col, 1)

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 1, -12)
    bar.Position         = UDim2.new(0, 6, 0, 6)
    bar.BackgroundColor3 = col
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 201
    bar.Parent           = toast
    corner(bar, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -18, 1, 0)
    lbl.Position           = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = msg
    lbl.TextColor3         = C.text
    lbl.TextSize           = FS
    lbl.Font               = Enum.Font.Gotham
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.TextTruncate       = Enum.TextTruncate.AtEnd
    lbl.ZIndex             = 201
    lbl.Parent             = toast

    -- slide in from right
    toast.Position = UDim2.new(1, 10, 1, -50)
    table.insert(activeToasts, toast)
    tw(toast, TIM, {BackgroundTransparency = 0, Position = UDim2.new(1, -250, 1, -50)})
    local _toastRS = game:GetService("RunService")
    local _tT = 0; local _tC
    _tC = _toastRS.Heartbeat:Connect(function(dt)
        _tT = _tT + dt
        if _tT >= 2.2 then
            _tC:Disconnect()
            tw(toast, TIM, {BackgroundTransparency = 1, Position = UDim2.new(1, 10, 1, -50)})
            local _dT = 0; local _dC
            _dC = _toastRS.Heartbeat:Connect(function(dt2)
                _dT = _dT + dt2
                if _dT >= 0.35 then _dC:Disconnect(); pcall(function() toast:Destroy() end) end
            end)
        end
    end)
end

local function fireFakeSignal(sigType, id)
    suppressCounter = suppressCounter + 1
    pcall(function()
        if     sigType == "Product"  then MPS:SignalPromptProductPurchaseFinished(player.UserId, id, true)
        elseif sigType == "Gamepass" then MPS:SignalPromptGamePassPurchaseFinished(player, id, true)
        elseif sigType == "Bulk"     then MPS:SignalPromptBulkPurchaseFinished(player.UserId, id, true)
        elseif sigType == "Purchase" then MPS:SignalPromptPurchaseFinished(player.UserId, id, true)
        end
    end)
    suppressCounter = suppressCounter - 1
end

local function stopAllAutoAndSpam()
    for btn, data in pairs(activeAutoButtons) do
        data.active = false
        if data.loop then task.cancel(data.loop) end
        if btn and btn.Parent then
            btn.Text = "Auto"; btn.TextColor3 = C.textMuted; btn.BackgroundColor3 = C.surfaceHi
        end
    end
    table.clear(activeAutoButtons)
    for btn, data in pairs(activeSpamButtons) do
        data.active = false
        if data.loop then task.cancel(data.loop) end
        if btn and btn.Parent then
            btn.Text = "Run"; btn.TextColor3 = C.textMuted; btn.BackgroundColor3 = C.surfaceHi
        end
    end
    table.clear(activeSpamButtons)
end

stopAllBtn.MouseButton1Click:Connect(stopAllAutoAndSpam)

local globalPinned = {}
local function updateLogVisuals(id, isPinned)
    for _, e in ipairs(entries) do
        if e:GetAttribute("SigID") == id then
            tw(e, TweenInfo.new(0.18), {BackgroundColor3 = isPinned and C.surfaceHi or C.bg})
        end
    end
end
local addPinnedEntry -- Forward declaration so addLog can use it
local removePinnedEntryByID -- Forward declaration

local function addLog(label, id, sigType)
    if suppressCounter > 0 then return end
    setEmpty(false)

    local entry = Instance.new("Frame")
    entry:SetAttribute("SigID", id)
    entry.Size             = UDim2.new(1, -2, 0, isMobile and 56 or 46)
    entry.BackgroundColor3 = globalPinned[id] and C.surfaceHi or C.bg
    entry.BorderSizePixel  = 0
    entry.LayoutOrder      = -eventCount
    entry.Parent           = logArea
    corner(entry, 10)
    stroke(entry, C.border, 1)
    entry.BackgroundTransparency = 1
    tw(entry, TweenInfo.new(0.18), {BackgroundTransparency = 0})

    local sigCol = SIG_COLOR[sigType] or C.textMuted

    -- Colored dot per signal type
    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 8, 0, 8)
    dot.Position         = UDim2.new(0, 14, 0.5, -4)
    dot.BackgroundColor3 = sigCol
    dot.BorderSizePixel  = 0
    dot.Parent           = entry
    corner(dot, 999)

    -- Removed PinIcon per user request

    local typeLbl = Instance.new("TextLabel")
    typeLbl.Name             = "TypeLbl"
    typeLbl.Size             = UDim2.new(0, 76, 1, 0)
    typeLbl.Position         = UDim2.new(0, 28, 0, 0)
    typeLbl.BackgroundTransparency = 1
    typeLbl.Text             = string.upper(label)
    typeLbl.TextColor3       = sigCol
    typeLbl.TextSize         = 10
    typeLbl.Font             = Enum.Font.GothamBold
    typeLbl.TextXAlignment   = Enum.TextXAlignment.Left
    typeLbl.Parent           = entry

    -- ID label — double-click to rename
    local customName = nil
    local lastIdClick = 0
    local idLbl = Instance.new("TextButton")
    idLbl.Name             = "IdLbl"
    idLbl.Size             = UDim2.new(0, 200, 1, 0)
    idLbl.Position         = UDim2.new(0, 108, 0, 0)
    idLbl.BackgroundTransparency = 1
    local displayText = tostring(id)
    if showProductNames then
        local pName = getProductName(id, sigType)
        if pName then displayText = pName end
    end
    idLbl.Text             = displayText
    idLbl.TextColor3       = showProductNames and C.accent or C.text
    idLbl.TextSize         = 14
    idLbl.Font             = Enum.Font.GothamBold
    idLbl.TextXAlignment   = Enum.TextXAlignment.Left
    idLbl.TextTruncate     = Enum.TextTruncate.AtEnd
    idLbl.AutoButtonColor  = false
    idLbl.BorderSizePixel  = 0
    idLbl.Parent           = entry

    -- Double-click to open rename TextBox
    idLbl.MouseButton1Click:Connect(function()
        local now = tick()
        if now - lastIdClick < 0.4 then
            lastIdClick = 0
            local box = Instance.new("TextBox")
            box.Size             = idLbl.Size
            box.Position         = idLbl.Position
            box.BackgroundColor3 = C.surfaceHi
            box.Text             = customName or tostring(id)
            box.TextColor3       = C.accent
            box.TextSize         = 13
            box.Font             = Enum.Font.GothamBold
            box.TextXAlignment   = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            box.BorderSizePixel  = 0
            box.ZIndex           = 10
            box.Parent           = entry
            corner(box, 4)
            stroke(box, C.accentDim, 1)
            box:CaptureFocus()
            box.FocusLost:Connect(function(entered)
                local newName = box.Text ~= "" and box.Text or tostring(id)
                customName   = newName ~= tostring(id) and newName or nil
                idLbl.Text   = customName or tostring(id)
                idLbl.TextColor3 = customName and C.accent or C.text
                box:Destroy()
            end)
        else
            lastIdClick = now
        end
    end)
    idLbl.MouseEnter:Connect(function()
        tw(idLbl, TIF, {TextColor3 = C.accent})
    end)
    idLbl.MouseLeave:Connect(function()
        tw(idLbl, TIF, {TextColor3 = customName and C.accent or C.text})
    end)

    -- Middle-click or Right-click to pin to Pinned tab
    entry.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton3 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
            if globalPinned[id] then
                globalPinned[id] = nil
                updateLogVisuals(id, false)
                removePinnedEntryByID(id)
                showToast("Unpinned from Pinned tab", C.textMuted)
            else
                globalPinned[id] = true
                updateLogVisuals(id, true)
                addPinnedEntry(id, sigType, customName)
                showToast("Pinned to Pinned tab", C.accent)
            end
        end
    end)

    local timeLbl = Instance.new("TextLabel")
    timeLbl.Size             = UDim2.new(0, 70, 1, 0)
    timeLbl.Position         = UDim2.new(0, 318, 0, 0)
    timeLbl.BackgroundTransparency = 1
    timeLbl.Text             = os.date("%H:%M:%S")
    timeLbl.TextColor3       = C.textDim
    timeLbl.TextSize         = FS
    timeLbl.Font             = Enum.Font.Gotham
    timeLbl.Parent           = entry

    local bf = Instance.new("Frame")
    bf.Size                 = UDim2.new(0, 196, 1, 0)
    bf.Position             = UDim2.new(1, -200, 0, 0)
    bf.BackgroundTransparency = 1
    bf.Parent               = entry

    local function mkBtn(txt, xOff)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 56, 0, BH)
        b.Position         = UDim2.new(0, xOff, 0.5, -BH/2)
        b.BackgroundColor3 = C.surfaceHi
        b.Text             = txt
        b.TextColor3       = C.textMuted
        b.TextSize         = FS
        b.Font             = Enum.Font.GothamBold
        b.BorderSizePixel  = 0
        b.AutoButtonColor  = false
        b.Parent           = bf
        corner(b, 7)
        stroke(b, C.border, 1)
        return b
    end

    local autoBtn = mkBtn("Auto", 0)
    local copyBtn = mkBtn("Copy", 62)
    local runBtn  = mkBtn("▶",  138) -- Play button instead of 'Run'
    runBtn.Size     = UDim2.new(0, 42, 0, BH) -- Squared up to center the icon perfectly
    runBtn.TextSize = 18 -- Make the play icon a bit bigger

    -- COPY
    copyBtn.MouseButton1Click:Connect(function()
        pcall(setclipboard, tostring(id))
        copyBtn.Text = "Copied!"; copyBtn.TextColor3 = C.accent
        task.wait(1.5)
        if copyBtn.Parent then copyBtn.Text = "Copy"; copyBtn.TextColor3 = C.textMuted end
    end)

    -- AUTO
    local autoActive = false; local autoLoop = nil
    local function startAuto()
        if autoActive then return end
        autoActive = true
        autoBtn.Text = "Stop"; autoBtn.TextColor3 = C.red; autoBtn.BackgroundColor3 = Color3.fromRGB(40,15,15)
        autoLoop = task.spawn(function()
            while autoActive and autoBtn.Parent do
                fireFakeSignal(sigType, id)
                task.wait(autoSpeed > 0 and 1/autoSpeed or 0.01)
            end
        end)
        activeAutoButtons[autoBtn] = {active = true, loop = autoLoop}
    end
    local function stopAuto()
        autoActive = false
        if autoLoop then task.cancel(autoLoop) end
        activeAutoButtons[autoBtn] = nil
        if autoBtn.Parent then autoBtn.Text = "Auto"; autoBtn.TextColor3 = C.textMuted; autoBtn.BackgroundColor3 = C.surfaceHi end
    end
    autoBtn.MouseButton1Click:Connect(function() if autoActive then stopAuto() else startAuto() end end)

    -- RUN (click = once, hold 3s = spam)
    local holdStart = nil; local holdConn = nil; local spamLoop = nil; local isSpamming = false
    local function startSpam()
        if isSpamming then return end
        isSpamming = true
        runBtn.Text = "Spamming"; runBtn.TextSize = FS; runBtn.TextColor3 = C.amber
        spamLoop = task.spawn(function()
            while isSpamming and runBtn.Parent do fireFakeSignal(sigType, id); task.wait(0.08) end
        end)
        activeSpamButtons[runBtn] = {active = true, loop = spamLoop}
    end
    local function stopSpam()
        isSpamming = false
        if spamLoop then task.cancel(spamLoop) end
        activeSpamButtons[runBtn] = nil
        if runBtn.Parent then runBtn.Text = "▶"; runBtn.TextSize = 18; runBtn.TextColor3 = C.textMuted; runBtn.BackgroundColor3 = C.surfaceHi end
    end
    runBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            holdStart = tick()
            holdConn  = task.spawn(function()
                while holdStart and (tick() - holdStart) < 3 do task.wait(0.1) end
                if holdStart and not isSpamming then startSpam() end
            end)
        end
    end)
    runBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            local dur = holdStart and (tick() - holdStart) or 0
            holdStart = nil
            if holdConn then task.cancel(holdConn) end
            if isSpamming then
                stopSpam()
            elseif dur < 3 then
                fireFakeSignal(sigType, id)
                runBtn.Text = "Sent!"; runBtn.TextSize = FS
                task.wait(1.5)
                if runBtn.Parent then runBtn.Text = "▶"; runBtn.TextSize = 18 end
            end
        end
    end)
    runBtn.MouseEnter:Connect(function()
        if not isSpamming and runBtn.Text == "▶" then tw(runBtn, TIF, {TextColor3 = C.accent, BackgroundColor3 = C.surface}) end
    end)
    runBtn.MouseLeave:Connect(function()
        if not isSpamming and runBtn.Text == "▶" then tw(runBtn, TIF, {TextColor3 = C.textMuted, BackgroundColor3 = C.surfaceHi}) end
    end)

    entry.AncestryChanged:Connect(function()
        if not entry.Parent then
            if autoActive then stopAuto() end
            if isSpamming then stopSpam() end
            for i, e in ipairs(entries) do if e == entry then table.remove(entries, i); break end end
        end
    end)

    eventCount = eventCount + 1
    countLabel.Text = eventCount .. (eventCount == 1 and " event captured" or " events captured")
    table.insert(entries, entry)
    task.defer(function() logArea.CanvasPosition = Vector2.new(0, logArea.AbsoluteCanvasSize.Y) end)
    latestEvent = {sigType = sigType, id = id}
    showToast(string.upper(sigType) .. "  " .. tostring(id), C.text)
end

clearBtn.MouseButton1Click:Connect(function()
    stopAllAutoAndSpam()
    for _, e in ipairs(entries) do e:Destroy() end
    entries = {}; eventCount = 0; countLabel.Text = "0 events captured"; setEmpty(true)
end)


-- PINNED TAB
local pinnedPage = addTab("Pinned", "rbxassetid://7733920644", 2) -- Verified Material Pin Image
local pinnedScroll = Instance.new("ScrollingFrame")
pinnedScroll.Size                = UDim2.new(1, 0, 1, -(TH + 60))
pinnedScroll.Position            = UDim2.new(0, 0, 0, TH)
pinnedScroll.BackgroundTransparency = 1
pinnedScroll.BorderSizePixel     = 0
pinnedScroll.ScrollBarThickness  = 3
pinnedScroll.ScrollBarImageColor3 = C.accentDim
pinnedScroll.CanvasSize          = UDim2.new(0,0,0,0)
pinnedScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
pinnedScroll.Parent              = pinnedPage

local pinnedLayout = Instance.new("UIListLayout", pinnedScroll)
pinnedLayout.SortOrder = Enum.SortOrder.LayoutOrder
pinnedLayout.Padding   = UDim.new(0, 6)

local pinnedPad = Instance.new("UIPadding", pinnedScroll)
pinnedPad.PaddingTop    = UDim.new(0, 6)
pinnedPad.PaddingBottom = UDim.new(0, 6)
pinnedPad.PaddingLeft   = UDim.new(0, 4)
pinnedPad.PaddingRight  = UDim.new(0, 4)

pinnedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    pinnedScroll.CanvasSize = UDim2.new(0, 0, 0, pinnedLayout.AbsoluteContentSize.Y + 12)
end)

local pinnedEntries = {}
local pinnedDataList = {}  -- {id, sigType, displayName} for persistence
local pinnedCount = 0

-- Persistence: save/load pinned entries to workspace file
local function savePinnedToFile()
    pcall(function()
        if writefile then
            writefile(PINNED_FILE, HS:JSONEncode(pinnedDataList))
        end
    end)
end

local function loadPinnedFromFile()
    local ok, data = pcall(function()
        if isfile and isfile(PINNED_FILE) then
            return HS:JSONDecode(readfile(PINNED_FILE))
        end
        return {}
    end)
    return ok and type(data) == "table" and data or {}
end

local function setPinnedEmpty(show)
    local e = pinnedScroll:FindFirstChild("PinnedEmpty")
    if show and not e then
        local el = Instance.new("TextLabel")
        el.Name               = "PinnedEmpty"
        el.Size               = UDim2.new(1, 0, 0, 200)
        el.BackgroundTransparency = 1
        el.Text               = "No pinned entries yet.\nRight-click or Middle-click an event in Listener to pin it."
        el.TextColor3         = C.textDim
        el.TextSize           = FM
        el.Font               = Enum.Font.Gotham
        el.TextWrapped        = true
        el.LayoutOrder        = 99999
        el.TextXAlignment     = Enum.TextXAlignment.Center
        el.Parent             = pinnedScroll
    elseif not show and e then
        e:Destroy()
    end
end
setPinnedEmpty(true)

removePinnedEntryByID = function(id)
    for i = #pinnedDataList, 1, -1 do
        if pinnedDataList[i].id == id then
            table.remove(pinnedDataList, i)
        end
    end
    for i = #pinnedEntries, 1, -1 do
        local pe = pinnedEntries[i]
        if pe:GetAttribute("SigID") == id then
            pe:Destroy()
            table.remove(pinnedEntries, i)
        end
    end
    savePinnedToFile()
    if #pinnedEntries == 0 then setPinnedEmpty(true) end
end

addPinnedEntry = function(id, sigType, displayName, skipSave)
    globalPinned[id] = true
    setPinnedEmpty(false)
    pinnedCount = pinnedCount + 1
    local sigCol = SIG_COLOR[sigType] or C.textMuted

    -- Track data for persistence
    local dataEntry = {id = id, sigType = sigType, displayName = displayName}
    table.insert(pinnedDataList, dataEntry)
    if not skipSave then savePinnedToFile() end

    local pe = Instance.new("Frame")
    pe:SetAttribute("SigID", id)
    pe.Size             = UDim2.new(1, -2, 0, isMobile and 56 or 46)
    pe.BackgroundColor3 = C.bg -- Changed from C.surfaceHi to match top bar
    pe.BorderSizePixel  = 0
    pe.LayoutOrder      = pinnedCount
    pe.Parent           = pinnedScroll
    corner(pe, 10)
    stroke(pe, C.border, 1)

    local pdot = Instance.new("Frame")
    pdot.Size             = UDim2.new(0, 8, 0, 8)
    pdot.Position         = UDim2.new(0, 14, 0.5, -4)
    pdot.BackgroundColor3 = sigCol
    pdot.BorderSizePixel  = 0
    pdot.Parent           = pe
    corner(pdot, 999)

    local ptype = Instance.new("TextLabel")
    ptype.Size               = UDim2.new(0, 70, 1, 0)
    ptype.Position           = UDim2.new(0, 28, 0, 0)
    ptype.BackgroundTransparency = 1
    ptype.Text               = string.upper(sigType)
    ptype.TextColor3         = sigCol
    ptype.TextSize           = 10
    ptype.Font               = Enum.Font.GothamBold
    ptype.TextXAlignment     = Enum.TextXAlignment.Left
    ptype.Parent             = pe

    local pname = Instance.new("TextButton")
    pname.Size               = UDim2.new(0, 200, 1, 0)
    pname.Position           = UDim2.new(0, 100, 0, 0)
    pname.BackgroundTransparency = 1
    pname.Text               = displayName or tostring(id)
    pname.TextColor3         = displayName and C.accent or C.text
    pname.TextSize           = FM
    pname.Font               = Enum.Font.GothamBold
    pname.TextXAlignment     = Enum.TextXAlignment.Left
    pname.TextTruncate       = Enum.TextTruncate.AtEnd
    pname.BorderSizePixel    = 0
    pname.AutoButtonColor    = false
    pname.Parent             = pe

    -- Double-click to rename pinned entry
    local lastPinClick = 0
    pname.MouseButton1Click:Connect(function()
        local now = tick()
        if now - lastPinClick < 0.4 then
            lastPinClick = 0
            local box = Instance.new("TextBox")
            box.Size             = pname.Size
            box.Position         = pname.Position
            box.BackgroundColor3 = C.surfaceHi
            box.Text             = pname.Text
            box.TextColor3       = C.accent
            box.TextSize         = FM
            box.Font             = Enum.Font.GothamBold
            box.TextXAlignment   = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            box.BorderSizePixel  = 0
            box.ZIndex           = 10
            box.Parent           = pe
            corner(box, 4)
            stroke(box, C.accentDim, 1)
            box:CaptureFocus()
            box.FocusLost:Connect(function()
                local newName = box.Text ~= "" and box.Text or tostring(id)
                pname.Text = newName
                pname.TextColor3 = (newName ~= tostring(id)) and C.accent or C.text
                -- Update persistence data
                dataEntry.displayName = (newName ~= tostring(id)) and newName or nil
                savePinnedToFile()
                box:Destroy()
            end)
        else
            lastPinClick = now
        end
    end)

    -- Buttons: Auto, Copy, Run, Unpin
    local pbf = Instance.new("Frame")
    pbf.Size                 = UDim2.new(0, 240, 1, 0)
    pbf.Position             = UDim2.new(1, -244, 0, 0)
    pbf.BackgroundTransparency = 1
    pbf.Parent               = pe

    local function mkPBtn(txt, xOff)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 52, 0, BH)
        b.Position         = UDim2.new(0, xOff, 0.5, -BH/2)
        b.BackgroundColor3 = C.surfaceHi
        b.Text             = txt
        b.TextColor3       = C.textMuted
        b.TextSize         = FS
        b.Font             = Enum.Font.GothamBold
        b.BorderSizePixel  = 0
        b.AutoButtonColor  = false
        b.Parent           = pbf
        corner(b, 7)
        stroke(b, C.border, 1)
        return b
    end

    local pautoBtn = mkPBtn("Auto", 0)
    local pcopyBtn = mkPBtn("Copy", 58)
    local prunBtn  = mkPBtn("\226\150\182", 126)
    prunBtn.Size   = UDim2.new(0, 42, 0, BH)
    prunBtn.TextSize = 18

    -- pinned auto
    local pAutoActive = false; local pAutoLoop = nil
    local function startPAuto()
        if pAutoActive then return end
        pAutoActive = true
        pautoBtn.Text = "Stop"; pautoBtn.TextColor3 = C.red; pautoBtn.BackgroundColor3 = Color3.fromRGB(40,15,15)
        pAutoLoop = task.spawn(function()
            while pAutoActive and pautoBtn.Parent do
                fireFakeSignal(sigType, id)
                task.wait(autoSpeed > 0 and 1/autoSpeed or 0.01)
            end
        end)
        activeAutoButtons[pautoBtn] = {active = true, loop = pAutoLoop}
    end
    local function stopPAuto()
        pAutoActive = false
        if pAutoLoop then task.cancel(pAutoLoop) end
        activeAutoButtons[pautoBtn] = nil
        if pautoBtn.Parent then pautoBtn.Text = "Auto"; pautoBtn.TextColor3 = C.textMuted; pautoBtn.BackgroundColor3 = C.surfaceHi end
    end
    pautoBtn.MouseButton1Click:Connect(function() if pAutoActive then stopPAuto() else startPAuto() end end)

    pcopyBtn.MouseButton1Click:Connect(function()
        pcall(setclipboard, tostring(id))
        pcopyBtn.Text = "Done!"; pcopyBtn.TextColor3 = C.accent
        local RS3 = game:GetService("RunService")
        local ct=0; local cc
        cc = RS3.Heartbeat:Connect(function(dt)
            ct=ct+dt; if ct>=1.2 then cc:Disconnect()
                if pcopyBtn.Parent then pcopyBtn.Text="Copy"; pcopyBtn.TextColor3=C.textMuted end
            end
        end)
    end)

    prunBtn.MouseButton1Click:Connect(function()
        fireFakeSignal(sigType, id)
        prunBtn.Text = "Sent!"; prunBtn.TextSize = FS
        local RS3 = game:GetService("RunService")
        local rt=0; local rc
        rc = RS3.Heartbeat:Connect(function(dt)
            rt=rt+dt; if rt>=1.2 then rc:Disconnect()
                if prunBtn.Parent then prunBtn.Text="\226\150\182"; prunBtn.TextSize = 18 end
            end
        end)
    end)
    
    pe.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton3 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
            if globalPinned[id] then
                globalPinned[id] = nil
                updateLogVisuals(id, false)
                removePinnedEntryByID(id)
                showToast("Unpinned from Pinned tab", C.textMuted)
            end
        end
    end)

    pe.AncestryChanged:Connect(function()
        if not pe.Parent and pAutoActive then stopPAuto() end
    end)

    table.insert(pinnedEntries, pe)
    return pe
end


-- SETTINGS TAB
local settingsPage = addTab("Settings", "rbxassetid://6031280882", 3) -- Swapped for a super-reliable gear icon ID

local sw = Instance.new("ScrollingFrame")
sw.Size                = UDim2.new(1, 0, 1, -(TH + 60))
sw.Position            = UDim2.new(0, 0, 0, TH)
sw.BackgroundTransparency = 1
sw.BorderSizePixel     = 0
sw.ScrollBarThickness  = 3
sw.ScrollBarImageColor3 = C.accentDim
sw.CanvasSize          = UDim2.new(0,0,0,0)
sw.AutomaticCanvasSize = Enum.AutomaticSize.Y
sw.Parent              = settingsPage

local sl = Instance.new("UIListLayout", sw)
sl.SortOrder = Enum.SortOrder.LayoutOrder
sl.Padding   = UDim.new(0, 10)

local sp = Instance.new("UIPadding", sw)
sp.PaddingTop   = UDim.new(0, 8)
sp.PaddingLeft  = UDim.new(0, 4)
sp.PaddingRight = UDim.new(0, 4)

local speedRow = Instance.new("Frame")
speedRow.Size             = UDim2.new(1, -4, 0, 54)
speedRow.BackgroundColor3 = C.bg
speedRow.BorderSizePixel  = 0
speedRow.LayoutOrder      = 1
speedRow.Parent           = sw
corner(speedRow, 8)
stroke(speedRow, C.border, 1)

local speedTitle = Instance.new("TextLabel")
speedTitle.Size             = UDim2.new(0.65, 0, 0, 20)
speedTitle.Position         = UDim2.new(0, 12, 0, 8)
speedTitle.BackgroundTransparency = 1
speedTitle.Text             = "Signals per second"
speedTitle.TextColor3       = C.text
speedTitle.TextSize         = FM
speedTitle.Font             = Enum.Font.GothamBold
speedTitle.TextXAlignment   = Enum.TextXAlignment.Left
speedTitle.Parent           = speedRow

local speedDesc = Instance.new("TextLabel")
speedDesc.Size             = UDim2.new(0.65, 0, 0, 14)
speedDesc.Position         = UDim2.new(0, 12, 0, 28)
speedDesc.BackgroundTransparency = 1
speedDesc.Text             = "1 slowest  |  10000 fastest  |  Default: 100"
speedDesc.TextColor3       = C.textDim
speedDesc.TextSize         = 9
speedDesc.Font             = Enum.Font.Gotham
speedDesc.TextXAlignment   = Enum.TextXAlignment.Left
speedDesc.Parent           = speedRow

local speedBox = Instance.new("TextBox")
speedBox.Size             = UDim2.new(0, 100, 0, 30)
speedBox.Position         = UDim2.new(1, -116, 0.5, -15)
speedBox.BackgroundColor3 = C.bg
speedBox.Text             = tostring(autoSpeed)
speedBox.TextColor3       = C.text
speedBox.TextSize         = FM
speedBox.Font             = Enum.Font.RobotoMono
speedBox.BorderSizePixel  = 0
speedBox.ClearTextOnFocus = false
speedBox.Parent           = speedRow
corner(speedBox, 6)
stroke(speedBox, C.border, 1)

local sboxPad = Instance.new("UIPadding", speedBox)
sboxPad.PaddingLeft = UDim.new(0, 8)

speedBox.FocusLost:Connect(function()
    local n = tonumber(speedBox.Text)
    if n and n >= 1 and n <= 10000 then
        autoSpeed = math.floor(n)
        speedBox.Text = tostring(autoSpeed)
        tw(speedBox, TIF, {BackgroundColor3 = C.greenDim})
        task.wait(0.6)
        tw(speedBox, TIF, {BackgroundColor3 = C.bg})
    else
        tw(speedBox, TIF, {BackgroundColor3 = C.redDim})
        task.wait(0.6)
        tw(speedBox, TIF, {BackgroundColor3 = C.bg})
        speedBox.Text = tostring(autoSpeed)
    end
end)

local _conns = {}

local kbRow = Instance.new("Frame")
kbRow.Size             = UDim2.new(1, -4, 0, 54)
kbRow.BackgroundColor3 = C.bg
kbRow.BorderSizePixel  = 0
kbRow.LayoutOrder      = 2
kbRow.Parent           = sw
corner(kbRow, 8)
stroke(kbRow, C.border, 1)

local kbTitle = Instance.new("TextLabel")
kbTitle.Size             = UDim2.new(0.65, 0, 0, 20)
kbTitle.Position         = UDim2.new(0, 12, 0, 8)
kbTitle.BackgroundTransparency = 1
kbTitle.Text             = "Toggle Keybind"
kbTitle.TextColor3       = C.text
kbTitle.TextSize         = FM
kbTitle.Font             = Enum.Font.GothamBold
kbTitle.TextXAlignment   = Enum.TextXAlignment.Left
kbTitle.Parent           = kbRow

local kbDesc = Instance.new("TextLabel")
kbDesc.Size             = UDim2.new(0.65, 0, 0, 14)
kbDesc.Position         = UDim2.new(0, 12, 0, 28)
kbDesc.BackgroundTransparency = 1
kbDesc.Text             = "Click to rebind. Hide/show UI."
kbDesc.TextColor3       = C.textDim
kbDesc.TextSize         = 9
kbDesc.Font             = Enum.Font.Gotham
kbDesc.TextXAlignment   = Enum.TextXAlignment.Left
kbDesc.Parent           = kbRow

local kbBtn = Instance.new("TextButton")
kbBtn.Size             = UDim2.new(0, 100, 0, 30)
kbBtn.Position         = UDim2.new(1, -116, 0.5, -15)
kbBtn.BackgroundColor3 = C.surfaceHi
kbBtn.Text             = "RightShift"
kbBtn.TextColor3       = C.text
kbBtn.TextSize         = 11
kbBtn.Font             = Enum.Font.GothamBold
kbBtn.BorderSizePixel  = 0
kbBtn.Parent           = kbRow
corner(kbBtn, 6)
stroke(kbBtn, C.border, 1)

local toggleKey = Enum.KeyCode.RightShift
local listening = false
kbBtn.MouseButton1Click:Connect(function()
    if listening then return end
    listening = true
    kbBtn.Text = "..."
    tw(kbBtn, TIF, {BackgroundColor3 = C.surface})
end)

-- quick fire hotkey setting
local qfRow = Instance.new("Frame")
qfRow.Size             = UDim2.new(1, -4, 0, 54)
qfRow.BackgroundColor3 = C.bg
qfRow.BorderSizePixel  = 0
qfRow.LayoutOrder      = 3
qfRow.Parent           = sw
corner(qfRow, 8)
stroke(qfRow, C.border, 1)

local qfTitle = Instance.new("TextLabel")
qfTitle.Size             = UDim2.new(0.65, 0, 0, 20)
qfTitle.Position         = UDim2.new(0, 12, 0, 8)
qfTitle.BackgroundTransparency = 1
qfTitle.Text             = "Quick Fire Hotkey"
qfTitle.TextColor3       = C.text
qfTitle.TextSize         = FM
qfTitle.Font             = Enum.Font.GothamBold
qfTitle.TextXAlignment   = Enum.TextXAlignment.Left
qfTitle.Parent           = qfRow

local qfDesc = Instance.new("TextLabel")
qfDesc.Size             = UDim2.new(0.65, 0, 0, 14)
qfDesc.Position         = UDim2.new(0, 12, 0, 28)
qfDesc.BackgroundTransparency = 1
qfDesc.Text             = "Fires the latest recorded event."
qfDesc.TextColor3       = C.textDim
qfDesc.TextSize         = 9
qfDesc.Font             = Enum.Font.Gotham
qfDesc.TextXAlignment   = Enum.TextXAlignment.Left
qfDesc.Parent           = qfRow

local qfBtn = Instance.new("TextButton")
qfBtn.Size             = UDim2.new(0, 100, 0, 30)
qfBtn.Position         = UDim2.new(1, -116, 0.5, -15)
qfBtn.BackgroundColor3 = C.surfaceHi
qfBtn.Text             = quickFireKey and quickFireKey.Name or "None"
qfBtn.TextColor3       = C.text
qfBtn.TextSize         = 11
qfBtn.Font             = Enum.Font.GothamBold
qfBtn.BorderSizePixel  = 0
qfBtn.Parent           = qfRow
corner(qfBtn, 6)
stroke(qfBtn, C.border, 1)

local qfListening = false
qfBtn.MouseButton1Click:Connect(function()
    if qfListening then return end
    qfListening = true
    qfBtn.Text = "..."
    tw(qfBtn, TIF, {BackgroundColor3 = C.surface})
end)

-- show product names toggle
local namesRow = Instance.new("Frame")
namesRow.Size             = UDim2.new(1, -4, 0, 54)
namesRow.BackgroundColor3 = C.bg
namesRow.BorderSizePixel  = 0
namesRow.LayoutOrder      = 4
namesRow.Parent           = sw
corner(namesRow, 8)
stroke(namesRow, C.border, 1)

local namesTitle = Instance.new("TextLabel")
namesTitle.Size             = UDim2.new(0.65, 0, 0, 20)
namesTitle.Position         = UDim2.new(0, 12, 0, 8)
namesTitle.BackgroundTransparency = 1
namesTitle.Text             = "Show Product Names"
namesTitle.TextColor3       = C.text
namesTitle.TextSize         = FM
namesTitle.Font             = Enum.Font.GothamBold
namesTitle.TextXAlignment   = Enum.TextXAlignment.Left
namesTitle.Parent           = namesRow

local namesDesc = Instance.new("TextLabel")
namesDesc.Size             = UDim2.new(0.65, 0, 0, 14)
namesDesc.Position         = UDim2.new(0, 12, 0, 28)
namesDesc.BackgroundTransparency = 1
namesDesc.Text             = "Show name instead of ID (e.g. 100 Coins)"
namesDesc.TextColor3       = C.textDim
namesDesc.TextSize         = 9
namesDesc.Font             = Enum.Font.Gotham
namesDesc.TextXAlignment   = Enum.TextXAlignment.Left
namesDesc.Parent           = namesRow

local namesToggle = Instance.new("TextButton")
namesToggle.Size             = UDim2.new(0, 60, 0, 30)
namesToggle.Position         = UDim2.new(1, -76, 0.5, -15)
namesToggle.BackgroundColor3 = showProductNames and C.greenDim or C.surfaceHi
namesToggle.Text             = showProductNames and "ON" or "OFF"
namesToggle.TextColor3       = showProductNames and C.green or C.textMuted
namesToggle.TextSize         = FM
namesToggle.Font             = Enum.Font.GothamBold
namesToggle.BorderSizePixel  = 0
namesToggle.AutoButtonColor  = false
namesToggle.Parent           = namesRow
corner(namesToggle, 6)
stroke(namesToggle, C.border, 1)

namesToggle.MouseButton1Click:Connect(function()
    showProductNames = not showProductNames
    namesToggle.Text = showProductNames and "ON" or "OFF"
    namesToggle.TextColor3 = showProductNames and C.green or C.textMuted
    tw(namesToggle, TIF, {BackgroundColor3 = showProductNames and C.greenDim or C.surfaceHi})
    saveMervanSettings()
end)

local detachRow = Instance.new("Frame")
detachRow.Size             = UDim2.new(1, -4, 0, 54)
detachRow.BackgroundColor3 = C.bg
detachRow.BorderSizePixel  = 0
detachRow.LayoutOrder      = 10
detachRow.Parent           = sw
corner(detachRow, 8)
stroke(detachRow, C.border, 1)

local detachTitle = Instance.new("TextLabel")
detachTitle.Size             = UDim2.new(0.65, 0, 0, 20)
detachTitle.Position         = UDim2.new(0, 12, 0, 8)
detachTitle.BackgroundTransparency = 1
detachTitle.Text             = "Detach Script"
detachTitle.TextColor3       = C.red
detachTitle.TextSize         = FM
detachTitle.Font             = Enum.Font.GothamBold
detachTitle.TextXAlignment   = Enum.TextXAlignment.Left
detachTitle.Parent           = detachRow

local detachDesc = Instance.new("TextLabel")
detachDesc.Size             = UDim2.new(0.65, 0, 0, 14)
detachDesc.Position         = UDim2.new(0, 12, 0, 28)
detachDesc.BackgroundTransparency = 1
detachDesc.Text             = "Closes UI and stops listeners."
detachDesc.TextColor3       = C.textDim
detachDesc.TextSize         = 9
detachDesc.Font             = Enum.Font.Gotham
detachDesc.TextXAlignment   = Enum.TextXAlignment.Left
detachDesc.Parent           = detachRow

local detachBtn = Instance.new("TextButton")
detachBtn.Size             = UDim2.new(0, 80, 0, 30)
detachBtn.Position         = UDim2.new(1, -96, 0.5, -15)
detachBtn.BackgroundColor3 = C.surfaceHi
detachBtn.Text             = "Detach"
detachBtn.TextColor3       = C.red
detachBtn.TextSize         = FM
detachBtn.Font             = Enum.Font.GothamBold
detachBtn.BorderSizePixel  = 0
detachBtn.Parent           = detachRow
corner(detachBtn, 6)
stroke(detachBtn, C.redDim, 1)

detachBtn.MouseButton1Click:Connect(function()
    stopAllAutoAndSpam()
    pcall(function() sg:Destroy() end)
    pcall(function() if reopenButton then reopenButton:Destroy() end end)
    for _, c in ipairs(_conns) do pcall(function() c:Disconnect() end) end
end)

local infoLbl = Instance.new("TextLabel")
infoLbl.Size               = UDim2.new(1, -4, 0, 28)
infoLbl.BackgroundTransparency = 1
infoLbl.Text               = "Mervan Services  v1.0  |  discord.gg/mervan"
infoLbl.TextColor3         = C.textDim
infoLbl.TextSize           = 9
infoLbl.Font               = Enum.Font.Gotham
infoLbl.TextXAlignment     = Enum.TextXAlignment.Center
infoLbl.LayoutOrder        = 99
infoLbl.Parent             = sw

-- CLOSE / SHOW / HIDE
local uiVisible    = true
local reopenButton = nil

local function showGui()
    if not sg.Enabled then
        sg.Enabled = true; uiVisible = true
        if reopenButton then reopenButton.Visible = false end
    end
end

local function hideGui()
    if sg.Enabled then
        sg.Enabled = false; uiVisible = false
        if isMobile then
            if not reopenButton or not reopenButton.Parent then
                reopenButton = Instance.new("TextButton")
                reopenButton.Size             = UDim2.new(0, 52, 0, 52)
                reopenButton.Position         = UDim2.new(1, -70, 1, -70)
                reopenButton.AnchorPoint      = Vector2.new(1, 1)
                reopenButton.BackgroundColor3 = C.surface
                reopenButton.Text             = "S"
                reopenButton.TextColor3       = C.accent
                reopenButton.TextSize         = 22
                reopenButton.Font             = Enum.Font.GothamBold
                reopenButton.BorderSizePixel  = 0
                reopenButton.ZIndex           = 100
                reopenButton.Parent           = CoreGui
                corner(reopenButton, 999)
                stroke(reopenButton, C.accentDim, 1.5)
                reopenButton.MouseButton1Click:Connect(showGui)
            else
                reopenButton.Visible = true
            end
        end
    end
end

closeBtn.MouseButton1Click:Connect(hideGui)

table.insert(_conns, UIS.InputBegan:Connect(function(inp, gpe)
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    -- toggle keybind listener
    if listening then
        toggleKey = inp.KeyCode
        kbBtn.Text = toggleKey.Name
        listening = false
        tw(kbBtn, TIF, {BackgroundColor3 = C.surfaceHi})
        return
    end
    -- quick fire keybind listener
    if qfListening then
        quickFireKey = inp.KeyCode
        qfBtn.Text = quickFireKey.Name
        qfListening = false
        tw(qfBtn, TIF, {BackgroundColor3 = C.surfaceHi})
        saveMervanSettings()
        return
    end
    if gpe then return end
    -- toggle ui
    if inp.KeyCode == toggleKey then
        if uiVisible then hideGui() else showGui() end
    end
    -- quick fire latest event
    if quickFireKey and inp.KeyCode == quickFireKey and latestEvent then
        fireFakeSignal(latestEvent.sigType, latestEvent.id)
        showToast("Fired  " .. tostring(latestEvent.id), C.accent)
    end
end))

-- Pre-select Listener tab (so content is visible when panel reveals)
switchTab("Listener")
setEmpty(true)

-- Load saved pinned entries from workspace
do
    local saved = loadPinnedFromFile()
    for _, d in ipairs(saved) do
        if d.id and d.sigType then
            addPinnedEntry(d.id, d.sigType, d.displayName, true)
        end
    end
end

-- MARKETPLACE LISTENERS
pcall(function()
    table.insert(_conns, MPS.PromptProductPurchaseFinished:Connect(function(_, id, _)
        if suppressCounter == 0 then addLog("Product", id, "Product") end
    end))
end)
pcall(function()
    table.insert(_conns, MPS.PromptGamePassPurchaseFinished:Connect(function(_, id, _)
        if suppressCounter == 0 then addLog("Gamepass", id, "Gamepass") end
    end))
end)
pcall(function()
    table.insert(_conns, MPS.PromptBulkPurchaseFinished:Connect(function(_, id, _)
        if suppressCounter == 0 then addLog("Bulk", id, "Bulk") end
    end))
end)
pcall(function()
    table.insert(_conns, MPS.PromptPurchaseFinished:Connect(function(_, id, _)
        if suppressCounter == 0 then addLog("Purchase", id, "Purchase") end
    end))
end)

print("[Mervan Services] v1.0 loaded")
print("discord.gg/mervan")
