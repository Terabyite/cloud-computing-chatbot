# **🚀 AI Chatbot Deployment on AWS (Terraform + EC2 + ALB + Auto Scaling)**

A fully automated, production grade deployment of a Python Tornado based AI chatbot application on AWS using Terraform.
This project demonstrates real world cloud engineering, including scalability, high availability, secure networking, and automated provisioning.

## **🧩 1. Project Overview**

### 🎯 Purpose

This project provisions and deploys a Python Tornado AI chatbot onto AWS using 100% Infrastructure as Code (Terraform).

The chatbot is a lightweight AI model using:
- Tornado for Web server
- NLTK for Natural language processing
- Keras + TensorFlow CPU – Deep learning model
- Bootstrap – Frontend UI

The goal is to run this app behind a secure, scalable AWS architecture featuring:
- Application Load Balancer
- Auto Scaling
- Private subnets + NAT
- ACM SSL + HTTPS
- Domain hosted on Route53


### 👥 Target Audience

This documentation is written for:
- Cloud Engineers deploying Python apps on AWS
- Developers modifying the chatbot code
- Administrators running and monitoring the application
- Students practicing AWS infrastructure projects


### 🏗 Core Technologies

| Component                     | Purpose                                  |
|------------------------------|------------------------------------------|
| **Amazon VPC**               | Secure, isolated network                 |
| **EC2 Auto Scaling Group**   | Runs and scales chatbot instances        |
| **Application Load Balancer (ALB)** | Traffic distribution + health checks |
| **AWS ACM**                  | SSL/TLS certificate for HTTPS            |
| **Amazon Route 53**          | Domain + DNS mapping to ALB              |
| **IAM Roles**                | Secure permissions for EC2               |
| **Terraform**                | Infrastructure automation                |`


## **🏛 2. Architecture**

<img width="2068" height="1525" alt="arc2" src="https://github.com/user-attachments/assets/2f98d6d4-79ed-45fe-a145-0e6f0ec10ab4" />

---

## 🔍 Component Breakdown

### 🖥 User Interface (UI)
- Web browser → HTTPS  
- Uses **https://terabbyte.online** or the ALB DNS  

---

### ⚙️ Backend Services
- Tornado Python web server  
- `systemd` ensures the chatbot stays alive  
- ALB health checks ensure only healthy instances receive traffic  

---

### 🛡 Networking
- EC2 instances in **private subnets**  
- ALB in **public subnets**  
- NAT Gateway enables outbound internet access  
- Security Groups restrict inbound/outbound traffic  

---

### 📦 Data & Application Code
- Chatbot cloned automatically from GitHub:  
  **https://github.com/edwincai/cloud-computing-chatbot.git**
- Python libraries installed:  
  - Tornado  
  - TensorFlow CPU  
  - Keras  
  - NLTK  
- NLTK data stored in:  
  `/usr/share/nltk_data`

---

## **⚙️ 3. Prerequisites & Setup**

### 🏢 AWS Requirements
You need:
- An AWS Account
- IAM user with permissions for:
  - EC2  
  - VPC  
  - ALB  
  - Route53  
  - ACM  
  - IAM  

---

### 💻 Local Machine Requirements

Install:
- Terraform **1.5+**
- AWS CLI
- Git

### Configure AWS credentials:

```sh
aws configure
```

### 📦 Deployment Steps

1️⃣ Initialize Terraform

```sh
terraform init
```
2️⃣ Review Deployment Plan
```sh
terraform plan
```
3️⃣ Deploy Infrastructure
```sh
terraform apply  auto approve
```

Terraform will deploy:
- VPC + subnets + NAT
- ALB with HTTPS
- Auto Scaling Group
- EC2 instances with full user data bootstrapping
- Route53 DNS → ALB mapping

### 🔧 Administrator Guide

Check chatbot service:

```sh
sudo systemctl status chatbot
```
View application logs:

```sh
sudo journalctl  u chatbot  n 50  no pager
```
Check if the app is listening:

```sh
sudo ss  ltnp | grep 8080
```
### 📈 Scaling

Managed automatically via Auto Scaling Group.

Modify in Terraform:

desired_capacity = 2
min_size         = 1
max_size         = 4

## **🛠 5. Troubleshooting & Maintenance**

### ❌ Issue: chatbot.service not found

Cause: User data failed before creating systemd service.
### Fix: Reordered and improved user data (install Python first, then dependencies).

### ❌ Issue: ModuleNotFoundError: No module named 'tornado'

Cause: TensorFlow installation consumed memory, killing pip mid install.
### Fix:
- Added swap space
- Used lightweight TensorFlow CPU 2.13.0

### ❌ Issue: Pip upgrade failing

Cause: System pip is RPM managed.
### Fix:
Use this instead of uninstalling pip:

python3  m ensurepip  upgrade

### ❌ Issue: 502 Bad Gateway from ALB

Cause: Target group had no healthy instances.
### Fix:
- Ensured chatbot listens on 0.0.0.0:8080
- Ensured systemd restarts the service automatically

### ❌ Issue: Auto Scaling Group stuck at 1/2 healthy

Cause: User data failed inconsistently.
### Fixes:
- Git clone retry logic
- Simplified pip installations
- Global NLTK data directory

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

## **📁 6. Project Repository**

### GitHub Repo:https://github.com/Terabyite/ Chatbot On AWS EC2

Repo contains:
- All Terraform code
- Modularized components
- User data script
- CI/CD workflow (optional, and will be updated later) 
- Outputs for debugging

### .terraform/ and Terraform state files are intentionally excluded.


## **📸 7. Deployed Resources on AWS (Screenshots)**

### **Auto Scaling Group**
<img width="1440" height="238" alt="Screenshot 2025-11-23 at 12 39 15 PM" src="https://github.com/user-attachments/assets/68f5223d-bdb3-4d44-ad9e-9e5b03541915" />

### **Hosted Zones**
<img width="1440" height="846" alt="Screenshot 2025-11-23 at 12 37 40 PM" src="https://github.com/user-attachments/assets/47dfece2-fecf-4968-91e0-16adbdebc9c1" />

### **Internet Gateway**
<img width="1440" height="238" alt="Screenshot 2025-11-23 at 12 41 37 PM" src="https://github.com/user-attachments/assets/2fe04cda-42c1-42c2-b162-c3c0ab999957" />

### **Load Balancer**
<img width="1440" height="202" alt="Screenshot 2025-11-23 at 12 38 44 PM" src="https://github.com/user-attachments/assets/5ab3ae16-ca8a-463a-be74-f67539a4f8a8" />

### **NAT Gateways**
<img width="1440" height="238" alt="Screenshot 2025-11-23 at 12 42 05 PM" src="https://github.com/user-attachments/assets/2d48394f-8dce-411c-81ac-22ccb0752322" />

### **Subnets**
<img width="1440" height="238" alt="Screenshot 2025-11-23 at 12 40 48 PM" src="https://github.com/user-attachments/assets/da67a624-ef7e-45a9-bfe7-1aab4056ce36" />

### **VPC**
<img width="1440" height="238" alt="Screenshot 2025-11-23 at 12 41 07 PM" src="https://github.com/user-attachments/assets/90d8dfb3-4cbf-4b59-a7cc-97b4414e9bea" />

### **Running Chatbot UI**
<img width="1440" height="846" alt="Screenshot 2025-11-23 at 12 33 52 PM" src="https://github.com/user-attachments/assets/ccb8f484-487a-4b50-b16f-f361086529eb" />






