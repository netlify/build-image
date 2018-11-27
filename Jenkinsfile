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
        sh "docker build --build-arg NF_IMAGE_VERSION=${env.GIT_COMMIT} -t netlify/build:latest -t netlify/build:${env.GIT_COMMIT} -t netlify/build:${env.GIT_TAG} ."
        sh "docker build --build-arg NF_IMAGE_VERSION=${env.GIT_COMMIT} --squash -t netlify/build:squash -t netlify/build:${env.GIT_COMMIT}-squash -t netlify/build:${env.GIT_TAG}-squash ."
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
            docker.image("netlify/build:${env.GIT_COMMIT}").push()
            docker.image("netlify/build:${env.GIT_TAG}").push()
            docker.image('netlify/build:squash').push()
            docker.image("netlify/build:${env.GIT_COMMIT}-squash").push()
            docker.image("netlify/build:${env.GIT_TAG}-squash").push()
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
