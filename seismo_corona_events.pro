pro seismo_corona_add_loop, ev
  print, 'Add_loop'
end
pro seismo_corona_delete_loop, ev
  print, 'Delete_loop'
end
pro seismo_corona_open, ev
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
end

pro seismo_corona_plot_frame, ev
common seismo_corona
  if global['state'] eq 'no data' then return
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, get_value = frame_num
  implot, comprange((global['data'])[*,*,frame_num],/global),/iso
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