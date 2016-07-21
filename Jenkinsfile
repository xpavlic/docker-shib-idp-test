node {

  env.DOCKERHUB_ACCOUNT = "bigfleet"
  env.VERSION_TAG = "3.2.1" // latest version of the release
  env.BUILD_TAG = "testing" // default tag to push for to the registry
  
  stage 'Checkout'

    checkout scm

  stage 'Base'
    
    sh 'bin/build.sh'
    
  stage 'Tests'
  
    sh '/usr/local/bin/bats tests'
    

}