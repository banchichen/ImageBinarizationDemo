## 重要提示：请先将项目中的opencv2.framework.zip解压并拖入项目中。
为了避免github的文件最大100M限制...

## 关于OpenCV
[OpenCV](https://github.com/opencv/opencv)是用的3.2.0版本，直接导入会报错，该Demo做了如下修改：           
编译错误：exposure_compensate.hpp:66:12: Expected identifier          
修复方案：把NO改为NO_EXPOSURE_COMPENSATOR = 0          
错误错误：operations.hpp文件217行的Mat A(*this, false), B(rhs, false), X(x, false);   Too many arguments...           
修复方案：改为Mat A(*this, false), B(rhs, false), XX(x, false); 。接下来的X也换成XX即可。

## 相关博客：[阿里数据iOS端线上错误定位方案演进过程](https://www.jianshu.com/p/5d900c2d55ad)
