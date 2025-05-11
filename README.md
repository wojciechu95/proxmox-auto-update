# 🖥️ Przewodnik instalacji

# Proxmox Auto-Update Script

**Wersja:** 1.4.0-intelligent
**Autor:** Wojciech Piwowarski

## 📦 Instalacja krok po kroku

---

### 1. Rozpakuj paczkę:

```bash
tar -xvzf proxmox-auto-update.tar.gz -C /
```

> 📁 Jeśli pliki wypakują się do katalogu `proxmox-auto-update/`, przenieś je odpowiednio:

```bash
mv proxmox-auto-update/usr/ /usr/
mv proxmox-auto-update/etc/ /etc/
```

### 2. Skonfiguruj adres e-mail:

🧑‍🔧 Edytuj plik `/usr/local/bin/proxmox-auto-update.sh` i ustaw zmienną `EMAIL`:

```bash
EMAIL="twoj_adres@email.com"
```

### 3. Nadaj uprawnienia wykonywalne:

```bash
chmod +x /usr/local/bin/proxmox-auto-update.sh
```

### 4. Przeładuj konfigurację systemd:

```bash
systemctl daemon-reload
```

> 🔄 Przeładowuje konfigurację jednostek systemd (🔧 usługi, ⏲️ timery, 🧩 itd.).

### 5. Aktywuj timer:

⏲️ Natychmiastowe uruchomienie i aktywacja na stałe:

```bash
systemctl enable --now proxmox-auto-update.timer
```

⏲️ Tylko aktywacja ( 🚨 uruchomi się przy następnym uruchomieniu systemu):

```bash
systemctl enable proxmox-auto-update.timer
```

⏲️ Jednorazowe uruchomienie:

```bash
systemctl start proxmox-auto-update.timer
```

### 6. Sprawdzenie działania timera:

```bash
systemctl status proxmox-auto-update.timer
```

### 7. Lista aktywnych timerów:

```bash
systemctl list-timers --all
```

---

## 📨 Konfiguracja klienta `msmtp` (wysyłka e-maili)

### Instalacja:

```bash
apt install msmtp msmtp-mta -y
```

### 📄 Plik konfiguracyjny:

* Użytkownik: `~/.msmtprc`
* Globalnie: `/etc/msmtprc`

> 💡 Szablon pliku konfiguracyjnego znajduje się w paczce instalacyjnej.

### 🔒 Ustawienia uprawnień:

```bash
chmod 600 ~/.msmtprc
```

### 🧪 Test działania:

```bash
echo "To: twoj_email@gmail.com" | msmtp --debug --from=default -t
```

---

## 📌 (Opcjonalnie) 🔐 Zabezpieczenie hasła za pomocą GPG

### 1. Wygeneruj klucz (jeśli jeszcze go nie masz):

```bash
gpg --full-generate-key
```

### 2. Sprawdź dostępne klucze:

```bash
gpg --list-keys
```

### 3. Zaszyfruj hasło:

```bash
echo "twoje_haslo" | gpg --encrypt --recipient twoj_email@email.com > ~/.msmtp-password.gpg
```

### 4. Skonfiguruj `.msmtprc`:

```bash
passwordeval "gpg --quiet --for-your-eyes-only --no-tty --decrypt ~/.msmtp-password.gpg"
```

### 5. Zabezpiecz plik z hasłem:

```bash
chmod 600 ~/.msmtp-password.gpg
```

---

## 📁 Dodatkowe informacje

* 🔍 Logi działania skryptu: `/var/log/proxmox-auto-update.log`
* 🛠️ Diagnostyka `msmtp`: `~/.msmtp.log` lub `journalctl -xe`
