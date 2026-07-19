#!/usr/bin/env bash
set -euo pipefail

SELF="$(readlink -f "$0")"

command -v fzf >/dev/null 2>&1 || { echo "fzf not found in PATH" >&2; exit 1; }

CONFIG_DIR="$HOME/.config/pkgpick"
CONFIG_FILE="$CONFIG_DIR/lang"

declare -A EN=(
    [select_source]="Select a package source"
    [source_prompt]="Source> "
    [lbl_aur]="AUR (available)"
    [lbl_official]="Official repos (available)"
    [lbl_all]="All repositories (available)"
    [lbl_installed]="Installed packages"
    [lbl_aur_installed]="Installed AUR packages"
    [sort_prefix]="Sort:"
    [sort_name]="Name"
    [sort_size]="Size"
    [sort_date]="Date"
    [sort_explicit]="Explicit only"
    [sort_dependency]="Dependencies only"
    [key_hint]="Ctrl-N name  Ctrl-S size  Ctrl-T date  Ctrl-E explicit  Ctrl-D dependency"
    [unknown_option]="Unknown option:"
    [invalid_lang]="Invalid --lang value (use: en or ru):"
    [aur_helper_missing]="No AUR helper (yay or paru) found in PATH; this mode needs one."
    [invalid_mode]="Invalid mode:"
    [nothing_selected]="Nothing selected."
    [selected_label]="Selected"
    [action_header]="What to do with the selected packages?"
    [action_prompt]="Action> "
    [act_install]="Install"
    [act_update]="Update"
    [act_remove]="Remove"
    [act_info]="Info"
    [remove_confirm]="Remove"
    [remove_confirm_suffix]="package(s)? [y/N]"
    [cancelled]="Cancelled."
    [invalid_action]="Invalid action:"
)

declare -A RU=(
    [select_source]="Выбери источник пакетов"
    [source_prompt]="Источник> "
    [lbl_aur]="AUR (доступные)"
    [lbl_official]="Официальные репозитории (доступные)"
    [lbl_all]="Все репозитории (доступные)"
    [lbl_installed]="Установленные пакеты"
    [lbl_aur_installed]="Установленные AUR-пакеты"
    [sort_prefix]="Сортировка:"
    [sort_name]="Имя"
    [sort_size]="Размер"
    [sort_date]="Дата"
    [sort_explicit]="Только explicit"
    [sort_dependency]="Только dependency"
    [key_hint]="Ctrl-N имя  Ctrl-S размер  Ctrl-T дата  Ctrl-E explicit  Ctrl-D dependency"
    [unknown_option]="Неизвестный флаг:"
    [invalid_lang]="Некорректное значение --lang (используй: en или ru):"
    [aur_helper_missing]="Не найден AUR-хелпер (yay или paru) в PATH; этот режим требует один из них."
    [invalid_mode]="Некорректный режим:"
    [nothing_selected]="Ничего не выбрано."
    [selected_label]="Выбрано"
    [action_header]="Что сделать с выбранными пакетами?"
    [action_prompt]="Действие> "
    [act_install]="Установить"
    [act_update]="Обновить"
    [act_remove]="Удалить"
    [act_info]="Инфо"
    [remove_confirm]="Удалить"
    [remove_confirm_suffix]="пакет(ов)? [y/N]"
    [cancelled]="Отменено."
    [invalid_action]="Некорректное действие:"
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
                sort -t $'\t' -k2,2 -nr "$meta_file" | cut -f1
            else
                sort -t $'\t' -k2,2 -n "$meta_file" | cut -f1
            fi
            ;;
        date)
            if [[ "$dir" == "desc" ]]; then
                sort -t $'\t' -k3,3 -nr "$meta_file" | cut -f1
            else
                sort -t $'\t' -k3,3 -n "$meta_file" | cut -f1
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

usage() {
    if [[ "$LANG_CHOICE" == "ru" ]]; then
cat <<'EOF'
Использование: pkgpick [ОПЦИЯ]

  --aur             AUR-пакеты (доступные)
  --official        Официальные пакеты (доступные)
  --all             Все репозитории (доступные)
  --installed       Установленные пакеты
  --aur-installed   Установленные AUR-пакеты
  --lang en|ru      Сменить язык интерфейса НАВСЕГДА (сохраняется в конфиг)
                    и продолжить с этим языком в текущем запуске
  -h, --help        Показать эту справку

Язык также можно сменить в любой момент, удалив файл:
  ~/.config/pkgpick/lang
— тогда при следующем запуске снова появится выбор языка.

Для installed / aur-installed сортировку можно менять прямо в списке:
  Ctrl-N  по имени      (переключение asc/desc)
  Ctrl-S  по размеру    (переключение asc/desc)
  Ctrl-T  по дате       (переключение asc/desc)
  Ctrl-E  только explicit
  Ctrl-D  только dependency

После выбора пакетов (Tab — мультивыбор) откроется меню действий:
  install / update / remove / info

Если в PATH нет ни yay, ни paru, доступны только --official и --installed
(режимы, требующие AUR, будут скрыты из меню и недоступны через флаги).
EOF
    else
cat <<'EOF'
Usage: pkgpick [OPTION]

  --aur             AUR packages (available)
  --official        Official repo packages (available)
  --all             All repositories (available)
  --installed       Installed packages
  --aur-installed   Installed AUR packages
  --lang en|ru      Change UI language PERMANENTLY (saved to config)
                    and continue this run in that language
  -h, --help        Show this help

You can also reset the language at any time by deleting:
  ~/.config/pkgpick/lang
— the language picker will show again on the next run.

For installed / aur-installed, sorting can be changed live inside the list:
  Ctrl-N  sort by name        (toggle asc/desc)
  Ctrl-S  sort by size        (toggle asc/desc)
  Ctrl-T  sort by date        (toggle asc/desc)
  Ctrl-E  filter explicit only
  Ctrl-D  filter dependencies only

After selecting packages (Tab for multi-select), an action menu appears:
  install / update / remove / info

If neither yay nor paru is found in PATH, only --official and --installed
are available (AUR-requiring modes are hidden from the menu and refused
via flags).
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

# ---- parse CLI arguments ----
MODE=""
LANG_FLAG=""
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
        --aur)            MODE="aur" ;;
        --official)       MODE="official" ;;
        --all)             MODE="all" ;;
        --installed)      MODE="installed" ;;
        --aur-installed)  MODE="aur-installed" ;;
        -h|--help)        HELP_REQUESTED=1 ;;
        *)
            echo "$(t unknown_option) $1" >&2
            usage
            exit 1
            ;;
    esac
    shift
done

# ---- finalize language: flag > saved config > interactive picker ----
if [[ -n "$LANG_FLAG" ]]; then
    LANG_CHOICE="$LANG_FLAG"
    mkdir -p "$CONFIG_DIR"
    echo "$LANG_CHOICE" > "$CONFIG_FILE"
elif [[ "$LANG_CHOICE" != "en" && "$LANG_CHOICE" != "ru" ]]; then
    LANG_CHOICE=$(printf "en\tEnglish\nru\tРусский\n" | \
        fzf --exact --height 30% --border --layout=reverse \
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
    echo "$(t aur_helper_missing)" >&2
    exit 1
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
            size = bytes
        }
        /^Install Date/ {
            line=$0; sub(/^Install Date[ \t]*: /,"",line)
            cmd = "date -d \x27" line "\x27 +%s 2>/dev/null"
            cmd | getline epoch
            close(cmd)
            date = epoch + 0
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

# Навигация:
#   - Esc в списке пакетов (любой из 5 источников)  -> назад к "Select a package source"
#     (для запуска с флагом типа --installed возврата нет, там сразу выход)
#   - Esc в меню действий (Install/Update/...)       -> назад к списку пакетов, с которого пришли
#
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
        SOURCE_LINES+="installed"$'\t'"$(t lbl_installed)"$'\n'
        if [[ -n "$AUR_HELPER" ]]; then
            SOURCE_LINES+="aur-installed"$'\t'"$(t lbl_aur_installed)"$'\n'
        fi
        MODE=$(printf '%s' "$SOURCE_LINES" | \
            fzf --exact --height 100% --border --layout=reverse \
                --delimiter=$'\t' --with-nth=2 \
                --prompt="$(t source_prompt)" \
                --header="$(t select_source)" | \
            cut -f1) || true
        [[ -z "$MODE" ]] && exit 0
    else
        MODE="$FLAG_MODE"
    fi

    while true; do  # внутренний цикл: список пакетов <-> меню действий
        [[ -n "$META_FILE" && -f "$META_FILE" ]] && rm -f "$META_FILE"
        [[ -n "$STATE_FILE" && -f "$STATE_FILE" ]] && rm -f "$STATE_FILE"
        [[ -n "$HELPER_SCRIPT" && -f "$HELPER_SCRIPT" ]] && rm -f "$HELPER_SCRIPT"
        META_FILE=""
        STATE_FILE=""
        HELPER_SCRIPT=""

        clear

        case "$MODE" in
            aur)
                SELECTED=$("$AUR_HELPER" -Sl aur | awk '{print $1, $2}' | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview "$AUR_HELPER -Si \$(echo {} | cut -d' ' -f2)" | \
                    awk '{print $2}') || true
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
            installed|aur-installed)
                if [[ "$MODE" == "aur-installed" ]]; then
                    META_FILE=$(build_meta "yes")
                else
                    META_FILE=$(build_meta "no")
                fi
                STATE_FILE=$(mktemp)
                echo "name:asc" > "$STATE_FILE"

                HELPER_SCRIPT=$(mktemp /tmp/pkgpick_helper.XXXXXX)
                cp "$SELF" "$HELPER_SCRIPT"
                chmod +x "$HELPER_SCRIPT"

                SELECTED=$(sort -t $'\t' -k1,1 "$META_FILE" | cut -f1 | \
                    fzf "${FZF_COMMON_OPTS[@]}" \
                        --preview 'pacman -Qi {}' \
                        --header "$("$HELPER_SCRIPT" __header "$STATE_FILE")" \
                        --bind "ctrl-n:reload($HELPER_SCRIPT __sort name \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header \"$STATE_FILE\")" \
                        --bind "ctrl-s:reload($HELPER_SCRIPT __sort size \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header \"$STATE_FILE\")" \
                        --bind "ctrl-t:reload($HELPER_SCRIPT __sort date \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header \"$STATE_FILE\")" \
                        --bind "ctrl-e:reload($HELPER_SCRIPT __sort explicit \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header \"$STATE_FILE\")" \
                        --bind "ctrl-d:reload($HELPER_SCRIPT __sort dependency \"$META_FILE\" \"$STATE_FILE\")+transform-header($HELPER_SCRIPT __header \"$STATE_FILE\")") || true
                ;;
            *)
                echo "$(t invalid_mode) $MODE" >&2
                exit 1
                ;;
        esac

        if [[ -z "${SELECTED// }" ]]; then
            # Esc в списке пакетов
            if [[ -n "$FLAG_MODE" ]]; then
                echo "$(t nothing_selected)"
                exit 0
            else
                continue 2  # назад к выбору источника
            fi
        fi

        SELECTED_COUNT=$(echo "$SELECTED" | grep -c .)

        clear
        echo "$(t selected_label) ($SELECTED_COUNT):"
        echo "$SELECTED" | sed 's/^/  - /'
        echo

        ACTION_LINES=""
        if [[ "$MODE" == "installed" || "$MODE" == "aur-installed" ]]; then
            ACTION_LINES+="update"$'\t'"$(t act_update)"$'\n'
            ACTION_LINES+="remove"$'\t'"$(t act_remove)"$'\n'
            ACTION_LINES+="info"$'\t'"$(t act_info)"$'\n'
        else
            ACTION_LINES+="install"$'\t'"$(t act_install)"$'\n'
            ACTION_LINES+="info"$'\t'"$(t act_info)"$'\n'
        fi

        ACTION=$(printf '%s' "$ACTION_LINES" | \
            fzf --exact --height 30% --border --layout=reverse \
                --delimiter=$'\t' --with-nth=2 \
                --prompt="$(t action_prompt)" \
                --header="$(t action_header)" | \
            cut -f1) || true

        if [[ -z "$ACTION" ]]; then
            # Esc в меню действий -> назад к списку пакетов (тот же источник)
            continue
        fi

        case "$ACTION" in
            install)
                if [[ -n "$AUR_HELPER" ]]; then
                    echo "$SELECTED" | xargs -o -r "$AUR_HELPER" -S --needed
                else
                    echo "$SELECTED" | xargs -o -r sudo pacman -S --needed
                fi
                ;;
            update)
                if [[ -n "$AUR_HELPER" ]]; then
                    echo "$SELECTED" | xargs -o -r "$AUR_HELPER" -S
                else
                    echo "$SELECTED" | xargs -o -r sudo pacman -S
                fi
                ;;
            remove)
                read -r -p "$(t remove_confirm) $SELECTED_COUNT $(t remove_confirm_suffix) " confirm
                case "$confirm" in
                    y|Y|yes|Yes|д|Д|да|Да)
                        if [[ -n "$AUR_HELPER" ]]; then
                            echo "$SELECTED" | xargs -o -r "$AUR_HELPER" -Rns
                        else
                            echo "$SELECTED" | xargs -o -r sudo pacman -Rns
                        fi
                        ;;
                    *)
                        echo "$(t cancelled)"
                        ;;
                esac
                ;;
            info)
                for pkg in $SELECTED; do
                    echo "=== $pkg ==="
                    if [[ -n "$AUR_HELPER" ]]; then
                        "$AUR_HELPER" -Si "$pkg" 2>/dev/null || "$AUR_HELPER" -Qi "$pkg" 2>/dev/null
                    else
                        pacman -Si "$pkg" 2>/dev/null || pacman -Qi "$pkg" 2>/dev/null
                    fi
                    echo
                done
                ;;
            *)
                echo "$(t invalid_action) $ACTION" >&2
                exit 1
                ;;
        esac

        exit 0
    done
done
