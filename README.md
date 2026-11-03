# AWS Multi-AZ Architecture with Terraform

A highly available three-tier AWS architecture built with Terraform while preparing for the University of Houston Cloudathon.

## Overview

This project was designed to practice cloud architecture around common business requirements including:

- High availability
- Scalability
- Network isolation
- Database resiliency
- Secure administration
- Repeatable infrastructure deployment

## Architecture

The environment follows a multi-AZ three-tier design:

**Internet → Application Load Balancer → Private EC2 Auto Scaling Group → Amazon Aurora MySQL**

### Networking

- VPC spanning two Availability Zones
- Public subnets for the Application Load Balancer and NAT Gateways
- Private subnets for EC2 application servers
- Isolated database subnets for Amazon Aurora
- Separate NAT Gateways provide outbound connectivity for private resources

### Compute

- Amazon EC2 instances deployed through a Launch Template
- Auto Scaling Group distributes instances across multiple Availability Zones
- Application Load Balancer performs health checks and distributes incoming traffic
- Rolling instance refreshes support infrastructure updates while maintaining healthy capacity

### Security

- EC2 instances are not directly exposed to the internet
- Security groups restrict communication between infrastructure tiers
- Application traffic follows:

`Internet → ALB → EC2 → Aurora`

- AWS Systems Manager provides instance administration without requiring public SSH access
- IMDSv2 is required for EC2 instance metadata access

### Database

- Amazon Aurora MySQL cluster distributed across isolated database subnets
- Writer and reader instances support availability and failover
- Storage encryption and automated backups are enabled
- Database instances are not publicly accessible
- AWS Secrets Manager manages the database master password

## Design Decisions

### Multi-AZ Deployment

Resources are distributed across multiple Availability Zones to reduce the impact of a single-AZ failure and improve application availability.

### Public Load Balancer, Private Compute

The Application Load Balancer is placed in public subnets while EC2 instances remain in private subnets.

This allows users to access the application without exposing the compute layer directly to the internet.

### Separate NAT Gateways

Each private application subnet uses a NAT Gateway in its corresponding Availability Zone.

This avoids creating a cross-AZ dependency for outbound traffic and improves fault tolerance if one Availability Zone becomes unavailable.

### Auto Scaling Group

EC2 instances are managed by an Auto Scaling Group rather than deployed individually.

This provides:

- Automatic instance replacement
- Horizontal scaling
- Multi-AZ distribution
- Integration with Application Load Balancer health checks

### Application-Level Health Checks

The Auto Scaling Group uses Elastic Load Balancing health checks so instances can be replaced when the web application becomes unhealthy, even if the EC2 instance itself is still running.

### Isolated Database Tier

Aurora is deployed in dedicated database subnets without a direct route to the internet.

Only resources using the application security group are allowed to connect to the database on the MySQL port.

### Security Group Referencing

Security groups reference other security groups rather than allowing broad internal CIDR ranges.

The intended traffic flow is:

`Internet → ALB Security Group → Web Security Group → Database Security Group`

This limits communication between infrastructure tiers.

### AWS Systems Manager Instead of SSH

The EC2 instances use AWS Systems Manager for administration.

This removes the need to expose SSH to the public internet and allows access to be controlled using IAM.

### IMDSv2

The EC2 Launch Template requires IMDSv2 for access to instance metadata and IAM role credentials.

### AWS Secrets Manager

Aurora manages the database master password through AWS Secrets Manager rather than storing a static password directly in the Terraform configuration.

### Aurora MySQL

Amazon Aurora MySQL was selected to provide managed database replication, availability, backups, and failover capabilities while reducing the operational overhead of managing database replication manually.

### Rolling Instance Refresh

Launch Template changes can trigger rolling instance replacement while maintaining healthy application capacity.

This reduces disruption during infrastructure updates.

### Terraform State vs Auto Scaling

Terraform defines the Auto Scaling Group configuration while AWS Auto Scaling is allowed to dynamically change desired capacity.

Terraform ignores changes to desired capacity so it does not attempt to undo scaling decisions made by the Auto Scaling service.

### Infrastructure as Code

Terraform is used to provision the environment so infrastructure can be:

- Version controlled
- Recreated consistently
- Reviewed before deployment
- Modified through code instead of undocumented console changes

## Technologies

- Amazon VPC
- Amazon EC2
- Application Load Balancer
- EC2 Auto Scaling
- Amazon Aurora MySQL
- AWS IAM
- AWS Systems Manager
- AWS Secrets Manager
- NAT Gateway
- Terraform
- Amazon Linux
- Apache

## Project Goals

This project was built to strengthen my understanding of not only how AWS services are configured, but why specific architecture choices are made based on availability, security, scalability, and operational requirements.
