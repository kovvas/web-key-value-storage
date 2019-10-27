# web-key-value-storage

Based on tarantool

**API:**

**POST:**
`/kv body: {key: "test", "value": {SOME ARBITRARY JSON}}`

**PUT:**
`kv/{id} body: {"value": {SOME ARBITRARY JSON}}`

**GET:**
`kv/{id}`

**DELETE:**
`kv/{id}`
