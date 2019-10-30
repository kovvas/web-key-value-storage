#!/usr/bin/env tarantool
local json = require('json')
local log = require('log')

-- Database config
box.cfg {
    -- port = 8080,
    listen = 3331,
    background = false,
    log_format = 'plain',
    log = 'myApp.log',
    pid_file = 'myApp.pid',
    strip_core = false
}

-- Create kv_storage database
box.once('schema', function()
    box.schema.create_space('kv_storage')
    box.space.kv_storage:create_index('primary',
        { type = 'hash', parts = {1, 'string'}})
end)

-- helper to get length of lua's table
local function checkTableLength(dataTable)
    local count = 0
    for _ in pairs(dataTable) do count = count + 1 end
    return count
end

-- helper to process messages
local function messageHelper(req, messageType, status, text)
    local responce = req:render{json = {info = text}}
    responce.status = status
    log.info("%s! %d: %s", messageType, status, text)
    return responce
end

-- POST handler
local function postHandler(req)
    local status, body = pcall(req.json, req)

    -- checking for request be json type
    if (status == false) then
        return messageHelper(req, "ERROR", 400, "request is not json type")
    end

    local key, data = body['key'], body['value']

    checkRequestDataHelper(key, data, body)

    if (type(key) ~= 'string') or (type(data) ~= 'table') then
        return messageHelper(req, "ERROR", 400, "invalid type of key/value")
    end

    if (key == nil) then
        return messageHelper(req, "ERROR", 400, "missing key")
    end

    if (body == nil) then
        return messageHelper(req, "ERROR", 400, "missing value")
    end

    -- request is valid, so check for duplicate key
    if table.getn(box.space.kv_storage:select{key}) ~= 0 then
        return messageHelper(req, "ERROR", 409, "key already exists")
    end

    -- request is valid and key is new, so insert
    box.space.kv_storage:insert{key, body['value']}
    return messageHelper(req, "OK", 200, "POST successful")
end

-- DELETE handler
local function deleteHandler(req)
    local key = req:stash('key')

    -- check for valid key
    if (type(key) ~= 'string') then
        return messageHelper(req, "ERROR", 400, "invalid type of key")
    end

    if (key == nil) then
        return messageHelper(req, "ERROR", 400, "missing key")
    end

    -- check if key exists
    if table.getn(box.space.kv_storage:select{key}) == 0 then
        return messageHelper(req, "ERROR", 404, "no such key")
    end

    -- key is valid and exists, so delete
    box.space.kv_storage:delete{key}
    return messageHelper(req, "OK", 200, "DELETE successful")
end

-- GET handler
local function getHandler(req)
    local key = req:stash('key')

    -- check for valid key
    if (type(key) ~= 'string') then
        return messageHelper(req, "ERROR", 400, "invalid type of key")
    end

    if (key == nil) then
        return messageHelper(req, "ERROR", 400, "missing key")
    end
    
    local data = box.space.kv_storage:select{key}

    if table.getn(data) == 0 then
        return messageHelper(req, "ERROR", 404, "no such key")
    end

    local response = req:render{json = {key = data[1][1], value = data[1][2]}}
    response.status = 200
    log.info("OK! 200: GET successful")
    return response
end

-- PUT handler
local function putHandler(req)
    local status, body = pcall(req.json, req)

    -- checking for valid request
    if (status == false) then
        return messageHelper(req, "ERROR", 400, "invalid request")
    end

    if (checkTableLength(body) ~= 2) then
        return messageHelper(req, "ERROR", 400, "invalid body")
    end

    local key, data = body['key'], body['value']

    if (type(key) ~= 'string') or (type(data) ~= 'table') then
        return messageHelper(req, "ERROR", 400, "invalid type of key/value")
    end

    if (key == nil) then
        return messageHelper(req, "ERROR", 400, "missing key")
    end

    if (body == nil) then
        return messageHelper(req, "ERROR", 400, "missing value")
    end

    -- check if key exists
    if table.getn(box.space.kv_storage:select{key}) == 0 then
        return messageHelper(req, "ERROR", 404, "no such key")
    end

    -- request is valid and key exists, so update
    box.space.kv_storage:update({key}, {{'=', 2, data}})
    return messageHelper(req, "OK", 201, "PUT successful")
end

-- change requests handler
local function changeHandler(req)
    if req.method == 'GET' then
        return getHandler(req)
    end
    if req.method == 'PUT' then
        return putHandler(req)
    end
    if req.method == 'DELETE' then
        return deleteHandler(req)
    end
    return messageHelper(req, "ERROR", 400, "Bad request")
    -- Handle ERROR?
end

-- Create server instance
local server = require('http.server').new('127.0.0.1', 8888)

-- Server's methods
server:route({path = '/kv', method = 'POST'}, postHandler)
server:route({path = '/kv/:key'}, changeHandler)

server:start()