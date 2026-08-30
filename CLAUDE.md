# Şükela Lite — çalışma notları

Reklamsız, kişisel Ekşi Sözlük okuyucusu. Yayınlanmayacak, App Store'a gitmeyecek.

## Değişmez kararlar

- **Mevcut uygulamalar kırılmıyor.** İstemci sıfırdan yazılıyor.
- **Dağıtım SideStore.** Ücretsiz imza, telefonda otomatik yenileme.
- **Derleme GitHub Actions `macos-15` runner'ında.** Geliştirme makinesinde Mac yok.
- **İki repo var.** `eksi-reader` (bu repo, private) kodu ve CI'ı tutuyor;
  `er-dist` (public) yalnızca `docs/source.json`, `docs/icon.png` ve
  Release'lerdeki IPA'ları tutuyor. **Dist reposu public kalmak zorunda** — SideStore
  ikisini de kimlik doğrulaması olmadan indiriyor. Hiçbirine token, şifre veya çerez
  koyma; dist'e yazma yetkisi `DIST_TOKEN` secret'ında.
- **`docs/source.json` bu repoda takip edilmiyor.** Sürüm geçmişi dist reposunda
  yaşıyor; CI her koşuda dist'i klonlayıp geçmişi oradan alıyor, üstüne yeni sürümü
  ekleyip geri yazıyor. Bu repoda tuttuğumuz kopya bayatlar, o yüzden `.gitignore`'da.
- **Her build'in `version`'ı farklı.** SideStore güncellemeyi kaynaktaki
  `version` alanına bakarak buluyor; `buildVersion` tek başına tetiklemiyor.
  CI yama numarasını build numarasına eşitliyor (`VERSION` dosyası `1.0.0`,
  build 15 → `1.0.15`, tag `v1.0.15`). `VERSION` dosyasında major.minor'ı
  değiştir, yama hanesine dokunma.
- **Bundle ID sabit: `com.kerem.sukelalite`.** Apple haftada 10 yeni App ID'ye izin
  veriyor; aynı bundle ID'yi yeniden kurmak kotadan yemiyor. Değiştirme.
- **Deployment target iOS 16.0.** `NavigationStack` bunu gerektiriyor. Düşürmek
  gerekirse `NavigationView`'a dönmek gerekir.

## Yapı

- `.xcodeproj` repoda **yok**, `project.yml`'den XcodeGen üretiyor. Yeni Swift dosyası
  eklerken projeye ayrıca kaydetmen gerekmiyor — `Sources/` altına koyman yeterli.
- `Info.plist` de üretiliyor (`project.yml` içindeki `info.properties`). Elle düzenleme,
  değişiklik `project.yml`'e yazılır.
- İkon `tools/make-icon.mjs` ile üretiliyor, bağımlılık yok. İkonu değiştireceksen
  betikteki `BARS` / renk sabitlerini düzenle.
- Araç betikleri Node ile yazıldı, Python değil: bu Codespaces imajındaki Python
  stdlib kırpılmış (`json` modülü bile yok), Node hem burada hem macOS runner'da var.

## Giriş

Yazar girişi Ekşi'nin kendi `/giris` sayfasında, gömülü bir `WKWebView`
içinde yapılıyor (`LoginView`). **Şifre uygulamaya hiç uğramıyor**, captcha ve
benzeri ne varsa sitenin akışında kalıyor. Giriş bitince elimizde kalan tek
şey çerezler; onları WebKit'in kendi deposu (`WKWebsiteDataStore.default()`)
diskte tutuyor ve veri çeken gizli tarayıcı da aynı depoyu kullandığı için
istekler kendiliğinden girişli oluyor. Ayrıca bir yere çerez kopyalamıyoruz.
`AuthSession` yalnızca "girişli miyiz, nick ne" bilgisini saklıyor.

Dikkat: `SessionBridge` Ekşi çerezlerinin hepsini App Group'a yazıyor, oturum
çerezi de buna dahil. Aynı uygulamanın kutusu, ama widget'a giden veriyi
genişletirken bunu hatırla.

## Oylama

Artı/eksi düğmeleri `EntryRow`'da, işi `VoteService` yapıyor. İstek
`WebViewFetcher.post` ile gidiyor: sayfa içi `fetch()` artık GET dışında
gövde de taşıyor, çerezi ve Referer'ı yine tarayıcı koyuyor.

- **Verilmiş oy sayfadan okunuyor**, bizde tutulmuyor: Ekşi entry'nin
  `<li>`'sine `data-isliked` / `data-isdisliked` yazıyor, `EntryPageParser`
  bunu `Entry.vote`'a çeviriyor. Uygulama kapanıp açılınca oy yerinde duruyor.
- `VoteService.overrides` yalnızca geçici üstyazım: düğmeye basınca renk
  taze sayfayı beklemeden değişsin diye. Sayfa yeniden çekilince
  `adopt(_:)` üstyazımı atıyor, sunucunun dediği geçerli oluyor.
- Uçlar sitenin kendi `#title` özniteliklerinden: `/entry/vote` ve
  `/entry/removevote`. Gövde ikisinde de `id`, `owner`, `rate`; geri
  alırken de `rate` basılan okun yönünü taşıyor.
- Yanıt `{"SuccessData":{"Success":…,"Message":…},"LikeCount":…}`.
  Oturum yoksa JSON değil, düz `nologin` geliyor — `VoteParser` bunu ayrı
  hata sayıp `AuthSession`'ı tazeliyor. Antiforgery anahtarı gerekmiyor,
  sitenin kendi JS'i de göndermiyor.
- Sunucu reddederse üstyazım düşüyor, başlık ekranında uyarı çıkıyor.

Bu uçlar ve öznitelikler canlı siteden doğrulandı: sayfanın HTML'i
web.archive.org'dan, oy mantığı `ekstat.com/js/ek$i-combo.js` içinden
okundu (eksisozluk.com'un kendisi buradan 403 veriyor, ikisi vermiyor).

## Favorileyenler

Entry'nin altındaki kalp+sayı bir düğme: dokununca favorileyen yazarlar
kartta açılıyor (`FavoriteListView`). Sayı sıfırken düğme hiç çizilmiyor.

Liste entry ile gelmiyor, ayrı adreste: `/entry/favorileyenler?entryId=…`
parça HTML döndürüyor. `FavoriteListParser` sarmalayana bakmıyor, yazar
bağlantılarını (`/biri/<nick>`) topluyor — işaretleme değişse de ayakta
kalsın diye. Aynı parçadaki "çaylakları göster" bağlantısı yazar değil,
listeye girmiyor.

Favorileme (`/entry/favla`, `/entry/favlama`) henüz yok, yalnızca okuma var.

## Debe destesi ve okundu takibi

Debe'de her satır tek bir entry, o yüzden başlık ekranı liste değil bir
deste (`CatchUpSwipe`). Slack'in "catch up" ekranı gibi tek karar var:

- **sağdan sola** (kartı sola at) → okundu
- **soldan sağa** (kartı sağa at) → okunmadı bırak

İki yön de sıradaki entry'ye geçiriyor, fark yalnızca okundu kaydında.
Deste bitince ekran kapanıp listeye dönüyor. Alt gezinme barı yok:
tek gezinme kaydırma.

Ekran düzeni: üstte kalan okunmamış sayısı + ilerleme şeridi + yön ipucu,
altında iki ayrı kart — başlık kartı ve entry kartı (`cardSurface()`).
Zebra yalnız gündemin liste düzeninde kaldı.

Kaydırma 3D: kart perspektifle dönüp elden çıkarken arkasında sıradaki
entry'nin kartı büyüyor, kararın ne olduğu damgada yazıyor (adaçayı
"okundu", amber "okunmadı"). Ayrıntılar:

- Yatay/dikey ekseni gesture'ın ilk noktalarında bir kez seçiliyor;
  kartlar dikey kaydırılırken deste dönmesin diye.
- Sol kenardan başlayan sağa kaydırma sistemin geri hareketi, ona
  karışmıyoruz.

Okundu kaydı `ReadTracker`'da: `UserDefaults`'ta `readTopicIDs`, en fazla
800 `Topic.id`. **Okundu yalnız kaydırma kararıyla düşüyor**, entry'yi
açmak yetmiyor. Debe listesinde okunmamışın solunda nokta, okunmuş satır
soluk, üst barda kalan sayı; gündemde bu izin hiçbiri yok (`TopicRow.isRead`
nil geçiyor). Ayarlardan sıfırlanıyor. App Group'a yazılmıyor.

## Widget

Gündem widget'ı `Widget/` altında, ayrı bir app-extension hedefi. **Veriyi kendi
çekmiyor:** Cloudflare'ı WKWebView ile aşıyoruz, extension'da WebView yok. Uygulama
gündemi her çektiğinde App Group'a (`group.com.kerem.sukelalite`) yazıyor, widget
oradan okuyor. Yani widget "uygulamanın son gördüğü gündem"i gösteriyor.

Dokununca `sukela://topic?link=...` açılıyor, `RootView.onOpenURL` başlığı gündem
sekmesinin yığınına ekliyor.

App Group ücretsiz imzada sorun çıkarabilir: SideStore/AltStore Info.plist'teki
`ALTAppGroups` anahtarını okuyup entitlement'ı kendisi üretiyor. Çalışmazsa widget
"gündem yok" gösterir, uygulama etkilenmez. LiveContainer ile kurulumda
extension'lar hiç çalışmıyor.

## Sınırlar (Apple kaynaklı, bizim seçimimiz değil)

- Ücretsiz imza 7 gün geçerli.
- Aynı anda 3 sideload uygulaması, SideStore'un kendisi dahil.
- Haftada 10 yeni App ID.

Sonuç: **ikinci bir kişisel araç gerekirse ayrı uygulama yapma, aynı uygulamaya sekme
ekle.** Slot maliyeti sıfır.

## Doğrulama

- Linux'ta Swift kodu derlenemez. Değişiklik sonrası tek gerçek doğrulama CI'ın yeşil
  olması; Actions çıktısına bak.
- **`build-ipa` artık her push'ta koşmuyor.** macOS runner dakikası 10x çarpanla
  faturalanıyor ve tek başına aylık kotanın yarısını yiyordu. Otomatik tetik yalnızca
  `VERSION` değişince; onun dışında Actions sekmesinden "Run workflow" ile elle
  tetikle. Yani derlemenin doğruluğunu görmek istiyorsan build'i sen başlatacaksın.
  `core-tests` Linux'ta (1x) her push'ta koşmaya devam ediyor.
- Arka arkaya push'larda `build-ipa` eski koşuyu iptal eder (`cancel-in-progress`).
  Son push kazanır; ara commit'ler için ayrı IPA çıkmaz.
- Telefondaki build'in doğru olduğunu uygulamanın **ayarlar** sekmesindeki sürüm
  satırından kontrol et.
- `tools/*.mjs` değişirse `node tools/update-source.mjs --repo <owner>/<name>` ve
  `node tools/make-icon.mjs` yerelde koşturulabilir.

## Sırada

Veri katmanı: Ekşi'nin resmî API'si yok, HTML parse edilecek. Parse mantığı
platformdan bağımsız bir SwiftPM hedefine konacak ki Linux'ta `swift test` ile
Mac olmadan test edilebilsin. `MockFeedProvider` yerini gerçek `FeedProviding`
uygulamasına bırakacak; protokol sınırı bunun için var.
