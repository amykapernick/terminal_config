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

---------------------------------------------------------------------------
MARKDOWN FORMAT
---------------------------------------------------------------------------
Optional header lines before the first "## " heading (all optional, can be
overridden by CLI flags):

    Repo: owner/repo
    Project: 5
    Project-Owner: owner

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


@dataclass
class Item:
    title: str
    labels: list = field(default_factory=list)
    milestone: Optional[str] = None
    assignees: list = field(default_factory=list)
    body: str = ""
    subissues: list = field(default_factory=list)


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


def parse_markdown(text):
    config = {}
    issues = []

    lines = text.splitlines()
    i = 0
    n = len(lines)

    # Header config lines before first heading.
    while i < n and not HEADING_RE.match(lines[i]):
        m = CONFIG_RE.match(lines[i].strip())
        if m:
            config[m.group(1).lower().replace("-", "_")] = m.group(2).strip()
        i += 1

    while i < n:
        m = HEADING_RE.match(lines[i])
        if not m:
            i += 1
            continue
        issue = Item(title=m.group(1).strip())
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

        # Body text, until a bullet or the next heading.
        body_lines = []
        while i < n and not HEADING_RE.match(lines[i]) and not BULLET_RE.match(lines[i]):
            body_lines.append(lines[i])
            i += 1
        issue.body = "\n".join(body_lines).strip()

        # Top-level bullets == sub-issues.
        while i < n and BULLET_RE.match(lines[i]):
            bm = BULLET_RE.match(lines[i])
            title, meta = parse_inline_meta(bm.group(1))
            sub = Item(
                title=title,
                labels=[v.strip() for v in meta["labels"].split(",")] if "labels" in meta else list(issue.labels),
                milestone=meta.get("milestone", issue.milestone),
                assignees=[v.strip() for v in meta["assignees"].split(",")] if "assignees" in meta else list(issue.assignees),
            )
            i += 1
            sub_body_lines = []
            while i < n and lines[i].startswith((" ", "\t")) and lines[i].strip():
                inner = lines[i].strip()
                smm = META_RE.match(inner)
                if smm:
                    apply_meta_line(sub, smm.group(1), smm.group(2))
                else:
                    sub_body_lines.append(inner)
                i += 1
            sub.body = "\n".join(sub_body_lines).strip()
            issue.subissues.append(sub)

        issues.append(issue)

    return config, issues


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

def print_plan(config, issues):
    print(f"Repo:          {config.get('repo', '<none — pass --repo>')}")
    if config.get("project"):
        owner = config.get("project_owner") or config.get("repo", "?").split("/")[0]
        print(f"Project:       #{config['project']} (owner: {owner})")
    print(f"Issues:        {len(issues)} top-level, {sum(len(i.subissues) for i in issues)} sub-issues")
    print()
    for issue in issues:
        meta = []
        if issue.labels:
            meta.append("labels=" + ",".join(issue.labels))
        if issue.milestone:
            meta.append(f"milestone={issue.milestone}")
        if issue.assignees:
            meta.append("assignees=" + ",".join(issue.assignees))
        print(f"- {issue.title}" + (f"  [{'; '.join(meta)}]" if meta else ""))
        for sub in issue.subissues:
            smeta = []
            if sub.labels:
                smeta.append("labels=" + ",".join(sub.labels))
            if sub.milestone:
                smeta.append(f"milestone={sub.milestone}")
            print(f"    - {sub.title}" + (f"  [{'; '.join(smeta)}]" if smeta else ""))


def run(config, issues, project_id):
    repo = config["repo"]
    ctx = RepoContext(repo)

    for issue in issues:
        created = ctx.create_issue(issue)
        print(f"created #{created['number']}: {created['title']} ({created['html_url']})")
        if project_id:
            add_to_project(project_id, created["node_id"])

        for sub in issue.subissues:
            sub_created = ctx.create_issue(sub)
            print(f"  created #{sub_created['number']}: {sub_created['title']} ({sub_created['html_url']})")
            ctx.link_sub_issue(created["number"], sub_created["id"])
            if project_id:
                add_to_project(project_id, sub_created["node_id"])


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("file", help="Markdown file describing the issues")
    parser.add_argument("--repo", help="owner/repo (overrides 'Repo:' in the file)")
    parser.add_argument("--project", help="Project number (overrides 'Project:' in the file)")
    parser.add_argument("--project-owner", help="Org/user that owns the project (overrides 'Project-Owner:')")
    parser.add_argument("--dry-run", action="store_true", help="Print the plan, make no GitHub calls")
    parser.add_argument("-y", "--yes", action="store_true", help="Skip confirmation prompt")
    args = parser.parse_args()

    with open(args.file) as f:
        text = f.read()
    config, issues = parse_markdown(text)

    if args.repo:
        config["repo"] = args.repo
    if args.project:
        config["project"] = args.project
    if args.project_owner:
        config["project_owner"] = args.project_owner

    if not issues:
        print("No issues found in file.", file=sys.stderr)
        sys.exit(1)

    if not config.get("repo"):
        print("No repo specified. Add 'Repo: owner/repo' to the file or pass --repo.", file=sys.stderr)
        sys.exit(1)

    print_plan(config, issues)

    if args.dry_run:
        return

    if not args.yes:
        answer = input("\nProceed and create these on GitHub? [y/N] ").strip().lower()
        if answer != "y":
            print("Aborted.")
            return

    project_id = None
    if config.get("project"):
        owner = config.get("project_owner") or config["repo"].split("/")[0]
        project_id = resolve_project_id(owner, config["project"])

    try:
        run(config, issues, project_id)
    except GhError as e:
        print(f"\nError: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
