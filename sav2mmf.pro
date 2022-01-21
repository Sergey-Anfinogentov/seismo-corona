pro sav2mmf, sav_file
  new_sav = str_replace(sav_file,"prj.sav","new.prj.sav")
  prj_dir = str_replace(sav_file,".prj.sav","")
  data_dir = filepath("data",root = prj_dir)
  file_mkdir, prj_dir
  file_mkdir, data_dir
  data_file = filepath("images.dat",root_dir = data_dir)
  index_file = filepath("index.sav",root_dir = prj_dir)
  print,"restoring data"
  restore,sav_file,/relaxed
  print,"data has been restored"
  sz = size(global["data"])
  data_mmf = mmf_create(data_file,sz[1], sz[2], sz[3],/float)
  data_mmf[*] = global["data"]
  mmf_close, data_mmf
  print,"images have neen saved"
  global.remove, "data"
  
  nl = n_elements(global["loops"])
  for i = 0, nl -1 do begin
    print,"processing loop",i
    td = global["loops", i, "data"]
    global["loops", i].remove,"data"
    
    loop_file = "loop"+strcompress(i,/remove_all)+".dat"
    loop_file = filepath(loop_file, root_dir = data_dir)
    global["loops", i,"data_file"] = file_basename(loop_file)
    sz = size(td)
    td_mmf = mmf_create(loop_file, sz[1], sz[2],sz[3],/float, segname = segment)
    td_mmf[*] = temporary(td)
    global["loops", i, "data_segment"] = segment
    shmunmap, segment
  endfor
    
  save, global, file = index_file
end