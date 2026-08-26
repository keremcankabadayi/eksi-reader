# Şükela Lite

Reklamsız, kişisel bir Ekşi Sözlük okuyucusu. Yayınlanmıyor; SideStore ile yalnızca
kendi cihazıma kuruluyor.

Şu an **iskelet aşamasında**: arayüz ayakta ama veri sahte. Bu turun amacı
derleme → release → telefona kurulum hattının uçtan uca çalıştığını görmek.

## Nasıl çalışıyor

```
main'e push
  → GitHub Actions (macos-15 runner) imzasız IPA üretir
  → GitHub Release'e yükler
  → docs/source.json'u günceller  ── SideStore kaynağı
  → telefonda SideStore "Update" gösterir
```

Mac gerekmiyor, kablo gerekmiyor, dosya taşımak gerekmiyor. İmzayı SideStore telefonun
içinde atıyor, o yüzden ürettiğimiz IPA tamamen imzasız (`CODE_SIGNING_ALLOWED=NO`) ve
build tarafında hiçbir Apple ID / sertifika yok.

## Başlarken

Telefon kurulumu için: **[docs/sidestore-kurulum.md](docs/sidestore-kurulum.md)**

Sıra şu:

1. SideStore'u telefona kur (tek seferlik, bir kişisel bilgisayar gerekiyor).
2. Bu repoyu GitHub'a push'la, Actions'taki `build-ipa` işinin yeşile dönmesini bekle.
3. Telefonda SideStore kaynağını ekle, uygulamayı kur.

> **Repo public olmalı.** İki sebeple: public repolarda Actions dakikaları ücretsiz
> (private'ta macOS runner 10x çarpanla ücretsiz kotayı yiyor), ve SideStore release
> asset'ini kimlik doğrulaması olmadan indirebilmeli. Bu yüzden repoya hiçbir token,
> şifre veya çerez koyma.

## Repo yapısı

| Yol | Ne |
|---|---|
| `project.yml` | XcodeGen tanımı. `.xcodeproj` repoda tutulmuyor, her build'de üretiliyor. |
| `Sources/` | SwiftUI kaynak kodu. |
| `Resources/Assets.xcassets` | İkon ve accent color. `Info.plist` XcodeGen tarafından üretiliyor. |
| `build-ipa.sh` | İmzasız IPA üretir → `dist/SukelaLite.ipa`. Sadece macOS. |
| `run-sim.sh` | Simülatörde çalıştırıp `sim-screenshot.png` alır. Sadece macOS. |
| `tools/make-icon.mjs` | App ikonunu bağımlılıksız üretir (saf PNG yazıcı). |
| `tools/update-source.mjs` | `docs/source.json` (SideStore kaynağı) üretir/günceller. |
| `.github/workflows/build-ipa.yml` | Derleme + release + kaynak güncelleme hattı. |
| `VERSION` | Tek sürüm kaynağı. Build numarası CI'ın `run_number`'ı. |

## Sürüm çıkarmak

Build numarası her Actions koşusunda otomatik artıyor, elle bir şey yapmana gerek yok.
Sürüm numarasını yükseltmek istersen `VERSION` dosyasını değiştirip push'la.

## Yerelde derlemek (macOS, opsiyonel)

Zorunlu değil — CI zaten derliyor. Mac'te denemek istersen:

```bash
brew install xcodegen
./build-ipa.sh          # dist/SukelaLite.ipa
./run-sim.sh            # simülatör + sim-screenshot.png
```

Codespaces / Linux'ta derleme **yapılamaz**: iOS SDK ve SwiftUI sadece macOS'ta var.
Kod yazmak, gözden geçirmek ve push'lamak için Codespaces yeterli.

## Sırada ne var

Veri katmanı. Ekşi'nin resmî bir API'si yok, yani HTML parse edilecek — projenin en
kırılgan kısmı orası olacak. Planı: parse'ı platformdan bağımsız bir SwiftPM hedefine
koymak, böylece Linux'ta `swift test` ile Mac'siz test edilebilir.
