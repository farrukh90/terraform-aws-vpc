node {
    stage("Clone") {
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/farrukh90/terraform-aws-vpc.git']]])
    }
}