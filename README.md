# web key-value-storage

Based on [tarantool](https://www.tarantool.io/)

**API:**

**POST:**
`/kv body: {key: "test", "value": {SOME ARBITRARY JSON}}`

**PUT:**
`kv/{id} body: {"value": {SOME ARBITRARY JSON}}`

**GET:**
`kv/{id}`

**DELETE:**
`kv/{id}`

Also in `server.lua` you can set RPS limit and if you exceed it - you will get 429 request status

To run tests you should run server : 

`tarantool server.lua` 
  
and then run tests: 

`tarantool tests.lua`
