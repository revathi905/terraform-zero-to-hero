name: CI-CD ${project_name}

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '${python_version}'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt

      - name: Validate Python files
        run: |
          python -m compileall .

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: $${{{ secrets.DOCKER_USERNAME }}}
          password: $${{{ secrets.DOCKER_PASSWORD }}}

      - name: Build and Push Docker Image
        run: |
          docker build -t $${{{ secrets.DOCKER_USERNAME }}}/${project_name}:latest .
          docker push $${{{ secrets.DOCKER_USERNAME }}}/${project_name}:latest

      - name: Deploy to EC2
        uses: appleboy/ssh-action@v1
        with:
          host: $${{{ secrets.EC2_HOST }}}
          username: $${{{ secrets.EC2_USER }}}
          key: $${{{ secrets.EC2_SSH_KEY }}}
          script: |
            docker pull $${{{ secrets.DOCKER_USERNAME }}}/${project_name}:latest
            docker stop ${project_name} || true
            docker rm ${project_name} || true
            docker run -d --name ${project_name} \
              $${{{ secrets.DOCKER_USERNAME }}}/${project_name}:latest
