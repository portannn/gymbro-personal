# Gymbro - PPL Kelompok C

# Panduan Kolaborasi Git - Proyek S1SIKJ2305-KELC

Berikut adalah instruksi setup awal dan alur kerja harian untuk pengembangan proyek menggunakan Git.

---

## 1. Setup Awal (Lakukan Sekali)

Gunakan perintah ini saat pertama kali menyiapkan repositori di lokal:

```bash
# Clone repositori ke mesin lokal
git clone https://github.com/PPL-Kelompok-C-Tugas-Besar/S1SIKJ2305-KELC.git

# Masuk ke direktori proyek
cd S1SIKJ2305-KELC

# Berpindah ke branch kerja masing-masing (Contoh: Samuel_branch)
git checkout [branch_kalian]

# Sinkronisasi dengan source code terbaru dari branch develop
git pull origin develop
```

---

## 2. Alur Kerja Harian

Ikuti langkah-langkah ini setiap kali melakukan perubahan kode.

### Langkah 1: Pengembangan

Pastikan Anda selalu bekerja di dalam branch masing-masing, **bukan** di branch `main` atau `develop`.

### Langkah 2: Menyimpan Perubahan

```bash
# Menambahkan semua file yang diubah ke area staging
git add .

# Membuat snapshot perubahan dengan pesan commit
# Gunakan prefix feat: atau fix: sesuai standar
git commit -m "feat: [deskripsi singkat]"
```

### Langkah 3: Mengirim ke Repositori Remote

```bash
# Mengirim perubahan dari lokal ke GitHub
git push origin [branch_kalian]
```

### Langkah 4: Penggabungan (Merge)

1. Buka repositori di GitHub.
2. Pilih menu **Pull Request (PR)**.
3. Klik **New Pull Request**.
4. Set **Base Branch** ke `develop` (**bukan** `main`).
5. Set **Compare Branch** ke `[branch_kalian]`.
6. Klik **Create Pull Request**.
