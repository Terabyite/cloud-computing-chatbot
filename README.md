# **AI Chatbot Deployment on AWS Fully Automated**

## **Terraform Modules | Docker | EC2 ASG | ALB | CloudWatch | SSM | GitHub Actions**

This project is an end to end deployment of an AI Chatbot application on AWS using Infrastructure as Code (Terraform), Docker, EC2 Auto Scaling, CloudWatch monitoring, SSM remote execution, and GitHub Actions for CI/CD.

You do not run Terraform manually and you don’t SSH into servers.
Deployment happens automically when you push to main.

### **Main Features**
- Modular Terraform infrastructure
- Remote Terraform State stored in S3
- Application executed on EC2 using Systems Manager (SSM)
- NO SSH keys required
- Auto Scaling based on CPU Utilization
- Logs & metrics streamed to CloudWatch
- Fully automated deployment with GitHub Actions
- Dockerized Python chatbot
- HTTPS support with ACM
- DNS with Route53 → domain points to ALB

## **Architecture**
<img width="2025" height="1233" alt="terra" src="https://github.com/user-attachments/assets/2dcf776a-b3bc-4538-bc2d-2587a894cb3b" />

## **Infrastructure Breakdown**

| Component                    | Functions                                |
|------------------------------|------------------------------------------|
|**VPC Module**	               |Creates VPC, public/private subnets, IGW, NAT gw, routing|
|**Security Module**           |ALB SG, EC2 SG, ingress/egress control|
|**IAM Module**	               |EC2 role with SSM + CloudWatch + S3 permissions|
|**ALB Module**	               |Public load balancer, listeners, target groups & health checks|
|**ASG (EC2 Module)**	       |Auto Scaling Group and Launch Template for Docker app|
|**DNS Module	Route53**      |domain → ALB mapping|
|**ACM Module**	               |SSL certificate for HTTPS|
|**CloudWatch**	               |Metrics, log groups, container logs & dashboards|
|**Auto Scaling**              |Policies	CPU-based scaling triggers|
|**Remote Backend**	           |Terraform state stored safely in S3|


## **Terraform Modules Explained**

### **modules/vpc**

#### What it does:

**Creates**
|**VPC (Virtual Private Cloud)**|your private network in AWS.|
**Public subnets**             |subnets that can reach the internet directly for things like the ALB.
**Private subnets**            |subnets with no direct public IPs, used for EC2 instances in the Auto Scaling Group.
**Internet Gateway**           |allows traffic from public subnets to the internet.
**NAT Gateway**                |lets instances in private subnets reach the internet outbound only (for apt/pip updates), while still staying private.
**Route tables**               |define how traffic routes inside the VPC and to the internet.

### **modules/security**

#### What it does:
**Creates Security Groups (virtual firewalls) for:**
|**ALB security group**     | allows inbound HTTP/HTTPS (e.g. ports 80 and 443) from the internet.
|**EC2/ASG security group** | only allows inbound traffic from the ALB security group on the application port (e.g. 8080 or 80).
|**Optionally, an SSH security group for admin access (usually restricted by IP).**

### **modules/iam**

#### What it does:
**Creates IAM roles and policies for:**
- EC2 instances (for example, to read from S3, send logs to CloudWatch, or use SSM).
- Terraform itself (if you configured Terraform to assume a specific role).
- GitHub Actions (if using GitHub OIDC instead of long-lived AWS keys).

### **modules/alb**

#### What it does:
- Creates an Application Load Balancer (ALB) in the public subnets.
#### Configures:
- Listeners (e.g. port 80 for HTTP, 443 for HTTPS).
- Target groups that point to the Auto Scaling Group’s EC2 instances.
- Health checks to detect which instances are healthy.
#### Why it matters:
- Spreads traffic across multiple EC2 instances.
- Lets you use a clean domain like https://terabbyte.online/
- With HTTPS, terminates SSL using ACM certificate.

### **modules/asg**

#### What it does:
**Creates:**
- Launch Template or Launch Configuration for EC2 instances.
- Auto Scaling Group (ASG) that manages EC2 instances in the private subnets.
**The Launch Template typically:**
- Uses an AMI (e.g. Amazon Linux 2 or Ubuntu).
- Pulls your code or uses a deployment script to build/run the Docker container.
ASG is like a manager that says “we must always have N instances running”. If one dies, it creates another. If load increases, it can scale up more instances.

### **modules/dns**

#### What it does:
- Configures Route 53 DNS records.
- Creates a record like:
terabbyte.online an ALB DNS name
So instead of typing a long ALB URL, you use a simple domain.

### **modules/acm**

#### What it does:
- Requests or validates an ACM (AWS Certificate Manager) SSL/TLS certificate for your domain.
- The certificate is attached to the ALB’s HTTPS listener so users can reach: https://terabbyte.online/ with a browser “lock” icon.

## **Amazon EC2 (Elastic Compute Cloud) = virtual machine in the cloud.**

### In this project:
- The ASG manages EC2 instances.
**Each EC2 instance:**
- Runs Docker.
- Runs your chatbot container (from Dockerfile).
- Serves HTTP traffic on some port (e.g. 8080 or 80).
- The ALB forwards external requests to these EC2 instances.
So EC2 is where your chatbot app actually lives and runs.

## CloudWatch is integrated inside ASG

### Monitoring & Logs With CloudWatch enabled, you get:

|Log Type	                      |Source                                    |
|------------------------------|------------------------------------------|
|Application logs  | printed output from your Python app|
|Docker logs       |container stdout/stderr|
|ASG/EC2 metrics	 |CPU, memory (if enabled), network|
|Scaling events	   |scale up/down triggers|
|Health checks	   |from ALB|
|Dashboard/alarms	 |optional alerts|

## **CPU Auto Scaling**
Auto Scaling scales up/down based on CPU usage


## **Dockerfile**
- Builds a lightweight container
- Installs dependencies
- Copies project files
- Runs the chatbot server

## **GitHub Actions CI/CD (using SSM)**

### GitHub Secrets:
|Secret	                       |Purpose                                   |
|------------------------------|------------------------------------------|
|AWS_ACCESS_KEY_ID	           |authenticate GitHub to AWS                |
|AWS_SECRET_ACCESS_KEY	       |authenticate GitHub to AWS                |
|AWS_REGION	                   |sets default deployment region            |

No private key required
No SSH configuration
The EC2 instance only needs SSM + CloudWatch IAM role


## **Deployment Workflow**

|Step	                         |Trigger                                   |
|------------------------------|------------------------------------------|
|Push to main                  |GitHub workflow runs                      |
|Terraform executes	           |infrastructure updates                    |
|SSM connects to EC2	       |deploys and restarts container            |
|CloudWatch monitors app	   |autoscaling + logs visible                |

Fully automated zero-manual deployment pipeline.

## **How to Use This Project**

### **1. Prerequisites**
- AWS account.
- S3 bucket created for Terraform state (and optionally DynamoDB lock table).
**GitHub repository with:**
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
stored in GitHub Secrets.

### **2. Clone & Work Locally**
```sh
git clone https://github.com/Terabyite/cloud-computing-chatbot
cd cloud-computing-chatbot
```
### **3. Deploy**
Just push to main:
```sh
git add .
git commit -m "write whatever you like here"
git push origin main
```

## **Local Development**

```sh
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python chatdemo.py
```

Visit: http://localhost:8080

### 🧹 Cleanup (Avoid AWS Charges)

To delete all resources:

```sh
terraform destroy  auto approve
```
This removes:
- VPC
- NAT Gateway
- ALB
- EC2 + ASG
- IAM roles
- Route53 records
- ACM certificates

## **Project Repository**

### GitHub Repo: [here](https://github.com/Terabyite/cloud-computing-chatbot.git)

Repo contains:
- All Terraform code
- Modularized components
- Dockerfile
- CI/CD workflow
- Outputs for debugging

### .terraform/ and Terraform state files are intentionally excluded.


## **Deployed Resources on AWS (Screenshots)**

### **Auto Scaling Group**
<img width="1440" height="735" alt="Screenshot 2025-12-08 at 7 05 32 PM" src="https://github.com/user-attachments/assets/2982962d-9172-472d-8133-59cab70b11d3" />

### **CloudWatch**
<img width="1440" height="492" alt="Screenshot 2025-12-08 at 4 10 28 PM" src="https://github.com/user-attachments/assets/b06bd3ff-5f8d-4987-ad5e-d19d65087004" />

### **EC2 Instance**
<img width="1440" height="287" alt="Screenshot 2025-12-08 at 4 04 51 PM" src="https://github.com/user-attachments/assets/b266bfe0-af35-4519-a338-3eafc8b158f4" />

### **Identity and Access Management (IAM)**
<img width="1440" height="287" alt="Screenshot 2025-12-08 at 4 03 46 PM" src="https://github.com/user-attachments/assets/40991268-c680-4a52-adeb-440eb3406503" />

### **Security Groups**
<img width="1440" height="352" alt="Screenshot 2025-12-08 at 4 01 51 PM" src="https://github.com/user-attachments/assets/6e74c270-f092-4aed-a05a-92e571741292" />

### **Docker Container on one of the instance**
<img width="1440" height="769" alt="Screenshot 2025-12-08 at 7 08 32 PM" src="https://github.com/user-attachments/assets/298ef126-0947-4128-8c81-afa13b69f005" />

### **Hosted Zones**
<img width="1440" height="846" alt="Screenshot 2025-11-23 at 12 37 40 PM" src="https://github.com/user-attachments/assets/47dfece2-fecf-4968-91e0-16adbdebc9c1" />

### **Internet Gateway**
<img width="1440" height="238" alt="Screenshot 2025-11-23 at 12 41 37 PM" src="https://github.com/user-attachments/assets/2fe04cda-42c1-42c2-b162-c3c0ab999957" />

### **Load Balancer**
<img width="1440" height="287" alt="Screenshot 2025-12-08 at 4 05 23 PM" src="https://github.com/user-attachments/assets/de1534ad-8341-4495-b74e-bb8a1854d671" />

### **NAT Gateways**
<img width="1440" height="238" alt="Screenshot 2025-11-23 at 12 42 05 PM" src="https://github.com/user-attachments/assets/2d48394f-8dce-411c-81ac-22ccb0752322" />

### **Subnets**
<img width="1440" height="352" alt="Screenshot 2025-12-08 at 4 00 00 PM" src="https://github.com/user-attachments/assets/3e7a3a84-803e-46dd-b65c-eb012a448024" />

### **VPC**
<img width="1440" height="352" alt="Screenshot 2025-12-08 at 4 00 00 PM" src="https://github.com/user-attachments/assets/5ac28e5e-09fe-4839-bbf4-dc59d217f0b6" />

### **Running Chatbot UI**
<img width="1440" height="864" alt="Screenshot 2025-12-08 at 6 57 14 PM" src="https://github.com/user-attachments/assets/c154e064-d913-4a97-980f-4d0e0fe60b80" />




