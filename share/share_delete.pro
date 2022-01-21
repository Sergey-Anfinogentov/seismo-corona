pro share_delete,var,save=save
  name=share_getname(var)
  if name eq '' then begin
    help,var,out=out
   message,'The variable is not shared:'+out
  end 
  outvar=var  
  shmunmap,name
  outvar[*]=temporary(var)
  if keyword_set(save) then var=outvar
  if n_elements(var) eq 1 then var=var[0]
end
