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
compile_opt idl2
scal =2
  base = WIDGET_BASE( xsize = 1000*scal, ysize = 750*scal, /row, mbar = bar, title = 'Seismo corona')
  menu_file = WIDGET_BUTTON(bar, VALUE='file', /MENU)
    button_open   = WIDGET_BUTTON(menu_file, VALUE='Open...', event_pro = 'seismo_corona_open')
    button_save   = WIDGET_BUTTON(menu_file, VALUE='Save...', event_pro = 'seismo_corona_save')
    button_close  = WIDGET_BUTTON(menu_file, VALUE='Close',   event_pro = 'seismo_corona_close')
    button_import = WIDGET_BUTTON(menu_file, VALUE='Import from FITS..', event_pro = 'seismo_corona_import_fits')
    
    
    
  
  left_panel  = WIDGET_BASE(base,/column)
  right_panel = WIDGET_BASE(base,/column)
  
  status_text = WIDGET_text(left_panel, uname = 'status_text', value = 'No data loaded')
  
  tabs = widget_tab(left_panel, event_pro = 'seismo_corona_switch_view')
  image_view = widget_base(tabs,/column, title = 'Image View')
  td_view = widget_base(tabs,/column, title = 'Time-distance View')
  
  ;content of the image view tab
  draw_sun = WIDGET_DRAW(image_view, xsize = 800*scal, ysize = 600*scal, uname = 'draw_frame')
  frame_selector = widget_slider(image_view, uname = 'frame_selector', event_pro = 'seismo_corona_plot_frame',$
    title = 'Current Frame')
  
  ;content of Time-Distance view tab
  td_base = widget_base(td_view, /row)
  button_back = widget_button(td_base, value ='<', xsize = 25*scal, event_pro = 'seismo_corona_td_back')
  draw_td = WIDGET_DRAW(td_base, xsize = 750*scal, ysize = 400*scal, uname = 'draw_td')
  button_forward = widget_button(td_base, value ='>', xsize = 25*scal, event_pro = 'seismo_corona_td_forward')
  
  slit_selector = widget_slider(td_view, uname = 'slit_selector', event_pro = 'seismo_corona_plot_td',$
    title = 'Slit position')
  time_range_selector = widget_slider(td_view, uname = 'time_range_selector', event_pro = 'seismo_corona_plot_td',$
    title = 'Time range', minimum = 100*scal, maximum = 900*scal, value = 300*scal)
  time_range_selector = widget_slider(td_view, uname = 'slit_width_selector', event_pro = 'seismo_corona_plot_td',$
    title = 'Slit width', minimum = 1, maximum = 30, value = 1)  
    
  
  
  
  
  button_add = widget_button(right_panel, xsize = 150*scal, value = 'Add loop', event_pro = 'seismo_corona_add_loop')
  button_del = widget_button(right_panel, xsize = 150*scal, value = 'Delete loop', event_pro = 'seismo_corona_delete_loop')
  
  list = WIDGET_LIST(right_panel, YSIZE=8, uname = 'loop_list', event_pro = 'seismo_corona_select_loop')
  loop_data = WIDGET_table(right_panel, uname = 'loop_data', ysize =6, xsize = 1,$
     row_labels = ['Length'], column_width = [100]*scal, row_heights = 20*scal,SCR_XSIZE =150*scal,/RESIZEABLE_COLUMNS,$
     COLUMN_LABELS = ['Param', 'Value'])
     
  button_fit_oscillation= widget_button(right_panel, xsize = 150*scal, value = 'Fit oscillation',$
     event_pro = 'seismo_corona_fit_oscillation', sensitive = 0, uname = 'fit_osc')
  
  return, base
end