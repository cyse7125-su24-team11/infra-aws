pipeline{
    agent any
        environment {
        GITHUB_CREDENTIALS_ID = 'GH_CRED'
        GITHUB_REPO_OWNER = 'cyse7125-su24-team11'
        GITHUB_REPO_NAME = 'infra-aws'
            }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    changelog: false,
                    credentialsId: 'GH_CRED',
                    poll: false,
                    url: 'https://github.com/cyse7125-su24-team11/infra-aws.git'
            }
        }
        stage('PR') {
            steps {
                withCredentials([usernamePassword(credentialsId: GITHUB_CREDENTIALS_ID, usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
                    script{
                        def prCommitSHA = sh(script: "git ls-remote https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}.git refs/pull/${env.CHANGE_ID}/head | cut -f1", returnStdout: true).trim()
                        echo "PR Commit SHA: ${prCommitSHA}"
                        env.PR_COMMIT_SHA = prCommitSHA
                    }
                }
            }
        }
        stage('Terraform Validate')
        {
        steps{

            sh '''
            terraform fmt -check -recursive .
            if [ $? == 0 ]; then
              echo "Terraform script formatted correctly";
            else 
              echo "Terraform script is incorrectly formatted. Please fix it";
              exit 1
            fi
            '''
        }
        post{
            failure{
                script{
                    currentBuild.result = 'FAILURE'
                }
            }
        }
    }
    }
    post {
        success {
            script {
                state = 'success'
                description = 'All checks have passed!'
                withCredentials([usernamePassword(credentialsId: GITHUB_CREDENTIALS_ID, usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
                    sh "curl -u ${GITHUB_USERNAME}:${GITHUB_TOKEN} -X POST https://api.github.com/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/statuses/${env.PR_COMMIT_SHA} -d '{\"state\": \"${state}\", \"description\": \"${description}\", \"context\": \"Jenkins CI\"}'"
                }
            }
        }
        failure {
            script {
                state = 'failure'
                description = 'One or more checks have failed!'
                withCredentials([usernamePassword(credentialsId: GITHUB_CREDENTIALS_ID, usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
                    sh "curl -u ${GITHUB_USERNAME}:${GITHUB_TOKEN} -X POST https://api.github.com/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/statuses/${env.PR_COMMIT_SHA} -d '{\"state\": \"${state}\", \"description\": \"${description}\", \"context\": \"Jenkins CI\"}'"
                }                
            }
        }
    }
}

