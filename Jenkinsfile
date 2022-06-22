pipeline {
  agent any
  stages {
    stage('Test') {
      steps {
        sh '''#dir=`echo $JOB_NAME | sed \'s/\\//_/g\'`
dir=\'aes-circom_feat_script\'
cd /var/lib/jenkins/workspace/$dir
docker build -t aes_circom . 
docker rmi -f aes_circom:latest
echo "Tested Successfully"
'''
      }
    }

  }
}