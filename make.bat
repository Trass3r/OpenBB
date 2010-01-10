@del .deps
@del *.moduleDeps
xfbuild spriteviewer.d +obin\SpriteViewer -debug -g
xfbuild openbb.d +obin\OpenBB -debug -g

cv2pdb -D2 bin\Spriteviewer.exe
cv2pdb -D2 bin\OpenBB.exe