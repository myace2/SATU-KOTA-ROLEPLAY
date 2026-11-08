#!/usr/bin/env python3
'''
NSR HUD Ultimate — Automated Static & Architectural Validation Suite
File: tests/validate_resource.py
Run with: python3 tests/validate_resource.py
'''
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def fail(msg):
    print(f"[FAIL] {msg}")
    sys.exit(1)

def ok(msg):
    print(f"[PASS] {msg}")

def test_manifest_files():
    manifest_path = os.path.join(ROOT, "fxmanifest.lua")
    if not os.path.isfile(manifest_path):
        fail("fxmanifest.lua is missing")
    with open(manifest_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Extract all quoted file paths inside fxmanifest.lua
    candidates = re.findall(r"'([^']+\.(?:lua|html|css|js|svg))'", content)
    if len(candidates) < 40:
        fail(f"Expected >= 40 file references in fxmanifest.lua, found {len(candidates)}")

    for rel in candidates:
        full = os.path.join(ROOT, rel)
        if not os.path.isfile(full):
            fail(f"Manifest references missing file: {rel}")
        if os.path.getsize(full) == 0:
            fail(f"Manifest references empty file: {rel}")
    ok(f"Manifest Integrity: All {len(candidates)} referenced files exist and are non-empty.")

def strip_lua_comments_and_strings(src):
    # Remove block comments --[[ ... ]]
    src = re.sub(r"--\[\[[\s\S]*?\]\]", "", src)
    # Remove single-line comments --...
    src = re.sub(r"--[^\n]*", "", src)
    # Remove multiline strings [[ ... ]]
    src = re.sub(r"\[\[[\s\S]*?\]\]", "''", src)
    # Remove single and double quoted strings
    src = re.sub(r"'(?:\\.|[^'\\])*'", "''", src)
    src = re.sub(r'"(?:\\.|[^"\\])*"', '""', src)
    return src

def test_lua_syntax_and_balance():
    lua_files = []
    for dirpath, _, filenames in os.walk(ROOT):
        for fn in filenames:
            if fn.endswith(".lua"):
                lua_files.append(os.path.join(dirpath, fn))

    for lf in sorted(lua_files):
        rel = os.path.relpath(lf, ROOT)
        with open(lf, "r", encoding="utf-8") as f:
            raw = f.read()
        cleaned = strip_lua_comments_and_strings(raw)

        # Check balanced braces and parentheses
        if cleaned.count("{") != cleaned.count("}"):
            fail(f"Unbalanced curly braces in {rel}")
        if cleaned.count("(") != cleaned.count(")"):
            fail(f"Unbalanced parentheses in {rel}")

        # Check Lua block keywords balance: (function + if + do + repeat) vs (end + until)
        # Note: in Lua, `while ... do` and `for ... do` use `do` which closes with `end`.
        openers = len(re.findall(r"\b(?:function|if|do)\b", cleaned))
        closers = len(re.findall(r"\bend\b", cleaned))
        if openers != closers:
            fail(f"Unbalanced Lua block keywords in {rel}: openers={openers}, ends={closers}")

    ok(f"Lua Structural & Keyword Balance: All {len(lua_files)} Lua files verified.")

def test_localization_parity_and_references():
    expected_langs = ["en", "ar", "fr", "de", "es", "pt", "tr", "it"]
    lang_keys = {}

    for code in expected_langs:
        p = os.path.join(ROOT, "locales", f"{code}.lua")
        if not os.path.isfile(p):
            fail(f"Missing locale file: locales/{code}.lua")
        with open(p, "r", encoding="utf-8") as f:
            txt = f.read()
        keys = set(re.findall(r"\['([a-zA-Z0-9_.]+)'\]\s*=", txt))
        if len(keys) < 200:
            fail(f"Too few keys in locales/{code}.lua: {len(keys)}")
        lang_keys[code] = keys

    en_set = lang_keys["en"]
    for code in expected_langs:
        if lang_keys[code] != en_set:
            missing = en_set - lang_keys[code]
            extra = lang_keys[code] - en_set
            fail(f"Key mismatch in locales/{code}.lua: missing={missing}, extra={extra}")

    # Check HTML data-i18n attributes against en_set
    with open(os.path.join(ROOT, "html", "index.html"), "r", encoding="utf-8") as f:
        html_txt = f.read()
    html_keys = re.findall(r'data-i18n(?:-[a-z]+)?="([^"]+)"', html_txt)
    for hk in html_keys:
        if hk not in en_set:
            fail(f"HTML references undefined localization key: {hk}")

    ok(f"Localization Parity & HTML Audit: All 8 languages share {len(en_set)} identical keys and all {len(html_keys)} HTML i18n attributes resolve.")

def test_no_language_selector_in_ui():
    forbidden_patterns = [
        r"language-select",
        r"select-language",
        r"changeLanguage",
        r"setLanguage",
        r"locale-dropdown"
    ]
    for dirpath, _, filenames in os.walk(os.path.join(ROOT, "html")):
        for fn in filenames:
            if fn.endswith((".html", ".js", ".css")):
                p = os.path.join(dirpath, fn)
                with open(p, "r", encoding="utf-8") as f:
                    txt = f.read()
                for pat in forbidden_patterns:
                    if re.search(pat, txt, re.IGNORECASE):
                        fail(f"Forbidden UI language selector pattern '{pat}' found in {fn}")
    ok("Configuration-Only Localization Rule: Zero UI language selectors exist in HTML/CSS/JS.")

def test_zero_external_network_dependencies():
    for dirpath, _, filenames in os.walk(os.path.join(ROOT, "html")):
        for fn in filenames:
            if fn.endswith((".html", ".css", ".js")):
                p = os.path.join(dirpath, fn)
                with open(p, "r", encoding="utf-8") as f:
                    txt = f.read()
                # Allow only https://${getResourceName()}/ inside persistence.js
                cleaned = txt.replace("https://${getResourceName()}/", "")
                cleaned = cleaned.replace("http://www.w3.org/2000/svg", "")
                urls = re.findall(r"https?://[^\s'\"`)>]+", cleaned)
                if urls:
                    fail(f"External URL found in {fn}: {urls}")
    ok("Offline Asset Compliance: Zero external CDN, font server, or remote URLs in NUI.")

def test_framework_isolation():
    for sub in ["client", "server"]:
        for dirpath, _, filenames in os.walk(os.path.join(ROOT, sub)):
            for fn in filenames:
                if fn.endswith(".lua"):
                    p = os.path.join(dirpath, fn)
                    with open(p, "r", encoding="utf-8") as f:
                        txt = f.read()
                    for fw in ["qb-core", "qbx_core", "es_extended"]:
                        if fw in txt:
                            fail(f"Framework export '{fw}' leaked outside bridge/framework.lua into {sub}/{fn}")
    ok("Framework Adapter Isolation: Zero framework exports scattered in client/ or server/.")

if __name__ == "__main__":
    print("=== Running NSR HUD Ultimate Static & Architectural Validation ===")
    test_manifest_files()
    test_lua_syntax_and_balance()
    test_localization_parity_and_references()
    test_no_language_selector_in_ui()
    test_zero_external_network_dependencies()
    test_framework_isolation()
    print("=== ALL STATIC & ARCHITECTURAL CHECKS PASSED ===")
