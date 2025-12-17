# File: app/api/item_routes.py

from flask import Blueprint, jsonify, request
from app.models import Item, db

bp = Blueprint('item_api', __name__, url_prefix='/api/items')

# 1. AMBIL SEMUA ITEM (Untuk Client & Admin)
@bp.route('', methods=['GET'])
def get_items():
    items = Item.query.order_by(Item.created_at.desc()).all()
    result = []
    for item in items:
        result.append({
            'id': item.id,
            'nama': item.nama,
            'tipe': item.tipe, # 'produk' atau 'layanan'
            'harga': item.harga,
            'stok': item.stok,
            'deskripsi': item.deskripsi,
            'gambar_url': item.gambar_url
        })
    return jsonify(result), 200

# 2. TAMBAH ITEM BARU (Khusus Admin)
@bp.route('', methods=['POST'])
def add_item():
    data = request.get_json()
    
    try:
        new_item = Item(
            nama=data['nama'],
            tipe=data['tipe'],
            harga=data['harga'],
            stok=data.get('stok', 0),
            deskripsi=data.get('deskripsi', ''),
            gambar_url=data.get('gambar_url', 'assets/images/pet_avatar.png')
        )
        db.session.add(new_item)
        db.session.commit()
        return jsonify({'message': 'Item berhasil ditambahkan!'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Gagal tambah item', 'error': str(e)}), 500

# 3. EDIT ITEM (Khusus Admin)
@bp.route('/<int:id>', methods=['PUT'])
def update_item(id):
    item = Item.query.get(id)
    if not item: return jsonify({'message': 'Item tidak ditemukan'}), 404
    
    data = request.get_json()
    try:
        item.nama = data.get('nama', item.nama)
        item.tipe = data.get('tipe', item.tipe)
        item.harga = data.get('harga', item.harga)
        item.stok = data.get('stok', item.stok)
        item.deskripsi = data.get('deskripsi', item.deskripsi)
        item.gambar_url = data.get('gambar_url', item.gambar_url)
        
        db.session.commit()
        return jsonify({'message': 'Item berhasil diupdate!'}), 200
    except Exception as e:
        return jsonify({'message': 'Gagal update', 'error': str(e)}), 500

# 4. HAPUS ITEM (Khusus Admin)
@bp.route('/<int:id>', methods=['DELETE'])
def delete_item(id):
    item = Item.query.get(id)
    if not item: return jsonify({'message': 'Item tidak ditemukan'}), 404
    
    try:
        db.session.delete(item)
        db.session.commit()
        return jsonify({'message': 'Item berhasil dihapus!'}), 200
    except Exception as e:
        return jsonify({'message': 'Gagal hapus (Mungkin item ini ada di riwayat pesanan)', 'error': str(e)}), 500