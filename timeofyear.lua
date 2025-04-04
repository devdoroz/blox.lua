--@ Module `blox.lua`
-- Lua wrapper for handling chat commands in Roblox

-- @ services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- @ modules

local Signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/devdoroz/Signal/refs/heads/main/Signal.lua"))()

-- @ init

local Client = {}

Client.commands = {}
Client.prefix = "!"

Client.on_message = Signal.new()

rconsoleprint = print
rconsolewarn = warn
rconsoleerr = warn
rconsoleinfo = print
rconsoleclear = function() end

rconsoleclear()

-- @ public

function Client.send(message)
    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
end

function Client.whisper(player, message)
    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/w " .. player.Name .. " " .. message, "All")
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
