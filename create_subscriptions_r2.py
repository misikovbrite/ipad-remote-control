"""
Создание подписок для Tablet Remote Control - Pad+ (R2).
App ID: 6762023054
"""
import jwt, time, requests, json, os, hashlib

CONFIG = {
    "issuer_id": "f7dc851a-bdcb-47d6-b5c7-857f48cadb17",
    "key_id": "C37442BRFH",
    "key_path": os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_C37442BRFH.p8"),
    "app_id": "6762023054",
    "group_name": "Tablet Remote Premium",
    "app_display_name": "Tablet Remote",
    "weekly_product_id": "ipadremotecontrolapp_weekly",
    "yearly_product_id": "ipadremotecontrolapp_yearly",
    "weekly_price_level": "10075",      # $5.99 в USA
    "yearly_base_price_level": "10142", # $12.99 в USA (база)
    "yearly_usa_price_level": "10177",  # $19.99 в USA (override)
    "trial_duration": "THREE_DAYS",
    "screenshot_path": os.path.expanduser("~/Desktop/vibecode/app-builder/subscription-review-screenshot.png"),
}

BASE = "https://api.appstoreconnect.apple.com"

with open(CONFIG["key_path"]) as f:
    PRIVATE_KEY = f.read()


def get_token():
    return jwt.encode(
        {
            "iss": CONFIG["issuer_id"],
            "iat": int(time.time()),
            "exp": int(time.time()) + 1200,
            "aud": "appstoreconnect-v1",
        },
        PRIVATE_KEY,
        algorithm="ES256",
        headers={"kid": CONFIG["key_id"]},
    )


def api(method, path, payload=None, params=None):
    for attempt in range(3):
        headers = {
            "Authorization": f"Bearer {get_token()}",
            "Content-Type": "application/json",
        }
        if method == "GET":
            r = requests.get(f"{BASE}{path}", headers=headers, params=params)
        elif method == "POST":
            r = requests.post(f"{BASE}{path}", headers=headers, json=payload)
        elif method == "PATCH":
            r = requests.patch(f"{BASE}{path}", headers=headers, json=payload)
        if r.status_code == 429:
            print(f"  Rate limited, retrying in 3s... (attempt {attempt+1}/3)")
            time.sleep(3)
            continue
        return r
    return r


def get_all_pages(path, params=None):
    all_data = []
    url = f"{BASE}{path}"
    p = {**(params or {}), "limit": 200}
    while url:
        headers = {
            "Authorization": f"Bearer {get_token()}",
            "Content-Type": "application/json",
        }
        r = requests.get(url, headers=headers, params=p)
        data = r.json()
        all_data.extend(data.get("data", []))
        url = data.get("links", {}).get("next")
        p = {}
    return all_data


def assert_ok(r, step):
    if r.status_code not in (200, 201):
        print(f"  ERROR at {step}: {r.status_code}")
        print(r.text[:2000])
        raise SystemExit(1)


def main():
    # -------------------------------------------------------------------------
    # Шаг 1: Создать группу подписок
    # -------------------------------------------------------------------------
    print("\n=== Шаг 1: Создание группы подписок ===")
    r = api("POST", "/v1/subscriptionGroups", payload={
        "data": {
            "type": "subscriptionGroups",
            "attributes": {"referenceName": CONFIG["group_name"]},
            "relationships": {
                "app": {"data": {"type": "apps", "id": CONFIG["app_id"]}}
            },
        }
    })
    assert_ok(r, "create subscriptionGroup")
    group_id = r.json()["data"]["id"]
    print(f"  Group created: {group_id}")

    # -------------------------------------------------------------------------
    # Шаг 2: Локализация группы (en-US)
    # -------------------------------------------------------------------------
    print("\n=== Шаг 2: Локализация группы (en-US) ===")
    r = api("POST", "/v1/subscriptionGroupLocalizations", payload={
        "data": {
            "type": "subscriptionGroupLocalizations",
            "attributes": {
                "locale": "en-US",
                "name": "Premium",
                "customAppName": CONFIG["app_display_name"],
            },
            "relationships": {
                "subscriptionGroup": {"data": {"type": "subscriptionGroups", "id": group_id}}
            },
        }
    })
    assert_ok(r, "create subscriptionGroupLocalization")
    print(f"  Group localization created (en-US)")

    # -------------------------------------------------------------------------
    # Шаг 3: Создать подписки Weekly + Yearly
    # -------------------------------------------------------------------------
    print("\n=== Шаг 3: Создание подписок ===")

    def create_subscription(product_id, name, period, group_level, review_note):
        r = api("POST", "/v1/subscriptions", payload={
            "data": {
                "type": "subscriptions",
                "attributes": {
                    "productId": product_id,
                    "name": name,
                    "subscriptionPeriod": period,
                    "groupLevel": group_level,
                    "reviewNote": review_note,
                },
                "relationships": {
                    "group": {"data": {"type": "subscriptionGroups", "id": group_id}}
                },
            }
        })
        assert_ok(r, f"create subscription {product_id}")
        sub_id = r.json()["data"]["id"]
        print(f"  [{name}] created: {sub_id}")
        return sub_id

    weekly_id = create_subscription(
        CONFIG["weekly_product_id"],
        "Weekly",
        "ONE_WEEK",
        2,
        "Weekly subscription providing full access to all premium features including keyboard input, touchpad control, and apps grid.",
    )

    yearly_id = create_subscription(
        CONFIG["yearly_product_id"],
        "Yearly",
        "ONE_YEAR",
        1,
        "Yearly subscription providing full access to all premium features including keyboard input, touchpad control, and apps grid.",
    )

    # -------------------------------------------------------------------------
    # Шаг 4: Локализация подписок (en-US)
    # -------------------------------------------------------------------------
    print("\n=== Шаг 4: Локализация подписок (en-US) ===")

    def create_sub_localization(sub_id, name, description):
        r = api("POST", "/v1/subscriptionLocalizations", payload={
            "data": {
                "type": "subscriptionLocalizations",
                "attributes": {
                    "locale": "en-US",
                    "name": name,
                    "description": description,
                },
                "relationships": {
                    "subscription": {"data": {"type": "subscriptions", "id": sub_id}}
                },
            }
        })
        assert_ok(r, f"create subscriptionLocalization {name}")
        print(f"  [{name}] localization (en-US) created")

    create_sub_localization(
        weekly_id, "Weekly", "All features unlocked for a week"
    )
    create_sub_localization(
        yearly_id, "Yearly", "All features unlocked for a year"
    )

    # -------------------------------------------------------------------------
    # Шаг 5: Получить все территории
    # -------------------------------------------------------------------------
    print("\n=== Шаг 5: Получение территорий ===")
    territories = get_all_pages("/v1/territories")
    territory_ids = [t["id"] for t in territories]
    print(f"  Territories fetched: {len(territory_ids)}")

    # -------------------------------------------------------------------------
    # Шаг 6: Availability ОБЯЗАТЕЛЬНО до цен
    # -------------------------------------------------------------------------
    print("\n=== Шаг 6: Установка availability ===")

    def set_availability(sub_id, label):
        r = api("POST", "/v1/subscriptionAvailabilities", payload={
            "data": {
                "type": "subscriptionAvailabilities",
                "attributes": {"availableInNewTerritories": True},
                "relationships": {
                    "subscription": {"data": {"type": "subscriptions", "id": sub_id}},
                    "availableTerritories": {
                        "data": [{"type": "territories", "id": tid} for tid in territory_ids]
                    },
                },
            }
        })
        assert_ok(r, f"create subscriptionAvailability {label}")
        print(f"  [{label}] availability set ({len(territory_ids)} territories)")

    set_availability(weekly_id, "Weekly")
    set_availability(yearly_id, "Yearly")

    # -------------------------------------------------------------------------
    # Шаг 7: Цены
    # -------------------------------------------------------------------------
    print("\n=== Шаг 7: Установка цен ===")

    def get_usa_price_point(sub_id, price_level):
        """Найти конкретный pricePoint для USA по номеру уровня."""
        points = get_all_pages(
            f"/v1/subscriptions/{sub_id}/pricePoints",
            params={"filter[territory]": "USA", "limit": 200},
        )
        for p in points:
            if p.get("attributes", {}).get("customerPrice") is not None:
                # Используем customerPrice как фильтр уровня через номер
                pass
        # Найти точку по ID уровня через атрибут name/tier нет — используем GET pricePoints без фильтра и ищем по ID
        all_points = get_all_pages(
            f"/v1/subscriptions/{sub_id}/pricePoints",
            params={"filter[territory]": "USA"},
        )
        # price_level — числовой ID уровня в Apple (например "10075")
        # Ищем точку, у которой id заканчивается на нужное значение или по порядку
        # Apple использует составные ID вида {sub_id}_{territory}_{level}
        for p in all_points:
            pid = p.get("id", "")
            if pid.endswith(f"_{price_level}") or pid.endswith(price_level):
                return p["id"]
        # Fallback: перебрать и найти по customerPrice соответствующей цене
        price_map = {
            "10075": "5.99",
            "10142": "12.99",
            "10177": "19.99",
        }
        target = price_map.get(price_level)
        if target:
            for p in all_points:
                cp = str(p.get("attributes", {}).get("customerPrice", ""))
                if cp == target:
                    return p["id"]
        raise ValueError(f"Price point {price_level} not found for sub {sub_id}")

    def get_equalizations(price_point_id):
        """Получить эквализированные price points для всех территорий."""
        return get_all_pages(f"/v1/subscriptionPricePoints/{price_point_id}/equalizations")

    def set_prices(sub_id, label, base_price_level, usa_price_level=None):
        print(f"  [{label}] Получаем USA price point для базового уровня {base_price_level}...")
        base_pp_id = get_usa_price_point(sub_id, base_price_level)
        print(f"  [{label}] Base USA price point: {base_pp_id}")

        print(f"  [{label}] Получаем эквализации...")
        eq_points = get_equalizations(base_pp_id)
        print(f"  [{label}] Equalizations: {len(eq_points)} territories")

        # Если нужен override для USA — найти отдельный price point
        usa_override_pp_id = None
        if usa_price_level and usa_price_level != base_price_level:
            print(f"  [{label}] Получаем USA override price point {usa_price_level}...")
            usa_override_pp_id = get_usa_price_point(sub_id, usa_price_level)
            print(f"  [{label}] USA override price point: {usa_override_pp_id}")

        # Собираем финальный список: territory -> price_point_id
        territory_price_map = {}
        for ep in eq_points:
            ter = ep.get("relationships", {}).get("territory", {}).get("data", {}).get("id")
            if ter:
                territory_price_map[ter] = ep["id"]

        # Переопределяем USA если нужно
        if usa_override_pp_id:
            # Найти price point для USA из override
            territory_price_map["USA"] = usa_override_pp_id

        # POST цены по одной (175 запросов)
        ok_count = 0
        for ter_id, pp_id in territory_price_map.items():
            r = api("POST", "/v1/subscriptionPrices", payload={
                "data": {
                    "type": "subscriptionPrices",
                    "attributes": {
                        "startDate": None,
                        "preserveCurrentPrice": False,
                    },
                    "relationships": {
                        "subscription": {"data": {"type": "subscriptions", "id": sub_id}},
                        "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": pp_id}},
                    },
                }
            })
            if r.status_code in (200, 201):
                ok_count += 1
            else:
                print(f"    WARNING price {ter_id}: {r.status_code} {r.text[:200]}")
            time.sleep(0.05)  # небольшая задержка против rate limit

        print(f"  [{label}] Prices set: {ok_count}/{len(territory_price_map)}")

    set_prices(weekly_id, "Weekly", CONFIG["weekly_price_level"])
    set_prices(yearly_id, "Yearly", CONFIG["yearly_base_price_level"], CONFIG["yearly_usa_price_level"])

    # -------------------------------------------------------------------------
    # Шаг 8: Introductory Offers для Yearly (3-day free trial) — все территории
    # -------------------------------------------------------------------------
    print("\n=== Шаг 8: Introductory offers (3-day trial) для Yearly ===")

    # Получаем все subscriptionPricePoints для yearly чтобы иметь pp_id по territory
    yearly_price_points = get_all_pages(f"/v1/subscriptions/{yearly_id}/pricePoints")
    # Строим map territory -> pp_id из pricePoints
    yearly_pp_map = {}
    for pp in yearly_price_points:
        ter = pp.get("relationships", {}).get("territory", {}).get("data", {}).get("id")
        if ter:
            yearly_pp_map[ter] = pp["id"]

    offer_ok = 0
    for ter_id, pp_id in yearly_pp_map.items():
        r = api("POST", "/v1/subscriptionIntroductoryOffers", payload={
            "data": {
                "type": "subscriptionIntroductoryOffers",
                "attributes": {
                    "offerMode": "FREE_TRIAL",
                    "duration": CONFIG["trial_duration"],
                    "numberOfPeriods": 1,
                    "startDate": None,
                    "endDate": None,
                },
                "relationships": {
                    "subscription": {"data": {"type": "subscriptions", "id": yearly_id}},
                    "subscriptionPricePoint": {"data": {"type": "subscriptionPricePoints", "id": pp_id}},
                    "territory": {"data": {"type": "territories", "id": ter_id}},
                },
            }
        })
        if r.status_code in (200, 201):
            offer_ok += 1
        else:
            print(f"    WARNING intro offer {ter_id}: {r.status_code} {r.text[:200]}")
        time.sleep(0.05)

    print(f"  Introductory offers created: {offer_ok}/{len(yearly_pp_map)}")

    # -------------------------------------------------------------------------
    # Шаг 9: Загрузка скриншотов для ревью
    # -------------------------------------------------------------------------
    print("\n=== Шаг 9: Загрузка скриншотов для ревью ===")

    screenshot_path = CONFIG["screenshot_path"]
    if not os.path.exists(screenshot_path):
        print(f"  WARNING: screenshot not found at {screenshot_path}, пропускаем")
    else:
        file_size = os.path.getsize(screenshot_path)
        with open(screenshot_path, "rb") as f:
            file_data = f.read()
        file_md5 = hashlib.md5(file_data).hexdigest()
        file_name = os.path.basename(screenshot_path)

        ext = file_name.rsplit(".", 1)[-1].lower()
        mime_map = {"png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg"}
        mime_type = mime_map.get(ext, "image/png")

        for sub_id, label in [(weekly_id, "Weekly"), (yearly_id, "Yearly")]:
            print(f"  [{label}] Резервируем скриншот...")
            r = api("POST", "/v1/subscriptionAppStoreReviewScreenshots", payload={
                "data": {
                    "type": "subscriptionAppStoreReviewScreenshots",
                    "attributes": {
                        "fileName": file_name,
                        "fileSize": file_size,
                    },
                    "relationships": {
                        "subscription": {"data": {"type": "subscriptions", "id": sub_id}}
                    },
                }
            })
            assert_ok(r, f"reserve screenshot {label}")
            ss_data = r.json()["data"]
            ss_id = ss_data["id"]
            upload_ops = ss_data.get("attributes", {}).get("uploadOperations", [])

            # Загружаем файл
            for op in upload_ops:
                upload_url = op["url"]
                offset = op.get("offset", 0)
                length = op.get("length", file_size)
                req_headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
                chunk = file_data[offset: offset + length]
                put_r = requests.put(upload_url, data=chunk, headers=req_headers)
                if put_r.status_code not in (200, 201, 204):
                    print(f"    WARNING upload chunk: {put_r.status_code} {put_r.text[:200]}")

            # Commit
            print(f"  [{label}] Коммитим скриншот...")
            r = api("PATCH", f"/v1/subscriptionAppStoreReviewScreenshots/{ss_id}", payload={
                "data": {
                    "type": "subscriptionAppStoreReviewScreenshots",
                    "id": ss_id,
                    "attributes": {
                        "uploaded": True,
                        "sourceFileChecksum": file_md5,
                    },
                }
            })
            if r.status_code in (200, 201):
                print(f"  [{label}] Скриншот загружен успешно")
            else:
                print(f"    WARNING commit screenshot {label}: {r.status_code} {r.text[:300]}")

    # -------------------------------------------------------------------------
    # Шаг 10: Итог
    # -------------------------------------------------------------------------
    print("\n=== Шаг 10: Итог ===")
    print(f"  App ID:         {CONFIG['app_id']}")
    print(f"  Group ID:       {group_id}")
    print(f"  Weekly ID:      {weekly_id}  ({CONFIG['weekly_product_id']})")
    print(f"  Yearly ID:      {yearly_id}  ({CONFIG['yearly_product_id']})")
    print("\nДобавь эти ID в CLAUDE.md проекта.")
    print("Затем зайди в ASC → подписки и убедись что статус = WAITING_FOR_REVIEW")
    print("Done!")


if __name__ == "__main__":
    main()
