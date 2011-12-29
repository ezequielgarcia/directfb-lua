#!/usr/bin/perl
#use strict;  # Enforce some good programming rules

#######################
## Package variables ##
#######################

$pkgname = "directfb";
$src_dir = "./src/";

#########################
## Interface blacklist ##
#########################
$blacklist{"IDirectFBEventBuffer"}		= 1;
$blacklist{"IDirectFBPalette"}			= 1;
$blacklist{"IDirectFBGL"}				= 1;
$blacklist{"IDirectFBGL2"}				= 1;
$blacklist{"IDirectFBGL2Context"}		= 1;
$blacklist{"IDirectFBScreen"}			= 1;
	
########################
## Function blacklist ##
########################
$blacklist{"GetClipboardData"}			= 1;
$blacklist{"GetGL"}						= 1;
$blacklist{"Lock"}						= 1;
$blacklist{"Unlock"}					= 1;
$blacklist{"GetProperty"}				= 1;
$blacklist{"RemoveProperty"}			= 1;
$blacklist{"GetStringBreak"}	 		= 1;
$blacklist{"SetStreamAttributes"} 		= 1;
$blacklist{"SetBufferThresholds"} 		= 1;
$blacklist{"SetClipboardData"}	 		= 1;
$blacklist{"GetClipboardTimeStamp"}		= 1;
$blacklist{"Write"} 					= 1;
$blacklist{"PutData"} 					= 1;
$blacklist{"SetColors"}					= 1;
$blacklist{"TextureTriangles"}			= 1;
$blacklist{"SetIndexTranslation"}		= 1;
$blacklist{"SetMatrix"}					= 1;
$blacklist{"SetSrcColorMatrix"}			= 1;
$blacklist{"SetKeySelection"}			= 1;
$blacklist{"Read"}						= 1;
$blacklist{"GetInterface"}				= 1;
$blacklist{"EnumInputDevices"}			= 1;
$blacklist{"EnumDisplayLayers"}			= 1;
$blacklist{"EnumScreens"}				= 1;
$blacklist{"EnumVideoModes"}			= 1;
$blacklist{"SetProperty"} 				= 1;
$blacklist{"EnumEncodings"} 			= 1;
$blacklist{"SetRenderCallback"} 		= 1;
$blacklist{"GetData"} 					= 1;
$blacklist{"PeekData"} 					= 1;
$blacklist{"GetDeviceDescription"}		= 1;
$blacklist{"CreatePalette"}				= 1;
$blacklist{"CreateDataBuffer"}			= 1;
$blacklist{"CreateEventBuffer"}			= 1;
$blacklist{"DetachEventBuffer"}			= 1;
$blacklist{"AttachEventBuffer"}			= 1;
$blacklist{"SetSrcGeometry"}			= 1;
$blacklist{"SetDstGeometry"}			= 1;
$blacklist{"GetPalette"}				= 1;
$blacklist{"SetPalette"}				= 1;
$blacklist{"SetDstGeometry"}			= 1;
$blacklist{"CreateInputEventBuffer"}	= 1;
$blacklist{"SendEvent"}					= 1;
$blacklist{"GetScreen"}					= 1;
$blacklist{"GetKeymapEntry"}			= 1;
$blacklist{"SetKeymapEntry"}			= 1;
$blacklist{"SetRop"}					= 1;
$blacklist{"SetSrcColorKeyExtended"}	= 1;
$blacklist{"SetDstColorKeyExtended"}	= 1;
$blacklist{"DrawMonoGlyphs"}			= 1;
$blacklist{"SetSrcConvolution"}			= 1;

###############
## Utilities ##
###############

sub trim ($) {
	local (*str) = @_;

	# remove leading white space
	$str =~ s/^\s*//g;

	# remove trailing white space and new line
	$str =~ s/\s*$//g;
}

sub string_to_flag {
	my ($enum, $name) = @_;
	my $val = 0;

	foreach my $entry (@{$types{$enum}->{ENTRIES}}) {
		
		if ($entry =~ /\w*$name\w*/i) {
			return $entry;
		}
	}

	return $val;
}

#####################
## Code Generation ##
#####################

sub generate_enum_check {

	my ($enum) = @_;

	# enum build function
	print ENUMS_C "static void build_$enum(lua_State *L)\n",
				  "{\n",
				  "\tlua_newtable(L);\n";

	foreach (@{$types{$enum}->{ENTRIES}}) {
		print ENUMS_C "\tlua_pushnumber(L, $_);\n",
					  "\tlua_setfield(L, -2, \"$_\");\n";
	}

	print ENUMS_C "\tlua_setfield(L, -2, \"$enum\");\n",
				  "}\n\n";

	# check function
	print ENUMS_H "DLL_LOCAL ${enum} check_${enum} (lua_State *L, int index);\n";
	print ENUMS_C "DLL_LOCAL ${enum} check_${enum} (lua_State *L, int index)\n",
			      "{\n",
				  "\tint result = 0;\n",
				  "\tconst char *str;\n",
				  "\tif (lua_isnoneornil(L, index))\n",
				  "\t\treturn 0;\n",
				  "\tif (lua_isnumber(L, index))\n",
				  "\t\treturn luaL_checknumber(L, index);\n",
				  "\tstr = luaL_checkstring(L, index);\n",
				  "\tlua_getglobal(L, \"$pkgname\");\n",
				  "\tlua_getfield(L, -1, \"$enum\");\n",
				  "\tresult = string2enum(L, str, \"$enum\");\n",
				  "\treturn result;\n",
				  "}\n\n";
}

sub generate_struct_check {

	my ($struct) = @_;
	my $hasflags = $types{$struct}->{HASFLAGS};
	my $flagval;

	# Struct check (read)
	print STRUCTS_H "DLL_LOCAL ${struct}* check_${struct} (lua_State *L, int index, ${struct} *dst);\n";
	print STRUCTS_C "DLL_LOCAL ${struct}* check_${struct} (lua_State *L, int index, ${struct} *dst)\n",
			        "{\n";

	if ($hasflags) {
		print STRUCTS_C "\tint autoflag = 1;\n";
	}

	print STRUCTS_C	"\tif (lua_isnil(L, index)) \n",
		  			"\t\treturn NULL;\n\n",
		  			"\tluaL_checktype(L, index, LUA_TTABLE);\n",
		  			"\tmemset(dst, 0, sizeof(${struct}));\n";

	foreach my $entry (@{$types{$struct}->{ENTRIES}}) {

		if ($types{$entry->{TYPE}}->{KIND} eq "struct") {
			print "UNIMPLEMENTED: $entry->{TYPE} $entry->{NAME}\n";
			print STRUCTS_C "\n\t#warning Unimplemented struct of struct: $entry->{TYPE} $entry->{NAME}\n";
		}
		else {
			# We get the member, could be nil
			print STRUCTS_C "\n\tlua_getfield(L, index, \"$entry->{NAME}\");\n";

			if ($entry->{ARRAY} ne "" and $entry->{TYPE} eq "char") {
				# TODO: Do memcpy or strcpy into the char array.
				#print STRUCTS_C "\tdst->$entry->{NAME} = lua_tonumber(L, -1);\n";
				print "UNIMPLEMENTED: $entry->{TYPE} $entry->{NAME}\n";
			}
			else {
				# Flags members are special, 
				if ($entry->{NAME} eq "flags") {
					print STRUCTS_C "\tif (!lua_isnil(L, -1)) {\n", 
									"\t\tdst->$entry->{NAME} = lua_tonumber(L, -1);\n",
									"\t\tautoflag = 0;\n",
									"\t}\n";
				}
				else {

					print STRUCTS_C "\tif (!lua_isnil(L, -1)) {\n";

					if ($types{$entry->{TYPE}}->{KIND} eq "enum") {
						print STRUCTS_C "\t\tdst->$entry->{NAME} = check_$entry->{TYPE}(L, -1);\n";
						$gen_enum_check{$entry->{TYPE}} = 1;
					}
					else {
						print STRUCTS_C "\t\tdst->$entry->{NAME} = lua_tonumber(L, -1);\n";
					}

					if ($hasflags) {
						$flagval = string_to_flag("${struct}Flags", $entry->{NAME});
						print STRUCTS_C "\t\tif (autoflag)\n", 
										"\t\t\tdst->flags |= $flagval;\n";
					}
					
					print STRUCTS_C "\t}\n";
				}
			}
			print STRUCTS_C "\tlua_pop(L, 1);\n";
		}
	}

	print STRUCTS_C "\t\n\treturn dst;\n",
					"}\n\n";
}

sub generate_struct_push {

	my ($struct) = @_;

	# Struct push (return)
	print STRUCTS_H "DLL_LOCAL void push_${struct} (lua_State *L, ${struct} *src);\n";
	print STRUCTS_C "DLL_LOCAL void push_${struct} (lua_State *L, ${struct} *src)\n",
			        "{\n",
				    "\tlua_newtable(L);\n\n";

	foreach my $entry (@{$types{$struct}->{ENTRIES}}) {

		print STRUCTS_C "\tlua_pushstring(L, \"$entry->{NAME}\");\n";
		if ($entry->{ARRAY} ne "" and $entry->{TYPE} eq "char") {
			print STRUCTS_C "\tlua_pushstring(L, src->$entry->{NAME});\n";
		}
		else {
			print STRUCTS_C "\tlua_pushnumber(L, src->$entry->{NAME});\n";
		}
		print STRUCTS_C "\tlua_settable(L, -3);\n";
	}

	print STRUCTS_C "}\n\n";
}

# TODO: Is there a need for null interface pointer safe-checking?
#
sub generate_common_interface {

	my ($interface) = @_;

	print COMMON_H  "DLL_LOCAL int open_${interface} (lua_State *L);\n";
	print COMMON_H  "DLL_LOCAL void push_${interface} (lua_State *L, ${interface} *interface);\n";
	print COMMON_C  "DLL_LOCAL void push_${interface} (lua_State *L, ${interface} *interface)\n",
					"{\n",
					"\t${interface} **p;\n",
					"\tp = lua_newuserdata(L, sizeof(${interface}*));\n",
					"\t*p = interface;\n",
					"\tluaL_getmetatable(L, \"${interface}\");\n",
					"\tlua_setmetatable(L, -2);\n",
					"}\n\n";

	print COMMON_H  "DLL_LOCAL ${interface} **check_${interface} (lua_State *L, int index);\n\n";
	print COMMON_C  "DLL_LOCAL ${interface} **check_${interface} (lua_State *L, int index)\n",
					"{\n",
					"\t${interface} **p;\n",
					"\tluaL_checktype(L, index, LUA_TUSERDATA);\n",
					"\tp = (${interface} **) luaL_checkudata(L, index, \"${interface}\");\n",
					"\tif (p == NULL) luaL_typerror(L, index, \"${interface}\");\n",
					"\treturn p;\n",
					"}\n\n";
}

###################
## File creation ##
###################

sub h_create {
	my ($FILE, $filename, $includes) = @_;

	open( $FILE, ">${src_dir}$filename" )
		or die ("*** Can not open '$filename' for writing:\n*** $!");

	print $FILE "#ifndef $FILE\n",
				"#define $FILE\n\n",
				"#include \"lua.h\"\n", 
				"#include \"lauxlib.h\"\n",
				"#include \"directfb.h\"\n",
				"\n",
				"$includes\n";
}

sub c_create {
	my ($FILE, $filename, $includes) = @_;

	open( $FILE, ">${src_dir}$filename" )
		or die ("*** Can not open '$filename' for writing:\n*** $!");

	print $FILE "#include \"lua.h\"\n", 
				"#include \"lauxlib.h\"\n",
				"#include \"directfb.h\"\n",
				"\n",
				"$includes\n";
}

sub h_close {
	my ($FILE) = @_;
	print $FILE "\n#endif\n";
	close( $FILE );
}

sub c_close {
	my ($FILE) = @_;
	close( $FILE );
}

#############
## Parsing ##
#############

# Reads stdin until the end of the parameter list is reached.
# Returns list of parameter records.
#
# TODO: Add full comment support and use it for function types as well.
#
sub parse_params () {
	my @entries;

	while (<>) {
		chomp;
		last if /^\s*\)\;\s*$/;

		if ( /^\s*(const)?\s*([\w\ ]+)\s+(\**)(\w+),?\s*$/ ) {
			my $const = $1;
			my $type  = $2;
			my $ptr   = $3;
			my $name  = $4;

			trim( \$type );

			if (!($name eq "thiz")) {
				my $rec = {
					NAME   => $name,
					CONST  => $const,
					TYPE   => $type,
					PTR    => $ptr
				};

				push (@entries, $rec);
			}
		}
	}

	return @entries;
}

# Reads stdin until the end of the interface is reached.
# Parameter is the interface name.
#
sub parse_interface ($) {
	my ($interface) = @_;

	trim( \$interface );

	c_create( FH, "${interface}.c", "#include \"common.h\"\n#include \"structs.h\"\n#include \"enums.h\"\n" );

	my @funcs;

	while (<>) {
		chomp;
		last if /^\s*\)\s*$/;

		if ( /^\s*\/\*\*\s*(.+)\s*\*\*\/\s*$/ ) {
		}
		elsif ( /^\s*(\w+)\s*\(\s*\*\s*(\w+)\s*\)\s*\(?\s*$/ ) {
			# Skip blacklisted functions
			next if ($blacklist{$2} eq 1);

			my $function   = $2;
			my $return_val = 0;

			my @params = parse_params();
			my $param;

			my $args;
			my $declaration;
			my $pre_code;
			my $post_code;

			# Arg number starts at 2 (Lua starts at 1 plus self interface which uses 1).
			my $arg_num = 2;

			for $param (@params) {
				# simple
				if ($param->{PTR} eq "") {
					# enum input?
					if ($types{$param->{TYPE}}->{KIND} eq "enum") {
						$declaration .= "\t$param->{TYPE} $param->{NAME};\n";
						$pre_code .= "\t$param->{NAME} = check_$param->{TYPE}(L, $arg_num);\n";
						$args .= ", $param->{NAME}";
						$gen_enum_check{$param->{TYPE}} = 1;
					}
					else {
						$declaration .= "\t$param->{TYPE} $param->{NAME};\n";
						$pre_code .= "\t$param->{NAME} = luaL_checkinteger(L, $arg_num);\n";
						$args .= ", $param->{NAME}";
					}
				}
				# pointer
				elsif ($param->{PTR} eq "*") {
					# input
					if ($param->{CONST} eq "const") {
						# "void" -> buffer input 
						if ($param->{TYPE} eq "void") {
							print "UNIMPLEMENTED: $interface\::$function: $param->{TYPE} $param->{PTR} $param->{NAME}\n";
							$pre_code .= "\t#warning unimplemented (buffer input)\n";
							$args .= ", NULL";
						}
						# "char" -> string input
						elsif ($param->{TYPE} eq "char") {
							$declaration .= "\tconst $param->{TYPE} *$param->{NAME};\n";
							$pre_code .= "\t$param->{NAME} = luaL_checkstring(L, $arg_num);\n";
							$args .= ", $param->{NAME}";
						}
						# struct input, must handle nil value
						elsif ($types{$param->{TYPE}}->{KIND} eq "struct") {
							$declaration .= "\t$param->{TYPE} $param->{NAME}, *$param->{NAME}_p;\n";
							$pre_code .= "\t$param->{NAME}_p = check_$param->{TYPE}(L, $arg_num, &$param->{NAME});\n";
							$args .= ", $param->{NAME}_p";
							$gen_struct_check{$param->{TYPE}} = 1;
						}
						# array input?
						else
						{
							print "UNIMPLEMENTED: $interface\::$function: $param->{TYPE} $param->{PTR} $param->{NAME}\n";
							$pre_code .= "\t#warning unimplemented (array input?)\n";
							$args .= ", NULL";
						}
					}
					
					# output
					else {
						# "void" -> just context pointer
						if ($param->{TYPE} eq "void") {
							print "UNIMPLEMENTED: $interface\::$function: $param->{TYPE} $param->{PTR} $param->{NAME}\n";
							$pre_code .= "\t#warning unimplemented (context pointer)\n";
							$args .= ", NULL";
						}
						# struct output
						elsif ($types{$param->{TYPE}}->{KIND} eq "struct") {
							$declaration .= "\t$param->{TYPE} $param->{NAME};\n";
							$args .= ", &$param->{NAME}";
							$post_code .= "\tpush_$param->{TYPE}(L, &$param->{NAME});\n";
							$return_val++;
							$gen_struct_push{$param->{TYPE}} = 1;
						}
						# Interface input(!)
						elsif ($types{$param->{TYPE}}->{KIND} eq "interface") {
							$declaration .= "\t$param->{TYPE} **$param->{NAME};\n";
							$pre_code .= "\t$param->{NAME} = check_$param->{TYPE}(L, $arg_num);\n";
							$args .= ", *$param->{NAME}";
						}
						# enum? output
						# TODO: Add proper enum output. Right now, 
						# we just return a number.
						else {
							$declaration .= "\t$param->{TYPE} $param->{NAME};\n";
							$args .= ", &$param->{NAME}";
							$return_val++;
							#if ($types{$param->{TYPE}}->{KIND} eq "enum") {
							#	print "Enum output found $param->{TYPE}\n";
							#	$post_code .= "\tpush_$param->{TYPE}(L, $param->{NAME});\n";
							#	$gen_enum_push{$param->{TYPE}} = 1;
							#}
							#else {
								$post_code .= "\tlua_pushnumber(L, $param->{NAME});\n";
								$gen_enum_push{$param->{TYPE}} = 1;
							#}
						}
					}
				}
				# double pointer
				elsif ($param->{PTR} eq "**") {
					# input (pass array)
					if ($param->{CONST} eq "const") {
						print "UNIMPLEMENTED: $interface\::$function: $param->{CONST} $param->{TYPE} $param->{PTR} $param->{NAME}\n";
					}
					# output (return interface)
					else {
						# "void" -> return buffer
						if ($param->{TYPE} eq "void") {
							print "UNIMPLEMENTED: $interface\::$function: $param->{CONST} $param->{TYPE} $param->{PTR} $param->{NAME}\n";
							$pre_code .= "\t#warning unimplemented (return pointer)\n";
						}
						# "char" -> return string
						elsif ($param->{TYPE} eq "char") {
							print "UNIMPLEMENTED: $interface\::$function: $param->{CONST} $param->{TYPE} $param->{PTR} $param->{NAME}\n";
						}
						# output (return interface)
						else {
							$declaration .= "\t$param->{TYPE} *$param->{NAME};\n";
							$post_code .= "\tpush_$param->{TYPE}(L, $param->{NAME});\n";
							$return_val++;
						}
					}

					$args .= ", &$param->{NAME}";
				}

				$arg_num++;
			}

			# Append new line in front of post_code for cleanear code, you obsessive bastard.
			if ($post_code ne "") {
				$post_code = "\n".$post_code;
			}

			print FH "static int\n",
						"l_${interface}_${function} (lua_State *L)\n",
						"{\n",
						"\tDFBResult res;\n",
						"\t${interface} **thiz;\n",
						"${declaration}\n",
					   	"\tthiz = check_${interface}(L, 1);\n",
						"${pre_code}\n",
						"\tres = (*thiz)->${function}( *thiz${args} );\n",
						"\tif (res != DFB_OK)\n",
						"\t\treturn luaL_error(L, \"\\nError in function %s\::%s\\n%s\", \"${interface}\", \"${function}\", DirectFBErrorString(res));\n",
						"${post_code}\n",
						"\treturn ${return_val};\n",
						"}\n\n";

			push( @funcs, {
					NAME   => $function,
					PARAMS => @params
					} );
		}
		elsif ( /^\s*\/\*\s*$/ ) {
			# Comment
		}
	}

	print FH "static int\n",
				"l_${interface}_Release (lua_State *L)\n",
				"{\n",
				"\t${interface} **thiz;\n",
				"\tthiz = check_${interface}(L, 1);\n",
				"\tif (*thiz) {\n",
				"\t\t(*thiz)->Release( *thiz );\n",
				"\t\t*thiz = NULL;\n",
				"\t}\n",
				"\treturn 0;\n",
				"}\n",
				"\n\n";

	print FH "static const luaL_reg ${interface}_methods[] = {\n";

	for $func (@funcs) {
		print FH "\t{\"$func->{NAME}\",l_${interface}_$func->{NAME}},\n";
	}

	print FH "\t{\"Release\", l_${interface}_Release},\n",
				"\t{\"__gc\", l_${interface}_Release},\n",
				"\t{NULL, NULL}\n",
				"};\n\n";

	print FH "DLL_LOCAL int open_${interface} (lua_State *L)\n",
				"{\n",
				"\tluaL_newmetatable(L, \"${interface}\");\n",
				"\tlua_pushstring(L, \"__index\");\n",
				"\tlua_pushvalue(L, -2);\n",
				"\tlua_settable(L, -3);\n",
				"\tluaL_openlib(L, NULL, ${interface}_methods, 0);\n",
				"\treturn 1;\n",
				"}\n";

	c_close( FH );
}

# Reads stdin until the end of the enum is reached.
#
sub parse_enum {
	my @entries;

	while (<>) {
		chomp;

		my $entry;

		# entry with assignment (complete comment)
		if ( /^\s*(\w+)\s*=\s*([\w\d\(\)\,\|\!\s]+[^\,\s])\s*,?\s*\/\*\s*(.+)\s*\*\/\s*$/ ) {
			$entry = $1;
		}
		# entry with assignment (opening comment)
		elsif ( /^\s*(\w+)\s*=\s*([\w\d\(\)\,\|\!\s]+[^\,\s])\s*,?\s*\/\*\s*(.+)\s*$/ ) {
			$entry = $1;
		}
		# entry with assignment (none or preceding comment)
		elsif ( /^\s*(\w+)\s*=\s*([\w\d\(\)\,\|\!\s]+[^\,\s])\s*,?\s*$/ ) {
			$entry = $1;
		}
		# entry without assignment (complete comment)
		elsif ( /^\s*(\w+)\s*,?\s*\/\*\s*(.+)\s*\*\/\s*$/ ) {
			$entry = $1;
		}
		# entry without assignment (opening comment)
		elsif ( /^\s*(\w+)\s*,?\s*\/\*\s*(.+)\s*$/ ) {
			$entry = $1;
		}
		# entry without assignment (none or preceding comment)
		elsif ( /^\s*(\w+)\s*,?\s*$/ ) {
			$entry = $1;
		}
		# preceding comment (complete)
		elsif ( /^\s*\/\*\s*(.+)\s*\*\/\s*$/ ) {
		}
		# preceding comment (opening)
		elsif ( /^\s*\/\*\s*(.+)\s*$/ ) {
		}
		# end of enum
		elsif ( /^\s*\}\s*(\w+)\s*\;\s*$/ ) {
			$enum = $1;
			last;
		}
		# blank line?
		else {
		}

		if ($entry ne "") {
			push (@entries, $entry);
		}
	}

	$types{$enum} = {
		NAME    => $enum,
		KIND    => "enum",
		ENTRIES => \@entries
	};
}

# Reads stdin until the end of the enum is reached.
#
sub parse_struct {
	my @entries;
	my $hasflags = 0;

	while (<>) {
		chomp;

		my $entry;

		# without comment
		if ( /^\s*(const )?\s*([\w ]+)\s+(\**)([\w]+)([\[\w\]]+)*(\s*:\s*\d+)?;\s*$/ ) {
			$const = $1;
			$type = $2;
			$ptr = $3;
			$entry = $4.$6;
			$array = $5;
			$text = "";
		}
		# complete one line entry
		elsif ( /^\s*(const )?\s*([\w ]+)\s+(\**)([\w]+)([\[\]\w]+)*(\s*:\s*\d+)?;\s*\/\*\s*(.+)\*\/\s*$/ ) {
			$const = $1;
			$type = $2;
			$ptr = $3;
			$entry = $4.$6;
			$array = $5;
			$text = $7;
		}
		# with comment opening
		elsif ( /^\s*(const )?\s*([\w ]+)\s+(\**)([\w]+)([\[\w\]]+)*(\s*:\s*\d+)?;\s*\/\*\s*(.+)\s*$/ ) {
			$const = $1;
			$type = $2;
			$ptr = $3;
			$entry = $4.$6;
			$array = $5;
			$text = $t1.$t2;
		}
		# sub
		elsif ( /^\s*struct\s*\{\s*$/ ) {
			while (<>) {
				chomp;
				last if /^\s*\}\s*([\w\d\+\[\]]+)\s*\;\s*/;
			}
		}
		elsif ( /^\s*\}\s*(\w+)\s*\;\s*$/ ) {
			$struct = $1;

			trim( \$struct );

			$struct_list{$struct} = $headline;
			$type_list{$struct} = $headline;

			last;
		}

		trim( \$type );

		if ($entry ne "") {

			if ($entry eq "flags") {
				$hasflags = 1;
			}

			push (@entries, {
					NAME   => $entry,
					CONST  => $const,
					TYPE   => $type,
					PTR    => $ptr,
					ARRAY  => $array
					} );
		}
	}

	$types{$struct} = {
		NAME    => $struct,
		KIND    => "struct",
		ENTRIES => \@entries,
		HASFLAGS => $hasflags
	};
}

#
# Reads stdin until the end of the function type is reached.
# Parameters are the return type and function type name.
#
sub parse_func ($$) {
	my ($rtype, $name) = @_;

	my @entries;
	my %entries_params;
	my %entries_types;
	my %entries_ptrs;

	trim( \$rtype );
	trim( \$name );

	while (<>) {
		chomp;

		my $entry;

		# without comment
		if ( /^\s*(const )?\s*([\w ]+)\s+(\**)([\w\d\+\[\]]+)(\s*:\s*\d+)?,?\s*$/ ) {
			$const = $1;
			$type = $2;
			$ptr = $3;
			$entry = $4.$5;
			$text = "";
		}
		# complete one line entry
		elsif ( /^\s*(const )?\s*([\w ]+)\s+(\**)([\w\d\+\[\]]+)(\s*:\s*\d+)?,?\s*\/\*\s*(.+)\*\/\s*$/ ) {
			$const = $1;
			$type = $2;
			$ptr = $3;
			$entry = $4.$5;
			$text = $6;
		}
		# with comment opening
		elsif ( /^\s*(const )?\s*([\w ]+)\s+(\**)([\w\d\+\[\]]+)(\s*:\s*\d+)?,?\s*\/\*\s*(.+)\s*$/ ) {
			$const = $1;
			$type = $2;
			$ptr = $3;
			$entry = $4.$5;
			$text = $t1.$t2;
		}
		elsif ( /^\s*\)\;\s*$/ ) {
			$func_list{$name} = $headline;
			$type_list{$name} = $headline;

			last;
		}

		if ($entry ne "") {
			$entries_types{$entry} = $const . $type;
			$entries_ptrs{$entry} = $ptr;
			$entries_params{$entry} = $text;

			push (@entries, $entry);

		}
	}
}

##########
## Main ##
##########

h_create( COMMON_H, "common.h", "" );
c_create( COMMON_C, "common.c", "#include \"common.h\"\n#include \"enums.h\"\n" );

h_create( STRUCTS_H, "structs.h", "#include \"common.h\"\n" );
c_create( STRUCTS_C, "structs.c", "#include \"structs.h\"\n#include \"common.h\"\n#include \"enums.h\"\n" );

h_create( ENUMS_H, "enums.h", "#include \"common.h\"\n" );
c_create( ENUMS_C, "enums.c", "#include \"enums.h\"\n#include \"common.h\"\n" );

print COMMON_H	"#if defined(__GNUC__) && __GNUC__ >= 4\n",
				"\t#define DLL_EXPORT __attribute__((visibility(\"default\")))\n",
				"\t#define DLL_LOCAL	__attribute__((visibility(\"hidden\")))\n",
				"#else\n",
				"\t#define DLL_EXPORT\n",
				"\t#define DLL_LOCAL\n",
				"#endif\n\n";

print ENUMS_C "static int string2enum(lua_State *L, const char *str, const char* type)\n",
			  "{\n",
			  "\tint result = 0;\n",
			  "\tconst char *str_start, *str_end;\n",
			  "\tstr_start = str;\n",
			  "\twhile (1) {\n",
			  "\t\tif (*str_start == 0)\n",
			  "\t\t\tbreak;\n",
			  "\t\tif (!isalnum(*str_start) && *str_start != '_') {\n",
			  "\t\t\tstr_start++;\n",
			  "\t\t\tcontinue;\n",
			  "\t\t}\n",
			  "\t\tstr_end = str_start;\n",
			  "\t\twhile (isalnum(*str_end) || *str_end == '_') {\n",
			  "\t\t\tstr_end++;\n",
			  "\t\t\tcontinue;\n",
			  "\t\t}\n",
			  "\t\tlua_pushlstring(L, str_start, str_end-str_start);\n",
			  "\t\tlua_gettable(L, -2);\n",
			  "\t\tif (!lua_isnumber(L, -1))\n",
			  "\t\t\tluaL_error(L, \"'%s' is not a valid '%s' value\", str_start, type);\n",
			  "\t\tresult |= lua_tointeger(L, -1);\n",
			  "\t\tlua_pop(L, 1);\n",
			  "\t\tstr_start = str_end;\n",
			  "\t}\n",
			  "\tlua_pop(L, 1);\n",
			  "\treturn result;\n",
			  "}\n\n";

while (<>) {
	chomp;

	# Search interface declaration
	if ( /^\s*\w*DECLARE_INTERFACE\s*\(\s*(\w+)\s\)\s*$/ ) {
		$interface = $1;

		trim( \$interface );

		# Skip blacklisted interfaces
		next if (defined $blacklist{$interface});

		generate_common_interface($interface);

		if (!defined ($types{$interface})) {
			$types{$interface} = {
				NAME    => $interface,
				KIND    => "interface"
			};
		}
	}
	elsif ( /^\s*\w*DEFINE_INTERFACE\s*\(\s*(\w+),\s*$/ ) {
		# Skip blacklisted interfaces
		next if (defined $blacklist{$1});
		parse_interface( $1 );
	}
	elsif ( /^\s*typedef\s+enum\s*\{?\s*$/ ) {
		parse_enum();
	}
	elsif ( /^\s*typedef\s+(struct|union)\s*\{?\s*$/ ) {
		parse_struct();
	}
	elsif ( /^\s*typedef\s+(\w+)\s+\(\*(\w+)\)\s*\(\s*$/ ) {
		parse_func( $1, $2 );
	}
	elsif ( /^\s*#define\s+([^\(\s]+)(\([^\)]*\))?\s*(.*)/ ) {
		# Macro, nothing to do 
	}
	elsif ( /^\s*\/\*\s*$/ ) {
		# Comment, nothing to do 
	}
	else {
		$headline = "";
		$detailed = "";
		%options  = ();
	}
}

foreach my $s (keys %gen_struct_check) {
	generate_struct_check($s);
}

foreach my $s (keys %gen_struct_push) {
	generate_struct_push($s);
}

foreach my $s (keys %gen_enum_check) {
	generate_enum_check($s);
}


#################################
## Library initialization code ##
#################################

print ENUMS_H "DLL_LOCAL void open_enums (lua_State *L);\n";
print ENUMS_C "DLL_LOCAL void open_enums (lua_State *L)\n",
			  "{\n";

foreach (keys %gen_enum_check) {
	print ENUMS_C "\tbuild_$_(L);\n";
}

print ENUMS_C "\n";

foreach my $enum (keys %gen_enum_push) {
	foreach (@{$types{$enum}->{ENTRIES}}) {
		print ENUMS_C 	"\tlua_pushnumber(L, $_);\n",
						"\tlua_setglobal(L, \"$_\");\n\n";
	}
}
foreach my $enum (keys %gen_enum_check) {
	foreach (@{$types{$enum}->{ENTRIES}}) {
		print ENUMS_C 	"\tlua_pushnumber(L, $_);\n",
						"\tlua_setglobal(L, \"$_\");\n\n";
	}
}

print ENUMS_C "}\n";

print COMMON_C 	"static int l_DirectFBInit (lua_State *L)\n",
			   	"{\n",
				"\tDirectFBInit(NULL, NULL);\n",
				"\treturn 0;\n",
				"}\n\n";

print COMMON_C	"static int l_DirectFBCreate (lua_State *L)\n",
				"{\n",
				"\tDFBResult res;\n",
				"\tIDirectFB *interface;\n",
				"\tres = DirectFBCreate(&interface);\n",
				"\tif (res != DFB_OK)\n",
				"\t\treturn luaL_error(L, \"Error %d on DirectFB call to DirectFBCreate\", res);\n",
				"\tpush_IDirectFB(L, interface);\n",
				"\treturn 1;\n",
				"}\n\n";

print COMMON_C  "static const luaL_reg dfb_m[] = {\n",
				"\t{\"DirectFBCreate\", l_DirectFBCreate},\n",
				"\t{\"DirectFBInit\", l_DirectFBInit},\n",
				"\t{NULL, NULL}\n",
				"};\n\n";

print COMMON_C "int LUALIB_API luaopen_$pkgname (lua_State *L)\n",
	 		   "{\n";

my @interfaces = grep { $types{$_}{KIND} eq "interface" } keys %types;
foreach (@interfaces) {
	print COMMON_C "\topen_$_(L);\n",
}

print COMMON_C "\n",
			   "\tluaL_openlib(L, \"$pkgname\", dfb_m, 0);\n",
				"\topen_enums(L);\n",
			   "\treturn 1;\n",
			   "}";

h_close( COMMON_H );
c_close( COMMON_C );

h_close( STRUCTS_H );
c_close( STRUCTS_C );

h_close( ENUMS_H );
c_close( ENUMS_C );
