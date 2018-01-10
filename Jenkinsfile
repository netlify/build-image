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
      failFast true
      parallel {
          stage("Push Squash") {
              steps {
                  sh "docker push netlify/build:squash"
              }
          }
          stage("Push Latest") {
              steps {
                  sh "docker push netlify/build:squash"
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
