# GitHub Actions CI/CD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Jenkinsfile with GitHub Actions workflows that deploy the VPC module to dev, qa, and prod environments using OIDC authentication, per-branch triggers, and S3 remote state.

**Architecture:** Three branch-triggered workflows (`dev`→dev, `qa`→qa, `main`→prod) call a shared reusable workflow that runs `terraform init/validate/plan/apply` from the `examples/` directory with environment-specific tfvars. A fourth workflow validates all pull requests with plan-only (no apply). State is stored in S3 with DynamoDB locking, one key per environment in the same bucket. Prod uses a GitHub Environment with required reviewers as the approval gate.

**Tech Stack:** GitHub Actions, Terraform >= 1.1.0, AWS OIDC (no long-lived keys), S3 + DynamoDB backend, `hashicorp/setup-terraform` action, `aws-actions/configure-aws-credentials` action.

---

## Pre-Sprint: One-Time AWS Bootstrap (manual — do this before running any workflow)

These steps only need to be done once. They cannot be automated because they are prerequisites for automation.

### A. Create S3 bucket and DynamoDB table for Terraform state

```bash
# Create the state bucket (replace BUCKET_NAME with your chosen name, e.g. farrukh-vpc-tfstate)
aws s3api create-bucket \
  --bucket BUCKET_NAME \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket BUCKET_NAME \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### B. Create IAM OIDC provider for GitHub (once per AWS account)

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### C. Create IAM role for GitHub Actions

Save this as `/tmp/trust-policy.json` (replace `YOUR_GITHUB_ORG` and `YOUR_REPO`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:farrukh90/terraform-aws-vpc:*"
        }
      }
    }
  ]
}
```

```bash
aws iam create-role \
  --role-name github-actions-vpc-deployer \
  --assume-role-policy-document file:///tmp/trust-policy.json

aws iam attach-role-policy \
  --role-name github-actions-vpc-deployer \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

> Note: Scope the policy down to only VPC/EC2 permissions in production. PowerUserAccess is fine for getting started.

### D. Set GitHub repository secrets

In GitHub → Settings → Secrets → Actions, add:

| Secret name | Value |
|---|---|
| `AWS_ROLE_ARN` | `arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-vpc-deployer` |
| `TF_STATE_BUCKET` | Your bucket name from step A |
| `TF_LOCK_TABLE` | `terraform-state-lock` |

### E. Create GitHub Environment for prod approval gate

In GitHub → Settings → Environments → New environment → name it `production`.
Add yourself (and any reviewers) under "Required reviewers".
This blocks the prod apply job until a reviewer approves.

---

## File Map

| Action | File |
|---|---|
| CREATE | `.github/workflows/_terraform.yml` (reusable workflow) |
| CREATE | `.github/workflows/pr-validate.yml` |
| CREATE | `.github/workflows/deploy-dev.yml` |
| CREATE | `.github/workflows/deploy-qa.yml` |
| CREATE | `.github/workflows/deploy-prod.yml` |
| CREATE | `environments/dev.tfvars` |
| CREATE | `environments/qa.tfvars` |
| CREATE | `environments/prod.tfvars` |
| MODIFY | `examples/provider.tf` (add S3 backend block) |
| DELETE | `Jenkinsfile` |
| MODIFY | `README.md` (replace Jenkins section with GitHub Actions) |

---

## Task 1: Create environment tfvars files

**Files:**
- Create: `environments/dev.tfvars`
- Create: `environments/qa.tfvars`
- Create: `environments/prod.tfvars`

- [ ] **Step 1: Create `environments/dev.tfvars`**

```hcl
region   = "us-east-1"
vpc_cidr = "10.0.0.0/16"

public_cidr1 = "10.0.101.0/24"
public_cidr2 = "10.0.102.0/24"
public_cidr3 = "10.0.103.0/24"

private_cidr1 = "10.0.1.0/24"
private_cidr2 = "10.0.2.0/24"
private_cidr3 = "10.0.3.0/24"

tags = {
  Name        = "VPC_Project"
  Environment = "dev"
  Team        = "DevOps"
  Created_by  = "Terraform"
  ManagedBy   = "GitHub Actions"
}
```

- [ ] **Step 2: Create `environments/qa.tfvars`**

```hcl
region   = "us-east-1"
vpc_cidr = "10.1.0.0/16"

public_cidr1 = "10.1.101.0/24"
public_cidr2 = "10.1.102.0/24"
public_cidr3 = "10.1.103.0/24"

private_cidr1 = "10.1.1.0/24"
private_cidr2 = "10.1.2.0/24"
private_cidr3 = "10.1.3.0/24"

tags = {
  Name        = "VPC_Project"
  Environment = "qa"
  Team        = "DevOps"
  Created_by  = "Terraform"
  ManagedBy   = "GitHub Actions"
}
```

- [ ] **Step 3: Create `environments/prod.tfvars`**

```hcl
region   = "us-east-1"
vpc_cidr = "10.2.0.0/16"

public_cidr1 = "10.2.101.0/24"
public_cidr2 = "10.2.102.0/24"
public_cidr3 = "10.2.103.0/24"

private_cidr1 = "10.2.1.0/24"
private_cidr2 = "10.2.2.0/24"
private_cidr3 = "10.2.3.0/24"

tags = {
  Name        = "VPC_Project"
  Environment = "prod"
  Team        = "DevOps"
  Created_by  = "Terraform"
  ManagedBy   = "GitHub Actions"
}
```

- [ ] **Step 4: Verify CIDRs don't overlap across environments**

Run:
```bash
grep vpc_cidr environments/*.tfvars
```
Expected output — three distinct /16 blocks:
```
environments/dev.tfvars:vpc_cidr = "10.0.0.0/16"
environments/qa.tfvars:vpc_cidr  = "10.1.0.0/16"
environments/prod.tfvars:vpc_cidr = "10.2.0.0/16"
```

- [ ] **Step 5: Commit**

```bash
git add environments/
git commit -m "feat: add per-environment tfvars for dev, qa, prod"
```

---

## Task 2: Add S3 backend to examples/provider.tf

**Files:**
- Modify: `examples/provider.tf`

The backend block is intentionally empty — all values are passed via `-backend-config` flags in CI so the same code works for all three environments.

- [ ] **Step 1: Update `examples/provider.tf`**

Replace the entire file with:

```hcl
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.region
}
```

- [ ] **Step 2: Verify the file is valid Terraform syntax**

```bash
cd examples && terraform init -backend=false 2>&1 | grep -E "Success|Error"
```
Expected: `Terraform has been successfully initialized!`

- [ ] **Step 3: Commit**

```bash
git add examples/provider.tf
git commit -m "feat: add partial S3 backend config to examples"
```

---

## Task 3: Create reusable workflow

**Files:**
- Create: `.github/workflows/_terraform.yml`

This workflow is called by the three deploy workflows and the PR validate workflow. It is NOT triggered directly.

- [ ] **Step 1: Create `.github/workflows/_terraform.yml`**

```yaml
name: Terraform (reusable)

on:
  workflow_call:
    inputs:
      environment:
        description: "Environment name (dev, qa, prod)"
        required: true
        type: string
      apply:
        description: "Run terraform apply after plan"
        required: false
        type: boolean
        default: false
    secrets:
      AWS_ROLE_ARN:
        required: true
      TF_STATE_BUCKET:
        required: true
      TF_LOCK_TABLE:
        required: true

jobs:
  terraform:
    name: Terraform ${{ inputs.apply && 'Plan + Apply' || 'Plan' }} — ${{ inputs.environment }}
    runs-on: ubuntu-latest
    environment: ${{ inputs.apply && inputs.environment == 'prod' && 'production' || '' }}

    permissions:
      id-token: write   # required for OIDC
      contents: read

    defaults:
      run:
        working-directory: examples

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.1"

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
            -backend-config="key=terraform/${{ inputs.environment }}/terraform.tfstate" \
            -backend-config="region=us-east-1" \
            -backend-config="dynamodb_table=${{ secrets.TF_LOCK_TABLE }}" \
            -backend-config="encrypt=true" \
            -input=false

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: |
          terraform plan \
            -var-file="../environments/${{ inputs.environment }}.tfvars" \
            -out=tfplan \
            -input=false

      - name: Terraform Apply
        if: inputs.apply
        run: terraform apply -input=false tfplan
```

- [ ] **Step 2: Verify YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/_terraform.yml'))" && echo "YAML valid"
```
Expected: `YAML valid`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/_terraform.yml
git commit -m "feat: add reusable Terraform workflow"
```

---

## Task 4: Create PR validation workflow

**Files:**
- Create: `.github/workflows/pr-validate.yml`

Runs on every pull request to `dev`, `qa`, or `main`. Plans all three environments so reviewers can see what would change in each. Does NOT apply.

- [ ] **Step 1: Create `.github/workflows/pr-validate.yml`**

```yaml
name: PR Validate

on:
  pull_request:
    branches: [dev, qa, main]

jobs:
  validate-dev:
    name: Plan — dev
    uses: ./.github/workflows/_terraform.yml
    with:
      environment: dev
      apply: false
    secrets:
      AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}
      TF_STATE_BUCKET: ${{ secrets.TF_STATE_BUCKET }}
      TF_LOCK_TABLE: ${{ secrets.TF_LOCK_TABLE }}

  validate-qa:
    name: Plan — qa
    uses: ./.github/workflows/_terraform.yml
    with:
      environment: qa
      apply: false
    secrets:
      AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}
      TF_STATE_BUCKET: ${{ secrets.TF_STATE_BUCKET }}
      TF_LOCK_TABLE: ${{ secrets.TF_LOCK_TABLE }}

  validate-prod:
    name: Plan — prod
    uses: ./.github/workflows/_terraform.yml
    with:
      environment: prod
      apply: false
    secrets:
      AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}
      TF_STATE_BUCKET: ${{ secrets.TF_STATE_BUCKET }}
      TF_LOCK_TABLE: ${{ secrets.TF_LOCK_TABLE }}
```

- [ ] **Step 2: Verify YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/pr-validate.yml'))" && echo "YAML valid"
```
Expected: `YAML valid`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/pr-validate.yml
git commit -m "feat: add PR validation workflow (plan only, all envs)"
```

---

## Task 5: Create deploy-dev workflow

**Files:**
- Create: `.github/workflows/deploy-dev.yml`

- [ ] **Step 1: Create `.github/workflows/deploy-dev.yml`**

```yaml
name: Deploy — dev

on:
  push:
    branches: [dev]

jobs:
  deploy:
    name: Apply — dev
    uses: ./.github/workflows/_terraform.yml
    with:
      environment: dev
      apply: true
    secrets:
      AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}
      TF_STATE_BUCKET: ${{ secrets.TF_STATE_BUCKET }}
      TF_LOCK_TABLE: ${{ secrets.TF_LOCK_TABLE }}
```

- [ ] **Step 2: Verify YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/deploy-dev.yml'))" && echo "YAML valid"
```
Expected: `YAML valid`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/deploy-dev.yml
git commit -m "feat: add deploy workflow for dev environment"
```

---

## Task 6: Create deploy-qa workflow

**Files:**
- Create: `.github/workflows/deploy-qa.yml`

- [ ] **Step 1: Create `.github/workflows/deploy-qa.yml`**

```yaml
name: Deploy — qa

on:
  push:
    branches: [qa]

jobs:
  deploy:
    name: Apply — qa
    uses: ./.github/workflows/_terraform.yml
    with:
      environment: qa
      apply: true
    secrets:
      AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}
      TF_STATE_BUCKET: ${{ secrets.TF_STATE_BUCKET }}
      TF_LOCK_TABLE: ${{ secrets.TF_LOCK_TABLE }}
```

- [ ] **Step 2: Verify YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/deploy-qa.yml'))" && echo "YAML valid"
```
Expected: `YAML valid`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/deploy-qa.yml
git commit -m "feat: add deploy workflow for qa environment"
```

---

## Task 7: Create deploy-prod workflow

**Files:**
- Create: `.github/workflows/deploy-prod.yml`

Prod approval is enforced by the GitHub Environment named `production` configured in Pre-Sprint step E. When `inputs.environment == 'prod'` and `inputs.apply == true`, the reusable workflow sets `environment: production` on the job, which blocks execution until a required reviewer approves in the GitHub UI.

- [ ] **Step 1: Create `.github/workflows/deploy-prod.yml`**

```yaml
name: Deploy — prod

on:
  push:
    branches: [main]

jobs:
  deploy:
    name: Apply — prod
    uses: ./.github/workflows/_terraform.yml
    with:
      environment: prod
      apply: true
    secrets:
      AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}
      TF_STATE_BUCKET: ${{ secrets.TF_STATE_BUCKET }}
      TF_LOCK_TABLE: ${{ secrets.TF_LOCK_TABLE }}
```

- [ ] **Step 2: Verify YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/deploy-prod.yml'))" && echo "YAML valid"
```
Expected: `YAML valid`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/deploy-prod.yml
git commit -m "feat: add deploy workflow for prod environment (approval gate via GitHub Environment)"
```

---

## Task 8: Delete Jenkinsfile

- [ ] **Step 1: Delete Jenkinsfile**

```bash
git rm Jenkinsfile
```

- [ ] **Step 2: Commit**

```bash
git commit -m "chore: remove Jenkinsfile, replaced by GitHub Actions"
```

---

## Task 9: Update README.md

**Files:**
- Modify: `README.md`

Replace the README CI/CD section (add after the Outputs table):

- [ ] **Step 1: Add CI/CD section to `README.md`**

Append the following to `README.md`:

```markdown
## CI/CD

GitHub Actions deploys this module via the `examples/` directory using environment-specific tfvars.

| Branch | Environment | Behavior |
|--------|-------------|----------|
| `dev` | dev | Push triggers auto plan + apply |
| `qa` | qa | Push triggers auto plan + apply |
| `main` | prod | Push triggers plan; apply requires manual approval |
| Any PR | all three | Plan only — no apply |

### Secrets required (GitHub → Settings → Secrets → Actions)

| Secret | Description |
|--------|-------------|
| `AWS_ROLE_ARN` | IAM role ARN assumed via OIDC |
| `TF_STATE_BUCKET` | S3 bucket name for Terraform state |
| `TF_LOCK_TABLE` | DynamoDB table name for state locking |

### State layout in S3

```
s3://BUCKET/
  terraform/dev/terraform.tfstate
  terraform/qa/terraform.tfstate
  terraform/prod/terraform.tfstate
```

### One-time AWS bootstrap

See `docs/superpowers/plans/2026-05-11-github-actions-cicd.md` — Pre-Sprint section — for the exact commands to create the S3 bucket, DynamoDB table, OIDC provider, and IAM role.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add GitHub Actions CI/CD section to README"
```

---

## Verification

### Local smoke test (before pushing to GitHub)

```bash
# Validate all workflow YAML files
for f in .github/workflows/*.yml; do
  python3 -c "import yaml; yaml.safe_load(open('$f'))" && echo "$f — OK"
done

# Verify environment tfvars exist and have no overlapping CIDRs
grep vpc_cidr environments/*.tfvars

# Confirm Jenkinsfile is gone
ls Jenkinsfile 2>&1 | grep -c "No such file"
# Expected: 1
```

### End-to-end test

1. Push a commit to the `dev` branch
2. Go to GitHub → Actions → "Deploy — dev" — confirm the workflow runs and applies
3. Open a PR targeting `main` — confirm "PR Validate" runs all three plan jobs
4. Merge to `main` — confirm "Deploy — prod" pauses at the approval gate, then applies after approval
