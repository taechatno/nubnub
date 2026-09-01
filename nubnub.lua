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

-- ข้อ 2: Cooldown / Retry
local TELEPORT_COOLDOWN = 3
local MAX_RETRY = 20

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
-- TAB
--==================================================

local Tab = Window:Tab({
    Title = "Server",
    Icon = "users"
})

--==================================================
-- AUTO CHANGE SERVER
--==================================================

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
-- WEBHOOK
--==================================================

Tab:Section({
    Title = "Webhook"
})

-- ข้อ 4: เปิด/ปิด Webhook
local WebhookToggle

WebhookToggle = Tab:Toggle({
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

WebhookInput = Tab:Input({
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

Tab:Button({
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
                "🔵 Webhook Test",
                "Webhook ทำงานเรียบร้อย!",
                255
            )

            if success then

                WindUI:Notify({
                    Title = "Webhook",
                    Content = "Test Webhook sent.",
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
-- TEST SERVER CHECK
--==================================================

Tab:Button({
    Title = "Test Server Check",
    Icon = "scan-search",

    Callback = function()

        local foundPlayer = nil

        for _, otherPlayer in ipairs(
            Players:GetPlayers()
        ) do

            if otherPlayer ~= player
                and isBlacklisted(otherPlayer.Name) then

                foundPlayer = otherPlayer
                break
            end
        end

        if foundPlayer then

            WindUI:Notify({
                Title = "Blacklist Found",
                Content =
                    foundPlayer.Name ..
                    " is in your blacklist.",
                Icon = "triangle-alert",
                Duration = 4
            })

        else

            WindUI:Notify({
                Title = "Server Safe",
                Content =
                    "No blacklisted player found.",
                Icon = "check",
                Duration = 4
            })

        end
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
-- SERVER CHECK
--==================================================

local function checkServer()

    if not enabled then
        return
    end

    if teleporting then
        return
    end

    for _, otherPlayer in ipairs(
        Players:GetPlayers()
    ) do

        if otherPlayer ~= player
            and isBlacklisted(otherPlayer.Name) then

            teleporting = true
            retryCount = 0

            --========================================
            -- 🟡 BLACKLIST FOUND
            --========================================

            task.spawn(function()

                sendWebhook(
                    "🟡 Blacklisted Player Found",

                    "**Username:** " ..
                    otherPlayer.Name ..

                    "\n**Display Name:** " ..
                    otherPlayer.DisplayName ..

                    "\n**User ID:** " ..
                    otherPlayer.UserId ..

                    "\n**Place ID:** " ..
                    game.PlaceId ..

                    "\n**Job ID:** `" ..
                    game.JobId ..
                    "`",

                    16776960
                )

            end)

            WindUI:Notify({
                Title = "Player Found",
                Content =
                    otherPlayer.Name ..
                    " is in blacklist.\nChanging server...",
                Icon = "triangle-alert",
                Duration = 3
            })

            --========================================
            -- TELEPORT
            --========================================

            task.spawn(function()

                task.wait(TELEPORT_COOLDOWN)

                local success = pcall(function()

                    TeleportService:Teleport(
                        game.PlaceId,
                        player
                    )

                end)

                if not success then

                    retryCount += 1

                    teleporting = false

                    -- 🔴 Retry
                    if retryCount < MAX_RETRY then

                        task.wait(
                            TELEPORT_COOLDOWN
                        )

                        if enabled then
                            checkServer()
                        end

                    else

                        task.spawn(function()

                            sendWebhook(
                                "🔴 Server Change Failed",

                                "ไม่สามารถย้ายเซิร์ฟได้" ..

                                "\n**Attempts:** " ..
                                MAX_RETRY ..

                                "\n**Place ID:** " ..
                                game.PlaceId,

                                16711680
                            )

                        end)

                    end
                end

            end)

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

TeleportService.TeleportInitFailed:Connect(
    function()

        teleporting = false
        retryCount += 1

        if retryCount < MAX_RETRY then

            task.wait(
                TELEPORT_COOLDOWN
            )

            if enabled then
                checkServer()
            end

        else

            task.spawn(function()

                sendWebhook(
                    "🔴 Server Change Failed",

                    "Teleport ถูกปฏิเสธหรือไม่สำเร็จ" ..

                    "\n**Attempts:** " ..
                    MAX_RETRY ..

                    "\n**Place ID:** " ..
                    game.PlaceId,

                    16711680
                )

            end)

        end

    end
)

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
