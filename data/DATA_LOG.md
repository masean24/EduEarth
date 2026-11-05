# DATA_LOG

Diperbarui 2026-11-04. Semua angka dihitung skrip dari CSV. Dataset BELUM dibekukan (tanpa CHECKSUMS).

## 1. Jumlah akhir (staging saat ini)

| Jenis | Baris | operating (n / MW) | construction (n / MW) | planned (n / MW) | Total MW semua status |
|---|---|---|---|---|---|
| geothermal | 34 | 18 / 2492.70 | 3 / 220.00 | 13 / 955.00 | 3667.70 |
| wind | 6 | 2 / 147.00 | 0 / 0.00 | 4 / 419.00 | 566.00 |
| hydro | 55 | 35 / 5512.32 | 5 / 3433.00 | 15 / 3956.00 | 12901.32 |
| solar | 11 | 8 / 265.80 | 1 / 100.00 | 2 / 400.00 | 765.80 |
| bioenergy | 22 | 22 / 73.70 | 0 / 0.00 | 0 / 0.00 | 73.70 |
| **Jumlah** | **128** | **85 / 8491.52** | **9 / 3753.00** | **34 / 5730.00** | **17974.52** |

## 2. Dikarantina (`data/staging/quarantine/`)

| Jenis | Baris | operating (n / MW) | construction (n / MW) | planned (n / MW) | Total MW semua status |
|---|---|---|---|---|---|
| geothermal | 1 | 1 / 10.00 | 0 / 0.00 | 0 / 0.00 | 10.00 |
| wind | 2 | 0 / 0.00 | 0 / 0.00 | 2 / 141.00 | 141.00 |
| hydro | 15 | 2 / 102.40 | 0 / 0.00 | 13 / 10574.00 | 10676.40 |
| solar | 5 | 2 / 5.50 | 1 / 60.00 | 2 / 250.00 | 315.50 |
| bioenergy | 18 | 18 / 46.45 | 0 / 0.00 | 0 / 0.00 | 46.45 |
| **Jumlah** | **41** | **23 / 164.35** | **1 / 60.00** | **17 / 10965.00** | **11189.35** |

## 3. Sumber

| Sumber | URL | Akses | Lisensi | Catatan |
|---|---|---|---|---|
| Global Energy Monitor, tracker panas bumi / angin / air / surya (halaman GEM.wiki per proyek) | https://www.gem.wiki/ | 2026-11-03 (sebagian dibaca subagent; saat revisi ini 403) | CC BY 4.0 (dikutip dari ringkasan pencarian; halaman lisensi belum dibuka) | Nama tracker + bulan rilis belum terverifikasi; klaim rilis sebelumnya ditarik. |
| Ditjen EBTKE, Buku Saku Bioenergi 2023 (PDF) | https://ebtke.esdm.go.id/api/storage/2025/elibrary/file/xlYZhs1MO6_11022025023103.pdf | 2026-11-03 (PDF diunduh, hal. 72-75 dibaca) | Publikasi pemerintah; lisensi eksplisit tidak ditemukan | Tidak memuat koordinat. |
| Artikel ESDM / media (Kontan, Kompas, babelprov dll.) untuk beberapa baris bioenergi | per baris di `source_url` | 2026-11-03 (HTTP 200 pada uji URL) | hak cipta penerbit | Isi artikel belum dicocokkan per baris. |
| OpenStreetMap Nominatim | https://nominatim.openstreetmap.org/ | 2026-11-03 | ODbL 1.0 (atribusi: OpenStreetMap contributors) | Dipakai MENURUNKAN koordinat bioenergi (bukan memeriksa); diberi label approximate dengan disclaimer eksplisit di source_notes. |
| Poligon batas provinsi (`indonesia-prov.geojson`) | https://raw.githubusercontent.com/ans-4175/peta-indonesia-geojson/master/indonesia-prov.geojson | 2026-11-03 | MIT License (Ahmad Anshorimuslim Syuhada) | Repositori ans-4175/peta-indonesia-geojson; rincian metodologi & klarifikasi metadata di `province_check.md`. |

## 4. Hasil audit

- Sampel awal 78 baris: masih di staging **49 baris**; dikarantina: **13 baris**; dikeluarkan awal: **16 baris**.
- Nilai dicocokkan otomatis untuk 49 baris staging: nama 48, kapasitas 34, koordinat 15, status 0.
- Tautan valid staging (HTTP 200): **109 dari 128 baris**; perlu cek manual (403/429/timeout): **19 baris**; gagal permanen: 0.
- Gagal audit awal: 16 baris dikeluarkan. Karantina: **41 baris**. Rincian: `logs/audit.md`, `logs/quarantine.md`, `logs/pairs_500m.md`, `logs/province_check.md`, `logs/capacity_basis.md`, `logs/url_check.md`, `logs/proposed_fixes.md`.
- Sanity check visual citra satelit: diperiksa pada sampel kecil (15 dari 64 baris exact staging) via otomasi peramban dengan hasil **15 dari 15 sampel terperiksa tampak sesuai secara fisik**, dan tidak dimaksudkan untuk menggeneralisasi seluruh dataset.

## 5. Cakupan terhadap total nasional (belum diverifikasi)

Sesuai instruksi pengguna, angka kapasitas nasional resmi Kementerian ESDM dan persentase cakupan ditulis **"belum diverifikasi"** sampai diverifikasi langsung oleh pengguna dari publikasi primer.

| Jenis | Operating dataset (MW) | Angka nasional (MW) | Cakupan | Status angka nasional |
|---|---|---|---|---|
| geothermal | 2492.70 | belum diverifikasi | belum diverifikasi | angka resmi ESDM belum diverifikasi pengguna |
| wind | 147.00 | belum diverifikasi | belum diverifikasi | angka resmi ESDM belum diverifikasi pengguna |
| hydro | 5512.32 | belum diverifikasi | belum diverifikasi | angka resmi ESDM belum diverifikasi pengguna |
| solar | 265.80 | belum diverifikasi | belum diverifikasi | angka resmi ESDM belum diverifikasi pengguna |
| bioenergy | 73.70 | belum diverifikasi | belum diverifikasi | angka resmi ESDM belum diverifikasi pengguna |

## 6. Tidak bisa diverifikasi

- Status semua baris; kapasitas/koordinat baris di luar sampel; placeholder unik per baris; basis kapasitas.
- Rilis/versi tracker GEM; tahun dan tautan publikasi ESDM definitif untuk angka nasional.
- Koordinat tapak pabrik bioenergi (yang tercatat adalah sentroid wilayah tingkat desa/kecamatan hasil geocoding OSM Nominatim).
