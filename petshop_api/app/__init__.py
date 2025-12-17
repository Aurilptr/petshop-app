# File: app/__init__.py

from flask import Flask
from config import Config
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS

# Inisialisasi Database
db = SQLAlchemy()

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Aktifkan CORS supaya Flutter bisa akses
    CORS(app)

    db.init_app(app)

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