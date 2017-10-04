Title: new vs. initialize

new vs. initialize 可能是大部分采用 Squeak 来学习 Smalltalk 的人迟早要接触到一个问题。而我则是从 BDFFontReader 的一个 bug 开始。

这个 bug Robert Withers 在 2007-09 就[报告][1]过。可能是没有添加到 Bug Reporter 的原因，直到 08-12，Tim 将它提交到 [Mantics][2]，这是在 Greg A. Woods 发了如下两封Mail[1][3][2][4] 之后，其中就有对 new 中调用 initialize 的讨论，ST-80 中 new 并不调用 initialize，这是在 Squeak 3.7 加入的，通过 3.7 的 Change Sorter 可以看到是 Noury Bouraqadi 做的修改。之后就可以找到[源头][5]。从中可以看到遵循标准的复杂性。

讲了一堆历史，对于现在的我们如何使用，可以参考 [Seaside][6]。 

[1]: http://lists.squeakfoundation.org/pipermail/squeak-dev/2007-September/120822.html
[2]: http://bugs.squeak.org/view.php?id=7241
[3]: http://lists.squeakfoundation.org/pipermail/squeak-dev/2008-December/132811.html
[4]: http://lists.squeakfoundation.org/pipermail/squeak-dev/2008-December/132828.html
[5]: http://lists.squeakfoundation.org/pipermail/squeak-dev/2003-September/066069.html
[6]: https://github.com/SeasideSt/Seaside/wiki/Object-Initialization
