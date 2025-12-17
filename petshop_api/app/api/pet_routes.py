# File: app/api/pet_routes.py

from flask import Blueprint, request, jsonify
from app.models import Pet
from app import db

bp = Blueprint('pet_api', __name__, url_prefix='/api/pets')

# ----------------------------------------------------------------------
# 1. TAMBAH HEWAN BARU (Create)
# ----------------------------------------------------------------------
@bp.route('', methods=['POST'])
def add_pet():
    data = request.get_json()
    
    # Validasi input dasar (Hanya user_id dan nama_hewan yang wajib keras)
    if not data or 'user_id' not in data or 'nama_hewan' not in data:
        return jsonify({'message': 'Data tidak lengkap (Wajib: user_id & nama_hewan)'}), 400
        
    try:
        new_pet = Pet(
            user_id=data['user_id'],
            nama_hewan=data['nama_hewan'],
            # Pakai .get() supaya kalau null tidak error, dikasih default '-'
            jenis=data.get('jenis', '-'), 
            warna=data.get('warna', '-'), 
            usia=data.get('usia', '-'),   
            foto_url=data.get('foto_url', '') 
        )
        db.session.add(new_pet)
        db.session.commit()
        
        # Print di terminal biar tahu berhasil
        print(f"Sukses tambah hewan: {new_pet.nama_hewan}")
        
        return jsonify({'message': 'Hewan berhasil ditambahkan!', 'id': new_pet.id}), 201
    
    except Exception as e:
        db.session.rollback()
        # Print error ke terminal (PENTING BUAT DEBUG)
        print(f"Gagal tambah hewan: {e}") 
        return jsonify({'message': 'Gagal tambah hewan', 'error': str(e)}), 500

# ----------------------------------------------------------------------
# 2. AMBIL DAFTAR HEWAN USER (Read)
# ----------------------------------------------------------------------
@bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_pets(user_id):
    try:
        # Urutkan berdasarkan ID (ID besar = Inputan baru)
        pets = Pet.query.filter_by(user_id=user_id).order_by(Pet.id.desc()).all()
        
        result = []
        for p in pets:
            result.append({
                'id': p.id,
                'user_id': p.user_id,
                'nama_hewan': p.nama_hewan,
                'jenis': p.jenis,
                'warna': p.warna,
                'usia': p.usia,
                'foto_url': p.foto_url
            })
        return jsonify(result), 200
    except Exception as e:
        print(f"Error ambil data: {e}")
        return jsonify({'message': 'Gagal ambil data', 'error': str(e)}), 500

# ----------------------------------------------------------------------
# 3. UPDATE DATA HEWAN (Edit)
# ----------------------------------------------------------------------
@bp.route('/<int:pet_id>', methods=['PUT'])
def update_pet(pet_id):
    pet = Pet.query.get(pet_id)
    if not pet:
        return jsonify({'message': 'Hewan tidak ditemukan'}), 404
    
    data = request.get_json()
    
    try:
        # Update hanya field yang dikirim
        if 'nama_hewan' in data: pet.nama_hewan = data['nama_hewan']
        if 'jenis' in data: pet.jenis = data['jenis']
        if 'warna' in data: pet.warna = data['warna']
        if 'usia' in data: pet.usia = data['usia']
        if 'foto_url' in data: pet.foto_url = data['foto_url']
            
        db.session.commit()
        return jsonify({'message': 'Data hewan berhasil diupdate!'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Gagal update hewan', 'error': str(e)}), 500

# ----------------------------------------------------------------------
# 4. HAPUS HEWAN (Delete)
# ----------------------------------------------------------------------
@bp.route('/<int:pet_id>', methods=['DELETE'])
def delete_pet(pet_id):
    pet = Pet.query.get(pet_id)
    if not pet:
        return jsonify({'message': 'Hewan tidak ditemukan'}), 404
        
    try:
        db.session.delete(pet)
        db.session.commit()
        return jsonify({'message': 'Hewan berhasil dihapus!'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Gagal hapus hewan', 'error': str(e)}), 500