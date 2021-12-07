# Key names CANNOT have spaces in them
KEYS=( \
	"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICzGL9KhRd2lKNuTZq1cK+4bkioGBkaMetfbzf/uuqTj dominic@enki" \
	"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE5rpMMLWs8oQXYtg9wXuvsb70O0vtPX+KEK1KiJAZVO dominic@ninhursag" \
)

NEWKEYS=""
for KEY in "${KEYS[@]}"; do
	NONE="====================================================================="
	KEYNAME="${KEY#* * }" # Strip the first 2 space separated parts, i.e. get comment only.

	NEWKEYS="${NEWKEYS} ${KEYNAME} "

	REMOTEFINGERPRINT="$(aws ec2 describe-key-pairs \
		--key-name "$KEYNAME" \
		--filters \
			"Name=tag:Project,Values=${PROJECT}" \
			"Name=tag:Stage,Values=${STAGE}" \
		--output json \
		--query 'KeyPairs[0].KeyFingerprint' 2>/dev/null \
		|| echo "$NONE" \
	)"

	LOCALFINGERPRINT=$(echo "$KEY" | ssh-keygen -E sha256 -lf -)
	LOCALFINGERPRINT=${LOCALFINGERPRINT#*SHA256:} # Strip everything preceding fingerprint
	LOCALFINGERPRINT=${LOCALFINGERPRINT%% *} # Strip everything after fingerprint

	if [[ "$REMOTEFINGERPRINT" != *$LOCALFINGERPRINT* ]]; then
		if [[ "$REMOTEFINGERPRINT" != "$NONE" ]]; then
			echo "  Deleting existing key - $KEYNAME"
			aws ec2 delete-key-pair --key-name "$KEYNAME"
		fi
			echo "  Uploading key - $KEYNAME"
		aws ec2 import-key-pair \
			--key-name "$KEYNAME" \
			--public-key-material "$KEY" \
			--output text \
			--query "[KeyPairId,KeyFingerprint]" \
			--tag-specifications "ResourceType=key-pair,Tags=[{Key=Project,Value=${PROJECT}},{Key=Stage,Value=${STAGE}}]"
	fi
done

ALLKEYS="$(aws ec2 describe-key-pairs \
	--filters \
		"Name=tag:Project,Values=${PROJECT}" \
		"Name=tag:Stage,Values=${STAGE}" \
	--output text \
	--query "KeyPairs[*].KeyName" \
)"

for KEY in $ALLKEYS; do
	if [[ "$NEWKEYS" != *" $KEY "* ]]; then
			echo "  Deleting old key - ${KEY}"
			aws ec2 delete-key-pair --key-name "$KEY"
	fi
done
