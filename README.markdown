# oh

* http://github.com/aasmith/oh

## Description

An API for OptionsHouse (http://optionshouse.com).

Currently provides a mechanism for pulling stock and option quotes.

## Synopsis

```
  # The basic oh API. Calls to the API return parsed Nokogiri documents.
  require 'oh'

  # An object wrapper around the basic api. Marshals above responses into
  # handy Ruby objects, defined in lib/ohbjects.
  require 'ohbjects'
  Ohbjects.activate

  # You defined these vars somewhere else, right?
  o = Oh.new(username, password)

  # Use the virtual account so we don't accidentally spend all your
  # hard-earned dollars on Frozen Pork Belly futures.
  account = o.accounts.detect { |a| a.virtual? }
  o.account_id = account.id

  # Bask is the glory of knowing the latest price for the 
  # iPath Dow Jones-AIG Coffee Total Return Sub-Index ETN.
  p o.quote("JO")

  # Do something like this every 120 seconds or so, otherwise your
  # token will expire.
  o.keep_alive
```

## Requirements

*  Nokogiri
*  An OptionsHouse account

## Install

```
  sudo gem install oh
```

## License

Copyright (c) 2010 Andrew A. Smith

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
