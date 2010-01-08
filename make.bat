@del .deps
@del *.moduleDeps
xfbuild main.d +obin\SpriteViewer -debug -g -Isfml2/DSFML/import

cv2pdb -D2 bin\Spriteviewer.exe