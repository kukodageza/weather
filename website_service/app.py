import logging
from flask import Flask, render_template, request
import requests
from prometheus_client import Counter, generate_latest

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

# Prometheus metrics
REQUEST_COUNT = Counter('website_service_requests_total', 'Total number of requests to website service', ['method', 'endpoint'])

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/search', methods=['POST'])
def search():
    location = request.form['location']
    
    # Log the request
    logging.info(f"Received search request for location: {location}")
    REQUEST_COUNT.labels(method='POST', endpoint='/search').inc()

    response = requests.get(f'http://api-service/weather?location={location}')
    if response.status_code == 200:
        weather_data = response.json()
        
        # Log the response
        logging.info(f"Received weather data for location: {location}")
    else:
        weather_data = None
        logging.warning(f"Failed to retrieve weather data for location: {location}")

    return render_template('index.html', weather=weather_data)

@app.route('/metrics', methods=['GET'])
def metrics():
    return generate_latest(), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)