This is a simple cv and pdf renderer i wrote over the weekend, il immprove it as i go.

to build:
```
$ nix run > output.pdf
```

## TODO
### CV
 - Add monospaced fon
 - Add light mode scheme
### Library
 - Add support for fonts
 - Add support for embeding fonts
 - Add support for newlines in the stream_renderer
 - Center "non-comptime" text
 - Seperate out the pdf renderer and make it a real lib
 - Dynamic scaling buffer for content_stream
 - Draw images

Resources used:
 - https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art019
 - https://stuff.mit.edu/afs/sipb/contrib/doc/specs/software/adobe/pdf/PDFReference16-v4.pdf
