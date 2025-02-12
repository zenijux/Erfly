--Menu

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()
local Window = Library.CreateLib("Erfy - Army Roblox Rp", "RJTheme1")
local Tab = Window:NewTab("Main")
local Section = Tab:NewSection("Section Name")

Section:NewButton("ESP", "Подсвечивает игроков", function()
    loadstring(game:HttpGet("https://github.com/zenijux/Erfly/blob/main/esp"))()
end)
