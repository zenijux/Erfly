--Menu

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()
local Window = Library.CreateLib("Erfy | by silphy hacker`s ~ by zen, "RJTheme6")
local Tab = Window:NewTab("Visual")
local Section = Tab:NewSection("thx for using!")

Section:NewButton("ESP", "Подсвечивает игроков", function()
--[[
A distribution of https://wearedevs.net/scripts
Created August 17, 2021, Last updated August 17, 2021

Description: Draws boxes around each player.

Credits to "Real Panda" for their ESP library

Instruction: Edit the settings as desired below and execute the script.

Settings: 
Replace "nil" with "true" to enable the setting, or "false" to disable the setting. Without the quotes. 
If you do not change "nil", the defaults will take place.
]]
_G.WRDESPEnabled = nil --Enables the ESP (Defaults to true)
_G.WRDESPBoxes = nil --Draws boxes around other players (Defaults to true)
_G.WRDESPTeamColors = nil --Distinguish different teams by their team color. If the game sets one. (Defaults to true)
_G.WRDESPTracers = nil --Displays lines leading to other players (Defaults to false)
_G.WRDESPNames = nil --Displays the names of the players within the ESP box (Defaults to true)

--Dont edit below

--Only ever load the script once
if not _G.WRDESPLoaded then    
    ----[[ First- Load Kiriot ESP Library ]]----

    --Settings--
    local ESP = {
        Enabled = false,
        Boxes = true,
        BoxShift = CFrame.new(0,-1.5,0),
        BoxSize = Vector3.new(4,6,0),
        Color = Color3.fromRGB(255, 170, 0),
        FaceCamera = false,
        Names = false,
        TeamColor = true,
        Thickness = 2,
        AttachShift = 1,
        TeamMates = true,
        Players = true,
        
        Objects = setmetatable({}, {__mode="kv"}),
        Overrides = {}
    }

    --Declarations--
    local cam = workspace.CurrentCamera
    local plrs = game:GetService("Players")
    local plr = plrs.LocalPlayer
    local mouse = plr:GetMouse()

    local V3new = Vector3.new
    local WorldToViewportPoint = cam.WorldToViewportPoint

    --Functions--
    local function Draw(obj, props)
        local new = Drawing.new(obj)
        
        props = props or {}
        for i,v in pairs(props) do
            new[i] = v
        end
        return new
    end

    function ESP:GetTeam(p)
        local ov = self.Overrides.GetTeam
        if ov then
            return ov(p)
        end
        
        return p and p.Team
    end

    function ESP:IsTeamMate(p)
        local ov = self.Overrides.IsTeamMate
        if ov then
            return ov(p)
        end
        
        return self:GetTeam(p) == self:GetTeam(plr)
    end

    function ESP:GetColor(obj)
        local ov = self.Overrides.GetColor
        if ov then
            return ov(obj)
        end
        local p = self:GetPlrFromChar(obj)
        return p and self.TeamColor and p.Team and p.Team.TeamColor.Color or self.Color
    end

    function ESP:GetPlrFromChar(char)
        local ov = self.Overrides.GetPlrFromChar
        if ov then
            return ov(char)
        end
        
        return plrs:GetPlayerFromCharacter(char)
    end

    function ESP:Toggle(bool)
        self.Enabled = bool
        if not bool then
            for i,v in pairs(self.Objects) do
                if v.Type == "Box" then --fov circle etc
                    if v.Temporary then
                        v:Remove()
                    else
                        for i,v in pairs(v.Components) do
                            v.Visible = false
                        end
                    end
                end
            end
        end
    end

    function ESP:GetBox(obj)
        return self.Objects[obj]
    end

    function ESP:AddObjectListener(parent, options)
        local function NewListener(c)
            if type(options.Type) == "string" and c:IsA(options.Type) or options.Type == nil then
                if type(options.Name) == "string" and c.Name == options.Name or options.Name == nil then
                    if not options.Validator or options.Validator(c) then
                        local box = ESP:Add(c, {
                            PrimaryPart = type(options.PrimaryPart) == "string" and c:WaitForChild(options.PrimaryPart) or type(options.PrimaryPart) == "function" and options.PrimaryPart(c),
                            Color = type(options.Color) == "function" and options.Color(c) or options.Color,
                            ColorDynamic = options.ColorDynamic,
                            Name = type(options.CustomName) == "function" and options.CustomName(c) or options.CustomName,
                            IsEnabled = options.IsEnabled,
                            RenderInNil = options.RenderInNil
                        })
                        --TODO: add a better way of passing options
                        if options.OnAdded then
                            coroutine.wrap(options.OnAdded)(box)
                        end
                    end
                end
            end
        end

        if options.Recursive then
            parent.DescendantAdded:Connect(NewListener)
            for i,v in pairs(parent:GetDescendants()) do
                coroutine.wrap(NewListener)(v)
            end
        else
            parent.ChildAdded:Connect(NewListener)
            for i,v in pairs(parent:GetChildren()) do
                coroutine.wrap(NewListener)(v)
            end
        end
    end

    local boxBase = {}
    boxBase.__index = boxBase

    function boxBase:Remove()
        ESP.Objects[self.Object] = nil
        for i,v in pairs(self.Components) do
            v.Visible = false
            v:Remove()
            self.Components[i] = nil
        end
    end

    function boxBase:Update()
        if not self.PrimaryPart then
            --warn("not supposed to print", self.Object)
            return self:Remove()
        end

        local color
        if ESP.Highlighted == self.Object then
        color = ESP.HighlightColor
        else
            color = self.Color or self.ColorDynamic and self:ColorDynamic() or ESP:GetColor(self.Object) or ESP.Color
        end

        local allow = true
        if ESP.Overrides.UpdateAllow and not ESP.Overrides.UpdateAllow(self) then
            allow = false
        end
        if self.Player and not ESP.TeamMates and ESP:IsTeamMate(self.Player) then
            allow = false
        end
        if self.Player and not ESP.Players then
            allow = false
        end
        if self.IsEnabled and (type(self.IsEnabled) == "string" and not ESP[self.IsEnabled] or type(self.IsEnabled) == "function" and not self:IsEnabled()) then
            allow = false
        end
        if not workspace:IsAncestorOf(self.PrimaryPart) and not self.RenderInNil then
            allow = false
        end

        if not allow then
            for i,v in pairs(self.Components) do
                v.Visible = false
            end
            return
        end

        if ESP.Highlighted == self.Object then
            color = ESP.HighlightColor
        end

        --calculations--
        local cf = self.PrimaryPart.CFrame
        if ESP.FaceCamera then
            cf = CFrame.new(cf.p, cam.CFrame.p)
        end
        local size = self.Size
        local locs = {
            TopLeft = cf * ESP.BoxShift * CFrame.new(size.X/2,size.Y/2,0),
            TopRight = cf * ESP.BoxShift * CFrame.new(-size.X/2,size.Y/2,0),
            BottomLeft = cf * ESP.BoxShift * CFrame.new(size.X/2,-size.Y/2,0),
            BottomRight = cf * ESP.BoxShift * CFrame.new(-size.X/2,-size.Y/2,0),
            TagPos = cf * ESP.BoxShift * CFrame.new(0,size.Y/2,0),
            Torso = cf * ESP.BoxShift
        }

        if ESP.Boxes then
            local TopLeft, Vis1 = WorldToViewportPoint(cam, locs.TopLeft.p)
            local TopRight, Vis2 = WorldToViewportPoint(cam, locs.TopRight.p)
            local BottomLeft, Vis3 = WorldToViewportPoint(cam, locs.BottomLeft.p)
            local BottomRight, Vis4 = WorldToViewportPoint(cam, locs.BottomRight.p)

            if self.Components.Quad then
                if Vis1 or Vis2 or Vis3 or Vis4 then
                    self.Components.Quad.Visible = true
                    self.Components.Quad.PointA = Vector2.new(TopRight.X, TopRight.Y)
                    self.Components.Quad.PointB = Vector2.new(TopLeft.X, TopLeft.Y)
                    self.Components.Quad.PointC = Vector2.new(BottomLeft.X, BottomLeft.Y)
                    self.Components.Quad.PointD = Vector2.new(BottomRight.X, BottomRight.Y)
                    self.Components.Quad.Color = color
                else
                    self.Components.Quad.Visible = false
                end
            end
        else
            self.Components.Quad.Visible = false
        end

        if ESP.Names then
            local TagPos, Vis5 = WorldToViewportPoint(cam, locs.TagPos.p)
            
            if Vis5 then
                self.Components.Name.Visible = true
                self.Components.Name.Position = Vector2.new(TagPos.X, TagPos.Y)
                self.Components.Name.Text = self.Name
                self.Components.Name.Color = color
                
                self.Components.Distance.Visible = true
                self.Components.Distance.Position = Vector2.new(TagPos.X, TagPos.Y + 14)
                self.Components.Distance.Text = math.floor((cam.CFrame.p - cf.p).magnitude) .."m away"
                self.Components.Distance.Color = color
            else
                self.Components.Name.Visible = false
                self.Components.Distance.Visible = false
            end
        else
            self.Components.Name.Visible = false
            self.Components.Distance.Visible = false
        end
        
        if ESP.Tracers then
            local TorsoPos, Vis6 = WorldToViewportPoint(cam, locs.Torso.p)

            if Vis6 then
                self.Components.Tracer.Visible = true
                self.Components.Tracer.From = Vector2.new(TorsoPos.X, TorsoPos.Y)
                self.Components.Tracer.To = Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/ESP.AttachShift)
                self.Components.Tracer.Color = color
            else
                self.Components.Tracer.Visible = false
            end
        else
            self.Components.Tracer.Visible = false
        end
    end

    function ESP:Add(obj, options)
        if not obj.Parent and not options.RenderInNil then
            return warn(obj, "has no parent")
        end

        local box = setmetatable({
            Name = options.Name or obj.Name,
            Type = "Box",
            Color = options.Color --[[or self:GetColor(obj)]],
            Size = options.Size or self.BoxSize,
            Object = obj,
            Player = options.Player or plrs:GetPlayerFromCharacter(obj),
            PrimaryPart = options.PrimaryPart or obj.ClassName == "Model" and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj:IsA("BasePart") and obj,
            Components = {},
            IsEnabled = options.IsEnabled,
            Temporary = options.Temporary,
            ColorDynamic = options.ColorDynamic,
            RenderInNil = options.RenderInNil
        }, boxBase)

        if self:GetBox(obj) then
            self:GetBox(obj):Remove()
        end

        box.Components["Quad"] = Draw("Quad", {
            Thickness = self.Thickness,
            Color = color,
            Transparency = 1,
            Filled = false,
            Visible = self.Enabled and self.Boxes
        })
        box.Components["Name"] = Draw("Text", {
            Text = box.Name,
            Color = box.Color,
            Center = true,
            Outline = true,
            Size = 19,
            Visible = self.Enabled and self.Names
        })
        box.Components["Distance"] = Draw("Text", {
            Color = box.Color,
            Center = true,
            Outline = true,
            Size = 19,
            Visible = self.Enabled and self.Names
        })
        
        box.Components["Tracer"] = Draw("Line", {
            Thickness = ESP.Thickness,
            Color = box.Color,
            Transparency = 1,
            Visible = self.Enabled and self.Tracers
        })
        self.Objects[obj] = box
        
        obj.AncestryChanged:Connect(function(_, parent)
            if parent == nil and ESP.AutoRemove ~= false then
                box:Remove()
            end
        end)
        obj:GetPropertyChangedSignal("Parent"):Connect(function()
            if obj.Parent == nil and ESP.AutoRemove ~= false then
                box:Remove()
            end
        end)

        local hum = obj:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                if ESP.AutoRemove ~= false then
                    box:Remove()
                end
            end)
        end

        return box
    end

    local function CharAdded(char)
        local p = plrs:GetPlayerFromCharacter(char)
        if not char:FindFirstChild("HumanoidRootPart") then
            local ev
            ev = char.ChildAdded:Connect(function(c)
                if c.Name == "HumanoidRootPart" then
                    ev:Disconnect()
                    ESP:Add(char, {
                        Name = p.Name,
                        Player = p,
                        PrimaryPart = c
                    })
                end
            end)
        else
            ESP:Add(char, {
                Name = p.Name,
                Player = p,
                PrimaryPart = char.HumanoidRootPart
            })
        end
    end
    local function PlayerAdded(p)
        p.CharacterAdded:Connect(CharAdded)
        if p.Character then
            coroutine.wrap(CharAdded)(p.Character)
        end
    end
    plrs.PlayerAdded:Connect(PlayerAdded)
    for i,v in pairs(plrs:GetPlayers()) do
        if v ~= plr then
            PlayerAdded(v)
        end
    end

    game:GetService("RunService").RenderStepped:Connect(function()
        cam = workspace.CurrentCamera
        for i,v in (ESP.Enabled and pairs or ipairs)(ESP.Objects) do
            if v.Update then
                local s,e = pcall(v.Update, v)
                if not s then warn("[EU]", e, v.Object:GetFullName()) end
            end
        end
    end)

    ----[[ Now Begins WRD's modification for implementation ]]----

    --Sets defaults where required
    if _G.WRDESPEnabled == nil then _G.WRDESPEnabled = true end
    if _G.WRDESPBoxes == nil then _G.WRDESPBoxes = true end
    if _G.WRDESPTeamColors == nil then _G.WRDESPTeamColors = true end
    if _G.WRDESPTracers == nil then _G.WRDESPTracers = false end
    if _G.WRDESPNames == nil then _G.WRDESPNames = false end
	
	--Hacky way to keep up with setting changes
    while wait(.1) do
        ESP:Toggle(_G.WRDESPEnabled or false)
        ESP.Boxes = _G.WRDESPBoxes or false
        ESP.TeamColors = _G.WRDESPTeamColors or false
        ESP.Tracers = _G.WRDESPTracers or false
        ESP.Names = _G.WRDESPNames or false
    end

    _G.WRDESPLoaded = true
end
end)

-- Секция
local Tab = Window:NewTab("Rage")

-- Кнопка
Section:NewButton("AimBot", "По умолчанию TeamCheck и Wall Check", function()
    -- Copyright https://WeAreDevs.net 2019
-- https://wearedevs.net/exploits

--[[ Configuration ]]--

--If true, 
	--Players on the same team will not be aimed at
	--Will not work in games with custom team systems
--If false,
	--All players in the game will be aimed at
    _G.WRDAimbotTeamCheck = true

    --If true, 
        --Simulates mouse movement. Its as if you actually moved your mouse onto the player, meaning this is harder to detect
        --Tradeoff is it comes with a lot of bugs. Lacks smoothness, not 100% accurate, and can't aim at players dirrectly behind.
    --If false, 
        --Will use camera manipulation. 
        --This is the smoothest and most accurate, but games can detect this easy. Be careful with what games you use false in.
        --May be buggy for 3rd person games!
    _G.WRDAimbotBypass = false
    
    --If true, the aimbot will only look for the closest visible player
        --Buggy for 3rd person games!
        --May cause heavy lag
    --If false, the aimbot will look for all players, even if they're behind a wall
    _G.WRDAimBotWallcheck = true
    
    --[[ 
    
    Additional Notes | August 17, 2019
    
    *This was made for exploits using the WeAreDevs API, such as JJSploit.
    *Please don't steal credits. I worked pretty hard on this ;c
    *This should be able to work in all games using default Roblox character systems. Games using using custom/modified characters may be buggy, such as Strucid and Phantom Forces.
    *You don't need to rexecute the entire script to change configuration above. You could simply execute the desired configuration line.
    *Rexecuting the script should not cause issues
    *The WRDAimbotBypass enabled bug involving players behind you will be fixed eventually. Be sure to check the website time to time!
    *Aimbot starts when you hold the right mouse button
    *This aimbot snaps aims to the closest player's head.
    *Please change the configuration below appropriately.
    *Check the website occasionally for updates!
    *Found a new bug? Report it on the forum: https://wearedevs.net/forum/complaints
    
    ]]--
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    --[[
    
    WARNING: Editing below may break the script!
    
    ]]--
    
    local SynapseXen_iiilliIiI=select;local SynapseXen_IIIIillIIIliIl=string.byte;local SynapseXen_iIiIlIillIlliili=string.sub;local SynapseXen_iillI=string.char;local SynapseXen_iIiiiIIiIlllIliIi=type;local SynapseXen_iIIIIlIliiliIiIll=table.concat;local unpack=unpack;local setmetatable=setmetatable;local pcall=pcall;local SynapseXen_lIilIiiIiIiIliIi,SynapseXen_iiililIlIiiliiillIlI,SynapseXen_lilIiIlliIi,SynapseXen_IIIiiiiiilIiiiilii;if bit and bit.bxor then SynapseXen_lIilIiiIiIiIliIi=bit.bxor;SynapseXen_iiililIlIiiliiillIlI=function(SynapseXen_iiiii,SynapseXen_iiiiIllill)local SynapseXen_ilIiiiillII=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_iiiii,SynapseXen_iiiiIllill)if SynapseXen_ilIiiiillII<0 then SynapseXen_ilIiiiillII=4294967296+SynapseXen_ilIiiiillII end;return SynapseXen_ilIiiiillII end else SynapseXen_lIilIiiIiIiIliIi=function(SynapseXen_iiiii,SynapseXen_iiiiIllill)local SynapseXen_IilliIliliI=function(SynapseXen_llliiiIIil,SynapseXen_lllli)return SynapseXen_llliiiIIil%(SynapseXen_lllli*2)>=SynapseXen_lllli end;local SynapseXen_lIiiilIlIiiIIlII=0;for SynapseXen_lllilIIIllililIIlIi=0,31 do SynapseXen_lIiiilIlIiiIIlII=SynapseXen_lIiiilIlIiiIIlII+(SynapseXen_IilliIliliI(SynapseXen_iiiii,2^SynapseXen_lllilIIIllililIIlIi)~=SynapseXen_IilliIliliI(SynapseXen_iiiiIllill,2^SynapseXen_lllilIIIllililIIlIi)and 2^SynapseXen_lllilIIIllililIIlIi or 0)end;return SynapseXen_lIiiilIlIiiIIlII end;SynapseXen_iiililIlIiiliiillIlI=SynapseXen_lIilIiiIiIiIliIi end;SynapseXen_lilIiIlliIi=function(SynapseXen_lIiIIlIIliiiiliIiIiI,SynapseXen_lIliIilllllIIIIli,SynapseXen_iIllIiiliiliI)return(SynapseXen_lIiIIlIIliiiiliIiIiI+SynapseXen_lIliIilllllIIIIli)%SynapseXen_iIllIiiliiliI end;SynapseXen_IIIiiiiiilIiiiilii=function(SynapseXen_lIiIIlIIliiiiliIiIiI,SynapseXen_lIliIilllllIIIIli,SynapseXen_iIllIiiliiliI)return(SynapseXen_lIiIIlIIliiiiliIiIiI-SynapseXen_lIliIilllllIIIIli)%SynapseXen_iIllIiiliiliI end;local function SynapseXen_iIIIIIlIiillii(SynapseXen_ilIiiiillII)if SynapseXen_ilIiiiillII<0 then SynapseXen_ilIiiiillII=4294967296+SynapseXen_ilIiiiillII end;return SynapseXen_ilIiiiillII end;local getfenv=getfenv;if not getfenv then getfenv=function()return _ENV end end;local SynapseXen_iillIlliII={}local SynapseXen_ilIllllilIilIIIIlI={}local SynapseXen_IIiiliIilIiiiI;local SynapseXen_liIiiliIIiiiillIiIi;local SynapseXen_lIIlIilIIiIliIIillIl={}local SynapseXen_iiIllilillIIIiiiIl={}for SynapseXen_lllilIIIllililIIlIi=0,255 do local SynapseXen_illIlllll,SynapseXen_IIIillIlIIlilIl=SynapseXen_iillI(SynapseXen_lllilIIIllililIIlIi),SynapseXen_iillI(SynapseXen_lllilIIIllililIIlIi,0)SynapseXen_lIIlIilIIiIliIIillIl[SynapseXen_illIlllll]=SynapseXen_IIIillIlIIlilIl;SynapseXen_iiIllilillIIIiiiIl[SynapseXen_IIIillIlIIlilIl]=SynapseXen_illIlllll end;local function SynapseXen_iIIliiIIIiIll(SynapseXen_illiiIiIll,SynapseXen_lliIlIIIilIIliIIiII,SynapseXen_ilIlIIiIlllIIiiiII,SynapseXen_lIlIliilIIi)if SynapseXen_ilIlIIiIlllIIiiiII>=256 then SynapseXen_ilIlIIiIlllIIiiiII,SynapseXen_lIlIliilIIi=0,SynapseXen_lIlIliilIIi+1;if SynapseXen_lIlIliilIIi>=256 then SynapseXen_lliIlIIIilIIliIIiII={}SynapseXen_lIlIliilIIi=1 end end;SynapseXen_lliIlIIIilIIliIIiII[SynapseXen_iillI(SynapseXen_ilIlIIiIlllIIiiiII,SynapseXen_lIlIliilIIi)]=SynapseXen_illiiIiIll;SynapseXen_ilIlIIiIlllIIiiiII=SynapseXen_ilIlIIiIlllIIiiiII+1;return SynapseXen_lliIlIIIilIIliIIiII,SynapseXen_ilIlIIiIlllIIiiiII,SynapseXen_lIlIliilIIi end;local function SynapseXen_IiIiII(SynapseXen_ilIlIIiIillIili)local function SynapseXen_lliIllIiil(SynapseXen_lIIlIiIIlililIIIilll)local SynapseXen_lIlIliilIIi='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'SynapseXen_lIIlIiIIlililIIIilll=string.gsub(SynapseXen_lIIlIiIIlililIIIilll,'[^'..SynapseXen_lIlIliilIIi..'=]','')return SynapseXen_lIIlIiIIlililIIIilll:gsub('.',function(SynapseXen_lIiIIlIIliiiiliIiIiI)if SynapseXen_lIiIIlIIliiiiliIiIiI=='='then return''end;local SynapseXen_IliIIIiII,SynapseXen_iIiII='',SynapseXen_lIlIliilIIi:find(SynapseXen_lIiIIlIIliiiiliIiIiI)-1;for SynapseXen_lllilIIIllililIIlIi=6,1,-1 do SynapseXen_IliIIIiII=SynapseXen_IliIIIiII..(SynapseXen_iIiII%2^SynapseXen_lllilIIIllililIIlIi-SynapseXen_iIiII%2^(SynapseXen_lllilIIIllililIIlIi-1)>0 and'1'or'0')end;return SynapseXen_IliIIIiII end):gsub('%d%d%d?%d?%d?%d?%d?%d?',function(SynapseXen_lIiIIlIIliiiiliIiIiI)if#SynapseXen_lIiIIlIIliiiiliIiIiI~=8 then return''end;local SynapseXen_lIliIllIl=0;for SynapseXen_lllilIIIllililIIlIi=1,8 do SynapseXen_lIliIllIl=SynapseXen_lIliIllIl+(SynapseXen_lIiIIlIIliiiiliIiIiI:sub(SynapseXen_lllilIIIllililIIlIi,SynapseXen_lllilIIIllililIIlIi)=='1'and 2^(8-SynapseXen_lllilIIIllililIIlIi)or 0)end;return string.char(SynapseXen_lIliIllIl)end)end;SynapseXen_ilIlIIiIillIili=SynapseXen_lliIllIiil(SynapseXen_ilIlIIiIillIili)local SynapseXen_llIlllIlIilII=SynapseXen_iIiIlIillIlliili(SynapseXen_ilIlIIiIillIili,1,1)if SynapseXen_llIlllIlIilII=="u"then return SynapseXen_iIiIlIillIlliili(SynapseXen_ilIlIIiIillIili,2)elseif SynapseXen_llIlllIlIilII~="c"then error("Synapse Xen - Failed to verify bytecode. Please make sure your Lua implementation supports non-null terminated strings.")end;SynapseXen_ilIlIIiIillIili=SynapseXen_iIiIlIillIlliili(SynapseXen_ilIlIIiIillIili,2)local SynapseXen_iIiIili=#SynapseXen_ilIlIIiIillIili;local SynapseXen_lliIlIIIilIIliIIiII={}local SynapseXen_ilIlIIiIlllIIiiiII,SynapseXen_lIlIliilIIi=0,1;local SynapseXen_liiIi={}local SynapseXen_ilIiiiillII=1;local SynapseXen_lIlllilliIIliiIIiI=SynapseXen_iIiIlIillIlliili(SynapseXen_ilIlIIiIillIili,1,2)SynapseXen_liiIi[SynapseXen_ilIiiiillII]=SynapseXen_iiIllilillIIIiiiIl[SynapseXen_lIlllilliIIliiIIiI]or SynapseXen_lliIlIIIilIIliIIiII[SynapseXen_lIlllilliIIliiIIiI]SynapseXen_ilIiiiillII=SynapseXen_ilIiiiillII+1;for SynapseXen_lllilIIIllililIIlIi=3,SynapseXen_iIiIili,2 do local SynapseXen_ilIIiilllilII=SynapseXen_iIiIlIillIlliili(SynapseXen_ilIlIIiIillIili,SynapseXen_lllilIIIllililIIlIi,SynapseXen_lllilIIIllililIIlIi+1)local SynapseXen_liIliliIlIIIillIl=SynapseXen_iiIllilillIIIiiiIl[SynapseXen_lIlllilliIIliiIIiI]or SynapseXen_lliIlIIIilIIliIIiII[SynapseXen_lIlllilliIIliiIIiI]if not SynapseXen_liIliliIlIIIillIl then error("Synapse Xen - Failed to verify bytecode. Please make sure your Lua implementation supports non-null terminated strings.")end;local SynapseXen_IiIiilIIllI=SynapseXen_iiIllilillIIIiiiIl[SynapseXen_ilIIiilllilII]or SynapseXen_lliIlIIIilIIliIIiII[SynapseXen_ilIIiilllilII]if SynapseXen_IiIiilIIllI then SynapseXen_liiIi[SynapseXen_ilIiiiillII]=SynapseXen_IiIiilIIllI;SynapseXen_ilIiiiillII=SynapseXen_ilIiiiillII+1;SynapseXen_lliIlIIIilIIliIIiII,SynapseXen_ilIlIIiIlllIIiiiII,SynapseXen_lIlIliilIIi=SynapseXen_iIIliiIIIiIll(SynapseXen_liIliliIlIIIillIl..SynapseXen_iIiIlIillIlliili(SynapseXen_IiIiilIIllI,1,1),SynapseXen_lliIlIIIilIIliIIiII,SynapseXen_ilIlIIiIlllIIiiiII,SynapseXen_lIlIliilIIi)else local SynapseXen_lIiIIiiIIIlillii=SynapseXen_liIliliIlIIIillIl..SynapseXen_iIiIlIillIlliili(SynapseXen_liIliliIlIIIillIl,1,1)SynapseXen_liiIi[SynapseXen_ilIiiiillII]=SynapseXen_lIiIIiiIIIlillii;SynapseXen_ilIiiiillII=SynapseXen_ilIiiiillII+1;SynapseXen_lliIlIIIilIIliIIiII,SynapseXen_ilIlIIiIlllIIiiiII,SynapseXen_lIlIliilIIi=SynapseXen_iIIliiIIIiIll(SynapseXen_lIiIIiiIIIlillii,SynapseXen_lliIlIIIilIIliIIiII,SynapseXen_ilIlIIiIlllIIiiiII,SynapseXen_lIlIliilIIi)end;SynapseXen_lIlllilliIIliiIIiI=SynapseXen_ilIIiilllilII end;return SynapseXen_iIIIIlIliiliIiIll(SynapseXen_liiIi)end;local function SynapseXen_lIiiil(SynapseXen_llIiIlil,SynapseXen_iilIiiliiillIIilIi,SynapseXen_ilIIilliili)if SynapseXen_ilIIilliili then local SynapseXen_IIIiIiililIiii=SynapseXen_llIiIlil/2^(SynapseXen_iilIiiliiillIIilIi-1)%2^(SynapseXen_ilIIilliili-1-(SynapseXen_iilIiiliiillIIilIi-1)+1)return SynapseXen_IIIiIiililIiii-SynapseXen_IIIiIiililIiii%1 else local SynapseXen_iiiIliIiIIliIIlIlli=2^(SynapseXen_iilIiiliiillIIilIi-1)if SynapseXen_llIiIlil%(SynapseXen_iiiIliIiIIliIIlIlli+SynapseXen_iiiIliIiIIliIIlIlli)>=SynapseXen_iiiIliIiIIliIIlIlli then return 1 else return 0 end end end;local function SynapseXen_iIIliii()local SynapseXen_iIlIiiIilIII=SynapseXen_lIilIiiIiIiIliIi(2162144820,SynapseXen_ilIllllilIilIIIIlI[4])while true do if SynapseXen_iIlIiiIilIII==SynapseXen_lIilIiiIiIiIliIi(1383174331,SynapseXen_liIiiliIIiiiillIiIi)then SynapseXen_IIiiliIilIiiiI=function(SynapseXen_lIiIIIIIiIIlIiIiI,SynapseXen_lIilIIiillI)return SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIiIIIIIiIIlIiIiI+44892,SynapseXen_lIilIIiillI-38679)-SynapseXen_lIilIiiIiIiIliIi(2888435060,SynapseXen_ilIllllilIilIIIIlI[5])end;SynapseXen_iIlIiiIilIII=SynapseXen_iIlIiiIilIII+SynapseXen_lIilIiiIiIiIliIi(888136258,SynapseXen_ilIllllilIilIIIIlI[2])elseif SynapseXen_iIlIiiIilIII==SynapseXen_lIilIiiIiIiIliIi(43403037,SynapseXen_liIiiliIIiiiillIiIi)then SynapseXen_IIiiliIilIiiiI=function(SynapseXen_lIiIIIIIiIIlIiIiI,SynapseXen_lIilIIiillI)return SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIiIIIIIiIIlIiIiI+35407,SynapseXen_lIilIIiillI+21939)-SynapseXen_lIilIiiIiIiIliIi(41899183,SynapseXen_ilIllllilIilIIIIlI[4])end;SynapseXen_iIlIiiIilIII=SynapseXen_iIlIiiIilIII+SynapseXen_lIilIiiIiIiIliIi(2888486612,SynapseXen_ilIllllilIilIIIIlI[5])elseif SynapseXen_iIlIiiIilIII==SynapseXen_lIilIiiIiIiIliIi(3326520097,SynapseXen_ilIllllilIilIIIIlI[3])then SynapseXen_IIiiliIilIiiiI=function(SynapseXen_lIiIIIIIiIIlIiIiI,SynapseXen_lIilIIiillI)return SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIiIIIIIiIIlIiIiI-12137,SynapseXen_lIilIIiillI-13915)+SynapseXen_lIilIiiIiIiIliIi(3910019922,SynapseXen_liIiiliIIiiiillIiIi)end;SynapseXen_iIlIiiIilIII=SynapseXen_iIlIiiIilIII-SynapseXen_lIilIiiIiIiIliIi(4159816661,SynapseXen_ilIllllilIilIIIIlI[1])elseif SynapseXen_iIlIiiIilIII==SynapseXen_lIilIiiIiIiIliIi(1383173287,SynapseXen_liIiiliIIiiiillIiIi)then SynapseXen_IIiiliIilIiiiI=function(SynapseXen_lIiIIIIIiIIlIiIiI,SynapseXen_lIilIIiillI)return SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIiIIIIIiIIlIiIiI+1729,SynapseXen_lIilIIiillI-17131)-SynapseXen_lIilIiiIiIiIliIi(3910009909,SynapseXen_liIiiliIIiiiillIiIi)end;SynapseXen_iIlIiiIilIII=SynapseXen_iIlIiiIilIII-SynapseXen_lIilIiiIiIiIliIi(41890645,SynapseXen_ilIllllilIilIIIIlI[4])elseif SynapseXen_iIlIiiIilIII==SynapseXen_lIilIiiIiIiIliIi(3103836623,SynapseXen_ilIllllilIilIIIIlI[4])then SynapseXen_IIiiliIilIiiiI=function(SynapseXen_lIiIIIIIiIIlIiIiI,SynapseXen_lIilIIiillI)return SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIiIIIIIiIIlIiIiI-28963,SynapseXen_lIilIIiillI-29607)-SynapseXen_lIilIiiIiIiIliIi(555216482,SynapseXen_ilIllllilIilIIIIlI[3])end;SynapseXen_iIlIiiIilIII=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_iIlIiiIilIII,SynapseXen_lIilIiiIiIiIliIi(3038785898,SynapseXen_liIiiliIIiiiillIiIi))elseif SynapseXen_iIlIiiIilIII==SynapseXen_lIilIiiIiIiIliIi(241144012,SynapseXen_liIiiliIIiiiillIiIi)then SynapseXen_IIiiliIilIiiiI=function(SynapseXen_lIiIIIIIiIIlIiIiI,SynapseXen_lIilIIiillI)return SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIiIIIIIiIIlIiIiI+10524,SynapseXen_lIilIIiillI+39542)+SynapseXen_lIilIiiIiIiIliIi(3910011795,SynapseXen_liIiiliIIiiiillIiIi)end;SynapseXen_iIlIiiIilIII=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_iIlIiiIilIII,SynapseXen_lIilIiiIiIiIliIi(85136277,SynapseXen_ilIllllilIilIIIIlI[1]))elseif SynapseXen_iIlIiiIilIII==SynapseXen_lIilIiiIiIiIliIi(43450111,SynapseXen_liIiiliIIiiiillIiIi)then return elseif SynapseXen_iIlIiiIilIII==SynapseXen_lIilIiiIiIiIliIi(1968249256,SynapseXen_ilIllllilIilIIIIlI[1])then SynapseXen_IIiiliIilIiiiI=function(SynapseXen_lIiIIIIIiIIlIiIiI,SynapseXen_lIilIIiillI)return SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIiIIIIIiIIlIiIiI-17028,SynapseXen_lIilIIiillI-18608)-SynapseXen_lIilIiiIiIiIliIi(3910038513,SynapseXen_liIiiliIIiiiillIiIi)end;SynapseXen_iIlIiiIilIII=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_iIlIiiIilIII,SynapseXen_lIilIiiIiIiIliIi(2515908525,SynapseXen_ilIllllilIilIIIIlI[5]))elseif SynapseXen_iIlIiiIilIII==SynapseXen_lIilIiiIiIiIliIi(4240249756,SynapseXen_liIiiliIIiiiillIiIi)then SynapseXen_IIiiliIilIiiiI=function(SynapseXen_lIiIIIIIiIIlIiIiI,SynapseXen_lIilIIiillI)return SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIiIIIIIiIIlIiIiI-5835,SynapseXen_lIilIIiillI+8433)-SynapseXen_lIilIiiIiIiIliIi(3910042645,SynapseXen_liIiiliIIiiiillIiIi)end;SynapseXen_iIlIiiIilIII=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_iIlIiiIilIII,SynapseXen_lIilIiiIiIiIliIi(388329040,SynapseXen_liIiiliIIiiiillIiIi))end end end;local function SynapseXen_IIIlill(SynapseXen_IiIliiiillIlIIliiI)local SynapseXen_IliliiIIIIilIl=1;local SynapseXen_IIlllIil;local SynapseXen_iiIIlIIillilI;local function SynapseXen_illii()local SynapseXen_lIIiIlIIIIiilIllIIil=SynapseXen_IIIIillIIIliIl(SynapseXen_IiIliiiillIlIIliiI,SynapseXen_IliliiIIIIilIl,SynapseXen_IliliiIIIIilIl)SynapseXen_IliliiIIIIilIl=SynapseXen_IliliiIIIIilIl+1;return SynapseXen_lIIiIlIIIIiilIllIIil end;local function SynapseXen_IIillliIiii()local SynapseXen_lIIlllIlIIIi,SynapseXen_lIiIIIIIiIIlIiIiI,SynapseXen_lIilIIiillI,SynapseXen_iiIIIIi=SynapseXen_IIIIillIIIliIl(SynapseXen_IiIliiiillIlIIliiI,SynapseXen_IliliiIIIIilIl,SynapseXen_IliliiIIIIilIl+3)SynapseXen_IliliiIIIIilIl=SynapseXen_IliliiIIIIilIl+4;return SynapseXen_iiIIIIi*16777216+SynapseXen_lIilIIiillI*65536+SynapseXen_lIiIIIIIiIIlIiIiI*256+SynapseXen_lIIlllIlIIIi end;local function SynapseXen_IiiiIliIliIiIiIi()return SynapseXen_IIillliIiii()*4294967296+SynapseXen_IIillliIiii()end;local function SynapseXen_iiIlIii()local SynapseXen_liIiIliliIIlI=SynapseXen_iiililIlIiiliiillIlI(SynapseXen_IIillliIiii(),SynapseXen_iillIlliII[933892480]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="SYNAPSE XEN [FE BYPASS] [BETTER THEN LURAPH] [AMAZING] OMG OMG OMG !!!!!!"SynapseXen_iillIlliII[933892480]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(1346492038,2410968002),SynapseXen_lIilIiiIiIiIliIi(2594626660,SynapseXen_ilIllllilIilIIIIlI[5]))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{4182913793,1849289885,3847464351,1342156515,2438159094,480885268,1867258922,67268387,414297217}return SynapseXen_iillIlliII[933892480]end)())local SynapseXen_lIIllIiIliiIlllllliI=SynapseXen_iiililIlIiiliiillIlI(SynapseXen_IIillliIiii(),SynapseXen_iillIlliII[2270638235]or(function(...)local SynapseXen_lIiIIlIIliiiiliIiIiI="https://twitter.com/Ripull_RBLX/status/1059334518581145603"local SynapseXen_iIIIl=SynapseXen_IIiiliIilIiiiI(2453344636,432816361)local SynapseXen_llllIIIliIili={...}for SynapseXen_lllilIIIllililIIlIi,SynapseXen_illlIIllli in pairs(SynapseXen_llllIIIliIili)do local SynapseXen_lIIIiIiIi;local SynapseXen_IIIiilIiiIiIIiIiiilI=type(SynapseXen_illlIIllli)if SynapseXen_IIIiilIiiIiIIiIiiilI=="number"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="string"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli:len()elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="table"then SynapseXen_lIIIiIiIi=SynapseXen_IIiiliIilIiiiI(4174774958,4174816152)end;SynapseXen_iIIIl=SynapseXen_iIIIl-SynapseXen_lIIIiIiIi end;SynapseXen_iillIlliII[2270638235]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIilIiiIiIiIliIi(4292806034,SynapseXen_iIIIl),SynapseXen_lIilIiiIiIiIliIi(1851844393,SynapseXen_ilIllllilIilIIIIlI[3]))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{524198476,3754059098,3817373713,2683464200,454068447,2849708967,3087202578,2909019072,473534095}return SynapseXen_iillIlliII[2270638235]end)(9331,11829,"lllIliiiIiIl",10249,{},{},{},{},"I",{}))local SynapseXen_iilIiIilIill=1;local SynapseXen_liIlliIIIiIil=SynapseXen_lIiiil(SynapseXen_lIIllIiIliiIlllllliI,1,20)*2^32+SynapseXen_liIiIliliIIlI;local SynapseXen_iIIlllllIlIIlii=SynapseXen_lIiiil(SynapseXen_lIIllIiIliiIlllllliI,21,31)local SynapseXen_llIllIlilIllIIli=(-1)^SynapseXen_lIiiil(SynapseXen_lIIllIiIliiIlllllliI,32)if SynapseXen_iIIlllllIlIIlii==0 then if SynapseXen_liIlliIIIiIil==0 then return SynapseXen_llIllIlilIllIIli*0 else SynapseXen_iIIlllllIlIIlii=1;SynapseXen_iilIiIilIill=0 end elseif SynapseXen_iIIlllllIlIIlii==2047 then if SynapseXen_liIlliIIIiIil==0 then return SynapseXen_llIllIlilIllIIli*1/0 else return SynapseXen_llIllIlilIllIIli*0/0 end end;return math.ldexp(SynapseXen_llIllIlilIllIIli,SynapseXen_iIIlllllIlIIlii-1023)*(SynapseXen_iilIiIilIill+SynapseXen_liIlliIIIiIil/2^52)end;local function SynapseXen_liiiIiIiIiii(SynapseXen_illllIIIIiIiiiIi)local SynapseXen_IiillilIiiIlIlliiI;if SynapseXen_illllIIIIiIiiiIi then SynapseXen_IiillilIiiIlIlliiI=SynapseXen_iIiIlIillIlliili(SynapseXen_IiIliiiillIlIIliiI,SynapseXen_IliliiIIIIilIl,SynapseXen_IliliiIIIIilIl+SynapseXen_illllIIIIiIiiiIi-1)SynapseXen_IliliiIIIIilIl=SynapseXen_IliliiIIIIilIl+SynapseXen_illllIIIIiIiiiIi else SynapseXen_illllIIIIiIiiiIi=SynapseXen_IIlllIil()if SynapseXen_illllIIIIiIiiiIi==0 then return""end;SynapseXen_IiillilIiiIlIlliiI=SynapseXen_iIiIlIillIlliili(SynapseXen_IiIliiiillIlIIliiI,SynapseXen_IliliiIIIIilIl,SynapseXen_IliliiIIIIilIl+SynapseXen_illllIIIIiIiiiIi-1)SynapseXen_IliliiIIIIilIl=SynapseXen_IliliiIIIIilIl+SynapseXen_illllIIIIiIiiiIi end;return SynapseXen_IiillilIiiIlIlliiI end;local function SynapseXen_lilliIIIIlIliiliIlii(SynapseXen_IiillilIiiIlIlliiI)local SynapseXen_IIIiIiililIiii={}for SynapseXen_lllilIIIllililIIlIi=1,#SynapseXen_IiillilIiiIlIlliiI do local SynapseXen_liiiIilliiilIIliil=SynapseXen_IiillilIiiIlIlliiI:sub(SynapseXen_lllilIIIllililIIlIi,SynapseXen_lllilIIIllililIIlIi)SynapseXen_IIIiIiililIiii[#SynapseXen_IIIiIiililIiii+1]=string.char(SynapseXen_lIilIiiIiIiIliIi(string.byte(SynapseXen_liiiIilliiilIIliil),SynapseXen_iillIlliII[2952018602]or(function(...)local SynapseXen_lIiIIlIIliiiiliIiIiI="double-header fair! this rationalization has a overenthusiastically anticheat! you will get nonpermissible for exploiting!"local SynapseXen_iIIIl=SynapseXen_IIiiliIilIiiiI(579310494,3090021572)local SynapseXen_llllIIIliIili={...}for SynapseXen_lllilIIIllililIIlIi,SynapseXen_illlIIllli in pairs(SynapseXen_llllIIIliIili)do local SynapseXen_lIIIiIiIi;local SynapseXen_IIIiilIiiIiIIiIiiilI=type(SynapseXen_illlIIllli)if SynapseXen_IIIiilIiiIiIIiIiiilI=="number"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="string"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli:len()elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="table"then SynapseXen_lIIIiIiIi=SynapseXen_IIiiliIilIiiiI(4209840582,4209818745)end;SynapseXen_iIIIl=SynapseXen_iIIIl+SynapseXen_lIIIiIiIi end;SynapseXen_iillIlliII[2952018602]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIilIiiIiIiIliIi(2898183939,SynapseXen_iIIIl),SynapseXen_lIilIiiIiIiIliIi(3742791195,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{3760885321,2036477415,1619889306,2962670457,1528004725,3577618620,382314588,3098483726}return SynapseXen_iillIlliII[2952018602]end)(3148,"ilIIIii",10895,13560,"iilllllIliIiiI",{},6305,"IllllllliilIillIlI","iIllllIiI")))end;return table.concat(SynapseXen_IIIiIiililIiii)end;local function SynapseXen_liiIll()local SynapseXen_IIiililIilIlllliiili={}local SynapseXen_IilIiiiillll={}local SynapseXen_IIliiilIiiliilII={}local SynapseXen_liiiIlillIililIii={[SynapseXen_iillIlliII[3722681896]or(function(...)local SynapseXen_lIiIIlIIliiiiliIiIiI="inb4 posted on exploit reports section"local SynapseXen_iIIIl=SynapseXen_IIiiliIilIiiiI(1198617687,3944673247)local SynapseXen_llllIIIliIili={...}for SynapseXen_lllilIIIllililIIlIi,SynapseXen_illlIIllli in pairs(SynapseXen_llllIIIliIili)do local SynapseXen_lIIIiIiIi;local SynapseXen_IIIiilIiiIiIIiIiiilI=type(SynapseXen_illlIIllli)if SynapseXen_IIIiilIiiIiIIiIiiilI=="number"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="string"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli:len()elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="table"then SynapseXen_lIIIiIiIi=SynapseXen_IIiiliIilIiiiI(3910505529,3910540789)end;SynapseXen_iIIIl=SynapseXen_iIIIl-SynapseXen_lIIIiIiIi end;SynapseXen_iillIlliII[3722681896]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIilIiiIiIiIliIi(1936874188,SynapseXen_iIIIl),SynapseXen_lIilIiiIiIiIliIi(2122981664,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{2909036160,3501444168,2359392139}return SynapseXen_iillIlliII[3722681896]end)("lliiIIIIIiIIil","lIIiiIIII","l",8504,"IiliiillIIli","iIiiIii")]=SynapseXen_IIiililIilIlllliiili,[SynapseXen_iillIlliII[1322603437]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="xen doesn't come with instance caching, sorry superskater"SynapseXen_iillIlliII[1322603437]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(1234169112,2616195061),SynapseXen_lIilIiiIiIiIliIi(1400832639,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{2105249635,1296455906,1964472716,1977716365,242545059,1252914832}return SynapseXen_iillIlliII[1322603437]end)()]=SynapseXen_IilIiiiillll,[SynapseXen_iillIlliII[2716574232]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="so if you'we nyot awawe of expwoiting by this point, you've pwobabwy been wiving undew a wock that the pionyeews used to wide fow miwes. wobwox is often seen as an expwoit-infested gwound by most fwom the suwface, awthough this isn't the case."SynapseXen_iillIlliII[2716574232]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(4158678024,1238442286),SynapseXen_lIilIiiIiIiIliIi(1141457967,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{2362934768,3584825577,84763399,4058176963,4121109528,3464102765,4013913617,3644297691}return SynapseXen_iillIlliII[2716574232]end)()]=SynapseXen_IIliiilIiiliilII}SynapseXen_illii()SynapseXen_illii()SynapseXen_liiiIlillIililIii[971025170]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_illii(),SynapseXen_iillIlliII[849413610]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="HELP ME PEOPLE ARE CRASHING MY GAME PLZ HELP"SynapseXen_iillIlliII[849413610]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(1730124159,1043123955),SynapseXen_lIilIiiIiIiIliIi(2952962537,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{2534054742,1038769976,453205404,959297495,968335698,3808117622,4202306117,3100320007,1001891347}return SynapseXen_iillIlliII[849413610]end)())SynapseXen_liiiIlillIililIii[1232933912]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_illii(),SynapseXen_iillIlliII[1657256976]or(function(...)local SynapseXen_lIiIIlIIliiiiliIiIiI="now with shitty xor string obfuscation"local SynapseXen_iIIIl=SynapseXen_IIiiliIilIiiiI(598176565,4026810318)local SynapseXen_llllIIIliIili={...}for SynapseXen_lllilIIIllililIIlIi,SynapseXen_illlIIllli in pairs(SynapseXen_llllIIIliIili)do local SynapseXen_lIIIiIiIi;local SynapseXen_IIIiilIiiIiIIiIiiilI=type(SynapseXen_illlIIllli)if SynapseXen_IIIiilIiiIiIIiIiiilI=="number"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="string"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli:len()elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="table"then SynapseXen_lIIIiIiIi=SynapseXen_IIiiliIilIiiiI(3019698602,3019744814)end;SynapseXen_iIIIl=SynapseXen_iIIIl-SynapseXen_lIIIiIiIi end;SynapseXen_iillIlliII[1657256976]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIilIiiIiIiIliIi(578322467,SynapseXen_iIIIl),SynapseXen_lIilIiiIiIiIliIi(3503101980,SynapseXen_ilIllllilIilIIIIlI[3]))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{3306051731,2008594810}return SynapseXen_iillIlliII[1657256976]end)("IIIIIIlI",11776))for SynapseXen_illililIiil=1,SynapseXen_lIilIiiIiIiIliIi(SynapseXen_iiIIlIIillilI(),SynapseXen_iillIlliII[2510078367]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="this is so sad, alexa play ripull.mp4"SynapseXen_iillIlliII[2510078367]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(186256668,3725437175),SynapseXen_lIilIiiIiIiIliIi(2418500254,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{1282989169,847099972,2403106212}return SynapseXen_iillIlliII[2510078367]end)())do local SynapseXen_IlIillIlllili=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIillliIiii(),SynapseXen_iillIlliII[2328944068]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="this is a christian obfuscator, no cursing allowed in our scripts"SynapseXen_iillIlliII[2328944068]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(372192770,2210376330),SynapseXen_lIilIiiIiIiIliIi(815955085,SynapseXen_ilIllllilIilIIIIlI[4]))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{629745696,1841126905,1219033871,4040735661,3153098322,3096400105}return SynapseXen_iillIlliII[2328944068]end)())local SynapseXen_IiiIII=SynapseXen_illii()local SynapseXen_iIiiiIIiIlllIliIi=SynapseXen_illii()SynapseXen_IIillliIiii()local SynapseXen_liiiiiiI={[1340504709]=SynapseXen_IlIillIlllili,[422628075]=SynapseXen_IiiIII,[1713111702]=SynapseXen_lIiiil(SynapseXen_IlIillIlllili,1,6),[2005561348]=SynapseXen_lIiiil(SynapseXen_IlIillIlllili,7,14)}if SynapseXen_iIiiiIIiIlllIliIi==(SynapseXen_iillIlliII[3454501117]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="hi xen doesn't work on sk8r please help"SynapseXen_iillIlliII[3454501117]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(1129645575,3721762179),SynapseXen_lIilIiiIiIiIliIi(2633969956,SynapseXen_ilIllllilIilIIIIlI[4]))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{1243330063,4165944629}return SynapseXen_iillIlliII[3454501117]end)())then SynapseXen_liiiiiiI[1328471899]=SynapseXen_lIiiil(SynapseXen_IlIillIlllili,24,32)SynapseXen_liiiiiiI[688126082]=SynapseXen_lIiiil(SynapseXen_IlIillIlllili,15,23)elseif SynapseXen_iIiiiIIiIlllIliIi==(SynapseXen_iillIlliII[3075881460]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="wait for someone on devforum to say they are gonna deobfuscate this"SynapseXen_iillIlliII[3075881460]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(26325920,1937015233),SynapseXen_lIilIiiIiIiIliIi(1889091994,SynapseXen_ilIllllilIilIIIIlI[4]))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{2870008302,3518725692,3035135703}return SynapseXen_iillIlliII[3075881460]end)())then SynapseXen_liiiiiiI[863174940]=SynapseXen_lIiiil(SynapseXen_IlIillIlllili,15,32)elseif SynapseXen_iIiiiIIiIlllIliIi==(SynapseXen_iillIlliII[2603792202]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="pain is gonna use the backspace method on xen"SynapseXen_iillIlliII[2603792202]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(555371945,1895312168),SynapseXen_lIilIiiIiIiIliIi(2786097950,SynapseXen_ilIllllilIilIIIIlI[1]))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{107033230,290926690,314741676,2571483746,3113157893}return SynapseXen_iillIlliII[2603792202]end)())then SynapseXen_liiiiiiI[1426143073]=SynapseXen_lIiiil(SynapseXen_IlIillIlllili,15,32)-131071 end;SynapseXen_IilIiiiillll[SynapseXen_illililIiil]=SynapseXen_liiiiiiI end;SynapseXen_IIillliIiii()for SynapseXen_illililIiil=1,SynapseXen_lIilIiiIiIiIliIi(SynapseXen_iiIIlIIillilI(),SynapseXen_iillIlliII[3960973482]or(function(...)local SynapseXen_lIiIIlIIliiiiliIiIiI="aspect network better obfuscator"local SynapseXen_iIIIl=SynapseXen_IIiiliIilIiiiI(1225519815,318936950)local SynapseXen_llllIIIliIili={...}for SynapseXen_lllilIIIllililIIlIi,SynapseXen_illlIIllli in pairs(SynapseXen_llllIIIliIili)do local SynapseXen_lIIIiIiIi;local SynapseXen_IIIiilIiiIiIIiIiiilI=type(SynapseXen_illlIIllli)if SynapseXen_IIIiilIiiIiIIiIiiilI=="number"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="string"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli:len()elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="table"then SynapseXen_lIIIiIiIi=SynapseXen_IIiiliIilIiiiI(1491445609,1491465543)end;SynapseXen_iIIIl=SynapseXen_iIIIl-SynapseXen_lIIIiIiIi end;SynapseXen_iillIlliII[3960973482]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIilIiiIiIiIliIi(1397599935,SynapseXen_iIIIl),SynapseXen_lIilIiiIiIiIliIi(1036526729,SynapseXen_ilIllllilIilIIIIlI[1]))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{4182306608,1308232431,339076473,1008303161,3977814900,4293838932,1578355166}return SynapseXen_iillIlliII[3960973482]end)("ilIIiIilIiIIi",{},4325,3509,"IiiillllliIlIiIIIIl","IiIlIiilIlIIlIiiii","IllilIIiI",{},{},"IIliiIli"))do SynapseXen_illii()local SynapseXen_iIiiiIIiIlllIliIi=SynapseXen_illii()SynapseXen_illii()local SynapseXen_lIilIiiIliiIIl;if SynapseXen_iIiiiIIiIlllIliIi==(SynapseXen_iillIlliII[2139417777]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="hi my 2.5mb script doesn't work with xen please help"SynapseXen_iillIlliII[2139417777]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(1535796548,328763950),SynapseXen_lIilIiiIiIiIliIi(1762038307,SynapseXen_ilIllllilIilIIIIlI[3]))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{3407498488,4120708737,3864421059,1976647929,4074140189,4162187719}return SynapseXen_iillIlliII[2139417777]end)())then SynapseXen_lIilIiiIliiIIl=SynapseXen_illii()~=0 elseif SynapseXen_iIiiiIIiIlllIliIi==(SynapseXen_iillIlliII[282851802]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="xen detects custom getfenv"SynapseXen_iillIlliII[282851802]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(2657347187,3106643347),SynapseXen_lIilIiiIiIiIliIi(3460377667,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{987366453,1579008377,4063904069,4135902334,958391070,4171525533,2060557906}return SynapseXen_iillIlliII[282851802]end)())then SynapseXen_lIilIiiIliiIIl=SynapseXen_iiIlIii()elseif SynapseXen_iIiiiIIiIlllIliIi==(SynapseXen_iillIlliII[50598889]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="level 1 crook = luraph, level 100 boss = xen"SynapseXen_iillIlliII[50598889]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(3708543538,1841920156),SynapseXen_lIilIiiIiIiIliIi(1506479257,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{3548478419,2784330584,1241019044,198324167,1657039901}return SynapseXen_iillIlliII[50598889]end)())then SynapseXen_lIilIiiIliiIIl=SynapseXen_iIiIlIillIlliili(SynapseXen_lilliIIIIlIliiliIlii(SynapseXen_liiiIiIiIiii()),1,-2)end;SynapseXen_IIiililIilIlllliiili[SynapseXen_illililIiil-1]=SynapseXen_lIilIiiIliiIIl end;for SynapseXen_illililIiil=1,SynapseXen_lIilIiiIiIiIliIi(SynapseXen_iiIIlIIillilI(),SynapseXen_iillIlliII[1920793482]or(function(...)local SynapseXen_lIiIIlIIliiiiliIiIiI="yed"local SynapseXen_iIIIl=SynapseXen_IIiiliIilIiiiI(935109527,3387000166)local SynapseXen_llllIIIliIili={...}for SynapseXen_lllilIIIllililIIlIi,SynapseXen_illlIIllli in pairs(SynapseXen_llllIIIliIili)do local SynapseXen_lIIIiIiIi;local SynapseXen_IIIiilIiiIiIIiIiiilI=type(SynapseXen_illlIIllli)if SynapseXen_IIIiilIiiIiIIiIiiilI=="number"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="string"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli:len()elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="table"then SynapseXen_lIIIiIiIi=SynapseXen_IIiiliIilIiiiI(2009834360,2009872482)end;SynapseXen_iIIIl=SynapseXen_iIIIl+SynapseXen_lIIIiIiIi end;SynapseXen_iillIlliII[1920793482]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIilIiiIiIiIliIi(3266803941,SynapseXen_iIIIl),SynapseXen_lIilIiiIiIiIliIi(318264244,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{1208904752,291617706,1285356657,605244474,475170607,888348529}return SynapseXen_iillIlliII[1920793482]end)(10085,"iiIll"))do SynapseXen_IIliiilIiiliilII[SynapseXen_illililIiil-1]=SynapseXen_liiIll()end;return SynapseXen_liiiIlillIililIii end;do assert(SynapseXen_liiiIiIiIiii(4)=="\27Xen","Synapse Xen - Failed to verify bytecode. Please make sure your Lua implementation supports non-null terminated strings.")SynapseXen_iiIIlIIillilI=SynapseXen_IIillliIiii;SynapseXen_IIlllIil=SynapseXen_IIillliIiii;local SynapseXen_liliIl=SynapseXen_liiiIiIiIiii()SynapseXen_illii()SynapseXen_IIillliIiii()SynapseXen_liIiiliIIiiiillIiIi=SynapseXen_iIIIIIlIiillii(SynapseXen_iiIIlIIillilI())SynapseXen_illii()local SynapseXen_iiIlIiiIIIlli=0;for SynapseXen_lllilIIIllililIIlIi=1,#SynapseXen_liliIl do local SynapseXen_liiiIilliiilIIliil=SynapseXen_liliIl:sub(SynapseXen_lllilIIIllililIIlIi,SynapseXen_lllilIIIllililIIlIi)SynapseXen_iiIlIiiIIIlli=SynapseXen_iiIlIiiIIIlli+string.byte(SynapseXen_liiiIilliiilIIliil)end;SynapseXen_iiIlIiiIIIlli=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_iiIlIiiIIIlli,SynapseXen_liIiiliIIiiiillIiIi)for SynapseXen_illililIiil=1,SynapseXen_illii()do SynapseXen_ilIllllilIilIIIIlI[SynapseXen_illililIiil]=SynapseXen_iiililIlIiiliiillIlI(SynapseXen_iiIIlIIillilI(),SynapseXen_iiIlIiiIIIlli)end;SynapseXen_iIIliii()end;return SynapseXen_liiIll()end;local function SynapseXen_IIIlIiIllIIIliiillli(...)return SynapseXen_iiilliIiI('#',...),{...}end;local function SynapseXen_Illlllii(SynapseXen_liiiIlillIililIii,SynapseXen_iliIlliiliIlIIIilIil,SynapseXen_iiIIiilIIiliiilIiIiI)local SynapseXen_IIiililIilIlllliiili=SynapseXen_liiiIlillIililIii[SynapseXen_iillIlliII[3722681896]or(function(...)local SynapseXen_lIiIIlIIliiiiliIiIiI="inb4 posted on exploit reports section"local SynapseXen_iIIIl=SynapseXen_IIiiliIilIiiiI(1198617687,3944673247)local SynapseXen_llllIIIliIili={...}for SynapseXen_lllilIIIllililIIlIi,SynapseXen_illlIIllli in pairs(SynapseXen_llllIIIliIili)do local SynapseXen_lIIIiIiIi;local SynapseXen_IIIiilIiiIiIIiIiiilI=type(SynapseXen_illlIIllli)if SynapseXen_IIIiilIiiIiIIiIiiilI=="number"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="string"then SynapseXen_lIIIiIiIi=SynapseXen_illlIIllli:len()elseif SynapseXen_IIIiilIiiIiIIiIiiilI=="table"then SynapseXen_lIIIiIiIi=SynapseXen_IIiiliIilIiiiI(3910505529,3910540789)end;SynapseXen_iIIIl=SynapseXen_iIIIl-SynapseXen_lIIIiIiIi end;SynapseXen_iillIlliII[3722681896]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIilIiiIiIiIliIi(1936874188,SynapseXen_iIIIl),SynapseXen_lIilIiiIiIiIliIi(2122981664,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{2909036160,3501444168,2359392139}return SynapseXen_iillIlliII[3722681896]end)("lliiIIIIIiIIil","lIIiiIIII","l",8504,"IiliiillIIli","iIiiIii")]local SynapseXen_IilIiiiillll=SynapseXen_liiiIlillIililIii[SynapseXen_iillIlliII[1322603437]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="xen doesn't come with instance caching, sorry superskater"SynapseXen_iillIlliII[1322603437]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(1234169112,2616195061),SynapseXen_lIilIiiIiIiIliIi(1400832639,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{2105249635,1296455906,1964472716,1977716365,242545059,1252914832}return SynapseXen_iillIlliII[1322603437]end)()]local SynapseXen_IIliiilIiiliilII=SynapseXen_liiiIlillIililIii[SynapseXen_iillIlliII[2716574232]or(function()local SynapseXen_lIiIIlIIliiiiliIiIiI="so if you'we nyot awawe of expwoiting by this point, you've pwobabwy been wiving undew a wock that the pionyeews used to wide fow miwes. wobwox is often seen as an expwoit-infested gwound by most fwom the suwface, awthough this isn't the case."SynapseXen_iillIlliII[2716574232]=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIiiliIilIiiiI(4158678024,1238442286),SynapseXen_lIilIiiIiIiIliIi(1141457967,SynapseXen_liIiiliIIiiiillIiIi))-string.len(SynapseXen_lIiIIlIIliiiiliIiIiI)-#{2362934768,3584825577,84763399,4058176963,4121109528,3464102765,4013913617,3644297691}return SynapseXen_iillIlliII[2716574232]end)()]return function(...)local SynapseXen_iIlIlllIIlIlillillI,SynapseXen_iIIII=1,-1;local SynapseXen_iIiIllIIliIIIilIi,SynapseXen_lliiiiIiII={},SynapseXen_iiilliIiI('#',...)-1;local SynapseXen_illIIIlIiiIIliIIi=0;local SynapseXen_iililIilIilllliiI={}local SynapseXen_llillili={}local SynapseXen_lIlllIIiiiIiii=setmetatable({},{__index=SynapseXen_iililIilIilllliiI,__newindex=function(SynapseXen_IilIilliiIiI,SynapseXen_IiiIiIiI,SynapseXen_lIlIiIlIIliiiillli)if SynapseXen_IiiIiIiI>SynapseXen_iIIII then SynapseXen_iIIII=SynapseXen_IiiIiIiI end;SynapseXen_iililIilIilllliiI[SynapseXen_IiiIiIiI]=SynapseXen_lIlIiIlIIliiiillli end})local function SynapseXen_lllIiIiIII()local SynapseXen_liiiiiiI,SynapseXen_IllIiiI;while true do SynapseXen_liiiiiiI=SynapseXen_IilIiiiillll[SynapseXen_iIlIlllIIlIlillillI]SynapseXen_IllIiiI=SynapseXen_liiiiiiI[422628075]SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+1;if SynapseXen_IllIiiI==191 then local SynapseXen_iiIIliI=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[1328471899],32,512)local SynapseXen_liiiIilliiilIIliil=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[688126082],115,512)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_iiIIliI>255 then SynapseXen_iiIIliI=SynapseXen_IIiililIilIlllliiili[SynapseXen_iiIIliI-256]else SynapseXen_iiIIliI=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]end;if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;SynapseXen_IIIillllliiIiIi[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],10,256)]=SynapseXen_iiIIliI/SynapseXen_liiiIilliiilIIliil elseif SynapseXen_IllIiiI==29 then SynapseXen_lIlllIIiiiIiii[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],1,256)]=SynapseXen_IIiililIilIlllliiili[SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[863174940],140271,262144)]elseif SynapseXen_IllIiiI==39 then SynapseXen_lIlllIIiiiIiii[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],98),SynapseXen_illIIIlIiiIIliIIi,256)]=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[1328471899],104,512)~=0;if SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[688126082],113,512)~=0 then SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+1 end elseif SynapseXen_IllIiiI==186 then local SynapseXen_iliIlIIIliIlIi=SynapseXen_IIliiilIiiliilII[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[863174940],80584)]local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;local SynapseXen_IIlliilliIl;local SynapseXen_ilIiiIIllliiIlll;if SynapseXen_iliIlIIIliIlIi[971025170]~=0 then SynapseXen_IIlliilliIl={}SynapseXen_ilIiiIIllliiIlll=setmetatable({},{__index=function(SynapseXen_IilIilliiIiI,SynapseXen_IiiIiIiI)local SynapseXen_illllI=SynapseXen_IIlliilliIl[SynapseXen_IiiIiIiI]return SynapseXen_illllI[1][SynapseXen_illllI[2]]end,__newindex=function(SynapseXen_IilIilliiIiI,SynapseXen_IiiIiIiI,SynapseXen_lIlIiIlIIliiiillli)local SynapseXen_illllI=SynapseXen_IIlliilliIl[SynapseXen_IiiIiIiI]SynapseXen_illllI[1][SynapseXen_illllI[2]]=SynapseXen_lIlIiIlIIliiiillli end})for SynapseXen_illililIiil=1,SynapseXen_iliIlIIIliIlIi[971025170]do local SynapseXen_lIIIilIillIiiIIilIi=SynapseXen_IilIiiiillll[SynapseXen_iIlIlllIIlIlillillI]if SynapseXen_lIIIilIillIiiIIilIi[422628075]==68 then SynapseXen_IIlliilliIl[SynapseXen_illililIiil-1]={SynapseXen_IIIillllliiIiIi,SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIIIilIillIiiIIilIi[1328471899],69)}elseif SynapseXen_lIIIilIillIiiIIilIi[422628075]==209 then SynapseXen_IIlliilliIl[SynapseXen_illililIiil-1]={SynapseXen_iiIIiilIIiliiilIiIiI,SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIIIilIillIiiIIilIi[1328471899],126)}end;SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+1 end;SynapseXen_llillili[#SynapseXen_llillili+1]=SynapseXen_IIlliilliIl end;SynapseXen_IIIillllliiIiIi[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],75,256)]=SynapseXen_Illlllii(SynapseXen_iliIlIIIliIlIi,SynapseXen_iliIlliiliIlIIIilIil,SynapseXen_ilIiiIIllliiIlll)elseif SynapseXen_IllIiiI==75 then SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+SynapseXen_liiiiiiI[1426143073]elseif SynapseXen_IllIiiI==59 then local SynapseXen_iiIIliI,SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[1328471899],93,512),SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[688126082],99)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_iiIIliI>255 then SynapseXen_iiIIliI=SynapseXen_IIiililIilIlllliiili[SynapseXen_iiIIliI-256]else SynapseXen_iiIIliI=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]end;if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;SynapseXen_IIIillllliiIiIi[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],37)][SynapseXen_iiIIliI]=SynapseXen_liiiIilliiilIIliil elseif SynapseXen_IllIiiI==237 then local SynapseXen_iiIIliI=SynapseXen_lIlllIIiiiIiii[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[1328471899],62,512)]if not not SynapseXen_iiIIliI==(SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[688126082],28)==0)then SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+1 else SynapseXen_lIlllIIiiiIiii[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],6)]=SynapseXen_iiIIliI end elseif SynapseXen_IllIiiI==188 then SynapseXen_lIlllIIiiiIiii[SynapseXen_lilIiIlliIi(SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],45),SynapseXen_illIIIlIiiIIliIIi,256)]=not SynapseXen_lIlllIIiiiIiii[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[1328471899],35)]elseif SynapseXen_IllIiiI==84 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],126,256)local SynapseXen_iiIIliI=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[1328471899],67)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;local SynapseXen_lllIiIIl,SynapseXen_iilIliiIlIli;local SynapseXen_iillllIIIlliilIlIiiI;if SynapseXen_iiIIliI==1 then return elseif SynapseXen_iiIIliI==0 then SynapseXen_iillllIIIlliilIlIiiI=SynapseXen_iIIII else SynapseXen_iillllIIIlliilIlIiiI=SynapseXen_IiIIillillliIiiliiI+SynapseXen_iiIIliI-2 end;SynapseXen_iilIliiIlIli={}SynapseXen_lllIiIIl=0;for SynapseXen_illililIiil=SynapseXen_IiIIillillliIiiliiI,SynapseXen_iillllIIIlliilIlIiiI do SynapseXen_lllIiIIl=SynapseXen_lllIiIIl+1;SynapseXen_iilIliiIlIli[SynapseXen_lllIiIIl]=SynapseXen_IIIillllliiIiIi[SynapseXen_illililIiil]end;return SynapseXen_iilIliiIlIli,SynapseXen_lllIiIIl elseif SynapseXen_IllIiiI==57 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],8)local SynapseXen_iiIIliI=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[1328471899],36,512)local SynapseXen_liiiIilliiilIIliil=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[688126082],23)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;local SynapseXen_IlIiiiiIlIi,SynapseXen_iiIIllllIli;local SynapseXen_iillllIIIlliilIlIiiI,SynapseXen_lllIiIIl;SynapseXen_IlIiiiiIlIi={}if SynapseXen_iiIIliI~=1 then if SynapseXen_iiIIliI~=0 then SynapseXen_iillllIIIlliilIlIiiI=SynapseXen_IiIIillillliIiiliiI+SynapseXen_iiIIliI-1 else SynapseXen_iillllIIIlliilIlIiiI=SynapseXen_iIIII end;SynapseXen_lllIiIIl=0;for SynapseXen_illililIiil=SynapseXen_IiIIillillliIiiliiI+1,SynapseXen_iillllIIIlliilIlIiiI do SynapseXen_lllIiIIl=SynapseXen_lllIiIIl+1;SynapseXen_IlIiiiiIlIi[SynapseXen_lllIiIIl]=SynapseXen_IIIillllliiIiIi[SynapseXen_illililIiil]end;SynapseXen_iillllIIIlliilIlIiiI,SynapseXen_iiIIllllIli=SynapseXen_IIIlIiIllIIIliiillli(SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI](unpack(SynapseXen_IlIiiiiIlIi,1,SynapseXen_iillllIIIlliilIlIiiI-SynapseXen_IiIIillillliIiiliiI)))else SynapseXen_iillllIIIlliilIlIiiI,SynapseXen_iiIIllllIli=SynapseXen_IIIlIiIllIIIliiillli(SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI]())end;SynapseXen_iIIII=SynapseXen_IiIIillillliIiiliiI-1;if SynapseXen_liiiIilliiilIIliil~=1 then if SynapseXen_liiiIilliiilIIliil~=0 then SynapseXen_iillllIIIlliilIlIiiI=SynapseXen_IiIIillillliIiiliiI+SynapseXen_liiiIilliiilIIliil-2 else SynapseXen_iillllIIIlliilIlIiiI=SynapseXen_iillllIIIlliilIlIiiI+SynapseXen_IiIIillillliIiiliiI-1 end;SynapseXen_lllIiIIl=0;for SynapseXen_illililIiil=SynapseXen_IiIIillillliIiiliiI,SynapseXen_iillllIIIlliilIlIiiI do SynapseXen_lllIiIIl=SynapseXen_lllIiIIl+1;SynapseXen_IIIillllliiIiIi[SynapseXen_illililIiil]=SynapseXen_iiIIllllIli[SynapseXen_lllIiIIl]end end elseif SynapseXen_IllIiiI==93 then SynapseXen_iiIIiilIIiliiilIiIiI[SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[1328471899],20,512)]=SynapseXen_lIlllIIiiiIiii[SynapseXen_lilIiIlliIi(SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],112,256),SynapseXen_illIIIlIiiIIliIIi,256)]elseif SynapseXen_IllIiiI==209 then SynapseXen_lIlllIIiiiIiii[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],107)]=SynapseXen_iiIIiilIIiliiilIiIiI[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[1328471899],126)]elseif SynapseXen_IllIiiI==251 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_lilIiIlliIi(SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],45),SynapseXen_illIIIlIiiIIliIIi,256)local SynapseXen_iiIIliI=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[1328471899],10,512)local SynapseXen_IIIillllliiIiIi,SynapseXen_iilIiiilIiiili=SynapseXen_lIlllIIiiiIiii,SynapseXen_iIiIllIIliIIIilIi;SynapseXen_iIIII=SynapseXen_IiIIillillliIiiliiI-1;for SynapseXen_illililIiil=SynapseXen_IiIIillillliIiiliiI,SynapseXen_IiIIillillliIiiliiI+(SynapseXen_iiIIliI>0 and SynapseXen_iiIIliI-1 or SynapseXen_lliiiiIiII)do SynapseXen_IIIillllliiIiIi[SynapseXen_illililIiil]=SynapseXen_iilIiiilIiiili[SynapseXen_illililIiil-SynapseXen_IiIIillillliIiiliiI]end elseif SynapseXen_IllIiiI==17 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],68),SynapseXen_illIIIlIiiIIliIIi,256)~=0;local SynapseXen_iiIIliI=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[1328471899],19,512),SynapseXen_illIIIlIiiIIliIIi)local SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[688126082],61,512),SynapseXen_illIIIlIiiIIliIIi,512)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_iiIIliI>255 then SynapseXen_iiIIliI=SynapseXen_IIiililIilIlllliiili[SynapseXen_iiIIliI-256]else SynapseXen_iiIIliI=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]end;if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;if SynapseXen_iiIIliI<=SynapseXen_liiiIilliiilIIliil~=SynapseXen_IiIIillillliIiiliiI then SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+1 end elseif SynapseXen_IllIiiI==1 then local SynapseXen_iiIIliI=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[1328471899],21,512)local SynapseXen_liiiIilliiilIIliil=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[688126082],98,512)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_iiIIliI>255 then SynapseXen_iiIIliI=SynapseXen_IIiililIilIlllliiili[SynapseXen_iiIIliI-256]else SynapseXen_iiIIliI=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]end;if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;SynapseXen_IIIillllliiIiIi[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],58,256)]=SynapseXen_iiIIliI%SynapseXen_liiiIilliiilIIliil elseif SynapseXen_IllIiiI==97 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],119,256)local SynapseXen_iiIIliI=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[1328471899],6,512)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;local SynapseXen_IlIiiiiIlIi,SynapseXen_iiIIllllIli;local SynapseXen_iillllIIIlliilIlIiiI;local SynapseXen_lilIliIilIiIi=0;SynapseXen_IlIiiiiIlIi={}if SynapseXen_iiIIliI~=1 then if SynapseXen_iiIIliI~=0 then SynapseXen_iillllIIIlliilIlIiiI=SynapseXen_IiIIillillliIiiliiI+SynapseXen_iiIIliI-1 else SynapseXen_iillllIIIlliilIlIiiI=SynapseXen_iIIII end;for SynapseXen_illililIiil=SynapseXen_IiIIillillliIiiliiI+1,SynapseXen_iillllIIIlliilIlIiiI do SynapseXen_IlIiiiiIlIi[#SynapseXen_IlIiiiiIlIi+1]=SynapseXen_IIIillllliiIiIi[SynapseXen_illililIiil]end;SynapseXen_iiIIllllIli={SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI](unpack(SynapseXen_IlIiiiiIlIi,1,SynapseXen_iillllIIIlliilIlIiiI-SynapseXen_IiIIillillliIiiliiI))}else SynapseXen_iiIIllllIli={SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI]()}end;for SynapseXen_ilill in next,SynapseXen_iiIIllllIli do if SynapseXen_ilill>SynapseXen_lilIliIilIiIi then SynapseXen_lilIliIilIiIi=SynapseXen_ilill end end;return SynapseXen_iiIIllllIli,SynapseXen_lilIliIilIiIi elseif SynapseXen_IllIiiI==231 then SynapseXen_lIlllIIiiiIiii[SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],21,256)]=-SynapseXen_lIlllIIiiiIiii[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[1328471899],35,512)]elseif SynapseXen_IllIiiI==14 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],80,256)local SynapseXen_iiIIliI=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[1328471899],31,512)local SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[688126082],120,512)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;SynapseXen_iiIIliI=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+1]=SynapseXen_iiIIliI;SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI]=SynapseXen_iiIIliI[SynapseXen_liiiIilliiilIIliil]elseif SynapseXen_IllIiiI==54 then SynapseXen_iliIlliiliIlIIIilIil[SynapseXen_IIiililIilIlllliiili[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[863174940],190020),SynapseXen_illIIIlIiiIIliIIi)]]=SynapseXen_lIlllIIiiiIiii[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],78,256),SynapseXen_illIIIlIiiIIliIIi,256)]elseif SynapseXen_IllIiiI==35 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],0),SynapseXen_illIIIlIiiIIliIIi,256)local SynapseXen_IliIlIIliiIlii={}for SynapseXen_illililIiil=1,#SynapseXen_llillili do local SynapseXen_IilIIIiIiiIIillii=SynapseXen_llillili[SynapseXen_illililIiil]for SynapseXen_iilIlIllilIiiIl=0,#SynapseXen_IilIIIiIiiIIillii do local SynapseXen_IiililI=SynapseXen_IilIIIiIiiIIillii[SynapseXen_iilIlIllilIiiIl]local SynapseXen_IIIillllliiIiIi=SynapseXen_IiililI[1]local SynapseXen_IliliiIIIIilIl=SynapseXen_IiililI[2]if SynapseXen_IIIillllliiIiIi==SynapseXen_lIlllIIiiiIiii and SynapseXen_IliliiIIIIilIl>=SynapseXen_IiIIillillliIiiliiI then SynapseXen_IliIlIIliiIlii[SynapseXen_IliliiIIIIilIl]=SynapseXen_IIIillllliiIiIi[SynapseXen_IliliiIIIIilIl]SynapseXen_IiililI[1]=SynapseXen_IliIlIIliiIlii end end end elseif SynapseXen_IllIiiI==34 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],59,256)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;local SynapseXen_lIllIiIlIlIlIil=SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+2]local SynapseXen_ilill=SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI]+SynapseXen_lIllIiIlIlIlIil;SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI]=SynapseXen_ilill;if SynapseXen_lIllIiIlIlIlIil>0 then if SynapseXen_ilill<=SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+1]then SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+SynapseXen_liiiiiiI[1426143073]SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+3]=SynapseXen_ilill end else if SynapseXen_ilill>=SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+1]then SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+SynapseXen_liiiiiiI[1426143073]SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+3]=SynapseXen_ilill end end elseif SynapseXen_IllIiiI==68 then SynapseXen_lIlllIIiiiIiii[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],88)]=SynapseXen_lIlllIIiiiIiii[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[1328471899],69)]elseif SynapseXen_IllIiiI==62 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],26,256)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI]=assert(tonumber(SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI]),'`for` initial value must be a number')SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+1]=assert(tonumber(SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+1]),'`for` limit must be a number')SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+2]=assert(tonumber(SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+2]),'`for` step must be a number')SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI]=SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI]-SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+2]SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+SynapseXen_liiiiiiI[1426143073]elseif SynapseXen_IllIiiI==107 then if SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[863174940],18085,262144)==149 then SynapseXen_lIlllIIiiiIiii[SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],114,256)]=SynapseXen_liIiiliIIiiiillIiIi else SynapseXen_lIlllIIiiiIiii[SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],114,256)]=SynapseXen_ilIllllilIilIIIIlI[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[863174940],18085,262144)]end elseif SynapseXen_IllIiiI==37 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],121)~=0;local SynapseXen_iiIIliI=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[1328471899],107,512),SynapseXen_illIIIlIiiIIliIIi)local SynapseXen_liiiIilliiilIIliil=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[688126082],108,512)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_iiIIliI>255 then SynapseXen_iiIIliI=SynapseXen_IIiililIilIlllliiili[SynapseXen_iiIIliI-256]else SynapseXen_iiIIliI=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]end;if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;if SynapseXen_iiIIliI<SynapseXen_liiiIilliiilIIliil~=SynapseXen_IiIIillillliIiiliiI then SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+1 end elseif SynapseXen_IllIiiI==201 then if not not SynapseXen_lIlllIIiiiIiii[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],84,256),SynapseXen_illIIIlIiiIIliIIi,256)]==(SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[688126082],96,512)==0)then SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+1 end elseif SynapseXen_IllIiiI==77 then local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;for SynapseXen_illililIiil=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],124,256),SynapseXen_illIIIlIiiIIliIIi,256),SynapseXen_lIilIiiIiIiIliIi(SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[1328471899],36,512),SynapseXen_illIIIlIiiIIliIIi)do SynapseXen_IIIillllliiIiIi[SynapseXen_illililIiil]=nil end elseif SynapseXen_IllIiiI==19 then local SynapseXen_iiIIliI=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[1328471899],64,512)local SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[688126082],10,512)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_iiIIliI>255 then SynapseXen_iiIIliI=SynapseXen_IIiililIilIlllliiili[SynapseXen_iiIIliI-256]else SynapseXen_iiIIliI=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]end;if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;SynapseXen_IIIillllliiIiIi[SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],75,256)]=SynapseXen_iiIIliI-SynapseXen_liiiIilliiilIIliil elseif SynapseXen_IllIiiI==116 then local SynapseXen_iiIIliI=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[1328471899],94)local SynapseXen_liiiIilliiilIIliil=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[688126082],30,512)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_iiIIliI>255 then SynapseXen_iiIIliI=SynapseXen_IIiililIilIlllliiili[SynapseXen_iiIIliI-256]else SynapseXen_iiIIliI=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]end;if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;SynapseXen_IIIillllliiIiIi[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],29,256)]=SynapseXen_iiIIliI+SynapseXen_liiiIilliiilIIliil elseif SynapseXen_IllIiiI==74 then local SynapseXen_iiIIliI=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[1328471899],93)local SynapseXen_liiiIilliiilIIliil=SynapseXen_lilIiIlliIi(SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[688126082],23),SynapseXen_illIIIlIiiIIliIIi,512)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_iiIIliI>255 then SynapseXen_iiIIliI=SynapseXen_IIiililIilIlllliiili[SynapseXen_iiIIliI-256]else SynapseXen_iiIIliI=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]end;if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;SynapseXen_IIIillllliiIiIi[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],61)]=SynapseXen_iiIIliI^SynapseXen_liiiIilliiilIIliil elseif SynapseXen_IllIiiI==170 then local SynapseXen_iiIIliI=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[1328471899],64,512),SynapseXen_illIIIlIiiIIliIIi,512)local SynapseXen_liiiIilliiilIIliil=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[688126082],59,512)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_iiIIliI>255 then SynapseXen_iiIIliI=SynapseXen_IIiililIilIlllliiili[SynapseXen_iiIIliI-256]else SynapseXen_iiIIliI=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]end;if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;SynapseXen_IIIillllliiIiIi[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],55,256)]=SynapseXen_iiIIliI*SynapseXen_liiiIilliiilIIliil elseif SynapseXen_IllIiiI==33 then local SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[688126082],65,512)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;SynapseXen_IIIillllliiIiIi[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],65)]=SynapseXen_IIIillllliiIiIi[SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[1328471899],42,512)][SynapseXen_liiiIilliiilIIliil]elseif SynapseXen_IllIiiI==143 then SynapseXen_lIlllIIiiiIiii[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],102),SynapseXen_illIIIlIiiIIliIIi)]=#SynapseXen_lIlllIIiiiIiii[SynapseXen_lilIiIlliIi(SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[1328471899],117,512),SynapseXen_illIIIlIiiIIliIIi,512)]elseif SynapseXen_IllIiiI==159 then local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;local SynapseXen_iiIIliI=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[1328471899],56)local SynapseXen_iIlIllil=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]for SynapseXen_illililIiil=SynapseXen_iiIIliI+1,SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[688126082],97)do SynapseXen_iIlIllil=SynapseXen_iIlIllil..SynapseXen_IIIillllliiIiIi[SynapseXen_illililIiil]end;SynapseXen_lIlllIIiiiIiii[SynapseXen_lilIiIlliIi(SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],27,256),SynapseXen_illIIIlIiiIIliIIi,256)]=SynapseXen_iIlIllil elseif SynapseXen_IllIiiI==160 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],119,256)local SynapseXen_iiIIliI=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[1328471899],98,512),SynapseXen_illIIIlIiiIIliIIi)local SynapseXen_liiiIilliiilIIliil=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[688126082],11)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_liiiIilliiilIIliil==0 then SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+1;SynapseXen_liiiIilliiilIIliil=SynapseXen_IilIiiiillll[SynapseXen_iIlIlllIIlIlillillI][1340504709]end;local SynapseXen_iIiIiIIi=(SynapseXen_liiiIilliiilIIliil-1)*50;local SynapseXen_iilil=SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI]if SynapseXen_iiIIliI==0 then SynapseXen_iiIIliI=SynapseXen_iIIII-SynapseXen_IiIIillillliIiiliiI end;for SynapseXen_illililIiil=1,SynapseXen_iiIIliI do SynapseXen_iilil[SynapseXen_iIiIiIIi+SynapseXen_illililIiil]=SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+SynapseXen_illililIiil]end elseif SynapseXen_IllIiiI==233 then SynapseXen_lIlllIIiiiIiii[SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],61,256)]=SynapseXen_iliIlliiliIlIIIilIil[SynapseXen_IIiililIilIlllliiili[SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[863174940],131061,262144)]]elseif SynapseXen_IllIiiI==140 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_IIIiiiiiilIiiiilii(SynapseXen_liiiiiiI[2005561348],39,256)local SynapseXen_liiiIilliiilIIliil=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[688126082],122)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;local SynapseXen_iIiIiIIi=SynapseXen_IiIIillillliIiiliiI+2;local SynapseXen_IlIlllIllIlIl={SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI](SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+1],SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+2])}for SynapseXen_illililIiil=1,SynapseXen_liiiIilliiilIIliil do SynapseXen_lIlllIIiiiIiii[SynapseXen_iIiIiIIi+SynapseXen_illililIiil]=SynapseXen_IlIlllIllIlIl[SynapseXen_illililIiil]end;if SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+3]~=nil then SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+2]=SynapseXen_IIIillllliiIiIi[SynapseXen_IiIIillillliIiiliiI+3]else SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+1 end elseif SynapseXen_IllIiiI==134 then SynapseXen_illIIIlIiiIIliIIi=SynapseXen_lIlllIIiiiIiii[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],71)]elseif SynapseXen_IllIiiI==196 then SynapseXen_lIlllIIiiiIiii[SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[2005561348],99)]={}elseif SynapseXen_IllIiiI==103 then local SynapseXen_IiIIillillliIiiliiI=SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[2005561348],62,256)~=0;local SynapseXen_iiIIliI=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_liiiiiiI[1328471899],48)local SynapseXen_liiiIilliiilIIliil=SynapseXen_lIilIiiIiIiIliIi(SynapseXen_lilIiIlliIi(SynapseXen_liiiiiiI[688126082],22,512),SynapseXen_illIIIlIiiIIliIIi)local SynapseXen_IIIillllliiIiIi=SynapseXen_lIlllIIiiiIiii;if SynapseXen_iiIIliI>255 then SynapseXen_iiIIliI=SynapseXen_IIiililIilIlllliiili[SynapseXen_iiIIliI-256]else SynapseXen_iiIIliI=SynapseXen_IIIillllliiIiIi[SynapseXen_iiIIliI]end;if SynapseXen_liiiIilliiilIIliil>255 then SynapseXen_liiiIilliiilIIliil=SynapseXen_IIiililIilIlllliiili[SynapseXen_liiiIilliiilIIliil-256]else SynapseXen_liiiIilliiilIIliil=SynapseXen_IIIillllliiIiIi[SynapseXen_liiiIilliiilIIliil]end;if SynapseXen_iiIIliI==SynapseXen_liiiIilliiilIIliil~=SynapseXen_IiIIillillliIiiliiI then SynapseXen_iIlIlllIIlIlillillI=SynapseXen_iIlIlllIIlIlillillI+1 end end end end;local SynapseXen_IlIiiiiIlIi={...}for SynapseXen_illililIiil=0,SynapseXen_lliiiiIiII do if SynapseXen_illililIiil>=SynapseXen_liiiIlillIililIii[1232933912]then SynapseXen_iIiIllIIliIIIilIi[SynapseXen_illililIiil-SynapseXen_liiiIlillIililIii[1232933912]]=SynapseXen_IlIiiiiIlIi[SynapseXen_illililIiil+1]else SynapseXen_lIlllIIiiiIiii[SynapseXen_illililIiil]=SynapseXen_IlIiiiiIlIi[SynapseXen_illililIiil+1]end end;local SynapseXen_iiIIliI,SynapseXen_liiiIilliiilIIliil=SynapseXen_lllIiIiIII()if SynapseXen_iiIIliI and SynapseXen_liiiIilliiilIIliil>0 then return unpack(SynapseXen_iiIIliI,1,SynapseXen_liiiIilliiilIIliil)end;return end end;local function SynapseXen_lIliiIIliilIli(SynapseXen_iIliIllillllilliiIii,SynapseXen_iliIlliiliIlIIIilIil)local SynapseXen_iIIiIIIliIiIlI=SynapseXen_IIIlill(SynapseXen_iIliIllillllilliiIii)return SynapseXen_Illlllii(SynapseXen_iIIiIIIliIiIlI,SynapseXen_iliIlliiliIlIIIilIil or getfenv(0)),SynapseXen_iIIiIIIliIiIlI end;return SynapseXen_lIliiIIliilIli(SynapseXen_IiIiII("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"),getfenv())()
    
end)


-- Секция
local Tab = Window:NewTab("Player")

-- Слайдер
Section:NewSlider("WalkSpeed", "Изменяет скорость персонажа.", 500, 1, function(s)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = s
end)

-- Слайдер
Section:NewSlider("JumpPower", "Изменяет высоту прыжка персонажа.", 500, 1, function(s)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = s
end)


-- Кнопка
Section:NewButton("Invisible", "Делает персонажа прозрачным. Уберите головные уборы.", function()
    loadstring(game:HttpGet("https://cdn.wearedevs.net/scripts/Invisible%20Character.txt"))()
    
end)

-- Секция
local Tab = Window:NewTab("Other")

-- Кнопка
Section:NewButton("InfiniteYield", "Admin Script", function()
    loadstring(game:HttpGet("https://cdn.wearedevs.net/scripts/Infinite%20Yield.txt"))()
    
end)

-- Кнопка
Section:NewButton("Click Teleport", "Left ctrl + click", function()
    loadstring(game:HttpGet("https://cdn.wearedevs.net/scripts/Click%20Teleport.txt"))()
    
end)
