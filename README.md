[![Platform](https://img.shields.io/cocoapods/p/Titanium.svg?style=flat)](http://cocoadocs.org/docsets/Titanium)
[![Version](https://img.shields.io/cocoapods/v/Titanium.svg?style=flat)](http://cocoadocs.org/docsets/Titanium)
[![CI](http://img.shields.io/travis/quri/Titanium.svg?style=flat)](https://travis-ci.org/quri/Titanium)
[![License](https://img.shields.io/cocoapods/l/Titanium.svg?style=flat)](http://cocoadocs.org/docsets/Titanium)

Titanium
========

Titanium is a library that provides a way to view full screen images from thumbnail previews.

Usage
-----

The main class of Titanium is `ESImageViewController`. It uses a custom modal transition to present and dismiss itslef, as well as gesture recognizers to provide zooming capabilities.
Using Titanium to display an image is easy. Just follow these steps:

1. Create a new instance of `ESImageViewController`.
2. Set the `image` property.
3. Set the `tappedThumbnail` property. This will be used to animate from the thumbnail into the full-screen imageView.
4. Present the instance.

For an example of how to use `ESImageViewController` with a storyboard segue, take a look at `-[ESImageViewController prepareForSegue:sender:]`.
