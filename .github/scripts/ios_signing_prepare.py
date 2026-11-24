#!/usr/bin/env python3
"""Check the App Store provisioning profile and prepare signing on the CI Mac.

Reads the decoded provisioning profile, stops with a clear message if it does
not fit this app or the signing certificate, then writes:
  * ExportOptions.plist for `flutter build ipa`
  * the profile's push setting (aps-environment) into Runner.entitlements
  * TEAM_ID, PROFILE_NAME and USE_ENTITLEMENTS to $GITHUB_ENV

Used by .github/workflows/ios-app-store.yml. It only changes files on the
runner; nothing here is committed.
"""
import argparse
import datetime
import hashlib
import os
import plistlib
import sys


def fail(message):
    print(f"::error::{message}")
    sys.exit(1)


parser = argparse.ArgumentParser()
parser.add_argument("--profile", required=True, help="decoded .mobileprovision (XML plist)")
parser.add_argument("--identity-sha1", required=True, help="SHA-1 of the imported distribution certificate")
parser.add_argument("--bundle-id", required=True)
parser.add_argument("--entitlements", required=True)
parser.add_argument("--export-options", required=True)
args = parser.parse_args()

with open(args.profile, "rb") as f:
    profile = plistlib.load(f)

entitlements = profile.get("Entitlements", {})
name = profile.get("Name", "")
team_id = (profile.get("TeamIdentifier") or [""])[0]
app_identifier = entitlements.get("application-identifier", "")
profile_bundle_id = app_identifier.split(".", 1)[1] if "." in app_identifier else app_identifier

if profile_bundle_id != args.bundle_id:
    fail(f"Provisioning profile '{name}' is for '{profile_bundle_id}', but this app is '{args.bundle_id}'.")
if profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices") or entitlements.get("get-task-allow"):
    fail(f"Provisioning profile '{name}' is a Development, Ad Hoc or Enterprise profile. "
         "Create an 'App Store Connect' distribution profile instead.")

expires = profile.get("ExpirationDate")
now = datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
if isinstance(expires, datetime.datetime) and expires.replace(tzinfo=None) < now:
    fail(f"Provisioning profile '{name}' expired on {expires:%Y-%m-%d}. Download a fresh one.")

profile_certs = {hashlib.sha1(cert).hexdigest().upper() for cert in profile.get("DeveloperCertificates", [])}
if args.identity_sha1.upper() not in profile_certs:
    fail(f"The certificate in IOS_DIST_CERT_P12_BASE64 is not part of provisioning profile '{name}'. "
         "Edit the profile on developer.apple.com, tick that certificate, then download it again.")

# Push notifications: the app's entitlement must match the profile
# ("production" for App Store builds), or be dropped if the App ID has no push.
try:
    with open(args.entitlements, "rb") as f:
        app_entitlements = plistlib.load(f)
except FileNotFoundError:
    app_entitlements = {}

push = entitlements.get("aps-environment")
if push:
    app_entitlements["aps-environment"] = push
elif app_entitlements.pop("aps-environment", None) is not None:
    print(f"::warning::Provisioning profile '{name}' has no Push Notifications, so Firebase push will not work "
          f"in this build. Turn on Push Notifications for the App ID {args.bundle_id}, then regenerate the profile.")

if app_entitlements:
    with open(args.entitlements, "wb") as f:
        plistlib.dump(app_entitlements, f)

export_options = {
    "method": "app-store-connect",
    "destination": "export",
    "teamID": team_id,
    "signingStyle": "manual",
    "signingCertificate": args.identity_sha1.upper(),
    "provisioningProfiles": {args.bundle_id: name},
    "uploadSymbols": True,
}
with open(args.export_options, "wb") as f:
    plistlib.dump(export_options, f)

with open(os.environ["GITHUB_ENV"], "a") as f:
    f.write(f"TEAM_ID={team_id}\n")
    f.write(f"PROFILE_NAME={name}\n")
    f.write(f"USE_ENTITLEMENTS={'1' if app_entitlements else '0'}\n")

expires_text = f"{expires:%Y-%m-%d}" if isinstance(expires, datetime.datetime) else "unknown"
print(f"Profile '{name}' (team {team_id}, {profile_bundle_id}), expires {expires_text}, push: {push or 'off'}")
