# NewNewTerm
This is a rewrite of the original NewTerm/Mobile Terminal project. Mobile Terminal’s codebase dates from the iPhone OS 2.0 – 3.0 era, and prior to this it was written for iPhone OS 1.0 (before an official SDK existed). There have been many significant improvements to iOS frameworks since then, so it was decided the best way to go from here was to rewrite the majority of the app.

The original terminal emulation backend based on a port of the original [iTerm](http://iterm.sourceforge.net/) is being upgraded to a port of a recent version of [iTerm2](http://iterm2.com/). This will hopefully provide more reliable and up-to-date terminal emulation, and also provides some of iTerm2’s [extended features](http://iterm2.com/documentation.html).

Compilation is done with Theos. Xcode project is included for convenience; no point in using it for compilation since the app is pretty useless within a sandbox.

## License
Licensed under the GNU General Public License, version 2.0. Refer to [LICENSE.md](LICENSE.md).
