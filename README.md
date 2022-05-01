# CS294-196
Project source code about CS294-196

## test case 1
```
construct graph:
[[[0,1,2,3,4,5],[1,0,2,3,4,5],[2,0,1,3,7,8],[3,0,1,2,4,7,8],[4,0,1,3,5,6,7],[5,0,1,4,6,7,8],[6,4,5,7,8],[7,2,3,4,5,6,8],[8,2,3,4,5,6,7]],[[1,2,5],[2,1,3],[3,2,4],[4,3,5],[5,1,4,6],[6,4,5],[8]],[[2,3],[5,6]],[[3],[6]]]
```
```
bidSubmission
0 [7,5,2,0]
1  [7,5,2,0]
2  [6,6,3,4]
3  [5,4,3,2]
4  [6,4,2,3]
5  [3,5,4,2]
6  [4,2,5,3]
7  [6,3,5,4]
8  [6,3,5,4]
```

```
Seller submission
i j fre V T   msg.value
1 1 30 5 10000000  5
1 2 40 4 10000000  4
2 1 50 4 10000000  4
3 1 60 1 10000000  1
```

## test case 2

```
construct graph:
[[[1,2,3],[2,1,4],[3,1],[4,2]]]

```

```
bidSubmission
1 [2,3]
2 [1,3]
3 [2,4]
4 [1,4]
```

```
Seller submission
i j fre V T   msg.value
1 1 30 5 100000000  1
2 1 40 4 100000000  2
```