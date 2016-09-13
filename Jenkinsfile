node('docker') {

  stage 'Checkout'

    checkout scm
    
  stage 'Acquire util'
    
    sh 'mkdir -p tmp && mkdir -p bin'
    dir('tmp'){
      git([ url: "https://github.internet2.edu/docker/util.git",
          credentialsId: "jenkins-github-access-token" ])
      sh 'mv ./bin/* ../bin/.'
    }
    sh 'rm -rf tmp'

  stage 'Setting build context'
  
    def maintainer = maintainer()
    def imagename = imagename()
    def tag
    
    // Tag images created on master branch with 'latest'
    if(env.BRANCH_NAME == "master"){
      tag = "latest"
    }else{
      tag = env.BRANCH_NAME
    }
        
    if(!imagename){
      echo "You must define an imagename in common.bash"
      currentBuild.result = 'FAILURE'
     }
     if(maintainer){
      echo "Building ${imagename}:${tag} for ${maintainer}"
     }    

  stage 'Build'
    
    try{
      sh 'bin/rebuild.sh &> debug'
    } catch(error) {
      def error_details = readFile('./debug');
      def message = "BUILD ERROR: There was a problem building ${imagename}:${tag}. \n\n ${error_details}"
      sh "rm -f ./debug"
      handleError(message)
    }
    
  stage 'Tests'
  
    try{
      sh 'bin/test.sh &> debug'
    } catch(error) {
      def error_details = readFile('./debug');
      def message = "BUILD ERROR: There was a problem building ${imagename}:${tag}. \n\n ${error_details}"
      sh "rm -f ./debug"
      handleError(message)
    }
    
  stage 'Push'
  
    docker.withRegistry('https://registry.hub.docker.com/',   "dockerhub-$maintainer") {
          def baseImg = docker.build("$maintainer/$imagename")
          baseImg.push("$tag")
    }
    
  stage 'Notify'
  
    slackSend color: 'good', message: "$maintainer/$imagename:$tag pushed to DockerHub"

}

def maintainer() {
  def matcher = readFile('common.bash') =~ 'maintainer="(.+)"'
  matcher ? matcher[0][1] : 'tier'
}

def imagename() {
  def matcher = readFile('common.bash') =~ 'imagename="(.+)"'
  matcher ? matcher[0][1] : null
}

def handleError(String message){
  echo "${message}"
  currentBuild.setResult("FAILED")
  slackSend color: 'danger', message: "${message}"
  //step([$class: 'Mailer', notifyEveryUnstableBuild: true, recipients: 'chris.bynum@levvel.io', sendToIndividuals: true])
  sh 'exit 1'
}