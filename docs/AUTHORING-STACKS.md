# Authoring a stack profile

A stack profile maps detection signals to concrete defaults: which pillar
options get pre-selected, which commands fill the `{vars}` in fragments, and
which catalog entries are recommended. Profiles contain NO templates.

## 1. Write `core/stacks/<id>.yaml`

Follow `core/stacks/_schema.yaml`. Model on `node-ts-react.yaml` (frontend) or
`python-fastapi.yaml` / `go-service.yaml` (services). Requirements:

- `id` matches the filename stem; it is what the detector emits.
- Every `vars` key in the schema must be present, even if `""` (the generator
  substitutes them blindly into fragments). `pkg_run` is the optional
  env-runner prefix (`"uv run"`, `"poetry run"`) for ecosystems where commands
  run inside a managed environment.
- `src_globs`/`test_globs` feed rule `paths:` frontmatter — they decide when
  rules auto-load, so keep them tight (no bare `**/*`).
- `pillar_defaults` must name existing option ids from each
  `core/pillars/<pillar>/pillar.yaml`.
- `catalog_recommend` ids must exist in `core/catalog/catalog.yaml` — a stack
  with no relevant entries gets an empty (skipped) catalog question, which is
  fine, but check whether an existing entry applies before leaving it empty.

## 2. Add detection

1. **Signal probe** — `core/detectors/signals.<lang>.sh` (new file per
   language, reused across that language's profiles). POSIX sh, read-only,
   prints `key=value` lines. Cheap substring greps over manifests
   (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`...) — no parsers,
   no network, no toolchain invocation. Resolve the package manager from
   lockfiles here.
2. **Scoring** — in `core/detectors/detect.sh`: source the probe, read its
   signals via `sig`, compute an integer 0–100 score (strong = 90, plausible =
   60–70, absent = 0), add the profile to the candidate list in the python
   emitter, and extend the pick-highest chain. Keep tie-breaks stable and
   document them in the comment.
3. **Signals into JSON** — add the new `key=value`s to the emitted `signals`
   object; catalog `triggers` match against these keys.

## 3. Test it

Add scenarios to `tests/test-detect.sh`: one strong-signal fixture, one
weak-signal fixture, and (if the language can coexist with others) a polyglot
fixture asserting the tie-break. Run `sh tests/test-detect.sh`.

## 4. Sanity-check generation

Run the interview against a scratch project of the new stack (see the dry-run
procedure in the roadmap/handoffs): detection confidence, batch A wording,
command-var reconciliation (`has_*_script`-style signals must exist for any
command the profile assumes), and that every fragment placeholder resolves.
