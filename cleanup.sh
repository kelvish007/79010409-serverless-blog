#!/usr/bin/env bash
# Removes everything to stay inside Free Tier. Run after testing / after the demo.
set -uo pipefail

STUDENT_ID="79010409"
STACK="blog-${STUDENT_ID}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ARTIFACT_BUCKET="${STUDENT_ID}-artifacts-${ACCOUNT}"

BUCKET=$(aws cloudformation describe-stacks --stack-name "$STACK" --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text 2>/dev/null || true)

if [ -n "${BUCKET:-}" ] && [ "$BUCKET" != "None" ]; then
  echo "==> Emptying s3://${BUCKET}"
  aws s3 rm "s3://${BUCKET}" --recursive --region "$REGION"
fi

echo "==> Deleting stack ${STACK}"
aws cloudformation delete-stack --stack-name "$STACK" --region "$REGION"
aws cloudformation wait stack-delete-complete --stack-name "$STACK" --region "$REGION"

echo "==> Removing artifact bucket ${ARTIFACT_BUCKET}"
aws s3 rb "s3://${ARTIFACT_BUCKET}" --force --region "$REGION" || true
echo "All deleted."
