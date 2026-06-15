#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# file-opener.sh — навигационный browser для rofi (мульти-монитор)
#   Вид строки: <глиф>  имя        <серый путь>
#   Правую колонку выравнивает САМ rofi через tab-stops в theme.rasi
#   (позиция в % ширины окна → одинаково на любом мониторе).
# ─────────────────────────────────────────────────────────────────────────────

# ── НАСТРОЙКА: корни ─────────────────────────────────────────────────────────
SEARCH_ROOTS=(
    "$HOME/.config"
    "$HOME/Downloads"
    "$HOME/Изображения"
    "$HOME"
    # "$HOME/Projects"
    # "$HOME/go"
)

EXCLUDES=(
    ".git" "node_modules" ".cache" "__pycache__"
    ".venv" "venv" ".mypy_cache" ".pytest_cache"
    ".next" ".nuxt" "dist" "build" "target" "vendor"
    "go-build" ".local/share/Trash"
)

ROOTS_MARKER="__ROOTS__"

FD_EXCLUDE_ARGS=()
for pat in "${EXCLUDES[@]}"; do FD_EXCLUDE_ARGS+=( --exclude "$pat" ); done

# ── Вид строк ────────────────────────────────────────────────────────────────
DIM_COLOR="#9e9b93"   # fg-muted из colors.rasi (серый путь). Pango хочет hex без alpha.

# ──────────────────────────────────────────────────────────────────────────
# ЗАМЕТКА ПРО ИКОНКИ (на будущее, когда поставишь icon-theme типа Papirus):
#   Сейчас иконка = ГЛИФ в тексте строки (ICON_* ниже).
#   Чтобы перейти на НАСТОЯЩИЕ иконки темы:
#     1. config.rasi:  icon-theme: "Papirus-Dark";  show-icons: true;
#     2. emit_row: убрать "${glyph}  " из начала disp.
#     3. emit_row: в конец printf добавить поле icon:  ...\x1ficon\x1f%s
#          %s = "folder" для папок / "text-x-generic" (или mime) для файлов.
#     4. theme.rasi: вернуть element-icon в children элемента (см. коммент там).
#   До тех пор — глифы, без зависимостей.
# ──────────────────────────────────────────────────────────────────────────
# Глифы заданы прямыми UTF-8 байтами — раскрывается одинаково в любом bash.
# (codepoints: folder U+F07B, file U+F016, arrow-up U+F062)
ICON_FOLDER=$(printf '\xef\x81\xbb')   # nf-fa-folder  U+F07B
ICON_FILE=$(printf '\xef\x80\x96')     # nf-fa-file_o  U+F016
ICON_UP=$(printf '\xef\x81\xa2')       # nf-fa-arrow_up U+F062 (для "..")

# Короткий «хвост» пути:  ~/.config/hypr/…   /   ~/Projects/…
short_tail() {
    local p="${1/#$HOME/\~}"
    IFS='/' read -ra parts <<< "$p"
    if   [ "${#parts[@]}" -le 2 ]; then printf '%s' "$p"
    elif [ "${#parts[@]}" -eq 3 ]; then printf '%s/%s/…' "${parts[0]}" "${parts[1]}"
    else printf '%s/%s/%s/…' "${parts[0]}" "${parts[1]}" "${parts[2]}"; fi
}

pango_escape() {
    local s="$1"; s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"
    printf '%s' "$s"
}

# glyph, name(для фильтра), right(серый путь), info(в ROFI_INFO)
emit_row() {
    local glyph="$1" name="$2" right="$3" info="$4"
    local ename eright disp
    ename="$(pango_escape "$name")"
    if [ -n "$right" ]; then
        eright="$(pango_escape "$right")"
        disp="${glyph}  ${ename}\t<span foreground=\"${DIM_COLOR}\">${eright}</span>"
    else
        disp="${glyph}  ${ename}"
    fi
    printf '%s\x00display\x1f%b\x1finfo\x1f%s\x1fmarkup\x1ftrue\n' "$name" "$disp" "$info"
}

# ── Диспетчер открытия файла ─────────────────────────────────────────────────
open_file() {
    local FILE="$1"; [ -z "$FILE" ] && return
    local ext="${FILE##*.}"
    [ "$ext" = "${FILE##*/}" ] && ext=""
    ext="${ext,,}"
    case "$ext" in
        go|mod|sum|tmpl|gohtml) kitty --detach -e nvim "$FILE" ;;
        lua|luau|py|rs|js|jsx|ts|tsx|mjs|cjs|vue|svelte|astro|\
        c|h|cpp|cc|cxx|hpp|rb|php|java|kt|swift|zig|nim|ml) kitty --detach -e nvim "$FILE" ;;
        sh|bash|zsh|fish) kitty --detach -e nvim "$FILE" ;;
        html|htm|css|scss|sass|less|xml|svg) kitty --detach -e nvim "$FILE" ;;
        md|markdown|rst|txt|org|adoc) kitty --detach -e nvim "$FILE" ;;
        json|jsonc|json5|yaml|yml|toml|ini|conf|config|env|properties|\
        desktop|service|timer|target|mount|nix|qml|qss|rasi|lock) kitty --detach -e nvim "$FILE" ;;
        mk|cmake|ninja|dockerfile|containerfile) kitty --detach -e nvim "$FILE" ;;
        csv|tsv|log) kitty --detach -e nvim "$FILE" ;;
        pdf) evince "$FILE" </dev/null >/dev/null 2>&1 & disown ;;
        png|jpg|jpeg|webp|gif|bmp|ico|tiff|avif) viewnior "$FILE" </dev/null >/dev/null 2>&1 & disown ;;
        "") kitty --detach -e nvim "$FILE" ;;
        *) xdg-open "$FILE" </dev/null >/dev/null 2>&1 & disown ;;
    esac
}

# ── Списки ───────────────────────────────────────────────────────────────────
show_roots() {
    echo -en "\x00prompt\x1ffile\n"
    echo -en "\x00data\x1f${ROOTS_MARKER}\n"
    echo -en "\x00markup-rows\x1ftrue\n"
    for root in "${SEARCH_ROOTS[@]}"; do
        [ -d "$root" ] || continue
        emit_row "$ICON_FOLDER" "${root##*/}" "$(short_tail "$root")" "$root"
    done
}

show_dir() {
    local DIR="$1"
    echo -en "\x00prompt\x1f${DIR/#$HOME/~}\n"
    echo -en "\x00data\x1f${DIR}\n"
    echo -en "\x00markup-rows\x1ftrue\n"

    local PARENT_INFO IS_ROOT=0
    for root in "${SEARCH_ROOTS[@]}"; do
        [ "$DIR" = "$root" ] && { IS_ROOT=1; break; }
    done
    [ "$IS_ROOT" -eq 1 ] && PARENT_INFO="$ROOTS_MARKER" || PARENT_INFO="$(dirname "$DIR")"
    emit_row "$ICON_UP" ".." "" "$PARENT_INFO"

    while IFS= read -r d; do
        [ -z "$d" ] && continue; d="${d%/}"
        emit_row "$ICON_FOLDER" "${d##*/}" "$(short_tail "$d")" "$d"
    done < <(fd --type d --hidden --color=never --max-depth 1 \
              "${FD_EXCLUDE_ARGS[@]}" . "$DIR" 2>/dev/null | sort -f)

    while IFS= read -r f; do
        [ -z "$f" ] && continue; f="${f%/}"
        emit_row "$ICON_FILE" "${f##*/}" "$(short_tail "$f")" "$f"
    done < <(fd --type f --hidden --color=never --max-depth 1 \
              "${FD_EXCLUDE_ARGS[@]}" . "$DIR" 2>/dev/null | sort -f)
}

# ── Главная логика ───────────────────────────────────────────────────────────
TARGET="$ROFI_INFO"

if [ -z "$1" ] && [ -z "$TARGET" ]; then show_roots; exit 0; fi
if [ "$TARGET" = "$ROOTS_MARKER" ]; then show_roots; exit 0; fi
if [ -d "$TARGET" ]; then show_dir "$TARGET"; exit 0; fi
if [ -f "$TARGET" ]; then open_file "$TARGET"; exit 0; fi
show_roots
exit 0