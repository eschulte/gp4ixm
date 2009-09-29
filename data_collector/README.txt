Here's a 'standaloneish' version of the 'Connection Direction
Detection' code.

How to run the demo:

 - Initialize a sketch directory however you do that.

 - Copy all the contents of this directory into that sketch directory,
   with this sketch.pde and Makefile displacing the default files, if
   they exist.

 - Adjust the first line of the Makefile to point BASEDIR at your SFB
   tree. 

 - Try the make.  The difference in this makefile is that it builds
   Grid2D.cpp and CDD.cpp as well as the sketch.

 - If you're using ant, you'll need to adjust its build file to do the
   same.  I haven't tried that yet.

 - Burn the sketch as usual.

 - Watch the output, push the buttons, read the sketch.pde.
