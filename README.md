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

To run tests you should run server : 

`tarantool server.lua` 
  
and then run tests: 

`tarantool tests.lua`
