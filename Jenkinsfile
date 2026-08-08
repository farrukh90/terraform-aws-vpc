properties([
  parameters([
    string(
      name: 'AWS_ACCOUNT',
      description: 'AWS account ID for ECR registry (required)',
      trim: true
    )
  ])
])

node {
  def REPOLOCATION = 'https://github.com/farrukh90/terraform-aws-vpc.git'
  def BRANCHNAME   = "master"
  def TF_IMAGE     = "${params.AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/tools:latest"

  stage("Clean Up") {
    sh "docker image prune --force"
  }

  stage("Pull Docker Image") {
    sh """
      aws ecr get-login-password --region us-east-1 \
        | docker login --username AWS --password-stdin \
            ${params.AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com
    """
    sh "docker pull ${TF_IMAGE}"
  }

  stage("Clone") {
    checkout([
      $class: 'GitSCM',
      branches: [[name: "*/${BRANCHNAME}"]],
      extensions: [],
      userRemoteConfigs: [[url: REPOLOCATION]]
    ])
  }

  withDockerContainer(image: TF_IMAGE) {
    stage("Initialize") {
      sh "terraform init -input=false"
    }

    stage("Validate") {
      sh "terraform validate"
    }

    stage("Plan") {
      sh "terraform plan -out=tfplan -input=false"
    }
  }

  stage("Approval") {
    timeout(time: 10, unit: 'MINUTES') {
      input message: "Review the Terraform plan above. Approve to apply?", ok: "Apply"
    }
  }

  withDockerContainer(image: TF_IMAGE) {
    stage("Apply") {
      sh "terraform apply -input=false tfplan"
    }
  }

  withDockerContainer(image: 'python:3.8') {
    stage("Python Analysis Test") {
      sh "python --version"
    }
  }

  stage("Email Notification") {
    sh "echo 'Pipeline complete'"
  }
}
