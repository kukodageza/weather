# website_service/app.py
from flask import Flask, render_template, request
import requests

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/search', methods=['POST'])
def search():
    location = request.form['location']
    response = requests.get(f'http://api-service/weather?location={location}')
    if response.status_code == 200:
        weather_data = response.json()
    else:
        weather_data = None
    return render_template('index.html', weather=weather_data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)