# cdi-zsh
 Interactive `cd` for Z shell

This script is a modified and partly improved translation of [cdi.sh](https://github.com/antonioolf/cdi) which is an interactive `cd` for Bash.

## Installation

- Download the [cdi.zsh](https://raw.githubusercontent.com/1jss/cdi-zsh/master/cdi.zsh) script and place it in `/usr/local/bin`.
- Add an alias for the script to your `.zshrc` file:
```zsh
alias cdi='. /usr/local/bin/cdi.zsh'
```

Note that the `.` in the alias is important as the script needs to be executed in the same context to be able to change the directory.

## Usage

Type `cdi` in your terminal and navigate with your arrow keys.

## License
[MIT](https://opensource.org/licenses/MIT)
