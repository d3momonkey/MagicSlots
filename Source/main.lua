import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "asset_generator"
import "sound_manager"
import "particles"
import "rpg_manager"
import "floating_text"

local gfx = playdate.graphics

-- Initialize Sound
SoundManager.init()

-- Initialize RPG
Monster.spawn(1)

-- Game Constants
local SCREEN_W = 400
local SCREEN_H = 240
local REEL_W = 70 -- Narrower reels
local REEL_H = 150 
local REEL_X_START = 20 -- Left aligned
local REEL_SPACING = 5

-- Generate Assets
local symbolImages = AssetGenerator.generateAll()
local monsterImages = AssetGenerator.generateMonsters()

-- Use standard Light Mode
gfx.setBackgroundColor(gfx.kColorWhite)
gfx.setImageDrawMode(gfx.kDrawModeCopy) -- Draw images normally
gfx.setColor(gfx.kColorBlack) -- Default drawing color

-- Symbol Definitions with Values
local SYMBOLS = {
    {name="FIREBALL", type="MAGIC", val=1000, img=symbolImages["FIREBALL"]},
    {name="SWORD", type="DMG", val=500, img=symbolImages["SWORD"]},
    {name="SHIELD", type="BLOCK", val=200, img=symbolImages["SHIELD"]},
    {name="COIN", type="GOLD", val=100, img=symbolImages["COIN"]},
    {name="POTION", type="HEAL", val=50, img=symbolImages["POTION"]},
    {name="WILD", type="WILD", val=0, img=symbolImages["WILD"]}
}
local NUM_SYMBOLS = #SYMBOLS
local SYMBOL_H = 50

-- Game State
local STATE_TITLE = 0
local STATE_IDLE = 1
local STATE_SPINNING = 2
local STATE_STOPPING = 3
local STATE_WIN = 4
local STATE_MINIGAME = 5
local STATE_CLASS_SELECT = 6
local STATE_GAME_OVER = 7

local currentState = STATE_TITLE

-- Mini-Game Data
local minigameSequence = {}
local minigameIndex = 1
local winMultiplier = 1
local ARROW_ICONS = {
    [playdate.kButtonUp] = "UP",
    [playdate.kButtonDown] = "DOWN",
    [playdate.kButtonLeft] = "LEFT",
    [playdate.kButtonRight] = "RIGHT"
}

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
end

local winLinesToDraw = {}
local shakeIntensity = 0
local mana = 0
local MANA_MAX = 100
local wildActive = false
local isBigWin = false

function shakeScreen(amount)
    shakeIntensity = amount
end

function updateShake()
    if shakeIntensity > 0 then
        local ox = math.random(-shakeIntensity, shakeIntensity)
        local oy = math.random(-shakeIntensity, shakeIntensity)
        playdate.display.setOffset(ox, oy)
        shakeIntensity = shakeIntensity - 1
        if shakeIntensity < 0 then shakeIntensity = 0 end
    else
        playdate.display.setOffset(0, 0)
    end
end

function getSymbolIndexAt(reel, offset)
    -- offset: -1 (Top), 0 (Center), 1 (Bottom)
    local rawPos = math.floor(reel.pos) + offset
    -- Lua 1-based indexing modulo arithmetic
    -- (value - 1) % max + 1
    local idx = (rawPos % NUM_SYMBOLS) + 1
    
    -- Check if this is Reel 2 Center (We need to know WHICH reel called this... 
    -- The function signature is `getSymbolIndexAt(reel, offset)`. 
    -- We can check if `reel == reels[2]` and `offset == 0`.
    if wildActive and reel == reels[2] and offset == 0 then
        -- Find WILD index
        for i, s in ipairs(SYMBOLS) do if s.name == "WILD" then return i end end
    end
    
    return idx
end

function checkWin()
    local winLines = {} 
    local anyAction = false
    
    -- Helper to get symbol ID at (reel, row_offset)
    -- row_offset: -1=Top, 0=Center, 1=Bottom
    local function sym(reelIdx, rowOffset)
        return getSymbolIndexAt(reels[reelIdx], rowOffset)
    end

    -- Define 5 Paylines
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

        -- Check 3-of-a-kind with WILD
        local d1, d2, d3 = SYMBOLS[s1], SYMBOLS[s2], SYMBOLS[s3]
        local wildName = "WILD"
        
        local matchSym = nil
        if d1.name ~= wildName then matchSym = d1
        elseif d2.name ~= wildName then matchSym = d2
        elseif d3.name ~= wildName then matchSym = d3
        else matchSym = d1 end -- All Wilds
        
        local isMatch = true
        if d1.name ~= wildName and d1.name ~= matchSym.name then isMatch = false end
        if d2.name ~= wildName and d2.name ~= matchSym.name then isMatch = false end
        if d3.name ~= wildName and d3.name ~= matchSym.name then isMatch = false end

        if isMatch then
            anyAction = true
            -- RPG Battle Logic
            local dmg = 0
            if matchSym.type == "DMG" then
                dmg = 10
                if Player.class == "WARRIOR" then dmg = 15 end
            elseif matchSym.type == "MAGIC" then
                dmg = 20
                if Player.class == "MAGE" then dmg = 30 end
            elseif matchSym.type == "HEAL" then
                local healAmt = 10
                Player.hp = Player.hp + healAmt
                if Player.hp > Player.maxHp then Player.hp = Player.maxHp end
                FloatingText.spawn(260, 60, "+" .. healAmt .. " HP")
            elseif matchSym.type == "BLOCK" then
                Player.block = Player.block + 1
                FloatingText.spawn(260, 60, "BLOCK UP!")
            elseif matchSym.type == "GOLD" then
                local goldAmt = 50
                Player.gold = Player.gold + goldAmt
                FloatingText.spawn(260, 120, "+$" .. goldAmt)
            end
            
            -- Apply Damage
            if dmg > 0 then
                if Player.class == "ROGUE" and math.random(1, 10) == 1 then
                    dmg = dmg * 2 
                    FloatingText.spawn(320, 150, "CRIT!")
                end
                
                if winMultiplier > 1 then
                    dmg = dmg * winMultiplier
                end
                
                local dead = Monster.takeDamage(dmg)
                FloatingText.spawn(320, 170, "-" .. dmg .. " HP")
                
                if dead then
                    FloatingText.spawn(320, 140, "DEFEATED!")
                    Player.gainXp(50)
                    Monster.spawn(Monster.level + 1)
                    Player.gold = Player.gold + 100
                end
            end
            
            table.insert(winLines, lineIdx)
        else
            -- Partial Potions (Cherries)
            local isCherry1 = (d1.name == "POTION" or d1.name == wildName)
            local isCherry2 = (d2.name == "POTION" or d2.name == wildName)
            
            if isCherry1 then
                local heal = 0
                if isCherry2 then heal = 5 else heal = 2 end
                
                if heal > 0 then
                    Player.hp = Player.hp + heal
                    if Player.hp > Player.maxHp then Player.hp = Player.maxHp end
                    FloatingText.spawn(260, 60, "+" .. heal .. " HP")
                    anyAction = true
                    table.insert(winLines, lineIdx) -- Highlight partial? Maybe just first symbol.
                end
            end
        end
    end
    
    if anyAction then
        currentState = STATE_WIN
        SoundManager.play("win")
        
        -- Win Lines
        winLinesToDraw = winLines
        
        -- Screen Shake
        shakeScreen(5)
        
        -- Reset Wild
        wildActive = false
        winMultiplier = 1
        
        -- Check Big Win
        if #winLinesToDraw >= 2 then isBigWin = true else isBigWin = false end
        
    else
        currentState = STATE_IDLE
        SoundManager.play("lose")
        -- Gain Mana on Loss
        mana += 10
        if mana > MANA_MAX then mana = MANA_MAX end
        
        -- Monster Attack
        if Player.block > 0 then
            FloatingText.spawn(260, 60, "BLOCKED!")
            Player.block = Player.block - 1
        else
            Player.hp = Player.hp - Monster.damage
            FloatingText.spawn(260, 60, "-" .. Monster.damage .. " HP")
            shakeScreen(10)
            
            if Player.hp <= 0 then
                Player.hp = 0
                currentState = STATE_GAME_OVER
                print("GAME OVER")
            end
        end
    end
end

function castWildMagic()
    mana = 0
    wildActive = true
    SoundManager.play("win") -- reuse win sound as 'magic' sound
    -- Force start spin
    startSpin()
end

function startSpin()
    SoundManager.play("start")
    currentState = STATE_SPINNING
    winLinesToDraw = {} -- Clear old win lines
    
    -- Crank speed bonus
    local change = math.abs(playdate.getCrankChange())
    local speedBoost = 0
    if change > 50 then speedBoost = 5 end

    for i, reel in ipairs(reels) do
        reel.speed = (0.5 + speedBoost) + i * 0.2 
        reel.stopping = false
    end
end

function alignReel(reel)
     local currentPos = reel.pos
     local nextSymbol = math.ceil(currentPos) 
     reel.target = nextSymbol
     
     -- Small shake on stop
     shakeScreen(2)
end

function stopReels()
    if currentState == STATE_SPINNING then
        currentState = STATE_STOPPING
        
        -- Pre-calculate stops to check for anticipation
        -- We won't set the final targets yet, just the timing
        
        -- Standard delay
        local baseDelay = 500 
        
        for i, reel in ipairs(reels) do
            local delay = i * baseDelay
            
            -- Anticipation Logic for Reel 3
            if i == 3 then
                -- Check if Reel 1 and 2 are aligned (approx)
                -- Simplification: If they are stopping nearby or we force them?
                -- Since targets are set inside the timer, we can't know for sure here easily
                -- without refactoring.
                -- Let's Refactor slightly: We trigger R1 stop, then R2.
                -- In R2's callback, we check if R1 and R2 match. If so, we delay R3.
            end
            
            -- OLD LOGIC REPLACED BELOW
        end
        
        -- STOP SEQUENCE
        -- Reel 1
        playdate.timer.performAfterDelay(baseDelay, function()
            reels[1].stopping = true
            alignReel(reels[1])
            SoundManager.play("stop")
        end)
        
        -- Reel 2
        playdate.timer.performAfterDelay(baseDelay * 2, function()
            reels[2].stopping = true
            alignReel(reels[2])
            SoundManager.play("stop")
            
            -- Check for Anticipation (Potential Win?)
            -- Get R1 and R2 potential symbols
            local r1Sym = getSymbolIndexAt(reels[1], 0) -- Center
            local r2Sym = getSymbolIndexAt(reels[2], 0) -- Center
            
            local delayR3 = baseDelay * 3
            
            -- Simple check: if Center match or any likely match
            if r1Sym == r2Sym then
                 -- TENSION!
                 delayR3 = baseDelay * 5 -- Extra delay
                 SoundManager.play("tension")
                 -- Maybe speed up reel 3?
                 reels[3].speed = reels[3].speed * 2
            end
            
            -- Reel 3
            playdate.timer.performAfterDelay(delayR3, function()
                reels[3].stopping = true
                alignReel(reels[3])
                SoundManager.play("stop")
                SoundManager.play("tension_stop") -- Ensure tension cuts off
            end)
        end)
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
            
            -- Tick sound based on speed/position (approximate)
            if math.floor(reel.pos * 10) % 5 == 0 then
                SoundManager.play("tick")
            end
            
            allStopped = false
        end
    end
    
    if currentState == STATE_STOPPING and allStopped then
        checkWin()
    end
end

function startMiniGame()
    currentState = STATE_MINIGAME
    minigameSequence = {}
    minigameIndex = 1
    winMultiplier = 1
    
    -- Generate 4 random directions
    local possible = {playdate.kButtonUp, playdate.kButtonDown, playdate.kButtonLeft, playdate.kButtonRight}
    for i=1, 4 do
        table.insert(minigameSequence, possible[math.random(1, 4)])
    end
end

function updateMiniGame()
    if playdate.buttonJustPressed(minigameSequence[minigameIndex]) then
        -- Correct!
        minigameIndex = minigameIndex + 1
        SoundManager.play("tick") -- Use tick as 'correct' sound for now
        
        if minigameIndex > #minigameSequence then
            -- WIN!
            winMultiplier = 2 -- Double Points!
            SoundManager.play("start") -- Success sound
            castWildMagic()
        end
    elseif playdate.buttonJustPressed(playdate.kButtonA) or 
           playdate.buttonJustPressed(playdate.kButtonB) or
           playdate.buttonJustPressed(playdate.kButtonUp) or
           playdate.buttonJustPressed(playdate.kButtonDown) or
           playdate.buttonJustPressed(playdate.kButtonLeft) or
           playdate.buttonJustPressed(playdate.kButtonRight) then
           
           -- Wrong button pressed (if we got here, it wasn't the correct one)
           -- Simple Shake or Fail sound?
           shakeScreen(2)
    end
end

function drawMiniGame()
    -- Dim background
    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer4x4)
    gfx.fillRect(0, 0, 400, 240)
    
    -- Draw Rune Circle
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(200, 120, 60)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawCircleAtPoint(200, 120, 55)
    
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("TRACE THE RUNE!", 200, 40, kTextAlignment.center)
    
    -- Draw Arrows
    local startX = 200 - (4 * 30) / 2 + 15
    for i, btn in ipairs(minigameSequence) do
        local x = startX + (i-1) * 30
        local y = 120
        local txt = ARROW_ICONS[btn]
        
        if i < minigameIndex then
            -- Completed (Green/Filled)
            gfx.fillCircleAtPoint(x, y, 12)
            gfx.setImageDrawMode(gfx.kDrawModeFillBlack) -- Inverted text
        else
            -- Pending (Outline)
            gfx.drawCircleAtPoint(x, y, 12)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end
        
        -- Draw Arrow Text (Ideally use arrow sprites)
        -- Using simplified text for now: U, D, L, R
        local symbol = "?"
        if txt == "UP" then symbol = "^" end
        if txt == "DOWN" then symbol = "v" end
        if txt == "LEFT" then symbol = "<" end
        if txt == "RIGHT" then symbol = ">" end
        
        gfx.drawTextAligned(symbol, x, y - 7, kTextAlignment.center)
    end
end

function drawTitleScreen()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, 400, 240)
    gfx.setColor(gfx.kColorBlack)
    
    -- Draw a big box
    gfx.drawRect(50, 60, 300, 100)
    gfx.drawRect(55, 65, 290, 90)
    
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.drawTextAligned("* MAGIC SLOTS *", 200, 100, kTextAlignment.center)
    
    -- Pulse "Press A"
    if playdate.getCurrentTimeMilliseconds() % 1000 < 500 then
        gfx.drawTextAligned("Press A to Start", 200, 180, kTextAlignment.center)
    end
end

function drawClassSelect()
    gfx.clear()
    gfx.drawTextAligned("CHOOSE YOUR HERO", 200, 30, kTextAlignment.center)
    
    local classes = {"WARRIOR", "MAGE", "ROGUE"}
    local yStart = 80
    
    -- Simple menu navigation
    -- (We'll implement actual selection logic in update)
    -- Just draw them for now
    gfx.drawTextAligned("A: WARRIOR (High HP, Sword Bonus)", 200, 80, kTextAlignment.center)
    gfx.drawTextAligned("B: MAGE (High MP, Magic Bonus)", 200, 120, kTextAlignment.center)
    gfx.drawTextAligned("UP: ROGUE (Crit Chance)", 200, 160, kTextAlignment.center)
end

function drawRPGInterface()
    -- Ensure clean state for UI
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.setColor(gfx.kColorBlack)

    -- Top Right Sidebar (x > 250)
    local startX = 260
    
    -- Player Stats (Top)
    gfx.setColor(gfx.kColorBlack)
    -- Smaller text if possible? Playdate only has one system font by default.
    -- We can just rely on cleaner layout.
    gfx.drawText("HERO L" .. Player.level, startX, 10)
    gfx.drawText(Player.class, startX, 25) -- Tightened spacing
    
    -- HP Bar (Smaller)
    gfx.setColor(gfx.kColorBlack) -- Ensure color is set before text
    gfx.drawText("HP", startX, 45)
    gfx.drawRect(startX, 60, 100, 6) -- Frame (Smaller width 100, height 6)
    local hpPct = Player.hp / Player.maxHp
    if hpPct < 0 then hpPct = 0 end
    gfx.fillRect(startX, 60, 100 * hpPct, 6)
    
    -- Mana Bar (Smaller)
    gfx.drawText("MP", startX, 70)
    gfx.drawRect(startX, 85, 100, 6) -- Frame (Smaller width 100, height 6)
    local mpPct = mana / MANA_MAX
    if mpPct < 0 then mpPct = 0 end
    gfx.fillRect(startX, 85, 100 * mpPct, 6)
    
    -- Gold
    gfx.drawText("Gold: $" .. Player.gold, startX, 105)
    
    -- Monster Area (Bottom Right)
    if Monster.hp > 0 then
        local mx = 320
        local my = 170
        
        -- Draw Monster Sprite
        local img = monsterImages[Monster.name]
        if img then
            img:drawCentered(mx, my)
        else
            -- Fallback
            gfx.drawRect(mx - 20, my - 20, 40, 40)
        end
        
        -- Monster Name
        gfx.drawTextAligned(Monster.name, mx, my - 45, kTextAlignment.center)
        
        -- Monster HP
        gfx.drawTextAligned("HP " .. Monster.hp, mx, my + 35, kTextAlignment.center)
    end
end

function drawCabinet()
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    
    -- Slot Machine Frame (Left Side)
    -- Left Section width = 240px.
    local bezelX = 10
    local bezelY = 40
    -- Reel Area: 3 reels * 70w + 2 gaps * 5 + margins
    -- 210 + 10 = 220 width content.
    local bezelW = 225
    local bezelH = REEL_H + 20
    
    gfx.drawRoundRect(bezelX, bezelY, bezelW, bezelH, 5)
    
    -- Logo above reels
    gfx.drawTextAligned("* MAGIC SLOTS *", 120, 15, kTextAlignment.center)
    
    -- Divider lines between reels
    local reel1End = REEL_X_START + REEL_W + (REEL_SPACING/2)
    local reel2End = reel1End + REEL_SPACING + REEL_W
    
    gfx.drawLine(reel1End, bezelY, reel1End, bezelY + bezelH)
    gfx.drawLine(reel2End, bezelY, reel2End, bezelY + bezelH)
    
    -- Vertical Divider separating RPG UI at x=240
    gfx.setLineWidth(3)
    gfx.drawLine(240, 0, 240, 240)
end

function drawWinAnimations()
    if #winLinesToDraw > 0 then
        -- Simple Blink Timer
        local blinkSpeed = 500
        if isBigWin then blinkSpeed = 100 end
        local show = (playdate.getCurrentTimeMilliseconds() % blinkSpeed < (blinkSpeed/2))
        
        if show then
             local paylines = {
                {0, 0, 0},   -- 1. Center
                {-1, -1, -1},-- 2. Top
                {1, 1, 1},   -- 3. Bottom
                {-1, 0, 1},  -- 4. Diagonal Top-Left -> Bottom-Right
                {1, 0, -1}   -- 5. Diagonal Bottom-Left -> Top-Right
             }
             
             for _, lineIdx in ipairs(winLinesToDraw) do
                 local offsets = paylines[lineIdx]
                 for reelIdx, rowOffset in ipairs(offsets) do
                     -- Calculate position (Must match drawReels EXACTLY)
                     local x = REEL_X_START + (reelIdx-1) * (REEL_W + REEL_SPACING)
                     -- Y Position fixed: drawReels uses y=50 (see below). 
                     local y = 50 
                     local symY = y + (REEL_H/2) + (rowOffset * SYMBOL_H) - (SYMBOL_H/2)
                     
                     -- Draw Highlight: Black Box + White Symbol
                     -- Removed Border Rect to reduce visual noise/flashing issues
                     -- gfx.setColor(gfx.kColorBlack)
                     -- gfx.setLineWidth(3)
                     -- gfx.drawRect(x + 2, symY + 2, REEL_W - 4, SYMBOL_H - 4)
                     
                     -- Fetch symbol
                     local reel = reels[reelIdx]
                     local symbolIdx = getSymbolIndexAt(reel, rowOffset)
                     local symbolData = SYMBOLS[symbolIdx]
                     
                     -- Draw White Symbol on top
                     -- kDrawModeFillWhite turns black pixels white, ignores transparent
                     -- BUT first we should clear behind it if we want it to pop?
                     -- Let's just draw inverted on top.
                     gfx.setImageDrawMode(gfx.kDrawModeInverted)
                     -- Use x + 10 centering
                     symbolData.img:draw(x + 10, symY)
                     
                     -- RESET MODE IMMEDIATELY
                     gfx.setImageDrawMode(gfx.kDrawModeCopy)
                 end
             end
        end
    end
end

function drawReels()
    -- Draw Cabinet Overlay
    drawCabinet()

    gfx.setColor(gfx.kColorBlack) -- Ensure we draw black lines
    for i, reel in ipairs(reels) do
        local x = REEL_X_START + (i-1) * (REEL_W + REEL_SPACING)
        local y = 50 -- Fixed Y position to match Bezel (40) + Padding
        
        -- Draw 3 Symbols (Top, Center, Bottom)
        for offset = -1, 1 do
            local symbolIdx = getSymbolIndexAt(reel, offset)
            local symbolData = SYMBOLS[symbolIdx]
            
            -- Calculate Y position
            local symY = y + (REEL_H/2) + (offset * SYMBOL_H) - (SYMBOL_H/2)
            
            -- Draw Symbol Image centered (Normal Black on White)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
            symbolData.img:draw(x + 10, symY)
            
            -- Draw dividers (optional) - at bottom of cell
            if offset < 1 then
                gfx.setColor(gfx.kColorBlack)
                gfx.setLineWidth(1)
                gfx.drawLine(x + 5, symY + SYMBOL_H, x + REEL_W - 5, symY + SYMBOL_H)
            end
        end
    end
    
    -- Draw Animations on top
    drawWinAnimations()
end

function playdate.update()
    playdate.timer.updateTimers()
    updateShake()
    gfx.clear()
    
    if currentState == STATE_TITLE then
        drawTitleScreen()
        if playdate.buttonJustPressed(playdate.kButtonA) then
            currentState = STATE_CLASS_SELECT
            SoundManager.play("tick")
        end
        return -- Skip the rest
    end
    
    if currentState == STATE_CLASS_SELECT then
        drawClassSelect()
        if playdate.buttonJustPressed(playdate.kButtonA) then
            Player.class = "WARRIOR"
            Player.maxHp = 150
            Player.hp = 150
            currentState = STATE_IDLE
            SoundManager.play("start")
        elseif playdate.buttonJustPressed(playdate.kButtonB) then
            Player.class = "MAGE"
            Player.maxMp = 150
            Player.mp = 150 -- Start full
            currentState = STATE_IDLE
            SoundManager.play("start")
        elseif playdate.buttonJustPressed(playdate.kButtonUp) then
            Player.class = "ROGUE"
            currentState = STATE_IDLE
            SoundManager.play("start")
        end
        return
    end
    
    -- Handle Input
    local crankChange = playdate.getCrankChange()
    if currentState == STATE_IDLE and math.abs(crankChange) > 10 then
        startSpin()
    end
    
    -- Button to stop (optional, or auto stop?)
    if currentState == STATE_SPINNING and playdate.buttonJustPressed(playdate.kButtonA) then
        stopReels()
    end
    
    -- Cast Spell (B)
    if currentState == STATE_IDLE and mana >= MANA_MAX and playdate.buttonJustPressed(playdate.kButtonB) then
        startMiniGame()
    end
    
    if currentState == STATE_MINIGAME then
        updateMiniGame()
    end
    
    -- Update Logic
    if currentState == STATE_SPINNING or currentState == STATE_STOPPING then
        updateReels()
    end
    
    ParticleSystem.update()
    FloatingText.update()
    
    if currentState == STATE_WIN then
        if playdate.buttonJustPressed(playdate.kButtonA) or math.abs(crankChange) > 5 then
            currentState = STATE_IDLE
            playdate.display.setInverted(false) -- Reset just in case
            isBigWin = false -- Reset Big Win flag
        end
        
        -- Continuous particles for Big Win
        if isBigWin then
            -- Restrict to Left Side (Slots area)
            ParticleSystem.spawn(math.random(0, 250), math.random(0, 240), 2)
        end
    end
    
    -- Draw
    drawReels()
    ParticleSystem.draw()
    
    -- Draw RPG UI LAST
    drawRPGInterface()
    FloatingText.draw()
    
    if currentState == STATE_MINIGAME then
        drawMiniGame()
    end
    
    -- Action Prompt (Bottom Center of Slots)
    if currentState == STATE_IDLE then
        if mana >= MANA_MAX then
             gfx.drawTextAligned("Press B for MAGIC!", 120, 215, kTextAlignment.center)
        else
             gfx.drawTextAligned("Crank to SPIN!", 120, 215, kTextAlignment.center)
        end
    elseif currentState == STATE_SPINNING then
         gfx.drawTextAligned("Press A to STOP", 120, 215, kTextAlignment.center)
    elseif currentState == STATE_WIN then
        gfx.drawTextAligned("WINNER! Press A", 120, 215, kTextAlignment.center)
    end
end
