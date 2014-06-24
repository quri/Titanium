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