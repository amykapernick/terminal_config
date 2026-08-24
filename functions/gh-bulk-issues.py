#!/usr/bin/env python3
"""
gh-bulk-issues.py — bulk-create GitHub issues (with native sub-issues, labels,
milestones, and Projects v2 placement) from a markdown file.

Requires: `gh` CLI, authenticated (`gh auth login`). No Python deps beyond stdlib
— everything goes through `gh api` (REST + GraphQL) so it works on old gh versions
that don't have `gh project`.

USAGE
  gh-bulk-issues.py issues.md [--repo owner/repo] [--project 5] [--project-owner name]
                     [--dry-run] [-y/--yes]

  --dry-run   Parse the file and print the plan, make no GitHub calls.
  -y/--yes    Skip the confirmation prompt before creating anything.
  --repo/--project/--project-owner force *every* section in the file to
              that value, overriding any Repo:/Project:/Project-Owner:
              lines. Omit them to let each section use its own.

---------------------------------------------------------------------------
MARKDOWN FORMAT
---------------------------------------------------------------------------
Optional header lines before the first "## " heading or "- " bullet (all
optional, can be overridden by CLI flags):

    Repo: owner/repo
    Project: 5
    Project-Owner: owner

Everything below one of these header blocks belongs to that repo. To bulk-
create across more than one repo in a single file, just start a new header
block later in the file (typically after a blank line) — a fresh "Repo:"
line closes off the previous section (whatever issues/tasks came before
it) and starts a new one:

    Repo: acme/webapp
    Project: 5

    ## Ship dark mode
    ...

    Repo: acme/api
    Project: 3

    ## Add rate limiting
    ...

Each "## " heading starts one issue. Metadata lines directly under the
heading (before body text or a bullet list) — all optional:

    Labels: bug, backend
    Milestone: v1.2
    Assignees: octocat, hubot

Following non-bullet lines, up to the next "## " heading or "- " bullet,
are the issue body.

Top-level "- " bullets under an issue become *sub-issues*, linked to the
parent via GitHub's native sub-issue relationship (so they show up as the
parent's sub-issue progress bar, and as child items when the parent is on
a project board). A sub-issue inherits its parent's labels/milestone
unless it sets its own inline in {...}. An indented line under a bullet
becomes that sub-issue's body:

    - Fix the login redirect {labels: bug, urgent}
      Optional indented body text for the sub-issue.
    - Write regression test {milestone: v1.3}

Full example:

    Repo: acme/webapp
    Project: 5

    ## Ship dark mode
    Labels: enhancement, ui
    Milestone: v2.0
    Add a dark mode toggle to settings and theme the whole app.

    - Add theme toggle to settings page
    - Audit components for hardcoded colors {labels: enhancement, tech-debt}
    - Update docs {milestone: v2.1}

    ## Fix flaky checkout tests
    Labels: bug, tests
    The checkout suite fails intermittently in CI.

---------------------------------------------------------------------------
BASIC TASK LISTS (no headings)
---------------------------------------------------------------------------
You don't need "## " headings at all. A plain top-level "- " bullet becomes
its own issue; an indented bullet under it becomes a subtask, linked the
same way as the sub-issues above. An indented, non-bullet line under a
bullet is that item's body text (same rule at both nesting levels).

Anywhere in a title (heading or bullet) you can also drop in tags instead
of/alongside Labels:/Milestone:/{...}:

    #label            adds a label — repeat for multiple, e.g. #bug #urgent
    @Milestone Name   sets the milestone — runs to the next # or @ (or end
                      of line), so it can contain spaces; put it after any
                      #labels on the same line so it doesn't swallow them

Tags are additive: they supplement (don't replace) any Labels:/Milestone:
set via a metadata line or {...}, and a subtask still inherits its
parent's labels/milestone when it doesn't set its own.

    Repo: acme/webapp

    - Buy groceries #errands
      - Milk
      - Eggs {labels: urgent}
    - Fix the leaky tap #home @Maintenance Q3
      Landlord said to use the guy from last time.
---------------------------------------------------------------------------
"""

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from typing import Optional


HEADING_RE = re.compile(r"^##\s+(.*\S)\s*$")
BULLET_RE = re.compile(r"^-\s+(.*\S)\s*$")
META_RE = re.compile(r"^(Labels|Milestone|Assignees)\s*:\s*(.*)$", re.IGNORECASE)
INLINE_META_RE = re.compile(r"\{([^}]*)\}\s*$")
CONFIG_RE = re.compile(r"^(Repo|Project|Project-Owner)\s*:\s*(.*)$", re.IGNORECASE)
TAG_LABEL_RE = re.compile(r"(?<!\S)#([A-Za-z0-9_-]+)")
TAG_MILESTONE_RE = re.compile(r"(?<!\S)@([^#@\n]+)")


@dataclass
class Item:
    title: str
    labels: list = field(default_factory=list)
    milestone: Optional[str] = None
    assignees: list = field(default_factory=list)
    body: str = ""
    subissues: list = field(default_factory=list)
    # Source line span (0-indexed, end exclusive) — only meaningful on
    # top-level items, used to strip a completed issue out of the source
    # file once it (and all its sub-issues) have been created.
    start_line: Optional[int] = None
    end_line: Optional[int] = None


def parse_inline_meta(text):
    m = INLINE_META_RE.search(text)
    if not m:
        return text.strip(), {}
    title = text[: m.start()].strip()
    meta = {}
    for part in m.group(1).split(";"):
        part = part.strip()
        if not part or ":" not in part:
            continue
        key, val = part.split(":", 1)
        meta[key.strip().lower()] = val.strip()
    return title, meta


def apply_meta_line(item, key, value):
    key = key.lower()
    if key == "labels":
        item.labels = [v.strip() for v in value.split(",") if v.strip()]
    elif key == "milestone":
        item.milestone = value.strip() or None
    elif key == "assignees":
        item.assignees = [v.strip() for v in value.split(",") if v.strip()]


def parse_inline_tags(text):
    """Pull #label and @Milestone Name tags out of a title.

    A milestone tag runs until the next # or @ (or end of line) so it can
    contain spaces — put it after any #labels on the same line.
    """
    milestone = None
    m = TAG_MILESTONE_RE.search(text)
    if m:
        milestone = m.group(1).strip() or None
        text = text[: m.start()] + text[m.end() :]
    labels = TAG_LABEL_RE.findall(text)
    text = TAG_LABEL_RE.sub("", text)
    return re.sub(r"\s+", " ", text).strip(), labels, milestone


def merge_tags(item, tag_labels, tag_milestone):
    """Apply tag-derived labels/milestone without clobbering explicit ones."""
    for label in tag_labels:
        if label not in item.labels:
            item.labels.append(label)
    if item.milestone is None and tag_milestone:
        item.milestone = tag_milestone


def parse_bullet_item(raw_title, inherit_from=None):
    """Build an Item from a bullet's title text ({...} meta + #/@ tags)."""
    title, meta = parse_inline_meta(raw_title)
    title, tag_labels, tag_milestone = parse_inline_tags(title)
    item = Item(
        title=title,
        labels=[v.strip() for v in meta["labels"].split(",")] if "labels" in meta
        else (list(inherit_from.labels) if inherit_from else []),
        milestone=meta.get("milestone", inherit_from.milestone if inherit_from else None),
        assignees=[v.strip() for v in meta["assignees"].split(",")] if "assignees" in meta
        else (list(inherit_from.assignees) if inherit_from else []),
    )
    merge_tags(item, tag_labels, tag_milestone)
    return item


def line_indent(line):
    return len(line) - len(line.lstrip(" \t"))


def parse_bullet_block(lines, i, n, base_indent, inherit_from=None):
    """Parse consecutive bullets more indented than base_indent as sibling
    Items. Each item's own further-indented lines are, in turn, either a
    nested bullet block (recursed into as its sub-issues, any depth) or
    plain body text — so subtasks can themselves have subtasks.
    """
    items = []
    while i < n and lines[i].strip() and line_indent(lines[i]) > base_indent:
        start = i
        indent = line_indent(lines[i])
        stripped = lines[i].strip()
        bm = BULLET_RE.match(stripped)
        if not bm:
            break
        item = parse_bullet_item(bm.group(1), inherit_from=inherit_from)
        i += 1

        body_lines = []
        while i < n and lines[i].strip() and line_indent(lines[i]) > indent:
            deeper = lines[i].strip()
            if BULLET_RE.match(deeper):
                item.subissues, i = parse_bullet_block(lines, i, n, indent, inherit_from=item)
            else:
                mm = META_RE.match(deeper)
                if mm:
                    apply_meta_line(item, mm.group(1), mm.group(2))
                else:
                    body_lines.append(deeper)
                i += 1
        item.body = "\n".join(body_lines).strip()
        item.start_line, item.end_line = start, i
        items.append(item)

    return items, i


def parse_markdown(text):
    """Returns a list of (config, config_lines, issues) sections.

    A Repo:/Project:/Project-Owner: line always belongs to the config of
    the section that follows it. If issues have already been collected
    under the current config, such a line starts a *new* section (flushing
    the old one first) — so a file can bulk-create across multiple repos,
    each with its own Repo:/Project: header, separated by a blank line.

    config_lines is the list of 0-indexed source line numbers the header
    lines came from, so a section whose issues have all been created can
    have its header stripped from the file too.
    """
    sections = []
    config = {}
    config_lines = []
    issues = []

    lines = text.splitlines()
    i = 0
    n = len(lines)

    while i < n:
        hm = HEADING_RE.match(lines[i])
        bm = BULLET_RE.match(lines[i])
        cm = None if hm or bm else CONFIG_RE.match(lines[i].strip())

        if cm:
            if issues:
                sections.append((config, config_lines, issues))
                config = {}
                config_lines = []
                issues = []
            config[cm.group(1).lower().replace("-", "_")] = cm.group(2).strip()
            config_lines.append(i)
            i += 1

        elif hm:
            start = i
            title, tag_labels, tag_milestone = parse_inline_tags(hm.group(1).strip())
            issue = Item(title=title)
            i += 1

            # Metadata block right under the heading.
            while i < n:
                stripped = lines[i].strip()
                mm = META_RE.match(stripped)
                if mm:
                    apply_meta_line(issue, mm.group(1), mm.group(2))
                    i += 1
                    continue
                break
            merge_tags(issue, tag_labels, tag_milestone)

            # Body text, until a bullet, the next heading, or a new config section.
            body_lines = []
            while (
                i < n
                and not HEADING_RE.match(lines[i])
                and not BULLET_RE.match(lines[i])
                and not CONFIG_RE.match(lines[i].strip())
            ):
                body_lines.append(lines[i])
                i += 1
            issue.body = "\n".join(body_lines).strip()

            # Top-level bullets == sub-issues (any depth of further nesting).
            issue.subissues, i = parse_bullet_block(lines, i, n, -1, inherit_from=issue)

            issue.start_line, issue.end_line = start, i
            issues.append(issue)

        elif bm:
            # Plain top-level bullets with no heading: each bullet is its
            # own issue, and a nested bullet under it becomes a subtask
            # (recursively, so a subtask can have its own subtasks).
            new_items, i = parse_bullet_block(lines, i, n, -1)
            issues.extend(new_items)

        else:
            i += 1

    if issues:
        sections.append((config, config_lines, issues))

    return sections


# ---------------------------------------------------------------------------
# gh CLI plumbing
# ---------------------------------------------------------------------------

class GhError(RuntimeError):
    pass


def gh(args, input_json=None, paginate=False):
    cmd = ["gh"] + args
    if paginate:
        cmd.append("--paginate")
    kwargs = dict(capture_output=True, text=True)
    if input_json is not None:
        kwargs["input"] = json.dumps(input_json)
    proc = subprocess.run(cmd, **kwargs)
    if proc.returncode != 0:
        raise GhError(f"`{' '.join(cmd)}` failed:\n{proc.stderr.strip()}")
    out = proc.stdout.strip()
    if not out:
        return None
    # --paginate with multiple pages can concatenate JSON arrays; handle plainly.
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return out


def api(method, path, repo=None, body=None, paginate=False):
    args = ["api", "-X", method, path]
    if body is not None:
        args += ["--input", "-"]
    return gh(args, input_json=body, paginate=paginate)


def graphql(query, **variables):
    args = ["api", "graphql", "-f", f"query={query}"]
    for k, v in variables.items():
        args += ["-f", f"{k}={v}"]
    return gh(args)


class RepoContext:
    def __init__(self, repo):
        self.repo = repo
        self._labels = None
        self._milestones = None

    def existing_labels(self):
        if self._labels is None:
            data = api("GET", f"/repos/{self.repo}/labels?per_page=100", paginate=True) or []
            if isinstance(data, dict):
                data = [data]
            self._labels = {l["name"] for l in data}
        return self._labels

    def ensure_labels(self, names):
        existing = self.existing_labels()
        for name in names:
            if name in existing:
                continue
            api("POST", f"/repos/{self.repo}/labels", body={"name": name, "color": "ededed"})
            existing.add(name)

    def existing_milestones(self):
        if self._milestones is None:
            data = api("GET", f"/repos/{self.repo}/milestones?state=all&per_page=100", paginate=True) or []
            if isinstance(data, dict):
                data = [data]
            self._milestones = {m["title"]: m["number"] for m in data}
        return self._milestones

    def ensure_milestone(self, title):
        if title is None:
            return None
        milestones = self.existing_milestones()
        if title in milestones:
            return milestones[title]
        result = api("POST", f"/repos/{self.repo}/milestones", body={"title": title})
        milestones[title] = result["number"]
        return result["number"]

    def create_issue(self, item):
        self.ensure_labels(item.labels)
        milestone_number = self.ensure_milestone(item.milestone)
        body = {"title": item.title}
        if item.body:
            body["body"] = item.body
        if item.labels:
            body["labels"] = item.labels
        if item.assignees:
            body["assignees"] = item.assignees
        if milestone_number is not None:
            body["milestone"] = milestone_number
        return api("POST", f"/repos/{self.repo}/issues", body=body)

    def link_sub_issue(self, parent_number, sub_issue_db_id):
        api(
            "POST",
            f"/repos/{self.repo}/issues/{parent_number}/sub_issues",
            body={"sub_issue_id": sub_issue_db_id},
        )


PROJECT_ID_QUERY_ORG = """
query($owner: String!, $number: Int!) {
  organization(login: $owner) { projectV2(number: $number) { id } }
}
"""
PROJECT_ID_QUERY_USER = """
query($owner: String!, $number: Int!) {
  user(login: $owner) { projectV2(number: $number) { id } }
}
"""
ADD_ITEM_MUTATION = """
mutation($projectId: ID!, $contentId: ID!) {
  addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) { item { id } }
}
"""


def resolve_project_id(owner, number):
    for query, key in ((PROJECT_ID_QUERY_ORG, "organization"), (PROJECT_ID_QUERY_USER, "user")):
        try:
            result = graphql(query, owner=owner, number=str(number))
        except GhError:
            continue
        node = result.get("data", {}).get(key)
        if node and node.get("projectV2"):
            return node["projectV2"]["id"]
    raise GhError(f"Could not find project #{number} for owner '{owner}' (checked org and user).")


def add_to_project(project_id, content_node_id):
    graphql(ADD_ITEM_MUTATION, projectId=project_id, contentId=content_node_id)


# ---------------------------------------------------------------------------
# Plan printing / execution
# ---------------------------------------------------------------------------

def count_all(items):
    """Total item count across all nesting depths."""
    return sum(1 + count_all(it.subissues) for it in items)


def _print_item(item, depth):
    meta = []
    if item.labels:
        meta.append("labels=" + ",".join(item.labels))
    if item.milestone:
        meta.append(f"milestone={item.milestone}")
    if item.assignees:
        meta.append("assignees=" + ",".join(item.assignees))
    print(f"{'    ' * depth}- {item.title}" + (f"  [{'; '.join(meta)}]" if meta else ""))
    for sub in item.subissues:
        _print_item(sub, depth + 1)


def print_plan(config, issues):
    print(f"Repo:          {config.get('repo', '<none — pass --repo>')}")
    if config.get("project"):
        owner = config.get("project_owner") or config.get("repo", "?").split("/")[0]
        print(f"Project:       #{config['project']} (owner: {owner})")
    total = count_all(issues)
    print(f"Issues:        {len(issues)} top-level, {total - len(issues)} sub-issues (all nesting levels)")
    print()
    for issue in issues:
        _print_item(issue, depth=0)


def run(config, issues, project_id, on_done=None):
    repo = config["repo"]
    ctx = RepoContext(repo)

    def create_recursive(item, parent_number=None, depth=0):
        created = ctx.create_issue(item)
        print(f"{'  ' * depth}created #{created['number']}: {created['title']} ({created['html_url']})")
        if parent_number is not None:
            ctx.link_sub_issue(parent_number, created["id"])
        if project_id:
            add_to_project(project_id, created["node_id"])
        for sub in item.subissues:
            create_recursive(sub, created["number"], depth + 1)

    for issue in issues:
        create_recursive(issue)
        # Only mark done once the whole top-level issue (and every
        # sub-issue under it) has been created without error — a failure
        # partway through leaves it in the file for the next run to retry.
        if on_done:
            on_done(issue)


def strip_done_lines(path, lines, keep):
    """Rewrite `path` to contain only the lines still marked True in `keep`."""
    remaining = [ln for ln, k in zip(lines, keep) if k]
    text = "\n".join(remaining)
    if remaining:
        text += "\n"
    with open(path, "w") as f:
        f.write(text)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("file", help="Markdown file describing the issues")
    parser.add_argument("--repo", help="owner/repo — forces every section to this repo, overriding all 'Repo:' lines in the file")
    parser.add_argument("--project", help="Project number — forces every section to this project, overriding all 'Project:' lines")
    parser.add_argument("--project-owner", help="Org/user that owns the project — overrides all 'Project-Owner:' lines")
    parser.add_argument("--dry-run", action="store_true", help="Print the plan, make no GitHub calls")
    parser.add_argument("-y", "--yes", action="store_true", help="Skip confirmation prompt")
    args = parser.parse_args()

    with open(args.file) as f:
        text = f.read()
    sections = parse_markdown(text)
    file_lines = text.splitlines()

    for config, _, _ in sections:
        if args.repo:
            config["repo"] = args.repo
        if args.project:
            config["project"] = args.project
        if args.project_owner:
            config["project_owner"] = args.project_owner

    if not sections:
        print("No issues found in file.", file=sys.stderr)
        sys.exit(1)

    for config, _, _ in sections:
        if not config.get("repo"):
            print("No repo specified. Add 'Repo: owner/repo' to the file (or a section) or pass --repo.", file=sys.stderr)
            sys.exit(1)

    for n, (config, _, issues) in enumerate(sections):
        if n:
            print("\n" + "-" * 60 + "\n")
        print_plan(config, issues)

    if args.dry_run:
        return

    if not args.yes:
        total = sum(len(issues) for _, _, issues in sections)
        noun = "repo" if len(sections) == 1 else "repos"
        answer = input(
            f"\nProceed and create these {total} issues across {len(sections)} {noun} on GitHub? [y/N] "
        ).strip().lower()
        if answer != "y":
            print("Aborted.")
            return

    # As each top-level issue is successfully created, its lines (and its
    # section's header, once the whole section is done) are stripped from
    # the source file and the file is rewritten immediately — so a script
    # crash or Ctrl-C only loses progress since the last successful issue,
    # and a re-run just picks up wherever it left off.
    keep = [True] * len(file_lines)

    try:
        for config, config_lines, issues in sections:
            project_id = None
            if config.get("project"):
                owner = config.get("project_owner") or config["repo"].split("/")[0]
                project_id = resolve_project_id(owner, config["project"])

            remaining = len(issues)

            def on_done(item, config_lines=config_lines):
                nonlocal remaining
                for idx in range(item.start_line, item.end_line):
                    keep[idx] = False
                remaining -= 1
                if remaining == 0:
                    for idx in config_lines:
                        keep[idx] = False
                strip_done_lines(args.file, file_lines, keep)

            run(config, issues, project_id, on_done=on_done)
    except GhError as e:
        print(f"\nError: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
