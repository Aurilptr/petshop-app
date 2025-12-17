from flask import Blueprint, request, jsonify
from app import db
from app.models import Booking, Item
from datetime import datetime
import random

bp = Blueprint('booking_api', __name__, url_prefix='/api/bookings')

# ---------------------------------------------------------------------
# 1. CREATE BOOKING (Booking Baru)
# ---------------------------------------------------------------------
@bp.route('', methods=['POST'])
def create_booking():
    # Gunakan silent=True agar tidak Error 415 jika Header tertinggal
    data = request.get_json(silent=True) 
    
    if not data:
        return jsonify({'message': 'Data JSON tidak ditemukan'}), 400

    print("----- DATA BOOKING MASUK -----")
    print(data)
    print("------------------------------")

    try:
        # 1. Validasi Tanggal
        if 'booking_date' not in data:
            return jsonify({'message': 'Tanggal booking wajib diisi'}), 400
            
        date_obj = datetime.strptime(data['booking_date'], '%Y-%m-%d').date()
        
        # 2. Cari Harga Layanan
        service_item = Item.query.filter_by(nama=data['service_name']).first()
        harga_layanan = service_item.harga if service_item else 50000 
        
        # 3. Metode Pembayaran & VA
        method = data.get('payment_method', 'Bayar di Tempat')
        bank_selected = data.get('bank_name', '-')
        
        va_generated = None
        if 'Transfer' in method:
            # Generate VA Dummy
            va_generated = f"8800{data['user_id']}{random.randint(100, 999)}"

        # 4. Simpan ke Database
        new_booking = Booking(
            user_id=data['user_id'],
            service_name=data['service_name'],
            pet_name=data.get('pet_name', 'Hewan Kesayangan'),
            pet_type=data.get('pet_type', 'Unknown'),
            pet_color=data.get('pet_color', '-'),
            booking_date=date_obj,
            booking_time=data['booking_time'],
            keluhan=data.get('keluhan', '-'),
            status='menunggu_pembayaran', 
            total_harga=harga_layanan,
            payment_method=method,
            bank_name=bank_selected,
            va_number=va_generated
        )

        db.session.add(new_booking)
        db.session.commit()
        
        print(f">>> SUKSES SIMPAN BOOKING ID: {new_booking.id}")
        
        return jsonify({
            'message': 'Booking berhasil dibuat', 
            'booking_id': new_booking.id,
            'va_number': va_generated,
            'total_harga': harga_layanan
        }), 201
    
    except Exception as e:
        db.session.rollback()
        print(f"!!! ERROR SAAT BOOKING: {e}") 
        return jsonify({'message': 'Gagal memproses booking', 'error': str(e)}), 500


# ---------------------------------------------------------------------
# 2. GET USER BOOKINGS (Riwayat) - FIX SESUAI DATABASE
# ---------------------------------------------------------------------
@bp.route('/user/<int:user_id>', methods=['GET'])
def get_user_bookings(user_id):
    try:
        bookings = Booking.query.filter_by(user_id=user_id).order_by(Booking.id.desc()).all()
        result = []
        
        for b in bookings:
            # --- LOGIKA MENCARI GAMBAR ---
            item = Item.query.filter_by(nama=b.service_name).first()
            
            # [FIX] Menggunakan .gambar_url (Sesuai tabel items di database kamu)
            gambar_layanan = item.gambar_url if item else None 
            # -----------------------------

            result.append({
                'id': b.id,
                'service_name': b.service_name,
                'pet_name': b.pet_name,
                'pet_type': b.pet_type,
                'booking_date': str(b.booking_date),
                'booking_time': b.booking_time,
                'status': b.status,
                'total_harga': b.total_harga, 
                'payment_method': b.payment_method,
                'bank_name': b.bank_name,
                'va_number': b.va_number,
                'keluhan': b.keluhan,
                'cancel_reason': b.cancel_reason,
                
                # Kirim URL gambar ke Flutter
                'image_url': gambar_layanan
            })
        return jsonify(result), 200
    except Exception as e:
        print(f"Error Get History: {e}")
        return jsonify({'message': 'Gagal ambil data', 'error': str(e)}), 500


# ---------------------------------------------------------------------
# 3. CANCEL BOOKING
# ---------------------------------------------------------------------
@bp.route('/<int:booking_id>/cancel', methods=['PUT'])
def cancel_booking(booking_id):
    booking = Booking.query.get(booking_id)
    if not booking: 
        return jsonify({'message': 'Booking tidak ditemukan'}), 404
    
    data = request.get_json(silent=True)
    if data is None:
        data = {}

    alasan = data.get('reason', 'Dibatalkan oleh Pengguna')

    try:
        if booking.status in ['selesai', 'batal']:
            return jsonify({'message': 'Pesanan sudah tidak bisa dibatalkan'}), 400

        booking.status = 'batal'
        booking.cancel_reason = alasan
        db.session.commit()
        return jsonify({'message': 'Booking berhasil dibatalkan'}), 200
    except Exception as e:
        return jsonify({'message': 'Gagal cancel', 'error': str(e)}), 500


# ---------------------------------------------------------------------
# 4. PAY BOOKING
# ---------------------------------------------------------------------
@bp.route('/<int:booking_id>/pay', methods=['PUT'])
def pay_booking(booking_id):
    booking = Booking.query.get(booking_id)
    if not booking: 
        return jsonify({'message': 'Booking tidak ditemukan'}), 404
    
    try:
        if booking.status != 'menunggu_pembayaran':
            return jsonify({'message': 'Status pesanan tidak valid untuk pembayaran'}), 400

        booking.status = 'diproses' 
        db.session.commit()
        return jsonify({'message': 'Pembayaran berhasil dikonfirmasi'}), 200
    except Exception as e:
        return jsonify({'message': 'Gagal update status', 'error': str(e)}), 500