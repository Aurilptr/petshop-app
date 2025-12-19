from flask import Blueprint, request, jsonify,current_app
from app import db
from app.models import User
from werkzeug.security import generate_password_hash, check_password_hash

bp = Blueprint('user_api', __name__, url_prefix='/api/users')

# 1. REGISTER
@bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    
    # Validasi input
    if not data or not data.get('email') or not data.get('password') or not data.get('nama_lengkap'):
        return jsonify({'message': 'Data tidak lengkap'}), 400

    # Cek apakah email sudah ada
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'message': 'Email sudah terdaftar'}), 400

    hashed_password = generate_password_hash(data['password'], method='pbkdf2:sha256')
    
    new_user = User(
        nama_lengkap=data['nama_lengkap'],
        email=data['email'],
        password=hashed_password,
        no_hp=data.get('no_hp', ''),
        alamat=data.get('alamat', '')
    )

    try:
        db.session.add(new_user)
        db.session.commit()
        current_app.logger.info(f"👤 USER BARU DAFTAR: {data['nama_lengkap']} ({data['email']})")
        return jsonify({'message': 'Registrasi berhasil'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Gagal registrasi', 'error': str(e)}), 500

# 2. LOGIN
@bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'message': 'Email dan password wajib diisi'}), 400

    user = User.query.filter_by(email=data['email']).first()

    if not user or not check_password_hash(user.password, data['password']):
        return jsonify({'message': 'Email atau password salah'}), 401

    return jsonify({
        'message': 'Login berhasil',
        'user': {
            'id': user.id,
            'nama_lengkap': user.nama_lengkap,
            'email': user.email,
            'role': user.role,
            'no_hp': user.no_hp,
            'alamat': user.alamat
        }
    }), 200

# 3. GET USER PROFILE
@bp.route('/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'message': 'User tidak ditemukan'}), 404
        
    return jsonify({
        'id': user.id,
        'nama_lengkap': user.nama_lengkap,
        'email': user.email,
        'role': user.role,
        'no_hp': user.no_hp,
        'alamat': user.alamat
    }), 200

# 4. UPDATE PROFILE
@bp.route('/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'message': 'User tidak ditemukan'}), 404
    
    data = request.get_json()
    
    try:
        if 'nama_lengkap' in data: user.nama_lengkap = data['nama_lengkap']
        if 'no_hp' in data: user.no_hp = data['no_hp']
        if 'alamat' in data: user.alamat = data['alamat']
        
        # Jika ganti password
        if 'password' in data and data['password']:
             user.password = generate_password_hash(data['password'], method='pbkdf2:sha256')

        db.session.commit()
        return jsonify({'message': 'Profil berhasil diupdate'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Gagal update', 'error': str(e)}), 500