# ============================================================
# Генератор: cmus/current.theme
#
# Вызывается из _theme_generate (theme.fish) после разбора
# активной темы. Пишет velora/cmus/current.theme.
# Файл не коммитится в git.
#
# Номера цветов фиксированы по v1:
#   14 — курсор активного окна
#   5  — заголовок альбома
#   6  — info
#   12 — директории
#   3  — курсор неактивного окна
#   1  — error
#   0  — separator
# accent берётся из метаданных (colorN -> N).
# ============================================================

function _gen_cmus
    set -l dir $VELORA_ROOT/cmus
    mkdir -p -- $dir
    or return 1

    set -l accent_key (_theme_meta accent)
    if test -z "$accent_key"
        set accent_key color4
    end

    set -l am (string match -r -- '^color(\d+)$' $accent_key)
    if test (count $am) -ne 2
        echo "Ошибка [cmus]: accent должен быть colorN, получено '$accent_key'" >&2
        return 1
    end
    set -l accent $am[2]

    set -l lines
    set -a lines '# current.theme — сгенерирован командой theme set, править руками нельзя.'
    set -a lines '# Источник: velora/themes/current/theme.conf'
    set -a lines ''
    set -a lines 'set color_win_bg=default'
    set -a lines 'set color_win_fg=default'
    set -a lines 'set color_win_attr=default'
    set -a lines ''
    set -a lines 'set color_cmdline_bg=default'
    set -a lines 'set color_cmdline_fg=default'
    set -a lines 'set color_cmdline_attr=default'
    set -a lines ''
    set -a lines 'set color_win_title_bg=default'
    set -a lines "set color_win_title_fg=$accent"
    set -a lines 'set color_win_title_attr=bold'
    set -a lines ''
    set -a lines 'set color_titleline_bg=default'
    set -a lines "set color_titleline_fg=$accent"
    set -a lines 'set color_titleline_attr=bold'
    set -a lines ''
    set -a lines 'set color_trackwin_album_bg=default'
    set -a lines 'set color_trackwin_album_fg=5'
    set -a lines 'set color_trackwin_album_attr=default'
    set -a lines ''
    set -a lines 'set color_statusline_bg=default'
    set -a lines "set color_statusline_fg=$accent"
    set -a lines 'set color_statusline_attr=default'
    set -a lines ''
    set -a lines 'set color_statusline_progress_bg=default'
    set -a lines "set color_statusline_progress_fg=$accent"
    set -a lines 'set color_statusline_progress_attr=default'
    set -a lines ''
    set -a lines "set color_win_cur=$accent"
    set -a lines 'set color_win_cur_attr=bold'
    set -a lines ''
    set -a lines 'set color_win_cur_sel_bg=default'
    set -a lines 'set color_win_cur_sel_fg=14'
    set -a lines 'set color_win_cur_sel_attr=bold'
    set -a lines ''
    set -a lines 'set color_win_sel_bg=default'
    set -a lines 'set color_win_sel_fg=14'
    set -a lines 'set color_win_sel_attr=bold'
    set -a lines ''
    set -a lines 'set color_win_inactive_cur_sel_bg=default'
    set -a lines 'set color_win_inactive_cur_sel_fg=3'
    set -a lines 'set color_win_inactive_cur_sel_attr=default'
    set -a lines ''
    set -a lines 'set color_win_inactive_sel_bg=default'
    set -a lines 'set color_win_inactive_sel_fg=3'
    set -a lines 'set color_win_inactive_sel_attr=default'
    set -a lines ''
    set -a lines 'set color_win_dir=12'
    set -a lines ''
    set -a lines 'set color_info=6'
    set -a lines 'set color_error=1'
    set -a lines 'set color_separator=0'

    _theme_write $dir/current.theme $lines
    or begin
        echo "Ошибка [cmus]: не удалось записать $dir/current.theme" >&2
        return 1
    end
    echo "  [cmus] $dir/current.theme"
end
