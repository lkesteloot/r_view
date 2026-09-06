// Works out what kind of image a file holds. The decoder needs a MIME type, and
// the bytes are more trustworthy than the extension, so we sniff first and fall
// back to the name.

const EXTENSIONS = new Map<string, string>([
    ["png", "image/png"],
    ["jpg", "image/jpeg"],
    ["jpeg", "image/jpeg"],
    ["jpe", "image/jpeg"],
    ["gif", "image/gif"],
    ["webp", "image/webp"],
    ["avif", "image/avif"],
    ["bmp", "image/bmp"],
    ["ico", "image/x-icon"],
]);

// The extensions we tell the Open dialog about.
export const IMAGE_EXTENSIONS: readonly string[] = [...EXTENSIONS.keys()];

function startsWith(bytes: Uint8Array, offset: number, signature: readonly number[]): boolean {
    if (bytes.length < offset + signature.length) {
        return false;
    }
    return signature.every((byte, i) => bytes[offset + i] === byte);
}

function ascii(text: string): number[] {
    return [...text].map((c) => c.charCodeAt(0));
}

// The type from the file's magic bytes, or undefined if we don't recognize them.
export function sniffMimeType(bytes: Uint8Array): string | undefined {
    if (startsWith(bytes, 0, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
        return "image/png";
    }
    if (startsWith(bytes, 0, [0xFF, 0xD8, 0xFF])) {
        return "image/jpeg";
    }
    if (startsWith(bytes, 0, ascii("GIF87a")) || startsWith(bytes, 0, ascii("GIF89a"))) {
        return "image/gif";
    }
    if (startsWith(bytes, 0, ascii("RIFF")) && startsWith(bytes, 8, ascii("WEBP"))) {
        return "image/webp";
    }
    if (startsWith(bytes, 0, ascii("BM"))) {
        return "image/bmp";
    }
    if (startsWith(bytes, 0, [0x00, 0x00, 0x01, 0x00])) {
        return "image/x-icon";
    }
    // ISO base media: a "ftyp" box whose brand says which flavor.
    if (startsWith(bytes, 4, ascii("ftyp"))) {
        const brand = String.fromCharCode(...bytes.slice(8, 12));
        if (brand === "avif" || brand === "avis") {
            return "image/avif";
        }
    }

    return undefined;
}

export function mimeTypeFromName(name: string): string | undefined {
    const dot = name.lastIndexOf(".");
    if (dot < 0) {
        return undefined;
    }
    return EXTENSIONS.get(name.slice(dot + 1).toLowerCase());
}

export function mimeTypeFor(name: string, bytes: Uint8Array): string | undefined {
    return sniffMimeType(bytes) ?? mimeTypeFromName(name);
}
