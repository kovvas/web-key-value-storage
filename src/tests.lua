local json = require('json')
local tap = require('tap')
local httpc = require("http.client")

local check = tap.test('methods-test')
local testsTable = {}
local url = 'http://0.0.0.0:8080/kv'

-- POST request tests
local function postOK()
    local data = {key = '1', value = {planet = 'Earth', city = 'Moscow'}}
    check:is(httpc.post(url, json.encode(data)).status, 200, 'valid POST')
end

local function postMissingKey()
    local data = {key = '', value = {planet = 'Earth', city = 'Moscow'}}
    check:is(httpc.post(url, json.encode(data)).status, 400, 'POST with empty key')
end

local function postLongBody()
    local data = {key = '1', value = {planet = 'Earth'}, extra = {city = 'Moscow'}}
    check:is(httpc.post(url, json.encode(data)).status, 400, 'POST with long body')
end

local function postMissingBody()
    local data = {}
    check:is(httpc.post(url, json.encode(data)).status, 400, 'POST with empty body')
end

local function postKeyExists()
    local data = {key = '3', value = {planet = 'Earth', city = 'Moscow'}}
    check:is(httpc.post(url, json.encode(data)).status, 200, 'valid POST')
    check:is(httpc.post(url, json.encode(data)).status, 409, 'POST with existed key')
end

-- GET request tests
local function getOK()
    local data = {key = '2', value = {planet = 'Earth', city = 'Moscow'}}
    httpc.post(url, json.encode(data))
    local response = httpc.get(string.format('%s/%s', url, data.key))
    check:is(response.status, 200, "valid GET")
    check:is(response.body, json.encode(data), "valid GET's value")
end

local function getNoKey()
    local response = httpc.get(string.format('%s/%s', url, '123'))
    check:is(response.status, 404, "GET with not existing key")
end

-- PUT request tests
local function putOK()
    local data = {value = {planet = 'Earth', city = 'Minsk'}}
    local checkData = {key = '2', value = {planet = 'Earth', city = 'Minsk'}}
    local response = httpc.put(
        string.format('%s/%s', url, '2'), json.encode(data))
    check:is(response.status, 201, "valid after PUT")
    local response = httpc.get(string.format('%s/%s', url, '2'))
    check:is(response.body, json.encode(checkData), "valid after PUT value")
end

local function putBadBody()
    local data = {{planet = 'Earth'}, extra = {city = 'Moscow'}}
    check:is(httpc.put(
        string.format('%s/%s', url, '2'), json.encode(data)).status, 400, "valid PUT's body")
end

local function putNoKey()
    local data = {value = {planet = 'Earth', city = 'Minsk'}}
    check:is(httpc.put(
        string.format('%s/%s', url, '10'), json.encode(data)).status, 404, "PUT not existed key")
end

-- DELETE request tests
local function deleteOK()
    local response = httpc.delete(string.format('%s/%s', url, '2'))
    check:is(response.status, 200, "valid DELETE")
end

local function deleteNoKey()
    local response = httpc.delete(string.format('%s/%s', url, '10'))
    check:is(response.status, 404, "DELETE not existed key")
end

local function cleanUpAfterTests()
    httpc.delete(string.format('%s/%s', url, '1'))
    httpc.delete(string.format('%s/%s', url, '2'))
    httpc.delete(string.format('%s/%s', url, '3'))
end

testsTable.methodTests = {
    postOK,
    postMissingKey,
    postLongBody,
    postMissingBody,
    postKeyExists,

    getOK,
    getNoKey,

    putOK,
    putBadBody,
    putNoKey,
    
    deleteOK,
    deleteNoKey    
}

function runTests()
    for testNumber = 1, #testsTable.methodTests do
        testsTable.methodTests[testNumber]()
    end

    cleanUpAfterTests()
end

runTests()