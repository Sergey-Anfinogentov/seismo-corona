function share_getoshandle,var,name=name
  if not keyword_set(name) then name=share_getname(var)
  help,/shared,out=out
  ind=where(strmatch(out,name+'*'))
  if ind[0] eq -1 then message, 'No segment found'
  info=out[ind[0]]
  os_handle=(stregex(info,'<[^\(]*\(([^,\)]*)\).*>',/subexpr,/extr))[1]
  if os_handle eq '' then message,'We have an error here'
  return,os_handle
end