function mmf_open, file, segname = segname
  openr,lun,file,/get_lun
  ndim=0l
  readu,lun,ndim
  n=ndim+2
  si=lonarr(n)
  point_lun,lun,0
  readu,lun,si
  free_lun,lun
  offset=(n)*4l
  shmmap,size=si,file=file,get_name=segname,offset=offset
  var=shmvar(segname)
  return,var
end