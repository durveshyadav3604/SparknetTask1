# 🧩 Luggage Bags Full-Stack DevOps Migration Challenge

**Azure → AWS (Free Tier)**

## 📌 Project Overview

This repository contains a **full-stack web application** (Frontend + Backend) that has been **intentionally misconfigured** and deployed on **Microsoft Azure**.

The primary objective of this project is to evaluate and strengthen an intern’s practical skills in:

* Debugging real-world DevOps issues
* Containerization and image management
* Cloud infrastructure understanding
* Migration from **Azure** to **AWS (Free Tier only)**

This is **not a greenfield project**. It reflects real production-like challenges faced by DevOps engineers.

---

## 🎯 Objective

As an intern, your task is to:

1. **Analyze** the existing Azure-based deployment
2. **Identify and resolve** configuration and deployment issues
3. **Rebuild and redeploy** the complete application on **AWS Free Tier**
4. Ensure the application works correctly end-to-end after migration

> ⚠️ The project contains **intentional errors and misconfigurations**.
> You are expected to **find and fix them independently**.

---

## 🏗️ Application Architecture

* **Frontend**

  * React application
  * Served via Nginx
  * Containerized using Docker

* **Backend**

  * Node.js + Express REST API
  * MongoDB integration
  * Containerized using Docker

* **Infrastructure**

  * Original deployment on **Azure Container Instances**
  * CI/CD and Infrastructure as Code concepts included
  * Target platform: **AWS Free Tier**

---

## ☁️ Migration Requirements

You must redeploy the application on AWS using **only Free Tier eligible services**, such as:

* EC2 / ECS (with EC2 launch type)
* Application Load Balancer (if required)
* Security Groups
* IAM Roles
* Docker Hub or ECR
* Amazon Linux–based instances

> ❌ Paid AWS services are **not allowed**

---

## 🔧 Your Responsibilities

* Debug frontend ↔ backend communication
* Fix container build and runtime issues
* Resolve networking and CORS-related problems
* Ensure correct environment configuration **without modifying `.env` files**
* Rebuild Docker images correctly
* Push and pull images from a container registry
* Deploy securely and reliably on AWS
* Validate application functionality after deployment

---

## ✅ Expected Outcome

After successful completion:

* Frontend should be publicly accessible
* Backend API should be reachable and functional
* API requests (e.g., placing orders) should work without errors
* Application should run **entirely on AWS Free Tier**
* Deployment should be stable and reproducible

---

## 📦 Deliverables

You are expected to provide:

1. AWS deployment details (services used)
2. Screenshots or logs proving successful deployment
3. Public URLs (Frontend & Backend)
4. Brief explanation of issues faced and how they were resolved
5. Updated deployment documentation (if applicable)
