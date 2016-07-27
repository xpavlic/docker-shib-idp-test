node {

  env.DOCKERHUB_ACCOUNT = "bigfleet"
  env.VERSION_TAG = "3.2.1" // latest version of the release
  env.BUILD_TAG = "testing" // default tag to push for to the registry
  
  stage 'Checkout'

    checkout scm
    
  stage 'Acquire util'
    
    sh 'mkdir -p bin'
    dir('bin'){
      git([ url: "https://github.internet2.edu/docker/util.git",
          credentialsId: "jenkins-github-access-token" ])
      sh 'ls'
      sh 'mv bin/* .'
    }

  stage 'Base'
    
    sh 'bin/build.sh'
    
  stage 'Tests'
  
    sh 'bin/test.sh'
    

}