node {

  env.DOCKERHUB_ACCOUNT = "bigfleet"
  env.VERSION_TAG = "3.2.1" // latest version of the release
  env.BUILD_TAG = "testing" // default tag to push for to the registry
  
  stage 'Checkout'

    checkout scm
    
  stage 'Acquire util'
  
    sh 'curl "https://github.internet2.edu/raw/docker/util/master/bin/install.sh?token=AAAAEddkrL9MeeA6VWcNn_PgV30r4lD1ks5XogeiwA%3D%3D" | bash'

  stage 'Base'
    
    sh 'bin/build.sh'
    
  stage 'Tests'
  
    sh '/usr/local/bin/bats tests'
    

}