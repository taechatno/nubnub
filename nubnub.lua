local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local WindUI = require(path.to.WindUI)

local blacklist = {
    ["Ollightw99"] = true,
    ["im_mythaw"] = true,
    ["ifelpenkhonthai"] = true
}

local player = Players.LocalPlayer
local enabled = true

local Window = WindUI:CreateWindow({
    Title = "Server Guard",
})

local Tab = Window:Tab({
    Title = "Main",
})

Tab:Toggle({
    Title = "Auto Leave",
    Value = true,
    Callback = function(value)
        enabled = value
    end
})

Tab:Button({
    Title = "Check Server",
    Callback = function()
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
})
