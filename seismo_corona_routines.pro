function seismo_corona_read_data, file_name

end

function seismo_corona_loop_length, index, ev

  wcs = fitshead2wcs(index)
  
  seismo_corona_show_status, ev, 'Click at the first footpoint (or between the loop footpoints)'
  cursor,x1,y1,/data,/down
  plots,x1,y1, psym = 2
  seismo_corona_show_status, ev, 'Click at the second footpoint (orst the loop apex)'
  cursor,x2,y2,/data,/down
  plots,x2,y2, psym = 2
  
  points = dblarr(2,2)
  points[0,*] = [x1,x2] & points[1,*] = [y1,y2]
  
  rsun_arcsec = index.rsun_obs
  rsun_m = wcs_rsun()
  
  r1 = sqrt(x1^2 + y1^2)
  r2 = sqrt(x2^2 + y2^2)
  seismo_corona_show_status, ev, 'Ready'
  
  if (r1 gt rsun_arcsec) or (r2 gt rsun_arcsec) then begin ; Apex method
    r_loop = sqrt((x1-x2)^2 +(y1-y2)^2) * rsun_m / rsun_arcsec
    length = !dpi * r_loop * 1d-6
    print, 'loop length',length
    return, length
  endif
  
  stop

end

pro seismo_corona_routines

end