Powerup = Class{}

function Powerup:init(params)
    self.type = params.type

    self.x = params.x
    self.y = params.y

    self.width, self.height = 16, 16

    self.dy = 30

    --self.isKey = self.type == 10 and true or false
end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end

function Powerup:collides(target)
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 
    return true
end

function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.type + 144],
    self.x, self.y)
end