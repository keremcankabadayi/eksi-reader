#!/usr/bin/env node
// Uygulama ikonunu bağımlılık olmadan üretir (saf zlib + Buffer PNG yazıcı).
//
// Çıktı:
//   Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png  (iOS app icon, alfa yok)
//   docs/icon.png                                               (SideStore kaynağı için 256px)
import { deflateSync } from "node:zlib";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");

const BG = [0x16, 0x18, 0x1d];
const FG = [0x81, 0xc1, 0x4b];
const DIM = [0x3a, 0x45, 0x2a];

// Koyu zemin üzerine entry satırlarını andıran yatay çubuklar.
// Koordinatlar 16 birimlik bir ızgarada; boyuttan bağımsız.
const BARS = [
  [3.0, 3.0, 10.0, 1.4, FG],
  [3.0, 5.6, 8.0, 1.4, DIM],
  [3.0, 8.2, 9.5, 1.4, DIM],
  [3.0, 10.8, 5.0, 1.4, FG],
];

const CRC_TABLE = (() => {
  const table = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c;
  }
  return table;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (const byte of buf) c = CRC_TABLE[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(tag, data) {
  const body = Buffer.concat([Buffer.from(tag, "ascii"), data]);
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}

function render(size) {
  const u = size / 16;
  // Her satır: 1 filtre baytı + size * 3 renk baytı.
  const raw = Buffer.alloc(size * (1 + size * 3));
  let p = 0;
  for (let y = 0; y < size; y++) {
    raw[p++] = 0; // filtre: none
    for (let x = 0; x < size; x++) {
      let color = BG;
      for (const [bx, by, bw, bh, c] of BARS) {
        if (x >= bx * u && x < (bx + bw) * u && y >= by * u && y < (by + bh) * u) {
          color = c;
          break;
        }
      }
      raw[p++] = color[0];
      raw[p++] = color[1];
      raw[p++] = color[2];
    }
  }
  return raw;
}

function writePng(path, size) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; // bit derinliği
  ihdr[9] = 2; // renk tipi 2 = truecolor, alfa yok (iOS app icon şartı)

  const png = Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr),
    chunk("IDAT", deflateSync(render(size), { level: 9 })),
    chunk("IEND", Buffer.alloc(0)),
  ]);

  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, png);
  console.log(`yazıldı: ${relative(ROOT, path)} ${size}x${size} ${png.length}B`);
}

writePng(join(ROOT, "Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"), 1024);
writePng(join(ROOT, "docs/icon.png"), 256);
