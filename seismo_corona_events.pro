pro seismo_corona_add_loop, ev
  common seismo_corona
  if global['state'] eq 'no data' then retu
  print, 'Add_loop'
  loop = time_distance_ellipse(global['data'],/current_plot)
  global['loops'].Add, loop
  loop_list = widget_info(ev.top, find_by_uname = 'loop_list')
  loop_count = global['loops'].count()
  widget_control, loop_list, set_value = 'loop '+ strcompress(indgen(loop_count),/remove_all)
end

pro seismo_corona_show_status, ev, text
  status_text = widget_info(ev.top, find_by_uname = 'status_text')
  widget_control, status_text, set_value = text
end

pro seismo_corona_delete_loop, ev
  print, 'Delete_loop'
end
pro seismo_corona_select_loop, ev
common seismo_corona
  seismo_corona_plot_frame, ev
end
pro seismo_corona_open, evseismo_corona_show_status, ev, text
common seismo_corona
  print, 'Open event fired'
  file_name = dialog_pickfile(title = 'Select save file with data')
  print, 'readind data from '+ file_name
  restore, file_name,/v
end

pro seismo_corona_import_fits, ev
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
  seismo_corona_show_status, ev, 'Waiting for a user command...'
end

pro seismo_corona_plot_frame, ev
common seismo_corona
  if global['state'] eq 'no data' then return
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, get_value = frame_num
  implot, comprange((global['data'])[*,*,frame_num],/global),/iso
  seismo_corona_plot_loops, ev
end

pro seismo_corona_plot_loops, ev
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

pro seismo_corona_save, ev
  print, 'save'
end
pro seismo_corona_close, ev
  print, 'close'
end

pro seismo_corona_cleanup, ev
common seismo_corona
  global.remove,global.keys()
  global = []
  message,'CleanUP completed',/info
  

end

pro seismo_corona_events,ev
  Message,'unprocessed event',/info
end