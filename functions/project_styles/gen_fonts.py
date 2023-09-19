import fire
import re
import pyperclip
from os import listdir, getcwd
from os.path import isfile, join

fileFormats = {
	'ttf': 'truetype',
	'otf': 'opentype',
	'woff': 'woff',
	'woff2': 'woff2'
}

fontWeights = {
	'Hairline': '50',
	'Thin': '100',
	'ExtraLight': '200',
	'Light': '300',
	'Regular': '400',
	'Medium': '500',
	'SemiBold': '600',
	'Bold': '700',
	'ExtraBold': '800',
	'Black': '900',
	'hairline': '50',
	'thin': '100',
	'extralight': '200',
	'light': '300',
	'regular': '400',
	'medium': '500',
	'semibold': '600',
	'bold': '700',
	'extrabold': '800',
	'black': '900'
}

def gen_fonts(folder):
	cwd = getcwd()
	fontFiles = [join(cwd, f) for f in listdir(cwd) if 
	isfile(join(cwd, f))]

	fontFaces = ''
	for font in fontFiles:
		match = re.compile('(\w+)-(\w+)\.(ttf|woff|woff2|otf)$', re.IGNORECASE).search(font)
		fileName = match.group(0)
		family = match.group(1)
		type = match.group(2)
		format = match.group(3)

		fontTypes = re.compile('([^I]+)?(Italic)?$').search(type)
		
		italic = True if fontTypes.group(2) else False
		weight = fontTypes.group(1) if fontTypes.group(1) else 'Regular'
		
		style = 'italic' if italic else 'normal'

		familyName = re.sub(r"(\w)([A-Z])", r"\1 \2", family)

		fontFaces += '@font-face {\n\tfont-family: "' + familyName + '";\n\tfont-style: ' + style + ';\n\tfont-weight: ' + fontWeights[weight] + ';\n\tsrc: url("' + folder + fileName + '") format("' + fileFormats[format] + '");\n}\n\n'	

	pyperclip.copy(fontFaces)
	

if __name__ == "__main__":
    fire.Fire(gen_fonts)