#!/usr/bin/perl

############################################
# Lua2DFB generator script
#
# This script parses directfb headers and produces
# lua binding C code.
#
# This is based on a previous script by Denis Oliver Kropp,
# for a javascript v8 binding.
#
#
use strict;  # Enforce some good programming rules
#use warnings;

#######################
## Package variables ##
#######################

my $pkgname = "directfb";
my $src_dir = "./src/";

my %types;
my %gen_struct_check;
my %gen_struct_push;
my %gen_union_push;
my %gen_enum_check;
my %gen_enum_globals;
my %gen_enum_push;

my ($FH, $CORE_C, $COMMON_H, $STRUCTS_H, $STRUCTS_C, $ENUMS_H, $ENUMS_C, $INTERFACE_H, $INTERFACE_C);

#########################
## Interface blacklist ##
#########################
my %blacklist;
$blacklist{IDirectFBPalette}		= 1;
$blacklist{IDirectFBGL}				= 1;
$blacklist{IDirectFBGL2}			= 1;
$blacklist{IDirectFBGL2Context}		= 1;
$blacklist{IDirectFBScreen}			= 1;

####################
## Type blacklist ##
####################
$blacklist{DFBUserEvent}			= 1;
$blacklist{DFBSurfaceEvent}			= 1;
$blacklist{DFBVideoProviderEvent}	= 1;
$blacklist{DFBUniversalEvent}		= 1;

########################
## Function blacklist ##
########################
$blacklist{GetClipboardData}		= 1;
$blacklist{GetGL}					= 1;
$blacklist{Lock}					= 1;
$blacklist{Unlock}					= 1;
$blacklist{GetProperty}				= 1;
$blacklist{RemoveProperty}			= 1;
$blacklist{GetStringBreak}	 		= 1;
$blacklist{SetStreamAttributes} 	= 1;
$blacklist{SetBufferThresholds} 	= 1;
$blacklist{SetClipboardData}	 	= 1;
$blacklist{GetClipboardTimeStamp}	= 1;
$blacklist{Write} 					= 1;
$blacklist{PutData} 				= 1;
$blacklist{SetColors}				= 1;
$blacklist{TextureTriangles}		= 1;
$blacklist{SetIndexTranslation}		= 1;
$blacklist{SetSrcColorMatrix}		= 1;
$blacklist{SetKeySelection}			= 1;
$blacklist{Read}					= 1;
$blacklist{GetInterface}			= 1;
$blacklist{EnumInputDevices}		= 1;
$blacklist{EnumDisplayLayers}		= 1;
$blacklist{EnumScreens}				= 1;
$blacklist{EnumVideoModes}			= 1;
$blacklist{SetProperty} 			= 1;
$blacklist{EnumEncodings} 			= 1;
$blacklist{SetRenderCallback} 		= 1;
$blacklist{GetData} 				= 1;
$blacklist{PeekData} 				= 1;
$blacklist{GetDeviceDescription}	= 1;
$blacklist{CreatePalette}			= 1;
$blacklist{CreateDataBuffer}		= 1;
$blacklist{SetSrcGeometry}			= 1;
$blacklist{SetDstGeometry}			= 1;
$blacklist{GetPalette}				= 1;
$blacklist{SetPalette}				= 1;
$blacklist{SetDstGeometry}			= 1;
$blacklist{SendEvent}				= 1;
$blacklist{GetScreen}				= 1;
$blacklist{GetKeymapEntry}			= 1;
$blacklist{SetKeymapEntry}			= 1;
$blacklist{SetRop}					= 1;
$blacklist{SetSrcColorKeyExtended}	= 1;
$blacklist{SetDstColorKeyExtended}	= 1;
$blacklist{DrawMonoGlyphs}			= 1;
$blacklist{SetSrcConvolution}		= 1;

######################
## Define blacklist ##
######################
$blacklist{DIDCAPS_NONE} = 1;
$blacklist{DIDCAPS_KEYS} = 1;
$blacklist{DIDCAPS_AXES} = 1;
$blacklist{DIDCAPS_BUTTONS} = 1;
$blacklist{DIDCAPS_ALL} = 1;


###############
## Utilities ##
###############

sub trim {
	my $str_ref = shift;

	# remove leading white space
	$$str_ref =~ s/^\s*//g;

	# remove trailing white space and new line
	$$str_ref =~ s/\s*$//g;
}

sub string_to_flag {
	my ($enum, $name) = @_;
	my @entries = @{$types{$enum}->{ENTRIES}};

	foreach (@entries) {

		# try to match case-insensitive the name of the enum flag
		return $_ if /\w*$name\w*/i;
	}

	return 0;
}

#####################
## Code Generation ##
#####################

sub generate_enum_check {

	my ($enum) = @_;

	# enum build function
	print $ENUMS_C "static void build_$enum(lua_State *L)\n",
				  "{\n",
				  "\tlua_newtable(L);\n";

	foreach (@{$types{$enum}->{ENTRIES}}) {
		print $ENUMS_C "\tlua_pushnumber(L, $_);\n",
					  "\tlua_setfield(L, -2, \"$_\");\n";
	}

	print $ENUMS_C "\tlua_setfield(L, -2, \"$enum\");\n",
				  "}\n\n";

	# check function
	print $ENUMS_H "DLL_LOCAL ${enum} check_${enum} (lua_State *L, int index);\n";
	print $ENUMS_C "DLL_LOCAL ${enum} check_${enum} (lua_State *L, int index)\n",
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

	my $struct = shift;
	my $hasflags = $types{$struct}->{HASFLAGS};
	my $flagval;

	# Struct check (read)
	print $STRUCTS_H "DLL_LOCAL ${struct}* check_${struct} (lua_State *L, int index, ${struct} *dst);\n";
	print $STRUCTS_C "DLL_LOCAL ${struct}* check_${struct} (lua_State *L, int index, ${struct} *dst)\n",
			        "{\n";

	if ($hasflags) {
		print $STRUCTS_C "\tint autoflag = 1;\n";
	}

	print $STRUCTS_C	"\tif (lua_isnoneornil(L, index)) \n",
		  			"\t\treturn NULL;\n\n",
		  			"\tluaL_checktype(L, index, LUA_TTABLE);\n",
		  			"\tmemset(dst, 0, sizeof(${struct}));\n";

	foreach my $entry (@{$types{$struct}->{ENTRIES}}) {

		if ($types{$entry->{TYPE}}->{KIND} eq "struct") {
			print "UNIMPLEMENTED: $entry->{TYPE} $entry->{NAME}\n";
			print $STRUCTS_C "\n\t#warning Unimplemented struct of struct: $entry->{TYPE} $entry->{NAME}\n";
		}
		else {
			# We get the member, could be nil
			print $STRUCTS_C "\n\tlua_getfield(L, index, \"$entry->{NAME}\");\n";

			if ($entry->{ARRAY} ne "" and $entry->{TYPE} eq "char") {
				# TODO: Do memcpy or strcpy into the char array.
				#print $STRUCTS_C "\tdst->$entry->{NAME} = lua_tonumber(L, -1);\n";
				print "UNIMPLEMENTED: $entry->{TYPE} $entry->{NAME}\n";
			}
			else {
				# Flags members are special, 
				if ($entry->{NAME} eq "flags") {
					print $STRUCTS_C "\tif (!lua_isnil(L, -1)) {\n", 
									"\t\tdst->$entry->{NAME} = lua_tonumber(L, -1);\n",
									"\t\tautoflag = 0;\n",
									"\t}\n";
				}
				else {

					print $STRUCTS_C "\tif (!lua_isnil(L, -1)) {\n";

					if ($types{$entry->{TYPE}}->{KIND} eq "enum") {
						print $STRUCTS_C "\t\tdst->$entry->{NAME} = check_$entry->{TYPE}(L, -1);\n";
						$gen_enum_check{$entry->{TYPE}} = 1;
						$gen_enum_globals{$entry->{TYPE}} = 1;
					}
					else {
						print $STRUCTS_C "\t\tdst->$entry->{NAME} = lua_tonumber(L, -1);\n";
					}

					if ($hasflags) {
						$flagval = string_to_flag("${struct}Flags", $entry->{NAME});
						print $STRUCTS_C "\t\tif (autoflag)\n", 
										"\t\t\tdst->flags |= $flagval;\n";
					}
					
					print $STRUCTS_C "\t}\n";
				}
			}
			print $STRUCTS_C "\tlua_pop(L, 1);\n";
		}
	}

	print $STRUCTS_C "\t\n\treturn dst;\n",
					"}\n\n";
}

# TODO: This is way too specific. Should be more generic. Works for the moment, though.
sub generate_union_push {

	my $union = shift;

	# Union push (return)
	print $STRUCTS_H "DLL_LOCAL void push_${union} (lua_State *L, ${union} *src);\n";
	print $STRUCTS_C "DLL_LOCAL void push_${union} (lua_State *L, ${union} *src)\n",
			        "{\n",
					"\tif (src->clazz == DFEC_WINDOW)\n",
					"\t\tpush_DFBWindowEvent (L, &src->window);\n",
					"\telse if (src->clazz == DFEC_INPUT)\n",
					"\t\tpush_DFBInputEvent (L, &src->input);\n",
					"}\n\n";
}

sub generate_struct_push {

	my $struct = shift;

	# Struct push (return)
	print $STRUCTS_H "DLL_LOCAL void push_${struct} (lua_State *L, ${struct} *src);\n";
	print $STRUCTS_C "DLL_LOCAL void push_${struct} (lua_State *L, ${struct} *src)\n",
			        "{\n",
				    "\tlua_newtable(L);\n\n";

	foreach my $entry (@{$types{$struct}->{ENTRIES}}) {
		# FIXME: Little hack to avoid struct timeval
		next if ($entry->{TYPE} eq "struct timeval");

		if ($types{$entry->{TYPE}}->{KIND} eq "enum") {
			$gen_enum_globals{$entry->{TYPE}} = 1;
		}

		print $STRUCTS_C "\tlua_pushstring(L, \"$entry->{NAME}\");\n";
		if ($entry->{ARRAY} ne "" and $entry->{TYPE} eq "char") {
			print $STRUCTS_C "\tlua_pushstring(L, src->$entry->{NAME});\n";
		}
		else {
			print $STRUCTS_C "\tlua_pushnumber(L, src->$entry->{NAME});\n";
		}
		print $STRUCTS_C "\tlua_settable(L, -3);\n";
	}

	print $STRUCTS_C "}\n\n";
}

# TODO: Is there a need for null interface pointer safe-checking?
#
sub generate_interface_push {
	my $interface = shift;
	print $INTERFACE_H	"DLL_LOCAL void push_${interface} (lua_State *L, ${interface} *interface);\n\n";
	print $INTERFACE_C	"DLL_LOCAL void push_${interface} (lua_State *L, ${interface} *interface)\n",
						"{\n",
						"\t${interface} **p;\n",
						"\tp = lua_newuserdata(L, sizeof(${interface}*));\n",
						"\t*p = interface;\n",
						"\tluaL_getmetatable(L, \"${interface}\");\n",
						"\tlua_setmetatable(L, -2);\n",
						"}\n\n";
}

sub generate_interface_check {
	my $interface = shift;
	print $INTERFACE_H	"DLL_LOCAL ${interface} **check_${interface} (lua_State *L, int index);\n\n";
	print $INTERFACE_C	"DLL_LOCAL ${interface} **check_${interface} (lua_State *L, int index)\n",
						"{\n",
						"\t${interface} **p;\n",
						"\tluaL_checktype(L, index, LUA_TUSERDATA);\n",
						"\tp = (${interface} **) luaL_checkudata(L, index, \"${interface}\");\n",
						"\tif (p == NULL) luaL_argerror(L, index, \"${interface}\");\n",
						"\treturn p;\n",
						"}\n\n";
}

sub generate_interface_open {
	my $interface = shift;
	print $INTERFACE_H  "DLL_LOCAL int open_${interface} (lua_State *L);\n\n";
}

###################
## File creation ##
###################

sub h_create {
	my ($filename, @includes) = @_;

	open( my $FILE, ">", ${src_dir} . $filename )
		or die ("*** Can not open '$filename' for writing:\n*** $!");

    (my $header_guard = $filename) =~ s/\./_/g;
	print $FILE <<"END";
#ifndef $header_guard
#define $header_guard

#include "lua.h"
#include "lauxlib.h"
#include "directfb.h"

END
    
    foreach my $inc (@includes){
        print $FILE qq!#include "$inc"\n!;
    }
    
    return $FILE;
}

sub c_create {
	my ($filename, @includes) = @_;

	open( my $FILE, ">", ${src_dir} . $filename )
		or die ("*** Can not open '$filename' for writing:\n*** $!");

	print $FILE <<"END";
#include "lua.h"
#include "lauxlib.h"
#include "directfb.h"

END
    
    foreach my $inc (@includes){
        print $FILE qq!#include "$inc"\n!;
    }
    
    return $FILE;
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
sub parse_params {
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
sub parse_interface {
	my ($interface) = @_;

	trim( \$interface );

	# TODO: separate generate from parsing
	$FH = c_create( "${interface}.c", qw"common.h structs.h interfaces.h enums.h" );

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

			# TODO: separate generate from parsing
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
						$pre_code .= "\t$param->{NAME} = lua_tointeger(L, $arg_num);\n";
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
							$declaration .= "\t$param->{TYPE} *$param->{NAME}_p;\n";
							$pre_code .= "\t$param->{NAME}_p = check_array(L, $arg_num);\n";
							$post_code .= "\tfree($param->{NAME}_p);\n";
							$args .= ", $param->{NAME}_p";
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
						# union output
						elsif ($types{$param->{TYPE}}->{KIND} eq "union") {
							$declaration .= "\t$param->{TYPE} $param->{NAME};\n";
							$args .= ", &$param->{NAME}";
							$post_code .= "\tpush_$param->{TYPE}(L, &$param->{NAME});\n";
							$return_val++;
							$gen_union_push{$param->{TYPE}} = 1;
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
								$gen_enum_globals{$param->{TYPE}} = 1;
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

			# TODO: separate generate from parsing
			print $FH "static int\n",
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

	print $FH "static int\n",
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

	print $FH "static const luaL_Reg ${interface}_methods[] = {\n";

	for my $func (@funcs) {
		print $FH "\t{\"$func->{NAME}\",l_${interface}_$func->{NAME}},\n";
	}

	print $FH "\t{\"Release\", l_${interface}_Release},\n",
				"\t{\"__gc\", l_${interface}_Release},\n",
				"\t{NULL, NULL}\n",
				"};\n\n";

	print $FH "DLL_LOCAL int open_${interface} (lua_State *L)\n",
				"{\n",
				"\tluaL_newmetatable(L, \"${interface}\");\n",
				"\tlua_pushstring(L, \"__index\");\n",
				"\tlua_pushvalue(L, -2);\n",
				"\tlua_settable(L, -3);\n",
				"\tluaL_setfuncs(L, ${interface}_methods, 0);\n",
				"\tlua_pop(L, 1);\n",
				"\treturn 1;\n",
				"}\n";

	c_close( $FH );
}

# Reads stdin until the end of the enum is reached.
#
sub parse_enum {
	my @entries;
	my $enum;

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

		# NOTE: This strange "sa" exception is needed because
		# older headers comments are a bit wicked. This 
		# is already fixed in newer ones (check git repo).
		if ($entry ne "" and $entry ne "sa" and ! exists $blacklist{$entry}) {
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
sub parse_union {
	my @entries;
	my $union;

	while (<>) {
		chomp;

		my ($entry, $const, $ptr, $array, $text, $type, $t1, $t2);

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
			$union = $1;

			trim( \$union );

			last;
		}

		trim( \$type );

		if ($entry ne "") {

			if ($types{$type}->{KIND} eq "struct") {
				unless (defined $blacklist{$type}) {
					$gen_struct_push{$type} = 1;
				}
			}
			elsif ($types{$type}->{KIND} eq "enum") {
			}
			else {
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


	$types{$union} = {
		NAME    => $union,
		KIND    => "union",
		ENTRIES => \@entries,
	};
}

# Reads stdin until the end of the enum is reached.
#
sub parse_struct {
	my @entries;
	my $hasflags = 0;
	my $struct;

	while (<>) {
		chomp;

		my ($entry, $const, $ptr, $array, $text, $type, $t1, $t2);

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

			# TODO: Verify this and remove if useless
			# 
			#$struct_list{$struct} = $headline;
			#$type_list{$struct} = $headline;

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
sub parse_func {
	my ($rtype, $name) = @_;

	my @entries;
	my %entries_params;
	my %entries_types;
	my %entries_ptrs;

	trim( \$rtype );
	trim( \$name );

	while (<>) {
		chomp;

		my ($entry, $const, $type, $ptr, $text, $t1, $t2);

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
			# TODO: Verify this and remove if useless
			# 
			#$func_list{$name} = $headline;
			#$type_list{$name} = $headline;

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

## common.h
$COMMON_H = h_create( "common.h" );

# DLL_EXPORT is not being used, so it could be removed.
print $COMMON_H <<END;
#if defined(__GNUC__) && __GNUC__ >= 4
    #define DLL_EXPORT __attribute__((visibility("default")))
    #define DLL_LOCAL  __attribute__((visibility("hidden")))
#else
    #define DLL_EXPORT
    #define DLL_LOCAL
#endif

END

h_close( $COMMON_H );


$CORE_C = c_create( "core.c", qw"interfaces.h enums.h" );

$INTERFACE_H = h_create( "interfaces.h", qw"common.h" );
$INTERFACE_C = c_create( "interfaces.c", qw"common.h" );

$STRUCTS_H = h_create( "structs.h" );
$STRUCTS_C = c_create( "structs.c", qw"common.h enums.h" );

$ENUMS_H = h_create( "enums.h", qw"common.h" );
$ENUMS_C = c_create( "enums.c", qw"ctype.h enums.h common.h" );

print $ENUMS_C "static int string2enum(lua_State *L, const char *str, const char* type)\n",
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

print $STRUCTS_H "void* check_array(lua_State *L, int index);\n";
print $STRUCTS_C "void* check_array(lua_State *L, int index)\n",
				"{\n",
				"\tsize_t len,i;\n",
				"\tint* array;\n",
				"\tif (lua_isnoneornil(L, index))\n",
				"\t\treturn NULL;\n",
				"\tluaL_checktype(L, index, LUA_TTABLE);\n",
				"\tlen = lua_rawlen(L, index);\n",
				"\tlua_pop(L, 1);\n",
				"\tif (len <= 0)\n",
				"\t\treturn NULL;\n",
				"\tarray = malloc(sizeof(int)*len);\n",
				"\tfor (i=0; i<len; i++) {\n",
				"\t\tlua_rawgeti(L, index, i+1);\n",
				"\t\tarray[i] = luaL_checkinteger(L, -1);\n",
				"\t}\n",
				"\treturn array;\n",
				"}\n\n";

while (<>) {
	chomp;

	# Search interface declaration
	if ( /^\s*\w*DECLARE_INTERFACE\s*\(\s*(\w+)\s\)\s*$/ ) {
		my $interface = $1;

		trim( \$interface );

		# Skip blacklisted interfaces
		next if (defined $blacklist{$interface});

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
	elsif ( /^\s*typedef\s+(struct)\s*\{?\s*$/ ) {
		parse_struct();
	}
	elsif ( /^\s*typedef\s+(union)\s*\{?\s*$/ ) {
		parse_union();
	}
	elsif ( /^\s*typedef\s+(\w+)\s+\(\*(\w+)\)\s*\(\s*$/ ) {
		parse_func( $1, $2 );
	}
	elsif ( /^\s*#define\s+([^\(\s]+)(\([^\)]*\))?\s*([0-9x]+)/ ) {
		# Simple valued macro, 
		# TODO: Map some of these macros to strings. Maybe through a white list?
		#print("Hey look, a simple macro! name=$1, value=$3\n");
	}
	elsif ( /^\s*#define\s+([^\(\s]+)(\([^\)]*\))?\s*(.*)/ ) {
		# Macro, nothing to do 
	}
	elsif ( /^\s*\/\*\s*$/ ) {
		# Comment, nothing to do 
	}
	else {
		# TODO: Verify this and remove if useless
		# 
		#$headline = "";
		#$detailed = "";
		#%options  = ();
	}
}

foreach (keys %gen_struct_check) {
	generate_struct_check($_);
}

foreach (keys %gen_struct_push) {
	generate_struct_push($_);
}

foreach (keys %gen_enum_check) {
	generate_enum_check($_);
}

foreach (keys %gen_union_push) {
	generate_union_push($_);
}

#################################
## Library initialization code ##
#################################
my @interfaces = grep { $types{$_}{KIND} eq "interface" } keys %types;
foreach (@interfaces) {
	generate_interface_open($_);
	generate_interface_check($_);
	generate_interface_push($_);
}

print $ENUMS_H "DLL_LOCAL void open_enums (lua_State *L);\n";
print $ENUMS_C "DLL_LOCAL void open_enums (lua_State *L)\n",
			  "{\n";

foreach (keys %gen_enum_check) {
	print $ENUMS_C "\tbuild_$_(L);\n";
}

print $ENUMS_C "\n";

foreach my $enum (keys %gen_enum_globals) {
	foreach (@{$types{$enum}->{ENTRIES}}) {
		print $ENUMS_C 	"\tlua_pushnumber(L, $_);\n",
						"\tlua_setglobal(L, \"$_\");\n\n";
	}
}

print $ENUMS_C "}\n";

print $CORE_C 	"static int l_DirectFBInit (lua_State *L)\n",
			   	"{\n",
				"\tDirectFBInit(NULL, NULL);\n",
				"\treturn 0;\n",
				"}\n\n";

print $CORE_C	"static int l_DirectFBCreate (lua_State *L)\n",
				"{\n",
				"\tDFBResult res;\n",
				"\tIDirectFB *interface;\n",
				"\tres = DirectFBCreate(&interface);\n",
				"\tif (res != DFB_OK)\n",
				"\t\treturn luaL_error(L, \"Error %d on DirectFB call to DirectFBCreate\", res);\n",
				"\tpush_IDirectFB(L, interface);\n",
				"\treturn 1;\n",
				"}\n\n";

print $CORE_C  "static const luaL_Reg dfb_m[] = {\n",
				"\t{\"DirectFBCreate\", l_DirectFBCreate},\n",
				"\t{\"DirectFBInit\", l_DirectFBInit},\n",
				"\t{NULL, NULL}\n",
				"};\n\n";

print $CORE_C "int LUALIB_API luaopen_$pkgname (lua_State *L)\n",
	 		   "{\n";

foreach (@interfaces) {
	print $CORE_C "\topen_$_(L);\n",
}

print $CORE_C <<"END";
    
    luaL_newlib(L, dfb_m);
    open_enums(L);
    lua_setglobal(L, "$pkgname"); 
    return 1;
}
END

c_close( $CORE_C );

h_close( $STRUCTS_H );
c_close( $STRUCTS_C );

h_close( $INTERFACE_H );
c_close( $INTERFACE_C );

h_close( $ENUMS_H );
c_close( $ENUMS_C );
