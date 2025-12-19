# File: app/api/admin_routes.py

from flask import Blueprint, jsonify, request, current_app
from app.models import Order, Booking, User, Item, db
from sqlalchemy import func

bp = Blueprint('admin_api', __name__, url_prefix='/api/admin')

# ---------------------------------------------------------------------
# 1. DASHBOARD STATS
# ---------------------------------------------------------------------
@bp.route('/stats', methods=['GET'])
def get_stats():
    # 1. Hitung Total Uang dari ORDERS (Jual Beli Barang)
    order_revenue = db.session.query(func.sum(Order.total_harga)).scalar() or 0
 
    # 2. Hitung Total Uang dari BOOKINGS (Jasa Grooming/Hotel)
    booking_revenue = db.session.query(func.sum(Booking.total_harga)).scalar() or 0

    # 3. Gabungkan keduanya
    total_revenue = order_revenue + booking_revenue

    # Hitung jumlah data lain
    total_orders = Order.query.count()
    total_bookings = Booking.query.count()
    
    # Menghitung user client saja (selain admin)
    total_users = User.query.filter(User.role != 'admin').count()

    current_app.logger.info(f"📊 ADMIN MEMBUKA DASHBOARD (Total Omzet: Rp {total_revenue})")

    return jsonify({
        'revenue': int(total_revenue),      # Pastikan jadi integer
        'total_orders': total_orders,
        'total_bookings': total_bookings,
        'total_users': total_users
    })


# ---------------------------------------------------------------------
# 2. KELOLA PESANAN TOKO (PRODUK)
# ---------------------------------------------------------------------
@bp.route('/orders', methods=['GET'])
def get_all_orders():
    orders = Order.query.order_by(Order.created_at.desc()).all()
    result = []
    
    for order in orders:
        items_str = []
        first_image = None 

        # Ambil detail barang yang dibeli
        for d in order.details:
            item_obj = Item.query.get(d.item_id)
            if item_obj:
                items_str.append(f"{item_obj.nama} ({d.jumlah}x)")
                # Ambil gambar dari item pertama yang ketemu
                if not first_image:
                    first_image = item_obj.gambar_url

        result.append({
            'id': order.id,
            # [FIX] Ganti order.customer jadi order.user
            'customer': order.user.nama_lengkap if order.user else "Unknown",
            'total': order.total_harga,
            'status': order.status,
            'bank': order.bank_name,
            'va': order.va_number,
            'date': order.created_at.strftime('%Y-%m-%d %H:%M'),
            'items': ", ".join(items_str),
            'image': first_image,
            'cancel_reason': order.cancel_reason
        })
    return jsonify(result), 200


@bp.route('/orders/<int:id>/status', methods=['PUT'])
def update_order_status(id):
    data = request.get_json()
    order = Order.query.get(id)
    if not order: return jsonify({'message': 'Not found'}), 404
    
    order.status = data.get('status')
    reason = data.get('reason')
    if reason: order.cancel_reason = reason
        
    db.session.commit()
    return jsonify({'message': 'Status updated'}), 200


# ---------------------------------------------------------------------
# 3. KELOLA BOOKING JASA (+ HARGA)
# ---------------------------------------------------------------------
@bp.route('/bookings', methods=['GET'])
def get_all_bookings():
    bookings = Booking.query.order_by(Booking.booking_date.desc()).all()
    result = []
    for b in bookings:
        # Cari Item berdasarkan nama layanan untuk ambil Harga & Gambar
        service_item = Item.query.filter_by(nama=b.service_name).first()
        service_image = service_item.gambar_url if service_item else None
        service_price = service_item.harga if service_item else 0 # Ambil Harga

        result.append({
            'id': b.id,
            # Ini sudah benar (b.user)
            'customer': b.user.nama_lengkap if b.user else "Unknown",
            'service': b.service_name,
            'image': service_image,
            'price': service_price, 
            'pet': f"{b.pet_name} ({b.pet_type})",
            'date': str(b.booking_date),
            'time': b.booking_time,
            'status': b.status,
            'cancel_reason': b.cancel_reason
        })
    return jsonify(result), 200


@bp.route('/bookings/<int:id>/status', methods=['PUT'])
def update_booking_status(id):
    data = request.get_json()
    booking = Booking.query.get(id)
    if not booking: return jsonify({'message': 'Not found'}), 404
    
    booking.status = data.get('status')
    reason = data.get('reason')
    if reason: booking.cancel_reason = reason
        
    db.session.commit()
    return jsonify({'message': 'Status updated'}), 200