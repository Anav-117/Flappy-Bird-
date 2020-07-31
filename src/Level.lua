--[[
    GD50
    Angry Birds

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Level = Class{}

function Level:init()
    -- create a new "world" (where physics take place), with no x gravity
    -- and 30 units of Y gravity (for downward force)
    self.world = love.physics.newWorld(0, 300)

    self.collided = false
    self.count = 0

    -- bodies we will destroy after the world update cycle; destroying these in the
    -- actual collision callbacks can cause stack overflow and other errors
    self.destroyedBodies = {}

    -- define collision callbacks for our world; the World object expects four,
    -- one for different stages of any given collision
    function beginContact(a, b, coll)
        local types = {}
        types[a:getUserData()] = true
        types[b:getUserData()] = true

        -- if we collided between both an alien and an obstacle...
        if types['Obstacle'] and types['Player'] then
            self.collided = true

            -- destroy the obstacle if player's combined velocity is high enough
            if a:getUserData() == 'Obstacle' then
                local velX, velY = b:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, a:getBody())
                end
            else
                local velX, velY = a:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, b:getBody())
                end
            end
        end

        -- if we collided between an obstacle and an alien, as by debris falling...
        if types['Obstacle'] and types['Alien'] then

            -- destroy the alien if falling debris is falling fast enough
            if a:getUserData() == 'Obstacle' then
                local velX, velY = a:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, b:getBody())
                end
            else
                local velX, velY = b:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, a:getBody())
                end
            end
        end

        -- if we collided between the player and the alien...
        if types['Player'] and types['Alien'] then
            self.collided = true

            -- destroy the alien if player is traveling fast enough
            if a:getUserData() == 'Player' then
                local velX, velY = a:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, b:getBody())
                end
            else
                local velX, velY = b:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, a:getBody())
                end
            end
        end

        -- if we hit the ground, play a bounce sound
        if types['Player'] and types['Ground'] then
            gSounds['bounce']:stop()
            gSounds['bounce']:play()
        end
    end

    -- the remaining three functions here are sample definitions, but we are not
    -- implementing any functionality with them in this demo; use-case specific
    function endContact(a, b, coll)
        
    end

    function preSolve(a, b, coll)

    end

    function postSolve(a, b, coll, normalImpulse, tangentImpulse)

    end

    -- register just-defined functions as collision callbacks for world
    self.world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    -- shows alien before being launched and its trajectory arrow
    self.launchMarker = {AlienLaunchMarker(self.world)}

    -- aliens in our scene
    self.aliens = {}

    -- obstacles guarding aliens that we can destroy
    self.obstacles = {}

    -- simple edge shape to represent collision for ground
    self.edgeShape = love.physics.newEdgeShape(0, 0, VIRTUAL_WIDTH * 3, 0)

    -- spawn an alien to try and destroy
    table.insert(self.aliens, Alien(self.world, 'square', VIRTUAL_WIDTH - 80, VIRTUAL_HEIGHT - TILE_SIZE - ALIEN_SIZE / 2, 'Alien'))

    -- spawn a few obstacles
    table.insert(self.obstacles, Obstacle(self.world, 'vertical',
        VIRTUAL_WIDTH - 120, VIRTUAL_HEIGHT - 35 - 110 / 2))
    table.insert(self.obstacles, Obstacle(self.world, 'vertical',
        VIRTUAL_WIDTH - 35, VIRTUAL_HEIGHT - 35 - 110 / 2))
    table.insert(self.obstacles, Obstacle(self.world, 'horizontal',
        VIRTUAL_WIDTH - 80, VIRTUAL_HEIGHT - 35 - 110 - 35 / 2))

    -- ground data
    self.groundBody = love.physics.newBody(self.world, -VIRTUAL_WIDTH, VIRTUAL_HEIGHT - 35, 'static')
    self.groundFixture = love.physics.newFixture(self.groundBody, self.edgeShape)
    self.groundFixture:setFriction(0.5)
    self.groundFixture:setUserData('Ground')

    -- background graphics
    self.background = Background()
end

function Level:update(dt)
    -- update launch marker, which shows trajectory
    for i = 1, #self.launchMarker do 
        self.launchMarker[i]:update(dt)
    end

    --print (self.launchMarker[1].split)
    if self.launchMarker[1].split == 1  and (not self.collided) then 
        table.insert(self.launchMarker, AlienLaunchMarker(self.world))
        table.insert(self.launchMarker, AlienLaunchMarker(self.world))
        print(self.launchMarker[1].alien.body:getX())

        local VelX, VelY = self.launchMarker[1].alien.body:getLinearVelocity() 

        self.launchMarker[2].alien = Alien(self.world, 'round', self.launchMarker[1].alien.body:getX(), self.launchMarker[1].alien.body:getY(), 'Player')
        self.launchMarker[3].alien = Alien(self.world, 'round', self.launchMarker[1].alien.body:getX(), self.launchMarker[1].alien.body:getY(), 'Player')

        self.launchMarker[2].alien.body:setLinearVelocity(VelX, VelY + 50)
        self.launchMarker[2].alien.body:applyForce(0, 1000)
        self.launchMarker[3].alien.body:setLinearVelocity(VelX, VelY - 50)
        self.launchMarker[3].alien.body:applyForce(0, -1000)

        self.launchMarker[2].launched = true
        self.launchMarker[3].launched = true

        self.launchMarker[1].split = -1
    end

    -- Box2D world update code; resolves collisions and processes callbacks
    self.world:update(dt)

    -- destroy all bodies we calculated to destroy during the update call
    for k, body in pairs(self.destroyedBodies) do
        if not body:isDestroyed() then 
            body:destroy()
        end
    end

    -- reset destroyed bodies to empty table for next update phase
    self.destroyedBodies = {}

    -- remove all destroyed obstacles from level
    for i = #self.obstacles, 1, -1 do
        if self.obstacles[i].body:isDestroyed() then
            table.remove(self.obstacles, i)

            -- play random wood sound effect
            local soundNum = math.random(5)
            gSounds['break' .. tostring(soundNum)]:stop()
            gSounds['break' .. tostring(soundNum)]:play()
        end
    end

    -- remove all destroyed aliens from level
    for i = #self.aliens, 1, -1 do
        if self.aliens[i].body:isDestroyed() then
            table.remove(self.aliens, i)
            gSounds['kill']:stop()
            gSounds['kill']:play()
        end
    end

    for i = 1, #self.launchMarker do  
        -- replace launch marker if original alien stopped moving
        if self.launchMarker[i].launched then
            local xPos, yPos = self.launchMarker[i].alien.body:getPosition()
            local xVel, yVel = self.launchMarker[i].alien.body:getLinearVelocity()
            
            -- if we fired our alien to the left or it's almost done rolling, respawn
            if (xPos < 0 or (math.abs(xVel) + math.abs(yVel) < 1.5)) then
                if self.count == 2 then
                    for i = 1, #self.launchMarker do
                        self.launchMarker[i].alien.body:destroy()
                        self.launchMarker[i] = AlienLaunchMarker(self.world)
                    end
                    self.collided = false
                    self.count = 0
                    -- re-initialize level if we have no more aliens
                    if #self.aliens == 0 then
                        gStateMachine:change('start')
                    end
                else
                    self.count = self.count + 1
                end    
            end
        end
    end
end

function Level:render()
    -- render ground tiles across full scrollable width of the screen
    for x = -VIRTUAL_WIDTH, VIRTUAL_WIDTH * 2, 35 do
        love.graphics.draw(gTextures['tiles'], gFrames['tiles'][12], x, VIRTUAL_HEIGHT - 35)
    end

    for i = 1, #self.launchMarker do
        self.launchMarker[i]:render()
    end

    for k, alien in pairs(self.aliens) do
        alien:render()
    end

    for k, obstacle in pairs(self.obstacles) do
        obstacle:render()
    end

    for i = 1, #self.launchMarker do
        -- render instruction text if we haven't launched bird
        if not self.launchMarker[i].launched then
            love.graphics.setFont(gFonts['medium'])
            love.graphics.setColor(0, 0, 0, 255)
            love.graphics.printf('Click and drag circular alien to shoot!',
                0, 64, VIRTUAL_WIDTH, 'center')
            love.graphics.setColor(255, 255, 255, 255)
        end
    end
    -- render victory text if all aliens are dead
    if #self.aliens == 0 then
        love.graphics.setFont(gFonts['huge'])
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.printf('VICTORY', 0, VIRTUAL_HEIGHT / 2 - 32, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(255, 255, 255, 255)
    end
end