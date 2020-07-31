--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    local key_block = math.random(5)
    local blockHeight = 4
    local level_width = width
    local end_flag = false
    local key_frame = math.random(4)
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1 and x > 1 and x < LEVEL_WIDTH-2 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 and x < LEVEL_WIDTH-2 and x ~= LEVEL_WIDTH - 10 then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block
            if math.random(10) == 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                if key_block > 0 then
                                    key_block = key_block - 1
                                elseif key_block == 0 then
                                    key_block = -1
                                    print(key_frame)
                                    local key = GameObject {
                                        texture = 'key',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = key_frame,
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            end_flag = true
                                            gSounds['pickup']:play()
                                            player.has_key = true
                                            print(player.has_key)
                                            print(player)
                                        end
                                    }

                                    Timer.tween(0.6, {
                                        [key] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, key)

                                    goto exit
                                end
                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.6, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                ::exit::

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
    end
    --table.insert(objects,
                -- jump block
                lock = GameObject {
                    texture = 'key',
                    x = (LEVEL_WIDTH - 10) * TILE_SIZE,
                    y = (blockHeight - 1) * TILE_SIZE,
                    width = 16,
                    height = 16,

                    -- make it a random variant
                    frame = key_frame + 4,
                    collidable = true,
                    hit = false,
                    solid = true,

                    onCollide = function()
                        --player.dy = 6
                        --print(player.has_key)
                        if end_flag then
                            end_flag = false
                            collidable = false
                            consumable = true
                            solid = false
                            for i = 1, 3 do
                                table.insert(objects,
                                    GameObject {        
                                        texture = 'flag',
                                        x = (LEVEL_WIDTH-2) * TILE_SIZE,
                                        y = (blockHeight - 2 + i) * TILE_SIZE,
                                        width = 16,
                                        height = 16,

                                        -- make it a random variant
                                        frame = (i-1) * 18 + 1,
                                        consumable =true,
                                        hit = false,
                                        solid = false,
                                        
                                        onConsume = function(player)
                                            end_level(player)
                                        end
                                    }
                                )
                                table.insert(objects,
                                    GameObject {        
                                        texture = 'flag',
                                        x = (LEVEL_WIDTH-2) * TILE_SIZE + TILE_SIZE/2,
                                        y = (blockHeight - 2 + i) * TILE_SIZE,
                                        width = 16,
                                        height = 16,

                                        -- make it a random variant
                                        frame = (i-1) * 18 + 2,
                                        consumable =true,
                                        hit = false,
                                        solid = false,
                                        onConsume = function(player)
                                            end_level(player)
                                        end
                                    }
                                )
                            end
                            table.insert(objects,
                                GameObject {        
                                    texture = 'flag',
                                    x = (LEVEL_WIDTH-2) * TILE_SIZE + TILE_SIZE/2,
                                    y = ((blockHeight - 1) * TILE_SIZE) + 3,
                                    width = 16,
                                    height = 16,

                                    -- make it a random variant
                                    frame = 15,
                                    consumable =true,
                                    hit = false,
                                    solid = false,
                                    onConsume = function(player)
                                        end_level(player)
                                    end
                                }
                            )
                            table.insert(objects,
                                GameObject {        
                                    texture = 'flag',
                                    x = ((LEVEL_WIDTH-2) * TILE_SIZE) + (TILE_SIZE),
                                    y = ((blockHeight - 1) * TILE_SIZE) + 3,
                                    width = 16,
                                    height = 16,

                                    -- make it a random variant
                                    frame = 16,
                                    consumable =true,
                                    hit = false,
                                    solid = false,
                                    onConsume = function(player)
                                        end_level(player)
                                    end
                                }
                            )
                        table.remove(objects, lock_number)
                        end
                    end
                }
                table.insert(objects,lock)
                lock_number = #objects

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end

function end_level(player)
    LEVEL_WIDTH = LEVEL_WIDTH + 20
    print(LEVEL_WIDTH)
    key_block = math.random(5)
    gStateMachine:change('play', {score = player.score})
end
