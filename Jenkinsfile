node {

  env.DOCKERHUB_ACCOUNT = "bigfleet"
  env.VERSION_TAG = "3.2.1" // latest version of the release
  env.BUILD_TAG = "testing" // default tag to push for to the registry
  
  stage 'Checkout'

    checkout scm

  stage 'Base'
    
    sh './build_image.sh'
    
  stage 'Tests'
  
    sh '/usr/local/bin/bats tests/shibboleth-idp.bats'
    
  stage 'Push'
    if(env.BRANCH_NAME == "master")
    docker.withRegistry('https://registry.hub.docker.com/', 'dockerhub-bigfleet') {
      def baseImg = docker.build('bigfleet/centos7base')
      baseImg.push('latest')
    }

}