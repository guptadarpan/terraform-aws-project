# Terraform DevOps Assignment
### Production-grade Infrastructure as Code with Staging and Production Environments

---

## Table of Contents
1. [What This Project Does]
2. [Project Structure]
3. [Architecture Overview]
4. [Decisions Made]
5. [Prerequisites]
6. [Manual Testing Instructions]
7. [Environment Switching]
8. [CI/CD Pipeline]
9. [Secrets and Security]
10. [Destroying Resources]

---

## What This Project Does

This project provisions isolated AWS infrastructure for two environments
— staging and production — using Terraform. Both environments are
completely separate: different VPCs, different IP ranges, different
state files, and different passwords. They share the same Terraform
module code to avoid duplication.

Each environment contains:
- A VPC with public and private subnets
- An EC2 bastion host (jump server) in the public subnet
- A Postgres RDS database in the private subnet
- Security groups restricting access to only what is necessary
- A remote backend storing state in S3 with DynamoDB locking

A GitHub Actions CI/CD pipeline automates all Terraform operations —
checking code on pull requests and deploying on merge or version tag.

---

## Project Structure
```
my-terraform-project/
│
├── modules/                    # Reusable Terraform modules
│   ├── vpc/                    # VPC, subnets, IGW, route tables, security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2/                    # EC2 bastion host with user data bootstrap
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── rds/                    # RDS Postgres instance and DB subnet group
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   ├── staging/                # Staging environment
│   │   ├── main.tf             # Calls all three modules
│   │   ├── backend.tf          # Remote state: s3 key = staging/terraform.tfstate
│   │   ├── variables.tf        # Variable declarations
│   │   ├── terraform.tfvars    # Staging values (git-ignored)
│   │     
│   └── production/             # Production environment
│       ├── main.tf             # Identical structure to staging
│       ├── backend.tf          # Remote state: s3 key = production/terraform.tfstate
│       ├── variables.tf
│       ├── terraform.tfvars    # Production values (git-ignored)
│       
│
├── .github/
│   └── workflows/
│       └── terraform.yml       # GitHub Actions CI/CD pipeline
│
├              
└── README.md                   # This file
```

---

## Architecture Overview
```
Internet
   │
   ▼
Internet Gateway
   │
   ▼
┌─────────────────────────────────────────────┐
│  VPC (10.0.0.0/16 staging / 10.1.0.0/16 prod) │
│                                               │
│  ┌─────────────────┐   ┌───────────────────┐  │
│  │  Public Subnet  │   │  Private Subnet   │  │
│  │                 │   │                   │  │
│  │  EC2 Bastion    │──▶│  RDS Postgres     │  │
│  │  (t2.micro)     │   │  (db.t3.micro)    │  │
│  │  SSH: your IP   │   │  port 5432:       │  │
│  │  only           │   │  bastion only     │  │
│  └─────────────────┘   └───────────────────┘  │
└─────────────────────────────────────────────┘
```

Your laptop SSHs into the bastion. The bastion is the only
machine that can reach the database. The database has no
public IP and no route to the internet.

---

## Decisions Made

### Why Modules?

The same infrastructure pattern (VPC + bastion + RDS) is needed
in both staging and production. Writing it twice would mean
maintaining two copies — any bug fix or improvement would need
to be applied twice, and they could drift apart over time.

Modules solve this by writing the logic once and calling it
with different values per environment. This is the DRY
principle — Don't Repeat Yourself.

### Why Separate Environment Folders Instead of Workspaces?

Terraform workspaces are an alternative approach but they share
the same backend configuration and can be confusing for teams.
Separate folders give each environment a completely independent
state file and backend config, making it impossible for a
staging run to accidentally modify production.

The tradeoff is a small amount of repeated structure
(variables.tf is nearly identical across environments) but
the isolation benefit outweighs this.

### Why S3 + DynamoDB for Backend?

The default local backend stores state on your laptop. This
breaks in two scenarios — if you work in a team (two people
running apply simultaneously causes state corruption) and
in CI/CD (the runner machine is ephemeral and discards state
after every run).

S3 stores the state file remotely so every run — local or
CI/CD — reads and writes the same source of truth. DynamoDB
adds a lock so only one apply can run at a time, preventing
concurrent modification.

### How Are Secrets Handled?

Three layers of secret protection are used:

**Layer 1 — .gitignore**: The `terraform.tfvars` files
containing passwords are excluded from git entirely. They
exist only on the developer's local machine.

**Layer 2 — GitHub Secrets**: Sensitive values (DB passwords,
AWS credentials, IP address) are stored as encrypted GitHub
Secrets. The CI/CD pipeline injects them as environment
variables at runtime using `${{ secrets.NAME }}` syntax.
They are never written into any file that touches git.

**Layer 3 — Terraform sensitive variables**: Variables
holding passwords are marked `sensitive = true` in
`variables.tf`. This prevents Terraform from printing
their values in plan and apply output, protecting against
accidental exposure in logs.

### Why Is RDS Not Publicly Accessible?

The `publicly_accessible = false` setting on the RDS instance
means AWS does not assign it a public IP address. Even if
the security group were misconfigured, the database could
not be reached from the internet because there is no
network path to it.

Access is only possible by first connecting to the bastion
host, which is in the same VPC as the database and has the
bastion security group attached — which the RDS security
group explicitly trusts on port 5432.

### Why Does the Bastion Use User Data?

User data is a script that runs automatically the first time
an EC2 instance boots. It is used here to install the
Postgres client and other tools on the bastion so it is
immediately useful without any manual SSH configuration
after launch. This is called bootstrapping.

---

## Prerequisites

Before running this project we need the following installed
and configured on your machine:

| Tool | Version | Purpose |
|---|---|---|
| Terraform | >= 1.7.0 | Infrastructure provisioning |
| AWS CLI | >= 2.0 | AWS authentication |
| Git | any | Version control |

  We also need:
- An AWS account with Free Tier access
- An IAM user with AdministratorAccess and access keys configured
  via `aws configure`
- An S3 bucket named `terraform-state-darpan-2026` with
  versioning enabled
- A DynamoDB table named `terraform-lock` with partition key
  `LockID` (String)
- An EC2 key pair named `my-key-pair` saved at `~/.ssh/my-key-pair.pem`

---

## Manual Testing Instructions

Follow these steps exactly to test the project locally.

### Step 1 — Clone the repository
```bash
git clone https://github.com/guptadarpan/terraform-devops-assignment.git
cd terraform-devops-assignment
```

### Step 2 — Create your tfvars file
```bash
cd environments/staging
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and fill in your values:
- Replace `YOUR_PUBLIC_IP_HERE` with your IP
  (run `curl -s https://checkip.amazonaws.com` to find it)
- Replace the db_password with a strong password of your choice

### Step 3 — Initialise Terraform
```bash
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 4 — Check formatting
```bash
terraform fmt -check -recursive
```

No output means all files are correctly formatted.
If you see file names printed, run `terraform fmt -recursive`
to auto-fix them.

### Step 5 — Validate the configuration
```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### Step 6 — Preview what will be created
```bash
terraform plan \
  -var="db_password=YourPassword123!" \
  -var="my_ip=$(curl -s https://checkip.amazonaws.com)"
```

Review the plan output. You should see 10 resources planned
with a `+` sign. No resources should show `-` (destroy) or
`~` (modify) on a fresh run.

### Step 7 — Apply (creates real AWS resources)
```bash
terraform apply \
  -var="db_password=YourPassword123!" \
  -var="my_ip=$(curl -s https://checkip.amazonaws.com)"
```

Type `yes` when prompted. This takes 10-15 minutes because
RDS takes time to provision.

When complete you will see:
```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:
bastion_public_ip = "x.x.x.x"
rds_endpoint      = "staging-postgres-db.xxxx.rds.amazonaws.com:5432"
```

### Step 8 — Verify the bastion is reachable
```bash
ssh -i ~/.ssh/my-key-pair.pem ec2-user@<bastion_public_ip>
```

You should get a Linux shell prompt on the bastion. Type
`exit` to disconnect.

### Step 9 — Verify the database is reachable from the bastion

While SSH'd into the bastion, run:
```bash
psql -h <rds_endpoint_without_port> -U adminuser -d appdb
```

Enter your db_password when prompted. You should see the
Postgres prompt `appdb=>`. Type `\q` to exit.

### Step 10 — Destroy everything when done
```bash
terraform destroy \
  -var="db_password=YourPassword123!" \
  -var="my_ip=$(curl -s https://checkip.amazonaws.com)"
```

Type `yes` when prompted. Always destroy after testing to
avoid unexpected AWS charges.

---

## Environment Switching

The project uses separate folders for each environment.
Switching is done by changing directory.

**Work on staging:**
```bash
cd environments/staging
terraform init
terraform plan   -var="db_password=xxx" -var="my_ip=xxx"
terraform apply  -var="db_password=xxx" -var="my_ip=xxx"
```

**Work on production:**
```bash
cd environments/production
terraform init
terraform plan   -var="db_password=xxx" -var="my_ip=xxx"
terraform apply  -var="db_password=xxx" -var="my_ip=xxx"
```

The two environments are completely isolated:

| What | Staging | Production |
|---|---|---|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| State file | s3://.../staging/terraform.tfstate | s3://.../production/terraform.tfstate |
| Resource names | staging-vpc, staging-bastion | production-vpc, production-bastion |
| DB password | separate secret | separate secret |

Running `terraform apply` in staging **never touches** production
because the state files are completely separate. Terraform only
modifies resources it knows about from its own state file.

---

## CI/CD Pipeline

The pipeline lives in `.github/workflows/terraform.yml` and
has three triggers:

**On Pull Request → main:**
Runs `terraform fmt -check`, `terraform validate`, and
`terraform plan` for both environments. Results appear
directly in the PR so reviewers can see what infrastructure
changes are proposed before approving.

**On merge to main:**
Runs `terraform apply` on the staging environment only.
This means every merged PR is automatically deployed to
staging for testing.

**On version tag (v*.*.*):**
Runs `terraform apply` on the production environment.
To deploy to production:
```bash
git tag v1.0.0
git push origin v1.0.0
```

This design means staging is always up to date with main,
and production is only updated deliberately via a tagged release.

---

## Secrets and Security

The following secrets must be configured in
GitHub → Settings → Secrets and variables → Actions:

| Secret name | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `STAGING_DB_PASSWORD` | Postgres password for staging |
| `PROD_DB_PASSWORD` | Postgres password for production |
| `MY_IP` | Your public IP for SSH access |

None of these values appear anywhere in the codebase.
The `.tfvars` files are excluded by `.gitignore`.

---

## Destroying Resources

Always destroy resources after testing to stay within
the AWS Free Tier and avoid charges.

**Destroy staging:**
```bash
cd environments/staging
terraform destroy -var="db_password=xxx" -var="my_ip=xxx"
```

**Destroy production:**
```bash
cd environments/production
terraform destroy -var="db_password=xxx" -var="my_ip=xxx"
```

Type `yes` when prompted. Verify in the AWS Console
that no EC2 instances or RDS instances remain running.# terraform-aws-project
