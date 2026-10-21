"""Checks that every tr('...') text has a Hindi and a Kannada translation.

    python tools/check_translations.py            # all apps
    python tools/check_translations.py bank_app   # one app ("core" for packages/rakshak_core)

Texts used in an app may be translated in the app's lib/l10n.dart or in the shared
packages/rakshak_core/lib/src/l10n_core.dart.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CORE = ROOT / "packages" / "rakshak_core"
CORE_TABLE = CORE / "lib" / "src" / "l10n_core.dart"
APPS = ["bank_app", "upi_app", "merchant_app", "crypto_app", "police_app"]

LIT = r"""(?:'(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")"""
LITSEQ = rf"(?:{LIT}(?:\s*{LIT})*)"
TR_CALL = re.compile(rf"\btr\(\s*({LITSEQ})")
ENTRY = re.compile(rf"({LITSEQ})\s*:\s*({LITSEQ})\s*,")
LANG_BLOCK = re.compile(r"'(hi|kn)'\s*:\s*\{")


def decode(seq: str) -> str:
    out = []
    for m in re.finditer(LIT, seq):
        body = m.group(0)[1:-1]
        out.append(re.sub(r"\\(.)", lambda e: {"n": "\n", "t": "\t"}.get(e.group(1), e.group(1)), body))
    return "".join(out)


def used_keys(lib: pathlib.Path, skip: set[pathlib.Path]) -> dict[str, str]:
    keys = {}
    for f in lib.rglob("*.dart"):
        if f in skip:
            continue
        text = f.read_text(encoding="utf-8")
        for m in TR_CALL.finditer(text):
            line = text.count("\n", 0, m.start()) + 1
            keys.setdefault(decode(m.group(1)), f"{f.relative_to(ROOT)}:{line}")
    return keys


def table(path: pathlib.Path) -> dict[str, dict[str, str]]:
    result = {"hi": {}, "kn": {}}
    if not path.exists():
        return result
    text = path.read_text(encoding="utf-8")
    blocks = list(LANG_BLOCK.finditer(text))
    for i, b in enumerate(blocks):
        end = blocks[i + 1].start() if i + 1 < len(blocks) else len(text)
        for m in ENTRY.finditer(text[b.end():end]):
            result[b.group(1)][decode(m.group(1))] = decode(m.group(2))
    return result


def placeholders(s: str) -> set[str]:
    return set(re.findall(r"\{(\w+)\}", s))


def check(name: str) -> int:
    core = table(CORE_TABLE)
    if name == "core":
        lib, own = CORE / "lib", core
        used = used_keys(lib, {CORE_TABLE})
        others = {"hi": {}, "kn": {}}
    else:
        lib = ROOT / "apps" / name / "lib"
        own = table(lib / "l10n.dart")
        used = used_keys(lib, {lib / "l10n.dart"})
        others = core
    problems = 0
    for lang in ("hi", "kn"):
        for key, where in sorted(used.items(), key=lambda kv: kv[1]):
            value = own[lang].get(key, others[lang].get(key))
            if value is None:
                print(f"[{name}] missing {lang}: {key!r}  ({where})")
                problems += 1
            elif placeholders(value) != placeholders(key):
                print(f"[{name}] {lang} placeholders differ: {key!r} -> {value!r}")
                problems += 1
    print(f"[{name}] {len(used)} texts, {problems} problems")
    return problems


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    names = sys.argv[1:] or ["core", *APPS]
    sys.exit(1 if sum(check(n) for n in names) else 0)
