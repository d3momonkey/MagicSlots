-- RPG Data Structures

-- Player
Player = {
    class = "WARRIOR", -- Default
    hp = 100,
    maxHp = 100,
    mp = 0,
    maxMp = 100,
    gold = 0,
    level = 1,
    xp = 0,
    nextLevelXp = 100,
    block = 0 -- Damage mitigation for next turn
}

function Player.reset()
    Player.hp = Player.maxHp
    Player.mp = 0
    Player.block = 0
end

function Player.gainXp(amount)
    Player.xp = Player.xp + amount
    if Player.xp >= Player.nextLevelXp then
        Player.level = Player.level + 1
        Player.xp = Player.xp - Player.nextLevelXp
        Player.nextLevelXp = math.floor(Player.nextLevelXp * 1.5)
        Player.maxHp = Player.maxHp + 20
        Player.hp = Player.maxHp -- Heal on level up
        print("LEVEL UP! Level " .. Player.level)
    end
end

-- Monster
Monster = {
    name = "Slime",
    hp = 50,
    maxHp = 50,
    damage = 5,
    level = 1
}

function Monster.spawn(level)
    Monster.level = level
    
    local types = {
        {name="Slime", hpBase=50, dmg=5},
        {name="Goblin", hpBase=80, dmg=8},
        {name="Skeleton", hpBase=100, dmg=10},
        {name="Orc", hpBase=150, dmg=15},
        {name="Dragon", hpBase=500, dmg=25}
    }
    
    -- Pick type based on level roughly
    local idx = math.min(math.ceil(level / 2), #types)
    local t = types[idx]
    
    -- Scale stats
    Monster.name = t.name
    Monster.maxHp = t.hpBase + (level * 10)
    Monster.hp = Monster.maxHp
    Monster.damage = t.dmg + level
    
    print("A wild " .. Monster.name .. " appears! HP: " .. Monster.hp)
end

function Monster.takeDamage(amount)
    Monster.hp = Monster.hp - amount
    if Monster.hp <= 0 then
        Monster.hp = 0
        return true -- Dead
    end
    return false
end
