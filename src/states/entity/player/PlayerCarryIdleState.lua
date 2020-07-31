--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerCarryIdleState = Class{__includes = EntityIdleState}

function PlayerCarryIdleState:enter(params)
    -- render offset for spaced character sprite
    self.entity.offsetY = 5
    self.entity.offsetX = 0
    self.entity:changeAnimation('carry-idle-' .. self.entity.direction)    
end

function PlayerCarryIdleState:update(dt)
    EntityIdleState.update(self, dt)
end

function PlayerCarryIdleState:update(dt)
    if love.keyboard.isDown('left') or love.keyboard.isDown('right') or
       love.keyboard.isDown('up') or love.keyboard.isDown('down') then
        self.entity:changeState('carry-walk')
    end

    if love.keyboard.wasPressed('space') then
        self.entity:changeState('throw-pot')
    end
end