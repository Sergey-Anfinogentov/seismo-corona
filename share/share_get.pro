function share_get,os_handle,si
  shmmap,get_name=name,size=si,os_handle=os_handle
  return,shmvar(name);
end