module cairo.loader;
import bindbc.loader;
import cairo.types;
import cairo.funcs;

enum CairoSupport {
    noLibrary,
    badLibrary,
    cairo
}

private {
    SharedLib lib;
    CairoSupport loadedVersion;
}

@nogc nothrow:

CairoSupport loadedCairoVersion() {
    return loadedVersion;
}

bool isCairoLoaded() {
    return lib != invalidHandle;
}

CairoSupport loadCairo() {
    version (Windows) {
        const(char)[][1] libNames =
            [
                "cairo.dll"
            ];
    } else version (OSX) {
        const(char)[][1] libNames =
            [
                "libcairo.dylib"
            ];
    } else version (Posix) {
        const(char)[][2] libNames =
            [
                "libcairo.so",
                "/usr/local/lib/libcairo.so",
            ];
    } else
        static assert(0, "libcairo is not yet supported on this platform.");

    CairoSupport ret;
    foreach (name; libNames) {
        ret = loadCairo(name.ptr);
        if (ret != CairoSupport.noLibrary)
            break;
    }
    return ret;
}

CairoSupport loadCairo(const(char)* libName) {
    lib = load(libName);
    if (lib == invalidHandle) {
        return CairoSupport.noLibrary;
    }

    int loaded;
    loadedVersion = CairoSupport.badLibrary;
    import std.algorithm.searching : startsWith;

    static foreach (m; __traits(allMembers, cairo.funcs)) {
        static if (m.startsWith("cairo_")) {
            lib.bindSymbol(
                cast(void**)&__traits(getMember, cairo.funcs, m),
                __traits(getMember, cairo.funcs, m).stringof
            );
            loaded++;
        }
    }

    loaded -= errorCount();
    if (loaded <= 0)
        return CairoSupport.badLibrary;

    loadedVersion = CairoSupport.cairo;
    return loadedVersion;
}

void unloadCairo() {
    unload(lib);
    lib = invalidHandle;
    
    import std.algorithm.searching : startsWith;
    static foreach (m; __traits(allMembers, cairo.funcs)) {
        static if (m.startsWith("cairo_")) {
            __traits(getMember, cairo.funcs, m) = null;
        }
    }
}
