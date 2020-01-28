set PATH=C:\Tools\ldc2-1.20.0-beta1-windows-x64\bin;%PATH%

@REM -unittest -debug -g
rdmd --build-only -wi -O -inline unbox.d
rdmd --build-only -wi -O -inline m10decoder.d
rdmd --build-only -wi -O -inline mfbdecoder.d
