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
local SERVER_FETCH_LIMIT = 100
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

--==================================================
-- TELEPORT STATE
--==================================================

local teleporting = false
local retryCount = 0
local configLoaded = false

local teleportData = nil
local arrivingFromTeleport = false

local lastFoundUsername = nil
local lastAttemptSent = 0
local lastSuccessJob = nil

--==================================================
-- INIT TELEPORT DATA
--==================================================

pcall(function()

    teleportData =
        TeleportService:GetLocalPlayerTeleportData()

end)

if type(teleportData) == "table"
    and teleportData.NubNubTeleport == true then

    arrivingFromTeleport = true

    retryCount =
        tonumber(teleportData.Attempt) or 1

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

        Config =
            ConfigManager:CreateConfig("AutoLeave")

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

        if value
            and configLoaded then

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
        "You can save up to " ..
        MAX_USERS ..
        " players."
})

local UsernameInputs = {}

for i = 1, MAX_USERS do

    UsernameInputs[i] = Tab:Input({

        Title = "Username " .. i,

        Flag =
            "Username_" .. i,

        Value = "",

        Placeholder =
            "Enter username...",

        Callback = function(value)

            value =
                tostring(value or "")

            value =
                value:gsub("@", "")

            value =
                value:gsub("%s+", "")

            usernameValues[i] =
                value

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

    name =
        tostring(name)

    name =
        name:gsub("@", "")

    name =
        name:gsub("%s+", "")

    return string.lower(name)

end

--==================================================
-- BLACKLIST CHECK
--==================================================

local function isBlacklisted(username)

    local targetName =
        cleanUsername(username)

    if targetName == "" then
        return false
    end

    for i = 1, MAX_USERS do

        local savedName =
            cleanUsername(
                usernameValues[i]
            )

        if savedName ~= ""
            and savedName == targetName then

            return true

        end

    end

    return false

end

--==================================================
-- FIND BLACKLIST PLAYER
--==================================================

local function findBlacklistedPlayer()

    for _, otherPlayer in
        ipairs(Players:GetPlayers()) do

        if otherPlayer ~= player
            and isBlacklisted(
                otherPlayer.Name
            ) then

            return otherPlayer

        end

    end

    return nil

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

    Desc =
        "Enable Discord notifications",

    Flag =
        "WebhookEnabled",

    Value = true,

    Callback = function(value)

        webhookEnabled =
            value

        saveConfig()

    end
})

local WebhookInput

WebhookInput = WebhookTab:Input({

    Title = "Discord Webhook",

    Desc =
        "Paste your Discord Webhook URL",

    Placeholder =
        "https://discord.com/api/webhooks/...",

    InputIcon =
        "webhook",

    Flag =
        "WebhookURL",

    Value = "",

    Callback = function(value)

        WebhookURL =
            tostring(value or "")

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
-- WEBHOOK
--==================================================

local function sendWebhook(
    title,
    description,
    color
)

    if not webhookEnabled then
        return false
    end

    if WebhookURL == "" then
        return false
    end

    local requestFunc =
        getRequestFunction()

    if not requestFunc then
        return false
    end

    local success =
        pcall(function()

            requestFunc({

                Url =
                    WebhookURL,

                Method =
                    "POST",

                Headers = {
                    ["Content-Type"] =
                        "application/json"
                },

                Body =
                    HttpService:JSONEncode({

                        embeds = {

                            {

                                title =
                                    title,

                                description =
                                    description,

                                color =
                                    color,

                                footer = {

                                    text =
                                        "nubnub"

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

                Title =
                    "Webhook",

                Content =
                    "Please enter Webhook URL first.",

                Icon =
                    "triangle-alert",

                Duration = 3

            })

            return

        end

        task.spawn(function()

            local success =
                sendWebhook(

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

                    Title =
                        "Webhook",

                    Content =
                        "Test successful webhook sent.",

                    Icon =
                        "check",

                    Duration = 3

                })

            else

                WindUI:Notify({

                    Title =
                        "Webhook",

                    Content =
                        "ส่ง Webhook ไม่สำเร็จ",

                    Icon =
                        "triangle-alert",

                    Duration = 3

                })

            end

        end)

    end

})

--==================================================
-- CLEAR USERNAMES
--==================================================

Tab:Button({

    Title =
        "Clear All Username",

    Icon =
        "trash-2",

    Callback = function()

        for i = 1, MAX_USERS do

            usernameValues[i] =
                ""

            pcall(function()

                if UsernameInputs[i].SetValue then

                    UsernameInputs[i]:
                        SetValue("")

                end

            end)

        end

        saveConfig()

        WindUI:Notify({

            Title =
                "Username",

            Content =
                "All usernames cleared.",

            Icon =
                "check",

            Duration = 3

        })

    end

})

--==================================================
-- SERVER API
--==================================================

local function getServers()

    local servers = {}
    local cursor = ""

    for page = 1, 3 do

        local url =
            "https://games.roblox.com/v1/games/" ..
            tostring(game.PlaceId) ..
            "/servers/Public?sortOrder=Asc&limit=" ..
            SERVER_FETCH_LIMIT

        if cursor ~= "" then

            url =
                url ..
                "&cursor=" ..
                HttpService:UrlEncode(cursor)

        end

        local success, result =
            pcall(function()

                return game:HttpGet(url)

            end)

        if not success then

            return servers

        end

        local decoded

        local decodeSuccess =
            pcall(function()

                decoded =
                    HttpService:JSONDecode(
                        result
                    )

            end)

        if not decodeSuccess
            or type(decoded) ~= "table" then

            return servers

        end

        if type(decoded.data) == "table" then

            for _, server in
                ipairs(decoded.data) do

                if type(server) == "table"
                    and server.id
                    and server.playing
                    and server.maxPlayers then

                    if server.playing <
                        server.maxPlayers then

                        table.insert(
                            servers,
                            server
                        )

                    end

                end

            end

        end

        cursor =
            decoded.nextPageCursor

        if not cursor
            or cursor == "" then

            break

        end

    end

    return servers

end

--==================================================
-- FIND DIFFERENT SERVER
--==================================================

local function findDifferentServer()

    local currentJobId =
        game.JobId

    local servers =
        getServers()

    if #servers == 0 then
        return nil
    end

    -- สุ่มจุดเริ่มต้น
    local startIndex =
        math.random(
            1,
            #servers
        )

    for offset = 0,
        #servers - 1 do

        local index =
            ((startIndex + offset - 1)
                % #servers) + 1

        local server =
            servers[index]

        if server
            and server.id
            and server.id ~= currentJobId then

            return server.id

        end

    end

    return nil

end

--==================================================
-- SEND ATTEMPT WEBHOOK
--==================================================

local function sendAttemptWebhook(
    attempt,
    targetJobId
)

    if lastAttemptSent == attempt then
        return
    end

    lastAttemptSent =
        attempt

    task.spawn(function()

        sendWebhook(

            "🔵 Server Change Attempt",

            "**Attempt:** " ..
            attempt ..
            "/" ..
            MAX_RETRY ..

            "\n**Place ID:** " ..
            game.PlaceId ..

            "\n**Current Job ID:** `" ..
            game.JobId ..
            "`" ..

            "\n**Target Job ID:** `" ..
            tostring(targetJobId) ..
            "`" ..

            "\n**Status:** Attempting server change...",

            ATTEMPT_COLOR

        )

    end)

end

--==================================================
-- BLACKLIST WEBHOOK
--==================================================

local function sendBlacklistWebhook(
    target
)

    if not target then
        return
    end

    -- กันส่งคนเดิมซ้ำในรอบเดียวกัน
    local key =
        tostring(target.UserId) ..
        ":" ..
        tostring(game.JobId)

    if lastFoundUsername == key then
        return
    end

    lastFoundUsername =
        key

    task.spawn(function()

        sendWebhook(

            "🟡 Blacklisted Player Found",

            "**Username:** " ..
            target.Name ..

            "\n**Display Name:** " ..
            target.DisplayName ..

            "\n**User ID:** " ..
            target.UserId ..

            "\n**Place ID:** " ..
            game.PlaceId ..

            "\n**Job ID:** `" ..
            game.JobId ..
            "`",

            FOUND_COLOR

        )

    end)

end

--==================================================
-- SUCCESS WEBHOOK
--==================================================

local function sendSuccessWebhook(
    attempt,
    oldJobId
)

    if lastSuccessJob ==
        game.JobId then

        return

    end

    lastSuccessJob =
        game.JobId

    task.spawn(function()

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

            "\n**Old Job ID:** `" ..
            tostring(oldJobId) ..
            "`" ..

            "\n**New Job ID:** `" ..
            game.JobId ..
            "`" ..

            "\n**Status:** Server change successful",

            SUCCESS_COLOR

        )

    end)

end

--==================================================
-- FAILED WEBHOOK
--==================================================

local function sendFailedWebhook(
    reason
)

    task.spawn(function()

        sendWebhook(

            "🔴 Server Change Failed",

            "**Reason:** " ..
            tostring(reason) ..

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

    end)

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

        sendFailedWebhook(
            "Maximum retry reached"
        )

        return

    end

    --==============================================
    -- INCREASE ATTEMPT
    --==============================================

    retryCount += 1

    local currentAttempt =
        retryCount

    --==============================================
    -- FIND NEW SERVER
    --==============================================

    WindUI:Notify({

        Title =
            "Finding Server",

        Content =
            "Searching for a different server...",

        Icon =
            "search",

        Duration = 3

    })

    local targetJobId =
        findDifferentServer()

    if not targetJobId then

        WindUI:Notify({

            Title =
                "Server Search Failed",

            Content =
                "Could not find another server.",

            Icon =
                "triangle-alert",

            Duration = 3

        })

        if currentAttempt >=
            MAX_RETRY then

            sendFailedWebhook(
                "Could not find another server"
            )

            return

        end

        task.delay(
            TELEPORT_COOLDOWN,
            function()

                if enabled then
                    startTeleport()
                end

            end
        )

        return

    end

    --==============================================
    -- STATE
    --==============================================

    teleporting = true

    local oldJobId =
        game.JobId

    --==============================================
    -- WEBHOOK
    --==============================================

    sendAttemptWebhook(
        currentAttempt,
        targetJobId
    )

    --==============================================
    -- UI
    --==============================================

    WindUI:Notify({

        Title =
            "Changing Server",

        Content =
            "Attempt " ..
            currentAttempt ..
            "/" ..
            MAX_RETRY,

        Icon =
            "refresh-cw",

        Duration = 3

    })

    --==============================================
    -- TELEPORT DATA
    --==============================================

    local data = {

        NubNubTeleport =
            true,

        Attempt =
            currentAttempt,

        SourceJobId =
            oldJobId,

        TargetJobId =
            targetJobId

    }

    --==============================================
    -- TELEPORT
    --==============================================

    local success, errorMessage =
        pcall(function()

            TeleportService:
                TeleportToPlaceInstance(

                    game.PlaceId,

                    targetJobId,

                    player,

                    nil,

                    data

                )

        end)

    if not success then

        teleporting = false

        if currentAttempt >=
            MAX_RETRY then

            sendFailedWebhook(
                "Teleport error: " ..
                tostring(errorMessage)
            )

            return

        end

        task.delay(
            TELEPORT_COOLDOWN,
            function()

                if enabled then
                    startTeleport()
                end

            end
        )

        return

    end

    --==============================================
    -- TIMEOUT
    --==============================================

    task.spawn(function()

        local startTime =
            os.clock()

        while teleporting
            and
            os.clock() - startTime
                < TELEPORT_TIMEOUT do

            task.wait(1)

        end

        if not teleporting then
            return
        end

        -- ยังอยู่เซิร์ฟเดิม
        if game.JobId ==
            oldJobId then

            teleporting =
                false

            if currentAttempt >=
                MAX_RETRY then

                sendFailedWebhook(
                    "Teleport timeout"
                )

                return

            end

            task.wait(
                TELEPORT_COOLDOWN
            )

            if enabled then
                startTeleport()
            end

        end

    end)

end

_G.NubNubStartTeleport =
    startTeleport

--==================================================
-- CHECK CURRENT SERVER
--==================================================

local function checkServer()

    if not enabled then
        return
    end

    if teleporting then
        return
    end

    local target =
        findBlacklistedPlayer()

    --==============================================
    -- BLACKLIST FOUND
    --==============================================

    if target then

        sendBlacklistWebhook(
            target
        )

        WindUI:Notify({

            Title =
                "Player Found",

            Content =
                target.Name ..
                " is in blacklist.\nChanging server...",

            Icon =
                "triangle-alert",

            Duration = 3

        })

        task.delay(
            TELEPORT_COOLDOWN,
            function()

                if enabled
                    and not teleporting then

                    startTeleport()

                end

            end
        )

        return

    end

    --==============================================
    -- SERVER SAFE
    --==============================================

    if arrivingFromTeleport then

        arrivingFromTeleport =
            false

        local attempt =
            retryCount

        local oldJobId = ""

        if type(teleportData)
            == "table" then

            oldJobId =
                tostring(
                    teleportData.SourceJobId
                    or ""
                )

        end

        -- ยืนยันว่าเซิร์ฟใหม่ไม่ใช่เซิร์ฟเดิม
        if game.JobId ~= ""
            and game.JobId ~= oldJobId then

            sendSuccessWebhook(
                attempt,
                oldJobId
            )

            WindUI:Notify({

                Title =
                    "Server Changed",

                Content =
                    "New server is safe.\n" ..
                    "Attempt " ..
                    attempt ..
                    "/" ..
                    MAX_RETRY,

                Icon =
                    "check",

                Duration = 4

            })

        end

        return

    end

end

_G.NubNubCheckServer =
    checkServer

--==================================================
-- TELEPORT FAILED EVENT
--==================================================

TeleportService.TeleportInitFailed:
    Connect(
        function(
            failedPlayer,
            teleportResult,
            errorMessage
        )

            if failedPlayer
                and failedPlayer ~= player then

                return

            end

            if not teleporting then
                return
            end

            teleporting =
                false

            local reason =
                tostring(
                    errorMessage
                    or teleportResult
                    or "Unknown"
                )

            local currentAttempt =
                retryCount

            if currentAttempt >=
                MAX_RETRY then

                sendFailedWebhook(
                    "TeleportInitFailed: " ..
                    reason
                )

                return

            end

            task.delay(
                TELEPORT_COOLDOWN,
                function()

                    if enabled then
                        startTeleport()
                    end

               
