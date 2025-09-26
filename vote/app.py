import os
import json
import logging
import time
from datetime import datetime
from flask import Flask, render_template, request, jsonify
import redis
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Environment variables with defaults (Twelve-Factor App principle)
REDIS_HOST = os.environ.get('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.environ.get('REDIS_PORT', 6379))
REDIS_DB = int(os.environ.get('REDIS_DB', 0))
REDIS_PASSWORD = os.environ.get('REDIS_PASSWORD', None)
VOTE_QUEUE = os.environ.get('VOTE_QUEUE', 'votes')
APP_PORT = int(os.environ.get('PORT', 5000))
APP_HOST = os.environ.get('HOST', '0.0.0.0')

# Prometheus metrics
vote_counter = Counter('votes_total', 'Total number of votes', ['choice'])
request_duration = Histogram('request_duration_seconds', 'Request duration')
health_check_counter = Counter('health_checks_total', 'Total health checks', ['status'])

# Redis connection
def get_redis_client():
    try:
        client = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            db=REDIS_DB,
            password=REDIS_PASSWORD,
            socket_timeout=5,
            socket_connect_timeout=5,
            retry_on_timeout=True
        )
        # Test connection
        client.ping()
        return client
    except Exception as e:
        logger.error(f"Redis connection failed: {e}")
        return None

redis_client = get_redis_client()

@app.route('/')
def index():
    """Main voting page"""
    return render_template('index.html')

@app.route('/vote', methods=['POST'])
@request_duration.time()
def vote():
    """Handle vote submission"""
    try:
        data = request.get_json()
        if not data or 'vote' not in data:
            return jsonify({'error': 'Invalid vote data'}), 400
        
        choice = data['vote'].lower()
        if choice not in ['cats', 'dogs']:
            return jsonify({'error': 'Invalid choice. Must be cats or dogs'}), 400
        
        if not redis_client:
            return jsonify({'error': 'Service unavailable'}), 503
        
        # Create vote record
        vote_data = {
            'vote': choice,
            'voter_id': request.remote_addr,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        # Push vote to Redis queue
        redis_client.lpush(VOTE_QUEUE, json.dumps(vote_data))
        
        # Update metrics
        vote_counter.labels(choice=choice).inc()
        
        logger.info(f"Vote received: {choice} from {request.remote_addr}")
        
        return jsonify({
            'status': 'success',
            'vote': choice,
            'message': f'Thank you for voting for {choice}!'
        })
        
    except Exception as e:
        logger.error(f"Error processing vote: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/health')
def health_check():
    """Health check endpoint"""
    try:
        if redis_client:
            redis_client.ping()
            health_check_counter.labels(status='healthy').inc()
            return jsonify({
                'status': 'healthy',
                'service': 'vote',
                'redis': 'connected',
                'timestamp': datetime.utcnow().isoformat()
            }), 200
        else:
            health_check_counter.labels(status='unhealthy').inc()
            return jsonify({
                'status': 'unhealthy',
                'service': 'vote',
                'redis': 'disconnected',
                'timestamp': datetime.utcnow().isoformat()
            }), 503
            
    except Exception as e:
        health_check_counter.labels(status='unhealthy').inc()
        logger.error(f"Health check failed: {e}")
        return jsonify({
            'status': 'unhealthy',
            'service': 'vote',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 503

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {error}")
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    logger.info(f"Starting vote service on {APP_HOST}:{APP_PORT}")
    logger.info(f"Redis connection: {REDIS_HOST}:{REDIS_PORT}")
    app.run(host=APP_HOST, port=APP_PORT, debug=False)
