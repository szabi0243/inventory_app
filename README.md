# Inventory App – QR- és vonalkód alapú készletkezelő alkalmazás

GITHUB LINK: https://github.com/szabi0243/inventory_app

## Projekt leírása

Az Inventory App egy Flutter alapú mobilalkalmazás, amely QR-kódok és vonalkódok beolvasására, termékek azonosítására és készletként történő mentésére szolgál.

Az alkalmazás lehetővé teszi, hogy a felhasználó:

- QR-kódokat olvasson be
- Vonalkódokat olvasson be
- Kamera segítségével fényképet készítsen
- A fényképet PNG formátumba mentse
- A képen található QR-kódot vagy vonalkódot felismerje
- Linket tartalmazó QR-kód esetén automatikusan megnyissa a hivatkozást
- Termékadatokat kérjen le az OpenFoodFacts API segítségével
- A termékeket helyi adatbázisba mentse

A projekt a Gábor Dénes Egyetem BSc Mérnökinformatikus képzés 6. féléves **Szoftverfejlesztés Projekt** tárgyához készült.

---

## Fejlesztők

- Együd Izabella
- Gyöngyösi Szabolcs Patrik
- Földi Péter

---

## Használt technológiák

- Flutter
- Dart
- SQLite (sqflite)
- OpenFoodFacts API
- Codemagic CI/CD
- Android SDK
- Xcode (Codemagic környezetben)

---

## Használt Flutter csomagok

- `camera`
- `mobile_scanner`
- `image`
- `http`
- `sqflite`
- `path`
- `path_provider`
- `provider`
- `url_launcher`
- `connectivity_plus`
- `workmanager`

---

## Projekt struktúra

```text
lib/
├── db/
│   └── app_db.dart
├── models/
│   └── product.dart
├── features/
│   └── scanner/
│       └── scanner_page.dart
├── main.dart

Funkciók részletesen
QR- és vonalkód beolvasás

A Scan menüpont megnyitásakor a kamera előnézete jelenik meg.

A felhasználó a „Kép készítése és beolvasása” gombra kattintva:

Fényképet készít.
A képet PNG formátumba menti.
A képen megkeresi a QR-kódot vagy vonalkódot.
Feldolgozza az eredményt.
Link megnyitása QR-kód esetén

Ha a QR-kód például egy URL-t tartalmaz:

https://www.google.com

akkor az alkalmazás automatikusan megnyitja az alapértelmezett böngészőt.

Termékazonosítás

Vonalkód esetén az alkalmazás az OpenFoodFacts API-t használja a termék nevének lekérésére.

Helyi adatbázis

A termékek a készülék SQLite adatbázisába kerülnek mentésre.

Telepítés és futtatás
Előfeltételek

Telepítendő szoftverek:

Git
Flutter SDK
Android Studio
Android SDK
Xcode (macOS esetén)
Codemagic fiók
Flutter telepítés ellenőrzése
flutter doctor

Függőségek telepítése
flutter pub get

Android futtatás

Eszközök listázása
flutter devices

App futtatása Androidon
flutter run
Release APK készítése
flutter build apk --release
Kimeneti fájl
build/app/outputs/flutter-apk/app-release.apk

Ez közvetlenül telepíthető Android telefonra.

Android App Bundle készítése
flutter build appbundle --release
Kimeneti fájl
build/app/outputs/bundle/release/app-release.aab

Ez a Google Play Store feltöltéshez használható.

iOS build
Fontos tudnivaló

Windows alatt natív iOS build nem készíthető. A projekt iOS buildelése Codemagic segítségével történik.

iOS build Codemagic-ben
A projekt feltöltése GitHub repository-ba.
A repository összekapcsolása a Codemagic-gel.
Build indítása.
Az Artifacts menüpontból a kész IPA fájl letöltése.
iOS artifact fájlok

A build végén az alábbi artifactok keletkezhetnek:

Runner-unsigned.ipa
Runner.app.zip

Melyik a használható fájl?

A telepítéshez az alábbi fájl szükséges:

Runner-unsigned.ipa
IPA telepítése iPhone-ra
Windows rendszeren az alábbi programot használtuk:

Sideloadly
Telepítés lépései
iPhone csatlakoztatása.
Runner-unsigned.ipa kiválasztása.
Apple ID megadása.
Telepítés.
iOS biztonsági beállítás

iPhone-on:

Beállítások → Általános → VPN és eszközkezelés

Itt meg kell bízni a fejlesztői tanúsítványban.

Codemagic konfiguráció

A projekt codemagic.yaml fájl segítségével automatikusan buildelhető Androidra és iOS-re.

A build eredményei:

Android
app-release.apk
app-release.aab
iOS
Runner-unsigned.ipa

Hasznos parancsok
Projekt tisztítása
flutter clean

Függőségek újratelepítése
flutter pub get

iOS cache előkészítése
flutter precache --ios

Android APK build
flutter build apk --release

iOS build (macOS-en)
flutter build ipa --release --no-codesign

Jogosultságok
Android
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>

iOS
<key>NSCameraUsageDescription</key>
<string>Az alkalmazás kamerát használ QR-kódok és vonalkódok beolvasásához.</string>
Adatforrás

A termékadatok az alábbi szolgáltatásból érkeznek:

OpenFoodFacts API

Példa lekérdezés:

https://world.openfoodfacts.org/api/v2/product/5997200510017.json
Példa használat
Az alkalmazás elindítása.
Scan menüpont megnyitása.
Kép készítése.
QR-kód vagy vonalkód felismerése.
Link megnyitása vagy termékadat lekérése.
Mentés az adatbázisba.

Jövőbeli fejlesztési lehetőségek
Kategóriák kezelése
Készletmennyiség nyilvántartása
Felhőszinkronizáció
Export CSV/Excel formátumba
Webes admin felület
Licenc

A projekt oktatási célból készült a Gábor Dénes Egyetem Szoftverfejlesztés Projekt tantárgyához.