import os

# Ini adalah 'base directory' atau folder utama proyek API kita
basedir = os.path.abspath(os.path.dirname(__file__))

class Config:
    """
    Kelas ini berisi semua konfigurasi untuk aplikasi Flask kita.
    """
    
    # Kunci rahasia untuk keamanan (misal, sesi).
    # Nanti kita bisa ganti dengan yang lebih kompleks, tapi untuk sekarang ini saja cukup.
    SECRET_KEY = 'kunci-rahasia-petshop-yang-sangat-aman-dan-menggemaskan'
    
    # ==========================================================
    # BAGIAN PALING PENTING: KONEKSI KE DATABASE
    # ==========================================================
    
    # Ini adalah 'tali' yang menghubungkan Flask ke database MySQL kita.
    # Formatnya: 'mysql+mysqlclient://[USERNAME]:[PASSWORD]@[HOST]/[NAMA_DATABASE]'
    
    # [USERNAME] : Biasanya 'root' kalau pakai Laragon
    # [PASSWORD] : **Kosongkan** jika Laragon kamu tidak pakai password.
    # [HOST]     : 'localhost' (karena database-nya ada di laptop kita)
    # [NAMA_DATABASE]: 'petshop_db' (yang kita buat di Langkah 1)
    
    # Contoh jika MySQL kamu TIDAK pakai password (paling umum di Laragon):
    # Perhatikan ada ':@' setelah 'root'
    SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://root:@localhost/petshop_db'
    
    # Contoh jika MySQL kamu PAKAI password (misal password-nya '12345'):
    # SQLALCHEMY_DATABASE_URI = 'mysql+mysqlclient://root:12345@localhost/petshop_db'
    
    
    # Ini untuk mematikan 'warning' yang tidak perlu dari SQLAlchemy
    SQLALCHEMY_TRACK_MODIFICATIONS = False