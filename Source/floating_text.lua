local gfx = playdate.graphics

FloatingText = {}
local texts = {}

function FloatingText.spawn(x, y, text, color)
    local t = {
        x = x,
        y = y,
        text = text,
        color = color or gfx.kColorBlack,
        life = 90, -- Increased from 60 to 90 (3 seconds)
        vy = -0.5 -- Slower float up
    }
    table.insert(texts, t)
end

function FloatingText.update()
    for i = #texts, 1, -1 do
        local t = texts[i]
        t.y = t.y + t.vy
        t.life = t.life - 1
        
        if t.life <= 0 then
            table.remove(texts, i)
        end
    end
end

function FloatingText.draw()
    for _, t in ipairs(texts) do
        -- Ensure we draw in Black
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.setColor(gfx.kColorBlack)
        
        -- Drawing text directly
        gfx.drawTextAligned(t.text, t.x, t.y, kTextAlignment.center)
    end
end
