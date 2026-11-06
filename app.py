import os
from flask import Flask, jsonify

app = Flask(__name__)

students = [
    {"id": 1, "name": "Ravi"},
    {"id": 2, "name": "Sita"},
    {"id": 3, "name": "Kiran"}
]


@app.route("/")
def home():
    return jsonify({
        "message": "Secure DevSecOps Application",
        "status": "Running Successfully"
    })


@app.route("/students")
def get_students():
    return jsonify(students)


@app.route("/health")
def health():
    return jsonify({"status": "healthy"})


if __name__ == "__main__":
    app.run(host=os.getenv("HOST", "127.0.0.1"), port=5000)
