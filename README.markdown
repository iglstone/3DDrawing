3d打印画画程序，来源于开源项目Smooth line UIView，记录坐标，然后转换成3d打印机的可执行程序，最终给实现3d打印机画画。

The goal of this project is to create a UIView that can generate smooth lines from touch input in a reasonably fast manner without moving to a more complex framework like OpenGL. 

*Update:* Completely re-written smooth line algorithm to use native CGContext quadratic curves. The result is much faster and smoother drawing. There's no more need for switching between agorithms.

Many thanks to [Ginamin](http://stackoverflow.com/users/431480/ginamin) for his elegant solution.

The Smooth Line View code is licensed under the MIT License: [http://opensource.org/licenses/MIT](http://opensource.org/licenses/MIT)
