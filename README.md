
# Proxmox Auto-Update Script  
**Version:** 1.4.0-intelligent  
**Author:** Wojciech Piwowarski  

## Instrukcja instalacji

### 1. Rozpakuj paczkę:
```bash
tar -xvzf proxmox-auto-update.tar.gz -C /
```

### 2. Edytuj plik `/usr/local/bin/proxmox-auto-update.sh` i ustaw swój adres e-mail:
Znajdź i edytuj zmienną `EMAIL`, która odpowiada za adres adresata:
```bash
EMAIL="twoj_adres@email.com"
```

### 3. Ustaw uprawnienia:
```bash
chmod +x /usr/local/bin/proxmox-auto-update.sh
```

### 4. Załaduj konfigurację systemd:
```bash
systemctl daemon-reload
```
> Przeładowuje konfigurację jednostek systemd (usługi, timery, itd.).

### 5. Włącz timer:
Aby uruchomić timer od razu i aktywować go na stałe:
```bash
systemctl enable --now proxmox-auto-update.timer
```

Aby tylko aktywować timer (uruchomi się przy następnym reboot):
```bash
systemctl enable proxmox-auto-update.timer
```

Aby uruchomić timer tylko raz (do kolejnego rebootu):
```bash
systemctl start proxmox-auto-update.timer
```

### 6. Sprawdź status timera:
```bash
systemctl status proxmox-auto-update.timer
```
### 7. Skonfiguruj `msmtp` do wysyłki e-maili:

Komenda ta wyświetli wszystkie aktywne timery w systemie, w tym twój timer `proxmox-auto-update.timer`.:
```bash
systemctl list-timers --all
```

### 8. Skonfiguruj `msmtp` do wysyłki e-maili:
```bash
apt install msmtp msmtp-mta -y
```

#### Plik konfiguracyjny:
- `~/.msmtprc` (dla użytkownika)
- `/etc/msmtprc` (globalnie)

#### Uprawnienia:
```bash
chmod 600 ~/.msmtprc
```

#### Test wysyłki:
```bash
echo "To: twoj_email@gmail.com" | msmtp --debug --from=default -t
```

#### 🔐 Zabezpieczenie hasła:
Zaszyfruj hasło GPG:
```bash
echo "twoje_haslo" | gpg --encrypt --recipient email@email.com > ~/.msmtp-password.gpg
```

W pliku `.msmtprc` dodaj:
```bash
passwordeval "gpg --quiet --for-your-eyes-only --no-tty --decrypt ~/.msmtp-password.gpg"
```

Uprawnienia:
```bash
chmod 600 ~/.msmtp-password.gpg
```

---

📂 **Logi znajdziesz w:** `/var/log/proxmox-auto-update.log`
