@del .deps
@del *.moduleDeps /Q
@del .objs /Q
@del *.rsp /Q

@rem xfbuild m10decoder.d +v +xcore +xstd +obin\m10decoder -wi -unittest -debug -g && cv2pdb -D2 bin\m10decoder.exe
xfbuild m10decoder.d +v +xcore +xstd +obin\m10decoder -release -O -inline