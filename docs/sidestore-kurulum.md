# SideStore kurulumu ve Şükela Lite'ı telefona alma

Bu doküman iki bölüm: önce SideStore'u telefona kurmak (tek seferlik), sonra
bu repodan üretilen uygulamayı SideStore kaynağı olarak eklemek (yine tek seferlik,
ondan sonrası otomatik).

## Neye ihtiyacın var

- iOS 15 veya üstü bir iPhone. **Cihaz parolası açık olmalı** — parolasız cihazda
  SideStore çalışmıyor.
- Tek seferlik bir kişisel bilgisayar (Windows, macOS veya Linux fark etmez) ve bir
  USB kablo. Şirket bilgisayarı MDM yüzünden eşleşmeyi engelleyebilir; evdeki bir
  makine ya da bir arkadaşınınki yeterli. Bu adımdan sonra bilgisayara bir daha
  dönmeyeceksin.
- Ağ bağlantısı. İlk kurulum sırasında Wi-Fi kullan. Sonraki yenilemeler
  LocalDevVPN/StosVPN ile mobil veride de çalışıyor — bu kısıt eski WireGuard
  kurulumuna aitti, artık geçerli değil.
- **Ayrı bir Apple ID.** Aşağıda neden.

### Neden ayrı bir Apple ID

SideStore imzalama için Apple ID'ne geliştirici oturumu açıyor. SideStore'un kendi
dokümanı, eski veya üçüncü parti anisette sunucularının hesap kilitlenmesine yol
açtığının bilindiğini söylüyor. Resmî sunucu ayarında kalsan bile iCloud'un,
fotoğraflarının ve satın almalarının bağlı olduğu asıl hesabını bu işe sokma.
Telefonun ana Apple ID'sini değiştirmene gerek yok; ikisi bağımsız çalışıyor.

## Bölüm 1 — SideStore'u kur

### iLoader'ı nereden indireceksin

Yalnızca iki resmî kaynak var: <https://github.com/nab138/iloader> ve
<https://iloader.app>. Aramada çıkan benzer isimli siteleri (`iloader.site` gibi)
kullanma — imzasız kurulum yapan bir araca taklit binary indirmek kötü fikir.

Dosyalar `https://github.com/nab138/iloader/releases/latest/download/` altında:

| İşletim sistemi | Dosya |
|---|---|
| Windows | `iloader-windows-x64.msi` (önerilen) veya `iloader-windows-x64.exe` |
| macOS | `iloader-darwin-universal.dmg` |
| Linux — Debian/Ubuntu | `iloader-linux-amd64.deb` |
| Linux — Fedora/openSUSE | `iloader-linux-x86_64.rpm` |
| Linux — genel | `iloader-linux-amd64.AppImage` |

ARM makineler için `arm64.deb`, `aarch64.rpm`, `aarch64.AppImage` sürümleri var.

Platforma özel ek şartlar:

- **Windows:** Apple Mobile Device USB sürücüsü gerekiyor, iLoader telefonla onun
  üzerinden konuşuyor. Sürücüyü **iTunes** getiriyor — SideStore dokümanı Microsoft
  Store yerine doğrudan Apple'ın sitesindeki sürümü öneriyor. iTunes istemiyorsan
  aynı işi gören **Apple Devices** uygulaması da olur. 32-bit Windows ve ARM
  üzerindeki Windows 10 desteklenmiyor.
- **Linux:** `usbmuxd` kurulu olmalı.
- **macOS:** ek bir şey gerekmiyor.

### Adımlar

**Bilgisayarda:**

1. `iLoader`'ı indir ve çalıştır.
2. iPhone'u USB ile bağla, telefonda çıkan **"Bu Bilgisayara Güven"** sorusuna onay ver.
3. iLoader'da imzalama için açtığın Apple ID ile giriş yap.
4. Cihazını seç ve **Install SideStore (Stable)** de.

**Telefonda:**

5. Ayarlar > Genel > VPN ve Cihaz Yönetimi → geliştirici sertifikasına **Trust**,
   sonra **Allow & Restart**.
6. Ayarlar > Gizlilik ve Güvenlik > **Geliştirici Modu**'nu aç. Telefon yeniden başlar.
7. App Store'dan **LocalDevVPN**'i kur ve **Connect** de. Bu VPN yerel çalışıyor,
   dışarıya bağlantı açmıyor — ama uygulama kurarken ve yenilerken açık olmak zorunda.
8. SideStore'u aç, aynı Apple ID ile giriş yap.
9. **My Apps** sekmesinde SideStore'un yanındaki "7 DAYS" sayacına dokunup elle bir
   yenileme yap. Çalışıyorsa kurulum tamam.

Kabloyu çıkarabilirsin. Bilgisayarla işin bitti.

## Bölüm 2 — Şükela Lite kaynağını ekle

Proje iki repoya bölünmüş durumda:

- **`eksi-reader`** (private) — kaynak kod ve CI. Derleme burada koşuyor.
- **`er-dist`** (public) — yalnızca `docs/source.json`, `docs/icon.png` ve
  Release'lerdeki imzasız IPA'lar. SideStore bunları kimlik doğrulaması olmadan
  indirmek zorunda, o yüzden bu repo public.

Aşağıdaki URL'ler **dist** reposuna işaret ediyor.

Önce `eksi-reader`'ın `main` dalına bir push atılmış ve `build-ipa` işinin yeşil olmuş
olması gerekiyor — kaynak dosyasını o iş dist reposuna yazıyor. Actions sekmesinden
kontrol et.

Sonra telefonda şu linke dokun (Safari'de aç, SideStore'a devret):

```
sidestore://source?url=https://raw.githubusercontent.com/keremcankabadayi/er-dist/main/docs/source.json
```

Alternatif olarak SideStore > **Sources** > **+** deyip şu URL'yi elle yapıştır:

```
https://raw.githubusercontent.com/keremcankabadayi/er-dist/main/docs/source.json
```

Kaynak listeye düşünce **Şükela Lite**'ı seçip **FREE / GET** ile kur. İmzayı SideStore
kendi atıyor; bizim ürettiğimiz IPA tamamen imzasız, o yüzden Apple ID'yi build tarafında
hiçbir yere girmen gerekmiyor.

Doğrulama: uygulamayı aç, **ayarlar** sekmesinde yazan sürüm numarası
GitHub'daki son release'in adıyla aynı olmalı.

## Bundan sonrası

`main`'e her push'ta GitHub Actions imzasız IPA'yı üretip Release'e atıyor ve
`docs/source.json`'u güncelliyor. Telefonda SideStore kaynağı tazeleyince uygulamanın
yanında **Update** beliriyor. Kablo yok, Mac yok, dosya taşımak yok.

## Bilmen gereken sınırlar

- **7 gün.** Ücretsiz imza yedi gün geçerli. SideStore telefonun içinden kendi kendine
  yeniliyor, ama bunun için LocalDevVPN'in açık ve Wi-Fi'ın bağlı olması gerekiyor.
  Süre dolar da yenilenmezse uygulama açılmaz; elle yenilemek yeterli, veriler durur.
- **3 uygulama.** Aynı anda en fazla üç sideload uygulaması tutabiliyorsun ve
  **SideStore'un kendisi de bu üçten birini yiyor.** Bize bir slot yetiyor, bir tane de
  yedek kalıyor.
- **Haftada 10 yeni App ID.** Bu yüzden bundle ID'yi `com.kerem.sukelalite` olarak sabit
  tutuyoruz — aynı bundle ID'yi silip tekrar kurmak bu kotadan yemiyor.
- **Pairing bozulabilir.** iOS güncellemesi, sıfırlama, bazen sebepsiz. O zaman o kişisel
  bilgisayara bir kez daha uğraman gerekiyor. Bundan kalıcı kurtulmanın tek yolu
  99 $/yıl'lık Apple Developer Program hesabı.

## Takılırsan

- **Kaynak eklenmiyor / boş görünüyor:** Actions işi henüz koşmamış olabilir.
  `docs/source.json` içindeki `apps[0].versions` dizisi boşsa SideStore gösterecek bir
  şey bulamıyor.
- **İndirme başarısız:** `er-dist` public mi? SideStore release asset'ini kimlik
  doğrulaması olmadan indiriyor, private repoda bu çalışmaz. Kod reposunun private
  olması sorun değil, dist reposunun private olması her şeyi kırar.
- **Kurulum "unable to install" diyor:** LocalDevVPN bağlı mı, ağ açık mı, 3 uygulama
  limitine takıldın mı — sırayla bunlara bak.
- **"SideStore could not determine this device's UDID. Please replace your pairing using
  iloader."** (`SideStore.OperationError 1006`): minimuxer cihazı sorgularken zaman
  aşımına uğruyor. Önce kablosuz çözümler, sırayla: LocalDevVPN bağlı mı bak ve
  SideStore'u kapatıp aç; SideStore > Settings > VPN Configuration > **Device IP** =
  `10.7.0.1`; anisette sunucusunu `Macley` yap; telefonu yeniden başlat; Geliştirici
  Modu'nu kapatıp aç. Olmazsa pairing'i yenile (kablo gerekiyor): SideStore > Settings >
  **Reset Pairing File** → iLoader'da **Delete Stored Pairing** → **Refresh** → cihazı
  seç, telefonda **Güven** de → **Manage Pairing File** > **Place in All Apps**.
  Pairing dosyası iOS güncellemesinde, sıfırlamada ve bazen sebepsiz bozuluyor;
  bunu ileride tekrar yapman normal.
- **Belirli bir Wi-Fi'da SideStore açılmıyor ama mobil veride açılıyor:** o ağ
  SideStore'un açılışta gittiği anisette sunucusunu engelliyor. Sırayla: LocalDevVPN'i
  aç-kapat yap; Ayarlar > Wi-Fi > (i) > DNS'i Yapılandır > Elle > `1.1.1.1`; aynı
  ekranda **Özel Wi-Fi Adresi**'ni kapat; başka bir ağda (örneğin başka telefonun
  hotspot'u) dene; hâlâ olmuyorsa SideStore ayarlarından anisette sunucusunu değiştir.
  Şirket veya filtreli ağlarda beklenen bir durum — yenileme mobil veriyle de çalıştığı
  için engelleyici değil.
