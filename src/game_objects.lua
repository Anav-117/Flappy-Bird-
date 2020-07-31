--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GAME_OBJECT_DEFS = {
    ['switch'] = {
        type = 'switch',
        texture = 'switches',
        frame = 2,
        width = 16,
        height = 16,
        solid = false,
        defaultState = 'unpressed',
        states = {
            ['unpressed'] = {
                frame = 2
            },
            ['pressed'] = {
                frame = 1
            }
        }
    },
    ['pots'] = {
        -- TODO
        type = 'pots',
        texture = 'pots',
        frame = 0,
        width = 16,
        height = 16,
        solid = false,
        defaultState = 'unbroken',
        states = {
            ['unbroken'] = {
                frame = 1
            },
            ['broken'] = {
                frame = 7
            }
        }
    },
    ['heart'] = {
        type = 'heart',
        texture = 'hearts',
        frame = 5,
        width = 8,
        height = 8,
        scaleX = 0.5,
        scaleY = 0.5,
        solid = false,
        defaultState = 'floating',
        states = {
            ['floating'] = {
                frame = 5,
                width = 8,
                height = 8
            },
            ['null'] = {
                frame = 5,
                width = 0,
                height = 0,
                scaleX = 0,
                scaleY = 0
            }
        }
    }
}