import json

from flask import Flask


app = Flask(__name__)


@app.route('/')
def root():
    return json.dumps({'message': 'ok'})


@app.route('/conf')
def conf():
    return 'TODO'


app.run(host='0.0.0.0', port=80)
