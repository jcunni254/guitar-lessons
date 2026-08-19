#!/usr/bin/env python3
"""Keep the CSP script hash in index.html in sync with the inline script.

The page ships one inline <script>. Pinning it by hash means an injected
script cannot execute, but it also means an edit to that script silently
breaks the booking embed unless the hash is updated. So:

    python3 tools/csp-hash.py --write    # after editing the inline script
    python3 tools/csp-hash.py --check    # run in CI; exits 1 on drift
"""
import base64
import hashlib
import pathlib
import re
import sys

PAGE = pathlib.Path(__file__).resolve().parent.parent / "index.html"
SCRIPT_RE = re.compile(r"<script>(.*?)</script>", re.DOTALL)
HASH_RE = re.compile(r"script-src '([^']*)'")


def current_and_expected(html):
    scripts = SCRIPT_RE.findall(html)
    if len(scripts) != 1:
        sys.exit(f"expected exactly 1 inline <script>, found {len(scripts)}")
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
        return

    if mode == "--write":
        PAGE.write_text(html.replace(f"script-src '{current}'",
                                     f"script-src '{expected}'", 1),
                        encoding="utf-8")
        print(f"CSP script hash updated: {current} -> {expected}")
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
