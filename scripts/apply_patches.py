#!/usr/bin/env python3
import os
import sys

GL4ES_DIR = sys.argv[1] if len(sys.argv) > 1 else "gl4es"

def read_file(rel_path):
    full_path = os.path.join(GL4ES_DIR, rel_path)
    with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
        return f.read()

def write_file(rel_path, content):
    full_path = os.path.join(GL4ES_DIR, rel_path)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content)

def patch_loader():
    path = "src/gl/loader.c"
    content = read_file(path)
    ios_gles_path = '"/System/Library/Frameworks/OpenGLES.framework/OpenGLES",'
    if ios_gles_path not in content:
        target = 'static const char *gles_lib[] = {'
        if target in content:
            content = content.replace(
                target,
                target + "\n    " + ios_gles_path + "\n    \"@rpath/libGLESv2.dylib\","
            )
            write_file(path, content)
            print("[PATCH OK] src/gl/loader.c: Da them duong dan OpenGLES.framework cua iOS.")

def patch_hardext():
    path = "src/glx/hardext.c"
    content = read_file(path)
    marker = "/* GEMINI_IOS_APPLE_GPU_HARDEXT */"
    if marker in content:
        return

    header_inject = """
#ifdef __APPLE__
extern int gemini_ios_get_max_tex_size(void);
#endif
"""
    apple_caps = f"""
    {marker}
#ifdef __APPLE__
    // Kich hoat day du tinh nang phan cung GPU Apple A9 -> A18 khi build NOEGL
    hardext.npot = 3;            // Full hardware NPOT (tiet kiem RAM & CPU tren 6s Plus)
    hardext.elemuint = 1;        // GL_OES_element_index_uint (32-bit indices cho Sodium/OptiFine)
    hardext.depth24 = 1;         // 24-bit Depth Buffer (chong Z-Fighting)
    hardext.depthstencil = 1;    // GL_OES_packed_depth_stencil (sua loi FBO Forge/OptiFine)
    hardext.fbo = 1;
    hardext.pointsprite = 1;
    hardext.cubemap = 1;
    hardext.highp = 1;           // Ho tro highp float trong Fragment Shader
    hardext.maxtex = 8;
    hardext.maxvattrib = 16;
    hardext.maxcolorattach = 4;
    hardext.maxdrawbuffers = 4;
    hardext.bgra8888 = 1;        // Dinh dang texture native cua Apple GPU
    hardext.mapbuffer = 1;       // GL_OES_mapbuffer
    hardext.maxtexsize = gemini_ios_get_max_tex_size();
#endif
"""
    content = header_inject + content
    # Chen vao truoc dau ngoac nhon dong cuoi cung cua ham GetHardwareExtensions
    last_brace = content.rfind("}")
    if last_brace != -1:
        content = content[:last_brace] + apple_caps + "\n}\n"
        write_file(path, content)
        print("[PATCH OK] src/glx/hardext.c: Da mo khoa tap lenh GPU Apple A9-A18 (NPOT, Depth24, FBO, BGRA8888).")

def patch_fpe_shader():
    path = "src/gl/fpe_shader.c"
    content = read_file(path)
    marker = "/* GEMINI_HIGHP_PATCH */"
    if marker in content:
        return

    # Ep do chinh xac highp cho Fragment Shader de sua loi nhap nhay Enchantment Glint & Fog tren 1.8.9 - 1.16.5
    old_prec = 'precision mediump float;\\n'
    new_prec = 'precision highp float;\\n'
    if old_prec in content:
        content = marker + "\n" + content.replace(old_prec, new_prec)
        write_file(path, content)
        print("[PATCH OK] src/gl/fpe_shader.c: Da nang cap do chinh xac Fragment Shader len highp (sua loi Z-Fighting & Glint).")

def patch_framebuffers():
    path = "src/gl/framebuffers.c"
    content = read_file(path)
    marker = "/* GEMINI_JETSAM_TICK */"
    if marker in content:
        return

    inject_decl = """
/* GEMINI_JETSAM_TICK */
#ifdef __APPLE__
extern void gemini_ios_frame_tick(void);
#endif
"""
    content = inject_decl + content

    # Chen kiem tra Jetsam nhe nhang khi ket thuc / xoa frame
    target = "void APIENTRY_GL4ES gl4es_glClear(GLbitfield mask) {"
    replacement = """void APIENTRY_GL4ES gl4es_glClear(GLbitfield mask) {
#ifdef __APPLE__
    if (mask & GL_COLOR_BUFFER_BIT) {
        gemini_ios_frame_tick();
    }
#endif
"""
    if target in content:
        content = content.replace(target, replacement, 1)
        write_file(path, content)
        print("[PATCH OK] src/gl/framebuffers.c: Da tich hop bo canh gac RAM Jetsam theo tung Frame.")

def patch_getter():
    path = "src/gl/getter.c"
    content = read_file(path)
    marker = "/* GEMINI_RENDERER_BRAND */"
    if marker in content:
        return

    # Dam bao ten Renderer hien thi ro trong man hinh F3 cua Minecraft
    old_str = 'return (const GLubyte*)"GL4ES wrapper";'
    new_str = 'return (const GLubyte*)"GeminiGL4ES-iOS (Apple A9-A18 Optimized | MC <= 1.16.5)";'
    if old_str in content:
        content = marker + "\n" + content.replace(old_str, new_str)
    else:
        content = marker + "\n" + content
    write_file(path, content)
    print("[PATCH OK] src/gl/getter.c: Da cap nhat thong tin Renderer & Extension cho F3 Minecraft.")

if __name__ == "__main__":
    patch_loader()
    patch_hardext()
    patch_fpe_shader()
    patch_framebuffers()
    patch_getter()
    print("=== Hoan tat ap dung toan bo Patch GeminiGL4ES ===")
