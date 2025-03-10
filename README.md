# ZigCV

[![Formating](https://github.com/Miniwoffer/zigcv/actions/workflows/format.yml/badge.svg)](https://github.com/Miniwoffer/zigcv/actions/workflows/format.yml)
[![Unittest](https://github.com/Miniwoffer/zigcv/actions/workflows/unittest.yml/badge.svg)](https://github.com/Miniwoffer/zigcv/actions/workflows/unittest.yml)

This is a simple cv and pdf renderer i wrote over the weekend, il immprove it as i go.

to build:
```
$ nix run > output.pdf
```
or to build a ligth_theme version run:
```
$ nix run .#light_theme > output.pdf
```
You can also create your own theme in `./themes/` and running:
```
$ nix develop
$ zig build -Dgit_commit=$(git rev-parse HEAD) -Dtheme_path=./themes/<my_theme>.json run
```

## TODO
### CV
 - [ ] Add monospaced font
 - [X] Add light mode scheme
 - [ ] Setup gitlab ci to bulid CV
 - [X] Move content into a folder
 - [X] Write "ReadJSONFile" util
### Library
 - [X] Add support for fonts
 - [X] Add "zig fmt" test
 - [ ] Add support for embeding fonts
 - [ ] Add support for newlines in the stream_renderer
 - [ ] Center "non-comptime" text
 - [ ] Seperate out the pdf renderer and make it a real lib
 - [ ] Dynamic scaling buffer for content_stream
 - [ ] Draw images
 - [ ] Rewrite content_stream renderer to be "command" based
 - [X] Use new renderer
 - [ ] Change naming of "render" to "serialize"
 - [ ] Add null support for indirect referance
 - [ ] Extend objects too support all entries in PDF 16
   - [ ] catalog
   - [ ] content_stream
   - [ ] font
   - [ ] pages
   - [ ] page

## Some of the resources used
 - https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art019
 - https://stuff.mit.edu/afs/sipb/contrib/doc/specs/software/adobe/pdf/PDFReference16-v4.pdf
