#!/usr/bin/python

from os import path
from subprocess import run, PIPE
from re import findall
import sys

# Call help on the command
def get_usage(command):
	help = run(command+["--help"], check=True, stdout=PIPE).stdout.decode("utf-8").splitlines()
	options=[]
	for opt in ["Flags", "Modules"]:
		options += parse_section(help, opt)
	commands = parse_section(help, "Commands")
	return options, commands

# Parse input to retrieve a list of commands or flags
def parse_section(input, header):
	if not header:
		return []
	header+=":"

	result=None
	for line in input:
		line = line.strip()
		if result and line == "":
			return sorted(result)
		if result != None:
			if header == "Flags:":
				flags=line.split(' ')[0].split(',')
				result += flags
			else:
				result.append(line.split()[0])
		if str(line) == header:
			result=[]
	return []
		
# Process a command, its flags and (recursively) its subcommands.
def process_command(command, values, compfile):
	print(command)
	flags, commands = get_usage(command)

	configure_command(command, flags, commands, compfile)

	for flag in flags:
		configure_flag(command+[flag.strip('=')], values, compfile)

	for subcommand in commands:
		process_command(command+[subcommand], values, compfile)

# Configure auto-completion for a command
def configure_command(command, flags, commands, compfile):
	id = ""
	for c in command:
		_, _, c = c.rpartition('/')
		c, _, _ = c.partition('.') 
		id += "_" + c
	comp = [ '',
	id + '() {',
	'	local values',
	'	values="'+' '.join(flags+commands)+'"',
	'	COMPREPLY=( $(compgen -W "${values}" -- $1) )',
	'	return 0',
	'}',
	'' ]
	compfile.write('\n'.join(comp))

# Configure auto-completion for flags
def configure_flag(command, values, compfile):
	id = ""
	for c in command:
		_, _, c = c.rpartition('/')
		c, _, _ = c.partition('.')
		id += "_"+c
	comp = [ '',
	id + '() {',
	'	values="'+values.get(id,"")+' `_get_user_values '+id+'`"',
	'	COMPREPLY=( $(compgen -W "${values}" -- $1) )',
	'	return 0',
	'}',
	'']
	compfile.write('\n'.join(comp))

# Read a local file with known values for flags into a map
def read_default_values(bin_path):
	values={}
	with open(bin_path + "/../etc/flags.default", "r") as file:
		for line in file.readlines():
			line = line.strip()
			if not line.startswith('#'):
				line, _, _ = line.partition('#')
				ids, _, data = line.partition('=')
				for id in ids.split(','):
					values[id]=' '.join([ values.get(id, ""), data ]).strip()
	return values

def main(args):
	bin = path.abspath(args[0])
	bin_path = path.dirname(bin)
	bin_name = path.basename(bin).split('.')[0]

	comp_filepath = path.abspath(bin_path+"/../etc/"+bin_name+".completion")
	with open(comp_filepath, "w") as compfile:
		values = read_default_values(bin_path)
		process_command([ bin ], values, compfile)
		comp = [ '',
		# Allow users to set custom values for flags
		'_get_user_values(){',
		'	local id file',
		'	id="$1"',
		'	file="$HOME/.config/' + bin_name + '/completion"',
		'	[ ! -z "$XDG_CONFIG_HOME" ] && file="$XDG_CONFIG_HOME/' + bin_name + '/completion"',
		'	[ -e "$file" ] && grep $id $file | egrep -v " *#" | cut -d= -f2 | cut -d# -f1',
		'}',
		'',
		'_' + bin_name + '_main() {',
		'	local auto_complete cur flag parse word',
		'	auto_complete="_' + bin_name + '"',
		'	cur="${COMP_WORDS[$COMP_CWORD]}"',
		'	# Ignore ' + bin_name + ' and the word currently being typed',
		'	parse=(${COMP_WORDS[@]:1:$COMP_CWORD-1})',
		'	# Generate the function name that will return the proper auto-completion suggestions',
		'	while (( ${#parse} )); do',
		'		unset flag',
		'		word=${parse[0]}',
		'		COMPREPLY=()',
		'		$auto_complete "$word"',
		'		if [ "${#COMPREPLY}" != "0" ]; then',
		'			if [[ "${COMPREPLY[0]}" == -* ]]; then',
		'				# Ignore flags and their value',
		'				if [[ "${COMPREPLY[0]}" == *= ]]; then',
		'					parse=( ${parse[@]:1} )',
		'				fi',
		'				flag=`echo ${word} | sed "s:=$::"`',
		'			else',
		'				# append the command name',
		'				auto_complete="${auto_complete}_${word}"',
		'			fi',
		'		fi',
		'		parse=( ${parse[@]:1} )',
		'	done',
		'	# Handle the case when we are setting a flag value',
		'	[[ "$cur" == *=* ]] && flag=`echo $cur | cut -d= -f1 | sed "s:=$::"` cur=`echo $cur | cut -d= -f2`',
		'	# Handle flags',
		'	[ ! -z "$flag" ] && auto_complete="${auto_complete}_${flag}"',
		'	COMPREPLY=()',
    	'	$auto_complete "${cur}"',
		'	return 0',
		'}',
		'',
		'complete -F _' + bin_name + '_main ' + bin_name,
		'']
		compfile.write("\n".join(comp))

	target="/usr/share/bash-completion/completions/"+bin_name
	run(["sudo", "cp", comp_filepath, target], check=True)
	print("Auto-completion configuration "+comp_filepath+" deployed as "+target)

if __name__ == "__main__":
    main(sys.argv[1:])
	
