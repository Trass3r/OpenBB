@del .deps
@del *.moduleDeps
xfbuild main.d +v +obin\OpenBB-d -debug -g

cv2pdb -D2 bin\OpenBB-d.exe