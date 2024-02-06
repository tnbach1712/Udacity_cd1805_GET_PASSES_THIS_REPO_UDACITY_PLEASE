
# from flask import Flask

# app = Flask(__name__)

# @app.route('/')
# def index():
#     return 'Web App with Python Flask!'

# app.run(host='0.0.0.0', port=81)

from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, World! 1123'
    
@app.route('/app/<polo>')
def app_route(polo):
    return polo

if __name__ == "__main__":
   app.run()