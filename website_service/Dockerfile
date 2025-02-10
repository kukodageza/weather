# website_service/Dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install Dependencies
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Copy the Application Code
COPY . .

# Run the Application
CMD ["python", "app.py"]