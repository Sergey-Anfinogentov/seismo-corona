function seismo_corona_read_data, file_name
compile_opt idl2

end

function seismo_corona_loop_length, index, ev
compile_opt idl2

  wcs = fitshead2wcs(index)
  
  loadct,3
  seismo_corona_show_status, ev, 'Click at the first footpoint (or between the loop footpoints)'
  cursor,x1,y1,/data,/down
  plots,x1,y1, psym = 2, color =150
  seismo_corona_show_status, ev, 'Click at the second footpoint (orst the loop apex)'
  cursor,x2,y2,/data,/down
  plots,x2,y2, psym = 2, color = 150
  loadct,0
  
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
  
  wcs_convert_from_coord, wcs, points, 'hcc', points_x, points_y 
  d_loop = sqrt((points_x[1] - points_x[0])^2 + (points_y[1] - points_y[0])^2)
  length = !dpi * d_loop * 1d-6
  print, 'loop length',length
  return, length
  
  stop

end

function seismo_corona_time_distance_ellipse, ev, x_data, y_data, frame = frame, points = points, n_slit = n_slit, current_plot = current_plot
  compile_opt idl2
  common seismo_corona  
  data = global['data']
  sz = size(data)
  nx = sz[1]
  ny = sz[2]
  nt = sz[3]
  
  if not keyword_set(x_data) then begin
    x_data = findgen(nx)
  endif
  
  if not keyword_set(y_data) then begin
    y_data = findgen(ny)
  endif
  
  if not keyword_set(frame) then frame = 0
  if not keyword_set(current_plot) then implot,comprange(data[*,*,frame]),/iso
  loadct, 3
  if not keyword_set(points) then points = click_points(color = 150)
  loadct, 0
  ell = fit_ellipse_2d(points)
  n_ell = n_elements(ell.x)
  ; distance between nodes
  dl = sqrt((ell.x[1:*] - ell.x[0:-2])^2 + (ell.y[1:*] - ell.y[0:-2])^2)
  ;length along the loop
  l = [0d,total(dl,/cum)]
  ;index of the ellipse nodes
  ind = dindgen(n_ell)
  n_td = round(l[-1])+1d
  dl =l[-1]/(n_td -1d)
  
  slit_l =dindgen(n_td)*dl
  slit_ind = interpol(ind,l,slit_l)
  
  slit_x = interpolate(ell.x,slit_ind)
  slit_y = interpolate(ell.y,slit_ind)
  
  slit_x_px = interpol(findgen(nx),x_data,slit_x)
  slit_y_px = interpol(findgen(ny),y_data,slit_y)
  
  
  if not keyword_set(n_slit) then n_slit = 100
  
  td = dblarr(nt, n_td, n_slit)
  
  dx = deriv(slit_x_px)
  dy = deriv(slit_y_px)
  
  norm = sqrt(dx^2+dy^2)
  dx/= norm
  dy/=norm
  
  w =1.5d
  
  x_norm =-dy
  y_norm = dx
  
  l_norm = dindgen(n_slit) - (n_slit -1d)*0.5d
  for t = 0 , nt-1 do begin
    ;   ; TD[T,*] = INTERPOLATE(REFORM(DATA[*,*,T]),SLIT_X,SLIT_Y, CUBIC = -0.5)
    ;   TD1 = INTERPOLATE(REFORM(DATA[*,*,T]),SLIT_X1,SLIT_Y1, CUBIC = -0.5)
    ;   TD2 = INTERPOLATE(REFORM(DATA[*,*,T]),SLIT_X2,SLIT_Y2, CUBIC = -0.5)
    ;   TD0 = INTERPOLATE(REFORM(DATA[*,*,T]),SLIT_X,SLIT_Y, CUBIC = -0.5)
    ;   TD[T,*] =  (td1-td2)/(td1+td2)
    for i =0, n_slit -1 do begin
      td[t,*,i]  = INTERPOLATE(REFORM(DATA[*,*,t]),SLIT_X_px + x_norm*l_norm[i],SLIT_Y_px + y_norm*l_norm[i], CUBIC = -0.5)
    endfor
    seismo_corona_show_status, ev, "Making time-distance plots... " + strcompress(round(float(t*100.)/float(nt-1)))+'%'
  endfor
  
  x1 = SLIT_X_px + x_norm*l_norm[0]
  y1 = SLIT_y_px + y_norm*l_norm[0]
  x2 = SLIT_X_px + x_norm*l_norm[n_slit -1]
  y2 = SLIT_y_px + y_norm*l_norm[n_slit -1]
  
  x1_data = interpol(x_data,findgen(nx),x1)
  y1_data = interpol(y_data,findgen(ny),y1)
  x2_data = interpol(x_data,findgen(nx),x2)
  y2_data = interpol(y_data,findgen(ny),y2)
  
  
  oplot, slit_x, slit_y
  result = hash()
  result['x']     = slit_x
  result['y']     = slit_y
  result['data']  = td
  result['x1']    = x1_data
  result['x2']    = x2_data
  result['y1']    = y1_data
  result['y2']    = y2_data
  return, result
end

pro seismo_corona_routines
compile_opt idl2

end