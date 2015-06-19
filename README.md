# hubot-todo

A Hubot script that manage TODOs.

![](http://img.f.hatena.ne.jp/images/fotolife/b/bouzuya/20140922/20140922223214.gif)

## Installation

    $ npm install git://github.com/bouzuya/hubot-todo.git

or

    $ # TAG is the package version you need.
    $ npm install 'git://github.com/bouzuya/hubot-todo.git#TAG'

## Example

    bouzuya> hubot help todo
      hubot> hubot todo add <task> - add TODO
      hubot> hubot todo list - list TODOs
      hubot> hubot todo done <task no> - delete TODO

    (add TODOs)
    bouzuya> hubot todo add Hubot スクリプトを書かなきゃ
      hubot> (1) Hubot スクリプトを書かなきゃ
    bouzuya> hubot todo add 毎日 Hubot スクリプトを書かなきゃ
      hubot> (2) 毎日 Hubot スクリプトを書かなきゃ

    (list TODOs)
    bouzuya> hubot todo list
      hubot> (1) Hubot スクリプトを書かなきゃ
             (2) 毎日 Hubot スクリプトを書かなきゃ

    (delete TODO)
    bouzuya> hubot todo done 2
      hubot> (2) 毎日 Hubot スクリプトを書かなきゃ
    bouzuya> hubot todo list
      hubot> (1) Hubot スクリプトを書かなきゃ

## Configuration

See [`src/scripts/todo.coffee`](src/scripts/todo.coffee).

## Development

### Run test

    $ npm test

### Run robot

    $ npm run robot

## License

[MIT](LICENSE)

## Author

[bouzuya][user] &lt;[m@bouzuya.net][mail]&gt; ([http://bouzuya.net][url])

## Badges

[![Build Status][travis-badge]][travis]
[![Dependencies status][david-dm-badge]][david-dm]

[travis]: https://travis-ci.org/bouzuya/hubot-todo
[travis-badge]: https://travis-ci.org/bouzuya/hubot-todo.svg?branch=master
[david-dm]: https://david-dm.org/bouzuya/hubot-todo
[david-dm-badge]: https://david-dm.org/bouzuya/hubot-todo.png
[user]: https://github.com/bouzuya
[mail]: mailto:m@bouzuya.net
[url]: http://bouzuya.net
