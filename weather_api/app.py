# weather_api/app.py
from flask import Flask, request, jsonify
import requests
from geopy.geocoders import Nominatim

app = Flask(__name__)

geolocator = Nominatim(user_agent="weather_api")

def get_coordinates(city_name):
    location = geolocator.geocode(city_name)
    if location:
        return location.latitude, location.longitude
    else:
        return None, None

def process_weather_data(data):
    weather_data = []
    times = data['hourly']['time']
    temperatures = data['hourly']['temperature_2m']
    for time, temp in zip(times, temperatures):
        weather_data.append({'time': time, 'temperature': temp})
    return weather_data

@app.route('/weather', methods=['GET'])
def get_weather():
    city_name = request.args.get('location')
    latitude, longitude = get_coordinates(city_name)

    if latitude and longitude:
        endpoint = f'https://api.open-meteo.com/v1/forecast?latitude={latitude}&longitude={longitude}&hourly=temperature_2m'
        response = requests.get(endpoint)
        weather_data = response.json()
        processed_data = process_weather_data(weather_data)
        return jsonify(processed_data)
    else:
        return jsonify({"error": "City not found"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)