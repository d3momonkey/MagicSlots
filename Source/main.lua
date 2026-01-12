import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx = playdate.graphics

-- Game Constants
local SCREEN_W = 400
local SCREEN_H = 240
local REEL_W = 100
local REEL_H = 150 -- Will show 3 symbols (50px each)
local REEL_X_START = 40
local REEL_SPACING = 10

-- Symbol Definitions with Values
local SYMBOLS = {
    {name="GEM", val=1000},
    {name="7", val=500},
    {name="BELL", val=200},
    {name="BAR", val=100},
    {name="CHERRY", val=50}
}
local NUM_SYMBOLS = #SYMBOLS
local SYMBOL_H = 50

-- Game State
local STATE_IDLE = 1
local STATE_SPINNING = 2
local STATE_STOPPING = 3
local STATE_WIN = 4

local currentState = STATE_IDLE

-- Reels
local reels = {
    {pos = 0, speed = 0, target = 0, stopping = false},
    {pos = 0, speed = 0, target = 0, stopping = false},
    {pos = 0, speed = 0, target = 0, stopping = false}
}

-- Networking (Leaderboard)
local score = 0
local leaderboardURL = "http://localhost:3000/leaderboard" -- Placeholder

function submitScore(newScore)
    print("Submitting score: " .. newScore)
    -- In a real scenario, use playdate.network.http.post
    -- local json = json.encode({score = newScore})
    -- playdate.network.http.post(leaderboardURL, json, ...)
end

function getSymbolIndexAt(reel, offset)
    -- offset: -1 (Top), 0 (Center), 1 (Bottom)
    local rawPos = math.floor(reel.pos) + offset
    -- Lua 1-based indexing modulo arithmetic
    -- (value - 1) % max + 1
    return (rawPos % NUM_SYMBOLS) + 1
end

function checkWin()
    local totalWin = 0
    local winLines = {} -- Store info about winning lines if we want to draw them later

    -- Helper to get symbol ID at (reel, row_offset)
    -- row_offset: -1=Top, 0=Center, 1=Bottom
    local function sym(reelIdx, rowOffset)
        return getSymbolIndexAt(reels[reelIdx], rowOffset)
    end

    -- Define 5 Paylines: { {reel1_row, reel2_row, reel3_row}, ... }
    local paylines = {
        {0, 0, 0},   -- 1. Center
        {-1, -1, -1},-- 2. Top
        {1, 1, 1},   -- 3. Bottom
        {-1, 0, 1},  -- 4. Diagonal Top-Left -> Bottom-Right
        {1, 0, -1}   -- 5. Diagonal Bottom-Left -> Top-Right
    }

    for lineIdx, offsets in ipairs(paylines) do
        local s1 = sym(1, offsets[1])
        local s2 = sym(2, offsets[2])
        local s3 = sym(3, offsets[3])

        local winAmount = 0
        local symbolData = nil

        -- Check 3-of-a-kind
        if s1 == s2 and s2 == s3 then
            symbolData = SYMBOLS[s1]
            winAmount = symbolData.val
            print("Line " .. lineIdx .. " WIN: 3x " .. symbolData.name)
        else
            -- Check Cherries (Left-to-Right)
            -- Cherry is defined as the symbol with name "CHERRY"
            local cherryIdx = 0
            for i, s in ipairs(SYMBOLS) do if s.name == "CHERRY" then cherryIdx = i break end end
            
            if s1 == cherryIdx then
                if s2 == cherryIdx then
                    -- 2 Cherries
                    winAmount = 20 -- Medium payout
                    print("Line " .. lineIdx .. " WIN: 2x CHERRY")
                else
                    -- 1 Cherry
                    winAmount = 5 -- Small payout
                    print("Line " .. lineIdx .. " WIN: 1x CHERRY")
                end
            end
        end

        if winAmount > 0 then
            totalWin += winAmount
            table.insert(winLines, lineIdx)
        end
    end
    
    if totalWin > 0 then
        score += totalWin
        currentState = STATE_WIN
        print("TOTAL WIN: " .. totalWin)
        submitScore(score)
    else
        currentState = STATE_IDLE
    end
end

function startSpin()
    currentState = STATE_SPINNING
    for i, reel in ipairs(reels) do
        reel.speed = 0.5 + i * 0.2 -- Slower speed
        reel.stopping = false
    end
end

function stopReels()
    if currentState == STATE_SPINNING then
        currentState = STATE_STOPPING
        -- Set targets to land on a symbol
        for i, reel in ipairs(reels) do
            playdate.timer.performAfterDelay(i * 500, function()
                reel.stopping = true
                -- Align to next integer position
                local currentPos = reel.pos
                local nextSymbol = math.ceil(currentPos) 
                reel.target = nextSymbol
            end)
        end
    end
end

function updateReels()
    local allStopped = true
    for i, reel in ipairs(reels) do
        if reel.speed > 0 then
            if reel.stopping then
                -- Move towards target
                local diff = reel.target - reel.pos
                if diff < 0.1 then
                    reel.pos = reel.target
                    reel.speed = 0
                else
                     -- Simple ease out
                    reel.speed = diff * 0.2
                    if reel.speed < 0.1 then reel.speed = 0.1 end
                    reel.pos += reel.speed
                end
            else
                reel.pos += reel.speed
            end
            allStopped = false
        end
    end
    
    if currentState == STATE_STOPPING and allStopped then
        checkWin()
    end
end

function drawReels()
    gfx.setColor(gfx.kColorBlack)
    for i, reel in ipairs(reels) do
        local x = REEL_X_START + (i-1) * (REEL_W + REEL_SPACING)
        local y = (SCREEN_H - REEL_H) / 2
        
        -- Draw Reel Box
        gfx.drawRect(x, y, REEL_W, REEL_H)
        
        -- Draw 3 Symbols (Top, Center, Bottom)
        for offset = -1, 1 do
            local symbolIdx = getSymbolIndexAt(reel, offset)
            local symbolName = SYMBOLS[symbolIdx].name
            
            -- Calculate Y position for this symbol relative to reel center
            -- Center is at y + REEL_H/2
            -- Each symbol is SYMBOL_H height.
            -- offset -1: y + REEL_H/2 - SYMBOL_H
            -- offset  0: y + REEL_H/2
            -- offset  1: y + REEL_H/2 + SYMBOL_H
            -- We center the text in that band
            
            local symY = y + (REEL_H/2) + (offset * SYMBOL_H) - (SYMBOL_H/2)
            
            -- Center text vertically in the 50px cell. 
            -- Text height approx 20. (50-20)/2 = 15.
            gfx.drawTextInRect(symbolName, x + 10, symY + 15, REEL_W - 20, 20, nil, "...", kTextAlignment.center)
            
            -- Draw dividers (optional) - at bottom of cell
            if offset < 1 then
                -- Draw from x to x + REEL_W - 1 to fit exactly inside the box width
                gfx.drawLine(x, symY + SYMBOL_H, x + REEL_W - 1, symY + SYMBOL_H)
            end
        end
    end
end

function playdate.update()
    playdate.timer.updateTimers()
    gfx.clear()
    
    -- Handle Input
    local crankChange = playdate.getCrankChange()
    if currentState == STATE_IDLE and math.abs(crankChange) > 10 then
        startSpin()
    end
    
    -- Button to stop (optional, or auto stop?)
    if currentState == STATE_SPINNING and playdate.buttonJustPressed(playdate.kButtonA) then
        stopReels()
    end
    
    -- Auto stop after some time if crank used? 
    -- For now require button A or just wait? Let's make button A stop it for interactivity.
    
    -- Update Logic
    if currentState == STATE_SPINNING or currentState == STATE_STOPPING then
        updateReels()
    end
    
    if currentState == STATE_WIN then
        if playdate.buttonJustPressed(playdate.kButtonA) or math.abs(crankChange) > 5 then
            currentState = STATE_IDLE
        end
    end
    
    -- Draw
    drawReels()
    
    -- UI
    gfx.drawText("Score: " .. score, 10, 10)
    
    if currentState == STATE_IDLE then
        gfx.drawText("Crank to SPIN!", 120, 200)
    elseif currentState == STATE_SPINNING then
         gfx.drawText("Press A to STOP", 120, 200)
    elseif currentState == STATE_WIN then
        gfx.drawText("WINNER! Press A", 120, 200)
    end
end
