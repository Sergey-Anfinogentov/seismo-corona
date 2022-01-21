function share_createmmf,d1,d2,d3,d4,d5,d6,d7,d8,float=float,double=double,int=int,byte=byte,long=long
   ndim=n_params()
   case 1 of
    keyword_set(float):value=0.
    keyword_set(int):value=0
    keyword_set(double):value=0d
    keyword_set(byte):value=0b
    keyword_set(long):value=0l
    else:value=0.
   endcase
    type=size(value,/type)
   case ndim of
   1: begin 
        length=long(d1)
        si=long([ndim,d1,type,length])
      end
   2: begin 
        length=long(d1)*long(d2)
        si=long([ndim,d1,d2,type,length])
      end
   3: begin 
        length=long(d1)*long(d2)*long(d3)
        si=long([ndim,d1,d2,d3,type,length])
      end
   4: begin 
        length=long(d1)*long(d2)*long(d3)*long(d4)
        si=long([ndim,d1,d2,d3,d4,type,length])
      end
   5: begin 
        length=long(d1)*long(d2)*long(d3)*long(d4)*long(d5)
        si=long([ndim,d1,d2,d3,d4,d5,type,length])
      end    
   6: begin 
        length=long(d1)*long(d2)*long(d3)*long(d4)*long(d5)*long(d6)
        si=long([ndim,d1,d2,d3,d4,d5,d6,type,length])
      end
   7: begin 
        length=long(d1)*long(d2)*long(d3)*long(d4)*long(d5)*long(d6)*long(d7)
        si=long([ndim,d1,d2,d3,d4,d5,d6,d7,type,length])
      end
   8: begin 
        length=long(d1)*long(d2)*long(d3)*long(d4)*long(d5)*long(d6)*long(d7)*long(d8)
        si=long([ndim,d1,d2,d3,d4,d5,d6,d7,d8,type,length])
      end 
   endcase
   maxnr=1024l*1024l<length; Bufer length
   pos=0l; elements written to file
   tempfile=filepath('idl_shm_'+randomstring(s,10),root_dir=getenv('IDL_TMPDIR'))
   openw,lun,tempfile,/get_lun
   writeu,lun,si
   while pos lt length do begin
    nwr=(length - pos)<maxnr
    pos+=nwr
    writeu,lun,replicate(value,nwr)   
   endwhile
   free_lun,lun
   shmmap,size=si,file=tempfile,get_name=segname,get_os_handle=os_handle,offset=n_elements(si)*4l
   image=shmvar(segname)
   return,image
end