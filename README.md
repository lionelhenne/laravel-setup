# Laravel Setup Script

Automated setup script for Laravel projects with Spatie CSP and Cockpit CMS integration.

## Features

- Installs and configures [Spatie Laravel CSP](https://github.com/spatie/laravel-csp)
- Installs and configures [Laravel Cockpit CMS](https://github.com/lionelhenne/laravel-cockpit-cms)
- Updates `.env` with CSP and Cockpit variables
- Creates backups of modified files
- Downloads custom configuration templates

## Prerequisites

- Laravel project with `artisan` file
- `.env` file present
- `composer` installed and in PATH
- `curl` installed and in PATH

## Run the script

```bash
curl -fsSL https://raw.githubusercontent.com/lionelhenne/laravel-setup/refs/heads/main/bootstrap.sh | /bin/bash
```

## What it does

### 1. Prerequisites Check

Verifies that:
- Script is run in a Laravel project (checks for `artisan` file)
- `.env` file exists
- Required commands (`composer`, `curl`) are available

### 2. Package Installation

- Installs `spatie/laravel-csp` via Composer
- Publishes Spatie CSP configuration
- Installs `lionelhenne/laravel-cockpit-cms` via Composer
- Publishes Cockpit CMS configuration

### 3. File Backups

Creates backups of the following files in a `backup/` directory:
- `.env`
- `config/csp.php`
- `resources/css/app.css`
- `resources/js/app.js`

Backup directory structure mirrors the original file structure.

### 4. Environment Configuration

Updates `.env` file:
- Changes `APP_URL` from `http://` to `https://`
- Changes `APP_LOCALE` from `en` to `fr`
- Adds CSP configuration variables:
  ```
  CSP_REPORT_URI=
  CSP_ENABLED=false
  CSP_ENABLED_WHILE_HOT_RELOADING=false
  CSP_NONCE_ENABLED=false
  ```
- Adds Cockpit CMS variables:
  ```
  COCKPIT_GRAPHQL_ENDPOINT=
  COCKPIT_API_TOKEN=
  ```

### 5. Template Download

Downloads custom configuration files from GitHub:
- `config/csp.php`
- `resources/css/app.css`
- `resources/css/_base.css`
- `resources/js/app.js`

## Customization

### Change Template Source

Modify the `GITHUB_URL` variable to point to your own template repository:

```bash
readonly GITHUB_URL="https://raw.githubusercontent.com/your-username/your-repo/main"
```

### Add More Templates

Add files to the `templates` array in `copy_templates()`:

```bash
local templates=(
    "config/csp.php"
    "resources/css/app.css"
    "resources/css/_base.css"
    "resources/js/app.js"
    "your/custom/file.php"  # Add here
)
```

### Modify Environment Variables

Edit the `update_dotenv()` function to add or modify environment variables.

## License

MIT
