#!/usr/bin/env bash
set -euo pipefail

SELF="$(readlink -f "$0")"

command -v fzf >/dev/null 2>&1 || { echo "fzf not found in PATH" >&2; exit 1; }

CONFIG_DIR="$HOME/.config/pkgpick"
CONFIG_FILE="$CONFIG_DIR/lang"
CONFIG_FULL_FILE="$CONFIG_DIR/full_sources"

# Общие бинды для меню без поиска (--no-input): раз печатать в fzf нельзя,
# стрелки и vim h/j/k/l свободны — не конфликтуют с редактированием строки
# фильтра, как в списках пакетов. right/l = выбрать, left/h = назад,
# j = вниз, k = вверх (up/down и так работают по умолчанию в fzf).
NOSEARCH_NAV_BIND='right:accept,left:abort,l:accept,h:abort,j:down,k:up'

declare -A EN=(
    [select_source]="Select a package source"
    [source_prompt]="Source> "
    [lbl_aur]="AUR (available)"
    [lbl_official]="Official repos (available)"
    [lbl_all]="All repositories (available)"
    [lbl_installed]="Installed packages"
    [lbl_aur_installed]="Installed AUR packages"
    [lbl_flatpak]="Flatpak (available)"
    [lbl_flatpak_installed]="Installed Flatpak apps/runtimes"
    [lbl_npm_global]="Installed npm packages (global)"
    [lbl_pip_global]="Installed pip packages"
    [lbl_cargo_installed]="Installed cargo packages"
    [lbl_go_installed]="Installed go packages"
    [lbl_all_installed]="All installed packages (everywhere)"
    [lbl_pipx_installed]="Installed pipx packages"
    [lbl_cleanup]="Cleanup (caches, orphans, unused files)"
    [lbl_settings]="Settings"
    [settings_header]="Settings"
    [settings_language]="Language"
    [settings_full_sources]="Show all sources (npm/pip/cargo/go/pipx)"
    [settings_on]="ON"
    [settings_off]="OFF"
    [sort_prefix]="Sort:"
    [sort_name]="Name"
    [sort_size]="Size"
    [sort_date]="Date"
    [sort_explicit]="Explicit only"
    [sort_dependency]="Dependencies only"
    [sort_apps]="Apps only"
    [sort_runtimes]="Runtimes only"
    [key_hint]="Ctrl-N name  Ctrl-S size  Ctrl-T date  Ctrl-E explicit  Ctrl-D dependency"
    [key_hint_flatpak]="Ctrl-N name  Ctrl-S size  Ctrl-E apps  Ctrl-D runtimes"
    [unknown_option]="Unknown option:"
    [invalid_lang]="Invalid --lang value (use: en or ru):"
    [aur_helper_missing]="No AUR helper (yay or paru) found in PATH; this mode needs one."
    [flatpak_missing]="flatpak not found in PATH; this mode needs it."
    [npm_missing]="npm not found in PATH; this mode needs it."
    [pip_missing]="pip/pip3 not found in PATH; this mode needs it."
    [cargo_missing]="cargo not found in PATH; this mode needs it."
    [go_missing]="go not found in PATH; this mode needs it."
    [pipx_missing]="pipx not found in PATH; this mode needs it."
    [invalid_mode]="Invalid mode:"
    [nothing_selected]="Nothing selected."
    [selected_label]="Selected"
    [action_header]="What to do with the selected packages?"
    [action_prompt]="Action> "
    [act_install]="Install"
    [act_update]="Update"
    [act_update_all]="Full update (everything)"
    [act_update_all_pacman]="Fully update all system packages"
    [act_update_all_aur]="Fully update all packages (AUR)"
    [act_update_all_flatpak]="Fully update all Flatpak packages"
    [act_update_all_npm]="Fully update all npm packages"
    [act_update_all_pip]="Fully update all outdated pip packages"
    [act_update_all_cargo]="Fully reinstall/update all cargo packages"
    [act_update_all_go]="Fully update all go-installed binaries"
    [act_update_all_pipx]="Fully update all pipx packages"
    [act_remove]="Remove"
    [act_info]="Info"
    [remove_confirm]="Remove"
    [remove_confirm_suffix]="package(s)? [Y/n]"
    [cancelled]="Cancelled."
    [invalid_action]="Invalid action:"
    [cleanup_header]="What do you want to clean up?"
    [cleanup_confirm_suffix]="Proceed? [Y/n]"
    [cleanup_nothing]="Nothing to clean up here."
    [cleanup_failed]="Command failed — nothing may have been cleaned."
    [press_enter]="Press Enter (or any key) to continue..."
    [cleanup_pacman_cache]="Package cache (pacman)"
    [cleanup_orphans]="Orphaned packages (installed as deps, no longer needed)"
    [cleanup_aur_cache]="AUR helper build cache"
    [cleanup_flatpak_unused]="Unused Flatpak runtimes"
    [cleanup_npm_cache]="npm cache"
    [cleanup_pip_cache]="pip cache"
    [cleanup_cargo_cache]="cargo registry cache"
    [cleanup_go_cache]="go build cache"
)

declare -A RU=(
    [select_source]="Выбери источник пакетов"
    [source_prompt]="Источник> "
    [lbl_aur]="AUR (доступные)"
    [lbl_official]="Официальные репозитории (доступные)"
    [lbl_all]="Все репозитории (доступные)"
    [lbl_installed]="Установленные пакеты"
    [lbl_aur_installed]="Установленные AUR-пакеты"
    [lbl_flatpak]="Flatpak (доступные)"
    [lbl_flatpak_installed]="Установленные Flatpak-приложения/runtime"
    [lbl_npm_global]="Установленные npm-пакеты (глобальные)"
    [lbl_pip_global]="Установленные pip-пакеты"
    [lbl_cargo_installed]="Установленные cargo-пакеты"
    [lbl_go_installed]="Установленные go-пакеты"
    [lbl_all_installed]="Все установленные пакеты (везде)"
    [lbl_pipx_installed]="Установленные pipx-пакеты"
    [lbl_cleanup]="Очистка (кеши, orphan-пакеты, неиспользуемое)"
    [lbl_settings]="Настройки"
    [settings_header]="Настройки"
    [settings_language]="Язык"
    [settings_full_sources]="Показывать все источники (npm/pip/cargo/go/pipx)"
    [settings_on]="ВКЛ"
    [settings_off]="ВЫКЛ"
    [sort_prefix]="Сортировка:"
    [sort_name]="Имя"
    [sort_size]="Размер"
    [sort_date]="Дата"
    [sort_explicit]="Только explicit"
    [sort_dependency]="Только dependency"
    [sort_apps]="Только приложения"
    [sort_runtimes]="Только runtime"
    [key_hint]="Ctrl-N имя  Ctrl-S размер  Ctrl-T дата  Ctrl-E explicit  Ctrl-D dependency"
    [key_hint_flatpak]="Ctrl-N имя  Ctrl-S размер  Ctrl-E приложения  Ctrl-D runtime"
    [unknown_option]="Неизвестный флаг:"
    [invalid_lang]="Некорректное значение --lang (используй: en или ru):"
    [aur_helper_missing]="Не найден AUR-хелпер (yay или paru) в PATH; этот режим требует один из них."
    [flatpak_missing]="Не найден flatpak в PATH; этот режим требует его."
    [npm_missing]="Не найден npm в PATH; этот режим требует его."
    [pip_missing]="Не найден pip/pip3 в PATH; этот режим требует его."
    [cargo_missing]="Не найден cargo в PATH; этот режим требует его."
    [go_missing]="Не найден go в PATH; этот режим требует его."
    [pipx_missing]="Не найден pipx в PATH; этот режим требует его."
    [invalid_mode]="Некорректный режим:"
    [nothing_selected]="Ничего не выбрано."
    [selected_label]="Выбрано"
    [action_header]="Что сделать с выбранными пакетами?"
    [action_prompt]="Действие> "
    [act_install]="Установить"
    [act_update]="Обновить"
    [act_update_all]="Полное обновление (всё)"
    [act_update_all_pacman]="Обновить полностью все системные пакеты"
    [act_update_all_aur]="Обновить полностью все пакеты (AUR)"
    [act_update_all_flatpak]="Обновить полностью все flatpak-пакеты"
    [act_update_all_npm]="Обновить полностью все npm-пакеты"
    [act_update_all_pip]="Обновить все устаревшие pip-пакеты"
    [act_update_all_cargo]="Переустановить/обновить все cargo-пакеты"
    [act_update_all_go]="Обновить все go-установленные бинарники"
    [act_update_all_pipx]="Обновить полностью все pipx-пакеты"
    [act_remove]="Удалить"
    [act_info]="Инфо"
    [remove_confirm]="Удалить"
    [remove_confirm_suffix]="пакет(ов)? [Y/n]"
    [cancelled]="Отменено."
    [invalid_action]="Некорректное действие:"
    [cleanup_header]="Что почистить?"
    [cleanup_confirm_suffix]="Продолжить? [Y/n]"
    [cleanup_nothing]="Тут нечего чистить."
    [cleanup_failed]="Команда завершилась с ошибкой — возможно, ничего не почистилось."
    [press_enter]="Нажми Enter (или любую клавишу), чтобы продолжить..."
    [cleanup_pacman_cache]="Кеш пакетов (pacman)"
    [cleanup_orphans]="Пакеты-сироты (стояли как зависимость, больше не нужны)"
    [cleanup_aur_cache]="Кеш сборки AUR-хелпера"
    [cleanup_flatpak_unused]="Неиспользуемые flatpak-runtime'ы"
    [cleanup_npm_cache]="Кеш npm"
    [cleanup_pip_cache]="Кеш pip"
    [cleanup_cargo_cache]="Кеш реестра cargo"
    [cleanup_go_cache]="Кеш сборки go"
)

LANG_CHOICE=""

t() {
    local key="$1"
    if [[ "$LANG_CHOICE" == "ru" ]]; then
        printf '%s' "${RU[$key]:-}"
    else
        printf '%s' "${EN[$key]:-}"
    fi
}

# ---- internal helper subcommands, invoked by fzf reload/transform-header bindings ----
# These use a distinct, positional argument grammar (not option flags), so they are
# dispatched before any generic CLI parsing below.

if [[ "${1:-}" == "__sort" ]]; then
    field="${2:-name}"
    meta_file="${3:?}"
    state_file="${4:?}"

    prev_field=""
    prev_dir=""
    if [[ -f "$state_file" ]]; then
        IFS=":" read -r prev_field prev_dir < "$state_file"
    fi

    case "$field" in
        name|size|date)
            if [[ "$field" == "$prev_field" ]]; then
                if [[ "$prev_dir" == "asc" ]]; then dir="desc"; else dir="asc"; fi
            else
                if [[ "$field" == "name" ]]; then dir="asc"; else dir="desc"; fi
            fi
            ;;
        *)
            dir=""
            ;;
    esac

    echo "$field:$dir" > "$state_file"

    case "$field" in
        name)
            if [[ "$dir" == "asc" ]]; then
                sort -t $'\t' -k1,1 "$meta_file" | cut -f1
            else
                sort -t $'\t' -k1,1 -r "$meta_file" | cut -f1
            fi
            ;;
        size)
            if [[ "$dir" == "desc" ]]; then
                sort -t $'\t' -k2,2 -gr "$meta_file" | cut -f1
            else
                sort -t $'\t' -k2,2 -g "$meta_file" | cut -f1
            fi
            ;;
        date)
            if [[ "$dir" == "desc" ]]; then
                LC_ALL=C pacman -Qi 2>/dev/null | awk -v meta="$meta_file" '
                    BEGIN {
                        while ((getline < meta) > 0) {
                            split($0, f, "\t"); pkgs[f[1]] = 1
                        }
                        close(meta)
                    }
                    /^Name/ { line=$0; sub(/^Name[ \t]*: /,"",line); name=line }
                    /^Install Date/ {
                        line=$0; sub(/^Install Date[ \t]*: /,"",line)
                        cmd = "LC_ALL=C date -d \x27" line "\x27 +%s 2>/dev/null"
                        cmd | getline epoch; close(cmd)
                        date = epoch + 0
                    }
                    /^$/ {
                        if (name != "" && name in pkgs) printf "%d\t%s\n", date, name
                        name = ""; date = 0
                    }
                    END {
                        if (name != "" && name in pkgs) printf "%d\t%s\n", date, name
                    }
                ' | sort -t$'\t' -k1,1 -nr | cut -f2
            else
                LC_ALL=C pacman -Qi 2>/dev/null | awk -v meta="$meta_file" '
                    BEGIN {
                        while ((getline < meta) > 0) {
                            split($0, f, "\t"); pkgs[f[1]] = 1
                        }
                        close(meta)
                    }
                    /^Name/ { line=$0; sub(/^Name[ \t]*: /,"",line); name=line }
                    /^Install Date/ {
                        line=$0; sub(/^Install Date[ \t]*: /,"",line)
                        cmd = "LC_ALL=C date -d \x27" line "\x27 +%s 2>/dev/null"
                        cmd | getline epoch; close(cmd)
                        date = epoch + 0
                    }
                    /^$/ {
                        if (name != "" && name in pkgs) printf "%d\t%s\n", date, name
                        name = ""; date = 0
                    }
                    END {
                        if (name != "" && name in pkgs) printf "%d\t%s\n", date, name
                    }
                ' | sort -t$'\t' -k1,1 -n | cut -f2
            fi
            ;;
        explicit)
            awk -F'\t' '$4=="explicit"{print $1}' "$meta_file"
            ;;
        dependency)
            awk -F'\t' '$4=="dependency"{print $1}' "$meta_file"
            ;;
    esac
    exit 0
fi

if [[ "${1:-}" == "__header" ]]; then
    state_file="${2:?}"

    # Read-only language resolution: never prompt from inside a reload subprocess.
    # By construction the main process has already resolved (and persisted) the
    # language before this helper is ever invoked, so the config file will exist.
    if [[ -f "$CONFIG_FILE" ]]; then
        LANG_CHOICE=$(cat "$CONFIG_FILE")
    fi
    [[ "$LANG_CHOICE" != "en" && "$LANG_CHOICE" != "ru" ]] && LANG_CHOICE="en"

    field="name"
    dir="asc"
    if [[ -f "$state_file" ]]; then
        IFS=":" read -r field dir < "$state_file"
    fi
    arrow=""
    case "$dir" in
        asc) arrow="↑" ;;
        desc) arrow="↓" ;;
    esac
    label="$(t "sort_$field")"
    echo "$(t sort_prefix) $label $arrow   $(t key_hint)"
    exit 0
fi

if [[ "${1:-}" == "__sort_fp" ]]; then
    field="${2:-name}"
    meta_file="${3:?}"
    state_file="${4:?}"

    prev_field=""
    prev_dir=""
    if [[ -f "$state_file" ]]; then
        IFS=":" read -r prev_field prev_dir < "$state_file"
    fi

    case "$field" in
        name|size)
            if [[ "$field" == "$prev_field" ]]; then
                if [[ "$prev_dir" == "asc" ]]; then dir="desc"; else dir="asc"; fi
            else
                if [[ "$field" == "name" ]]; then dir="asc"; else dir="desc"; fi
            fi
            ;;
        *)
            dir=""
            ;;
    esac

    echo "$field:$dir" > "$state_file"

    # meta_file columns: id \t name \t size_bytes \t kind(app|runtime|available) \t description
    case "$field" in
        name)
            if [[ "$dir" == "asc" ]]; then
                sort -t $'\t' -k2,2f "$meta_file"
            else
                sort -t $'\t' -k2,2fr "$meta_file"
            fi | awk -F'\t' '{print $1, $2}'
            ;;
        size)
            if [[ "$dir" == "desc" ]]; then
                sort -t $'\t' -k3,3 -gr "$meta_file"
            else
                sort -t $'\t' -k3,3 -g "$meta_file"
            fi | awk -F'\t' '{print $1, $2}'
            ;;
        explicit)
            awk -F'\t' '$4=="app"{print $1, $2}' "$meta_file"
            ;;
        dependency)
            awk -F'\t' '$4=="runtime"{print $1, $2}' "$meta_file"
            ;;
    esac
    exit 0
fi

if [[ "${1:-}" == "__header_fp" ]]; then
    state_file="${2:?}"

    if [[ -f "$CONFIG_FILE" ]]; then
        LANG_CHOICE=$(cat "$CONFIG_FILE")
    fi
    [[ "$LANG_CHOICE" != "en" && "$LANG_CHOICE" != "ru" ]] && LANG_CHOICE="en"

    field="name"
    dir="asc"
    if [[ -f "$state_file" ]]; then
        IFS=":" read -r field dir < "$state_file"
    fi
    arrow=""
    case "$dir" in
        asc) arrow="↑" ;;
        desc) arrow="↓" ;;
    esac
    case "$field" in
        explicit) label="$(t sort_apps)" ;;
        dependency) label="$(t sort_runtimes)" ;;
        *) label="$(t "sort_$field")" ;;
    esac
    echo "$(t sort_prefix) $label $arrow   $(t key_hint_flatpak)"
    exit 0
fi

if [[ "${1:-}" == "__fp_info" ]]; then
    id="${2:?}"
    meta_file="${3:?}"
    awk -F'\t' -v id="$id" '
        $1 == id {
            name = $2; size = $3; kind = $4; desc = $5
            print name
            if (kind == "app") print "Type: application"
            else if (kind == "runtime") print "Type: runtime"
            if (size + 0 > 0) printf "Size: %.1f MB\n", size / 1024 / 1024
            print ""
            print (desc == "" ? "(no description)" : desc)
            found = 1
            exit
        }
        END { if (!found) print "No info available." }
    ' "$meta_file"
    exit 0
fi

if [[ "${1:-}" == "__all_info" ]]; then
    token="${2:?}"
    src="${token%%:*}"
    id="${token#*:}"
    case "$src" in
        pacman|aur)
            pacman -Qi "$id" 2>/dev/null || echo "No info available."
            ;;
        flatpak)
            flatpak info "$id" 2>/dev/null || echo "No info available."
            ;;
        npm)
            npm view "$id" 2>/dev/null || echo "No info available."
            ;;
        pip)
            if command -v pip3 >/dev/null 2>&1; then
                pip3 show "$id" 2>/dev/null || echo "No info available."
            elif command -v pip >/dev/null 2>&1; then
                pip show "$id" 2>/dev/null || echo "No info available."
            else
                echo "No info available."
            fi
            ;;
        cargo)
            "$SELF" __cargo_info "$id"
            ;;
        go)
            gobin=$(go env GOBIN 2>/dev/null)
            [[ -z "$gobin" ]] && gobin="$(go env GOPATH 2>/dev/null)/bin"
            go version -m "$gobin/$id" 2>/dev/null || echo "No info available."
            ;;
        pipx)
            "$SELF" __pipx_info "$id"
            ;;
        *)
            echo "No info available."
            ;;
    esac
    exit 0
fi

if [[ "${1:-}" == "__cargo_info" ]]; then
    pkg="${2:?}"
    cargo install --list 2>/dev/null | awk -v pkg="$pkg" '
        $0 ~ "^" pkg " " { show=1; print; next }
        show && /^[ \t]/ { print; next }
        show { exit }
    '
    exit 0
fi

if [[ "${1:-}" == "__pipx_info" ]]; then
    pkg="${2:?}"
    # `pipx list` blocks look like:
    #    package black 23.3.0, installed using Python 3.11.4
    #     - black
    #     - blackd
    pipx list 2>/dev/null | awk -v pkg="$pkg" '
        $0 ~ "^[ \t]*package " pkg " " { show=1; print; next }
        show && /^[ \t]*-/ { print; next }
        show { exit }
        END { if (!show) print "No info available." }
    '
    exit 0
fi

if [[ "${1:-}" == "__go_info" ]]; then
    dir="${2:?}"
    bin="${3:?}"
    go version -m "$dir/$bin" 2>/dev/null || echo "No info available."
    exit 0
fi

if [[ "${1:-}" == "__go_modpath" ]]; then
    dir="${2:?}"
    bin="${3:?}"
    go version -m "$dir/$bin" 2>/dev/null | awk '$1=="path"{print $2; exit}'
    exit 0
fi

usage() {
    local lang_display="$LANG_CHOICE"
    if [[ "$LANG_CHOICE" == "ru" ]]; then
        [[ -z "$lang_display" ]] && lang_display="ещё не выбран (появится запрос выбора языка)"
cat <<EOF
Использование: pkgpick [ОПЦИЯ]

Текущий язык интерфейса: $lang_display
Файл конфигурации языка: $CONFIG_FILE
(удали этот файл — при следующем запуске снова появится выбор языка)

  --aur               AUR-пакеты (доступные)
  --official          Официальные пакеты (доступные)
  --all               Все репозитории (доступные)
  --installed         Установленные пакеты
  --aur-installed     Установленные AUR-пакеты
  --flatpak           Flatpak-приложения (доступные для установки)
  --flatpak-installed Установленные Flatpak-приложения и runtime'ы
  --npm-global        Установленные глобальные npm-пакеты
  --pip-global        Установленные pip-пакеты (pip3/pip, если есть в PATH)
  --cargo-installed   Установленные через 'cargo install' бинарники
  --go-installed      Установленные через 'go install' бинарники (GOBIN/GOPATH/bin)
  --pipx-installed    Установленные через pipx пакеты
  --all-installed     Все установленные пакеты сразу (pacman/AUR + flatpak + npm + pip + cargo + go + pipx)
  --cleanup           Меню очистки: кеши пакетных менеджеров, orphan-пакеты, unused flatpak
  --full              Показать npm/pip/cargo/go/pipx в меню один раз, не сохраняя (см. Настройки)
  --lang en|ru        Сменить язык интерфейса НАВСЕГДА (сохраняется в конфиг)
                      и продолжить с этим языком в текущем запуске
  -h, --help          Показать эту справку

Для installed / aur-installed сортировку/фильтр можно менять прямо в списке:
  Ctrl-N  по имени      (переключение asc/desc)
  Ctrl-S  по размеру    (переключение asc/desc)
  Ctrl-T  по дате       (переключение asc/desc)
  Ctrl-E  только explicit
  Ctrl-D  только dependency

Для flatpak-installed сортировка/фильтр тоже доступны, но без даты:
  Ctrl-N  по имени      (переключение asc/desc)
  Ctrl-S  по размеру    (переключение asc/desc)
  Ctrl-E  только приложения (app)
  Ctrl-D  только runtime'ы (библиотеки/платформы)
Список flatpak-installed теперь включает и приложения, и runtime'ы
(раньше runtime'ы вроде Nvidia VAAPI driver туда не попадали).

После выбора пакетов (Tab — мультивыбор) откроется меню действий:
  update / remove / info / (кнопка полного обновления — последняя в списке)
Для installed / aur-installed / flatpak-installed / npm-global в конце меню
действий есть отдельная кнопка полного обновления источника — она игнорирует
выделение и обновляет ВСЕ пакеты этого источника, и подписана по-разному:
  installed          -> "Обновить полностью все системные пакеты (pacman)"
                          или "... (pacman + AUR)", если найден AUR-хелпер —
                          в этом случае реально вызывается ОН (yay/paru -Syu),
                          что и обновляет разом и pacman, и AUR
  aur-installed       -> "Обновить полностью все пакеты (AUR)"      (AUR-хелпер -Syu)
  flatpak-installed  -> "Обновить полностью все flatpak-пакеты"    (flatpak update)
  npm-global          -> "Обновить полностью все npm-пакеты"        (npm update -g)

Режим --all-installed показывает пакеты из ВСЕХ источников одним списком
(pacman/AUR + flatpak + npm) — там нет кнопки "обновить всё разом", т.к.
источники разные, зато update/remove/info применяются к каждому выбранному
пакету через нужный ему менеджер автоматически.

Если в PATH нет ни yay, ни paru, доступны только --official и --installed
(режимы, требующие AUR, будут скрыты из меню и недоступны через флаги).
Если в PATH нет flatpak, режимы --flatpak и --flatpak-installed скрыты
из меню и недоступны через флаги.
Если в PATH нет npm, режим --npm-global скрыт из меню и недоступен через флаг.
Если в PATH нет ни pip3, ни pip, режим --pip-global скрыт из меню и недоступен.
Если в PATH нет cargo, режим --cargo-installed скрыт из меню и недоступен.
Если в PATH нет go, режим --go-installed скрыт из меню и недоступен.
Если в PATH нет pipx, режим --pipx-installed скрыт из меню и недоступен.
Комбинированный --all-installed всегда доступен (использует pacman) и просто
не включает в список те источники (flatpak/npm/pip/cargo/go), которых нет.
EOF
    else
        [[ -z "$lang_display" ]] && lang_display="not chosen yet (you'll be prompted)"
cat <<EOF
Usage: pkgpick [OPTION]

Current interface language: $lang_display
Language config file: $CONFIG_FILE
(delete this file — the language picker will show again on the next run)

  --aur               AUR packages (available)
  --official          Official repo packages (available)
  --all               All repositories (available)
  --installed         Installed packages
  --aur-installed     Installed AUR packages
  --flatpak           Flatpak apps (available to install)
  --flatpak-installed Installed Flatpak apps and runtimes
  --npm-global        Installed global npm packages
  --pip-global        Installed pip packages (pip3/pip, whichever is in PATH)
  --cargo-installed   Binaries installed via 'cargo install'
  --go-installed      Binaries installed via 'go install' (GOBIN/GOPATH/bin)
  --pipx-installed    Packages installed via pipx
  --all-installed     Every installed package at once (pacman/AUR + flatpak + npm + pip + cargo + go + pipx)
  --cleanup           Cleanup menu: package manager caches, orphaned packages, unused flatpak runtimes
  --full              Show npm/pip/cargo/go/pipx in the menu for this run only, without saving (see Settings)
  --lang en|ru        Change UI language PERMANENTLY (saved to config)
                      and continue this run in that language
  -h, --help          Show this help

For installed / aur-installed, sorting can be changed live inside the list:
  Ctrl-N  sort by name        (toggle asc/desc)
  Ctrl-S  sort by size        (toggle asc/desc)
  Ctrl-T  sort by date        (toggle asc/desc)
  Ctrl-E  filter explicit only
  Ctrl-D  filter dependencies only

For flatpak-installed, sorting/filtering is also available, without date:
  Ctrl-N  sort by name        (toggle asc/desc)
  Ctrl-S  sort by size        (toggle asc/desc)
  Ctrl-E  filter apps only
  Ctrl-D  filter runtimes only
The flatpak-installed list now includes both apps and runtimes (previously
runtimes such as the Nvidia VAAPI driver were excluded from the list).

After selecting packages (Tab for multi-select), an action menu appears:
  update / remove / info / (a full-update button, always listed last)
For installed / aur-installed / flatpak-installed / npm-global, the last
item in the action menu is a source-specific full update button — it
ignores your selection and updates ALL packages from that source, labeled
per source:
  installed          -> "Fully update all system packages (pacman)", or
                          "... (pacman + AUR)" if an AUR helper is found —
                          in that case the helper itself (yay/paru -Syu) is
                          what actually runs, covering pacman and AUR at once
  aur-installed       -> "Fully update all packages (AUR)"      (AUR helper -Syu)
  flatpak-installed  -> "Fully update all Flatpak packages"    (flatpak update)
  npm-global          -> "Fully update all npm packages"        (npm update -g)

The --all-installed mode lists packages from every source at once (pacman/AUR
+ flatpak + npm) in one combined list. There is no single "update everything"
button there, since the sources are different package managers — but
update/remove/info on your selection is dispatched to the right manager
automatically per package.

If neither yay nor paru is found in PATH, only --official and --installed
are available (AUR-requiring modes are hidden from the menu and refused
via flags).
If flatpak is not found in PATH, --flatpak and --flatpak-installed are
hidden from the menu and refused via flags.
If npm is not found in PATH, --npm-global is hidden from the menu and
refused via the flag.
If neither pip3 nor pip is found in PATH, --pip-global is hidden and refused.
If cargo is not found in PATH, --cargo-installed is hidden and refused.
If go is not found in PATH, --go-installed is hidden and refused.
If pipx is not found in PATH, --pipx-installed is hidden and refused.
The combined --all-installed mode is always available (it uses pacman) and
simply omits whichever sources (flatpak/npm/pip/cargo/go) are not installed.
EOF
    fi
}

# ---- resolve a provisional language (config file only, no prompt yet) ----
# This lets any error/usage text printed during argument parsing already be
# localized to the user's saved preference, before --lang (if given) overrides it.
if [[ -f "$CONFIG_FILE" ]]; then
    LANG_CHOICE=$(cat "$CONFIG_FILE")
fi
[[ "$LANG_CHOICE" != "en" && "$LANG_CHOICE" != "ru" ]] && LANG_CHOICE=""

# ---- resolve persisted "show full source list" setting (npm/pip/cargo/go/pipx) ----
# Off by default: the interactive source menu shows only pacman/AUR/flatpak by
# default, to keep it short. Turned on permanently via the Settings menu, or
# just for this run via --full. Direct flags like --npm-global always work
# regardless of this setting, since they skip the menu entirely.
SHOW_FULL=""
if [[ -f "$CONFIG_FULL_FILE" && "$(cat "$CONFIG_FULL_FILE")" == "1" ]]; then
    SHOW_FULL="1"
fi

# ---- parse CLI arguments ----
MODE=""
LANG_FLAG=""
FULL_FLAG=""
HELP_REQUESTED=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --lang)
            shift
            case "${1:-}" in
                en|ru) LANG_FLAG="$1" ;;
                *)
                    echo "$(t invalid_lang) ${1:-}" >&2
                    exit 1
                    ;;
            esac
            ;;
        --lang=en) LANG_FLAG="en" ;;
        --lang=ru) LANG_FLAG="ru" ;;
        --aur)                MODE="aur" ;;
        --official)           MODE="official" ;;
        --all)                 MODE="all" ;;
        --installed)          MODE="installed" ;;
        --aur-installed)      MODE="aur-installed" ;;
        --flatpak)            MODE="flatpak" ;;
        --flatpak-installed)  MODE="flatpak-installed" ;;
        --npm-global)          MODE="npm-global" ;;
        --pip-global)          MODE="pip-global" ;;
        --cargo-installed)     MODE="cargo-installed" ;;
        --go-installed)        MODE="go-installed" ;;
        --all-installed)       MODE="all-installed" ;;
        --pipx-installed)      MODE="pipx-installed" ;;
        --cleanup)              MODE="cleanup" ;;
        --full)                 FULL_FLAG="1" ;;
        -h|--help)            HELP_REQUESTED=1 ;;
        *)
            echo "$(t unknown_option) $1" >&2
            usage
            exit 1
            ;;
    esac
    shift
done

# ---- apply --full: transient override, does not touch the saved setting ----
[[ -n "$FULL_FLAG" ]] && SHOW_FULL="1"

# ---- finalize language: flag > saved config > interactive picker ----
if [[ -n "$LANG_FLAG" ]]; then
    LANG_CHOICE="$LANG_FLAG"
    mkdir -p "$CONFIG_DIR"
    echo "$LANG_CHOICE" > "$CONFIG_FILE"
elif [[ "$HELP_REQUESTED" -eq 1 ]]; then
    [[ "$LANG_CHOICE" != "en" && "$LANG_CHOICE" != "ru" ]] && LANG_CHOICE="en"
elif [[ "$LANG_CHOICE" != "en" && "$LANG_CHOICE" != "ru" ]]; then
    LANG_CHOICE=$(printf "en\tEnglish\nru\tРусский\n" | \
        fzf --exact --height 100% --border --layout=reverse --no-input \
            --bind "$NOSEARCH_NAV_BIND" \
            --delimiter=$'\t' --with-nth=2 \
            --prompt="Language / Язык> " \
            --header="Choose your language / Выберите язык" | \
        cut -f1) || true
    [[ -z "$LANG_CHOICE" ]] && LANG_CHOICE="en"
    mkdir -p "$CONFIG_DIR"
    echo "$LANG_CHOICE" > "$CONFIG_FILE"
fi

if [[ "$HELP_REQUESTED" -eq 1 ]]; then
    usage
    exit 0
fi

AUR_HELPER=""
if command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
fi

if [[ -z "$AUR_HELPER" && ( "$MODE" == "aur" || "$MODE" == "all" || "$MODE" == "aur-installed" ) ]]; then
    printf '%s\n' "$(t aur_helper_missing)" >&2
    exit 1
fi

HAS_FLATPAK=""
if command -v flatpak >/dev/null 2>&1; then
    HAS_FLATPAK="1"
fi

if [[ -z "$HAS_FLATPAK" && ( "$MODE" == "flatpak" || "$MODE" == "flatpak-installed" ) ]]; then
    printf '%s\n' "$(t flatpak_missing)" >&2
    exit 1
fi

HAS_NPM=""
if command -v npm >/dev/null 2>&1; then
    HAS_NPM="1"
fi

if [[ -z "$HAS_NPM" && "$MODE" == "npm-global" ]]; then
    printf '%s\n' "$(t npm_missing)" >&2
    exit 1
fi

PIP_BIN=""
if command -v pip3 >/dev/null 2>&1; then
    PIP_BIN="pip3"
elif command -v pip >/dev/null 2>&1; then
    PIP_BIN="pip"
fi
HAS_PIP=""
[[ -n "$PIP_BIN" ]] && HAS_PIP="1"

if [[ -z "$HAS_PIP" && "$MODE" == "pip-global" ]]; then
    printf '%s\n' "$(t pip_missing)" >&2
    exit 1
fi

HAS_CARGO=""
if command -v cargo >/dev/null 2>&1; then
    HAS_CARGO="1"
fi

if [[ -z "$HAS_CARGO" && "$MODE" == "cargo-installed" ]]; then
    printf '%s\n' "$(t cargo_missing)" >&2
    exit 1
fi

HAS_GO=""
GO_BIN_DIR=""
if command -v go >/dev/null 2>&1; then
    HAS_GO="1"
    GO_BIN_DIR=$(go env GOBIN 2>/dev/null)
    [[ -z "$GO_BIN_DIR" ]] && GO_BIN_DIR="$(go env GOPATH 2>/dev/null)/bin"
fi

if [[ -z "$HAS_GO" && "$MODE" == "go-installed" ]]; then
    printf '%s\n' "$(t go_missing)" >&2
    exit 1
fi

HAS_PIPX=""
if command -v pipx >/dev/null 2>&1; then
    HAS_PIPX="1"
fi

if [[ -z "$HAS_PIPX" && "$MODE" == "pipx-installed" ]]; then
    printf '%s\n' "$(t pipx_missing)" >&2
    exit 1
fi

# "installed" (pacman) is labeled with what a full update there actually
# covers: if an AUR helper is present, the full-update button below calls
# the helper itself (yay/paru -Syu), which updates pacman AND AUR in one go.
if [[ -n "$AUR_HELPER" ]]; then
    SYS_SUFFIX=" (pacman + AUR)"
else
    SYS_SUFFIX=" (pacman)"
fi

FLAG_MODE="$MODE"

FZF_COMMON_OPTS=(
    --multi
    --exact
    --height 100%
    --border
    --layout=reverse
    --preview-window=right:60%:wrap
    --bind 'shift-up:preview-page-up,shift-down:preview-page-down'
)

META_FILE=""
STATE_FILE=""
HELPER_SCRIPT=""
cleanup() {
    [[ -n "$META_FILE" && -f "$META_FILE" ]] && rm -f "$META_FILE"
    [[ -n "$STATE_FILE" && -f "$STATE_FILE" ]] && rm -f "$STATE_FILE"
    [[ -n "$HELPER_SCRIPT" && -f "$HELPER_SCRIPT" ]] && rm -f "$HELPER_SCRIPT"
    return 0
}
trap cleanup EXIT

build_meta() {
    local filter_aur="$1"
    local tmp aur_set
    tmp=$(mktemp)
    aur_set=""
    if [[ "$filter_aur" == "yes" ]]; then
        aur_set=$(pacman -Qqm 2>/dev/null || true)
    fi
    LC_ALL=C pacman -Qi | awk -v want_aur="$filter_aur" -v aur_list="$aur_set" '
        BEGIN {
            n = split(aur_list, arr, "\n")
            for (i = 1; i <= n; i++) aur_map[arr[i]] = 1
        }
        /^Name/ { line=$0; sub(/^Name[ \t]*: /,"",line); name=line }
        /^Installed Size/ {
            line=$0; sub(/^Installed Size[ \t]*: /,"",line)
            split(line, a, " ")
            val = a[1] + 0; unit = a[2]
            if (unit == "KiB") bytes = val * 1024
            else if (unit == "MiB") bytes = val * 1024 * 1024
            else if (unit == "GiB") bytes = val * 1024 * 1024 * 1024
            else bytes = val
            size = int(bytes)
        }
        /^Install Date/ {
            date = 0
        }
        /^Install Reason/ {
            if ($0 ~ /Explicitly/) reason = "explicit"; else reason = "dependency"
        }
        /^$/ {
            if (name != "" && (want_aur == "no" || (name in aur_map))) {
                print name "\t" size "\t" date "\t" reason
            }
            name=""; size=0; date=0; reason="?"
        }
        END {
            if (name != "" && (want_aur == "no" || (name in aur_map))) {
                print name "\t" size "\t" date "\t" reason
            }
        }
    ' > "$tmp"
    echo "$tmp"
}

flatpak_size_to_bytes_awk='
    # Handles: "45.6 MB", "45.6MB" (no space), "45,6 MB" (comma decimal),
    # non-breaking spaces, and plain raw byte counts with no unit at all
    # (some flatpak versions print --columns=size as a bare byte number).
    # Returns 0 (caller must treat 0 as "unknown, do not display") for
    # anything that cannot be confidently parsed, instead of silently
    # producing a tiny garbage number that used to show up as "0.0 MB".
    function size_to_bytes(sizestr,   s, val, unit, rest, bytes) {
        s = sizestr
        gsub(/\xc2\xa0/, " ", s)
        gsub(/^[ \t]+|[ \t]+$/, "", s)
        if (s == "") return 0
        if (!match(s, /^[0-9]+([.,][0-9]+)?/)) return 0
        val = substr(s, RSTART, RLENGTH)
        gsub(/,/, ".", val)
        val = val + 0
        rest = substr(s, RSTART + RLENGTH)
        gsub(/^[ \t]+/, "", rest)
        unit = toupper(substr(rest, 1, 1))
        if (unit == "K") bytes = val * 1024
        else if (unit == "M") bytes = val * 1024 * 1024
        else if (unit == "G") bytes = val * 1024 * 1024 * 1024
        else if (unit == "T") bytes = val * 1024 * 1024 * 1024 * 1024
        else if (unit == "") bytes = val
        else return 0
        return int(bytes)
    }
'

# meta columns: id \t name \t size_bytes \t kind \t description
build_meta_flatpak_available() {
    local tmp
    tmp=$(mktemp)
    LC_ALL=C flatpak remote-ls --app --columns=application,name,download-size,description 2>/dev/null | \
        awk -F'\t' "$flatpak_size_to_bytes_awk"'
        {
            id = $1; name = ($2 == "" ? $1 : $2); desc = $4
            bytes = size_to_bytes($3)
            gsub(/\t/, " ", desc)
            print id "\t" name "\t" bytes "\t" "available" "\t" desc
        }' > "$tmp"
    echo "$tmp"
}

build_meta_flatpak_installed() {
    local tmp app_ids
    tmp=$(mktemp)
    app_ids=$'\n'"$(flatpak list --app --columns=application 2>/dev/null)"$'\n'
    LC_ALL=C flatpak list --columns=application,name,size,description 2>/dev/null | \
        awk -F'\t' -v apps="$app_ids" "$flatpak_size_to_bytes_awk"'
        function is_app(id,   needle) {
            needle = "\n" id "\n"
            return index(apps, needle) > 0
        }
        {
            id = $1; name = ($2 == "" ? $1 : $2); desc = $4
            bytes = size_to_bytes($3)
            gsub(/\t/, " ", desc)
            kind = is_app(id) ? "app" : "runtime"
            print id "\t" name "\t" bytes "\t" kind "\t" desc
        }' > "$tmp"
    echo "$tmp"
}
# Комбинированный список: pacman/AUR + flatpak + npm в одну таблицу.
# meta columns: token(source:id) \t display_name \t source \t size_bytes
# token используется как значение для выбора (fzf --with-nth скрывает его,
# показывая только display_name [source]); source нужен, чтобы потом понять,
# каким менеджером обновлять/удалять/смотреть info для конкретной строки.
build_meta_all_installed() {
    local tmp aur_set fp_meta

    tmp=$(mktemp)

    aur_set=$(pacman -Qqm 2>/dev/null || true)
    LC_ALL=C pacman -Qi | awk -v aur_list="$aur_set" '
        BEGIN {
            n = split(aur_list, arr, "\n")
            for (i = 1; i <= n; i++) aur_map[arr[i]] = 1
        }
        /^Name/ { line=$0; sub(/^Name[ \t]*: /,"",line); name=line }
        /^Installed Size/ {
            line=$0; sub(/^Installed Size[ \t]*: /,"",line)
            split(line, a, " ")
            val = a[1] + 0; unit = a[2]
            if (unit == "KiB") bytes = val * 1024
            else if (unit == "MiB") bytes = val * 1024 * 1024
            else if (unit == "GiB") bytes = val * 1024 * 1024 * 1024
            else bytes = val
            size = int(bytes)
        }
        /^$/ {
            if (name != "") {
                src = (name in aur_map) ? "aur" : "pacman"
                print src ":" name "\t" name "\t" src "\t" size
            }
            name=""; size=0
        }
        END {
            if (name != "") {
                src = (name in aur_map) ? "aur" : "pacman"
                print src ":" name "\t" name "\t" src "\t" size
            }
        }
    ' >> "$tmp"

    if [[ -n "$HAS_FLATPAK" ]]; then
        fp_meta=$(build_meta_flatpak_installed)
        awk -F'\t' '{ print "flatpak:" $1 "\t" $2 "\t" "flatpak" "\t" $3 }' "$fp_meta" >> "$tmp"
        rm -f "$fp_meta"
    fi

    if [[ -n "$HAS_NPM" ]]; then
        { npm ls -g --depth=0 --parseable 2>/dev/null || true; } | \
            awk 'NR > 1 {
                name = $0
                sub(/^.*\/node_modules\//, "", name)
                if (name != "") print "npm:" name "\t" name "\t" "npm" "\t" 0
            }' >> "$tmp"
    fi

    if [[ -n "$HAS_PIP" ]]; then
        "$PIP_BIN" list --format=freeze 2>/dev/null | \
            awk -F'==' '{ print "pip:" $1 "\t" $1 "\t" "pip" "\t" 0 }' >> "$tmp"
    fi

    if [[ -n "$HAS_CARGO" ]]; then
        cargo install --list 2>/dev/null | \
            awk '/^[^ \t]/ && /:$/ { sub(/:$/,""); split($0,a," "); print "cargo:" a[1] "\t" a[1] "\t" "cargo" "\t" 0 }' >> "$tmp"
    fi

    if [[ -n "$HAS_GO" && -d "$GO_BIN_DIR" ]]; then
        find "$GO_BIN_DIR" -maxdepth 1 -type f -perm -u+x -exec basename {} \; 2>/dev/null | \
            awk '{ print "go:" $1 "\t" $1 "\t" "go" "\t" 0 }' >> "$tmp"
    fi

    if [[ -n "$HAS_PIPX" ]]; then
        pipx list --short 2>/dev/null | \
            awk '{ print "pipx:" $1 "\t" $1 "\t" "pipx" "\t" 0 }' >> "$tmp"
    fi

    echo "$tmp"
}

# ---- generic "press enter to continue" that also accepts Esc (or any key) ----
press_enter_or_esc() {
    read -rsn1 -p "$(t press_enter)" _ || true
    echo
}

# ---- true if a directory exists and has at least one entry inside ----
dir_has_content() {
    [[ -d "$1" ]] && [[ -n "$(find "$1" -mindepth 1 -print -quit 2>/dev/null)" ]]
}

# ---- settings menu helpers ----
lang_display_name() {
    case "$1" in
        ru) echo "Русский" ;;
        *)  echo "English" ;;
    esac
}

# Same picker as the startup one, but on Esc it leaves the current language
# untouched instead of defaulting to English — startup and settings need
# different "nothing chosen" behavior, so this isn't shared with the block above.
settings_pick_language() {
    local choice
    choice=$(printf "en\tEnglish\nru\tРусский\n" | \
        fzf --exact --height 100% --border --layout=reverse --no-input \
            --bind "$NOSEARCH_NAV_BIND" \
            --delimiter=$'\t' --with-nth=2 \
            --prompt="Language / Язык> " \
            --header="Choose your language / Выберите язык" | \
        cut -f1) || true
    if [[ -n "$choice" ]]; then
        LANG_CHOICE="$choice"
        mkdir -p "$CONFIG_DIR"
        echo "$LANG_CHOICE" > "$CONFIG_FILE"
    fi
}

toggle_full_sources() {
    if [[ "$SHOW_FULL" == "1" ]]; then
        SHOW_FULL=""
    else
        SHOW_FULL="1"
    fi
    mkdir -p "$CONFIG_DIR"
    echo "${SHOW_FULL:-0}" > "$CONFIG_FULL_FILE"
}

# ---- cleanup mode: каждая функция показывает детали, спрашивает [y/N], выполняет ----
# Возврат: 0 = было что показать/сделать (в вызывающем коде после этого пауза
#          "нажми что-нибудь"), 1 = юзер отказался на confirm - тихо назад,
#          без паузы.
cleanup_confirm_and_run() {
    # $1 = shell command to run on confirm (eval'd)
    read -r -p "$(t cleanup_confirm_suffix) " confirm
    case "$confirm" in
        ""|y|Y|yes|Yes|д|Д|да|Да)
            if ! eval "$1"; then
                printf '%s\n' "$(t cleanup_failed)" >&2
            fi
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

do_cleanup_pacman_cache() {
    echo "== $(t cleanup_pacman_cache) =="
    local cache_dir="/var/cache/pacman/pkg"
    if ! dir_has_content "$cache_dir"; then
        printf '%s\n' "$(t cleanup_nothing)"
        return 0
    fi
    local size
    size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
    echo "$cache_dir: $size"
    cleanup_confirm_and_run 'sudo pacman -Sc --noconfirm'
}

do_cleanup_orphans() {
    echo "== $(t cleanup_orphans) =="
    local orphans count
    orphans=$(pacman -Qtdq 2>/dev/null || true)
    if [[ -z "$orphans" ]]; then
        printf '%s\n' "$(t cleanup_nothing)"
        return 0
    fi
    echo "$orphans"
    count=$(echo "$orphans" | grep -c .)
    echo "($count)"
    cleanup_confirm_and_run "echo \"\$orphans\" | xargs -o -r sudo pacman -Rns"
}

do_cleanup_aur_cache() {
    echo "== $(t cleanup_aur_cache) =="
    local cache_dir="$HOME/.cache/$AUR_HELPER"
    if ! dir_has_content "$cache_dir"; then
        printf '%s\n' "$(t cleanup_nothing)"
        return 0
    fi
    local size
    size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
    echo "$cache_dir: $size"
    cleanup_confirm_and_run '"$AUR_HELPER" -Sc --noconfirm'
}

do_cleanup_flatpak_unused() {
    echo "== $(t cleanup_flatpak_unused) =="
    local preview
    preview=$(flatpak uninstall --unused --assumeno 2>&1 || true)
    if [[ -z "$preview" ]]; then
        printf '%s\n' "$(t cleanup_nothing)"
        return 0
    fi
    echo "$preview"
    cleanup_confirm_and_run 'flatpak uninstall --unused -y'
}

do_cleanup_npm_cache() {
    echo "== $(t cleanup_npm_cache) =="
    local cache_dir
    cache_dir=$(npm config get cache 2>/dev/null)
    if [[ -z "$cache_dir" ]] || ! dir_has_content "$cache_dir"; then
        printf '%s\n' "$(t cleanup_nothing)"
        return 0
    fi
    local size
    size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
    echo "$cache_dir: $size"
    cleanup_confirm_and_run 'npm cache clean --force'
}

do_cleanup_pip_cache() {
    echo "== $(t cleanup_pip_cache) =="
    local cache_dir
    cache_dir=$("$PIP_BIN" cache dir 2>/dev/null)
    if [[ -z "$cache_dir" ]] || ! dir_has_content "$cache_dir"; then
        printf '%s\n' "$(t cleanup_nothing)"
        return 0
    fi
    "$PIP_BIN" cache info 2>/dev/null
    cleanup_confirm_and_run '"$PIP_BIN" cache purge'
}

do_cleanup_cargo_cache() {
    echo "== $(t cleanup_cargo_cache) =="
    local cache_dir="$HOME/.cargo/registry"
    if ! dir_has_content "$cache_dir"; then
        printf '%s\n' "$(t cleanup_nothing)"
        return 0
    fi
    local size
    size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
    echo "$cache_dir: $size"
    cleanup_confirm_and_run 'rm -rf "$HOME/.cargo/registry/cache" "$HOME/.cargo/registry/src"'
}

do_cleanup_go_cache() {
    echo "== $(t cleanup_go_cache) =="
    local cache_dir
    cache_dir=$(go env GOCACHE 2>/dev/null)
    if [[ -z "$cache_dir" ]] || ! dir_has_content "$cache_dir"; then
        printf '%s\n' "$(t cleanup_nothing)"
        return 0
    fi
    local size
    size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
    echo "$cache_dir: $size"
    cleanup_confirm_and_run 'go clean -cache'
}

# Навигация:
#   - Esc в списке пакетов (любой из 5 источников)  -> назад к "Select a package source"
#     (для запуска с флагом типа --installed возврата нет, там сразу выход)
#   - Esc в меню действий (Install/Update/...)       -> назад к списку пакетов, с которого пришли
#   - Esc в меню cleanup                             -> назад к "Select a package source"
#     (для запуска с флагом --cleanup возврата нет, там сразу выход, как у остальных)
#
HELPER_SCRIPT=$(mktemp /tmp/pkgpick_helper.XXXXXX)
cp "$SELF" "$HELPER_SCRIPT"
chmod +x "$HELPER_SCRIPT"

# Из-за `set -euo pipefail` пайплайны с fzf нужно завершать через `|| true`,
# иначе pipefail отдаёт код выхода fzf (130 при Esc) и errexit убивает скрипт.

while true; do  # внешний цикл: выбор источника
    if [[ -z "$FLAG_MODE" ]]; then
        SOURCE_LINES=""
        if [[ -n "$AUR_HELPER" ]]; then
            SOURCE_LINES+="aur"$'\t'"$(t lbl_aur)"$'\n'
        fi
        SOURCE_LINES+="official"$'\t'"$(t lbl_official)"$'\n'
        if [[ -n "$AUR_HELPER" ]]; then
            SOURCE_LINES+="all"$'\t'"$(t lbl_all)"$'\n'
        fi
        if [[ -n "$HAS_FLATPAK" ]]; then
            SOURCE_LINES+="flatpak"$'\t'"$(t lbl_flatpak)"$'\n'
        fi
        SOURCE_LINES+="__separator__"$'\t'""$'\n'
        SOURCE_LINES+="installed"$'\t'"$(t lbl_installed)$SYS_SUFFIX"$'\n'
        if [[ -n "$AUR_HELPER" ]]; then
            SOURCE_LINES+="aur-installed"$'\t'"$(t lbl_aur_installed)"$'\n'
        fi
        if [[ -n "$HAS_FLATPAK" ]]; then
            SOURCE_LINES+="flatpak-installed"$'\t'"$(t lbl_flatpak_installed)"$'\n'
        fi
        if [[ -n "$SHOW_FULL" ]]; then
            if [[ -n "$HAS_NPM" ]]; then
                SOURCE_LINES+="npm-global"$'\t'"$(t lbl_npm_global)"$'\n'
            fi
            if [[ -n "$HAS_PIP" ]]; then
                SOURCE_LINES+="pip-global"$'\t'"$(t lbl_pip_global)"$'\n'
            fi
            if [[ -n "$HAS_CARGO" ]]; then
                SOURCE_LINES+="cargo-installed"$'\t'"$(t lbl_cargo_installed)"$'\n'
            fi
            if [[ -n "$HAS_GO" ]]; then
                SOURCE_LINES+="go-installed"$'\t'"$(t lbl_go_installed)"$'\n'
            fi
            if [[ -n "$HAS_PIPX" ]]; then
                SOURCE_LINES+="pipx-installed"$'\t'"$(t lbl_pipx_installed)"$'\n'
            fi
        fi
        SOURCE_LINES+="all-installed"$'\t'"$(t lbl_all_installed)"$'\n'
        SOURCE_LINES+="__separator__"$'\t'""$'\n'
        SOURCE_LINES+="cleanup"$'\t'"$(t lbl_cleanup)"$'\n'
        SOURCE_LINES+="settings"$'\t'"$(t lbl_settings)"$'\n'
        MODE=$(printf '%s' "$SOURCE_LINES" | \
            fzf --exact --height 100% --border --layout=reverse --no-input \
                --bind "$NOSEARCH_NAV_BIND" \
                --delimiter=$'\t' --with-nth=2 \
                --prompt="$(t source_prompt)" \
                --header="$(t select_source)" | \
            cut -f1) || true
        [[ "$MODE" == "__separator__" ]] && continue
        [[ -z "$MODE" ]] && exit 0
    else
        MODE="$FLAG_MODE"
    fi

    if [[ "$MODE" == "cleanup" ]]; then
        while true; do  # cleanup-меню: после каждого действия возвращается сюда же
            clear
            CLEANUP_ACTION_LINES=""
            CLEANUP_ACTION_LINES+="pacman_cache"$'\t'"$(t cleanup_pacman_cache)"$'\n'
            CLEANUP_ACTION_LINES+="orphans"$'\t'"$(t cleanup_orphans)"$'\n'
            if [[ -n "$AUR_HELPER" ]]; then
                CLEANUP_ACTION_LINES+="aur_cache"$'\t'"$(t cleanup_aur_cache)"$'\n'
            fi
            if [[ -n "$HAS_FLATPAK" ]]; then
                CLEANUP_ACTION_LINES+="flatpak_unused"$'\t'"$(t cleanup_flatpak_unused)"$'\n'
            fi
            if [[ -n "$HAS_NPM" ]]; then
                CLEANUP_ACTION_LINES+="npm_cache"$'\t'"$(t cleanup_npm_cache)"$'\n'
            fi
            if [[ -n "$HAS_PIP" ]]; then
                CLEANUP_ACTION_LINES+="pip_cache"$'\t'"$(t cleanup_pip_cache)"$'\n'
            fi
            if [[ -n "$HAS_CARGO" ]]; then
                CLEANUP_ACTION_LINES+="cargo_cache"$'\t'"$(t cleanup_cargo_cache)"$'\n'
            fi
            if [[ -n "$HAS_GO" ]]; then
                CLEANUP_ACTION_LINES+="go_cache"$'\t'"$(t cleanup_go_cache)"$'\n'
            fi

            CLEANUP_ACTION=$(printf '%s' "$CLEANUP_ACTION_LINES" | \
                fzf --exact --height 100% --border --layout=reverse --no-input \
                    --bind "$NOSEARCH_NAV_BIND" \
                    --delimiter=$'\t' --with-nth=2 \
                    --prompt="$(t action_prompt)" \
                    --header="$(t cleanup_header)" | \
                cut -f1) || true

            if [[ -z "$CLEANUP_ACTION" ]]; then
                # Esc в меню cleanup
                if [[ -n "$FLAG_MODE" ]]; then
                    exit 0
                else
                    continue 2  # назад к выбору источника
                fi
            fi

            clear
            cleanup_rc=0
            case "$CLEANUP_ACTION" in
                pacman_cache)    do_cleanup_pacman_cache    || cleanup_rc=$? ;;
                orphans)         do_cleanup_orphans         || cleanup_rc=$? ;;
                aur_cache)       do_cleanup_aur_cache       || cleanup_rc=$? ;;
                flatpak_unused)  do_cleanup_flatpak_unused  || cleanup_rc=$? ;;
                npm_cache)       do_cleanup_npm_cache       || cleanup_rc=$? ;;
                pip_cache)       do_cleanup_pip_cache       || cleanup_rc=$? ;;
                cargo_cache)     do_cleanup_cargo_cache     || cleanup_rc=$? ;;
                go_cache)        do_cleanup_go_cache        || cleanup_rc=$? ;;
            esac
            if [[ "$cleanup_rc" -eq 0 ]]; then
                echo
                press_enter_or_esc
            fi
        done
    fi

    if [[ "$MODE" == "settings" ]]; then
        while true; do  # settings-меню: после каждого изменения возвращается сюда же
            clear
            SETTINGS_LINES=""
            full_state="$(t settings_off)"
            [[ "$SHOW_FULL" == "1" ]] && full_state="$(t settings_on)"
            SETTINGS_LINES+="language"$'\t'"$(t settings_language): $(lang_display_name "$LANG_CHOICE")"$'\n'
            SETTINGS_LINES+="toggle_full"$'\t'"$(t settings_full_sources): $full_state"$'\n'

            SETTINGS_ACTION=$(printf '%s' "$SETTINGS_LINES" | \
                fzf --exact --height 100% --border --layout=reverse --no-input \
                    --bind "$NOSEARCH_NAV_BIND" \
                    --delimiter=$'\t' --with-nth=2 \
                    --prompt="$(t action_prompt)" \
                    --header="$(t settings_header)" | \
                cut -f1) || true

            if [[ -z "$SETTINGS_ACTION" ]]; then
                # Esc в меню settings
                if [[ -n "$FLAG_MODE" ]]; then
                    exit 0
                else
                    continue 2  # назад к выбору источника
                fi
            fi

            case "$SETTINGS_ACTION" in
                language)     settings_pick_language ;;
                toggle_full)  toggle_full_sources ;;
            esac
        done
    fi

    while true; do  # внутренний цикл: список пакетов <-> меню действий
        [[ -n "$META_FILE" && -f "$META_FILE" ]] && rm -f "$META_FILE"
        [[ -n "$STATE_FILE" && -f "$STATE_FILE" ]] && rm -f "$STATE_FILE"
        META_FILE=""
        STATE_FILE=""

        clear

        case "$MODE" in
            aur)
                SELECTED=$("$AUR_HELPER" -Sl aur | awk '{print $2}' | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview "$AUR_HELPER -Si {}") || true
                ;;
            official)
                SELECTED=$(pacman -Sl | awk '{print $1, $2}' | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview "pacman -Si \$(echo {} | cut -d' ' -f2)" | \
                    awk '{print $2}') || true
                ;;
            all)
                SELECTED=$("$AUR_HELPER" -Sl | awk '{print $1, $2}' | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview "$AUR_HELPER -Si \$(echo {} | cut -d' ' -f2)" | \
                    awk '{print $2}') || true
                ;;
            flatpak)
                # application id идёт первым полем, name (может содержать пробелы) - вторым
                # Превью берётся из офлайн-метаданных (id/name/size/description), а не
                # через живой `flatpak search`, чтобы описание показывалось нормально и быстро.
                META_FILE=$(build_meta_flatpak_available)
                SELECTED=$(sort -t $'\t' -k2,2f "$META_FILE" | awk -F'\t' '{print $1, $2}' | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview "$HELPER_SCRIPT __fp_info \$(echo {} | cut -d' ' -f1) \"$META_FILE\"" | \
                    awk '{print $1}') || true
                ;;
            flatpak-installed)
                # Список включает и приложения, и runtime'ы (без --app), т.к. раньше
                # runtime'ы (например Nvidia VAAPI driver) не попадали в список установленных.
                META_FILE=$(build_meta_flatpak_installed)
                STATE_FILE=$(mktemp)
                echo "name:asc" > "$STATE_FILE"

                SELECTED=$(sort -t $'\t' -k2,2f "$META_FILE" | awk -F'\t' '{print $1, $2}' | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview "$HELPER_SCRIPT __fp_info \$(echo {} | cut -d' ' -f1) \"$META_FILE\"" \
                        --header "$("$HELPER_SCRIPT" __header_fp "$STATE_FILE")" \
                        --bind "ctrl-n:reload-sync($HELPER_SCRIPT __sort_fp name \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header_fp \"$STATE_FILE\")" \
                        --bind "ctrl-s:reload-sync($HELPER_SCRIPT __sort_fp size \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header_fp \"$STATE_FILE\")" \
                        --bind "ctrl-e:reload-sync($HELPER_SCRIPT __sort_fp explicit \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header_fp \"$STATE_FILE\")" \
                        --bind "ctrl-d:reload-sync($HELPER_SCRIPT __sort_fp dependency \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header_fp \"$STATE_FILE\")" | \
                    awk '{print $1}') || true
                ;;
            npm-global)
                SELECTED=$({ npm ls -g --depth=0 --parseable 2>/dev/null || true; } | \
                    awk 'NR > 1 {
                        name = $0
                        sub(/^.*\/node_modules\//, "", name)
                        if (name != "") print name
                    }' | \
                    sort | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview "npm view {} 2>/dev/null") || true
                ;;
            installed|aur-installed)
                if [[ "$MODE" == "aur-installed" ]]; then
                    META_FILE=$(build_meta "yes")
                else
                    META_FILE=$(build_meta "no")
                fi
                STATE_FILE=$(mktemp)
                echo "name:asc" > "$STATE_FILE"

                SELECTED=$(sort -t $'\t' -k1,1 "$META_FILE" | cut -f1 | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview 'pacman -Qi {}' \
                        --header "$("$HELPER_SCRIPT" __header "$STATE_FILE")" \
                        --bind "ctrl-n:reload-sync($HELPER_SCRIPT __sort name \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header \"$STATE_FILE\")" \
                        --bind "ctrl-s:reload-sync($HELPER_SCRIPT __sort size \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header \"$STATE_FILE\")" \
                        --bind "ctrl-t:reload-sync($HELPER_SCRIPT __sort date \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header \"$STATE_FILE\")" \
                        --bind "ctrl-e:reload-sync($HELPER_SCRIPT __sort explicit \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header \"$STATE_FILE\")" \
                        --bind "ctrl-d:reload-sync($HELPER_SCRIPT __sort dependency \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header \"$STATE_FILE\")") || true
                ;;
            pip-global)
                SELECTED=$("$PIP_BIN" list --format=freeze 2>/dev/null | \
                    awk -F'==' '{print $1, $2}' | \
                    sort | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview "$PIP_BIN show \$(echo {} | cut -d' ' -f1) 2>/dev/null" | \
                    awk '{print $1}') || true
                ;;
            cargo-installed)
                SELECTED=$(cargo install --list 2>/dev/null | \
                    awk '/^[^ \t]/ && /:$/ { sub(/:$/,""); split($0,a," "); print a[1], a[2] }' | \
                    sort | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview "$HELPER_SCRIPT __cargo_info \$(echo {} | cut -d' ' -f1)" | \
                    awk '{print $1}') || true
                ;;
            go-installed)
                SELECTED=$(find "$GO_BIN_DIR" -maxdepth 1 -type f -perm -u+x -exec basename {} \; 2>/dev/null | \
                    sort | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview "$HELPER_SCRIPT __go_info \"$GO_BIN_DIR\" {}") || true
                ;;
            pipx-installed)
                SELECTED=$(pipx list --short 2>/dev/null | \
                    awk '{print $1, $2}' | \
                    sort | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview "$HELPER_SCRIPT __pipx_info \$(echo {} | cut -d' ' -f1)" | \
                    awk '{print $1}') || true
                ;;
            all-installed)
                META_FILE=$(build_meta_all_installed)

                SELECTED=$(sort -t $'\t' -k2,2f "$META_FILE" | \
                    awk -F'\t' '{printf "%s\t%s [%s]\n", $1, $2, $3}' | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --delimiter=$'\t' --with-nth=2 \
                        --preview "$HELPER_SCRIPT __all_info \$(printf '%s' {} | cut -f1)" | \
                    cut -f1) || true
                ;;
            *)
                echo "$(t invalid_mode) $MODE" >&2
                exit 1
                ;;
        esac

        if [[ -z "${SELECTED// }" ]]; then
            # Esc в списке пакетов
            if [[ -n "$FLAG_MODE" ]]; then
                printf '%s\n' "$(t nothing_selected)"
                exit 0
            else
                continue 2  # назад к выбору источника
            fi
        fi

        SELECTED_COUNT=$(echo "$SELECTED" | grep -c .)

        SELECTED_DISPLAY="$SELECTED"
        if [[ "$MODE" == "all-installed" ]]; then
            SELECTED_DISPLAY=""
            while IFS= read -r token; do
                [[ -z "$token" ]] && continue
                SELECTED_DISPLAY+="${token#*:} (${token%%:*})"$'\n'
            done <<< "$SELECTED"
        fi

        clear
        echo "$(t selected_label) ($SELECTED_COUNT):"
        while IFS= read -r display_line; do
            printf '  - %s\n' "$display_line"
        done <<< "$SELECTED_DISPLAY"
        echo

        ACTION_LINES=""
        if [[ "$MODE" == "installed" || "$MODE" == "aur-installed" || "$MODE" == "flatpak-installed" || "$MODE" == "npm-global" || "$MODE" == "pip-global" || "$MODE" == "cargo-installed" || "$MODE" == "go-installed" || "$MODE" == "pipx-installed" || "$MODE" == "all-installed" ]]; then
            ACTION_LINES+="update"$'\t'"$(t act_update)"$'\n'
            ACTION_LINES+="remove"$'\t'"$(t act_remove)"$'\n'
            ACTION_LINES+="info"$'\t'"$(t act_info)"$'\n'
            # all-installed объединяет разные менеджеры пакетов в одном списке,
            # поэтому единой кнопки "обновить всё" для него не делаем —
            # непонятно, что за "всё" в разнородном списке. У остальных
            # источников кнопка одна, действует строго в рамках источника.
            if [[ "$MODE" != "all-installed" ]]; then
                UPDATE_ALL_LABEL_KEY="act_update_all"
                UPDATE_ALL_LABEL_SUFFIX=""
                case "$MODE" in
                    installed)
                        UPDATE_ALL_LABEL_KEY="act_update_all_pacman"
                        UPDATE_ALL_LABEL_SUFFIX="$SYS_SUFFIX"
                        ;;
                    aur-installed)      UPDATE_ALL_LABEL_KEY="act_update_all_aur" ;;
                    flatpak-installed)  UPDATE_ALL_LABEL_KEY="act_update_all_flatpak" ;;
                    npm-global)         UPDATE_ALL_LABEL_KEY="act_update_all_npm" ;;
                    pip-global)         UPDATE_ALL_LABEL_KEY="act_update_all_pip" ;;
                    cargo-installed)    UPDATE_ALL_LABEL_KEY="act_update_all_cargo" ;;
                    go-installed)       UPDATE_ALL_LABEL_KEY="act_update_all_go" ;;
                    pipx-installed)     UPDATE_ALL_LABEL_KEY="act_update_all_pipx" ;;
                esac
                ACTION_LINES+="__separator__"$'\t'""$'\n'
                ACTION_LINES+="update_all"$'\t'"$(t "$UPDATE_ALL_LABEL_KEY")$UPDATE_ALL_LABEL_SUFFIX"$'\n'
            fi
        else
            ACTION_LINES+="install"$'\t'"$(t act_install)"$'\n'
            ACTION_LINES+="info"$'\t'"$(t act_info)"$'\n'
        fi

        while true; do
            ACTION=$(printf '%s' "$ACTION_LINES" | \
                fzf --exact --height 100% --border --layout=reverse --no-input \
                    --bind "$NOSEARCH_NAV_BIND" \
                    --delimiter=$'\t' --with-nth=2 \
                    --prompt="$(t action_prompt)" \
                    --header="$(t action_header)" | \
                cut -f1) || true
            [[ "$ACTION" == "__separator__" ]] || break
        done

        if [[ -z "$ACTION" ]]; then
            # Esc в меню действий -> назад к списку пакетов (тот же источник)
            continue
        fi

        case "$ACTION" in
            install)
                if [[ "$MODE" == "flatpak" ]]; then
                    echo "$SELECTED" | xargs -o -r flatpak install -y
                elif [[ -n "$AUR_HELPER" ]]; then
                    echo "$SELECTED" | xargs -o -r "$AUR_HELPER" -S --needed
                else
                    echo "$SELECTED" | xargs -o -r sudo pacman -S --needed
                fi
                ;;
            update)
                if [[ "$MODE" == "all-installed" ]]; then
                    if [[ -z "$AUR_HELPER" ]] && grep -q '^aur:' <<< "$SELECTED"; then
                        printf '%s\n' "$(t aur_helper_missing)" >&2
                        exit 1
                    fi
                    while IFS= read -r token; do
                        [[ -z "$token" ]] && continue
                        src="${token%%:*}"; id="${token#*:}"
                        case "$src" in
                            aur)
                                "$AUR_HELPER" -S "$id"
                                ;;
                            pacman)
                                if [[ -n "$AUR_HELPER" ]]; then "$AUR_HELPER" -S "$id"; else sudo pacman -S "$id"; fi
                                ;;
                            flatpak) flatpak update -y "$id" ;;
                            npm) npm update -g "$id" ;;
                            pip) "$PIP_BIN" install -U "$id" ;;
                            cargo) cargo install --force "$id" ;;
                            go)
                                modpath=$("$SELF" __go_modpath "$GO_BIN_DIR" "$id")
                                [[ -n "$modpath" ]] && go install "${modpath}@latest"
                                ;;
                            pipx) pipx upgrade "$id" ;;
                        esac
                    done <<< "$SELECTED"
                elif [[ "$MODE" == "flatpak-installed" ]]; then
                    echo "$SELECTED" | xargs -o -r flatpak update -y
                elif [[ "$MODE" == "npm-global" ]]; then
                    echo "$SELECTED" | xargs -o -r npm update -g
                elif [[ "$MODE" == "pip-global" ]]; then
                    echo "$SELECTED" | xargs -o -r "$PIP_BIN" install -U
                elif [[ "$MODE" == "cargo-installed" ]]; then
                    echo "$SELECTED" | xargs -o -r -n1 cargo install --force
                elif [[ "$MODE" == "go-installed" ]]; then
                    echo "$SELECTED" | while IFS= read -r bin; do
                        [[ -z "$bin" ]] && continue
                        modpath=$("$SELF" __go_modpath "$GO_BIN_DIR" "$bin")
                        [[ -n "$modpath" ]] && go install "${modpath}@latest"
                    done
                elif [[ "$MODE" == "pipx-installed" ]]; then
                    echo "$SELECTED" | xargs -o -r -n1 pipx upgrade
                elif [[ -n "$AUR_HELPER" ]]; then
                    echo "$SELECTED" | xargs -o -r "$AUR_HELPER" -S
                else
                    echo "$SELECTED" | xargs -o -r sudo pacman -S
                fi
                ;;
            update_all)
                # Полное обновление: игнорирует выделение, обновляет всё из этого источника
                case "$MODE" in
                    flatpak-installed)
                        flatpak update -y
                        ;;
                    npm-global)
                        npm update -g
                        ;;
                    pip-global)
                        "$PIP_BIN" list --outdated --format=columns 2>/dev/null | \
                            awk 'NR > 2 { print $1 }' | \
                            xargs -r -n1 "$PIP_BIN" install -U
                        ;;
                    cargo-installed)
                        cargo install --list 2>/dev/null | \
                            awk '/^[^ \t]/ && /:$/ { sub(/:$/,""); split($0,a," "); print a[1] }' | \
                            xargs -r -n1 cargo install --force
                        ;;
                    go-installed)
                        find "$GO_BIN_DIR" -maxdepth 1 -type f -perm -u+x -exec basename {} \; 2>/dev/null | \
                            while IFS= read -r bin; do
                                modpath=$("$SELF" __go_modpath "$GO_BIN_DIR" "$bin")
                                [[ -n "$modpath" ]] && go install "${modpath}@latest"
                            done
                        ;;
                    aur-installed)
                        "$AUR_HELPER" -Syu
                        ;;
                    pipx-installed)
                        pipx upgrade-all
                        ;;
                    installed)
                        if [[ -n "$AUR_HELPER" ]]; then
                            "$AUR_HELPER" -Syu
                        else
                            sudo pacman -Syu
                        fi
                        ;;
                    *)
                        sudo pacman -Syu
                        ;;
                esac
                ;;
            remove)
                read -r -p "$(t remove_confirm) $SELECTED_COUNT $(t remove_confirm_suffix) " confirm
                case "$confirm" in
                    ""|y|Y|yes|Yes|д|Д|да|Да)
                        if [[ "$MODE" == "all-installed" ]]; then
                            while IFS= read -r token; do
                                [[ -z "$token" ]] && continue
                                src="${token%%:*}"; id="${token#*:}"
                                case "$src" in
                                    pacman|aur)
                                        if [[ -n "$AUR_HELPER" ]]; then "$AUR_HELPER" -Rns "$id"; else sudo pacman -Rns "$id"; fi
                                        ;;
                                    flatpak) flatpak uninstall -y "$id" ;;
                                    npm) npm uninstall -g "$id" ;;
                                    pip) "$PIP_BIN" uninstall -y "$id" ;;
                                    cargo) cargo uninstall "$id" ;;
                                    go) rm -f "$GO_BIN_DIR/$id" ;;
                                    pipx) pipx uninstall "$id" ;;
                                esac
                            done <<< "$SELECTED"
                        elif [[ "$MODE" == "flatpak-installed" ]]; then
                            echo "$SELECTED" | xargs -o -r flatpak uninstall -y
                        elif [[ "$MODE" == "npm-global" ]]; then
                            echo "$SELECTED" | xargs -o -r npm uninstall -g
                        elif [[ "$MODE" == "pip-global" ]]; then
                            echo "$SELECTED" | xargs -o -r "$PIP_BIN" uninstall -y
                        elif [[ "$MODE" == "cargo-installed" ]]; then
                            echo "$SELECTED" | xargs -o -r cargo uninstall
                        elif [[ "$MODE" == "go-installed" ]]; then
                            echo "$SELECTED" | while IFS= read -r bin; do
                                [[ -z "$bin" ]] && continue
                                rm -f "$GO_BIN_DIR/$bin"
                            done
                        elif [[ "$MODE" == "pipx-installed" ]]; then
                            echo "$SELECTED" | xargs -o -r -n1 pipx uninstall
                        elif [[ -n "$AUR_HELPER" ]]; then
                            echo "$SELECTED" | xargs -o -r "$AUR_HELPER" -Rns
                        else
                            echo "$SELECTED" | xargs -o -r sudo pacman -Rns
                        fi
                        ;;
                    *)
                        printf '%s\n' "$(t cancelled)"
                        ;;
                esac
                ;;
            info)
                while IFS= read -r entry; do
                    [[ -z "$entry" ]] && continue
                    if [[ "$MODE" == "all-installed" ]]; then
                        src="${entry%%:*}"; id="${entry#*:}"
                        echo "=== $id ($src) ==="
                        case "$src" in
                            pacman|aur) pacman -Qi "$id" 2>/dev/null ;;
                            flatpak)    flatpak info "$id" 2>/dev/null ;;
                            npm)        npm view "$id" 2>/dev/null ;;
                            pip)        "$PIP_BIN" show "$id" 2>/dev/null ;;
                            cargo)      "$SELF" __cargo_info "$id" ;;
                            go)         "$SELF" __go_info "$GO_BIN_DIR" "$id" ;;
                            pipx)       "$SELF" __pipx_info "$id" ;;
                        esac
                    else
                        pkg="$entry"
                        echo "=== $pkg ==="
                        if [[ "$MODE" == "flatpak" || "$MODE" == "flatpak-installed" ]]; then
                            if [[ -n "$META_FILE" && -f "$META_FILE" ]]; then
                                "$SELF" __fp_info "$pkg" "$META_FILE"
                            else
                                flatpak info "$pkg" 2>/dev/null
                            fi
                        elif [[ "$MODE" == "npm-global" ]]; then
                            npm view "$pkg" 2>/dev/null
                        elif [[ "$MODE" == "pip-global" ]]; then
                            "$PIP_BIN" show "$pkg" 2>/dev/null
                        elif [[ "$MODE" == "cargo-installed" ]]; then
                            "$SELF" __cargo_info "$pkg"
                        elif [[ "$MODE" == "go-installed" ]]; then
                            "$SELF" __go_info "$GO_BIN_DIR" "$pkg"
                        elif [[ "$MODE" == "pipx-installed" ]]; then
                            "$SELF" __pipx_info "$pkg"
                        elif [[ -n "$AUR_HELPER" ]]; then
                            "$AUR_HELPER" -Si "$pkg" 2>/dev/null || "$AUR_HELPER" -Qi "$pkg" 2>/dev/null
                        else
                            pacman -Si "$pkg" 2>/dev/null || pacman -Qi "$pkg" 2>/dev/null
                        fi
                    fi
                    echo
                done <<< "$SELECTED"
                press_enter_or_esc
                continue
                ;;
            *)
                echo "$(t invalid_action) $ACTION" >&2
                exit 1
                ;;
        esac

        exit 0
    done
done
