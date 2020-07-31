--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerThrowPotState = Class{__includes = BaseState}

function PlayerThrowPotState:init(player, dungeon)
    self.player = player
    self.dungeon = dungeon

    self.pot = self.player.carrying
    self.pot.thrown = true
    
    self.throwX = self.player.x
    self.throwY = self.player.y 

    self.player.carrying = nil

    -- render offset for spaced character sprite
    self.player.offsetY = 5
    self.player.offsetX = 0

    local direction = self.player.direction
    if direction == 'up' then
        self.dx = 0
        self.dy = -75
    elseif direction == 'down' then
        self.dx = 0
        self.dy = 75
    elseif direction == 'right' then
        self.dx = 75
        self.dy = 0
    elseif direction == 'left' then
        self.dx = -75
        self.dy = 0
    else
        self.dx = 0
        self.dy = 0
    end
    
    self.player:changeAnimation('throw-pot-' .. self.player.direction)
end

function PlayerThrowPotState:enter(params)
        self.player.currentAnimation:refresh()
end

function PlayerThrowPotState:update(dt)
    if self.player.currentAnimation.timesPlayed > 0 then
        self.player:changeAnimation('idle-' .. self.player.direction)
    end

    for k, entity in pairs(self.dungeon.currentRoom.entities) do
        if entity:collides(self.pot) then
            entity:damage(1)
            gSounds['hit-enemy']:play()
            self.pot.state = 'broken'
        end
    end

    if (self.pot.x > ((self.dungeon.currentRoom.width - 1) * TILE_SIZE ) or self.pot.x < 2 * TILE_SIZE) and self.pot.dx ~= 0 then
        self.pot.state = 'broken' 
    end
    if (self.pot.y > ((self.dungeon.currentRoom.height - 1) * TILE_SIZE ) or self.pot.y < 2 * TILE_SIZE) and self.pot.dy ~= 0 then
        self.pot.state = 'broken'
    end

    if math.abs(self.pot.x - self.throwX) > (4*TILE_SIZE) or math.abs(self.pot.y - self.throwY) > (4*TILE_SIZE) or self.pot.state == 'broken' then 
            gSounds['pot-break']:play()
            self.pot.state = 'broken'
            self.player:changeState('idle')
    else
        self.pot.x = self.pot.x + self.dx * dt
        self.pot.y = self.pot.y + self.dy * dt
    end
end

function PlayerThrowPotState:render()
    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x - self.player.offsetX), math.floor(self.player.y - self.player.offsetY))
end