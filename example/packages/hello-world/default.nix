{ stdenv }:

stdenv.mkDerivation {
  name = "hello-world";

  buildCommand = ''
    echo '#!/bin/bash' > $out
    echo 'echo "Hello, World!"' >> $out
    chmod +x $out
  '';
}
