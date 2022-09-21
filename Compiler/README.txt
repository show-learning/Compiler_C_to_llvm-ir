姓名：鄭宇軒 	學號：408410062 	系級： 資工三

執行環境

​	Ubuntu  22.04

​	antlr-3.5.2-complete.jar (file at same folder)

執行方式

​	輸入make指令,會編譯和執行 Complier,並將結果輸出到各自的ll中
	輸入make t1 會用clang編譯和執行test1.ll
	輸入make t2 會用clang編譯和執行test2.ll
	輸入make t3 會用clang編譯和執行test3.ll
​	附有make clean指令,能將產出的東西刪除

檔案說明

​	myInterp.g: 定義 interpreter 的 g檔
​	myInterp_test.java: 執行 parser 的 java程式
​	test1.c		test2.c		test3.c: 測試檔
​	Makefile: 編譯及執行程式,也可以刪除產出的檔案
​	README.txt: project說明
	C_subset_description.docx: 使用token的簡介
	
額外支援：
	行內多變數宣告 EX: int a,b;
	多支援宣告float 和 char,但賦值與使用僅支援int
	餘數運算
	printf %d數量沒有限制
	支援for-loop	while-loop	do-while-loop	
