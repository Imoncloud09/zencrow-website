pipeline {
    agent any
    
    environment {
        // GitHub repository details
        GITHUB_REPO = 'https://github.com/Imoncloud09/zencrow-website.git'
        GITHUB_BRANCH = 'master'
        
        // EC2 deployment details
        EC2_HOST = 'ec2-13-201-55-138.ap-south-1.compute.amazonaws.com'
        EC2_USER = 'ec2-user'
        SSH_KEY = 'C:\\ProgramData\\Jenkins\\.jenkins\\zen.pem'
        
        // Target directory on EC2
        TARGET_DIR = '/home/ec2-user/zencrow-website'
        BACKUP_DIR = '/home/ec2-user/zencrow-website-backup'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 15, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "Checking out code from GitHub..."
                git branch: "${GITHUB_BRANCH}", 
                    url: "${GITHUB_REPO}",
                    credentialsId: 'git-creds'
                echo "Code checked out successfully"
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                echo "Deploying to EC2..."
                bat """
                    ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "echo 'Starting deployment...'; if [ -d '${TARGET_DIR}' ]; then echo 'Backing up existing folder...'; rm -rf '${BACKUP_DIR}'; mv '${TARGET_DIR}' '${BACKUP_DIR}'; echo 'Backup created'; fi; echo 'Cloning repository...'; git clone ${GITHUB_REPO} ${TARGET_DIR}; cd ${TARGET_DIR}; git checkout ${GITHUB_BRANCH}; echo 'Deployment completed successfully'"
                """
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo "Verifying deployment..."
                bat """
                    ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "if [ -d '${TARGET_DIR}' ]; then echo '✅ Folder exists at ${TARGET_DIR}'; echo '📁 Contents:'; ls -la ${TARGET_DIR}; echo '📊 Folder size:'; du -sh ${TARGET_DIR}; else echo '❌ Folder not found'; exit 1; fi"
                """
            }
        }
    }
    
    post {
        success {
            echo "✅ Deployment completed successfully!"
        }
        
        failure {
            echo "❌ Deployment failed!"
            bat """
                ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "if [ -d '${BACKUP_DIR}' ]; then echo 'Restoring from backup...'; rm -rf ${TARGET_DIR}; mv ${BACKUP_DIR} ${TARGET_DIR}; echo '✅ Restored from backup'; fi"
            """
        }
        
        always {
            echo "Pipeline completed"
        }
    }
}
