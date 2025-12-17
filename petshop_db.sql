-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               8.0.30 - MySQL Community Server - GPL
-- Server OS:                    Win64
-- HeidiSQL Version:             12.1.0.6537
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Dumping database structure for petshop_db
DROP DATABASE IF EXISTS `petshop_db`;
CREATE DATABASE IF NOT EXISTS `petshop_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `petshop_db`;

-- Dumping structure for table petshop_db.bookings
DROP TABLE IF EXISTS `bookings`;
CREATE TABLE IF NOT EXISTS `bookings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `service_name` varchar(100) NOT NULL,
  `pet_name` varchar(100) NOT NULL,
  `pet_type` varchar(50) NOT NULL,
  `pet_color` varchar(50) NOT NULL,
  `booking_date` date NOT NULL,
  `booking_time` varchar(10) NOT NULL,
  `status` varchar(50) DEFAULT 'pending',
  `cancel_reason` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `payment_method` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT 'cod',
  `bank_name` varchar(50) DEFAULT NULL,
  `va_number` varchar(50) DEFAULT NULL,
  `keluhan` text,
  `total_harga` int DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table petshop_db.bookings: ~0 rows (approximately)

-- Dumping structure for table petshop_db.carts
DROP TABLE IF EXISTS `carts`;
CREATE TABLE IF NOT EXISTS `carts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `item_id` int NOT NULL,
  `jumlah` int DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `item_id` (`item_id`),
  CONSTRAINT `carts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `carts_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table petshop_db.carts: ~0 rows (approximately)

-- Dumping structure for table petshop_db.items
DROP TABLE IF EXISTS `items`;
CREATE TABLE IF NOT EXISTS `items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nama` varchar(255) NOT NULL,
  `deskripsi` text,
  `harga` int NOT NULL DEFAULT '0',
  `stok` int NOT NULL DEFAULT '0' COMMENT 'Stok untuk produk, layanan bisa diisi 999 (tak terbatas)',
  `tipe` enum('produk','layanan') NOT NULL,
  `gambar_url` varchar(255) DEFAULT NULL COMMENT 'Link ke URL gambar produk/layanan',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table petshop_db.items: ~13 rows (approximately)
INSERT INTO `items` (`id`, `nama`, `deskripsi`, `harga`, `stok`, `tipe`, `gambar_url`, `created_at`) VALUES
	(1, 'Whiskas Tuna 1kg', 'Makanan kucing rasa tuna lezat kaya nutrisi.', 65000, 48, 'produk', 'assets/images/whiskas.jpeg', '2025-12-09 20:16:45'),
	(2, 'Royal Canin Adult', 'Makanan premium untuk kucing dewasa indoor.', 120000, 29, 'produk', 'assets/images/royal_canin.jpeg', '2025-12-09 20:16:45'),
	(3, 'Shampoo Anti Kutu', 'Shampoo herbal pembasmi kutu dan jamur.', 35000, 18, 'produk', 'assets/images/shampoo.jpeg', '2025-12-09 20:16:45'),
	(4, 'Kalung Lonceng', 'Kalung lucu dengan lonceng nyaring.', 15000, 98, 'produk', 'assets/images/kalung.jpeg', '2025-12-09 20:16:45'),
	(5, 'Kandang Rio L', 'Kandang besi lipat ukuran L untuk kucing/anjing.', 150000, 1, 'produk', 'assets/images/kandang.jpeg', '2025-12-09 20:16:45'),
	(6, 'Mainan Tikus', 'Mainan interaktif untuk melatih ketangkasan.', 15000, 50, 'produk', 'assets/images/mainan_tikus.jpeg', '2025-12-09 20:16:45'),
	(7, 'Vitamin Bulu', 'Suplemen untuk melebatkan dan menghaluskan bulu.', 45000, 24, 'produk', 'assets/images/vitamins.jpeg', '2025-12-09 20:16:45'),
	(8, 'Bola Karet', 'Bola mainan gigit untuk anjing.', 12000, 40, 'produk', 'assets/images/bola.jpeg', '2025-12-09 20:16:45'),
	(9, 'Grooming Kucing', 'Mandi sehat, potong kuku, dan bersihkan telinga.', 50000, 999, 'layanan', 'assets/images/grooming.jpeg', '2025-12-09 20:16:45'),
	(10, 'Grooming Anjing', 'Perawatan lengkap khusus anjing ras kecil/sedang.', 70000, 999, 'layanan', 'assets/images/grooming_dog.jpeg', '2025-12-09 20:16:45'),
	(11, 'Penitipan (Hotel)', 'Harga per malam. Ruangan AC dan makan 3x sehari.', 50000, 999, 'layanan', 'assets/images/hotel_pet.jpeg', '2025-12-09 20:16:45'),
	(12, 'Vaksinasi Lengkap', 'Paket vaksin tahunan untuk pencegahan virus.', 180000, 999, 'layanan', 'assets/images/vaksin.jpeg', '2025-12-09 20:16:45'),
	(13, 'Konsultasi Dokter', 'Cek kesehatan umum oleh dokter hewan berpengalaman.', 100000, 999, 'layanan', 'assets/images/checkup.jpeg', '2025-12-09 20:16:45');

-- Dumping structure for table petshop_db.orders
DROP TABLE IF EXISTS `orders`;
CREATE TABLE IF NOT EXISTS `orders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT 'ID dari tabel users',
  `total_harga` int NOT NULL DEFAULT '0',
  `status` varchar(50) NOT NULL DEFAULT 'pending',
  `payment_method` varchar(50) DEFAULT 'transfer',
  `cancel_reason` text,
  `bank_name` varchar(50) DEFAULT NULL,
  `va_number` varchar(50) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table petshop_db.orders: ~9 rows (approximately)

-- Dumping structure for table petshop_db.order_details
DROP TABLE IF EXISTS `order_details`;
CREATE TABLE IF NOT EXISTS `order_details` (
  `id` int NOT NULL AUTO_INCREMENT,
  `order_id` int NOT NULL COMMENT 'ID dari tabel orders',
  `item_id` int NOT NULL COMMENT 'ID dari tabel items',
  `jumlah` int NOT NULL DEFAULT '1' COMMENT 'Jumlah item yang dibeli',
  `subtotal` int NOT NULL DEFAULT '0' COMMENT 'Harga item * jumlah',
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`),
  KEY `item_id` (`item_id`),
  CONSTRAINT `order_details_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `order_details_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table petshop_db.order_details: ~9 rows (approximately)

-- Dumping structure for table petshop_db.pets
DROP TABLE IF EXISTS `pets`;
CREATE TABLE IF NOT EXISTS `pets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `nama_hewan` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `jenis` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `warna` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `usia` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `foto_url` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `pets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table petshop_db.pets: ~1 rows (approximately)

-- Dumping structure for table petshop_db.users
DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nama_lengkap` varchar(255) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `no_hp` varchar(20) DEFAULT NULL,
  `alamat` text,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','client') NOT NULL DEFAULT 'client',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email_unique` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table petshop_db.users: ~2 rows (approximately)
INSERT INTO `users` (`id`, `nama_lengkap`, `email`, `no_hp`, `alamat`, `password`, `role`, `created_at`) VALUES
	(1, 'Auril Putri Amanda', 'auril@gmail.com', '081234567891', 'Jalan mawar, no.03', 'scrypt:32768:8:1$QbXooEnALcYTIh0I$c13e20d17fc1ec67dec10b1fd2093f658cc000de73db170648634f90119dada86fea78cf3cad0beca6f942770b43d2bad6260630913041e85f43fb7bc72f5c12', 'client', '2025-12-05 06:05:51'),
	(2, 'Rizky Aqil Hibatullah', 'aqil@gmail.com', NULL, NULL, 'scrypt:32768:8:1$nDaLRA99MoyMWSXx$bdef7a3dc70adae01c68bc22966c2dc9b5f7dd9753af5cf9e5beeaee9aca17a370fe51944d66a7a4af7dc0e30b25e6be6f0c1ef1d06d5081ae4237e81bded1c8', 'admin', '2025-12-05 06:07:21');

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
