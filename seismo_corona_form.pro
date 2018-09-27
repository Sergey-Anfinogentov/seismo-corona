;+
; :Description:
;    prepares GUI form.
;
;
;
;
;
; :Author: Sergey Anfinogentov (anfinogentov@iszf.irk.ru)
;-
function seismo_corona_form
  base = WIDGET_BASE( xsize = 1000, ysize = 700, /row, mbar = bar, title = 'Seismo corona')
  menu_file = WIDGET_BUTTON(bar, VALUE='file', /MENU)
    button_open   = WIDGET_BUTTON(menu_file, VALUE='Open...', event_pro = 'seismo_corona_open')
    button_save   = WIDGET_BUTTON(menu_file, VALUE='Save...', event_pro = 'seismo_corona_save')
    button_close  = WIDGET_BUTTON(menu_file, VALUE='Close',   event_pro = 'seismo_corona_close')
    button_import = WIDGET_BUTTON(menu_file, VALUE='Import from FITS..', event_pro = 'seismo_corona_import_fits')
    
    
    
  
  left_panel  = WIDGET_BASE(base,/column)
  right_panel = WIDGET_BASE(base,/column)
  
  draw_sun = WIDGET_DRAW(left_panel, xsize = 800, ysize = 600)
  frame_selector = widget_slider(left_panel, event_pro = 'seismo_corona_plot_frame')
  
  button_add = widget_button(right_panel, xsize = 150, value = 'Add loop', event_pro = 'seismo_corona_add_loop')
  button_del = widget_button(right_panel, xsize = 150, value = 'Delete loop', event_pro = 'seismo_corona_delete_loop')
  
  list = WIDGET_LIST(right_panel, VALUE=['loop 1', 'loop 2'], YSIZE=3)
  
  return, base
end