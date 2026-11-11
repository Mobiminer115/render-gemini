# 🚀 GeminiGL4ES — Custom iOS Renderer cho Amethyst-iOS (Minecraft ≤ 1.16.5)

Renderer tùy biến dựa trên lõi **GL4ES**, được thiết kế chuyên biệt cho **Minecraft: Java Edition từ 1.16.5 trở xuống (Java 8)** trên hệ điều hành iOS, hỗ trợ mượt mà từ **iPhone 6s Plus (Apple A9, 2GB RAM)** đến **iPhone 16 Pro Max (Apple A18 Pro)**.

## ✨ Tính năng nổi bật
* **Dynamic Hardware Tiering (`ios_gemini_tier.m`):** Tự động nhận diện dung lượng RAM vật lý:
  * **Tier 1 (≤ 2GB RAM - iPhone 6s Plus / 6s / SE1 / 7 / 8):** Giới hạn trần Texture `4096`, tự động theo dõi `os_proc_available_memory()` mỗi 180 frames để xả bộ đệm trước khi bị **iOS Jetsam** kill app.
  * **Tier 2 & Tier 3 (3GB – 8GB+ RAM):** Mở khóa trần Texture `8192` – `16384` và mở rộng bộ đệm VBO.
* **Mở khóa phần cứng Apple GPU (`hardext.c`):** Kích hoạt trực tiếp Full NPOT (`npot = 3`), `GL_OES_element_index_uint` (32-bit indices), `GL_OES_depth24`, `GL_OES_packed_depth_stencil` và `GL_EXT_texture_format_BGRA8888`.
* **Sửa lỗi đồ họa & Mod (`fpe_shader.c`, `framebuffers.c`):**
  * Chuyển Fragment Shader nội bộ sang `highp float` giúp xóa bỏ hoàn toàn lỗi Z-fighting, lỗi sương mù và nhấp nháy Enchantment Glint.
  * Tương thích tốt với **OptiFine (1.7.10 / 1.8.9 / 1.12.2 / 1.16.5)**, **Forge** và **Sodium (Fabric 1.16.5)**.

## 📦 Cách lấy file `.dylib` và tích hợp vào Amethyst-iOS
1. Vào tab **Actions** trên GitHub repo này → chọn workflow **Build GeminiGL4ES iOS Renderer** mới nhất.
2. Tải gói **GeminiGL4ES-Amethyst-iOS-arm64** về máy và giải nén lấy file `libgl4es_114.dylib`.
3. Mở file `Amethyst.ipa` / `Amethyst.tipa` (hoặc thư mục `Payload/Amethyst.app/Frameworks/` trên thiết bị qua Filza):
   * Ghi đè file `libgl4es_114.dylib` vào trong `Amethyst.app/Frameworks/`.
   * Mở Amethyst-iOS, chọn Renderer **GL4ES 1.1.4 (1.7.10 - 1.16.5)** và vào game!
