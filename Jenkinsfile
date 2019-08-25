node {
    def app

    stage('Clone repository') {
        /* Cloning the Repository to our Workspace */
        checkout scm
    }

    stage('Build image') {
        /* This builds the actual image */
        app = docker.build("proj/sqldb")
    }

    stage('Push image') {
        /* You would need to first register with DockerHub before you can push images to your account */
        docker.withRegistry('https://index.docker.io/v1/', 'docker-hub') {
            app.push()
	      } 
	      echo "Trying to Push Docker Build to DockerHub"
    }
	
    /*stage('Deploy Application') {
	  // Create namespace if it doesn't exist
        sh("kubectl get ns kubd || kubectl create ns kubd")
        //Update the imagetag to the latest version
        sh("sed -i.bak 's#gcr.io/proj/datahandle:q#r#' *.yaml")
        //Create or update resources
        sh("kubectl --namespace=kubd apply -f *.yaml")
        //Grab the external Ip address of the service
        sh("echo http://`kubectl --namespace=kubd get service/2s --output=json | jq -r '.status.loadBalancer.ingress[0].ip'` > ${feSvcName}")
    } */
}
