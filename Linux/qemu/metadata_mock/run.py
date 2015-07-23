import json

from flask import Flask, Blueprint


app = Flask(__name__, static_folder='static')


@app.route('/')
def root():
    return json.dumps({'message': 'ok'})


@app.route('/conf')
def conf():
    tags = {
        # 'INITRD_DEBUG': 0,
        # 'INITRD_PRE_SHELL': 0,
        'NO_NTPDATE': 1,
    }
    entries = {
        'TAGS': len(tags.keys()),
        'PRIVATE_IP': '10.0.2.15',
    }
    idx = 0
    for key, value in tags.items():
        entries['TAGS_{}'.format(idx)] = '{}={}'.format(key, value)
        idx += 1

    return '\n'.join([
        '{}={}'.format(key, value) for key, value in entries.items()
    ])


@app.route('/state', methods=['PATCH'])
def state():
    return 'OK'


app.run(host='0.0.0.0', port=80)
