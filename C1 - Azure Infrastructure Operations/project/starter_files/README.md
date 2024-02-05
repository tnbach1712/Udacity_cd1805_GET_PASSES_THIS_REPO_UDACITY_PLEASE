# Introduce IaC to create Infrastructure for web applications
This repository provides Infrastructure as Code (IaC) scripts to create the necessary infrastructure for deploying a web application. By leveraging IaC, you can automate the provisioning and configuration of your infrastructure, making it easier to manage and deploy your web application.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)


## Getting Started

### 1. Config, Build and push a Image use base image Ubuntu image 18.04 to Azure Image
  - Open file `server.json`
  - Replace or set variable values with your configuration
      ```
      "variables": {
        "client_id": "{{env `ARM_CLIENT_ID`}}",
        "client_secret": "{{env `ARM_CLIENT_SECRET`}}",
        "subscription_id": "{{env `ARM_SUBSCRIPTION_ID`}}",
        "tenant_id": "{{env `ARM_TENANT_ID`}}"
      }
      ```
  - Go to Azure Console and Upload this file
  - Run `Packer build` to buid and upload image to Azure
  - After comand run success, your image id is `/subscriptions/{{YOUR_SUBSCRIPTION_ID}}/resourceGroups/{{RESOURCE_GROUP_NAME}}/providers/Microsoft.Compute/images/{{YOUR_IMAGE_NAME}}`


### 2. Config, Build Isnfrastructue use terraform
---------------------------------------------------------------- 
  #### Variables
  Variable Descriptions
  Here are the descriptions of the variables available in your Terraform configuration:

  - subscription_id: This variable represents the Subscription ID and is of type string. It is used to specify the Subscription ID where your resources will be provisioned.

  - resource_group: This variable represents the Resource Group name and is of type string. It has a default value of "bachtn-demo" but can be overridden if needed. It is used to specify the name of the Resource Group where your resources will be created.

  - location: This variable represents the Azure region location and is of type string. It has a default value of "westus" but can be changed to the desired Azure region. It is used to specify the region where your resources will be deployed.

  - tags: This variable represents the tags for your resources and is of type map(string). It has a default value of {"env" = "Udacity-01"} but can be modified to include additional tags. It is used to apply tags to your Azure resources.

  - address_space: This variable represents the address space for your virtual network and is of type list(string). It has a default value of ["10.0.0.0/16"] but can be adjusted based on your requirements. It is used to define the IP address range for your virtual network.

  - dns_server: This variable represents the DNS servers for your virtual network and is of type list(string). It has a default value of ["10.0.0.4", "10.0.0.5"] but can be modified as needed. It is used to specify the DNS servers for your virtual network.

  - subnets: This variable represents the subnets for your virtual network and is of type list(object). Each subnet object consists of the following properties: name, address_prefix, and network_security_group (optional). The name property represents the name of the subnet, the address_prefix property represents the IP address range for the subnet, and the network_security_group property (optional) represents the name of the Network Security Group associated with the subnet. The variable has a default value of two subnets, "subnet1" and "subnet2", with their respective address prefixes. It is used to define the subnets within your virtual network.

  - admin_username: This variable represents the administrator username for your virtual machine and is of type string. It is used to specify the username for the administrator account on the virtual machine.

  - admin_password: This variable represents the administrator password for your virtual machine and is of type string. It is marked as sensitive to prevent displaying the password in the Terraform output. It is used to specify the password for the administrator account on the virtual machine.

  - image_name: This variable represents the name of the virtual machine image and is of type string. It is used to specify the name of the virtual machine image to be used for provisioning.

  #### Using Variables
  To use these variables in your Terraform configuration, you can reference them by their names. For example, to use the subscription_id variable, you can use var.subscription_id in your configuration file.

  You can also override the default values of variables by providing values when running Terraform commands. For example, you can use the -var flag to specify a different value for the resource_group variable: terraform apply -var="resource_group=my-resource-group".

  Example: 
  - Replace your config in file `terraform.tfvars`

    ```
    admin_username = "bachtn3"
    admin_password = "!6Den10kytu"
    location       = "Australia Southeast"
    subscription_id = "xxxxxxx-xxx-xxxxx-xxxx"
    image_name = "myPackerImage-Ubuntu-18_04"
    ```
  Remember to update the values of the variables according to your specific requirements before running any Terraform commands.
  
  #### How to use:
  - Run `terraform init`
  - Update variables with your config
  - Run `terraform valid` to check config is valid or not
  - Run `terraform plan` to see all resource will create/update or destroy when apply this config
  - To apply run `terraform apply`
  - If you want to remove `terraform destroy`

  #### Ouput
  - Use `terraform plan -o solution.plan` to export file 
