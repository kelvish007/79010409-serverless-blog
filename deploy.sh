#!/usr/bin/env bash
# Deploys the whole stack, uploads the website and creates a login user.
# Usage:  ./deploy.sh <login-email> <login-password>
# Works in AWS CloudShell (no installs needed). Uses only the AWS CLI.
set -euo pipefail

STUDENT_ID="79010409"
STACK="blog-${STUDENT_ID}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
EMAIL="${1:?Usage: ./deploy.sh <login-email> <login-password>}"
PASSWORD="${2:?Usage: ./deploy.sh <login-email> <login-password>}"

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ARTIFACT_BUCKET="${STUDENT_ID}-artifacts-${ACCOUNT}"

echo "==> Region: ${REGION}  Account: ${ACCOUNT}"

# Bucket that holds the zipped Lambda code during deployment.
if ! aws s3api head-bucket --bucket "$ARTIFACT_BUCKET" --region "$REGION" 2>/dev/null; then
  echo "==> Creating artifact bucket ${ARTIFACT_BUCKET}"
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$ARTIFACT_BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$ARTIFACT_BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
fi

echo "==> Packaging"
aws cloudformation package \
  --template-file template.yaml \
  --s3-bucket "$ARTIFACT_BUCKET" \
  --output-template-file packaged.yaml \
  --region "$REGION"

echo "==> Deploying stack ${STACK} (takes 2-4 minutes)"
aws cloudformation deploy \
  --template-file packaged.yaml \
  --stack-name "$STACK" \
  --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
  --parameter-overrides "StudentId=${STUDENT_ID}" \
  --no-fail-on-empty-changeset \
  --region "$REGION"

out() {
  aws cloudformation describe-stacks --stack-name "$STACK" --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}

API_URL=$(out ApiUrl)
POOL_ID=$(out UserPoolId)
CLIENT_ID=$(out UserPoolClientId)
BUCKET=$(out BucketName)
SITE_URL=$(out WebsiteUrl)

echo "==> Writing frontend/config.js"
cat > frontend/config.js <<EOF
window.APP_CONFIG = {
  studentId: "${STUDENT_ID}",
  region: "${REGION}",
  apiUrl: "${API_URL}",
  clientId: "${CLIENT_ID}"
};
EOF

echo "==> Uploading website to s3://${BUCKET}"
aws s3 sync frontend/ "s3://${BUCKET}/" --region "$REGION" --delete

echo "==> Creating Cognito user ${EMAIL}"
aws cognito-idp admin-create-user \
  --user-pool-id "$POOL_ID" --username "$EMAIL" \
  --user-attributes Name=email,Value="$EMAIL" Name=email_verified,Value=true \
  --message-action SUPPRESS --region "$REGION" >/dev/null 2>&1 || echo "    (user already exists, continuing)"
aws cognito-idp admin-set-user-password \
  --user-pool-id "$POOL_ID" --username "$EMAIL" \
  --password "$PASSWORD" --permanent --region "$REGION"

echo
echo "DONE. Website: ${SITE_URL}"
