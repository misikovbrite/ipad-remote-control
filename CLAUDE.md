# Tablet Remote Control - Pad+

**App ID:** 6762023054  
**Bundle ID:** ipadremotecontrolapp  
**Team:** Brite Technologies LLC (5487HDH2B9)  
**Repo:** misikovbrite/ipad-remote-control  
**Category:** Utilities  
**Platform:** iPad only (TARGETED_DEVICE_FAMILY=2, UIDeviceFamily=[2])  
**iOS:** 17.0+  

---

## Что это

iPad-приложение — универсальный пульт управления для смарт-телевизоров по Wi-Fi. Работает без ИК-бластера: подключается к телевизору напрямую по локальной сети через официальные протоколы каждого бренда.

Цель: заменить физический пульт для людей, которые управляют телевизором с дивана с iPad в руках. Крупные кнопки, удобный интерфейс, специально оптимизированный под большой экран планшета.

---

## Поддерживаемые ТВ-протоколы

| Бренд | Протокол | Порт |
|-------|----------|------|
| Samsung | WebSocket (2016+) | 8001 |
| LG | WebOS (2014+) | 3000 |
| Sony | IRCC / REST (Bravia) | 80 |
| Roku | ECP HTTP | 8060 |
| Android TV / Fire TV | ADB | 5555 |
| Philips | JointSpace | 1925 |
| Apple TV | Companion Protocol | 7000 |

---

## Архитектура

```
TabletRemoteControl/Sources/
├── App/
│   ├── TabletRemoteControlApp.swift   — @main, AppDelegate+SceneDelegate
│   ├── ContentView.swift              — корневой роутер (онбординг → remote → main)
│   ├── AppState.swift                 — глобальное состояние
│   └── Info.plist
├── Models/
│   ├── TVDevice.swift                 — Codable модель устройства (сохраняется в UserDefaults)
│   └── RemoteCommand.swift            — enum RemoteKey (все кнопки пульта)
├── Services/
│   ├── TVConnectionManager.swift      — @MainActor ObservableObject, connect/disconnect/reconnect/demo
│   └── TVProtocolFactory.swift        — фабрика протоколов по TVBrand
├── Protocols/
│   ├── TVProtocol.swift               — протокол TVProtocol + DemoProtocol
│   ├── Samsung/SamsungProtocol.swift
│   ├── LG/LGProtocol.swift
│   ├── Sony/SonyProtocol.swift
│   ├── Roku/RokuProtocol.swift
│   ├── ADB/ADBProtocol.swift          — Android TV / Fire TV
│   └── Philips/PhilipsProtocol.swift
├── Discovery/
│   └── TVDiscoveryService.swift       — mDNS/Bonjour сканирование сети
└── UI/
    ├── Onboarding/OnboardingView.swift
    ├── DeviceList/DeviceListView.swift — главный экран: сохранённые устройства + кнопки Add/Search/Demo
    ├── Remote/
    │   ├── RemoteControlView.swift    — пульт (навигация, громкость, каналы, плейбэк, цифры, стриминг)
    │   └── AppsGridView.swift         — список приложений на ТВ
    ├── Keyboard/TVKeyboardView.swift  — экранная клавиатура для ввода текста на ТВ
    └── Touchpad/TVTouchpadView.swift  — тачпад для управления курсором
```

---

## Ключевые решения

**TVConnectionManager** — единая точка входа для всей работы с ТВ:
- Сохраняет устройства в UserDefaults (`saved_tv_devices_v1`), max 10
- При старте пытается переподключиться к последнему устройству (`attemptReconnect`)
- Demo Mode: `connectDemo()` → `DemoProtocol` (no-op, для App Store ревьюера)
- `isDemoMode: Bool` — показывает оранжевый баннер в RemoteControlView

**TVDevice: Codable** — `connectionState` исключён из CodingKeys (не сериализуется)

**Сборка:**
- `xcodegen generate` — генерирует .xcodeproj из project.yml
- После xcodegen: запустить `ruby add_assets.rb` — добавляет Assets.xcassets в проект (xcodegen баг)
- Archive: `xcodebuild archive ... CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=5487HDH2B9`
- Upload: через Xcode Organizer (altool не работает из-за bundle ID)

---

## App Store

- **ASC:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → App ID 6762023054
- **v1.0 build 1** — rejected 2026-04-14, ответ отправлен 2026-04-15
- **Rejection:** 2.3.10 (android в keywords) + 2.1(b) (бизнес-модель)
- **v1.1 build 6** — отправлен на ревью 2026-04-19 (Fast Track + In-App Event)
- **Territories:** 175 стран
- **Release:** Manual (Pending Developer Release)
- **Keywords:** `smart,tv,samsung,lg,sony,roku,fire,amazon,touchpad,keyboard,wifi,universal,philips,oled`
- **Demo Mode для ревьюера:** на главном экране кнопка "Try Demo Mode"
- **In-App Event:** "Google TV Now Supported" (ID: 6762532263) — отправлен одновременно с билдом

---

## v1.1 — Статус (build 6, отправлен 2026-04-19)

### Что сделано:
- ✅ `PaywallView.swift` — пейволл (dark navy, indigo, fullScreenCover)
- ✅ `SubscriptionService.swift` — StoreKit 2, @Observable, ProState, offline cache
- ✅ `FeatureGate.swift` — keyboard/touchpad/appsGrid/multipleDevices = premium
- ✅ `PremiumBannerView.swift` — inline upsell для заблокированных фич
- ✅ Подписки в ASC: `ipadremotecontrolapp_weekly` ($5.99/wk) + `ipadremotecontrolapp_yearly` ($19.99/yr, 3-day trial) + `remote_ipad_lifetime` ($59.99)
- ✅ `TARGETED_DEVICE_FAMILY="2"` — iPad only в бинаре (было [1,2], исправлено)
- ✅ Иконка — цветные кнопки пульта, тёмно-синий фон, edge-to-edge
- ✅ Скриншоты — 3 iPad Pro 12.9" + 3 iPhone 6.5" (требование ASC)
- ✅ What's New — Google TV / Android TV поддержка
- ✅ In-App Event "Google TV Now Supported" (ID: 6762532263) — 175 территорий

### Сборка (важно):
- `TARGETED_DEVICE_FAMILY: "2"` должен быть в **target settings** (не только в global), иначе xcodegen перезаписывает на `1,2`
- project.yml → targets → TabletRemoteControl → settings → base → `TARGETED_DEVICE_FAMILY: "2"`

### Следующие шаги (R3):
- ⏳ Улучшить работу ТВ протоколов (Samsung/LG/Sony)
- ⏳ Загрузить ASO локализацию (из `docs/ASO_localization.md`) на 7 языков
- Apple TV протокол требует MFi/companion entitlement
