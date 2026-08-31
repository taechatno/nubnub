local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local blacklist = {
    ["Ollightw99"] = true,
    ["PlayerName2"] = true,
    ["PlayerName3"] = true
}

local player = Players.LocalPlayer

local function checkServer()
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and blacklist[otherPlayer.Name] then
            TeleportService:Teleport(game.PlaceId, player)
            return
        end
    end
end

checkServer()

Players.PlayerAdded:Connect(function()
    task.wait(1)
    checkServer()
end)
