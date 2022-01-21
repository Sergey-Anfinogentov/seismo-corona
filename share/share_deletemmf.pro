pro share_deletemmf,var  
  name=share_getname(var)
  file=share_getfile(var)
  var=0
  foo=temporary(var)
  shmunmap,name  
  file_delete,file
end