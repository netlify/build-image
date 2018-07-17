pipeline {
  agent any

  stages {
    stage("Build Branch") {
      when {
        not { branch 'master' }
      }
      steps {
        sh "docker build -t netlify/build:${env.BRANCH_NAME} ."
        sh "docker build --squash -t netlify/build:squash-${env.BRANCH_NAME} ."
      }
    }

    stage("Build Tagged") {
      when {
        branch 'master'
      }
      steps {
        sh "docker build -t netlify/build:latest ."
        sh "docker build --squash -t netlify/build:squash ."
      }
    }

    stage("Push Tagged") {
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

    stage("Push Branch") {
      when {
        not { branch 'master' }
      }
      steps {
        script {
          docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-ci') {
            docker.image("netlify/build:${env.BRANCH_NAME}").push()
            docker.image("netlify/build:squash-${env.BRANCH_NAME}").push()
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
