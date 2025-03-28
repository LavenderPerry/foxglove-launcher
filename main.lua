-- LÖVE functions

local Game = require("foxglove.game")
local Callbacks = require("foxglove.callbacks")

local gameDir = "Games"
local games = {}
local selectedGame = 1
local launcherCallbacks
local font

function love.load(_)
    launcherCallbacks = Callbacks:getCurrent()

    love.filesystem.createDirectory(gameDir)
    local prevConf = love.conf

    -- Get the list of games
    for _, filename in ipairs(love.filesystem.getDirectoryItems(gameDir)) do
        -- Create the default game
        local game = Game:new({
            title = filename,
            filepath = gameDir .. "/" .. filename
        })

        if game then
            -- Get the rest of the config
            love.conf = nil
            if game:setup("conf.lua") then
                pcall(love.conf, game)
            end
            game:unset()

            -- Finally, add the game to the games list
            table.insert(games, game)
        end
    end

    love.conf = prevConf

    -- Get the font for drawing
    font = love.graphics.newFont("fonts/m6x11plus.ttf", 18, "none")
end

-- Draws text centered horizontally in the window
--
-- @param text string The text to draw
-- @param y number The y-value to draw at (multiplied by font line height)
local function drawCenteredText(text, y)
    love.graphics.print(
        text,
        (love.graphics.getWidth() - font:getWidth(text)) / 2,
        font:getHeight() * y
    )
end

-- TODO: actually good UI
function love.draw()
    love.graphics.setFont(font)
    love.graphics.setColor(0.8, 0.8, 0.8)

    -- Handle case when no games
    if #games == 0 then
        drawCenteredText("No games", 2)
        return
    end

    -- Print out all games
    for i, game in ipairs(games) do
        if i == selectedGame then
            love.graphics.setColor(1, 1, 1)
        end
        drawCenteredText(game.title, i * 3 - 1)
        love.graphics.setColor(0.8, 0.8, 0.8)
    end

    -- Rectangle around selected game
    love.graphics.setColor(1, 1, 1)
    local lineHeight = font:getHeight()
    love.graphics.rectangle(
        "line",
        lineHeight, lineHeight * (selectedGame * 3 - 2),
        love.graphics.getWidth() - lineHeight * 2, lineHeight * 3
    )
end

-- For now, this assumes keyboard with arrow key and space controls
-- Change as needed for the actual console
-- Also look into love.gamepadpressed and love.gamepadreleased
function love.keypressed(key)
    if key == "down" then -- Select next game
        selectedGame = selectedGame + 1
        if selectedGame > #games then
            selectedGame = 1
        end
        return
    end

    if key == "up" then -- Select previous game
        selectedGame = selectedGame - 1
        if selectedGame < 1 then
            selectedGame = #games
        end
        return
    end

    if key == "space" then -- Launch selected game
        local game = games[selectedGame]

        Callbacks.default:apply()
        if not game:setup("main.lua") then
            -- TODO: handle error
            launcherCallbacks:apply()
            return
        end

        if game.window.width and game.window.height then
            love.window.setMode(game.window.width, game.window.height)
        end

        love.load({})

        local gameCallbacks = Callbacks:getCurrent()
        -- Wrap the quit callback to return to the launcher
        -- TODO: wrap more of the callbacks for better compatability
        --       perhaps use a separate module for this
        function love.quit()
            if not (gameCallbacks.quit and gameCallbacks.quit()) then
                love.audio.stop() -- In case the game was playing audio
                game:unset()
                launcherCallbacks:apply()
            end

            return true
        end

        return
    end
end
