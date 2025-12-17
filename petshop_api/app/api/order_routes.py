from flask import Blueprint, request, jsonify
from app import db
from app.models import Order, OrderDetail, Item, Cart
from datetime import datetime
import random

bp = Blueprint('order_api', __name__, url_prefix='/api/orders')

# 1. CREATE ORDER (Checkout)
@bp.route('', methods=['POST'])
def create_order():
    data = request.get_json()
    
    # --- REVISI: MENYESUAIKAN DENGAN FLUTTER ---
    user_id = data.get('user_id')
    
    # Flutter kirim 'items_list', tapi kita jaga-jaga terima 'items' juga
    items_data = data.get('items_list') or data.get('items') 
    
    # Flutter kirim 'bank', kita jaga-jaga terima 'bank_name'
    bank_name = data.get('bank') or data.get('bank_name', 'BCA') 
    
    # Ambil payment_method (Default 'transfer')
    payment_method = data.get('payment_method', 'transfer') 

    if not user_id or not items_data:
        print("Data Error: User ID atau Items kosong") # Debug di terminal
        return jsonify({'message': 'Data tidak lengkap (user_id / items_list)'}), 400

    try:
        total_harga_order = 0
        order_details_list = []

        # 1. Cek Stok & Hitung Total Dulu (Validasi)
        for item_info in items_data:
            item_db = Item.query.get(item_info['item_id'])
            
            if not item_db:
                return jsonify({'message': f"Item ID {item_info['item_id']} tidak ditemukan"}), 404
            
            if item_db.stok < item_info['jumlah']:
                return jsonify({'message': f"Stok {item_db.nama} tidak cukup (Sisa: {item_db.stok})"}), 400
            
            subtotal = item_db.harga * item_info['jumlah']
            total_harga_order += subtotal

        # 2. Generate VA Number (Format Bank)
        # Biar terlihat real, kita pakai kode bank
        bank_codes = {'BCA': '8800', 'BRI': '1234', 'MANDIRI': '9000', 'BNI': '8810', 'CIMB': '1199'}
        prefix = bank_codes.get(bank_name, '8800')
        random_suffix = random.randint(1000000000, 9999999999)
        va_generated = f"{prefix}{random_suffix}"

        # 3. Buat Order Header
        new_order = Order(
            user_id=user_id,
            total_harga=total_harga_order,
            status='menunggu_pembayaran', 
            bank_name=bank_name,
            va_number=va_generated,
            payment_method=payment_method, # <--- PENTING: Disimpan ke DB
            created_at=datetime.utcnow()
        )
        db.session.add(new_order)
        db.session.flush() # Flush biar dapat ID Order

        # 4. Buat Detail Order & KURANGI STOK
        for item_info in items_data:
            item_db = Item.query.get(item_info['item_id'])
            
            # Kurangi Stok
            item_db.stok -= item_info['jumlah']
            
            # Simpan Detail
            detail = OrderDetail(
                order_id=new_order.id,
                item_id=item_db.id,
                jumlah=item_info['jumlah'],
                subtotal=item_db.harga * item_info['jumlah']
            )
            db.session.add(detail)

        # 5. Hapus Keranjang User (Hanya item yang dibeli)
        # Jika mau hapus semua keranjang: Cart.query.filter_by(user_id=user_id).delete()
        # Tapi kode di bawah ini lebih aman (opsional)
        ids_to_remove = [item['item_id'] for item in items_data]
        Cart.query.filter(Cart.user_id == user_id, Cart.item_id.in_(ids_to_remove)).delete(synchronize_session=False)

        db.session.commit()

        print(f">>> ORDER SUCCESS ID: {new_order.id}")

        return jsonify({
            'message': 'Order berhasil dibuat',
            'order_id': new_order.id,
            'total_harga': total_harga_order,
            'va_number': va_generated,
            'bank': bank_name,
            'status': 'menunggu_pembayaran'
        }), 201

    except Exception as e:
        db.session.rollback()
        print(f"!!! ERROR: {str(e)}")
        return jsonify({'message': 'Gagal membuat order', 'error': str(e)}), 500

# 2. GET USER ORDERS (Riwayat)
@bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_orders(user_id):
    orders = Order.query.filter_by(user_id=user_id).order_by(Order.created_at.desc()).all()
    result = []
    
    for order in orders:
        items = []
        for detail in order.details:
            items.append({
                'nama_barang': detail.item.nama,
                'jumlah': detail.jumlah,
                'subtotal': detail.subtotal
            })
            
        result.append({
            'id': order.id,
            'total_harga': order.total_harga,
            'status': order.status,
            'payment_method': getattr(order, 'payment_method', 'transfer'), # Handle kalau kolom belum ada di model
            'tgl_transaksi': order.created_at.strftime('%Y-%m-%d %H:%M'),
            'items': items,
            'bank_name': order.bank_name,
            'va_number': order.va_number,
            'cancel_reason': order.cancel_reason 
        })
    
    return jsonify(result), 200

# 3. PAY ORDER (Bayar via VA)
@bp.route('/<int:order_id>/pay', methods=['PUT'])
def pay_order(order_id):
    order = Order.query.get(order_id)
    if not order:
        return jsonify({'message': 'Order tidak ditemukan'}), 404
    
    if order.status != 'menunggu_pembayaran':
        return jsonify({'message': 'Status order tidak valid untuk pembayaran'}), 400

    try:
        # Ubah status jadi 'dikemas' atau 'menunggu_konfirmasi'
        # Karena ini VA Virtual, biasanya dianggap lunas otomatis -> 'dikemas'
        # Tapi kalau manual check, pakai 'menunggu_konfirmasi'
        order.status = 'menunggu_konfirmasi' 
        db.session.commit()
        return jsonify({'message': 'Pembayaran berhasil dikonfirmasi'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Error update status', 'error': str(e)}), 500

# 4. CANCEL ORDER 
@bp.route('/<int:order_id>/cancel', methods=['PUT'])
def cancel_order(order_id):
    order = Order.query.get(order_id)
    if not order:
        return jsonify({'message': 'Order tidak ditemukan'}), 404

    if order.status in ['dikirim', 'selesai', 'batal']:
         return jsonify({'message': 'Order tidak bisa dibatalkan'}), 400

    data = request.get_json() or {}
    reason = data.get('reason', 'Dibatalkan Pengguna')

    try:
        for detail in order.details:
            item = Item.query.get(detail.item_id)
            if item:
                item.stok += detail.jumlah
        
        order.status = 'batal'
        order.cancel_reason = reason
        
        db.session.commit()
        return jsonify({'message': 'Order dibatalkan & stok dikembalikan'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Gagal cancel', 'error': str(e)}), 500

# 5. GET ORDER DETAIL
@bp.route('/<int:order_id>', methods=['GET'])
def get_order_detail(order_id):
    order = Order.query.get(order_id)
    if not order:
        return jsonify({'message': 'Order tidak ditemukan'}), 404

    details = []
    for d in order.details:
        details.append({
            'nama': d.item.nama,
            'gambar': d.item.gambar_url,
            'harga': d.item.harga,
            'jumlah': d.jumlah,
            'subtotal': d.subtotal
        })

    return jsonify({
        'id': order.id,
        'status': order.status,
        'total_harga': order.total_harga,
        'bank_name': order.bank_name,
        'va_number': order.va_number,
        'payment_method': getattr(order, 'payment_method', '-'),
        'items': details
    }), 200