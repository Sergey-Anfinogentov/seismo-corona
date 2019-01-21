pro seismo_corona_add_loop, ev
  compile_opt idl2
  common seismo_corona
  if global['state'] eq 'no data' then retu
  seismo_corona_show_status, ev, 'Click points to select a loop. Right click finalises selection.'
  
  seismo_corona_plot_frame, ev
  index = (global['index'])[0]
  x_arcsec = hdr2x(index)
  y_arcsec = hdr2y(index)
  
  loop = seismo_corona_time_distance_ellipse(ev, x_arcsec, y_arcsec, /current_plot)

  
  length = seismo_corona_loop_length(index, ev)
  
  loop['length'] = length
  
  global['loops'].Add, loop
  loop_list = widget_info(ev.top, find_by_uname = 'loop_list')
  loop_count = global['loops'].count()
  widget_control, loop_list, set_value = 'loop '+ strcompress(indgen(loop_count),/remove_all)
  
  seismo_corona_set_curent_loop, ev, loop_count - 1
 
  
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

  loop_index = seismo_corona_get_current_loop(ev)
  
  sz = size(global['loops', loop_index, 'data'])
  
  slit_selector = widget_info(ev.top, find_by_uname = 'slit_selector')
  widget_control, slit_selector, SET_SLIDER_MAX = sz[2] - 1
  
 loop_data = widget_info(ev.top, find_by_uname = 'loop_data')
 length = global['loops',loop_index,'length']
  widget_control, loop_data, set_value = [{length:length}]
  

  seismo_corona_plot_frame, ev
  seismo_corona_plot_td, ev
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
  dir_name = dialog_pickfile(title = 'Select directory with FITs files', /directory, path = '~/data/kink_magnetic/limb2')
  message,'Reading data from '+dir_name +' ...', /info
  seismo_corona_show_status, ev, 'Reading data...'
  files = file_search(filepath('*.fits', root_dir = dir_name))
  read_sdo, files, index, data,/use_shared_lib, /uncomp_delete
  data = float(data)
  
  ;normolizing exposure
  nt = n_elements(files)
  for i =0, nt -1 do begin
    data[*,*,i] /= index[i].exptime
  endfor
  
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
  
  ;Read current frame
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, get_value = frame_num
  
  ;Read current slit
  slit_selector = widget_info(ev.top, find_by_uname = 'slit_selector')
  widget_control, slit_selector, get_value = slit_num
  
  ;reed current loop
  loop_index = seismo_corona_get_current_loop(ev)
  
  ;Set graphics output to the correct draw widget
  draw_frame = widget_info(ev.top, find_by_uname = 'draw_frame')
  WIDGET_CONTROL, draw_frame, GET_VALUE = win 
  wset,win
  
  index = global['index',0]
  
  x_arcsec = hdr2x(index)
  y_arcsec = hdr2y(index) 
  
  implot, comprange(global['data',*,*,frame_num],/global), x_arcsec, y_arcsec,/iso, $
    xtitle = 'X [arcsec]', ytitle = "Y [arcsec]"
  seismo_corona_plot_loops, ev
  
  if global['loops'].count() gt 0 then begin
     oplot, [global['loops',loop_index,'x1',slit_num], global['loops',loop_index,'x2',slit_num]], $
            [global['loops',loop_index,'y1',slit_num], global['loops',loop_index,'y2',slit_num]]
  endif
  
end

pro seismo_corona_plot_loops, ev
compile_opt idl2
  common seismo_corona
  if global['state'] eq 'no data' then return
  if global['loops'].count() eq 0 then return
  for i =0, global['loops'].count()-1 do begin
    oplot, global['loops',i,'x'], global['loops',i , 'y']
  endfor
  loop_index = seismo_corona_get_current_loop(ev)
  if loop_index ge 0 then begin
    oplot, global['loops',loop_index,'x'], global['loops',loop_index, 'y'], thick = 2
  endif
end

pro seismo_corona_plot_td, ev
compile_opt idl2
common seismo_corona
  if global['loops'].count() eq 0 then return
  
  ;reed current loop
  loop_index = seismo_corona_get_current_loop(ev)
  
  ;Read current slit
  slit_selector = widget_info(ev.top, find_by_uname = 'slit_selector')
  widget_control, slit_selector, get_value = slit_num
  
  
  ;Read slit width
  slit_width_selector = widget_info(ev.top, find_by_uname = 'slit_width_selector')
  widget_control, slit_width_selector, get_value = slit_width
  
  ;Read current frame
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, get_value = frame_num
  
  ;Read current frame
  time_range_selector = widget_info(ev.top, find_by_uname = 'time_range_selector')
  widget_control, time_range_selector, get_value = td_window
  
  td =  seismo_corona_get_td(loop_index, slit_num, slit_width)
  
  draw_td = widget_info(ev.top, find_by_uname = 'draw_td')
  sz = size(td)
  WIDGET_CONTROL, draw_td, GET_VALUE = win
  
  xrange = frame_num + [-td_window/2., td_window/2.]
  
  
  wset,win
  implot, td,  xtitle = "Time [frames]", ytitle = "Distance [pixels]", xrange = xrange
  oplot, [frame_num, frame_num], [0,sz[2] - 1]
end

pro  seismo_corona_switch_view, ev
compile_opt idl2
common seismo_corona
  fit_osc = widget_info(ev.top, find_by_uname = 'fit_osc')
  if ev.tab eq 0 then begin ;Image view
    seismo_corona_plot_frame, ev
    widget_control, fit_osc, sensitive = 0
  endif
  if ev.tab eq 1 then begin ;TD view
    seismo_corona_plot_td, ev 
    widget_control, fit_osc, sensitive = 1
  endif
end

pro  seismo_corona_td_back, ev
  compile_opt idl2
  common seismo_corona
  
 ;Read current frame
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, get_value = frame_num
  
  ;Read current frame
  time_range_selector = widget_info(ev.top, find_by_uname = 'time_range_selector')
  widget_control, time_range_selector, get_value = td_window
  
  n_frames =  n_elements(global['data',0,0,*])
  
  new_frame_num = (frame_num - fix(td_window/5))>0
  widget_control, frame_selector, set_value = new_frame_num
  seismo_corona_plot_td, ev
 
end
pro  seismo_corona_td_forward, ev
  compile_opt idl2
  common seismo_corona
  
  ;Read current frame
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, get_value = frame_num
  
  ;Read current frame
  time_range_selector = widget_info(ev.top, find_by_uname = 'time_range_selector')
  widget_control, time_range_selector, get_value = td_window
  
  n_frames =  n_elements(global['data',0,0,*])
  
  new_frame_num = (frame_num + fix(td_window/5))<n_frames
  widget_control, frame_selector, set_value = new_frame_num
  seismo_corona_plot_td, ev
  
end

pro seismo_corona_fit_oscillation, ev
compile_opt idl2
common seismo_corona
  ;reed current loop
  loop_index = seismo_corona_get_current_loop(ev)
  
  ;Read current slit
  slit_selector = widget_info(ev.top, find_by_uname = 'slit_selector')
  widget_control, slit_selector, get_value = slit_index
  
  ;Read slit width
  slit_width_selector = widget_info(ev.top, find_by_uname = 'slit_width_selector')
  widget_control, slit_width_selector, get_value = slit_width
  
  td =  seismo_corona_get_td(loop_index, slit_index, slit_width)
  
  seismo_corona_measure_loop_position, ev, td, time, centre,sigma, amplitude
  
  mcmc = fit_decayless(time, centre,  params = params, credible_intervals = credible_intervals, samples = samples)
  oplot,time, mcmc['fit']
  
  ;updating loop data
  
  ind = where(mcmc['parnames'] eq 'period')
  period = mcmc['estimate',ind]
  
  ind = where(mcmc['parnames'] eq 'amplitude')
  amplitude = mcmc['estimate',ind]
  
  oscillation = hash()
  oscillation['td'] = td
  oscillation['slit_index'] = slit_index
  oscillation['slit_width'] = slit_width
  oscillation['time']=time
  oscillation['centre'] = centre
  oscillation['sigma'] = sigma
  oscillation['period'] = pariod
  oscillation['amplitude'] = amplitude
  oscillation['mcmc'] =mcmc
  global['loops', loop_index, 'oscillation'] = oscillation
  
  
;  stop
end

pro seismo_corona_save, ev
compile_opt idl2
  print, 'save'
end
pro seismo_corona_close, ev
compile_opt idl2
  print, 'close'
end
pro seismo_corona_export_oscillation, ev
compile_opt idl2
common seismo_corona
  loop_index = seismo_corona_get_current_loop(ev)
  oscillation = global['loops',loop_index,'oscillation']
  save,oscillation, file = dialog_pickfile(DEFAULT_EXTENSION = 'osc.sav', title = 'Select file where to save oscillation data')

end
pro seismo_corona_export_loop, ev
compile_opt idl2
common seismo_corona
  loop_index = seismo_corona_get_current_loop(ev)
  loop = global['loops',loop_index]
  save,loop, file = dialog_pickfile(DEFAULT_EXTENSION = 'loop.sav', title = 'Select file where to save loop data')
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