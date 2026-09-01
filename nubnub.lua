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
local TELEPORT_TIMEOUT = 15
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

-- เก็บ Job ID ก่อนเริ่มย้าย
local originalJobId = game.JobId

-- ป้องกันการส่ง Attempt ซ้ำ
local lastAttemptSent = 0

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
-- TELEPORT SUCCESS
--==================================================

local function sendTeleportSuccess(attempt)

    sendWebhook(
        "🟢 Server Change Successful",

        "**Username:** " ..
        player.Name ..

        "\n**Display Name:** " ..
        player.DisplayName ..

        "\n**User ID:** " ..
        player.UserId ..

        "\n**Attempt:** " ..
        attempt ..
        "/" ..
        MAX_RETRY ..

        "\n**Place ID:** " ..
        game.PlaceId ..

        "\n**New Job ID:** `" ..
        game.JobId ..
        "`" ..

        "\n**Status:** Server change successful",

        SUCCESS_COLOR
    )

end

--==================================================
-- TELEPORT FAILURE
--==================================================

local function teleportFailed(reason)

    if not teleporting then
        return
    end

    teleporting = false

    if retryCount >= MAX_RETRY then

        sendWebhook(
            "🔴 Server Change Failed",

            "ไม่สามารถย้ายเซิร์ฟได้" ..

            "\n**Reason:** " ..
            tostring(reason or "Unknown") ..

            "\n**Attempts:** " ..
            retryCount ..
            "/" ..
            MAX_RETRY ..

            "\n**Place ID:** " ..
            game.PlaceId ..

            "\n**Job ID:** `" ..
            game.JobId ..
            "`",

            FAILED_COLOR
        )

        WindUI:Notify({
            Title = "Server Change Failed",
            Content =
                "Failed after " ..
                retryCount ..
                "/" ..
                MAX_RETRY ..
                " attempts.",

            Icon = "x",
            Duration = 5
        })

        return
    end

    task.wait(TELEPORT_COOLDOWN)

    if enabled then
        _G.NubNubStartTeleport()
    end

end

--==================================================
-- START TELEPORT
--==================================================

local function startTeleport()

    if not enabled then
        return
    end

    if teleporting then
        return
    end

    if retryCount >= MAX_RETRY then

        sendWebhook(
            "🔴 Server Change Failed",

            "ถึงจำนวน Retry สูงสุดแล้ว" ..

            "\n**Attempts:** " ..
            retryCount ..
            "/" ..
            MAX_RETRY ..

            "\n**Place ID:** " ..
            game.PlaceId ..

            "\n**Job ID:** `" ..
            game.JobId ..
            "`",

            FAILED_COLOR
        )

        return
    end

    teleporting = true

    retryCount += 1

    local currentAttempt = retryCount
    local jobBeforeTeleport = game.JobId

    --==============================================
    -- WEBHOOK ATTEMPT
    --==============================================

    if lastAttemptSent ~= currentAttempt then

        lastAttemptSent = currentAttempt

        task.spawn(function()

            sendWebhook(
                "🔵 Server Change Attempt",

                "**Attempt:** " ..
                currentAttempt ..
                "/" ..
                MAX_RETRY ..

                "\n**Place ID:** " ..
                game.PlaceId ..

                "\n**Old Job ID:** `" ..
                jobBeforeTeleport ..
                "`" ..

                "\n**Status:** Attempting server change...",

                ATTEMPT_COLOR
            )

        end)

    end

    --==============================================
    -- UI
    --==============================================

    WindUI:Notify({
        Title = "Changing Server",
        Content =
            "Attempt " ..
            currentAttempt ..
            "/" ..
            MAX_RETRY,

        Icon = "refresh-cw",
        Duration = 3
    })

    --==============================================
    -- TELEPORT
    --==============================================

    local teleportCalled = false

    local success, errorMessage = pcall(function()

        -- ใช้ Teleport ฝั่ง Client
        -- แทน TeleportAsync ที่อาจไม่ทำงานใน Client

        TeleportService:Teleport(
            game.PlaceId,
            player
        )

        teleportCalled = true

    end)

    if not success then

        teleportFailed(
            "Teleport error: " ..
            tostring(errorMessage)
        )

        return

    end

    if not teleportCalled then

        teleportFailed(
            "Teleport was not called"
        )

        return

    end

    --==============================================
    -- TIMEOUT CHECK
    --==============================================

    task.spawn(function()

        local startTime = os.clock()

        while teleporting
            and os.clock() - startTime < TELEPORT_TIMEOUT do

            task.wait(1)

            -- ถ้า Job ID เปลี่ยน
            -- แปลว่าย้ายเซิร์ฟสำเร็จแล้ว

            if game.JobId ~= jobBeforeTeleport
                and game.JobId ~= "" then

                teleporting = false

                sendTeleportSuccess(
                    currentAttempt
                )

                WindUI:Notify({
                    Title = "Server Changed",
                    Content =
                        "Server change successful.\n" ..
                        "Attempt " ..
                        currentAttempt ..
                        "/" ..
                        MAX_RETRY,

                    Icon = "check",
                    Duration = 4
                })

                return

            end

        end

        --==========================================
        -- TIMEOUT
        --==========================================

        if teleporting then

            teleportFailed(
                "Teleport timeout (" ..
                TELEPORT_TIMEOUT ..
                " seconds)"
            )

        end

    end)

end

_G.NubNubStartTeleport = startTeleport

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

            --======================================
            -- BLACKLIST FOUND
            --======================================

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

                    FOUND_COLOR
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

            --======================================
            -- START TELEPORT
            --======================================

            task.spawn(function()

                task.wait(TELEPORT_COOLDOWN)

                if enabled
                    and not teleporting then

                    startTeleport()

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
-- TELEPORT INIT FAILED
--==================================================

TeleportService.TeleportInitFailed:Connect(
    function(
        failedPlayer,
        teleportResult,
        errorMessage
    )

        -- สนใจเฉพาะ LocalPlayer
        if failedPlayer
            and failedPlayer ~= player then

            return

        end

        if not teleporting then
            return
        end

        local reason =
            tostring(errorMessage or teleportResult or "Unknown")

        teleportFailed(
            "TeleportInitFailed: " ..
            reason
        )

    end
)

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

    -- ถ้าเราเข้ามาเซิร์ฟใหม่
    -- และ Job ID เปลี่ยนจากตอนก่อน Teleport

    if game.JobId ~= originalJobId
        and game.JobId ~= "" then

        -- ไม่ส่งซ้ำถ้าไม่มี teleport state
        -- เพราะเซิร์ฟอาจถูกเข้าโดยปกติ

    end

end)

--==================================================
-- START CHECK
--==================================================

task.wait(0.5)

checkServer()

--==================================================
-- PLAYER JOIN
--==================================================

Players.PlayerAdded:Connect(
    function(newPlayer)

        task.wait(1)

        if enabled
            and not teleporting then

            checkServer()

        end

    end
)
