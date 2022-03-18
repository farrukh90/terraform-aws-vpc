node {
    stage("Clone") {
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/farrukh90/terraform-aws-vpc.git']]])
    }
    stage("Terraform") {
        sh "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 713287746880.dkr.ecr.us-east-1.amazonaws.com"
        sh "docker pull 713287746880.dkr.ecr.us-east-1.amazonaws.com/tools:latest"
        sh "docker run  713287746880.dkr.ecr.us-east-1.amazonaws.com/tools:latest terraform init"
    }
}