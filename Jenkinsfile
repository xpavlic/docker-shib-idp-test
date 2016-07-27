node {

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
    
  stage 'Build'
    
    def maintainer = maintainer()
    def imagename = imagename()
    def tag = env.BRANCH_NAME
    if(!imagename){
      echo "You must define an imagename in common.bash"
      currentBuild.result = 'FAILURE'
    }
    if(maintainer){
      echo "Building ${maintainer}:${tag} for ${maintainer}"
    }
    
    sh 'bin/build.sh'
    
  stage 'Tests'
  
    sh 'bin/test.sh'
    
  stage 'Push'
  
    docker.withRegistry('https://registry.hub.docker.com/',   'dockerhub-bigfleet') {
          def baseImg = docker.build("$maintainer/$imagename")
          baseImg.push("$tag")
    }
    

}

def maintainer() {
  def matcher = readFile('common.bash') =~ 'maintainer="(.+)"'
  matcher ? matcher[0][1] : 'tier'
}

def imagename() {
  def matcher = readFile('common.bash') =~ 'imagename="(.+)"'
  matcher ? matcher[0][1] : null
}