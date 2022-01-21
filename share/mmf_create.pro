function mmf_byte_size, value
  n = n_elements(value)
  type_code = size(value,/type,/l64)
  case type_code of
    1: type_size = 1ll
    2: type_size = 2ll
    4: type_size = 4ll
    5: type_size = 8ll
    3: type_size = 4ll
    else:message,"Unsupported type"
  endcase
  
  return,n * type_size
end
function mmf_create,file_name,d1,d2,d3,d4,d5,d6,d7,d8,float=float,double=double,int=int,byte=byte,long=long, segname = segname
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
    2: begin
      length=long(d1)
      si=long([ndim,d1,type,length])
    end
    3: begin
      length=long(d1)*long(d2)
      si=long([ndim,d1,d2,type,length])
    end
    4: begin
      length=long(d1)*long(d2)*long(d3)
      si=long([ndim,d1,d2,d3,type,length])
    end
    5: begin
      length=long(d1)*long(d2)*long(d3)*long(d4)
      si=long([ndim,d1,d2,d3,d4,type,length])
    end
    6: begin
      length=long(d1)*long(d2)*long(d3)*long(d4)*long(d5)
      si=long([ndim,d1,d2,d3,d4,d5,type,length])
    end
    7: begin
      length=long(d1)*long(d2)*long(d3)*long(d4)*long(d5)*long(d6)
      si=long([ndim,d1,d2,d3,d4,d5,d6,type,length])
    end
    8: begin
      length=long(d1)*long(d2)*long(d3)*long(d4)*long(d5)*long(d6)*long(d7)
      si=long([ndim,d1,d2,d3,d4,d5,d6,d7,type,length])
    end
    9: begin
      length=long(d1)*long(d2)*long(d3)*long(d4)*long(d5)*long(d6)*long(d7)*long(d8)
      si=long([ndim,d1,d2,d3,d4,d5,d6,d7,d8,type,length])
    end
  endcase
  
  ;create a sparse file
  openw,lun,file_name,/get_lun
  writeu,lun,si
  point_lun,lun, mmf_byte_size(si) + length * mmf_byte_size(value) - 1l
  writeu,lun,0b
 
  free_lun,lun
  shmmap,size=si,file=file_name,get_name=segname,get_os_handle=os_handle,offset=n_elements(si)*4l
  image=shmvar(segname)
  return,image
end