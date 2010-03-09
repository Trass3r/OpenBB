@del .deps
@del *.moduleDeps
xfbuild +full spriteviewer.d +obin\SpriteViewer -debug -g

cv2pdb -D2 bin\Spriteviewer.exe