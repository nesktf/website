import sys

from pygments import highlight
from pygments.lexers import get_lexer_by_name
from pygments.formatters import HtmlFormatter

def main():
    lexer = sys.argv[1]
    input_file = sys.argv[2]
    output_file = sys.argv[3]
    formatter = HtmlFormatter(style="nord",
                              linenos=False,
                              noclasses=True,
                              nobackground=True,
                              cssclass='code-block',
                              cssstyles="",
                              prestyles="")
    with open(input_file, "r") as input:
        html = highlight(input.read(), get_lexer_by_name(lexer), formatter)
        with open(output_file, "w") as output:
            output.write(html)

if (__name__ == "__main__"):
    main()
