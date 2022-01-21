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
  
  td = loop["data"]
  loop.remove,"data"
  
  length = seismo_corona_loop_length(index, ev)
  
  loop['length'] = length
  
  loop_num = global['loops'].count() + 1
  loop_file = "loop"+strcompress(loop_num,/remove_all)+".dat"
  data_dir = filepath("data",root_dir = global["project_dir"])
  loop_file = filepath(loop_file, root_dir = data_dir)
  loop["data_file"] = file_basename(loop_file)
  sz = size(td)
  td_mmf = mmf_create(loop_file, sz[1], sz[2],sz[3],/float, segname = segment)
  td_mmf[*] = temporary(td)
  loop["data_segment"] = segment
  
  global['loops'].Add, loop
  loop_list = widget_info(ev.top, find_by_uname = 'loop_list')
  loop_count = global['loops'].count()
  
  seismo_corona_set_curent_loop, ev, loop_count - 1
  seismo_corona_select_loop, ev
  seismo_corona_show_status, ev, 'Ready'
end

pro seismo_corona_show_status, ev, text
compile_opt idl2
  status_text = widget_info(ev.top, find_by_uname = 'status_text')
  widget_control, status_text, set_value = text
end

pro seismo_corona_delete_loop, ev
compile_opt idl2
common seismo_corona
  print, 'Delete_loop'
  loop_index = seismo_corona_get_current_loop(ev)
  segment = global['loops', loop_index, 'data_segment']
  
  help,/shared,out=out
  ;stop
  ind=where(strmatch(out,segment+'*'))
  if ind[0] eq -1 then message, 'No segment found'
  info=out[ind[0]+1]
  file=(stregex(info,'<MappedFile\((.*)\),.*,.*>',/subexpr,/extr))[1]
  if file eq '' then message,'No memory mapped file found'
  shmunmap,segment
  file_delete, file
  global["loops"].remove, loop_index
  seismo_corona_set_curent_loop, ev, 0
  seismo_corona_select_loop, ev
  
end
pro seismo_corona_select_loop, ev
compile_opt idl2
common seismo_corona
  dt = 12d
  loop_index = seismo_corona_get_current_loop(ev)
  if n_elements(global['loops']) eq 0 then return
  td = shmvar(global['loops', loop_index, 'data_segment'])
  sz = size(td)
  
  slit_selector = widget_info(ev.top, find_by_uname = 'slit_selector')
  widget_control, slit_selector, SET_SLIDER_MAX = sz[2] - 1
  
 loop_data = widget_info(ev.top, find_by_uname = 'loop_data')
 length = global['loops',loop_index,'length']
  
  info = strarr(1,3)
  info[*,0] = strcompress(round(length))+' Mm'
  
  if global['loops',loop_index].haskey('oscillation') then begin
    period = dt*global['loops',loop_index,'oscillation','period']
    info[*,1] = strcompress(round(period))+' s'
    ca =  2d*length*1d3/period
    info[*,2] = strcompress(round(ca))+' km/s'
  endif
 

  widget_control, loop_data, set_value = info
  

  seismo_corona_plot_frame, ev
  seismo_corona_plot_td, ev
end
pro seismo_corona_open,  ev, text
compile_opt idl2
common seismo_corona
  file =dialog_pickfile(filter = '*.prj.sav', title = 'Select file with saved project',$
  path = '~/data/kink_magnetic/limb2')
  seismo_corona_show_status, ev, "Reading.."
  restore, file, /RELAXED_STRUCTURE_ASSIGNMENT
  data_file = str_replace(file,".sav",".dat")
  data = mmf_open(data_file, segname=segment)
  global["data_segment"] = segment
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  sz = size(data)
  widget_control, frame_selector, SET_SLIDER_MAX = sz[3] - 1
  seismo_corona_set_curent_loop, ev, 0
  seismo_corona_select_loop, ev
  seismo_corona_show_status, ev, "Ready"

end

pro seismo_corona_import_fits, ev
compile_opt idl2
common seismo_corona
  dir_name = dialog_pickfile(title = 'Select directory with FITs files', /directory, path = '~/data')
  message,'Reading data from '+dir_name +' ...', /info
  seismo_corona_show_status, ev, 'Reading data...'
  files = file_search(filepath('*.fits', root_dir = dir_name))
  read_sdo, files[0], temp_index, temp_data,/use_shared_lib, /uncomp_delete
  sz = size(temp_data)
  nx = sz[1]
  ny = sz[2]
  nt = n_elements(files)
  data_dir =filepath("data",root = global["project_dir"])
  data_file =filepath("images.dat",root =data_dir)
  file_mkdir, data_dir
  data = mmf_create(data_file, nx, ny, nt, segname = segment)
  global["data_segment"] = segment
  index = replicate(temp_index,nt)
  buffer_index = temp_index
  for i =0, nt -1 do begin
    read_sdo, files[i], temp_index, temp_data,/use_shared_lib, /uncomp_delete
    temp_data /= temp_index.exptime
    data[*,*,i] = temp_data
    ;index[i] = temp_index
    
    STRUCT_ASSIGN,temp_index,buffer_index
    index[i] = buffer_index
  endfor
  message,'Reading data complete', /info
  sz = size(data)
  global['index'] = temporary(index)
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
  data = shmvar(global["data_segment"])
  implot, comprange(data[*,*,frame_num],/global), x_arcsec, y_arcsec,/iso, $
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
    loadct, 5
    oplot, global['loops',loop_index,'x'], global['loops',loop_index, 'y'], thick = 2, color = 200
    loadct,0
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
  
  ;Read brightness range
  brightness_range_down_selector = widget_info(ev.top, find_by_uname = 'brightness_range_down_selector')
  widget_control, brightness_range_down_selector, get_value = limit_down
  brightness_range_up_selector = widget_info(ev.top, find_by_uname = 'brightness_range_up_selector')
  widget_control, brightness_range_up_selector, get_value = limit_up
  
  
  td =  seismo_corona_get_td(loop_index, slit_num, slit_width)
  
  draw_td = widget_info(ev.top, find_by_uname = 'draw_td')
  sz = size(td)
  WIDGET_CONTROL, draw_td, GET_VALUE = win
  
  xrange = frame_num + [-td_window/2., td_window/2.]

  td_min = min(td)
  td_max = max(td)
  range = td_max - td_min
  limit_down = td_min + range * (limit_down/100d)
  limit_up = td_min + range * (limit_up/100d)  
  
  wset,win
  implot, td>limit_down<limit_up,  xtitle = "Time [frames]", ytitle = "Distance [pixels]", xrange = xrange
  oplot, [frame_num, frame_num], [0,sz[2] - 1]
  
  switch_plot_osc = widget_info(ev.top, find_by_uname = 'switch_plot_osc')
  
  plot_fit = widget_info(switch_plot_osc, /button_set)
  if plot_fit and global['loops',loop_index].haskey('oscillation') then begin
    t = global['loops',loop_index,'oscillation','time']
    c = global['loops',loop_index,'oscillation','centre']
    loadct,3
    oplot, t, c, psym = 1, color = 128
    if global['loops',loop_index,'oscillation'].haskey('mcmc') then begin
      fit = global['loops',loop_index,'oscillation','mcmc','fit']
      loadct,8
      oplot, t, fit, color = 128
    end
    loadct,0
  endif
  
end


pro seismo_corona_plot_td_long, ev
  compile_opt idl2
  common seismo_corona
  if global['loops'].count() eq 0 then return

  ;reed current loop
  loop_index = seismo_corona_get_current_loop(ev)

  ;Read current slit
  slit_selector = widget_info(ev.top, find_by_uname = 'slit_selector_long')
  widget_control, slit_selector, get_value = slit_num


  ;Read slit width
  slit_width_selector = widget_info(ev.top, find_by_uname = 'slit_width_selector_long')
  widget_control, slit_width_selector, get_value = slit_width

  ;Read current frame
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, get_value = frame_num

  ;Read current frame
  time_range_selector = widget_info(ev.top, find_by_uname = 'time_range_selector_long')
  widget_control, time_range_selector, get_value = td_window

  ;Read brightness range
  brightness_range_down_selector = widget_info(ev.top, find_by_uname = 'brightness_range_down_selector_long')
  widget_control, brightness_range_down_selector, get_value = limit_down
  brightness_range_up_selector = widget_info(ev.top, find_by_uname = 'brightness_range_up_selector_long')
  widget_control, brightness_range_up_selector, get_value = limit_up


  td =  seismo_corona_get_td_long(loop_index, slit_num, slit_width)

  draw_td = widget_info(ev.top, find_by_uname = 'draw_td_long')
  sz = size(td)
  WIDGET_CONTROL, draw_td, GET_VALUE = win

  xrange = frame_num + [-td_window/2., td_window/2.]

  td_min = min(td)
  td_max = max(td)
  range = td_max - td_min
  limit_down = td_min + range * (limit_down/100d)
  limit_up = td_min + range * (limit_up/100d)

  wset,win
  implot, td>limit_down<limit_up,  xtitle = "Time [frames]", ytitle = "Distance [pixels]", xrange = xrange
  oplot, [frame_num, frame_num], [0,sz[2] - 1]

;  switch_plot_osc = widget_info(ev.top, find_by_uname = 'switch_plot_osc')
;
;  plot_fit = widget_info(switch_plot_osc, /button_set)
;  if plot_fit and global['loops',loop_index].haskey('oscillation') then begin
;    t = global['loops',loop_index,'oscillation','time']
;    c = global['loops',loop_index,'oscillation','centre']
;    loadct,3
;    oplot, t, c, psym = 1, color = 128
;    if global['loops',loop_index,'oscillation'].haskey('mcmc') then begin
;      fit = global['loops',loop_index,'oscillation','mcmc','fit']
;      loadct,8
;      oplot, t, fit, color = 128
;    end
;    loadct,0
;  endif

end


pro  seismo_corona_switch_view, ev
compile_opt idl2
common seismo_corona
  fit_osc = widget_info(ev.top, find_by_uname = 'fit_osc')
  switch_plot_osc = widget_info(ev.top, find_by_uname = 'switch_plot_osc')
  if ev.tab eq 0 then begin ;Image view
    seismo_corona_plot_frame, ev
    widget_control, fit_osc, sensitive = 0
    widget_control, switch_plot_osc, sensitive = 0
  endif
  if ev.tab eq 1 then begin ;TD view
    seismo_corona_plot_td, ev 
    widget_control, fit_osc, sensitive = 1
    widget_control, switch_plot_osc, sensitive = 1
  endif
  if ev.tab eq 2 then begin ;TD view
    seismo_corona_plot_td_long, ev
    ;widget_control, fit_osc, sensitive = 1
    ;widget_control, switch_plot_osc, sensitive = 1
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
  data = shmvar(global['data_segment'])
  n_frames =  n_elements(data)
  
  new_frame_num = (frame_num - fix(td_window/5))>0
  widget_control, frame_selector, set_value = new_frame_num
  seismo_corona_plot_td, ev
 
end

pro  seismo_corona_td_back_long, ev
  compile_opt idl2
  common seismo_corona

  ;Read current frame
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, get_value = frame_num

  ;Read current frame
  time_range_selector = widget_info(ev.top, find_by_uname = 'time_range_selector_long')
  widget_control, time_range_selector, get_value = td_window
  data = shmvar(global['data_segment'])
  n_frames =  n_elements(data)

  new_frame_num = (frame_num - fix(td_window/5))>0
  widget_control, frame_selector, set_value = new_frame_num
  seismo_corona_plot_td_long, ev

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
  
  data = shmvar(global['data_segment'])
  n_frames =  n_elements(data)
  
  new_frame_num = (frame_num + fix(td_window/5))<n_frames
  widget_control, frame_selector, set_value = new_frame_num
  seismo_corona_plot_td, ev
  
end

pro  seismo_corona_td_forward_long, ev
  compile_opt idl2
  common seismo_corona

  ;Read current frame
  frame_selector = widget_info(ev.top, find_by_uname = 'frame_selector')
  widget_control, frame_selector, get_value = frame_num

  ;Read current frame
  time_range_selector = widget_info(ev.top, find_by_uname = 'time_range_selector_long')
  widget_control, time_range_selector, get_value = td_window

  data = shmvar(global['data_segment'])
  n_frames =  n_elements(data)

  new_frame_num = (frame_num + fix(td_window/5))<n_frames
  widget_control, frame_selector, set_value = new_frame_num
  seismo_corona_plot_td_long, ev

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
  
  ;mcmc = fit_decayless(time, centre,  params = params, credible_intervals = credible_intervals, samples = samples)
  ;oplot,time, mcmc['fit']
  
  ;updating loop data
  
  ;ind = where(mcmc['parnames'] eq 'period')
 ; period = mcmc['estimate',ind]
  
  ;ind = where(mcmc['parnames'] eq 'amplitude')
  ;amplitude = mcmc['estimate',ind]
  
  oscillation = hash()
  oscillation['td'] = td
  oscillation['slit_index'] = slit_index
  oscillation['slit_width'] = slit_width
  oscillation['time']=time
  oscillation['centre'] = centre
  oscillation['sigma'] = sigma
  oscillation['period'] = 0.;period
  oscillation['amplitude'] = amplitude
  ;oscillation['mcmc'] =mcmc
  global['loops', loop_index, 'oscillation'] = oscillation
  
  
;  stop
end

pro seismo_corona_save, ev
compile_opt idl2
common seismo_corona
  message,'save project placeholder',/info
  return
   file = dialog_pickfile(DEFAULT_EXTENSION = 'prj.sav', title = 'Select file where to save current project',$
  path = '~/data/kink_magnetic/limb2')
   seismo_corona_show_status, ev, "Saving data.."
   save,global, file = file
   seismo_corona_show_status, ev, "Ready"
   
end
pro seismo_corona_close, ev
compile_opt idl2
 
end
pro seismo_corona_export_oscillation, ev
compile_opt idl2
common seismo_corona
  loop_index = seismo_corona_get_current_loop(ev)
  oscillation = global['loops',loop_index,'oscillation']
  
  time =  anytim(global["index"].t_obs)
  time_index = oscillation["time"]
  
  oscillation["time"] = oscillation["time"]
  oscillation["time_index"] = time_index
  oscillation=oscillation.tostruct()
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
  if global.haskey("data_segment") then begin
    shmunmap, global["data_segment"]
    index_file = filepath('index.sav',root_dir = global["project_dir"])
    save, global, file = index_file
  endif
  for i = 0, n_elements(global["loops"]) -1 do begin
    data_segment = global["loops", i, "data_segment"]
    shmunmap, data_segment
  endfor
  global.remove,global.keys()
  global = []
  message,'CleanUP completed',/info
  

end

pro seismo_corona_events,ev
compile_opt idl2
  Message,'unprocessed event',/info
end