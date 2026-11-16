# Bugbounty Toolkit Update Plan (Idea)

## The "Modular / Manifest-Driven" Architecture
Skrip `install-toolkit-for-linux-fixed.sh` saat ini melakukan *hardcoding* untuk semua perintah `git clone` dan `wget`. Ini membuatnya menjadi *monolith* dan sulit untuk diperbarui atau ditambah *tools* baru tanpa membongkar *source code* bash-nya.

### Proposed Solution (Solusi yang Diusulkan):
1. **Pemisahan URL:** Pindahkan semua *link* *repository* GitHub dan URL *download tools* ke dalam file teks terpisah, misalnya `tools_manifest.txt`.
2. **Looping Logic:** Ubah skrip `install-toolkit-for-linux-fixed.sh` agar membaca baris per baris dari `tools_manifest.txt` dan mengunduhnya menggunakan *looping*.
3. **Kemudahan Update:** Dengan cara ini, jika *user* ingin menambahkan *tool* hacking baru, mereka cukup menambahkan *link* URL-nya ke baris baru di file `.txt` tersebut, tanpa perlu memiliki kemampuan *coding* Bash sama sekali.
