local json = require('json')
local log = require('log')

local helpers = {}

-- helper to get length of lua's table
helpers.checkTableLength = function(dataTable)
    local count = 0
    for _ in pairs(dataTable) do count = count + 1 end
    return count
end

-- helper to process messages
helpers.messageHelper = function(req, messageType, status, text)
    local message = req:render{json = {info = text}}
    message.status = status
    log.info("%s! %d: %s", messageType, status, text)
    return message
end

-- helper to check is key and data valid
helpers.checkRequestDataHelper = function(req, requestType, key, body)
    local checkResult = {}
    checkResult.status = "OK"

    if (requestType == "POST") then
        if (helpers.checkTableLength(body) ~= 2) then
            checkResult.status = "ERROR"
            checkResult.response = helpers.messageHelper(req, "ERROR", 400, "invalid body")
            return checkResult
        end

        if (key == nil or key == '') then
            checkResult.status = "ERROR"
            checkResult.response = helpers.messageHelper(req, "ERROR", 400, "missing key")
            return checkResult
        end

        if (body == nil) then
            checkResult.status = "ERROR"
            checkResult.response = helpers.messageHelper(req, "ERROR", 400, "missing value")
            return checkResult
        end
    end

    if (requestType == "PUT") then
        if (helpers.checkTableLength(body) ~= 1) then
            checkResult.status = "ERROR"
            checkResult.response = helpers.messageHelper(req, "ERROR", 400, "invalid body")
            return checkResult
        end

        if (body == nil) then
            checkResult.status = "ERROR"
            checkResult.response = helpers.messageHelper(req, "ERROR", 400, "missing value")
            return checkResult
        end
    end

    if (requestType == "DELETE" or requestType == "GET") then
        if (key == nil or key == '') then
            checkResult.status = "ERROR"
            checkResult.response = helpers.messageHelper(req, "ERROR", 400, "missing key")
            return checkResult
        end
    end

    return checkResult
end

return helpers