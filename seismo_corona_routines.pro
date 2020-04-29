function osc_spline_trend, x, period, phi, tstart, trend_y, trend_x = trend_x
  omega = 2.d*!dpi/period
  t_shift = tstart - (phi -!pi)/omega
  n_trend_x = n_elements(trend_y) - 2
  trend_x = dindgen(n_trend_x)*period + t_shift
  ind = where(trend_x lt x[-1])
  trend_x = trend_x[ind]
  trend_x = [x[0],trend_x,x[-1]]
  n = n_elements(trend_x)
  return,spline(trend_x, trend_y[0:n-1], x)
end
function osc_decayless, t, a,_extra = _extra, get_parnames = get_parnames
  common trend_par, n_trend
  if keyword_Set(get_parnames) then begin
    return,['period','amplitude','displacement','trend_'+strcompress(indgen(n_trend),/remove_all)]
  endif
  travel_time = a[0]
  amp1 = a[1]
  displ =a[2]
  trend_y = a[3:3+n_trend - 1]
  tstart = t[0]
  tosc=t-tstart
  period1 = travel_time/1d
  omega1 = 2.d*!dpi/period1
  phi = asin((displ))
  sinusoid1=amp1*sin(omega1*tosc +phi)
  trend = osc_spline_trend(t, period1, phi, tstart, trend_y, trend_x = trend_x)
  return, sinusoid1 + trend
end
function fit_decayless, t, y, params = params, credible_intervals = credible_intervals, samples = samples
  common trend_par
  n_trend = 4
  max_period = (t[-1] - t[0])*0.5
  period_limits = reform([2d, max_period], 1, 2)
  ampl_limits = reform([0.01d, 10d], 1, 2)
  displ_limits = reform([-1d,1d], 1, 2)

  trend_limits = minmax(y)
  ;trend_limits += (trend_limits[1] - trend_limits[0])*[-0.9, 0.9]
  trend_limits = rebin(reform(trend_limits,1, 2 ), n_trend, 2)

  limits = [period_limits, ampl_limits, displ_limits, trend_limits]
  limits0 = limits

  model = 'osc_decayless'
  y_fit = mcmc_fit(t, y, a, limits, model, n_samples = 200000l,$
    burn_in = 100000l, samples = samples, ppd_samples = ppd_samples, values = values,credible_intervals = credible_intervals)

  params = a
  
  result = hash()
  result['fit'] = y_fit
  result['estimate'] = params
  result['parnames'] = call_function(model,/get_parnames)
  result['credible_intervals'] = credible_intervals
  result['samples'] = samples
  result['p_values'] = values

  return, result

end


function seismo_corona_read_data, file_name
compile_opt idl2

end

function seismo_corona_get_td, loop_index, slit_num, slit_width
compile_opt idl2
common seismo_corona 
     
  if slit_width eq 1 then begin
    td = reform(global['loops', loop_index, 'data', *, slit_num, *])
  endif else begin
    w_2 = (slit_width-1)/2
    length = n_elements(global['loops', loop_index, 'data',0,*,0])&
    slit_st = (slit_num - w_2)>0
    slit_en = (slit_num + w_2)<(length-1)
    td = total(global['loops', loop_index, 'data', *, slit_st:slit_en, *],2)
  endelse
  return, td
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

function loop_profile, x, p
  n_poly =2
  Amplitude = p[0]
  centre =p[1]
  sigma = p[2]
  c_bg = p[3:3+n_poly-1]
  
  background = poly(x, c_bg)
  loop =amplitude * exp(-((x-centre)/sigma)^2)
  
  return, background + loop
  
end

pro fit_loop_profile, x, profile, centre, sigma, amplitude
  nx = n_elements(x)
  n_poly = 2
  start_amplitude =(max(profile) - min(profile))*0.8d
  start_centre = x[nx/2]
  start_sigma = 1d
  start_bg =replicate(0d,n_poly)
  start_bg[0] = median(profile)
  
  start_params = [start_amplitude, start_centre, start_sigma, start_bg]
  
  par_info = replicate({value:0d,fixed:0,limited:[1,1],limits:[0d,1d]},3+n_poly)
  par_info.value = start_params
  par_info[0].limits = [0d,max(profile) - min(profile)]
  par_info[1].limits = start_centre + [-5.,5.];minmax(x)
  par_info[2].limits = [0.3d,3d];[1d,(max(x)-min(x))*0.5d]
  for i = 3, 3+n_poly-1 do par_info[i].limited = [0,0]
  
  fit_par = mpfitfun('loop_profile',x,profile, error,parinfo = par_info, weights = 1d, /quiet)
  
  centre = fit_par[1]
  sigma = fit_par[2]
  amplitude = fit_par[0]
  
end



pro track_loop, xfit,yfit, n_poly = n_poly
  if not keyword_set(n_poly) then n_poly =1
  
  x=0.
  y=0.
  print,'Use mouse to mark an oscillating loop. Click right button when finish'
  for i=0, 50 do begin
  
    cursor,x0,y0,/data,/down
    if !MOUSE.button eq 4 then break
    x=[x,x0]
    y=[y,y0]
    oplot,[x0],[y0],psym=1, color = 255
    
  endfor
  
  
  x=x[1:*]
  y=y[1:*]
  ; sort clicked points
  ind=sort(x)
  x=x[ind]
  y=y[ind]
  
  a=mean(abs((y-shift(y,1))[1:*]))*0.5
  yl=0.5*((y+shift(y,1))[1:*])
  xl=0.5*((x+shift(x,1))[1:*])
  
  n_poly = (n_elements(x) - 2)<2
  
  
  max_x = max(x)
  min_x = min(x)
  nx = max_x - min_x + 1
  xx=findgen(nx)/nx*(max(x)-min(x))+min(x)
  xfit = xx
  if n_elements(x) le 3 then begin
    c = linfit(x,y) 
    yfit=poly(xx,c)
    return
  endif; else  c=poly_fit(xl,yl,n_poly)
  yfit = spline(x,y,xx)
  
end



;+
; :Description:
;    Interactively measure positions of a coronal loop in time-distance map by fitting
;    a Gausian to the intencity profile at each instant of time
;
; :Usage:
;   IDL> measure_loop_position, td , time, centre, sigma, amplitude
;   A time-distance map will be plotted in the current window
;   Click some points with the left mouse button on the loop profile visible in the
;   time-distance map. Minimum 2 points should be clicked.
;   Click the right mouse button when finis.
;
; :Params:
;    td_map - (input) an arrayt containing time-distance map to analyse (can be constructed
;             using a long slit crossing multiple loops a long slit)
;    time - (output) time coordinate of the fitted loop positions
;    centre - (output) fitted loop positions
;    sigma - (output) a width of the gaussian fitted to the intensity profile
;    amplitude - (output) amplitude of the Gaussian fitted to the intensity profile
;
;
;
; :Author: Sergey Anfinogentov (sergey.istp@gmail.com)
;-
pro seismo_corona_measure_loop_position, ev, td_map, time, centre,sigma, amplitude
  compile_opt idl2
  common seismo_corona

  ;half length of the profile to fit [pixels]
  x_width = 7
  
  ;polynomial degree to fit the points putted by hand to track slow motions of the loop
  
  sz=size(td_map)
  
  ; window,xsi = 800,ysi = 400
  sz = size(td_map)
  x = findgen(sz[2]) ;* dx
  t = findgen(sz[1]) ;* dt
  
  ;
  
  
  ;2 or 3 clicks -> linear fit
  ;more than 3 clicks -> polynomial fitmeasure_loop_position, td_map, time, centre,sigma, amplitud
  ;
  track_loop,t_loop, x_loop,n_poly = n_poly
  
  oplot, t_loop, x_loop
  tran = round(minmax(t_loop))
  nt = tran[1] - tran[0]+1
  
  centre = dblarr(nt)
  time = dindgen(nt)+tran[0]
  sigma = centre
  error = centre
  amplitude =centre
  
  for i= 0, nt -1d do begin
  
    xst = (x_loop[i] - x_width); > 0
    xen = (x_loop[i] + x_width); < ((size(data))[2]-1)
    x_coord = findgen(xen-xst+1)+xst
    profile = interpolate(td_map,replicate(time[i],xen-xst+1),x_coord);td_map[t_loop[i], xst:xen]
    
    
    ; revert the profile is the loop looks dark
    ;if abs(min(profile)) gt abs(max(profile)) then profile *= -1
    
    ;fit loop profile with gaussian
    fit_loop_profile, x_coord, profile, centre_i, sigma_i, amplitude_i
    sigma[i]=sigma_i
    centre[i]=centre_i
    ;error[i]=error_i
    amplitude[i]=amplitude_i
  endfor
  
  oplot,time, centre, psym =1, color = 0
  
  
end

function seismo_corona_get_current_loop, ev
compile_opt idl2
common seismo_corona
  loop_list = widget_info(ev.top, find_by_uname = 'loop_list')
  loop_index = widget_info(loop_list, /LIST_SELECT)
  if loop_index lt 0 then loop_index = 0
  return, loop_index
end

pro seismo_corona_set_curent_loop, ev, loop_index
  compile_opt idl2
  common seismo_corona
  loop_list = widget_info(ev.top, find_by_uname = 'loop_list')
  loop_count = global['loops'].count()
  widget_control, loop_list, set_value = 'loop '+ strcompress(indgen(loop_count),/remove_all)
   widget_control, loop_list, SET_LIST_SELECT = loop_index
end

pro seismo_corona_routines
compile_opt idl2

end