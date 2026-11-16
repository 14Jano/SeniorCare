# SeniorCare

Aplikacja mobilna do monitorowania przyjmowania leków przez osoby starsze, z powiadomieniami dla opiekuna.
Projekt powstał jako praca inżynierska.

Aplikacja łączy dwa konta: **Administratora** (opiekuna) i **Użytkownika** (seniora).
Opiekun zarządza listą leków i dostaje powiadomienia, a senior zaznacza w aplikacji, że przyjął lek.

## Funkcjonalności

**Konta i logowanie**
- Rejestracja i logowanie e-mailem lub kontem Google
- Weryfikacja adresu e-mail i reset hasła
- Ekran powitalny dla nowych użytkowników

**Łączenie opiekuna z seniorem**
- Opiekun wysyła zaproszenie na adres e-mail seniora
- Senior akceptuje albo odrzuca zaproszenie w aplikacji
- Podział ról: Administrator i Użytkownik

**Leki i powiadomienia**
- Opiekun dodaje, edytuje i usuwa leki z listy seniora
- Senior potwierdza przyjęcie leku jednym dotknięciem
- Opiekun dostaje powiadomienia push o przyjęciu leków

## Stack technologiczny

- **Flutter / Dart**
- **Firebase Authentication** – logowanie e-mailem i przez Google
- **Cloud Firestore** – przechowywanie danych użytkowników i leków
- **Firebase Cloud Messaging** – powiadomienia push
- **Provider** – zarządzanie stanem

## Wymagania

- Flutter SDK (zgodny z `sdk: ^3.9.0`)
- Android Studio lub Xcode
- Projekt w [Firebase](https://console.firebase.google.com/) z włączonymi: Authentication (e-mail i Google), Firestore i Cloud Messaging

## Instalacja i uruchomienie

1. Sklonuj repozytorium:
   ```bash
   git clone https://github.com/14Jano/SeniorCare.git
   cd SeniorCare
   ```
2. Zainstaluj zależności:
   ```bash
   flutter pub get
   ```
3. Podłącz własny projekt Firebase:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Uruchom aplikację:
   ```bash
   flutter run
   ```

## Struktura projektu

```text
lib/
├── main.dart
├── components/      # współdzielone widgety
└── pages/
    ├── auth/        # logowanie, rejestracja, weryfikacja, reset hasła
    ├── home_page.dart
    ├── notifications_page.dart
    ├── user_details_page.dart
    └── welcome_screen.dart
```

## Zrzuty ekranu

_Wkrótce._

## Autor

**Jan Łabaj** – [@14Jano](https://github.com/14Jano) · [LinkedIn](https://www.linkedin.com/in/janlabaj)

Praca inżynierska, [nazwa uczelni], [rok].
