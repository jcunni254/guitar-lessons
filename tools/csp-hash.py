#!/usr/bin/env python3
"""Keep the page's CSP honest.

Two things can silently break the booking embed, and both fail closed:

1. The page ships one inline <script>, pinned in the CSP by hash. Pinning
   means an injected script cannot execute, but it also means editing that
   script breaks the embed unless the hash is updated.
2. The site is served with a real CSP header from render.yaml as well as the
   meta policy in index.html. If the two drift apart, the browser enforces
   the intersection and the result is a blank calendar with no obvious cause.

    python3 tools/csp-hash.py --write    # after editing the inline script
    python3 tools/csp-hash.py --check    # run in CI; exits 1 on drift
"""
import base64
import hashlib
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PAGE = ROOT / "index.html"
RENDER = ROOT / "render.yaml"
COMMENT_RE = re.compile(r"<!--.*?-->", re.DOTALL)
SCRIPT_RE = re.compile(r"<script>(.*?)</script>", re.DOTALL)
HASH_RE = re.compile(r"script-src '([^']*)'")
META_POLICY_RE = re.compile(r'content="(default-src[^"]*)"')
HEADER_POLICY_RE = re.compile(r'value: "(default-src[^"]*)"')

# The only directive the header carries that the meta policy cannot express.
HEADER_ONLY = "frame-ancestors 'none'; "


def check_policies_match():
    """The meta policy and the render.yaml header policy must agree."""
    if not RENDER.exists():
        return  # Pages-only deploy; nothing to cross-check.

    meta = META_POLICY_RE.search(PAGE.read_text(encoding="utf-8"))
    header = HEADER_POLICY_RE.search(RENDER.read_text(encoding="utf-8"))
    if not meta or not header:
        sys.exit("could not find both the meta policy and the render.yaml "
                 "header policy to compare")

    if header.group(1).replace(HEADER_ONLY, "") != meta.group(1):
        sys.exit(
            "CSP drift between index.html and render.yaml.\n"
            f"  meta:   {meta.group(1)}\n"
            f"  header: {header.group(1)}\n"
            "The browser enforces both, so the calendar would break in ways "
            "that are hard to trace. Make them identical apart from "
            f"\"{HEADER_ONLY.strip()}\"."
        )
    print("meta and header policies agree")


def current_and_expected(html):
    # Comments are stripped first: the CSP documentation block mentions the
    # literal tag, and matching that would hash the wrong span of the file
    # and quietly publish a hash that blocks the real script.
    scripts = SCRIPT_RE.findall(COMMENT_RE.sub("", html))
    if len(scripts) != 1:
        sys.exit(f"expected exactly 1 inline <script>, found {len(scripts)}")
    if "Cal(" not in scripts[0]:
        sys.exit("the matched inline script is not the Cal.com bootstrap; "
                 "refusing to write a hash for the wrong content")
    digest = hashlib.sha256(scripts[0].encode("utf-8")).digest()
    expected = "sha256-" + base64.b64encode(digest).decode("ascii")
    found = HASH_RE.search(html)
    if not found:
        sys.exit("no script-src hash found in the CSP meta tag")
    return found.group(1), expected


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "--check"
    html = PAGE.read_text(encoding="utf-8")
    current, expected = current_and_expected(html)

    if current == expected:
        print(f"CSP script hash is current: {expected}")
        check_policies_match()
        return

    if mode == "--write":
        PAGE.write_text(html.replace(f"script-src '{current}'",
                                     f"script-src '{expected}'", 1),
                        encoding="utf-8")
        # The header policy embeds the same hash, so update it too.
        if RENDER.exists():
            RENDER.write_text(
                RENDER.read_text(encoding="utf-8").replace(
                    f"script-src '{current}'", f"script-src '{expected}'", 1),
                encoding="utf-8")
        print(f"CSP script hash updated: {current} -> {expected}")
        check_policies_match()
        return

    sys.exit(
        f"CSP script hash is stale.\n"
        f"  in page:  {current}\n"
        f"  expected: {expected}\n"
        f"The inline script changed without updating the CSP, which would "
        f"stop the booking embed from loading.\n"
        f"Fix with: python3 tools/csp-hash.py --write"
    )


if __name__ == "__main__":
    main()
