#!/usr/bin/env sh
# transcend delivery-pipeline issue store helper. POSIX sh; logic in python3.
# Copied verbatim into .claude/scripts/transcend/pipeline/ — keep byte-identical
# to the core source (the golden test enforces this). No per-project templating.
#
# The committed issue store is the only durable state of the pipeline:
#   .claude/issues/<NNNN>-<slug>.md   one file per issue (frontmatter = source of truth)
#   .claude/roadmap.md                a generated projection (never hand-edit)
#
# Subcommands:
#   next                      print the first ready issue whose deps are all done
#   list <status>             list issues with a status (proposed|ready|in-progress|blocked|done)
#   claim <id>                ready->in-progress, single-flight (refuses if another is in-progress)
#   done <id>                 ->done
#   block <id> "<reason>"     ->blocked, appends the reason to the issue body
#   approve <id>              proposed->ready
#   roadmap                   regenerate roadmap.md from the issue files
#   new <kind> <slug> --title "..." [--milestone "..."] [--depends-on "NNNN,NNNN"] [--discovered-by NNNN]
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/../lib/common.sh"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PY="$(transcend_python)"
[ -z "$PY" ] && { echo "issues.sh: python3 is required" 1>&2; exit 1; }
TRANSCEND_PROJECT="$PROJECT_DIR" "$PY" - "$@" <<'PYEOF'
import os, sys, re, datetime

PROJECT = os.environ["TRANSCEND_PROJECT"]
ISSUES = os.path.join(PROJECT, ".claude", "issues")
ROADMAP = os.path.join(PROJECT, ".claude", "roadmap.md")
LOCK = os.path.join(ISSUES, ".lock")
KEYS = ["id", "title", "status", "milestone", "kind", "depends_on", "discovered_by", "updated"]
STATUSES = ["proposed", "ready", "in-progress", "blocked", "done"]
KINDS = ["feature", "bug", "gap", "enhancement"]


def die(msg):
    sys.stderr.write("issues.sh: " + msg + "\n")
    sys.exit(1)


def now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse(path):
    text = open(path, encoding="utf-8").read()
    fm, body = {}, text
    if text.startswith("---\n"):
        end = text.find("\n---", 4)
        if end != -1:
            block = text[4:end]
            body = text[end + 4:]
            if body.startswith("\n"):
                body = body[1:]
            for line in block.splitlines():
                if not line.strip() or ":" not in line:
                    continue
                k, v = line.split(":", 1)
                k, v = k.strip(), v.strip()
                if k == "depends_on":
                    inner = v.strip().lstrip("[").rstrip("]").strip()
                    fm[k] = [x.strip() for x in inner.split(",") if x.strip()] if inner else []
                else:
                    fm[k] = v
    fm.setdefault("depends_on", [])
    return fm, body


def serialize(fm, body):
    out = ["---"]
    for k in KEYS:
        if k not in fm:
            continue
        if k == "depends_on":
            out.append("depends_on: [" + ", ".join(fm[k]) + "]")
        else:
            out.append("%s: %s" % (k, fm[k]))
    out.append("---")
    return "\n".join(out) + "\n" + body


def issue_files():
    if not os.path.isdir(ISSUES):
        return []
    fs = [f for f in os.listdir(ISSUES) if re.match(r"^\d{4}-.*\.md$", f)]
    return sorted(os.path.join(ISSUES, f) for f in fs)


def load_all():
    out = []
    for p in issue_files():
        fm, body = parse(p)
        out.append((p, fm, body))
    return out


def find(issue_id):
    for p, fm, body in load_all():
        if fm.get("id") == issue_id:
            return p, fm, body
    die("no issue with id %s" % issue_id)


def save(path, fm, body):
    fm["updated"] = now()
    open(path, "w", encoding="utf-8").write(serialize(fm, body))


def cmd_new(args):
    if len(args) < 2:
        die("usage: new <kind> <slug> --title \"...\" [--milestone ...] [--discovered-by NNNN]")
    kind, slug = args[0], args[1]
    if kind not in KINDS:
        die("kind must be one of %s" % "|".join(KINDS))
    opts, rest = {}, args[2:]
    i = 0
    while i < len(rest):
        if rest[i].startswith("--") and i + 1 < len(rest):
            opts[rest[i][2:]] = rest[i + 1]
            i += 2
        else:
            i += 1
    title = opts.get("title", slug.replace("-", " "))
    deps = opts.get("depends-on", "")
    dep_list = [d.strip() for d in deps.split(",") if d.strip()] if deps else []
    nums = [int(re.match(r"^(\d{4})-", os.path.basename(p)).group(1)) for p, _, _ in load_all()]
    nid = "%04d" % ((max(nums) + 1) if nums else 1)
    fm = {
        "id": nid, "title": '"%s"' % title.strip('"'),
        "status": "proposed", "milestone": '"%s"' % opts.get("milestone", "Backlog"),
        "kind": kind, "depends_on": dep_list,
        "discovered_by": opts.get("discovered-by", "0000"), "updated": now(),
    }
    body = ("## Context / Goal\n\n_To be filled in._\n\n"
            "## Acceptance criteria\n\n- [ ] _define_\n\n"
            "## Notes\n\n")
    os.makedirs(ISSUES, exist_ok=True)
    path = os.path.join(ISSUES, "%s-%s.md" % (nid, slug))
    open(path, "w", encoding="utf-8").write(serialize(fm, body))
    sys.stdout.write("%s %s\n" % (nid, os.path.relpath(path, PROJECT)))


def deps_done(fm, by_id):
    for d in fm.get("depends_on", []):
        dep = by_id.get(d)
        if not dep or dep[1].get("status") != "done":
            return False
    return True


def cmd_next(_):
    items = load_all()
    by_id = {fm.get("id"): (p, fm, body) for p, fm, body in items}
    for p, fm, body in items:
        if fm.get("status") == "ready" and deps_done(fm, by_id):
            sys.stdout.write("%s %s\n" % (fm.get("id"), os.path.relpath(p, PROJECT)))
            return
    # nothing ready
    sys.exit(0)


def cmd_list(args):
    if not args or args[0] not in STATUSES:
        die("usage: list <%s>" % "|".join(STATUSES))
    want = args[0]
    for p, fm, body in load_all():
        if fm.get("status") == want:
            sys.stdout.write("%s %s\n" % (fm.get("id"), fm.get("title", "").strip('"')))


def cmd_claim(args):
    if not args:
        die("usage: claim <id>")
    target = args[0]
    try:
        os.mkdir(LOCK)  # atomic single-flight guard
    except FileExistsError:
        die("another issues.sh operation holds the lock (%s); one loop at a time" % LOCK)
    try:
        for p, fm, body in load_all():
            st = fm.get("status")
            if st == "in-progress" and fm.get("id") != target:
                die("issue %s is already in-progress — finish it before claiming %s" % (fm.get("id"), target))
        p, fm, body = find(target)
        if fm.get("status") == "in-progress":
            sys.stdout.write("%s already in-progress (resuming)\n" % target)
            return
        if fm.get("status") != "ready":
            die("issue %s is %s, not ready" % (target, fm.get("status")))
        fm["status"] = "in-progress"
        save(p, fm, body)
        sys.stdout.write("claimed %s\n" % target)
    finally:
        try:
            os.rmdir(LOCK)
        except OSError:
            pass


def transition(target, frm, to):
    p, fm, body = find(target)
    if fm.get("status") not in frm:
        die("issue %s is %s; expected one of %s" % (target, fm.get("status"), "|".join(frm)))
    fm["status"] = to
    save(p, fm, body)
    return p, fm, body


def cmd_done(args):
    if not args:
        die("usage: done <id>")
    transition(args[0], ["in-progress"], "done")
    sys.stdout.write("done %s\n" % args[0])


def cmd_block(args):
    if not args:
        die("usage: block <id> \"<reason>\"")
    reason = args[1] if len(args) > 1 else "unspecified"
    p, fm, body = find(args[0])
    fm["status"] = "blocked"
    body = body.rstrip() + "\n\n**Blocked (%s):** %s\n" % (now(), reason)
    save(p, fm, body)
    sys.stdout.write("blocked %s\n" % args[0])


def cmd_approve(args):
    if not args:
        die("usage: approve <id>")
    transition(args[0], ["proposed"], "ready")
    sys.stdout.write("approved %s -> ready\n" % args[0])


MARK = {"done": "[x]", "in-progress": "[~]", "blocked": "[!]", "ready": "[ ]"}


def cmd_roadmap(_):
    items = load_all()
    lines = ["# Roadmap", ""]
    milestones = []
    proposed = []
    for p, fm, body in items:
        if fm.get("status") == "proposed":
            proposed.append(fm)
        else:
            ms = fm.get("milestone", '"Backlog"').strip('"')
            if ms not in milestones:
                milestones.append(ms)
    for ms in milestones:
        lines.append("## Milestone: %s" % ms)
        for p, fm, body in items:
            if fm.get("status") == "proposed":
                continue
            if fm.get("milestone", '"Backlog"').strip('"') != ms:
                continue
            lines.append("- %s %s %s (status: %s)" % (
                MARK.get(fm.get("status"), "[ ]"), fm.get("id"),
                fm.get("title", "").strip('"'), fm.get("status")))
        lines.append("")
    if proposed:
        lines.append("## Proposed (await approval)")
        for fm in proposed:
            lines.append("- [?] %s %s (kind: %s, discovered_by: %s)" % (
                fm.get("id"), fm.get("title", "").strip('"'),
                fm.get("kind", "feature"), fm.get("discovered_by", "0000")))
        lines.append("")
    open(ROADMAP, "w", encoding="utf-8").write("\n".join(lines).rstrip() + "\n")
    sys.stdout.write("roadmap regenerated (%d issues)\n" % len(items))


CMDS = {
    "new": cmd_new, "next": cmd_next, "list": cmd_list, "claim": cmd_claim,
    "done": cmd_done, "block": cmd_block, "approve": cmd_approve, "roadmap": cmd_roadmap,
}

argv = sys.argv[1:]
if not argv or argv[0] not in CMDS:
    die("usage: issues.sh <%s> ..." % "|".join(CMDS))
CMDS[argv[0]](argv[1:])
PYEOF
