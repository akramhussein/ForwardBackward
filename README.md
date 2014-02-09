ForwardBackward
===============

Homage to [FrontBack](http://www.frontback.me) iOS app without the social network.

ForwardBackward is a self contained app that doesn't require any setup. Just take a picture on your forward and backwards cameras and share!

I wrote this app to effectively pluck out the cool feature they had built without needing to set up another social network account. As there was no intention to ever ship this, there are a few quirks that need to be resolved...see below!

All assets were hand-rolled using [Sketch](http://www.bohemiancoding.com/sketch/).

![Screenshots](https://github.com/akramhussein/ForwardBackward/blob/master/Assets/screenshots.png?raw=true)

__Features included:__

* Tap to set auto-focus/auto-exposure
* Flash on/off
* Share with iOS built-in channels/social networks (e.g. SMS, Mail, Twitter, Facebook etc)
* Save to custom photo library

__Thanks__

* [UIImage+Resize category](http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/)
* [ALAssetsLibrary+CustomPhotoAlbum category](https://github.com/Kjuly/ALAssetsLibrary-CustomPhotoAlbum)

__Notes__

I wrote this app after work over 2 evenings. I haven't been able to thoroughly debug it so there may be bugs/memory leaks/odd quirks! 

>= iOS 7

__Known bugs__

* Small delay in camera switching/image view setting.
* Images incorrectly cropped/scaled.
