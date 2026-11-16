# Arsitektur: OWASP Lab Toolkit (Speedrun Edition)
*(by iMoon, Inspired by Taro Lay)*

Arsitektur ini didesain ulang agar **100% realistis** menyerupai infrastruktur *enterprise* modern. Semua sistem *port hopping* atau *chaos mode* yang mengacak-acak port dihapus, karena menyulitkan proses belajar.

## 📝 Daftar Target Aplikasi & Pemetaan Domain

Seluruh aplikasi dijalankan di atas standar port HTTP (80) dan HTTPS (443) murni menggunakan sistem *Virtual Host* dan *SNI (Server Name Indication)*.

### 1. Mutillidae II
- **Domain:** `mutillidae.owasp.hacking`
- **Routing:** Nginx (HTTPS: 443) ➡️ Apache (HTTP: 80)

### 2. DVWA (Damn Vulnerable Web App)
- **Domain:** `dvwa.owasp.hacking`
- **Routing:** Nginx (HTTPS: 443) ➡️ Apache (HTTP: 80)

### 3. bWAPP (buggy Web Application)
- **Domain:** `bwapp.owasp.hacking`
- **Routing:** Nginx (HTTPS: 443) ➡️ Apache (HTTP: 80)

### 4. Juice Shop (Node.js)
- **Domain:** `juiceshop.owasp.hacking`
- **Routing:** Nginx (HTTPS: 443) ➡️ Node.js Internal (HTTP: 3000)
- **Instalasi:** `/opt/juiceshop`

### 5. WebGoat & WebWolf (Java)
- **Domain WebGoat:** `webgoat.owasp.hacking`
- **Domain WebWolf:** `webwolf.owasp.hacking`
- **Routing:** Nginx (HTTPS: 443) ➡️ Java Internal (HTTP: 8080 & 9090)
- **Instalasi:** `/opt/webgoat` (Dilengkapi full source code Java untuk analisis *White-box* di folder `/opt/webgoat/WebGoat-Source`)

### 6. XVWA & VWA
- **Domain XVWA:** `xvwa.owasp.hacking`
- **Domain VWA:** `vwa.owasp.hacking`
- **Routing:** Nginx (HTTPS: 443) ➡️ Apache (HTTP: 80)

---

## 🛠️ Environment & Server Stack (Speedrun APT Edition)

Arsitektur ini sudah bergeser dari "Native Compilation" menjadi "Speedrun APT Mode" untuk meningkatkan reliabilitas dan kecepatan eksekusi, mencegah *error* OOM (Out-of-Memory) saat melakukan *make install* secara paralel.

### 1. LAMP/LEMP Stack (APT Repo)
- Menggunakan repositori resmi dari kreator PHP (Ondřej Surý PPA).
- Apache2 akan di-bind secara paksa HANYA di port `80` (Merespon trafik HTTP murni dan trafik *reverse proxy* dari Nginx).
- Nginx akan di-bind HANYA di port `443 ssl` (Merespon koneksi SSL klien). Port 443 di Apache dimatikan secara eksplisit.
- **Backend PHP 8.3:** Terkonfigurasi secara tidak aman (*Insecure by Design*) untuk lab hacking (`allow_url_include = On`).

### 2. Database Stack
- Menggunakan MariaDB 11.4 LTS.
- Dijalankan lewat `.service` standar OS.

### 3. Systemd Daemons
Aplikasi Java dan Node.js diotomatisasi menggunakan Systemd agar terus berjalan di *background*:
- `juiceshop.service`
- `webgoat.service`
- `webwolf.service`

---

## ⚙️ Skrip Modular
- `install-owasp-lab.sh` 👉 Mengeksekusi instalasi seluruh stack.
- `check-owasp-lab.sh` 👉 Melakukan Health Check dan menampilkan endpoint.
- `update-owasp-lab.sh` 👉 Menarik update vulnerable apps terbaru.
- `uninstall-owasp-lab.sh` 👉 Membersihkan murni sisa-sisa lab (Nuclear Uninstall).
