#!/usr/bin/env python3
"""Checks the facts that live in more than one file still agree, and that the App Store listing fits.

    scripts/check-consistency.py          # exits 1 if anything is wrong; warnings don't fail

Errors are things App Review or the build will catch the hard way (a product ID that doesn't match, a
missing usage description, a listing field over its limit). Warnings need a human look (a Pro feature
the README doesn't mention). Runs anywhere Python 3 does, including Linux.
"""
import json
import pathlib
import plistlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
errors, warnings = [], []


def read(path):
    p = ROOT / path
    return p.read_text(encoding="utf-8") if p.exists() else ""


def error(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


project = read("project.yml")
NAME = re.search(r"^name:\s*(\S+)", project, re.M).group(1)
BUNDLE_ID = re.search(r"APP_BUNDLE_IDENTIFIER:\s*(\S+)", project).group(1)
swift_files = [p for d in (NAME, "Shared", f"{NAME}Widgets") for p in (ROOT / d).rglob("*.swift")]
app_swift = "\n".join(p.read_text(encoding="utf-8") for p in swift_files)

# --- Versions: ci_post_clone.sh stamps exactly one MARKETING_VERSION.
if len(re.findall(r"MARKETING_VERSION:", project)) != 1:
    error("project.yml must have exactly one MARKETING_VERSION line (ci_scripts/ci_post_clone.sh relies on it)")

# --- Pro product ID and price.
store = read(f"{NAME}/Store.swift")
m = re.search(r'proID\s*=\s*"([^"]+)"', store)
pro_id = m.group(1) if m else None
storekit = json.loads(read(f"{NAME}.storekit") or "{}")
products = {p["productID"]: p for p in storekit.get("products", [])}
if pro_id != f"{BUNDLE_ID}.pro":
    warn(f"Store.proID is {pro_id!r}; the convention is {BUNDLE_ID}.pro")
if pro_id not in products:
    error(f"{NAME}.storekit doesn't sell Store.proID ({pro_id})")
listing = read("APPSTORE.md")
if pro_id and pro_id not in listing:
    error(f"APPSTORE.md doesn't mention the product ID {pro_id}")
if pro_id in products:
    price = products[pro_id]["displayPrice"]
    m = re.search(r"\|\s*Price\s*\|\s*\$?([0-9.]+)", listing)
    if m and m.group(1) != price:
        error(f"APPSTORE.md price ${m.group(1)} doesn't match {NAME}.storekit's ${price}")
    for loc in products[pro_id].get("localizations", []):
        if len(loc.get("description", "")) > 55:
            error(f"{NAME}.storekit Pro description is over App Store Connect's 55 characters")

# --- Pro features are described everywhere they're sold (guideline 2.3.2).
features = re.findall(r'title:\s*"([^"]+)"', read(f"{NAME}/ProFeatures.swift"))
readme = read("README.md").lower()
for title in features:
    if title.lower() not in readme:
        warn(f"Pro feature {title!r} (ProFeatures.swift) isn't in README.md")
    if title.lower() not in listing.lower():
        warn(f"Pro feature {title!r} (ProFeatures.swift) isn't in APPSTORE.md")

# --- Accent colour in its four homes.
def hex_of(r, g, b):
    return "".join(f"{round(float(c) * 255):02X}" for c in (r, g, b))

rgb = r"red:\s*([0-9.]+),\s*green:\s*([0-9.]+),\s*blue:\s*([0-9.]+)"
accents = {}
m = re.search(r"accent\s*=\s*Color\(" + rgb, read("Shared/Brand.swift"))
if m:
    accents["Shared/Brand.swift"] = hex_of(*m.groups())
m = re.search(r"let accent\s*=\s*Color\(" + rgb, read("appstore/frame-screenshots.swift"))
if m:
    accents["appstore/frame-screenshots.swift"] = hex_of(*m.groups())
asset = read(f"{NAME}/Assets.xcassets/AccentColor.colorset/Contents.json")
if asset:
    comp = json.loads(asset)["colors"][0]["color"]["components"]
    accents["AccentColor asset"] = hex_of(comp["red"], comp["green"], comp["blue"])
m = re.search(r"--accent:\s*#([0-9A-Fa-f]{6})", read("docs/assets/style.css"))
if m:
    accents["docs/assets/style.css"] = m.group(1).upper()
if len(set(accents.values())) > 1:
    # Rounding 0–1 components can be off by one step; only flag real differences.
    vals = [tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in accents.values()]
    if any(abs(a - b) > 1 for v in vals for w in vals for a, b in zip(v, w)):
        error("Accent colour differs: " + ", ".join(f"{k} #{v}" for k, v in accents.items()))

# --- Website: the app links where the site lives.
web = dict(re.findall(r'static let (\w+) = URL\(string: "([^"]+)"\)', read(f"{NAME}/About.swift")))
cname = read("docs/CNAME").strip()
for key in ("privacy", "support"):
    url = web.get(key)
    if not url:
        error(f"About.swift has no AppWeb.{key} URL (App Review requires it in the app)")
        continue
    if cname and f"//{cname}/" not in url:
        error(f"AppWeb.{key} ({url}) isn't on docs/CNAME's domain ({cname})")
    if url not in listing:
        warn(f"APPSTORE.md doesn't list {url}")
    if not (ROOT / "docs" / key / "index.html").exists():
        error(f"docs/{key}/index.html is missing")

# --- Privacy policy in its two copies.
md, html = read("PRIVACY.md"), read("docs/privacy/index.html")
md_date = re.search(r"Last updated:\s*([^\n]+)", md)
html_date = re.search(r"Last updated:\s*([^<\n]+)", html)
if md_date and html_date:
    md_day, html_day = md_date.group(1).strip(" _"), html_date.group(1).strip(" _")
    if md_day != html_day:
        error(f"PRIVACY.md ({md_day}) and docs/privacy ({html_day}) have different dates")
md_points = {s.strip(" .") for s in re.findall(r"^- \*\*([^*]+)\*\*", md, re.M)}
html_points = {s.strip(" .") for s in re.findall(r"<li><strong>([^<]+)</strong>", html)}
if md_points != html_points:
    error("PRIVACY.md and docs/privacy/index.html cover different points: "
          f"only in PRIVACY.md {sorted(md_points - html_points)}, only on the site {sorted(html_points - md_points)}")

# --- Privacy manifests and usage descriptions against what the code uses.
def manifest(path):
    p = ROOT / path
    return plistlib.loads(p.read_bytes()) if p.exists() else {}

app_manifest = manifest(f"{NAME}/PrivacyInfo.xcprivacy")
declared = {t["NSPrivacyAccessedAPIType"] for t in app_manifest.get("NSPrivacyAccessedAPITypes", [])}
required_reason = {
    "NSPrivacyAccessedAPICategoryUserDefaults": r"\bUserDefaults\b|@AppStorage",
    "NSPrivacyAccessedAPICategoryFileTimestamp": r"\.creationDate\b|\.modificationDate\b|contentModificationDate|attributesOfItem",
    "NSPrivacyAccessedAPICategorySystemBootTime": r"systemUptime|mach_absolute_time",
    "NSPrivacyAccessedAPICategoryDiskSpace": r"volumeAvailableCapacity|systemFreeSize|systemSize\b",
}
for category, pattern in required_reason.items():
    if re.search(pattern, app_swift) and category not in declared:
        error(f"The code uses a required-reason API ({category}) that {NAME}/PrivacyInfo.xcprivacy doesn't declare")
collects = bool(app_manifest.get("NSPrivacyCollectedDataTypes"))
says_none = "doesn't collect" in md or "does not collect" in md
if collects and says_none:
    error("PrivacyInfo.xcprivacy declares collected data but PRIVACY.md says nothing is collected")

usage = {
    "NSMicrophoneUsageDescription": r"AVAudioEngine|inputNode|AVAudioRecorder|requestRecordPermission",
    "NSCameraUsageDescription": r"AVCaptureDevice|AVCaptureSession|UIImagePickerController\.SourceType\.camera",
    "NSPhotoLibraryUsageDescription": r"PHPhotoLibrary|PHAsset",
    "NSLocationWhenInUseUsageDescription": r"CLLocationManager|CLLocationUpdate|CLMonitor",
    "NSHealthShareUsageDescription": r"HKHealthStore",
    "NSHealthUpdateUsageDescription": r"HKHealthStore",
    "NSFaceIDUsageDescription": r"LAContext",
    "NSContactsUsageDescription": r"CNContactStore",
    "NSCalendarsFullAccessUsageDescription": r"EKEventStore",
    "NSSpeechRecognitionUsageDescription": r"SFSpeechRecognizer",
    "NSMotionUsageDescription": r"CMMotionActivityManager|CMPedometer",
}
info_plist = read(f"Config/{NAME}-Info.plist")
for key, pattern in usage.items():
    if re.search(pattern, app_swift) and key not in project and key not in info_plist:
        error(f"The code uses an API that needs {key} (add INFOPLIST_KEY_{key} to project.yml)")
if re.search(r"URLSession|URLRequest|WKWebView", app_swift) and "no network connections" in md:
    error("The code makes network requests but PRIVACY.md says the app makes no network connections")

# --- Listing limits (App Store Connect's character counts).
def table_value(field):
    m = re.search(r"^\|\s*" + re.escape(field) + r"[^|]*\|\s*(.*?)\s*\|\s*$", listing, re.M)
    return m.group(1) if m else ""

def block_after(heading):
    m = re.search(r"\*\*" + re.escape(heading) + r"[^*]*\*\*\s*\n+(?:> ([^\n]*)|```\n(.*?)```)", listing, re.S)
    return (m.group(1) or m.group(2) or "").strip() if m else ""

limits = [
    ("Name", table_value("Name"), 30),
    ("Subtitle", table_value("Subtitle"), 30),
    ("Promotional text", block_after("Promotional text"), 170),
    ("Keywords", block_after("Keywords"), 100),
    ("Description", block_after("Description"), 4000),
    ("What's New", block_after("What's New"), 4000),
    ("IAP description", table_value("Description (55)"), 55),
]
for field, value, limit in limits:
    if len(value) > limit:
        error(f"APPSTORE.md {field} is {len(value)} characters; App Store Connect allows {limit}")
keywords = block_after("Keywords")
if keywords and re.search(r",\s", keywords):
    warn("APPSTORE.md keywords have spaces after commas, which waste characters")
if not table_value("Subtitle"):
    warn("APPSTORE.md has no subtitle yet")

# --- Placeholders a new app still carries.
for path, text in [("README.md", read("README.md")), ("docs/index.html", read("docs/index.html")),
                   (f"{NAME}/ProFeatures.swift", read(f"{NAME}/ProFeatures.swift"))]:
    if re.search(r"describe the main screen|Feature one|Replace these with|list the rest here", text):
        warn(f"{path} still has template placeholder text")

for msg in errors:
    print(f"error: {msg}")
for msg in warnings:
    print(f"warning: {msg}")
if not errors and not warnings:
    print("All consistent.")
sys.exit(1 if errors else 0)
