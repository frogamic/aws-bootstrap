#! /usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
set -o errtrace

die() {
	echo "$*" 1>&2
	exit 1
}

hash jq || die "JQ is required"
hash aws || die "AWS CLI is required"

cd "$(dirname "$BASH_SOURCE[0]")"

PROJECT="Bootstrap"
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

	PARAMS="Project=${PROJECT} Revision=${REVISION}"
	PARAM_FILE="../parameters/${TEMPLATE%%.yaml}.json"
	if [[ -f "$PARAM_FILE" ]]; then
		PARAMS="${PARAMS} $(jq -r '. | join(" ")' < "$PARAM_FILE")"
	fi

	aws cloudformation deploy \
		--stack-name "$STACKNAME" \
		--template-file "$TEMPLATE" \
		--region "$AWS_REGION" \
		--parameter-overrides $PARAMS \
		--no-fail-on-empty-changeset
done
