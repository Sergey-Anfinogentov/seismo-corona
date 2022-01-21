pro share_var,var,name=name,os_handle=os_handle
  help,var,out=info
  si=size(var)
  if si[0] eq 0 then var=[var]
  if n_elements(var) eq 0 then message,'variable is undefined'
  if strmatch(info,'<Expression>*') then message, 'the first parameter should be a named variable'
  if keyword_set(name) then begin
    os_name='IDL_share_'+name
    shmmap,name,size=size(var),os_handle=os_name,destroy=1
  endif else shmmap,get_name=name,size=size(var),get_os_handle=os_handle,destroy=1
  tmp=temporary(var)
  var=shmvar(name)
  var[*]=tmp
end




