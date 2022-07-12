terraform {
  required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.15.1"
        }
    }
}

# Configure the AWS provider 

provider "aws" {
    region     = "us-east-1"
    access_key = ACCESS_KEY
    secret_key = SECRET_KEY
}

# Create a VPC

resource "aws_vpc" "MyLab-VPC"{
    cidr_block = var.cidr_block[0] 


    tags = {
        Name = "MyLab-VPC"
 }  

}

# Create Subnet (Public)

resource "aws_subnet" "MyLab-Subnet1" {
    vpc_id     = aws_vpc.MyLab-VPC.id
    cidr_block = var.cidr_block[1]
    
    tags = {
        Name = "MyLab-Subnet1"
    }
}

# Create Internet Gateway 

resource "aws_internet_gateway" "MyLab-IntGW" {
    vpc_id = aws_vpc.MyLab-VPC.id

    tags = {
        Name = "MyLab-igw"
    }

}

# Create Security Group 

resource "aws_security_group" "MyLab_sec_Group" {
    name        = "MyLab Security Group"
    description = "Allow ingress and egress traffic to mylab"
    vpc_id      = aws_vpc.MyLab-VPC.id

    dynamic ingress {
        iterator        = port
        for_each        = var.ports
          content {
            from_port   = port.value
            to_port     = port.value
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]

          }
        
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allow traffic"
    }
}

# Create route table and association

resource "aws_route_table" "MyLab_RouteTable" {
    vpc_id = aws_vpc.MyLab-VPC.id 

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.MyLab-IntGW.id
    }

    tags = {
        Name = "MyLab_Routetable"
    }
}

resource "aws_route_table_association" "MyLab_Assn" {
    subnet_id = aws_subnet.MyLab-Subnet1.id
    route_table_id = aws_route_table.MyLab_RouteTable.id
}

# Create an AWS EC2 Instance 

resource "aws_instance" "Jenkins" {
    ami                         = var.ami
    instance_type               = "t2.micro"
    key_name                    = "aconner-key"
    vpc_security_group_ids      = [aws_security_group.MyLab_sec_Group.id]
    subnet_id                   = aws_subnet.MyLab-Subnet1.id
    associate_public_ip_address = true
    user_data                   = file("./InstallJenkins.sh")

    tags = {
        Name = "Jenkins-Server"
    }
}

# Create Ansible Controller 

resource "aws_instance" "AnsibleController" {
    ami                         = var.ami
    instance_type               = "t2.micro"
    key_name                    = "aconner-key"
    vpc_security_group_ids      = [aws_security_group.MyLab_sec_Group.id]
    subnet_id                   = aws_subnet.MyLab-Subnet1.id
    associate_public_ip_address = true
    user_data                   = file("./InstallAnsibleCN.sh")

    tags = {
        Name = "Ansible-ControlNode"
    }
}

# Create/Launch Ansible Managed Node to host Apache Tomcat server
resource "aws_instance" "AnsibleManagedNode1" {
    ami                         = var.ami
    instance_type               = "t2.micro"
    key_name                    = "aconner-key"
    vpc_security_group_ids      = [aws_security_group.MyLab_sec_Group.id]
    subnet_id                   = aws_subnet.MyLab-Subnet1.id
    associate_public_ip_address = true
    user_data                   = file("./AnsibleManagedNode.sh")

    tags = {
        Name = "AnsibleMN-ApacheTomcat"
    }
}
