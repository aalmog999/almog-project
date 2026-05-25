pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['deploy', 'destroy'],
            description: 'Choose deploy to install/upgrade Helm chart, or destroy to uninstall it'
        )

        string(
            name: 'NAMESPACE',
            defaultValue: 'alma',
            description: 'Kubernetes namespace'
        )

        string(
            name: 'RELEASE_NAME',
            defaultValue: 'simple-web',
            description: 'Helm release name'
        )

        string(
            name: 'CHART_PATH',
            defaultValue: './helm',
            description: 'Path to Helm chart inside the GitHub repo'
        )

        string(
            name: 'VALUES_FILE',
            defaultValue: './helm/values.yaml',
            description: 'Path to Helm values file inside the GitHub repo'
        )
    }

    environment {
        AKS_NAME        = 'devops-interview-aks'
        AKS_RG          = 'devops-interview-rg'

        // Keep kubeconfig inside Jenkins workspace to avoid permission/user issues
        KUBECONFIG      = "${WORKSPACE}/kubeconfig"
    }

    stages {
        stage('Checkout GitHub Repo') {
            steps {
                checkout scm
            }
        }

        stage('Login to Azure with Managed Identity') {
            steps {
                sh '''
                    set -e

                    echo "Logging in to Azure using Managed Identity..."
                    az login -i

                    echo "Azure login completed"
                    az account show
                '''
            }
        }

        stage('Connect to AKS') {
            steps {
                sh '''
                    set -e

                    echo "Getting AKS credentials..."
                    az aks get-credentials \
                      --name "$AKS_NAME" \
                      --resource-group "$AKS_RG" \
                      --file "$KUBECONFIG" \
                      --overwrite-existing

                    echo "Converting kubeconfig to use Managed Identity..."
                    kubelogin convert-kubeconfig \
                      -l msi \
                      --kubeconfig "$KUBECONFIG"

                    echo "Testing connection to AKS..."
                    kubectl get nodes
                '''
            }
        }

        stage('Deploy or Destroy Helm Chart') {
            steps {
                script {
                    if (params.ACTION == 'deploy') {
                        sh '''
                            set -e

                            echo "Deploying Helm chart..."
                            helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
                              --namespace "$NAMESPACE" \
                              --values "$VALUES_FILE" \
                              --wait \
                              --timeout 10m

                            echo "Deployment completed"
                        '''
                    }

                    if (params.ACTION == 'destroy') {
                        sh '''
                            set -e

                            echo "Destroying Helm release..."
                            helm uninstall "$RELEASE_NAME" \
                              --namespace "$NAMESPACE" 

                            echo "Destroy completed"
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            sh '''
                echo "Cleaning kubeconfig..."
                rm -f "$KUBECONFIG" || true
            '''
        }

        success {
            echo "Pipeline completed successfully"
        }

        failure {
            echo "Pipeline failed"
        }
    }
}
