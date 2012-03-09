require "sketchup.rb"

# LDraw Export 1.0
# by Jim DeVona
# 1 February 2011
#
# This is a plugin for Google SketchUp (http://sketchup.google.com/).
# To install, put this file in your SketchUp plugins folder. Where's that? See here:
# See http://sketchuptips.blogspot.com/2008/03/how-to-download-and-install-plugins.html
# (Note on Mac OS X you can also use your user ~/Library instead of your system /Library)
# Restart SketchUp, and an "Export to LDraw…" item should now appear in the Plugins menu.
# 
# Credits:
#  - Based on Jim Foltz' Su2LDraw script, which has more features, including
#    importing LDraw models to SketchUp. http://sites.google.com/site/jimfoltz02/su2ldraw
#    Check out Jim's blog for other cool SketchUp stuff: http://sketchuptips.blogspot.com/
#
# References:
#  - SketchUp Ruby API: http://code.google.com/apis/sketchup/docs/
#  - LDraw File Format Specification: http://www.ldraw.org/specs/fileformat/ - oops, I mean http://www.ldraw.org/Article218.html
#
# Scale & Orientation:
#  - Per http://www.ldraw.org/Article218.html#coords "Real World Approximations", this script
#    assumes 1 LDU = 0.4 mm and converts units on export accordingly. In other words, model bricks
#    as life-size in SketchUp and they will be exported with correct LDraw units. An example:
#    Brick 1 x 1 (3001.dat) has an 8 mm footprint and is 9.6 mm tall not including stud.
#  - SketchUp and LDraw coordinate systems are slightly different. In general, for easiest results,
#    rotate your SketchUp model down 90 degrees around X axis before export (or just build that way).
#
# Limitations:
#  - Too many to list. Don't assume you can just export any SketchUp model and have an LDraw version;
#    it won't work. See code and comments below for details on how it works and what it doesn't do.
#
# License:
#  - Use this to have fun and build things. There are no restrictions. Don't restrict anybody else. There.

module LDraw
	
	#
	# export
	#
	def self.export()

		# should suggest LDraw filename based on SketchUp model name
		# "~" is the default directory... not sure if cross-platform
		file = UI.savepanel("Export to LDraw", "~", "untitled.dat")
		fp = File.open(file, "w")
		
		# what are we going to export? if there is a selection, only that.
		# otherwise, everything. Handling of Components, Groups, etc., is presently undefined.
		model = Sketchup.active_model
		if model.selection.empty?
			entities = model.active_entities
		else
			entities = model.selection
		end
		
		# output faces
		fp.puts "0 // Faces"
		faces = entities.select {|e| e.typename == "Face"}
		faces.each do |face|
			fp.puts(exportFace(face))
		end
		
		# output edges
		fp.puts "0 // Edges"
		edges = entities.select {|e| e.typename == "Edge"}
		edges.each do |edge|
			
			# determine what sort of edge this
			soft = edge.soft?
			smooth = edge.smooth?
			if (!soft && !smooth)
				# it's a regular edge!
				conditional = false
			elsif (soft && smooth)
				# conditinal edges are fully hidden
				conditional = true
			else
				# edges that are soft but not smooth or
				# smooth but not soft are not exported
				next
			end
			
			fp.puts(exportEdge(edge, conditional))
			
		end
		
		ensure
		fp.flush
		fp.close
		
	end
	
	#
	# exportFace
	#
	def self.exportFace(face)
		
		line = ""
		vertices = face.vertices.flatten
		
		# output appropriate face type followed by main color code,
		# or output vertices as comment if it needs to be split
		if vertices.length > 4
			line << "0 // Too many vertices:"
		elsif vertices.length == 3
			# triangular face
			line << "3 16"
		elsif vertices.length == 4
			# quadrilateral face
			line << "4 16"
		end
		
		# output each vertices
		vertices.each {|v|
			line << sprintf(" %8.4f", v.position.x.to_f.to_mm * 2.5)
			line << sprintf(" %8.4f", v.position.y.to_f.to_mm * 2.5)
			line << sprintf(" %8.4f", v.position.z.to_f.to_mm * 2.5)
		}
		
		line << "\n"
		line
		
	end
	
	#
	# exportEdge
	#
	def self.exportEdge(edge, conditional)
		
		# output approriate edge type followed by edge color code
		if conditional
			line = "5 24"
		else
			line = "2 24"
		end
		
		# an edge has two vertices; get the position of each
		svp = edge.start.position
		evp = edge.end.position
		
		# output the edge position (same for regular and conditional edges)
		line << sprintf(" %8.4f", svp.x.to_f.to_mm * 2.5)
		line << sprintf(" %8.4f", svp.y.to_f.to_mm * 2.5)
		line << sprintf(" %8.4f", svp.z.to_f.to_mm * 2.5)

		line << sprintf(" %8.4f", evp.x.to_f.to_mm * 2.5)
		line << sprintf(" %8.4f", evp.y.to_f.to_mm * 2.5)
		line << sprintf(" %8.4f", evp.z.to_f.to_mm * 2.5)
		
		# output conditional edge control points
		if conditional
			
			# Consult http://www.ldraw.org/Article218.html#lt5 for more information
			# about conditional edges (aka optional lines). Essentially, they are lines
			# that should only be rendered in certain conditions: when both control points
			# appear on screen on the same side of the line (suppose the edge is an infinite
			# line). Conventionally, the assumption is the conditional edge lies on a curved
			# surface and that the control points lie on adjacent facets of that surface.
			#
			# Here, we automatically pick control points for conditional edges by selecting
			# non-shared vertices from two adjacent faces. IMPORTANT NOTE: edges in SketchUp
			# may have less than or more than two adjacent faces! At present, this code
			# assumes the model has been carefully prepared such that every conditional line
			# has exactly two adjacent faces. It will fail if less than two and may not pick
			# an appropriate control point if more than two. (Rudimentary check should be
			# for faces.length == 2, and maybe output as a comment as with polygonal faces.)
			
			# get two adjacent faces
			faces = edge.faces
			f1 = faces[0]
			f2 = faces[1]
			
			# Get vertex positions of faces, not including vertices at this edge's endpoints.
			# (This code gets a list of vertices and replaces each vertex object with the
			# desired vertex position, or nil if the vertex position is shared with the edge.
			# The nils are then removed from the list via .compact, leaving potential control points.)
			f1p = f1.vertices.collect {|v| ((v.position == svp) || (v.position == evp)) ? nil : v.position}.compact
			f2p = f2.vertices.collect {|v| ((v.position == svp) || (v.position == evp)) ? nil : v.position}.compact

			# any one of the remaining face vertex positions will suffice for control points
			# (if the face is triangle, there is only one vertex position left anyway)
			cp1 = f1p[0]
			cp2 = f2p[0]
			
			# output the control points
			line << sprintf(" %8.4f", cp1.x.to_f.to_mm * 2.5)
			line << sprintf(" %8.4f", cp1.y.to_f.to_mm * 2.5)
			line << sprintf(" %8.4f", cp1.z.to_f.to_mm * 2.5)
	
			line << sprintf(" %8.4f", cp2.x.to_f.to_mm * 2.5)
			line << sprintf(" %8.4f", cp2.y.to_f.to_mm * 2.5)
			line << sprintf(" %8.4f", cp2.z.to_f.to_mm * 2.5)
			
		end
		
		line << "\n"
		line
		
	end
					
	#
	# Register plugin
	#
	scriptName = File.basename(__FILE__)
	unless file_loaded?(scriptName)
		pluginsMenu = UI.menu("Plugins")
		pluginsMenu.add_item("Export to LDraw…") {LDraw.export()}
		file_loaded(scriptName)
	end

end

