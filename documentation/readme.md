# TiKeyboardListener Module

## Description

Yet another simple module to do yet another simple thing: adjust content whenever the iOS keyboard appears or disappears. 
I didn't find a simple way to have a toolbar at the bottom of the window that goes up / down as soon as the keyboard is shown / hidden (like Apple Messages app or Whatsapp), so I've written this module.

They say a picture is worth a thousand word! http://www.screenr.com/5xc8

## Using the module

Just create a container view where you're going to add other views (ScrollView, etc.):

```js
var container = require('net.iamyellow.tikeyboardlistener').createView({
	backgroundColor: '#fff'
});
```

That view is just a common plain view, but:

* it always tries to fill its container height (height: Ti.UI.FILL)
* its top is set to 0
* you can add listeners for events 'keyboard:show' and 'keyboard:hide'
* listener callbacks has a single argument with two properties: 'height' (the view height) and 'keyboardHeight' (need help? ;))

## ScrollViews!

Although it's absolutely transparent when you're just using the module, you may find interesting to know that if you add a ScrollView to the created view w/ the module, it doesn't change the view height as he would do if it were some other kind of view. Instead, it's using the contentInset property of the UIScrollView native object. That rocks because avoids weird jumping with the scroll views content offset when the keyboard appears / disappears. 

## Example

https://gist.github.com/3105882

## Author

jordi domenech
jordi@iamyellow.net
http://iamyellow.net
@iamyellow2

## Feedback and Support

jordi@iamyellow.net

## License

Copyright 2012 jordi domenech <jordi@iamyellow.net>
Apache License, Version 2.0