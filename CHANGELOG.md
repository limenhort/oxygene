## 1.0.1

* Updated package description to English.
* Added `isComplex` and `willChange` hints to `CustomPaint` for better rendering performance.

## 1.0.0

* Initial release.
* `Oxygene` widget — a read-only, non-interactive preview that renders an
  L-system / turtle-graphics tree from a genome string and fits it to its box.
* Accepts both the plain genome form and the compact short form
  (`<old> || <buffer> | <count>`); the widget expands the short form itself.
* Configurable `width`, `height`, `backgroundColor`, and `leafScale`.
* Invalid genomes fail soft (truncated/blank tree, never a thrown exception).
