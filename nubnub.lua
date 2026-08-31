local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

-- WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Blacklist
local blacklist = {
    ["Ollightw99"] = true,
    ["im_mythaw"] = true,
    ["ifelpenkhonthai"] = true
}

local player = Players.LocalPlayer

-- Window
local Window = WindUI:CreateWindow({
    Title = "nubnub",
    Icon = "door-open",
    Author = "by nubnub",
})

-- Tab
local Tab = Window:Tab({
    Title = "Server",
})

-- Toggle
local enabled = true

Tab:Toggle({
    Title = "Auto Leave",
    Value = true,
    Callback = function(value)
        enabled = value
    end
})

-- Check Server
local function checkServer()
    if not enabled then
        return
    end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and blacklist[otherPlayer.Name] then
            TeleportService:Teleport(game.PlaceId, player)
            return
        end
    end
end

Tab:Button({
    Title = "Check Server",
    Callback = function()
        checkServer()
    end
})

checkServer()

Players.PlayerAdded:Connect(function()
    task.wait(1)
    checkServer()
end)
