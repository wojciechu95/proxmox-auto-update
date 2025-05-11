#!/bin/bash
set -euo pipefail

# ===========================
# Proxmox Auto-Update Script
# Version: 1.4.0-intelligent
# Wojciech Piwowarski
# ===========================

VERSION="1.4.0"
LOGFILE="/var/log/proxmox-auto-update.log"

#Adresat Wiadomości loga
EMAIL="wojtek.piwowarski1@gmail.com"

# Czyścimy log przed wysyłką
> "$LOGFILE"

SUBJECT="Proxmox Auto-Update - $(date '+%Y-%m-%d %H:%M:%S') - log (v$VERSION)"
KERNEL_BEFORE=$(uname -r)
KERNEL_AFTER=$(ls -1 /boot/vmlinuz-* 2>/dev/null | sed 's|.*/vmlinuz-||' | sort -V | tail -n 1)
REBOOT_NEEDED=0
HIGH_USAGE_VM=0

send_email() {
    if command -v msmtp >/dev/null 2>&1; then
       {
        echo "To: $EMAIL"
        echo "Subject: $SUBJECT"
        echo ""
        cat "$LOGFILE"
      } | msmtp "$EMAIL"
    fi
}

handle_error() {
    echo "❌ Błąd w linii $1: status $2"
    echo "❌ Skrypt zakończony z błędem w linii $1 (🟡 kod: $2)" >> "$LOGFILE"
    SUBJECT="❌ Proxmox Auto-Update ERROR (kod: $2) – $(date '+%Y-%m-%d %H:%M:%S')"
    send_email
    exit $2
}

trap 'handle_error $LINENO $?' ERR

{
    echo "🟡 🟡 Proxmox Auto-Update Script v$VERSION"
    echo
    echo "🟡 Start: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    echo "🟡 Kernel PRZED Aktualizacją: $KERNEL_BEFORE"

    apt update
    apt -y full-upgrade
    apt -y autoremove
    apt -y clean

    echo "✅ Aktualizacja zakończona: $(date '+%Y-%m-%d %H:%M:%S')"
    echo

     if [ -f /var/run/reboot-required ]; then
        echo "📎 System zgłasza potrzebę restartu ⚠️"
        if [[ "$KERNEL_BEFORE" != "$KERNEL_AFTER" ]]; then
           echo
           echo "🟡 Kernel został zaktualizowany – ⚠️ nastąpi restart."
           REBOOT_NEEDED=1
        fi

    if who | grep -q "pts"; then
        echo "❌ Aktywni użytkownicy w systemie – restart anulowany"
        echo
        echo "⚠️ Proxmox Auto-Update: bez restartu (aktywni użytkownicy) – $(date '+%Y-%m-%d %H:%M:%S')"
        send_email
        REBOOT_NEEDED=0
        exit 0
    fi

    if pgrep -f vzdump > /dev/null; then
        echo "❌ Trwa operacja backupu (vzdump) – ⚠️ restart anulowany"
        echo
        echo "⚠️ Proxmox Auto-Update: bez restartu (trwa backup vzdump) – $(date '+%Y-%m-%d %H:%M:%S')"
        send_email
        REBOOT_NEEDED=0
        exit 0
    fi

    for vmid in $(qm list | awk 'NR>1 {print $1}'); do
        cpu=$(qm status "$vmid" --verbose | grep 'cpu=' | cut -d= -f2 | cut -d, -f1)
        cpu_percent=$(echo "$cpu * 100" | bc)
        if (( $(echo "$cpu_percent > 10" | bc -l) )); then
            echo "❌ VM $vmid zużywa za dużo CPU: ${cpu_percent}% – ⚠️ restart anulowany"
            HIGH_USAGE_VM=1
            REBOOT_NEEDED=0
        fi
    done

    for ctid in $(pct list | awk 'NR>1 {print $1}'); do
        usage=$(pct exec "$ctid" -- top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d% -f1)
        if [[ -n "$usage" && $(echo "$usage > 10" | bc -l) -eq 1 ]]; then
            echo "❌ CT $ctid zużywa za dużo CPU: ${usage}% – ⚠️ restart anulowany"
            HIGH_USAGE_VM=1
            REBOOT_NEEDED=0
        fi
    done

        REBOOT_NEEDED=1
    else
        REBOOT_NEEDED=0
    fi

    if [[ "$HIGH_USAGE_VM" -eq 1 ]]; then
        echo "✅ Kernel PO AKTUALIZACJI: $KERNEL_AFTER"
        echo
        echo "⚠️  Proxmox Auto-Update: bez restartu (wysokie zużycie CPU) – $(date '+%Y-%m-%d %H:%M:%S')"
        send_email
        exit 0
    fi

    if [ "$REBOOT_NEEDED" -eq 1 ]; then
        echo "✅ Kernel PO AKTUALIZACJI: $KERNEL_AFTER"
        echo
        echo "✅ Spełnione warunki inteligentnego restartu – wykonuję reboot: $(date '+%Y-%m-%d %H:%M:%S')"
        send_email
        systemctl reboot
    else
        echo "✅ Kernel: $KERNEL_AFTER"
        echo
        echo "✅ Aktualizacja zakończona – brak potrzeby restartu: $(date '+%Y-%m-%d %H:%M:%S')"
        send_email
    fi
} >> "$LOGFILE" 2>&1
