# ldraw_sketchup.rb

This is a plugin for [Google SketchUp](http://sketchup.google.com/). It exports models to [LDraw](http://www.ldraw.org/) format - see Notes and Limitations below. ("LDraw is an open standard for LEGO CAD programs that allow the user to create virtual LEGO models and scenes.") It is intended to facilitate drafting of complex shapes using SketchUp's interactive geometry tools. Some manual touch-up of the output is typically required to meet LDraw library [standards](http://ldraw.org/Article292.html).

## Examples:

[![92579 progress](http://farm6.staticflickr.com/5090/5379959518_2b1a35e26c_m.jpg)](http://www.flickr.com/photos/anoved/5379959518/) [![92579 progress 2](http://farm6.staticflickr.com/5127/5379545295_03aca86723_m.jpg)](http://www.flickr.com/photos/anoved/5379545295/)

See [this Flickr gallery](http://www.flickr.com/photos/anoved/sets/72157625885422202/detail/) for more images of this part (`92579.dat`) being developed in SketchUp.

## Installation:

To install, put this file in your SketchUp plugins folder. ([Where's that?](http://sketchuptips.blogspot.com/2008/03/how-to-download-and-install-plugins.html) Note that on Mac OS X you can also use your user `~/Library` instead of your system `/Library`.) Restart SketchUp, and an *Export to LDraw…* item should now appear in the *Plugins* menu.

## Credits:

 - Based on Jim Foltz' [Su2LDraw](http://sites.google.com/site/jimfoltz02/su2ldraw) script, which has more features, including importing LDraw models to SketchUp. Check out [Jim's blog](http://sketchuptips.blogspot.com/) for other cool SketchUp stuff.

## References:

 - SketchUp Ruby API: <http://code.google.com/apis/sketchup/docs/>
 - LDraw File Format Specification: <http://www.ldraw.org/Article218.html>

## Notes on Scale, Orientation, and Edges:

 - Per <http://www.ldraw.org/Article218.html#coords> "Real World Approximations", this script assumes 1 LDU = 0.4 mm and converts units on export accordingly. In other words, model bricks as life-size in SketchUp and they will be exported with correct LDraw units. An example: Brick 1 x 1 (3001.dat) has an 8 mm footprint and is 9.6 mm tall not including stud.
 - SketchUp and LDraw coordinate systems are slightly different. In general, for easiest results, rotate your SketchUp model down 90 degrees around X axis before export (or just build that way).
 - SketchUp lines marked as *soft* and *smooth* are exported as LDraw conditional lines (used to draw the edge of "curved" surfaces when appropriate). Lines that are neither soft nor smooth are exported as regular LDraw lines (always drawn). Lines that are soft xor smooth are not exported.

## Limitations:

 - Too many to list. **Don't assume you can just export any SketchUp model and have an LDraw version; it won't work.** You need to prepare your SketchUp model with LDraw export in mind. (This entails things like ensuring conditional lines have exactly two adjacent faces.) See code and comments for details on how it works and what it doesn't do.

## License:

 - Use this to have fun and build things. There are no restrictions. Don't restrict anybody else. There.
