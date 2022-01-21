function share_openmmf,file
  openr,lun,file,/get_lun
  ndim=0l
  readu,lun,ndim
  n=ndim+3
  si=lonarr(n)
  point_lun,lun,0
  readu,lun,si  
  free_lun,lun
  offset=n*4l
  shmmap,size=si,file=file,get_name=segname,offset=offset
  var=shmvar(segname)
  return,var
end