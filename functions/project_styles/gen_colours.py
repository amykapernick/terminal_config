import fire, re
from pyperclip import copy
from humps import pascalize

def filter_empty(variable):
	return variable != ''

def gen_colours(gutenberg=False) :
	print('Enter your colours as Sass variables (Ctrl-D to save it):')
	colourVariables = []
	while True:
		try:
			line = input()
		except EOFError:
			break
		colourVariables.append(line)

	colourVariables = list(filter(filter_empty, colourVariables))

	colours = {}
	coloursList = '$coloursList: (\n'


	for i, colour in enumerate(colourVariables):
		colourMatch = re.compile('\$((?:\w|_|-)+): ((?:\$(\w|_|-)+)|(?:#\w{3,8}));$', re.IGNORECASE).search(colour)	

		colourName = colourMatch.group(1)
		colourValue = colourMatch.group(2)

		colours[colourName] = colourValue
		
		coloursList += "\t'" + colourName + "': $" + colourName + ",\n"

	coloursList += ");"


	if(gutenberg):
		colourTheme = '$colours = [\n'

		for colour in colours:
			colourValue = colours[colour]
			existingVariable = re.compile('^\$((?:\w|_|-)+)', re.IGNORECASE).search(colourValue)
			colourName = re.sub(r"(\w)([A-Z])", r"\1 \2", pascalize(colour))

			if(existingVariable):
				colourValue = colours[existingVariable.group(1)]

			colourTheme += "\t[\n\t\t'name'  => '" + colourName + "',\n\t\t'slug'  => '" + colour + "',\n\t\t'color' => '" + colourValue + "',\n\t],\n"
				
		colourTheme += '];'

		copy(colourTheme)
		print('Colours list for Gutenberg has been copied to the clipboard')


	else:
		copy(coloursList)
		print('Colours list for Sass has been copied to the clipboard')

	


if __name__ == "__main__":
    fire.Fire(gen_colours)