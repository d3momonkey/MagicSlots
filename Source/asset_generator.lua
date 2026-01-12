local gfx = playdate.graphics

AssetGenerator = {}

function AssetGenerator.generateAll()
    local images = {}
    
    -- 1. FIREBALL (was GEM)
    local fireball = gfx.image.new(50, 50)
    gfx.lockFocus(fireball)
        gfx.setColor(gfx.kColorBlack)
        -- Core
        gfx.fillCircleAtPoint(25, 28, 12)
        -- Flames moving up
        gfx.fillPolygon(15, 25, 35, 25, 25, 5)
        
        gfx.setColor(gfx.kColorWhite)
        -- Inner heat
        gfx.fillCircleAtPoint(25, 30, 5)
        -- Flame details
        gfx.setLineWidth(2)
        gfx.drawArc(25, 28, 12, 0, 180) -- Bottom round
        gfx.drawLine(15, 25, 25, 5)
        gfx.drawLine(35, 25, 25, 5)
    gfx.unlockFocus()
    images["FIREBALL"] = fireball

    -- 2. SWORD (was 7)
    local sword = gfx.image.new(50, 50)
    gfx.lockFocus(sword)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(3)
        -- Blade
        gfx.fillPolygon(22, 40, 28, 40, 28, 10, 25, 5, 22, 10)
        -- Hilt
        gfx.drawLine(15, 40, 35, 40) -- Crossguard
        gfx.drawLine(25, 40, 25, 48) -- Handle
        gfx.fillCircleAtPoint(25, 48, 2) -- Pommel
        
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(25, 10, 25, 38) -- Fuller
    gfx.unlockFocus()
    images["SWORD"] = sword
    
    -- 3. SHIELD (was BELL)
    local shield = gfx.image.new(50, 50)
    gfx.lockFocus(shield)
        gfx.setColor(gfx.kColorBlack)
        -- Heater shield shape
        gfx.fillPolygon(10, 10, 40, 10, 40, 30, 25, 45, 10, 30)
        
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(2)
        gfx.drawPolygon(10, 10, 40, 10, 40, 30, 25, 45, 10, 30) -- Outline
        -- Cross pattern
        gfx.drawLine(25, 12, 25, 42)
        gfx.drawLine(12, 20, 38, 20)
    gfx.unlockFocus()
    images["SHIELD"] = shield
    
    -- 4. COIN (was BAR)
    local coin = gfx.image.new(50, 50)
    gfx.lockFocus(coin)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(25, 25, 18)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(25, 25, 16) -- Rim
        gfx.drawText("$", 20, 18)
    gfx.unlockFocus()
    images["COIN"] = coin

    -- 5. POTION (was CHERRY)
    local potion = gfx.image.new(50, 50)
    gfx.lockFocus(potion)
        gfx.setColor(gfx.kColorBlack)
        -- Flask body
        gfx.fillCircleAtPoint(25, 32, 12)
        -- Neck
        gfx.fillRect(20, 10, 10, 15)
        -- Cork
        gfx.fillRect(18, 8, 14, 4)
        
        gfx.setColor(gfx.kColorWhite)
        -- Shine
        gfx.drawCircleAtPoint(25, 32, 10)
        -- Liquid level
        gfx.fillCircleAtPoint(25, 32, 8) -- Liquid
        gfx.setColor(gfx.kColorBlack)
        gfx.drawText("+", 21, 25) -- Cross
    gfx.unlockFocus()
    images["POTION"] = potion
    
    -- 6. WILD (Spell Book)
    local wild = gfx.image.new(50, 50)
    gfx.lockFocus(wild)
        gfx.setColor(gfx.kColorBlack)
        -- Book Cover / Outline
        -- Left page rect
        gfx.fillPolygon(5, 10, 25, 15, 25, 40, 5, 35)
        -- Right page rect
        gfx.fillPolygon(25, 15, 45, 10, 45, 35, 25, 40)
        
        gfx.setColor(gfx.kColorWhite)
        -- Page details (lines of text)
        gfx.setLineWidth(1)
        -- Left page lines
        gfx.drawLine(10, 18, 20, 20)
        gfx.drawLine(8, 22, 22, 25)
        gfx.drawLine(7, 26, 23, 30)
        -- Right page lines
        gfx.drawLine(28, 20, 40, 18)
        gfx.drawLine(30, 25, 42, 22)
        gfx.drawLine(28, 30, 43, 26)
        
        -- Spine
        gfx.drawLine(25, 15, 25, 40)
        
        -- "W" Rune on top? Or just leave as book. 
        -- Let's put a big "W" on the pages to signify WILD clearly.
        gfx.setLineWidth(2)
        gfx.drawLine(15, 15, 18, 25) -- Left stroke
        gfx.drawLine(18, 25, 25, 18) -- Mid up
        gfx.drawLine(25, 18, 32, 25) -- Mid down
        gfx.drawLine(32, 25, 35, 15) -- Right stroke
    gfx.unlockFocus()
    images["WILD"] = wild
    
    return images
end

function AssetGenerator.generateMonsters()
    local images = {}
    
    -- 1. Slime
    local slime = gfx.image.new(80, 60)
    gfx.lockFocus(slime)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillEllipseInRect(10, 20, 60, 40) -- Body
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(25, 35, 5) -- Eye L
        gfx.fillCircleAtPoint(55, 35, 5) -- Eye R
        gfx.drawEllipseInRect(10, 20, 60, 40) -- Outline
    gfx.unlockFocus()
    images["Slime"] = slime
    
    -- 2. Goblin
    local goblin = gfx.image.new(80, 60)
    gfx.lockFocus(goblin)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(40, 30, 20) -- Head
        gfx.fillPolygon(20, 30, 10, 10, 30, 20) -- Ear L
        gfx.fillPolygon(60, 30, 70, 10, 50, 20) -- Ear R
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(35, 30, 3) -- Eye
        gfx.fillCircleAtPoint(45, 30, 3) -- Eye
        gfx.drawLine(35, 40, 45, 40) -- Mouth
    gfx.unlockFocus()
    images["Goblin"] = goblin
    
    -- 3. Skeleton
    local skeleton = gfx.image.new(80, 60)
    gfx.lockFocus(skeleton)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(40, 25, 18) -- Skull
        gfx.fillRect(35, 45, 10, 15) -- Spine/Ribs
        gfx.drawLine(25, 50, 55, 50) -- Rib
        gfx.drawLine(28, 55, 52, 55) -- Rib
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(35, 25, 4) -- Eye Socket
        gfx.fillCircleAtPoint(45, 25, 4) -- Eye Socket
        gfx.drawLine(35, 35, 45, 35) -- Teeth
    gfx.unlockFocus()
    images["Skeleton"] = skeleton
    
    -- 4. Orc
    local orc = gfx.image.new(80, 60)
    gfx.lockFocus(orc)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(20, 10, 40, 40) -- Block Head
        gfx.fillPolygon(20, 40, 10, 20, 20, 20) -- Ear L
        gfx.fillPolygon(60, 40, 70, 20, 60, 20) -- Ear R
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(30, 25, 35, 28) -- Angry Eye L
        gfx.drawLine(50, 25, 45, 28) -- Angry Eye R
        gfx.fillPolygon(25, 45, 30, 35, 35, 45) -- Tusk
        gfx.fillPolygon(45, 45, 50, 35, 55, 45) -- Tusk
    gfx.unlockFocus()
    images["Orc"] = orc
    
    -- 5. Dragon
    local dragon = gfx.image.new(80, 60)
    gfx.lockFocus(dragon)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillPolygon(20, 50, 40, 20, 70, 30, 60, 50) -- Head/Neck
        gfx.fillPolygon(10, 20, 30, 30, 20, 50) -- Wing?
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(50, 30, 3) -- Eye
        gfx.drawLine(60, 50, 75, 45) -- Fire breath start
    gfx.unlockFocus()
    images["Dragon"] = dragon
    
    return images
end
