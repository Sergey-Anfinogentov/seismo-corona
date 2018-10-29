function ellipse_xy2phi,x,y,ell
  tilt_angle = ell[4]
  x_scale = ell[0]
  y_scale = ell[1]
  xc = ell[2]
  yc = ell[3]
  t3d,/reset , matrix = matrix
   t3d, matrix, scale = [1d/x_scale, 1d/y_scale, 0d], matrix= matrix
  t3d, matrix, rotate = [0.d, 0d, -tilt_angle*!radeg], matrix = matrix 
  crd = ssrt_transform(matrix, x - xc, y -yc, x*0d)
  phi = atan(crd.y, crd.x)

  foo = convol(phi,[-1.,1.])
  ind = where(abs(foo) lt (1.*!pi))
  foo[ind] =0.
  ind = where(foo lt 0)
  if ind[0] ne -1 then  foo[ind] = -2*!pi
  ind = where(foo gt 0)
  if ind[0] ne -1 then foo[ind] = 2*!pi
  phi -= total(foo,/cum)
  return ,phi
end

function fit_ellipse_2d, points, n = n
  if not keyword_set(n) then n =128
  
  ell=mpfitellipse(points.x,points.y,/tilt,quiet=1) 
  phi = ellipse_xy2phi(points.x,points.y,ell)

  phip = linspace(phi[0],phi[-1],n);dindgen(n)/n*(phi[-1]- phi[0]) + phi[0]
  xr = ell[2] + ell[0]*cos(phip)*cos(ell[4]) + ell[1]*sin(phip)*sin(ell[4]) ; Returns fitted ellipse
  yr = ell[3] - ell[0]*cos(phip)*sin(ell[4]) + ell[1]*sin(phip)*cos(ell[4])
  return,{x:xr, y:yr}
end