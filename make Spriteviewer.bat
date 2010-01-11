@del .deps
@del *.moduleDeps
xfbuild spriteviewer.d +obin\SpriteViewer -debug -g

cv2pdb -D2 bin\Spriteviewer.exe