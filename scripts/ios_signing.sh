#!/usr/bin/env bash
# Makes the iOS App Store signing files on Linux, so no Mac is needed.
# Files go to ~/ios-signing (outside the repo). Never commit them.
#
#   scripts/ios_signing.sh csr
#       Creates a private key and ios_distribution.csr. Upload the .csr at
#       developer.apple.com → Certificates → + → "Apple Distribution".
#
#   scripts/ios_signing.sh p12 <distribution.cer>
#       Joins the certificate Apple gave you with the private key into a .p12
#       and writes the values for IOS_DIST_CERT_P12_BASE64 and IOS_DIST_CERT_PASSWORD.
#
#   scripts/ios_signing.sh profile <file.mobileprovision>
#       Writes the value for IOS_PROVISION_PROFILE_BASE64.
#
# Set IOS_SIGNING_DIR to use another folder.
set -euo pipefail

dir="${IOS_SIGNING_DIR:-$HOME/ios-signing}"
key="$dir/ios_distribution.key"
umask 077
mkdir -p "$dir"
chmod 700 "$dir"

case "${1:-}" in
  csr)
    if [ -e "$key" ]; then
      echo "$key already exists; not replacing it." >&2
      exit 1
    fi
    email="${IOS_CSR_EMAIL:-$(git config user.email || true)}"
    name="${IOS_CSR_NAME:-$(git config user.name || echo 'iOS Distribution')}"
    openssl genrsa -out "$key" 2048 2>/dev/null
    openssl req -new -key "$key" -out "$dir/ios_distribution.csr" \
      -subj "/emailAddress=${email}/CN=${name}/C=IN"
    echo "Private key: $key   (keep this safe)"
    echo "CSR:         $dir/ios_distribution.csr   (upload this to Apple)"
    ;;

  p12)
    cer="${2:?usage: $0 p12 <distribution.cer>}"
    [ -e "$key" ] || { echo "No private key at $key. Run '$0 csr' first." >&2; exit 1; }
    pem="$dir/ios_distribution.pem"
    openssl x509 -inform DER -in "$cer" -out "$pem" 2>/dev/null || openssl x509 -in "$cer" -out "$pem"
    if [ "$(openssl x509 -in "$pem" -noout -pubkey)" != "$(openssl pkey -in "$key" -pubout)" ]; then
      echo "This certificate was not made from $key. Upload $dir/ios_distribution.csr to Apple again." >&2
      exit 1
    fi
    password=$(openssl rand -hex 16)
    # 3DES/SHA-1 so the macOS keychain on the build Mac can import it.
    openssl pkcs12 -export -inkey "$key" -in "$pem" -out "$dir/ios_distribution.p12" \
      -name "$(openssl x509 -in "$pem" -noout -subject -nameopt multiline | sed -n 's/^ *commonName *= //p')" \
      -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1 -passout "pass:$password"
    base64 -w0 "$dir/ios_distribution.p12" > "$dir/IOS_DIST_CERT_P12_BASE64.txt"
    printf '%s' "$password" > "$dir/IOS_DIST_CERT_PASSWORD.txt"
    openssl x509 -in "$pem" -noout -subject -enddate
    echo "Secret values written to:"
    echo "  $dir/IOS_DIST_CERT_P12_BASE64.txt"
    echo "  $dir/IOS_DIST_CERT_PASSWORD.txt"
    ;;

  profile)
    prof="${2:?usage: $0 profile <file.mobileprovision>}"
    base64 -w0 "$prof" > "$dir/IOS_PROVISION_PROFILE_BASE64.txt"
    echo "Secret value written to: $dir/IOS_PROVISION_PROFILE_BASE64.txt"
    ;;

  *)
    sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
