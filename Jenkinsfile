pipeline {
  agent any

  stages {
    stage("Build") {
      steps {
        sh "docker build -t netlify/build:latest ."
        sh "docker build --squash -t netlify/build:squash ."
      }
    }

    stage("Push") {
      when {
        branch 'master'
      }
      steps {
        script {
          docker.image('netlify/build:latest').push()
          docker.image('netlify/build:squash').push()
        }
      }
    }
  }

  post {
    failure {
      slackSend color: "danger", message: "Build failed - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}/console|Open>)"
    }
    success {
      slackSend color: "good", message: "Build succeeded - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}/console|Open>)"
    }
  }
}
