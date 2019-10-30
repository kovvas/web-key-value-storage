#!/usr/bin/env tarantool
local handlers = require('handlers')

-- Database config
box.cfg {
    log_format = 'plain',
    log = 'server.log',
}

-- Create kv_storage database
box.once('schema', function()
    box.schema.create_space('kv_storage')
    box.space.kv_storage:create_index('primary',
        { type = 'hash', parts = {1, 'string'}})
end)

-- Create server instance
local server = require('http.server').new('0.0.0.0', 8080)

-- Server's methods
server:route({path = '/kv', method = 'POST'}, handlers.postHandler)
server:route({path = '/kv/:key'}, handlers.changeHandler)

server:start()