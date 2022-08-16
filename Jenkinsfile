// Licensed to the University Corporation for Advanced Internet Development,
// Inc. (UCAID) under one or more contributor license agreements.  See the
// NOTICE file distributed with this work for additional information regarding
// copyright ownership. The UCAID licenses this file to You under the Apache
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
node('docker') {

  stage 'Checkout'

    checkout scm

  stage 'Acquire util files'

    sh 'mkdir -p tmp && mkdir -p bin'
    dir('tmp'){
      git([ url: "https://github.internet2.edu/docker/util.git",
          credentialsId: "jenkins-github-access-token" ])
      sh 'rm -rf ../bin/*'
      sh 'mv ./bin/* ../bin/.'
    }
    sh 'rm -rf tmp'

  stage 'Setting build context'
  
    def maintainer = maintainer()
    def previous_maintainer = previous_maintainer()
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

  stage 'Test'

    try {
      sh 'bin/test.sh 2>&1 | tee debug ; test ${PIPESTATUS[0]} -eq 0'
    } catch (error) {
      def error_details = readFile('./debug')
      def message = "BUILD ERROR: There was a problem testing ${imagename}:${tag}. \n\n ${error_details}"
      sh "rm -f ./debug"
      handleError(message)
    } 
   
  stage('Scan') {
      steps {
          // Install trivy and HTML template
          sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.31.1'
          sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl > html.tpl'

          // Scan container for all vulnerability levels
          sh 'mkdir -p reports'
          sh 'trivy image --ignore-unfixed --vuln-type os,library --no-progress --format template --template "@html.tpl" -o reports/container-scan.html ${imagename}:${tag}'
          publishHTML target : [
              allowMissing: true,
              alwaysLinkToLastBuild: true,
              keepAll: true,
              reportDir: 'reports',
              reportFiles: 'container-scan.html',
              reportName: 'Security Scan',
              reportTitles: 'Security Scan'
          ]

          // Scan again and fail on CRITICAL vulns
          sh 'trivy image --ignore-unfixed --vuln-type os,library --exit-code 1 --severity CRITICAL ${imagename}:${tag}'

      }
  }
 
  stage 'Push'

    docker.withRegistry('https://registry.hub.docker.com/',   "dockerhub-$previous_maintainer") {
          def baseImg = docker.build("$maintainer/$imagename")
          baseImg.push("$tag")
    }

    docker.withRegistry('https://registry.hub.docker.com/',   "dockerhub-$previous_maintainer") {
          def altImg = docker.build("$previous_maintainer/$imagename")
          altImg.push("$tag")
    }
    
  stage 'Notify'

    slackSend color: 'good', message: "$maintainer/$imagename:$tag pushed to DockerHub"

}

def maintainer() {
  def matcher = readFile('common.bash') =~ 'maintainer="(.+)"'
  matcher ? matcher[0][1] : 'i2incommon'
}

def previous_maintainer() {
  def matcher = readFile('common.bash') =~ 'previous_maintainer="(.+)"'
  matcher ? matcher[0][1] : 'tier'
}

def imagename() {
  def matcher = readFile('common.bash') =~ 'imagename="(.+)"'
  matcher ? matcher[0][1] : null
}

def handleError(String message){
  echo "${message}"
  currentBuild.setResult("FAILED")
  slackSend color: 'danger', message: "${message} (<${env.BUILD_URL}|Open>)"
  sh 'exit 1'
}

