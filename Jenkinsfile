pipeline {
  agent any

  stages {
    stage("Test Build") {
      when {
        not { anyOf { branch 'staging' ; branch 'xenial' ; branch 'trusty  ' ; buildingTag() } }
      }
      steps {
        sh "docker build --build-arg NF_IMAGE_VERSION=${env.GIT_COMMIT} ."
      }
    }

    stage("Build Tags and Special Branches") {
      when {
        anyOf { branch 'staging' ; branch 'xenial' ; branch 'trusty' ; buildingTag() }
      }
      steps {
        sh "docker build --build-arg NF_IMAGE_VERSION=${env.GIT_COMMIT} --build-arg NF_IMAGE_TAG=${env.BRANCH_NAME} -t netlify/build:${env.BRANCH_NAME} -t netlify/build:${env.GIT_COMMIT} ."
      }
    }

    stage("Build Squash images") {
      when {
        anyOf { buildingTag() }
      }
      steps {
        sh "docker build --build-arg NF_IMAGE_VERSION=${env.GIT_COMMIT} --build-arg NF_IMAGE_TAG=${env.BRANCH_NAME} --squash -t netlify/build:${env.BRANCH_NAME}-squash ."
      }
    }

    stage("Push Images") {
      when {
        anyOf { branch 'staging' ; branch 'xenial' ; branch 'trusty' ; buildingTag()}
      }
      steps {
        script {
          docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-ci') {
            docker.image("netlify/build:${env.BRANCH_NAME}").push()
            docker.image("netlify/build:${env.GIT_COMMIT}").push()
            if (env.BRANCH_NAME == 'xenial') {
              docker.image("netlify/build:${env.BRANCH_NAME}").push('latest')
            }
          }
        }
      }
    }

    stage("Push Squash Images") {
      when {
        anyOf { buildingTag() }
      }
      steps {
        script {
          docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-ci') {
            docker.image("netlify/build:${env.BRANCH_NAME}-squash").push()
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

/*
  Jenkins ENV Reference:
  env.GIT_COMMIT: the commit sha of the current build
  env.BRANCH_NAME: the branch name OR tag name of the current build, when it exists
  env.GIT_BRANCH: same as BRANCH_NAME
  env.TAG_NAME: the tag name of the current build, when it exists
*/
