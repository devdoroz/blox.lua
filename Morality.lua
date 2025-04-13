--@ Module `blox.lua`
-- Lua wrapper for handling chat commands in Roblox

-- @ services

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- @ modules

local Signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/devdoroz/Signal/refs/heads/main/Signal.lua"))()

-- @ init

local Channels = TextChatService:FindFirstChild("TextChannels")
local Player = Players.LocalPlayer

local Client = {}

Client.commands = {}
Client.prefix = "!"

Client.on_message = Signal.new()

if ({identifyexecutor()})[1] ~= "AWP" then
    rconsoleprint = print
    rconsolewarn = warn
    rconsoleerr = warn
    rconsoleinfo = print
    rconsoleclear = function() end
end

rconsoleclear()

-- @ public

function Client.send(message)
    Channels.RBXGeneral:SendAsync(message)
end

function Client.whisper(player, message)
    local channelName = "RBXWhisper:" .. player.UserId .. "_" .. Player.UserId
    local reversedChannelName = "RBXWhisper:" .. Player.UserId .. "_" .. player.UserId
    local channel = Channels:FindFirstChild(channelName) or Channels:FindFirstChild(reversedChannelName)

    if not channel then
        print("No channel")
        Channels.RBXGeneral:SendAsync("/w @" .. player.Name)
        print("Creating channel")
        channel = Channels:WaitForChild(channelName)
        print("Retrieved channel")
        
        task.delay(0.5, function()
            print("Attempted to send message")
            channel:SendAsync(message)
        end)
    else
        task.delay(0.1, function()
            channel:SendAsync(message)
        end)
    end
end

function Client.createCommand(name, action)
    Client.commands[name] = action
    rconsoleinfo("Created command `" .. name .. "`")
end

-- @ private

function onPlayerAdded(player)
    player.Chatted:Connect(function(message)
        local context = {
            message = message,
            author = player,
            time = os.time(),
            reply = function(message)
                Client.send(player.DisplayName .. " - " .. message)
            end,
            whisper = function(message)
                Client.whisper(player, message)
            end
        }

        Client.on_message:Fire(context)

        if string.sub(message, 1, 1) == Client.prefix then
            local newMessage = string.sub(message, 2, #message)
            local split = string.split(newMessage, " ")

            local args = {}
            local commandName = split[1]
            
            for index = 2, #split, 1 do
                table.insert(args, split[index])
            end

            if not Client.commands[commandName] then
                return
            end

            local success, err = pcall(Client.commands[commandName], context, table.unpack(args))

            if not success then
                rconsoleerr("Error while handling `" .. commandName ..  "`, " .. err)
            else
                rconsoleprint("@@GREEN@@")
                rconsoleprint("[INFO] Successfully handled " .. commandName .. "!")
            end
        end
    end)
    
    rconsoleinfo("Acknowledged " .. player.Name)
end

for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

return Client
