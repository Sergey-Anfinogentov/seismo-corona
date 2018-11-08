pro seismo_corona_add_loop, ev
  compile_opt idl2
  common seismo_corona
  if global['state'] eq 'no data' then retu
  seismo_corona_show_status, ev, 'Click points to select a loop. Right click finalises selection.'
  
  seismo_corona_plot_frame, ev
  index = (global['index'])[0]
  x_arcsec = hdr2x(index)
  y_arcsec = hdr2y(index)
  
  loop = time_distance_ellipse(global['data'], x_arcsec, y_arcsec, /current_plot)
  global['loops'].Add, loop
  loop_list = widget_info(ev.top, find_by_uname = 'loop_list')
  loop_count = global['loops'].count()
  widget_control, loop_list, set_value = 'loop '+ strcompress(indgen(loop_count),/remove_all)
  
  length = seismo_corona_loop_length(index, ev)
  
 
  
  seismo_corona_plot_frame, ev
  seismo_corona_plot_td, ev
  seismo_corona_show_status, ev, 'Ready'
end

pro seismo_corona_show_status, ev, text
compile_opt idl2
  status_text = widget_info(ev.top, find_by_uname = 'status_text')
  widget_control, status_text, set_value = text
end

pro seismo_corona_delete_loop, ev
compile_opt idl2
  print, 'Delete_loop'
end
pro seismo_corona_select_loop, ev
compile_opt idl2
common seismo_corona

  loop_list = widget_info(ev.top, find_by_uname = 'loop_list')
  loop_index = widget_info(loop_list, /LIST_SELECT)
  sz = size((global['loops'])[loop_index].data)
  
  slit_selector = widget_info(ev.top, find_by_uname = 'slit_selector')
  widget_control, slit_selector, SET_SLIDER_MAX = sz[2] - 1

  seismo_corona_plot_frame, ev
end
pro seismo_corona_open, evseismo_corona_show_status, ev, text
compile_opt idl2
common seismo_corona
  print, 'Open event fired'
  file_name = dialog_pickfile(title = 'Select save file with data')
  print, 'readind data from '+ file_name
  restore, file_name,/v
end

pro seismo_corona_import_fits, ev
compile_opt idl2
common seismo_corona
  dir_name = dialog_pickfile(title = 'Select directory with FITs files', /directory, path = '/home/sergey/data/kink_magnetic/limb2')
  message,'Reading data from '+dir_name +' ...', /info
  seismo_corona_show_status, ev, 'Reading data...'
  files = file_search(filepath('*.fits', root_dir = dir_name))
  read_sdo, files, index, data,/use_shared_lib, /uncomp_delete
  message,'Reading data complete', /info
  sz = size(data)
  global['index'] = temporary(index)
  global['data'] = temporary(data)
  global['state'] = 'data loaded'
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, SET_SLIDER_MAX = sz[3] - 1
  seismo_corona_plot_frame, ev
  seismo_corona_show_status, ev, 'Ready'
end

pro seismo_corona_plot_frame, ev
compile_opt idl2
common seismo_corona
  if global['state'] eq 'no data' then return
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, get_value = frame_num
  
  draw_frame = widget_info(ev.top, find_by_uname = 'draw_frame')
  WIDGET_CONTROL, draw_frame, GET_VALUE = win 
  wset,win
  
  index = (global['index'])[0]
  
  x_arcsec = hdr2x(index)
  y_arcsec = hdr2y(index) 
  
  implot, comprange((global['data'])[*,*,frame_num],/global), x_arcsec, y_arcsec,/iso, $
    xtitle = 'X [arcsec]', ytitle = "Y [arcsec]"
  seismo_corona_plot_loops, ev
end

pro seismo_corona_plot_loops, ev
compile_opt idl2
  common seismo_corona
  if global['state'] eq 'no data' then return
  if global['loops'].count() eq 0 then return
  for i =0, global['loops'].count()-1 do begin
    oplot, (global['loops'])[i].x, (global['loops'])[i].y
  endfor
  loop_list = widget_info(ev.top, find_by_uname = 'loop_list')
  loop_index = widget_info(loop_list, /LIST_SELECT)
  if loop_index ge 0 then begin
    oplot, (global['loops'])[loop_index].x, (global['loops'])[loop_index].y, thick = 2
  endif
end

pro seismo_corona_plot_td, ev
compile_opt idl2
common seismo_corona
  if global['loops'].count() eq 0 then return
  loop_list = widget_info(ev.top, find_by_uname = 'loop_list')
  loop_index = widget_info(loop_list, /LIST_SELECT)
  if loop_index lt 0 then loop_index = 0
  
  ;Read current slit
  slit_selector = widget_info(ev.top, find_by_uname = 'slit_selector')
  widget_control, slit_selector, get_value = slit_num
  
  ;Read current frame
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, get_value = frame_num
  
  td = reform((global['loops'])[loop_index].data[*,slit_num,*])
  
  draw_td = widget_info(ev.top, find_by_uname = 'draw_td')
  sz = size(td)
  WIDGET_CONTROL, draw_td, GET_VALUE = win
  wset,win
  implot, td, /sample, xtitle = "Time [frames]", ytitle = "Distance [pixels]"
  oplot, [frame_num, frame_num], [0,sz[2] - 1]
end

pro  seismo_corona_switch_view, ev
compile_opt idl2
common seismo_corona
  if ev.tab eq 0 then begin ;Image view
    seismo_corona_plot_frame, ev
  endif
  if ev.tab eq 1 then begin ;TD view
    seismo_corona_plot_td, ev
  endif
end

pro seismo_corona_save, ev
compile_opt idl2
  print, 'save'
end
pro seismo_corona_close, ev
compile_opt idl2
  print, 'close'
end

pro seismo_corona_cleanup, ev
compile_opt idl2
common seismo_corona
  global.remove,global.keys()
  global = []
  message,'CleanUP completed',/info
  

end

pro seismo_corona_events,ev
compile_opt idl2
  Message,'unprocessed event',/info
end