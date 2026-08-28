# Prompt Template: CAS / Optimistic Locking

```
Generate a Compare-And-Swap (CAS) update method for [entity].

Table: [table_name]
Fields: [list fields]
CAS condition: UPDATE [table] SET ... WHERE id = ? AND version = ?

Requirements:
- Return boolean indicating success/failure
- If failed due to version mismatch, return clear error
- Increment version on success
- Use [R2DBC / JDBC] inside a transaction
- Include a test that simulates two concurrent updates
  and asserts exactly one succeeds

Output the repository method, service method, and test.
```
