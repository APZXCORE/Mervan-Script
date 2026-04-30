-- vyvs hub v4 by seluwia

local Players          = game:GetService("Players")
local TeleportService  = game:GetService("TeleportService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LP  = Players.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui")

if PG:FindFirstChild("VyvsHub") then PG.VyvsHub:Destroy() end
local HS = game:GetService("HttpService")

-- settings (saved to workspace/vyv_settings.json)
local SETTINGS_FILE = "vyv_settings.json"
local settings = { mode = "most" } -- most players or best ping

local function saveSettings()
    pcall(function() if writefile then writefile(SETTINGS_FILE, HS:JSONEncode(settings)) end end)
end

local function loadSettings()
    pcall(function()
        if isfile and isfile(SETTINGS_FILE) then
            local data = HS:JSONDecode(readfile(SETTINGS_FILE))
            if data and type(data) == "table" then settings = data end
        else
            saveSettings()
        end
    end)
end
loadSettings()

-- games list
local GAMES = {
    { name = "Infinite Gear Tower",           id = 114632393617173 },
    { name = "YEET Troll Tower",              id = 131613915463964 },
    { name = "Nakakainis Na Laser Tower",     id = 77451737406508  },
    { name = "IQ Test Laser Tower",           id = 88993574192386  },
    { name = "Basic Na Laser Tower",          id = 123882157996955 },
    { name = "Exploding Na Laser Tower 2",    id = 93052351618271  },
    { name = "Makulay Na Laser Tower",        id = 128334198813458 },
    { name = "Mahirap Na Laser Tower 2",      id = 88761612446816  },
    { name = "Exploding Na Laser Tower",      id = 94754832944762  },
    { name = "Challenging Na Laser Tower",    id = 139733039793068 },
    { name = "Basic Na Laser Tower 2",        id = 74235991966880  },
    { name = "UNDERGROUND SHOP",              id = 72576893121513  },
    { name = "Mechanical Keyboard Tower",     id = 91229101932140  },
    { name = "Anime Tower",                   id = 13753090786     },
    { name = "Tower Of Candy",                id = 17612027930     },
    { name = "Rizz Tower",                    id = 108207853263201 },
    { name = "1 Jump Coil Escape",            id = 122363080663758 },
    { name = "100 Player Lava Escape",        id = 135535794227264 },
    { name = "Troll Tower Reborn",            id = 121518011796911 },
    { name = "MEGA IMPOSSIBLE OBBY",          id = 87437805664415  },
    { name = "Aura Edit Arena",               id = 106502313058092 },
    { name = "ANIME ABILITIES TOWER",         id = 103661214879860 },
    { name = "Phonk Troll Tower",             id = 114542099863393 },
    { name = "Raise a Floppa 2",              id = 9772878203      },
    { name = "Player or AI",                  id = 95217169945642  },
    { name = "Speeds Wall Hop Obby",          id = 101819119929603 },
    { name = "Infinite HD Admin Tower",       id = 137521538279053 },
    { name = "1 Speed Hospital Rescue",       id = 105791676851991 },
    { name = "1 Speed Unicycle Escape",       id = 70860953256036  },
    { name = "Escape the Nuke as Brainrot",   id = 112686931168882 },
}


-- colors
local BG      = Color3.fromRGB(12,  12,  12 )
local TOPBG   = Color3.fromRGB(18,  18,  18 )
local SRCHBG  = Color3.fromRGB(22,  22,  22 )
local CARDBG  = Color3.fromRGB(26,  26,  26 )
local CARDHOV = Color3.fromRGB(36,  36,  36 )
local THUMBBG = Color3.fromRGB(20,  20,  20 )
local BORDER  = Color3.fromRGB(46,  46,  46 )
local TPBG    = Color3.fromRGB(52,  52,  52 )
local TPHOV   = Color3.fromRGB(72,  72,  72 )
local CPBG    = Color3.fromRGB(34,  34,  34 )
local CPHOV   = Color3.fromRGB(50,  50,  50 )
local CLO     = Color3.fromRGB(52,  52,  52 )
local CLOHOV  = Color3.fromRGB(180, 45,  45 )
local TXT     = Color3.fromRGB(222, 222, 222)
local SUBT    = Color3.fromRGB(90,  90,  90 )
local DIM     = Color3.fromRGB(62,  62,  62 )
local DOTC    = Color3.fromRGB(88,  210, 108)
local TOASTBG = Color3.fromRGB(34,  34,  34 )
local TOAERR  = Color3.fromRGB(150, 38,  38 )
local W3      = Color3.new(1,1,1)

-- helpers
local function tw(o,p,t)
    TweenService:Create(o,TweenInfo.new(t or .15,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),p):Play()
end

-- rounded corners
local function rc(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
    return c
end

-- stroke/border
local function st(obj, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or BORDER
    s.Thickness = th or 1
    s.Parent = obj
    return s
end

-- frame shortcut
local function FR(nm, bg, par)
    local f = Instance.new("Frame")
    f.Name = nm ; f.BackgroundColor3 = bg or CARDBG
    f.BorderSizePixel = 0 ; f.Parent = par
    return f
end

-- label shortcut
local function LB(nm, tx, sz, col, par)
    local l = Instance.new("TextLabel")
    l.Name = nm ; l.Text = tx ; l.TextSize = sz or 12
    l.TextColor3 = col or TXT ; l.Font = Enum.Font.GothamBold
    l.BackgroundTransparency = 1 ; l.BorderSizePixel = 0
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = par ; return l
end

-- button shortcut
local function BT(nm, tx, bg, tc, par)
    local b = Instance.new("TextButton")
    b.Name = nm ; b.Text = tx ; b.TextSize = 10
    b.Font = Enum.Font.GothamBold ; b.TextColor3 = tc or TXT
    b.BackgroundColor3 = bg or TPBG
    b.BorderSizePixel = 0 ; b.AutoButtonColor = false
    b.Parent = par ; return b
end

-- gui setup
local Gui = Instance.new("ScreenGui")
Gui.Name = "VyvsHub" ; Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 999 ; Gui.Parent = PG

-- main window
local MW, MH = 830, 544
local Main = FR("Main", BG, Gui)
Main.Size = UDim2.fromOffset(MW, MH)
Main.Position = UDim2.new(.5, -MW/2, .5, -MH/2)
Main.ClipsDescendants = true
rc(Main, 12) ; st(Main, BORDER, 1)

-- top bar
local TB = FR("TB", TOPBG, Main)
TB.Size = UDim2.new(1,0,0,44) ; TB.ZIndex = 6
rc(TB, 12)

-- fills the bottom so only top corners are rounded
local TB_Fill = FR("TB_Fill", TOPBG, TB)
TB_Fill.Size = UDim2.new(1,0,0,20) ; TB_Fill.Position = UDim2.new(0,0,1,-20)
TB_Fill.ZIndex = 6 ; TB_Fill.BorderSizePixel = 0

-- line between top bar and content
local Sep = FR("Sep", BORDER, TB)
Sep.Size = UDim2.new(1,0,0,1) ; Sep.Position = UDim2.new(0,0,1,-1) ; Sep.ZIndex = 7

local Br = LB("Brand","vyvs",16,TXT,TB)
Br.Size=UDim2.new(0,60,1,0) ; Br.Position=UDim2.new(.5,-45,0,0)
Br.Font=Enum.Font.GothamBlack ; Br.ZIndex=7 ; Br.TextXAlignment=Enum.TextXAlignment.Center

local Sb = LB("Sub","seluwia",10,SUBT,TB)
Sb.Size=UDim2.new(0,60,1,0) ; Sb.Position=UDim2.new(.5,15,0,2)
Sb.Font=Enum.Font.Gotham ; Sb.ZIndex=7 ; Sb.TextXAlignment=Enum.TextXAlignment.Left

local Dc = LB("Dc",".gg/vyvs",10,SUBT,TB)
Dc.Size=UDim2.fromOffset(60,44) ; Dc.Position=UDim2.fromOffset(14,0)
Dc.Font=Enum.Font.Gotham ; Dc.ZIndex=7

local Pill = FR("Pill",SRCHBG,TB)
Pill.Size=UDim2.fromOffset(64,18) ; Pill.Position=UDim2.new(1,-108,.5,-9)
Pill.ZIndex=7 ; rc(Pill,9) ; st(Pill,BORDER,1)

local PL = LB("PL", #GAMES.." games", 9, SUBT, Pill)
PL.Size=UDim2.new(1,0,1,0) ; PL.TextXAlignment=Enum.TextXAlignment.Center
PL.Font=Enum.Font.Gotham ; PL.ZIndex=8

-- close btn
local XB = BT("X","x",CLO,TXT,TB)
XB.Size=UDim2.fromOffset(26,26) ; XB.Position=UDim2.new(1,-36,.5,-13)
XB.TextSize=12 ; XB.ZIndex=7 ; rc(XB,6)
XB.MouseEnter:Connect(function() tw(XB,{BackgroundColor3=CLOHOV,TextColor3=W3}) end)
XB.MouseLeave:Connect(function() tw(XB,{BackgroundColor3=CLO,TextColor3=TXT})   end)
XB.MouseButton1Click:Connect(function() Gui:Destroy() end)

-- search bar
local SBG = FR("SBG",SRCHBG,Main)
SBG.Size=UDim2.new(1,-20,0,32) ; SBG.Position=UDim2.fromOffset(10,52)
SBG.ZIndex=5 ; rc(SBG,8) ; st(SBG,BORDER,1)

local SBox = Instance.new("TextBox")
SBox.PlaceholderText="search games..."
SBox.PlaceholderColor3=SUBT ; SBox.Text=""
SBox.TextSize=12 ; SBox.Font=Enum.Font.Gotham
SBox.TextColor3=TXT ; SBox.BackgroundTransparency=1
SBox.BorderSizePixel=0 ; SBox.ClearTextOnFocus=false
SBox.Size=UDim2.new(1,-14,1,0) ; SBox.Position=UDim2.fromOffset(10,0)
SBox.TextXAlignment=Enum.TextXAlignment.Left
SBox.ZIndex=6 ; SBox.Parent=SBG

-- scrolling area
local SF = Instance.new("ScrollingFrame")
SF.Name="SF" ; SF.Size=UDim2.new(1,-20,1,-94)
SF.Position=UDim2.fromOffset(10,92)
SF.CanvasSize=UDim2.new(0,0,0,0)
SF.AutomaticCanvasSize=Enum.AutomaticSize.Y
SF.ScrollBarThickness=3
SF.ScrollBarImageColor3=DIM
SF.BorderSizePixel=0 ; SF.BackgroundTransparency=1
SF.ScrollingDirection=Enum.ScrollingDirection.Y
SF.ElasticBehavior=Enum.ElasticBehavior.Always
SF.ZIndex=4 ; SF.Parent=Main

local Grid = Instance.new("UIGridLayout")
Grid.CellSize=UDim2.fromOffset(192,202)
Grid.CellPadding=UDim2.fromOffset(10,10)
Grid.SortOrder=Enum.SortOrder.LayoutOrder
Grid.Parent=SF

local GPad = Instance.new("UIPadding")
GPad.PaddingTop=UDim.new(0,8) ; GPad.PaddingLeft=UDim.new(0,6)
GPad.PaddingRight=UDim.new(0,6) ; GPad.PaddingBottom=UDim.new(0,10)
GPad.Parent=SF

-- toast notifications
local Toast = FR("Toast",TOASTBG,Main)
Toast.Size=UDim2.new(1,-20,0,28)
Toast.Position=UDim2.new(0,10,1,40)
Toast.BackgroundTransparency=0.05 ; Toast.ZIndex=20
rc(Toast,7) ; st(Toast,BORDER,1)

local TL = LB("TL","",11,TXT,Toast)
TL.Size=UDim2.new(1,-14,1,0) ; TL.Position=UDim2.fromOffset(7,0)
TL.Font=Enum.Font.Gotham ; TL.ZIndex=21


local busy=false
local function showToast(msg,err)
    if busy then return end ; busy=true
    Toast.BackgroundColor3 = err and TOAERR or TOASTBG
    TL.Text=msg
    tw(Toast,{Position=UDim2.new(0,10,1,-36)},0.22)
    task.delay(2.4,function()
        tw(Toast,{Position=UDim2.new(0,10,1,40)},0.22)
        task.delay(.3,function() busy=false end)
    end)
end

-- game cards

local cards = {}

for i, g in ipairs(GAMES) do

    local Card = FR("Card",CARDBG,SF)
    Card.LayoutOrder=i ; Card.ZIndex=5
    Card.ClipsDescendants=true
    rc(Card,10) ; st(Card,BORDER,1)

    -- thumbnail
    local TH = FR("TH",THUMBBG,Card)
    TH.Size=UDim2.fromOffset(192,120)
    TH.Position=UDim2.fromOffset(0,0)
    TH.ZIndex=6
    TH.ClipsDescendants=true
    rc(TH,10)

    -- game icon
    local Img = Instance.new("ImageLabel")
    Img.Size=UDim2.new(1,0,1,0)
    Img.BackgroundTransparency=1
    Img.ScaleType=Enum.ScaleType.Crop
    Img.ZIndex=7
    Img.Image="https://www.roblox.com/asset-thumbnail/image?assetId="..tostring(g.id).."&width=420&height=420&format=png"
    Img.Parent=TH
    rc(Img, 10)

    -- online dot
    local Dot=FR("Dot",DOTC,Card)
    Dot.Size=UDim2.fromOffset(6,6)
    Dot.Position=UDim2.new(1,-10,0,7)
    Dot.ZIndex=8 ; rc(Dot,3)

    -- game name
    local NL=LB("N",g.name,12,TXT,Card)
    NL.Size=UDim2.new(1,-10,0,20) ; NL.Position=UDim2.fromOffset(6,124)
    NL.TextTruncate=Enum.TextTruncate.AtEnd ; NL.ZIndex=6

    -- place id
    local IL=LB("I","id: "..tostring(g.id),8,SUBT,Card)
    IL.Size=UDim2.new(1,-10,0,14) ; IL.Position=UDim2.fromOffset(6,144)
    IL.Font=Enum.Font.Gotham ; IL.ZIndex=6

    -- buttons
    local Row=FR("Row",CARDBG,Card)
    Row.Size=UDim2.new(1,-12,0,32) ; Row.Position=UDim2.fromOffset(6,160)
    Row.BackgroundTransparency=1 ; Row.ZIndex=6

    -- tp btn
    local Tp=BT("Tp","TELEPORT",TPBG,TXT,Row)
    Tp.Size=UDim2.new(1,-36,1,0)
    Tp.Font=Enum.Font.GothamBlack ; Tp.TextSize=10
    Tp.ZIndex=7 ; rc(Tp,6) ; st(Tp,BORDER,1)

    -- copy btn
    local Cp=BT("Cp","#",CPBG,DIM,Row)
    Cp.Size=UDim2.fromOffset(28,32) ; Cp.Position=UDim2.new(1,-28,0,0)
    Cp.TextSize=13 ; Cp.ZIndex=7 ; rc(Cp,6) ; st(Cp,BORDER,1)

    -- hover effects
    Card.MouseEnter:Connect(function() tw(Card,{BackgroundColor3=CARDHOV}) end)
    Card.MouseLeave:Connect(function() tw(Card,{BackgroundColor3=CARDBG})  end)
    Tp.MouseEnter:Connect(function()   tw(Tp,  {BackgroundColor3=TPHOV})   end)
    Tp.MouseLeave:Connect(function()   tw(Tp,  {BackgroundColor3=TPBG})    end)
    Cp.MouseEnter:Connect(function()   tw(Cp,  {BackgroundColor3=CPHOV,TextColor3=TXT}) end)
    Cp.MouseLeave:Connect(function()   tw(Cp,  {BackgroundColor3=CPBG,TextColor3=DIM})  end)

    -- tp click
    Tp.MouseButton1Click:Connect(function()
        showToast("teleporting to "..g.name.."...")
        task.spawn(function()
            local placeId = g.id

            -- bump identity so tp doesnt get blocked
            pcall(function()
                if setthreadidentity then setthreadidentity(8)
                elseif setidentity then setidentity(8)
                elseif syn and syn.set_thread_identity then syn.set_thread_identity(8)
                end
            end)

            -- queue script for after tp
            pcall(function()
                if queue_on_teleport then queue_on_teleport("") end
            end)

            -- try tp
            local ok, err = pcall(function()
                TeleportService:Teleport(placeId, LP)
            end)

            if not ok then
                -- fallback
                ok, err = pcall(function()
                    TeleportService:Teleport(placeId)
                end)
            end

            if not ok then
                showToast("blocked by game — try from lobby", true)
            end
        end)
    end)



    -- copy click
    Cp.MouseButton1Click:Connect(function()
        local url="https://www.roblox.com/games/"..tostring(g.id)
        if setclipboard then setclipboard(url)
        elseif syn and syn.clipboard then syn.clipboard.set(url)
        end
        showToast("copied  //  "..g.name)
    end)

    table.insert(cards,{card=Card,name=g.name:lower()})
end

-- search filter
SBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q=SBox.Text:lower()
    for _,e in ipairs(cards) do
        e.card.Visible=(q=="" or e.name:find(q,1,true)~=nil)
    end
end)

-- drag to move
do
    local drag,di,ds,sp
    TB.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true ; ds=i.Position ; sp=Main.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    TB.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then di=i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i==di then
            local d=i.Position-ds
            Main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- console prints
print("─────────────────────────────")
print("  vyvs hub v4")
print("  made by seluwia")
print("  discord.gg/vyvs")
print("  https://www.roblox.com/games/79012522/Boomhamzas-Place")
print("─────────────────────────────")
print("[vyvs v4] ready — "..#GAMES.." games")

-- loaded toast
task.delay(.2,function() showToast("vyvs  //  "..#GAMES.." games loaded") end)

-- bottom right warning popup
do
    local Warn = FR("Warn", Color3.fromRGB(30, 30, 30), Gui)
    Warn.Size = UDim2.fromOffset(280, 48)
    Warn.Position = UDim2.new(1, -290, 1, 60) -- starts offscreen
    Warn.ZIndex = 30
    rc(Warn, 8) ; st(Warn, BORDER, 1)

    local WIcon = LB("WI", "⚠️", 16, Color3.fromRGB(255, 190, 60), Warn)
    WIcon.Size = UDim2.fromOffset(30, 48)
    WIcon.Position = UDim2.fromOffset(8, 0)
    WIcon.TextXAlignment = Enum.TextXAlignment.Center
    WIcon.ZIndex = 31

    local WTxt = LB("WT", "join Boomhamza's Place for tp to work", 10, TXT, Warn)
    WTxt.Size = UDim2.new(1, -44, 1, 0)
    WTxt.Position = UDim2.fromOffset(36, 0)
    WTxt.Font = Enum.Font.Gotham
    WTxt.TextWrapped = true
    WTxt.ZIndex = 31

    -- slide in after a short delay
    task.delay(1, function()
        tw(Warn, {Position = UDim2.new(1, -290, 1, -58)}, 0.3)
    end)

    -- auto dismiss after 8 seconds
    task.delay(9, function()
        tw(Warn, {Position = UDim2.new(1, -290, 1, 60)}, 0.3)
        task.delay(0.4, function() Warn:Destroy() end)
    end)
end
