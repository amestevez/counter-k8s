from flask import Flask, render_template, request, jsonify, session
import redis
import os

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'fallback-local')

# Configuración Redis
redis_client = redis.Redis(
    host=os.environ.get('REDIS_HOST', 'redis'),
    port=int(os.environ.get('REDIS_PORT', 6379)),
    decode_responses=True
)

@app.route('/')
def index():
    # Incrementar contador de visitas global
    visits = redis_client.incr('global_visits')
    
    # Inicializar contador de clicks de sesión si no existe
    if 'session_clicks' not in session:
        session['session_clicks'] = 0
    
    # Obtener contador global de clicks
    global_clicks = int(redis_client.get('global_clicks') or 0)
    
    return render_template('index.html', 
                         visits=visits,
                         session_clicks=session['session_clicks'],
                         global_clicks=global_clicks)

@app.route('/click', methods=['POST'])
def click():
    # Incrementar clicks de sesión
    session['session_clicks'] = session.get('session_clicks', 0) + 1
    
    # Incrementar clicks globales en Redis
    global_clicks = redis_client.incr('global_clicks')
    
    return jsonify({
        'session_clicks': session['session_clicks'],
        'global_clicks': global_clicks
    })

@app.route('/submit_text', methods=['POST'])
def submit_text():
    text = request.json.get('text', '').strip()
    
    if text:
        # Guardar texto en lista de Redis
        redis_client.lpush('submitted_texts', text)
        return jsonify({'success': True, 'message': 'Texto guardado'})
    
    return jsonify({'success': False, 'message': 'Texto vacío'}), 400

@app.route('/get_texts', methods=['GET'])
def get_texts():
    # Obtener todos los textos (más recientes primero)
    texts = redis_client.lrange('submitted_texts', 0, -1)
    return jsonify({'texts': texts})

@app.route('/reset_session', methods=['POST'])
def reset_session():
    session.clear()
    return jsonify({'success': True})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)