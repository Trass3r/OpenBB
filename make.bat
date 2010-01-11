@del .deps
@del *.moduleDeps
xfbuild main.d +obin\OpenBB -debug -g

cv2pdb -D2 bin\OpenBB.exe