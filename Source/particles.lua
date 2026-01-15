local gfx = playdate.graphics

ParticleSystem = {}

local particles = {}

-- Spawns a burst of particles at x,y
function ParticleSystem.spawn(x, y, count)
    for i=1, count do
        local p = {
            x = x,
            y = y,
            vx = math.random(-30, 30) / 10,   -- Random Horizontal velocity
            vy = math.random(-50, -20) / 10,  -- Upward burst
            gravity = 0.2,
            life = math.random(30, 60),       -- Frames to live
            size = math.random(2, 4)
        }
        table.insert(particles, p)
    end
end

function ParticleSystem.update()
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        p.vy = p.vy + p.gravity -- Gravity
        p.life = p.life - 1
        
        if p.life <= 0 or p.y > 240 then
            table.remove(particles, i)
        end
    end
end

function ParticleSystem.draw()
    gfx.setColor(gfx.kColorBlack)
    for _, p in ipairs(particles) do
        if p.life > 10 then
             -- Draw solid square/star
            gfx.fillRect(p.x, p.y, p.size, p.size)
        else
            -- Flicker out near end of life
            if p.life % 2 == 0 then
                gfx.drawRect(p.x, p.y, p.size, p.size)
            end
        end
    end
end
