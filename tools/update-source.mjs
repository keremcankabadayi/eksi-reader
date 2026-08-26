#!/usr/bin/env node
// docs/source.json dosyasını üretir/günceller.
//
// Bu dosya bir AltStore/SideStore kaynağıdır. SideStore telefonda bu URL'yi
// periyodik olarak okur; yeni bir sürüm girişi görünce "Update" çıkarır.
//
// Kullanım:
//   # sadece iskeleti oluştur (sürüm eklemeden)
//   node tools/update-source.mjs --repo keremcankabadayi/eksi-reader
//
//   # CI'da yeni sürüm ekle
//   node tools/update-source.mjs --repo owner/name --version 1.0.0 \
//       --build 12 --tag v1.0.0-12 --ipa dist/SukelaLite.ipa --date 2026-08-26
import { readFileSync, writeFileSync, mkdirSync, statSync, existsSync } from "node:fs";
import { dirname, join, isAbsolute } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const SOURCE_PATH = join(ROOT, "docs", "source.json");
const BUNDLE_ID = "com.kerem.sukelalite";
const APP_NAME = "Şükela Lite";
const KEEP_VERSIONS = 5;

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i += 2) {
    if (!argv[i].startsWith("--")) die(`beklenmeyen argüman: ${argv[i]}`);
    out[argv[i].slice(2)] = argv[i + 1];
  }
  return out;
}

function die(msg) {
  console.error(`hata: ${msg}`);
  process.exit(1);
}

const args = parseArgs(process.argv.slice(2));
if (!args.repo) die("--repo owner/name gerekli");

const rawBase = `https://raw.githubusercontent.com/${args.repo}/main`;

let versions = [];
if (existsSync(SOURCE_PATH)) {
  try {
    versions = JSON.parse(readFileSync(SOURCE_PATH, "utf8")).apps[0].versions ?? [];
  } catch {
    versions = [];
  }
}

if (args.version) {
  const missing = ["build", "tag", "ipa", "date"].filter((k) => !args[k]);
  if (missing.length) die(`--version ile birlikte gerekli: ${missing.map((m) => "--" + m).join(", ")}`);

  const ipaPath = isAbsolute(args.ipa) ? args.ipa : join(ROOT, args.ipa);
  const entry = {
    version: args.version,
    buildVersion: String(args.build),
    date: args.date,
    localizedDescription: args.notes ?? "Otomatik build.",
    downloadURL: `https://github.com/${args.repo}/releases/download/${args.tag}/SukelaLite.ipa`,
    size: statSync(ipaPath).size,
    minOSVersion: "16.0",
  };

  // Aynı build tekrar koşarsa çift giriş olmasın.
  versions = versions.filter(
    (v) => !(v.version === entry.version && v.buildVersion === entry.buildVersion),
  );
  versions.unshift(entry);
  versions = versions.slice(0, KEEP_VERSIONS);
}

const source = {
  name: APP_NAME,
  identifier: `${BUNDLE_ID}.source`,
  subtitle: "Reklamsız kişisel Ekşi Sözlük okuyucusu",
  description:
    "Kişisel kullanım için yazılmış, reklamsız Ekşi Sözlük okuyucusu. " +
    "Yayınlanmıyor; SideStore ile kendi cihaza kuruluyor.",
  iconURL: `${rawBase}/docs/icon.png`,
  website: `https://github.com/${args.repo}`,
  tintColor: "#81C14B",
  apps: [
    {
      name: APP_NAME,
      bundleIdentifier: BUNDLE_ID,
      developerName: "kerem",
      subtitle: "Reklamsız Ekşi okuyucusu",
      localizedDescription:
        "Gündem ve debe akışlarını reklamsız okumak için yazılmış kişisel istemci.",
      iconURL: `${rawBase}/docs/icon.png`,
      tintColor: "#81C14B",
      category: "reading",
      screenshots: [],
      versions,
    },
  ],
  news: [],
};

mkdirSync(dirname(SOURCE_PATH), { recursive: true });
writeFileSync(SOURCE_PATH, JSON.stringify(source, null, 2) + "\n");
console.log(`docs/source.json yazıldı (${versions.length} sürüm)`);
