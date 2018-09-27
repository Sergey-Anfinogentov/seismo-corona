pro seismo_corona
common seismo_corona, global
compile_opt idl2
  global = hash()
  global['state'] = 'no data'
  base = seismo_corona_form()
  WIDGET_CONTROL, base, /REALIZE
  
  
  XMANAGER, 'seismo_corona', base, event_handler = 'seismo_corona_events', cleanup = 'seismo_corona_cleanup'
end