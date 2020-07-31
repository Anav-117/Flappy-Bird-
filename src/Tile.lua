--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

function Tile:init(x, y, color, variety)
    
    -- board positions
    self.gridX = x
    self.gridY = y

    -- coordinate positions
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety
    
    self.isShiny = false

    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 64)
    --self.psystem:setEmitterLifetime(10)
    self.psystem:setParticleLifetime(0.5, 1)
    self.psystem:setEmissionArea('normal', 8, 8)
    self.psystem:setSizes(0.5, 0.35, 0.25, 0.15)
    self.psystem:setLinearAcceleration(0, 0, 0, 0)
    --self.psystem:start()
end

function Tile:update(dt)
    self.psystem:update(dt)
    if self.psystem:isActive() then
        self.psystem:emit(1)
    end
end

function Tile:render(x, y)
    
    -- draw shadow
    love.graphics.setColor(34/255, 32/255, 52/255, 1)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x + 2, self.y + y + 2)

    -- draw tile itself
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x, self.y + y)

    if self.isShiny then
        love.graphics.setColor(236/255, 245/255, 66/255, 1)
        love.graphics.draw(self.psystem, self.x + x + 16, self.y + y + 16)
    end
end