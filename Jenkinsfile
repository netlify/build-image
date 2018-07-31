pipeline {
  agent any

  stages {
    stage("Build") {
      when {
        not { branch 'master' }
      }
      steps {
        sh "docker build --build-arg NF_IMAGE_VERSION=${env.GIT_COMMIT} ."
      }
    }

    stage("Build Tagged") {
      when {
        branch 'master'
      }
      steps {
        sh "docker build --build-arg NF_IMAGE_VERSION=${env.GIT_COMMIT} -t netlify/build:latest ."
        sh "docker build --build-arg NF_IMAGE_VERSION=${env.GIT_COMMIT} --squash -t netlify/build:squash ."
      }
    }

    stage("Push") {
      when {
        branch 'master'
      }
      steps {
        script {
          docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-ci') {
            docker.image('netlify/build:latest').push()
            docker.image('netlify/build:squash').push()
          }
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
