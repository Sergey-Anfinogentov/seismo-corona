function share_getfile,var
  name=share_getname(var)
  help,/shared,out=out
  ;stop
  ind=where(strmatch(out,name+'*'))
  if ind[0] eq -1 then message, 'No segment found'
  info=out[ind[0]]
  file=(stregex(info,'<MappedFile\((.*)\),.*,.*>',/subexpr,/extr))[1]
  if file eq '' then message,'No memory mapped file found'
  return,file
end