# Serverless Portfolio and Blog

Student ID: 79010409

Cloud Computing project (BSc.CSIT). A small portfolio and blog hosted on AWS. Anyone can read the posts, and only logged-in users can create them.

## Architecture
- S3: hosts the static website
- API Gateway: REST API (`GET /posts`, `GET /posts/{id}`, `POST /posts`)
- Lambda: three Python functions, one per route
- DynamoDB: stores the posts
- Cognito: user pool for login, protects `POST /posts`
- CloudWatch: Lambda logs
- SAM / CloudFormation: whole infrastructure is in `template.yaml`

All resource names start with `79010409`.

## Folders
- `template.yaml` - infrastructure
- `backend/` - Lambda code
- `frontend/index.html` - website
- `deploy.sh` - deploys the stack and uploads the site
- `cleanup.sh` - deletes everything

## Deploy
Run in AWS CloudShell (Learner Lab, us-east-1):

```bash
chmod +x deploy.sh cleanup.sh
./deploy.sh <email> '<password>'
```

The script prints the website URL at the end. Log in with the same email and password.

## Delete
```bash
./cleanup.sh
```
