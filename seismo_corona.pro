pro seismo_corona
compile_opt idl2
common seismo_corona, global
compile_opt idl2
resolve_routine,'seismo_corona_routines',/compile_full_file, /either
resolve_routine,'seismo_corona_form',/compile_full_file, /either
resolve_routine,'seismo_corona_events',/compile_full_file, /either
  ;widget_control, default_font = 'r24'
  global = hash()
  global['state'] = 'no data'
  global['loops'] = list()
  base = seismo_corona_form()
  WIDGET_CONTROL, base, /REALIZE
  
  
  XMANAGER, 'seismo_corona', base, event_handler = 'seismo_corona_events', cleanup = 'seismo_corona_cleanup'
end