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
REVISION="$(git rev-parse --short HEAD || die "Unknown git revision")"
REGION="ap-southeast-2"

cd templates
for TEMPLATE in *.yml; do
	STACKNAME="${PROJECT}-${TEMPLATE%.yml}"
	echo "Deploying ${STACKNAME}"

	aws cloudformation deploy \
		--stack-name "$STACKNAME" \
		--template-file "$TEMPLATE" \
		--capabilities CAPABILITY_NAMED_IAM \
		--region "$REGION" \
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
