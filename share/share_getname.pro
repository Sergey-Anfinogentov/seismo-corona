function share_getname,var
  help,var,out=out
  name=(stregex(out,'SharedMemory<(.+)>',/subexpr,/extr))[1]
  return,name
end