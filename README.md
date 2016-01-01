# 💂 Guardian.cr

Guardian is a file guardian that wathcing files of your project and run assigned tasks.

![Guardian](http://i.imgur.com/mUzv2DL.gif)

## Installation

### OS X

```bash
brew tap f/guardian
brew install guardian
```

### From Source

```bash
git clone https://github.com/f/guardian.git && cd guardian
crystal build src/guardian.cr --release
```

## Quickstart

### Crystal Libs

Guardian works seamless with Crystal Projects. It automatically binds itself to
library you use.

```bash
$ crystal init lib yourlib
$ cd yourlib
$ guardian init
Created .guardian.yml of ./src/yourlib.cr
```

### Non-Crystal Libs

You can use Guardian for another projects.

```bash
$ guardian init
Created .guardian.yml
```

## Usage

```bash
$ guardian init
```

It will create a `.guardian.yml` file to use by Guardian.

## `.guardian.yml`

`.guardian.yml` is a simple YAML file.

Simply it has **YAML documents** with seperated by `---` line and each document has
`files` and `run` keys.

`files` key needs a glob pattern, and `run` is a shell command what to run.

```yaml
files: ./**/*.cr
run: crystal build ./src/guardian.cr
---
files: ./shard.yml
run: crystal deps
```

### `%file%` Variable

Guardian replaces `%file%` variable in commands with the changed file.

```yaml
files: ./**/*.txt
run: echo "%file% is changed"
```

Think you have a `hello.txt` in your directory, and Guardian will run `echo "hello.txt is changed"` command when it's changed.

## Running Guardian

```bash
$ guardian
💂Guardian is on duty!
```

## Contributing

1. Fork it ( https://github.com/f/guardian/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [f](https://github.com/f) Fatih Kadir Akın - creator, maintainer
