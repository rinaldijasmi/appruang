# Menyiapkan backend bersama Ruang

Aplikasi menggunakan Supabase untuk autentikasi dan satu papan tugas bersama. Siapa pun yang berhasil membuat akun dan masuk dapat melihat, menambah, mengubah status, serta menghapus semua tugas di papan. Data tersimpan di Supabase dan pembaruan akan muncul otomatis pada pengguna lain yang sedang membuka aplikasi.

## 1. Buat proyek Supabase

1. Buat proyek baru di [supabase.com/dashboard](https://supabase.com/dashboard).
2. Simpan kata sandi database di tempat aman.
3. Buka **SQL Editor**, pilih **New query**, salin seluruh isi [`supabase/schema.sql`](./supabase/schema.sql), lalu pilih **Run**. Skrip membuat tabel, aturan akses, dan pembaruan real-time. Aturan akses memang mengizinkan semua pengguna terautentikasi mengelola seluruh papan bersama.

## 2. Hubungkan aplikasi

1. Buka **Project Settings → API** pada proyek Supabase.
2. Salin **Project URL** dan **anon/public key** (pada tampilan baru dapat bernama publishable key).
3. Isi kedua nilai tersebut di [`supabase-config.js`](./supabase-config.js):

   ```js
   window.RUANG_SUPABASE_URL = "https://PROJECT_REF.supabase.co";
   window.RUANG_SUPABASE_ANON_KEY = "sb_publishable_...";
   ```

   Gunakan hanya anon/public key. Jangan pernah memasukkan `service_role` key ke aplikasi browser.

## 3. Aktifkan email dan Google

### Email dan kata sandi

Buka **Authentication → Providers → Email** dan pastikan provider aktif. Untuk pengujian, akun baru mungkin harus mengklik tautan verifikasi email sebelum masuk. Pengaturan email verifikasi dan URL situs dapat dikelola lewat **Authentication → URL Configuration**.

### Google

1. Di Google Cloud Console, pilih/buat proyek dan buka **Google Auth Platform → Branding** untuk mengisi nama aplikasi dan email dukungan.
2. Buka **Google Auth Platform → Audience**. Pilih **External** agar akun Google di luar organisasi bisa menggunakan aplikasi. Untuk tahap uji coba, biarkan status **Testing**, lalu tambahkan setiap akun yang akan menguji lewat **Test users**. Akun yang tidak ada di daftar ini tidak bisa masuk saat status Testing.
3. Di **Google Auth Platform → Data Access**, pastikan scope dasar `openid`, `email`, dan `profile` tersedia. Jangan meminta akses Google tambahan untuk aplikasi tugas ini.
4. Buka **Google Auth Platform → Clients → Create client → Web application**.
   - **Authorized JavaScript origins**: tambahkan origin situs, tanpa path. Contoh `http://localhost:8000` untuk lokal dan `https://nama-situs.netlify.app` setelah deploy. Keduanya perlu didaftarkan jika memakai dua alamat tersebut.
   - **Authorized redirect URIs**: tambahkan callback Supabase yang tampil pada halaman Google provider di dashboard Supabase. Bentuknya `https://PROJECT_REF.supabase.co/auth/v1/callback`. Ini **bukan** alamat situs aplikasi.
5. Buat client, lalu salin **Client ID** dan **Client secret** yang diberikan Google.
6. Di dashboard Supabase, buka **Authentication → Providers → Google**, aktifkan provider, lalu isikan Client ID dan Client secret. Simpan secret hanya di Supabase, jangan di file aplikasi.
7. Di Supabase, buka **Authentication → URL Configuration**. Atur **Site URL** ke alamat aplikasi dan masukkan URL aplikasi sebagai **Redirect URL** yang diizinkan. Untuk server lokal yang dijalankan pada port 8000, tambahkan `http://localhost:8000/**`; untuk situs produksi, tambahkan URL situs tersebut.

Saat status Google masih **Testing**, hanya akun pada daftar **Test users** yang dapat login. Untuk membuka login kepada semua pengguna Google, ubah status publikasi sesuai petunjuk Google Auth Platform; Google mungkin meminta verifikasi branding terlebih dahulu.

## 4. Deploy ke GitHub Pages

Workflow deployment sudah disediakan di [`.github/workflows/deploy-pages.yml`](./.github/workflows/deploy-pages.yml).

1. Buat repository GitHub kosong untuk aplikasi ini, lalu push isi folder proyek ke branch `main`.
2. Pada repository, buka **Settings → Pages** dan atur **Build and deployment → Source** ke **GitHub Actions**.
3. Setelah workflow selesai, alamatnya biasanya `https://USERNAME.github.io/NAMA-REPOSITORY/`. Lihat URL deployment di tab **Actions**.
4. Di Google Cloud, tambahkan `https://USERNAME.github.io` sebagai **Authorized JavaScript origin** pada OAuth client. Authorized redirect URI tetap callback Supabase `https://PROJECT_REF.supabase.co/auth/v1/callback`.
5. Di Supabase **Authentication → URL Configuration**, isi **Site URL** dengan URL GitHub Pages lengkap (termasuk `/NAMA-REPOSITORY/`) dan tambahkan URL tersebut ke **Redirect URLs**. Redirect login Google di aplikasi menggunakan URL halaman aktif.
6. Saat menguji lokal dengan `python3 -m http.server 8000`, tambahkan `http://localhost:8000` ke Google **Authorized JavaScript origins**, dan `http://localhost:8000/**` ke Supabase **Redirect URLs**.

Jangan buka aplikasi melalui `file://`; OAuth memerlukan HTTP/HTTPS.

Sesudah deployment, buka URL GitHub Pages, daftar atau masuk, lalu gunakan akun lain untuk mengakses papan yang sama.

## Catatan migrasi

Pada masuk pertama, tugas versi lama yang tersimpan di browser akan dipindahkan ke Supabase hanya jika papan bersama masih kosong. Migrasi dicatat per akun pada browser tersebut agar tidak diimpor berulang kali.
