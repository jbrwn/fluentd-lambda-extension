# fluentd-lambda-extension Examples

We are using this place to have a quick test to verify everything changed is still working as expected. And we don't use SSH to connect to instance, we are using SSM Session Manager.

## Preparing

### AWS credentials
Make sure you can access AWS resources by using AWS CLI

### Install AWS SSM plugin for CLI
```
https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
```

## Terraform Command
```hcl
terraform plan
terraform apply
```

## Ansible Command

```
ansible-playbook -i <INSTANCE_ID>, ansible/config.yml -v
```
