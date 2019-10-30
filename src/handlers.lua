local json = require('json')
local log = require('log')
local helpers = require('helpers')

local handlers = {}

-- POST handler
handlers.postHandler = function(req)
    local status, body = pcall(req.json, req)

    -- checking for request be json type
    if (status == false) then
        return helpers.messageHelper(req, "ERROR", 400, "request is not json type")
    end

    local key, data = body['key'], body['value']

    -- check for errors
    local checkResult = helpers.checkRequestDataHelper(req, "POST", key, body)
    if (checkResult.status ~= "OK") then
        return checkResult.response
    end

    -- request is valid, so check for duplicate key
    if (table.getn(box.space.kv_storage:select{key}) ~= 0) then
        return helpers.messageHelper(req, "ERROR", 409, "key already exists")
    end

    -- request is valid and key is new, so insert
    box.space.kv_storage:insert{key, body['value']}
    return helpers.messageHelper(req, "OK", 200, "POST successful")
end

-- DELETE handler
local function deleteHandler(req)
    local key = req:stash('key')

    -- check for valid key
    local checkResult = helpers.checkRequestDataHelper(req, "DELETE", key, body)
    if (checkResult.status ~= "OK") then
        return checkResult.response
    end

    -- check if key exists
    if (table.getn(box.space.kv_storage:select{key}) == 0) then
        return helpers.messageHelper(req, "ERROR", 404, "no such key")
    end

    -- key is valid and exists, so delete
    box.space.kv_storage:delete{key}
    return helpers.messageHelper(req, "OK", 200, "DELETE successful")
end

-- GET handler
local function getHandler(req)
    local key = req:stash('key')

    -- check for valid key
    local checkResult = helpers.checkRequestDataHelper(req, "GET", key, body)
    if (checkResult.status ~= "OK") then
        return checkResult.response
    end
    
    local data = box.space.kv_storage:select{key}

    if (table.getn(data) == 0) then
        return helpers.messageHelper(req, "ERROR", 404, "no such key")
    end

    local response = req:render{json = {key = data[1][1], value = data[1][2]}}
    response.status = 200
    log.info("OK! 200: GET successful")
    return response
end

-- PUT handler
local function putHandler(req)
    local status, body = pcall(req.json, req)

    -- checking for request be json type
    if (status == false) then
        return helpers.messageHelper(req, "ERROR", 400, "request is not json type")
    end

    local key = req:stash('key')

    -- check for errors
    print(body)
    local checkResult = helpers.checkRequestDataHelper(req, "PUT", key, body)
    if (checkResult.status ~= "OK") then
        return checkResult.response
    end

    -- request is valid, so check if key exists
    if (table.getn(box.space.kv_storage:select{key}) == 0) then
        return helpers.messageHelper(req, "ERROR", 404, "no such key")
    end

    -- request is valid and key exists, so update
    box.space.kv_storage:update({key}, {{'=', 2, body.value}})
    return helpers.messageHelper(req, "OK", 201, "PUT successful")
end

-- change requests handler
handlers.changeHandler = function(req)
    if req.method == 'GET' then
        return getHandler(req)
    end
    if req.method == 'PUT' then
        return putHandler(req)
    end
    if req.method == 'DELETE' then
        return deleteHandler(req)
    end
    return helpers.messageHelper(req, "ERROR", 400, "Bad request")
end

return handlers