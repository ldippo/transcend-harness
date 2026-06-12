# api-contract-audit — API contract review

**What:** Compares the service's actual routes/handlers against its OpenAPI (or
gRPC) contract: flags breaking changes (removed/renamed fields, narrowed types,
changed status codes), undocumented endpoints, and request/response schema drift.
For FastAPI, leans on the generated `openapi.json`; for Go, on the declared
routes plus any committed spec.

**When to use:** Before merging any change to routes, handlers, DTOs/response
models, or serialization.

**Wiring when selected:**
- Adds a line to `CLAUDE.md` → "Specialized workflows".
- Adds a checklist step to `.claude/rules/quality-gates.md`: run
  `api-contract-audit` on endpoint/schema changes.
- Drops a thin pointer skill at `.claude/skills/api-contract-audit/SKILL.md`
  documenting invocation. (Replace the pointer with the real skill/plugin when
  available.)

**Invocation:** `/api-contract-audit` against the current diff, or a named
router/handler package.
