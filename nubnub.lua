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
-- SERVER LIST / TARGET SERVER
--==================================================
local attemptedServers = {}
local lastTeleportData = nil

local function getRequestFunction()
    return request
        or http_request
        or (syn and syn.request)
end

local function getPublicServers()
    local requestFunc = getRequestFunction()
    if not requestFunc then
        return nil, "Executor request function is unavailable"
    end

    local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId)
        .. "/servers/Public?sortOrder=Asc&limit=100"

    local ok, response = pcall(function()
        return requestFunc({
            Url = url,
            Method = "GET",
            Headers = { ["Content-Type"] = "application/json" }
        })
    end)

    if not ok or not response then
        return nil, "Server API request failed"
    end

    local status = tonumber(response.StatusCode or response.Status)
    if status and status ~= 200 then
        return nil, "Server API HTTP " .. tostring(status)
    end

    local body = response.Body
    if type(body) ~= "string" or body == "" then
        return nil, "Server API returned empty body"
    end

    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not decodeOk or type(data) ~= "table" or type(data.data) ~= "table" then
        return nil, "Invalid server API response"
    end

    return data.data
end

local function findDifferentServer(previousJobId)
    local servers, err = getPublicServers()
    if not servers then
        return nil, err
    end

    local candidates = {}

    for _, server in ipairs(servers) do
        local jobId = tostring(server.id or "")
        local playing = tonumber(server.playing) or 0
        local maxPlayers = tonumber(server.maxPlayers) or 0

        if jobId ~= ""
            and jobId ~= game.JobId
            and jobId ~= tostring(previousJobId or "")
            and not attemptedServers[jobId]
            and maxPlayers > 0
            and playing < maxPlayers then
            table.insert(candidates, server)
        end
    end

    if #candidates == 0 then
        -- Allow previously attempted servers again, but NEVER the current/previous one.
        for _, server in ipairs(servers) do
            local jobId = tostring(server.id or "")
            local playing = tonumber(server.playing) or 0
            local maxPlayers = tonumber(server.maxPlayers) or 0

            if jobId ~= ""
                and jobId ~= game.JobId
                and jobId ~= tostring(previousJobId or "")
                and maxPlayers > 0
                and playing < maxPlayers then
                table.insert(candidates, server)
            end
        end
    end

    if #candidates == 0 then
        return nil, "No different public server found"
    end

    -- Prefer the server with fewer players to reduce the chance of immediately
    -- joining the same crowded matchmaking group.
    table.sort(candidates, function(a, b)
        return (tonumber(a.playing) or 0) < (tonumber(b.playing) or 0)
    end)

    return candidates[1]
end

--==================================================
-- SEND SUCCESS / CONTINUE RETRY AFTER TELEPORT
--==================================================
local function handleTeleportArrival()
    local teleportData

    pcall(function()
        teleportData = TeleportService:GetLocalPlayerTeleportData()
    end)

    if type(teleportData) ~= "table" or teleportData.NubNubTeleport ~= true then
        return false
    end

    lastTeleportData = teleportData
    retryCount = tonumber(teleportData.Attempt) or 1
    local previousJobId = tostring(teleportData.SourceJobId or "")
    local targetJobId = tostring(teleportData.TargetJobId or "")

    task.wait(2)

    -- A teleport is only considered successful if Roblox actually placed us
    -- in a different JobId.
    if targetJobId ~= "" and game.JobId == targetJobId then
        -- expected target reached
    elseif previousJobId ~= "" and game.JobId == previousJobId then
        WindUI:Notify({
            Title = "Server Change",
            Content = "Teleport returned to the previous server.",
            Icon = "triangle-alert",
            Duration = 4
        })
    end

    local foundName, foundPlayer
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and isBlacklisted(otherPlayer.Name) then
            foundName = otherPlayer.Name
            foundPlayer = otherPlayer
            break
        end
    end

    if foundPlayer then
        -- We DID change server, but the target is still here.
        -- Keep the same retry chain instead of resetting to 1/20.
        teleporting = false

        sendWebhook(
            "🟡 Blacklisted Player Found",
            "**Username:** " .. foundPlayer.Name ..
            "\n**Display Name:** " .. foundPlayer.DisplayName ..
            "\n**User ID:** " .. foundPlayer.UserId ..
            "\n**Attempt:** " .. retryCount .. "/" .. MAX_RETRY ..
            "\n**Place ID:** " .. game.PlaceId ..
            "\n**Job ID:** `" .. game.JobId .. "`",
            FOUND_COLOR
        )

        if retryCount >= MAX_RETRY then
            sendWebhook(
                "🔴 Server Change Failed",
                "Blacklist player is still present after maximum attempts." ..
                "\n**Attempts:** " .. retryCount .. "/" .. MAX_RETRY ..
                "\n**Job ID:** `" .. game.JobId .. "`",
                FAILED_COLOR
            )
            return true
        end

        task.delay(TELEPORT_COOLDOWN, function()
            if enabled then
                checkServer()
            end
        end)

        return true
    end

    -- No blacklist found: this is a genuine successful server change.
    sendWebhook(
        "🟢 Server Change Successful",
        "**Username:** " .. player.Name ..
        "\n**Display Name:** " .. player.DisplayName ..
        "\n**User ID:** " .. player.UserId ..
        "\n**Attempt:** " .. retryCount .. "/" .. MAX_RETRY ..
        "\n**Place ID:** " .. game.PlaceId ..
        "\n**Old Job ID:** `" .. previousJobId .. "`" ..
        "\n**New Job ID:** `" .. game.JobId .. "`" ..
        "\n**Status:** Server change successful",
        SUCCESS_COLOR
    )

    WindUI:Notify({
        Title = "Server Changed",
        Content = "Server change successful.\nAttempt " .. retryCount .. "/" .. MAX_RETRY,
        Icon = "check",
        Duration = 4
    })

    return true
end

--==================================================
-- SERVER CHECK / CHANGE
--==================================================
function checkServer()
    if not enabled or teleporting then
        return
    end

    local foundPlayer
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and isBlacklisted(otherPlayer.Name) then
            foundPlayer = otherPlayer
            break
        end
    end

    if not foundPlayer then
        return
    end

    teleporting = true

    -- Do NOT reset retryCount here. It is restored from TeleportData after a
    -- successful teleport, which fixes the old 1/20 -> 1/20 -> 1/20 loop.
    if retryCount < 1 then
        retryCount = 0
    end

    sendWebhook(
        "🟡 Blacklisted Player Found",
        "**Username:** " .. foundPlayer.Name ..
        "\n**Display Name:** " .. foundPlayer.DisplayName ..
        "\n**User ID:** " .. foundPlayer.UserId ..
        "\n**Attempt:** " .. math.min(retryCount + 1, MAX_RETRY) .. "/" .. MAX_RETRY ..
        "\n**Place ID:** " .. game.PlaceId ..
        "\n**Job ID:** `" .. game.JobId .. "`",
        FOUND_COLOR
    )

    WindUI:Notify({
        Title = "Player Found",
        Content = foundPlayer.Name .. " is in blacklist.\nFinding a different server...",
        Icon = "triangle-alert",
        Duration = 3
    })

    task.spawn(function()
        task.wait(TELEPORT_COOLDOWN)

        if not enabled then
            teleporting = false
            return
        end

        local nextAttempt = retryCount + 1
        if nextAttempt > MAX_RETRY then
            teleporting = false
            sendWebhook(
                "🔴 Server Change Failed",
                "Maximum retry count reached." ..
                "\n**Attempts:** " .. MAX_RETRY .. "/" .. MAX_RETRY ..
                "\n**Job ID:** `" .. game.JobId .. "`",
                FAILED_COLOR
            )
            return
        end

        local previousJobId = ""
        if lastTeleportData and lastTeleportData.SourceJobId then
            previousJobId = tostring(lastTeleportData.SourceJobId)
        end

        local targetServer, searchError = findDifferentServer(previousJobId)
        if not targetServer then
            teleporting = false
            WindUI:Notify({
                Title = "Server Search Failed",
                Content = tostring(searchError or "Unknown error"),
                Icon = "triangle-alert",
                Duration = 5
            })
            sendWebhook(
                "🔴 Server Search Failed",
                "**Reason:** " .. tostring(searchError or "Unknown error") ..
                "\n**Attempt:** " .. nextAttempt .. "/" .. MAX_RETRY ..
                "\n**Current Job ID:** `" .. game.JobId .. "`",
                FAILED_COLOR
            )
            return
        end

        local targetJobId = tostring(targetServer.id)
        attemptedServers[targetJobId] = true

        sendWebhook(
            "🔵 Server Change Attempt",
            "**Attempt:** " .. nextAttempt .. "/" .. MAX_RETRY ..
            "\n**Place ID:** " .. game.PlaceId ..
            "\n**Old Job ID:** `" .. game.JobId .. "`" ..
            "\n**Target Job ID:** `" .. targetJobId .. "`" ..
            "\n**Players:** " .. tostring(targetServer.playing or 0) .. "/" .. tostring(targetServer.maxPlayers or 0) ..
            "\n**Status:** Attempting server change...",
            ATTEMPT_COLOR
        )

        local teleportData = {
            NubNubTeleport = true,
            Attempt = nextAttempt,
            SourceJobId = game.JobId,
            TargetJobId = targetJobId
        }

        local teleported = false

        -- Official Roblox API: TeleportOptions.ServerInstanceId selects a
        -- specific public JobId. TeleportAsync is server-script-only in the
        -- official API, so executor clients may reject this call.
        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions.ServerInstanceId = targetJobId
        teleportOptions:SetTeleportData(teleportData)

        local ok, result = pcall(function()
            return TeleportService:TeleportAsync(game.PlaceId, {player}, teleportOptions)
        end)

        if ok then
            teleported = true
        else
            -- Compatibility fallback for executors that still expose the
            -- deprecated client teleport-to-instance API.
            local fallbackOk = pcall(function()
                TeleportService:TeleportToPlaceInstance(
                    game.PlaceId,
                    targetJobId,
                    player,
                    nil,
                    teleportData
                )
            end)
            teleported = fallbackOk

            if not fallbackOk then
                sendWebhook(
                    "🔴 Server Change Failed",
                    "**Reason:** " .. tostring(result) ..
                    "\n**Attempt:** " .. nextAttempt .. "/" .. MAX_RETRY ..
                    "\n**Target Job ID:** `" .. targetJobId .. "`",
                    FAILED_COLOR
                )
            end
        end

        if not teleported then
            teleporting = false
            return
        end

        -- Keep retryCount alive until the destination script loads.
        retryCount = nextAttempt
    end)
end

_G.NubNubCheckServer = checkServer

--==================================================
-- TELEPORT FAILED
--==================================================
TeleportService.TeleportInitFailed:Connect(function(failedPlayer, teleportResult, errorMessage)
    if failedPlayer ~= player then
        return
    end

    teleporting = false

    sendWebhook(
        "🔴 Server Change Failed",
        "**Result:** " .. tostring(teleportResult) ..
        "\n**Reason:** " .. tostring(errorMessage) ..
        "\n**Attempts:** " .. retryCount .. "/" .. MAX_RETRY ..
        "\n**Current Job ID:** `" .. game.JobId .. "`",
        FAILED_COLOR
    )

    if retryCount < MAX_RETRY and enabled then
        task.delay(TELEPORT_COOLDOWN, function()
            if enabled then
                checkServer()
            end
        end)
    end
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
-- CHECK TELEPORT RESULT / START CHECK
--==================================================

task.spawn(function()
    task.wait(2)

    local arrivedFromTeleport = handleTeleportArrival()

    if not arrivedFromTeleport and enabled then
        checkServer()
    end
end)

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
