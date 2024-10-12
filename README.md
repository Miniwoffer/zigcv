

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
