This is a simple cv and pdf renderer i wrote over the weekend, il immprove it as i go.

TODO:
 - Add support for fonts
  - Add monospaced font
 - Add support for newlines in the stream_renderer
 - Center "non-comptime" text
 - Seperate out the pdf renderer and make it a real lib
 - Dynamic scaling buffer for content_stream

Possible api design
```
main {
  mpdf = pdf.init();
  page = try mpdf.addPage();
  try page.Write("Foobar baz\n");

  renderer = pdf.Renderer.init(stdout)
  renderer.Render(pdf);
}
```


Resources used:
https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art019
