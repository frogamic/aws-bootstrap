#! /usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
set -o errtrace

die() {
	echo "$*" 1>&2
	exit 1
}

cd "$(dirname "$BASH_SOURCE[0]")"

PROJECT="bootstrap"
REVISION="$(git rev-parse --short HEAD || die "unknown")"
if [[ "$(git diff --stat)" != "" ]]; then
	 REVISION="${REVISION}-dirty"
fi
AWS_REGION="ap-southeast-2"

cd templates
for TEMPLATE in *.yaml; do
	STACKNAME="${TEMPLATE##[0-9][0-9]-}"
	STACKNAME="${PROJECT}-${STACKNAME%.yaml}"
	echo "Deploying ${STACKNAME}"

	aws cloudformation deploy \
		--stack-name "$STACKNAME" \
		--template-file "$TEMPLATE" \
		--capabilities CAPABILITY_NAMED_IAM \
		--region "$AWS_REGION" \
		--parameter-overrides \
			"Project=${PROJECT}" \
			"Revision=${REVISION}" \
		--no-fail-on-empty-changeset
done

cd ../scripts
for SCRIPT in *.sh; do
	echo "Executing ${SCRIPT}"

	. "$SCRIPT"
done
