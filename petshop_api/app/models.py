from app import db
from datetime import datetime

# -------------------------------------------------------------------
# 1. CLASS USER (PUSAT RELASI)
# -------------------------------------------------------------------
class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    nama_lengkap = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)
    role = db.Column(db.String(20), default='client') # client/admin
    no_hp = db.Column(db.String(20), nullable=True)
    alamat = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # --- DEFINISI RELASI ---
    orders = db.relationship('Order', backref='user', lazy=True)
    bookings = db.relationship('Booking', backref='user', lazy=True)
    cart_items = db.relationship('Cart', backref='user', lazy=True)
    pets = db.relationship('Pet', backref='owner', lazy=True)


# -------------------------------------------------------------------
# 2. CLASS PET
# -------------------------------------------------------------------
class Pet(db.Model):
    __tablename__ = 'pets'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    nama_hewan = db.Column(db.String(100), nullable=False) 
    jenis = db.Column(db.String(50), nullable=False) # Kucing/Anjing
    warna = db.Column(db.String(50), default='-')
    usia = db.Column(db.String(50), default='-')
    foto_url = db.Column(db.String(255), nullable=True)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


# -------------------------------------------------------------------
# 3. CLASS ITEM (Produk/Layanan)
# -------------------------------------------------------------------
class Item(db.Model):
    __tablename__ = 'items'
    id = db.Column(db.Integer, primary_key=True)
    nama = db.Column(db.String(100), nullable=False)
    tipe = db.Column(db.String(20), nullable=False) # 'makanan', 'aksesoris', 'layanan'
    harga = db.Column(db.Integer, nullable=False)
    stok = db.Column(db.Integer, default=0)
    deskripsi = db.Column(db.Text, nullable=True)
    gambar_url = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


# -------------------------------------------------------------------
# 4. CLASS CART (Keranjang)
# -------------------------------------------------------------------
class Cart(db.Model):
    __tablename__ = 'carts'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    item_id = db.Column(db.Integer, db.ForeignKey('items.id'), nullable=False)
    jumlah = db.Column(db.Integer, default=1)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    item = db.relationship('Item') 


# -------------------------------------------------------------------
# 5. CLASS ORDER & ORDER DETAIL (YANG DIREVISI)
# -------------------------------------------------------------------
class Order(db.Model):
    __tablename__ = 'orders'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    total_harga = db.Column(db.Integer, nullable=False)
    
    status = db.Column(db.String(50), default='menunggu_pembayaran')
    cancel_reason = db.Column(db.Text, nullable=True)
    
    # Info Pembayaran
    bank_name = db.Column(db.String(50), nullable=True)
    va_number = db.Column(db.String(50), nullable=True)
    payment_method = db.Column(db.String(50), default='transfer') 
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    details = db.relationship('OrderDetail', backref='order', lazy=True)

class OrderDetail(db.Model):
    __tablename__ = 'order_details'
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=False)
    item_id = db.Column(db.Integer, db.ForeignKey('items.id'), nullable=False)
    jumlah = db.Column(db.Integer, nullable=False)
    subtotal = db.Column(db.Integer, nullable=False)
    
    item = db.relationship('Item')


# -------------------------------------------------------------------
# 6. CLASS BOOKING
# -------------------------------------------------------------------
class Booking(db.Model):
    __tablename__ = 'bookings'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    service_name = db.Column(db.String(100), nullable=False)
    booking_date = db.Column(db.Date, nullable=False)
    booking_time = db.Column(db.String(10), nullable=False) 
    keluhan = db.Column(db.String(255))
    status = db.Column(db.String(50), default='Pending') 
    
    pet_name = db.Column(db.String(100))
    pet_type = db.Column(db.String(50))  
    pet_color = db.Column(db.String(50)) 
    
    payment_method = db.Column(db.String(50)) 
    bank_name = db.Column(db.String(20))      
    va_number = db.Column(db.String(50))      
    total_harga = db.Column(db.Integer, default=0)
    cancel_reason = db.Column(db.String(255))

    def to_dict(self):
        return {
            'id': self.id,
            'service_name': self.service_name,
            'pet_name': self.pet_name,
            'booking_date': str(self.booking_date),
            'booking_time': self.booking_time,
            'status': self.status,
            'total_harga': self.total_harga
        }