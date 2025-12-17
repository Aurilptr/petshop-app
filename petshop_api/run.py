from app import create_app, db

# 1. Panggil "pabrik" aplikasi yang sudah kita buat di app/__init__.py
# Kita gunakan konfigurasi default (yaitu Config dari config.py)
app = create_app()

# 2. Ini adalah 'pintu masuk' utama aplikasi kita.
# Perintah 'if __name__ == "__main__":'
# berarti "HANYA jalankan kode di bawah ini jika file ini (run.py)
# dijalankan secara langsung oleh Python".
if __name__ == '__main__':
    # 3. Menjalankan aplikasi
    # host='0.0.0.0' artinya 'terima koneksi dari IP manapun'
    #     (Ini PENTING agar HP/Emulator bisa akses)
    # port=5000 adalah 'pintu' yang kita gunakan
    # debug=True artinya server akan auto-restart kalau kita ubah kode
    #     (Sangat berguna saat development)
    app.run(host='0.0.0.0', port=5000, debug=True)