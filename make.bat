@del .deps
@del *.moduleDeps /Q
@del .objs /Q
@del *.rsp /Q

xfbuild main.d +v +xcore +xstd +obin\OpenBB-d -wi -unittest -debug -g

cv2pdb -D2 bin\OpenBB-d.exe