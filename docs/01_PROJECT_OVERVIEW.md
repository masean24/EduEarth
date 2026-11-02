# 01 — Project Overview

## Tujuan
Membantu pelajar dan masyarakat Indonesia memahami energi terbarukan lewat **peta pembangkit**, **materi belajar**, dan **kuis**.

## Identitas
- Nama: **EduEarth**
- Tagline: **Explore Energy, Understand Earth.**
- Platform: Android dan iOS (Flutter)
- Bahasa antarmuka: Bahasa Indonesia (siapkan struktur agar mudah ditambah bahasa Inggris nanti)

## Kategori energi (data awal `energy_categories`)

| slug | Nama | Singkatan |
|---|---|---|
| `solar` | Solar Energy | PLTS |
| `hydro` | Hydropower | PLTA |
| `wind` | Wind Energy | PLTB |
| `geothermal` | Geothermal Energy | PLTP |
| `bioenergy` | Bioenergy | PLTBm / PLTBg |

## 24 fitur dan pembagian prioritas

**MVP (Fase 0–3) — harus ada untuk demo pertama**
1. Splash Screen
2. Onboarding
3. Login dan Register
4. Home Dashboard
5. Explore Map
6. Map Filter
7. Plant Preview (bottom sheet)
8. Plant Detail (termasuk tombol "Buka di Google Maps")
9. Nearby Plants
10. Learning Dashboard
11. Energy Category
12. Learning Detail
13. Bookmark

**Inti lanjutan (Fase 4–5)**
14. Quiz Dashboard
15. Quiz Gameplay
16. Quiz Result
17. Profile
18. My Learning
19. Settings
20. About EduEarth
21. Global Search

**Fitur lanjutan (Fase 6)**
22. Achievement
23. Notification Center
24. Energy Comparison

## Prinsip produk
- **Akurasi di atas kuantitas.** Lebih baik 20 pembangkit terverifikasi daripada 200 data asal.
- **Setiap data pembangkit punya sumber** (`source_url`, `verified_at`).
- **Edukatif dan ringan.** Materi singkat, visual jelas, kuis yang memberi penjelasan.
- **Performa dulu.** Glass effect dipakai selektif, bukan di mana-mana.

## Di luar cakupan (jangan dikerjakan kecuali diminta)
- Fitur sosial/komentar/chat.
- Pembayaran atau langganan.
- Panel admin di dalam app (konten dikelola lewat Supabase dashboard).
- Mode offline penuh.
