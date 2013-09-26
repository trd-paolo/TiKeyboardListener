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

## An **spetial** case: scrollviews

Although it's absolutely transparent when you're just using the module, you may find interesting to know that if you add a ScrollView to the created view w/ the module, it doesn't change the view height as he would do if it were some other kind of view. Instead, it's using the contentInset property of the UIScrollView native object. That rocks because avoids weird jumping with the scroll views content offset when the keyboard appears / disappears. 

## Example

```js
var test = 'tab'; // possible values: 'win' | 'nav' | 'tab'

(function (keyboardListener) {
	var win, navWin, tabGroup;
	
	// ****************************************************************************************************************
	// containers

	win = Ti.UI.createWindow({
		backgroundColor: '#fff612'
	});
	
	if (test === 'nav') {
		navWin = Ti.UI.iOS.createNavigationWindow({
			window: win
		});
	}
	else if (test === 'tab') {
		var tab = Titanium.UI.createTab({
			icon: 'KS_nav_views.png',
			title: 'Tab 1',
			window: win
		});
		
		tabGroup = Titanium.UI.createTabGroup();
		tabGroup.addTab(tab);
	};	

	// ****************************************************************************************************************
	// window views 
	
	// the container view which should be resized
	var container = keyboardListener.createView({
		width: Ti.UI.FILL, height: Ti.UI.FILL,
		backgroundColor: '#fff612'
	});
	win.add(container);

	// a bottom cointaner view
	var toolbar = Ti.UI.createView({
		width: Ti.UI.FILL, height: 40,
		backgroundColor: '#ccc',
		bottom: 0
	}),
	trigger = Ti.UI.createTextField({
		height: 20,
		top: 10, left: 10, right: 70,
		backgroundColor: '#fff'
	}),
	blurBtn = Ti.UI.createButton({
		width: 50, height: 20,
		top: 10,
		right: 10,
		title: 'blur'
	});
	toolbar.add(trigger);
	toolbar.add(blurBtn);
	container.add(toolbar);

	// ****************************************************************************************************************
	// keyboard listener stuff

	container.addEventListener('keyboard:show', function (ev) {
		Ti.API.info('* keyboard height is ' + ev.keyboardHeight + ', and my height is now ' + ev.height);
	});
	container.addEventListener('keyboard:hide', function (ev) {
		Ti.API.info('* keyboard height was ' + ev.keyboardHeight + ', and my height is now ' + ev.height);
	});

	blurBtn.addEventListener('click', function () {
		trigger.blur();
	});

	// ****************************************************************************************************************
	// start the show
	if (tabGroup) {
		tabGroup.open();
		return;
	}
	
	if (navWin) {
		navWin.open();
		return;	
	}
	
	win.open();
})(require('net.iamyellow.tikeyboardlistener'));
```

## Author

jordi domenech
jordi@iamyellow.net
http://iamyellow.net
@0xfff612

## License

Copyright 2012 jordi domenech <jordi@iamyellow.net>
Apache License, Version 2.0