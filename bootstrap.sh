#!/bin/bash
set -euo pipefail

readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly BOLD=$'\033[1m'
readonly RESET=$'\033[0m'

log_error() { printf "${RED}[ERROR] %s${RESET}\n" "$1" >&2; exit 1; }
log_header() { printf "\n${BOLD}${GREEN}=== %s ===${RESET}\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS] %s${RESET}\n" "$1"; }
log_warning() { printf "${YELLOW}[WARNING] %s${RESET}\n" "$1"; }
log_info() { printf "${BLUE}[INFO] %s${RESET}\n" "$1"; }

prevent_sleep() {
    if command -v caffeinate >/dev/null 2>&1; then
        caffeinate -dims &
        CAFFEINATE_PID=$!
        trap 'kill "$CAFFEINATE_PID" &>/dev/null 2>&1 || true' EXIT
        log_info "Sleep prevention activated."
    else
        log_warning "caffeinate command not found, sleep prevention disabled."
    fi
}

check_prerequisites() {
    if [[ ! -f "artisan" ]]; then
        log_error "❌ Ce script doit être exécuté dans un projet Laravel."
    fi
    if [[ ! -f ".env" ]]; then
        log_error "❌ Le fichier .env est introuvable."
    fi
    if ! command -v composer >/dev/null 2>&1; then
        log_error "❌ Composer n'est pas installé ou n'est pas dans le PATH."
    fi
    if ! command -v curl >/dev/null 2>&1; then
        log_error "❌ curl n'est pas installé ou n'est pas dans le PATH."
    fi
}

function backup_file_with_path() {
    local file="$1"
    local backup_dir="backup"
    local file_dir=$(dirname "$file")
    local backup_path="$backup_dir/$file_dir"
    local backup_file="$backup_dir/$file"
    
    # Créer l'arborescence de backup
    mkdir -p "$backup_path"
    
    if cp "$file" "$backup_file"; then
        log_info "📦 Backup créé: $backup_file"
        return 0
    else
        log_error "❌ Erreur lors de la création du backup"
        return 1
    fi
}

update_dotenv() {
    log_header "📦 Mise à jour de .env"
    sed -i '' 's|^APP_URL=http://|APP_URL=https://|g' ".env"
    sed -i '' 's|^APP_LOCALE=en$|APP_LOCALE=fr|g' ".env"

    if ! grep -q "^CSP_REPORT_URI=" ".env"; then
        cat >> ".env" << 'EOF'

CSP_REPORT_URI=
CSP_ENABLED=false
CSP_ENABLED_WHILE_HOT_RELOADING=false
CSP_NONCE_ENABLED=false
EOF
    else
        log_warning "⚠️ Variables CSP déjà présentes, ignoré."
    fi

    if ! grep -q "^COCKPIT_GRAPHQL_ENDPOINT=" ".env"; then
        cat >> ".env" << 'EOF'

COCKPIT_URL=
COCKPIT_GRAPHQL_ENDPOINT=
COCKPIT_API_TOKEN=
EOF
    else
        log_warning "⚠️ Variables Cockpit déjà présentes, ignoré."
    fi
}

function install_spatie_csp() {
    log_header "📦 Installation de Spatie CSP"
    if ! composer require spatie/laravel-csp; then
        log_error "❌ Échec de l'installation de Spatie CSP"
    fi
    if ! php artisan vendor:publish --tag=csp-config; then
        log_error "❌ Échec de la publication de la configuration de Spatie CSP"
    fi    
    log_success "✅ Spatie CSP installé et configuré"
}

function install_cockpit_cms() {
    log_header "📦 Installation de Laravel Cockpit CMS"
    if ! composer require lionelhenne/laravel-cockpit-cms; then
        log_error "❌ Échec de l'installation de Laravel Cockpit CMS"
    fi
    if ! php artisan vendor:publish --tag="cockpit-config"; then
        log_error "❌ Échec de la publication de la configuration de Laravel Cockpit CMS"
    fi
    log_success "✅ Laravel Cockpit CMS installé et configuré"
}

function create_backups() {
    log_header "📦 Backup des fichiers"
    local files_to_backup=(
        ".env"
        "config/csp.php"
        "resources/css/app.css"
        "resources/js/app.js"
    )
    for file in "${files_to_backup[@]}"; do
        backup_file_with_path "$file"
    done
    log_success "✅ Backup terminé"
}

copy_templates() {
    log_header "📦 Copie des templates"
    local templates=(
        "config/csp.php"
        "resources/css/app.css"
        "resources/css/_base.css"
        "resources/js/app.js"
    )
    for template in "${templates[@]}"; do
        local url="${GITHUB_URL}/templates/${template}"
        local dest="${template}"
        log_info "📄 Téléchargement de ${template}..."
        if ! curl -fsSL "$url" > "$dest"; then
            log_error "❌ Échec du téléchargement de ${template}"
        fi
    done
    log_success "✅ Copie terminée"
}

readonly GITHUB_URL="https://raw.githubusercontent.com/lionelhenne/laravel-setup/refs/heads/main"

main() {
    prevent_sleep
    check_prerequisites
    install_spatie_csp
    install_cockpit_cms
    create_backups
    update_dotenv
    copy_templates
    log_success "Toutes les étapes ont été exécutées avec succès."
}

main