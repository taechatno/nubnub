local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

--==================================================
-- WINDUI
--==================================================

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local player = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local MAX_USERS = 15

local TELEPORT_COOLDOWN = 3
local MAX_RETRY = 20

-- Webhook Colors
local ATTEMPT_COLOR = 3447003
local SUCCESS_COLOR = 65280
local FOUND_COLOR = 16776960
local FAILED_COLOR = 16711680

local enabled = true
local webhookEnabled = true

local usernameValues = {}
local WebhookURL = ""

local teleporting = false
local retryCount = 0
local configLoaded = false

for i = 1, MAX_USERS do
    usernameValues[i] = ""
end

--==================================================
-- WINDOW
--==================================================

local Window = WindUI:CreateWindow({
    Title = "nubnub",
    Icon = "flame",
    Author = "by nubnub",
    Folder = "nubnub"
})

--==================================================
-- CONFIG
--==================================================

local ConfigManager = Window.ConfigManager
local Config = nil

if ConfigManager then
    pcall(function()
        ConfigManager:Init(Window)
        Config = ConfigManager:CreateConfig("AutoLeave")
    end)
end

local function saveConfig()
    if not configLoaded then
        return
    end

    if Config then
        pcall(function()
            Config:Save()
        end)
    end
end

--==================================================
-- SERVER TAB
--==================================================

local Tab = Window:Tab({
    Title = "Server",
    Icon = "users"
})

--==================================================
-- CHANGE SERVER
--==================================================

Tab:Section({
    Title = "Change Server"
})

local AutoChangeServerToggle

AutoChangeServerToggle = Tab:Toggle({
    Title = "Auto Change Server",
    Desc = "Change server when target player is found",
    Flag = "AutoChangeServer",
    Value = true,

    Callback = function(value)
        enabled = value
        saveConfig()

        if value and configLoaded then
            task.spawn(function()
                task.wait(0.1)

                if _G.NubNubCheckServer then
                    _G.NubNubCheckServer()
                end
            end)
        end
    end
})

--==================================================
-- USERNAME LIST
--==================================================

Tab:Section({
    Title = "Username Blacklist"
})

Tab:Paragraph({
    Title = "Target Players",
    Desc =
        "Enter username only. @ is optional.\n" ..
        "You can save up to " .. MAX_USERS .. " players."
})

local UsernameInputs = {}

for i = 1, MAX_USERS do

    UsernameInputs[i] = Tab:Input({
        Title = "Username " .. i,
        Flag = "Username_" .. i,
        Value = "",
        Placeholder = "Enter username...",

        Callback = function(value)

            value = tostring(value or "")
            value = value:gsub("@", "")
            value = value:gsub("%s+", "")

            usernameValues[i] = value

            saveConfig()

        end
    })

end

--==================================================
-- CLEAN USERNAME
--==================================================

local function cleanUsername(name)

    if not name then
        return ""
    end

    name = tostring(name)
    name = name:gsub("@", "")
    name = name:gsub("%s+", "")

    return string.lower(name)

end

--==================================================
-- BLACKLIST CHECK
--==================================================

local function isBlacklisted(username)

    local targetName = cleanUsername(username)

    if targetName == "" then
        return false
    end

    for i = 1, MAX_USERS do

        local savedName =
            cleanUsername(usernameValues[i])

        if savedName ~= ""
            and savedName == targetName then

            return true

        end

    end

    return false

end

--==================================================
-- WEBHOOK TAB
--==================================================

local WebhookTab = Window:Tab({
    Title = "Webhook",
    Icon = "webhook"
})

--==================================================
-- WEBHOOK SETTINGS
--==================================================

local WebhookToggle

WebhookToggle = WebhookTab:Toggle({
    Title = "Webhook Notification",
    Desc = "Enable Discord notifications",
    Flag = "WebhookEnabled",
    Value = true,

    Callback = function(value)

        webhookEnabled = value
        saveConfig()

    end
})

local WebhookInput

WebhookInput = WebhookTab:Input({
    Title = "Discord Webhook",
    Desc = "Paste your Discord Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    InputIcon = "webhook",
    Flag = "WebhookURL",
    Value = "",

    Callback = function(value)

        WebhookURL = tostring(value or "")
        saveConfig()

    end
})

--==================================================
-- REQUEST
--==================================================

local function getRequestFunction()

    return request
        or http_request
        or (syn and syn.request)

end

--==================================================
-- EMBED WEBHOOK
--==================================================

local function sendWebhook(title, description, color)

    if not webhookEnabled then
        return false
    end

    if WebhookURL == "" then
        return false
    end

    local requestFunc = getRequestFunction()

    if not requestFunc then
        return false
    end

    local success = pcall(function()

        requestFunc({
            Url = WebhookURL,
            Method = "POST",

            Headers = {
                ["Content-Type"] = "application/json"
            },

            Body = HttpService:JSONEncode({
                embeds = {
                    {
                        title = title,
                        description = description,
                        color = color,

                        footer = {
                            text = "nubnub"
                        }
                    }
                }
            })
        })

    end)

    return success
end

--==================================================
-- TEST WEBHOOK
--==================================================

WebhookTab:Button({
    Title = "Test Webhook",
    Icon = "send",

    Callback = function()

        if WebhookURL == "" then

            WindUI:Notify({
                Title = "Webhook",
                Content = "Please enter Webhook URL first.",
                Icon = "triangle-alert",
                Duration = 3
            })

            return
        end

        task.spawn(function()

            local success = sendWebhook(
                "🟢 Server Change Successful",

                "**Username:** test_webhook" ..
                "\n**Display Name:** Test Webhook" ..
                "\n**User ID:** 123456789" ..
                "\n**Attempt:** 1/20" ..
                "\n**Place ID:** 987654321" ..
                "\n**Job ID:** `test-job-id-123456`" ..
                "\n**Status:** Server change successful",

                SUCCESS_COLOR
            )

            if success then

                WindUI:Notify({
                    Title = "Webhook",
                    Content = "Test successful webhook sent.",
                    Icon = "check",
                    Duration = 3
                })

            else

                WindUI:Notify({
                    Title = "Webhook",
                    Content = "ส่ง Webhook ไม่สำเร็จ",
                    Icon = "triangle-alert",
                    Duration = 3
                })

            end

        end)

    end
})

--==================================================
-- CLEAR ALL USERNAMES
--==================================================

Tab:Button({
    Title = "Clear All Username",
    Icon = "trash-2",

    Callback = function()

        for i = 1, MAX_USERS do

            usernameValues[i] = ""

            pcall(function()

                if UsernameInputs[i].SetValue then
                    UsernameInputs[i]:SetValue("")
                end

            end)

        end

        saveConfig()

        WindUI:Notify({
            Title = "Username",
            Content = "All usernames cleared.",
            Icon = "check",
            Duration = 3
        })

    end
})

--==================================================
-- SEND SUCCESS AFTER TELEPORT
--==================================================

local rejoinCurrentPlace

local function checkTeleportData()
    local teleportData

    pcall(function()
        teleportData = TeleportService:GetLocalPlayerTeleportData()
    end)

    if not teleportData then
        return
    end

    if teleportData.NubNubTeleport ~= true then
        return
    end

    local attempt = tonumber(teleportData.Attempt) or 1

    task.wait(2)

    -- Important: only report success when the new server is actually safe.
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and isBlacklisted(otherPlayer.Name) then
            WindUI:Notify({
                Title = "Blacklist Still Found",
                Content = otherPlayer.Name .. " is still here. Rejoining again...",
                Icon = "triangle-alert",
                Duration = 3
            })

            teleporting = false
            rejoinCurrentPlace()
            return
        end
    end

    sendWebhook(
        "🟢 Server Change Successful",
        "**Username:** " .. player.Name ..
        "\n**Display Name:** " .. player.DisplayName ..
        "\n**User ID:** " .. player.UserId ..
        "\n**Attempt:** " .. attempt .. "/" .. MAX_RETRY ..
        "\n**Place ID:** " .. game.PlaceId ..
        "\n**New Job ID:** `" .. game.JobId .. "`" ..
        "\n**Status:** Left old server and joined again successfully",
        SUCCESS_COLOR
    )

    WindUI:Notify({
        Title = "Server Changed",
        Content = "Rejoin successful.\nAttempt " .. attempt .. "/" .. MAX_RETRY,
        Icon = "check",
        Duration = 4
    })
end

--==================================================
-- SERVER CHECK / AUTO REJOIN
--==================================================

rejoinCurrentPlace = function()
    if teleporting then
        return
    end

    teleporting = true
    retryCount += 1

    if retryCount > MAX_RETRY then
        task.spawn(function()
            sendWebhook(
                "🔴 Server Change Failed",
                "Auto rejoin reached maximum attempts." ..
                "\n**Attempts:** " .. retryCount .. "/" .. MAX_RETRY ..
                "\n**Place ID:** " .. game.PlaceId ..
                "\n**Job ID:** `" .. game.JobId .. "`",
                FAILED_COLOR
            )
        end)
        teleporting = false
        return
    end

    task.spawn(function()
        sendWebhook(
            "🔵 Server Rejoin Attempt",
            "**Attempt:** " .. retryCount .. "/" .. MAX_RETRY ..
            "\n**Place ID:** " .. game.PlaceId ..
            "\n**Old Job ID:** `" .. game.JobId .. "`" ..
            "\n**Status:** Leaving current server and rejoining...",
            ATTEMPT_COLOR
        )
    end)

    WindUI:Notify({
        Title = "Rejoining Server",
        Content = "Leaving current server and joining again...\nAttempt " .. retryCount .. "/" .. MAX_RETRY,
        Icon = "refresh-cw",
        Duration = 3
    })

    local teleportOptions = Instance.new("TeleportOptions")
    teleportOptions:SetTeleportData({
        NubNubTeleport = true,
        Attempt = retryCount,
        AutoRejoin = true
    })

    -- No public-server HTTP API is used here, so this path avoids
    -- the games.roblox.com server-list request that can return HTTP 429.
    local success = pcall(function()
        TeleportService:TeleportAsync(
            game.PlaceId,
            {player},
            teleportOptions
        )
    end)

    -- Client/executor environments may reject TeleportAsync.
    -- Try the legacy client teleport as a compatibility fallback.
    if not success then
        local fallbackSuccess = pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)

        if not fallbackSuccess then
            teleporting = false

            task.spawn(function()
                sendWebhook(
                    "🔴 Server Rejoin Failed",
                    "Teleport request could not be started." ..
                    "\n**Attempt:** " .. retryCount .. "/" .. MAX_RETRY ..
                    "\n**Place ID:** " .. game.PlaceId ..
                    "\n**Job ID:** `" .. game.JobId .. "`",
                    FAILED_COLOR
                )
            end)
        end
    end
end

local function checkServer()
    if not enabled then
        return
    end

    if teleporting then
        return
    end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and isBlacklisted(otherPlayer.Name) then
            -- Do not query the public-server HTTP API.
            -- Simply leave this server and rejoin the same Place.
            task.spawn(function()
                sendWebhook(
                    "🟡 Blacklisted Player Found",
                    "**Username:** " .. otherPlayer.Name ..
                    "\n**Display Name:** " .. otherPlayer.DisplayName ..
                    "\n**User ID:** " .. otherPlayer.UserId ..
                    "\n**Place ID:** " .. game.PlaceId ..
                    "\n**Job ID:** `" .. game.JobId .. "`" ..
                    "\n**Action:** Leave + Rejoin",
                    FOUND_COLOR
                )
            end)

            WindUI:Notify({
                Title = "Player Found",
                Content = otherPlayer.Name .. " is in blacklist.\nLeaving and rejoining...",
                Icon = "triangle-alert",
                Duration = 3
            })

            rejoinCurrentPlace()
            return
        end
    end
end

--==================================================
-- GLOBAL CHECK
--==================================================

_G.NubNubCheckServer = checkServer

--==================================================
-- TELEPORT FAILED
--==================================================

pcall(function()
    TeleportService.TeleportInitFailed:Connect(function()
        teleporting = false

        if not enabled then
            return
        end

        -- If Roblox rejects the rejoin, wait briefly and try again.
        task.spawn(function()
            task.wait(1)
            if enabled then
                rejoinCurrentPlace()
            end
        end)
    end)
end)

--==================================================
-- CHECK SERVER BUTTON
--==================================================

Tab:Button({
    Title = "Check Server",
    Icon = "search",

    Callback = function()

        local found = false

        for _, otherPlayer in ipairs(
            Players:GetPlayers()
        ) do

            if otherPlayer ~= player
                and isBlacklisted(otherPlayer.Name) then

                found = true
                break

            end

        end

        if not found then

            WindUI:Notify({
                Title = "Server Safe",
                Content =
                    "No blacklisted player found.",
                Icon = "check",
                Duration = 3
            })

        end

        checkServer()

    end
})

--==================================================
-- CONFIG REGISTER
--==================================================

if Config then

    Config:Register(
        "AutoChangeServer",
        AutoChangeServerToggle
    )

    Config:Register(
        "WebhookEnabled",
        WebhookToggle
    )

    Config:Register(
        "WebhookURL",
        WebhookInput
    )

    for i = 1, MAX_USERS do

        Config:Register(
            "Username_" .. i,
            UsernameInputs[i]
        )

    end

    pcall(function()
        Config:Load()
    end)

end

--==================================================
-- WAIT FOR CONFIG
--==================================================

task.wait(1)

configLoaded = true

--==================================================
-- READ LOADED CONFIG
--==================================================

if AutoChangeServerToggle then
    enabled =
        AutoChangeServerToggle.Value
end

if WebhookToggle then
    webhookEnabled =
        WebhookToggle.Value
end

for i = 1, MAX_USERS do

    local input =
        UsernameInputs[i]

    if input and input.Value then

        usernameValues[i] =
            cleanUsername(input.Value)

    end

end

if WebhookInput
    and WebhookInput.Value then

    WebhookURL =
        tostring(
            WebhookInput.Value or ""
        )

end

saveConfig()

--==================================================
-- CHECK TELEPORT SUCCESS
--==================================================

task.spawn(function()

    task.wait(2)

    checkTeleportData()

end)

--==================================================
-- START CHECK
--==================================================

checkServer()

--==================================================
-- PLAYER JOIN
--==================================================

Players.PlayerAdded:Connect(
    function(newPlayer)

        task.wait(1)

        if enabled then
            checkServer()
        end

    end
)
