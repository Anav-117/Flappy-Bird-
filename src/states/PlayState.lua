--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level

    self.recoverPoints = 5000

    -- give ball random starting velocity
    for k, ball in pairs(self.ball) do 
        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)
    end

    self.powerup = {}

    self.collisionCounter = {0, math.random(5, 10)}

    self.flagKey = false
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    for k, ball in pairs(self.ball) do 
        ball:update(dt)
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - ball.height
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        for j, ball in pairs(self.ball) do
        -- only check collision if we're in play
        if brick.inPlay and ball:collides(brick) then

            -- add to score
            self.score = self.score + (brick.tier * 200 + brick.color * 25)

            -- trigger the brick's hit function, which removes it from play
            if self.flagKey then
                brick:hit(self.flagKey)
            else 
                brick:hit()
            end

            self.collisionCounter[1] = self.collisionCounter[1] + 1

            if self.collisionCounter[1] >= self.collisionCounter[2] then
                table.insert(self.powerup, Powerup({
                    type = self.flagKey and math.random(9) or math.min(10, math.random(50)),
                    x = brick.x + brick.width / 2,
                    y = brick.y + brick.height
                }))
                self.collisionCounter = {0, math.random(5, 10)}
            end

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                self.paddle:change_size('grow')

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if ball.x + 2 < brick.x and ball.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                ball.dx = -ball.dx
                ball.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                ball.dx = -ball.dx
                ball.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif ball.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                ball.dy = -ball.dy
                ball.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                ball.dy = -ball.dy
                ball.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(ball.dy) < 150 then
                ball.dy = ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end
    end

    for k, powerup in pairs(self.powerup) do
        powerup:update(dt)
    end

    for k, powerup in pairs(self.powerup) do
        if powerup:collides(self.paddle) then
            if powerup.type == 10 then
                gSounds['key']:play()
            else
                gSounds['powerup']:play()
            end
            
            if powerup.type == 1 then
                self.paddle:change_size('shrink')
            elseif powerup.type == 2 then
                self.paddle:change_size('grow')
            elseif powerup.type == 3 then
                self.health = math.min(3, self.health + 1)
            elseif powerup.type == 4 then
                self.health = math.max(0, self.health - 1)
            elseif powerup.type == 5 then 
                for k, ball in pairs(self.ball) do
                    ball.dy = ball.dy * 2
                    ball.dx = ball.dx * 2
                end
            elseif powerup.type == 6 then
                for k, ball in pairs(self.ball) do
                    ball.dy = ball.dy / 2
                    ball.dx = ball.dx / 2
                end
            elseif powerup.type == 7 then
                for k, ball in pairs(self.ball) do
                    ball.sx = math.max(0.5, ball.sx / 2)
                    ball.sy = math.max(0.5, ball.sy / 2) 
                    ball.width = math.max(4, ball.width / 2) 
                    ball.height = math.max(4, ball.height / 2)
                end
            elseif powerup.type == 8 then
                for k, ball in pairs(self.ball) do
                    ball.sx = math.min(2, ball.sx * 2)
                    ball.sy = math.min(2, ball.sy * 2)
                    ball.width = math.min(16, ball.width * 2) 
                    ball.height = math.min(16, ball.height * 2)
                end
            elseif powerup.type == 9 then
                BallY = self.ball[1].y
                BallX = self.ball[1].x
                BalldY = self.ball[1].dy
                BalldX = self.ball[1].dx
                table.insert(self.ball, Ball(self.ball[1].skin))
                table.insert(self.ball, Ball(self.ball[1].skin))
                table.insert(self.ball, Ball(self.ball[1].skin))
                for k, ball in pairs(self.ball) do
                    ball.x = BallX
                    ball.y = BallY
                    ball.dy = BalldY >= BalldX and BalldY or math.random(-50, 50)
                    ball.dx = BalldX > BalldY and BalldX or math.random(-50, 50)
                end
            elseif powerup.type == 10 then
                self.flagKey = true
            end
            table.remove(self.powerup, k)
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    for k, ball in pairs(self.ball) do 
        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.ball, k)
            if #self.ball == 0 then
                self.health = self.health - 1
                gSounds['hurt']:play()
                self.paddle:change_size('shrink')

                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints
                    })
                end
            end
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    for k, ball in pairs(self.ball) do 
        ball:render()
    end

    for k, powerup in pairs(self.powerup) do
        powerup:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    if self.flagKey then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][154] ,VIRTUAL_WIDTH / 2 + 85, 2, 0, 0.85, 0.85)
    end

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end