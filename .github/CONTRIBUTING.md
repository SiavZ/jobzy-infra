# Contributing to Jobzy Infrastructure

Thank you for contributing to the Jobzy infrastructure repository!

## Getting Started

1. Clone the repository
2. Install prerequisites (Terraform, gcloud CLI, kubectl)
3. Set up your GCP credentials
4. Read the [Setup Guide](../docs/SETUP.md)

## Development Workflow

1. Create a feature branch from `main`
2. Make your changes
3. Test your changes locally:
   ```bash
   terraform fmt -recursive
   terraform validate
   terraform plan -var-file="environments/dev.tfvars"
   ```
4. Commit your changes with descriptive messages
5. Push to your branch and create a Pull Request

## Terraform Standards

- Use consistent formatting (`terraform fmt`)
- Add comments for complex logic
- Follow the module structure
- Update documentation when making changes
- Use variables for configurable values
- Never commit sensitive data or credentials

## Testing

- Always run `terraform plan` before applying
- Test in dev environment first
- Verify outputs and connectivity
- Check resource labels and naming conventions

## Pull Request Process

1. Ensure all tests pass
2. Update documentation if needed
3. Get approval from infrastructure team
4. Squash commits before merging

## Code of Conduct

- Be respectful and professional
- Focus on constructive feedback
- Help others learn and grow
