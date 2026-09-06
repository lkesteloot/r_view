// Turns the bytes of an image file into RGBA pixels.
//
// The obvious way to do this is createImageBitmap() into a canvas and then
// getImageData(). That works, but a canvas stores colors premultiplied by
// alpha, so the round trip changes the color of every partly transparent pixel
// by a unit or two. In a program whose job is to report exact colors that's not
// acceptable, so we prefer WebCodecs, which hands back the bytes the file
// actually contains. The canvas is the fallback, and it's exact for opaque
// images, which is most of them.

import { type SourceImage } from "../core/compose.js";

// WebCodecs' ImageDecoder isn't in lib.dom yet.
interface ImageDecoderInit {
    data: ArrayBufferView | ArrayBuffer;
    type: string;
    colorSpaceConversion?: "none" | "default";
}
interface ImageDecoderResult {
    image: VideoFrame;
    complete: boolean;
}
interface ImageDecoderClass {
    new (init: ImageDecoderInit): {
        decode(): Promise<ImageDecoderResult>;
        close(): void;
    };
    isTypeSupported(type: string): Promise<boolean>;
}
declare const ImageDecoder: ImageDecoderClass | undefined;

// Interleaved formats we can read directly. Anything else (planar YUV, say) is
// from a format without alpha, where the canvas path is exact anyway.
const DIRECT_FORMATS = new Set(["RGBA", "RGBX", "BGRA", "BGRX"]);

function frameToImage(frame: VideoFrame, data: Uint8ClampedArray): SourceImage | undefined {
    const format = frame.format;
    if (format === null || !DIRECT_FORMATS.has(format)) {
        return undefined;
    }

    const width = frame.displayWidth;
    const height = frame.displayHeight;
    if (data.length !== width*height*4) {
        return undefined;
    }

    if (format === "BGRA" || format === "BGRX") {
        for (let i = 0; i < data.length; i += 4) {
            const blue = data[i]!;
            data[i] = data[i + 2]!;
            data[i + 2] = blue;
        }
    }
    if (format === "RGBX" || format === "BGRX") {
        for (let i = 3; i < data.length; i += 4) {
            data[i] = 255;
        }
    }

    return { width, height, data };
}

async function decodeWithWebCodecs(bytes: Uint8Array, mimeType: string):
        Promise<SourceImage | undefined> {

    if (typeof ImageDecoder === "undefined" || !(await ImageDecoder.isTypeSupported(mimeType))) {
        return undefined;
    }

    // Keep the file's own color values instead of converting them into the
    // display's profile, which would change the numbers we report.
    const decoder = new ImageDecoder({
        data: bytes,
        type: mimeType,
        colorSpaceConversion: "none",
    });

    try {
        const { image: frame } = await decoder.decode();
        try {
            if (frame.allocationSize() !== frame.displayWidth*frame.displayHeight*4) {
                return undefined;
            }
            const data = new Uint8ClampedArray(frame.allocationSize());
            await frame.copyTo(data);
            return frameToImage(frame, data);
        } finally {
            frame.close();
        }
    } finally {
        decoder.close();
    }
}

async function decodeWithCanvas(bytes: Uint8Array, mimeType: string | undefined):
        Promise<SourceImage> {

    // A copy, because Blob wants a view that owns a plain ArrayBuffer.
    const copy = new Uint8Array(bytes.byteLength);
    copy.set(bytes);
    const blob = new Blob([copy], mimeType === undefined ? undefined : { type: mimeType });

    const bitmap = await createImageBitmap(blob, {
        colorSpaceConversion: "none",
        premultiplyAlpha: "none",
    });

    try {
        const canvas = new OffscreenCanvas(bitmap.width, bitmap.height);
        const ctx = canvas.getContext("2d", { colorSpace: "srgb", willReadFrequently: true });
        if (ctx === null) {
            throw new Error("Can't get a 2D canvas context.");
        }

        ctx.drawImage(bitmap, 0, 0);
        const imageData = ctx.getImageData(0, 0, bitmap.width, bitmap.height);

        return { width: bitmap.width, height: bitmap.height, data: imageData.data };
    } finally {
        bitmap.close();
    }
}

export async function decodeImage(bytes: Uint8Array, mimeType: string | undefined):
        Promise<SourceImage> {

    if (mimeType !== undefined) {
        const image = await decodeWithWebCodecs(bytes, mimeType).catch(() => undefined);
        if (image !== undefined) {
            return image;
        }
    }

    return await decodeWithCanvas(bytes, mimeType);
}
