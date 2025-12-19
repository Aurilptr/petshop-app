# File: app/__init__.py

from flask import Flask, request
from config import Config
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import logging

# Inisialisasi Database
db = SQLAlchemy()

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Aktifkan CORS supaya Flutter bisa akses
    CORS(app)

    db.init_app(app)

    # ============================================================
    # MULAI KODE LOGGER (DEBUG TERMINAL)
    # ============================================================
    
    # 1. Setting Format Log biar Rapi
    # Format: [WAKTU] - [TIPE] - [PESAN]
    logging.basicConfig(level=logging.INFO, 
                        format='%(asctime)s - %(levelname)s - %(message)s')
    
    # 2. CCTV Masuk (Mencatat Request dari HP/Flutter)
    @app.before_request
    def log_request_info():
        # Jangan log request gambar (biar terminal gak penuh spam)
        if not request.path.startswith('/static'):
            app.logger.info('================================================')
            app.logger.info(f'📢 TERIMA REQUEST: {request.method} {request.url}')
            # Cek kalau ada data JSON yang dikirim
            if request.is_json:
                app.logger.info(f'📦 DATA MASUK: {request.get_json()}')
    
    # 3. CCTV Keluar (Mencatat Respon ke HP/Flutter)
    @app.after_request
    def log_response_info(response):
        if not request.path.startswith('/static'):
            status = response.status_code
            if status >= 400:
                app.logger.error(f'❌ GAGAL/ERROR: Status {status}')
            else:
                app.logger.info(f'✅ SUKSES: Status {status}')
            app.logger.info('================================================\n')
        return response

    # ============================================================
    # SELESAI KODE LOGGER
    # ============================================================

    # -----------------------------------------------------------
    # PENDAFTARAN BLUEPRINT (JANGAN DIHAPUS/DIUBAH)
    # -----------------------------------------------------------

    # 1. User Routes
    from .api import user_routes
    app.register_blueprint(user_routes.bp)

    # 2. Pet Routes (INI YANG TADINYA ERROR 404)
    from .api import pet_routes
    app.register_blueprint(pet_routes.bp)

    # 3. Item Routes
    from .api import item_routes
    app.register_blueprint(item_routes.bp)

    # 4. Order Routes
    from .api import order_routes
    app.register_blueprint(order_routes.bp)

    # 5. Booking Routes
    from .api import booking_routes
    app.register_blueprint(booking_routes.bp)
    
    # 6. Admin Routes
    from .api import admin_routes
    app.register_blueprint(admin_routes.bp)

    return app