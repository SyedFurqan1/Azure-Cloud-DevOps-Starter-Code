 Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction (This ReadMe applies to the folder C1 - Azure Infrastructure Operations)
This project is designed to create a Packer template and Terraform template to deploy a customizable, scalable web server in Azure. You can also optionally deploy a custom Azure policy using Azure CLI which will deny any deployment of indexed resources if it does not contain a tag.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Getting Started
1. Clone this repository.

2. Ensure you have the above mentioned dependencies fulilled.

3. Deploy a custom policy in Azure which denies deployment of any indexed resource not containing a tag.

4. Create and deploy a custom Image in your Azure account using Packer.

5. Deploy a scalable web server and it's surrounding infrastucture using Terraform. 

### Instructions

#### Creating an Azure Policy
Once you have the dependencies fulfilled we can move on to creating an Azure policy.

Navigate to the path ```C1 - Azure Infrastructure Operations/project/policies```. At this point we would like to ensure that we have logged in to the Azure CLI and the command ``` az account list ``` should display our account information.

Next, we will create an Azure Policy definition using the command:

1. ```az policy definition create --name "tagging-policy-general" --description "Deny the deployment of any indexed resource if it does not have a tag." --display-name "Deny Resources if not tagged" --mode "Indexed" --rules ./deny-deployment-if-not-tagged.json ```

After creating this policy definition we will then assign this policy to any resource group or subscription:

2. ```az policy assignment create --name "tagging-policy" --description "Assignment of the policy of denying any deployment of any indexed resource if it does not have a tag." --display-name "Assignment of denying deployment of resources if not tagged" --policy "tagging-policy-general"```

Notice in the above command we have not specified any ```--scope``` parameter hence the above policy assignment would scope all over the subscription that you would be working with.


#### Creating a Image and Deploying/Storing it to our Azure account using Packer

For this part you should navigate to ```C1 - Azure Infrastructure Operations/project/Packer template```.

Now you can move on to creating your custom image - the packer template that is included in the repository creates a simple hello world webser using nohup busybox and httpd. 

As a source of our image, we will be using Ubuntu 18.04 LTS - if you wish to use any other Linux flavour OR any other OS then feel free to change the information in the packer template json file. (The fields ```os_type, image_publisher, image_offer, image_sku``` can be changed.

**(Optional)** If you wish to pick a third party image from Azure marketplace you might want to include the plan information in the ```builders``` section of the Packer template). For example;

```
      "plan_info": {
        "plan_name": "centos-7-8-free",
        "plan_product": "centos-7-8-free",
        "plan_publisher": "cognosys"
      }
```

Before we move on to creating the image, we can ensure that we know the following variables;

1. Your Subscription ID.
2. Resource group name (Should be already present in your Azure account, this is the resource group which would contain our image. You can create this resourece group using Azure CLI or Azure Portal).
3. Name of the custom image that you are creating.

Optionally, you can also change other things in the Packer template if you wish to, like ```location, vm_size, azure_tags ```.

Run the following command to create your custom VM image (fill in your variables);

```packer build -var 'subscription_id=<YOUR SUBSCRIPTION ID>' -var 'managed_image_resource_group=<NAME OF THE RESOURCE GROUP>' -var 'managed_image=<NAME YOUR IMAGE>' server.json```

The above command might require you to authenticate Packer to log in to your Azure account.


#### Creating reliable IaaS Webserver on Azure using Terraform

Creating a reliable webserver using the included Terraform files is very simple. These VMs will use the Packer image that you have created and deployed on your Azure account.

Before moving on to initializing Terraform we can ensure that we have the following variable values for our usecase; 

*  ```prefix```  = Add any prefix here for your deployment, this will be used to name the resources being created.
* ```name_rg``` = Name of the resource group that will be created for your resources to be deployed in.
* ```location_rg``` = The location of the Resource Group. The Azure Region. (Defaults to UAE North)
* ```number of VMs``` = The number of virtual machines to be created/provisioned. (uses availability set).
* ```VM_admin_username``` = The username of admin for your VM.
* ```VM_admin_password``` = The password of the admin user.
* ```custom_image_name``` = The name of the server template custom image that was created using packer earlier. 
* ```custom_image_rg``` = The name of the resource group the server template custom image is stored in.

To avoid passing these variables on run time you can configure default values of these variables in the ```variables.tf``` file.

To create the resources, navigate to the folder ```C1 - Azure Infrastructure Operations/project/Terraform```.

1. **Initialize Terraform**

Run the command: ``` terraform init ```

2. **Plan your output and review changes**

Run the command: ``` terraform plan ``` 

Optionally, you can choose to store your output by appending the ```-out``` parameter in the above command.

3. **Create your resources**

Run the command: ```Terraform apply```

Done! Your resources would be created.


### Output

* A custom policy that denies any deployment of Indexed resources in your Azure account. You can confirm this by running the command ``` az policy assignment list -o table ``` to confirm if your policy has been created and assigned to whatever scope you wanted. A sample output PNG is stored in the policies folder as a reference.

* A custom VM image using Packer. You can review this image on the Azure portal or Azure CLI. 

* A reliable webserver infrastructure on Azure. An example plan file (```solution.plan```) is included in the ```Terraform``` folder of this repository. 
