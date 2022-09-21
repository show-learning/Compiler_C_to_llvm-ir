all:
	java -cp antlr-3.5.2-complete.jar org.antlr.Tool myCompiler.g
	javac -cp ./antlr-3.5.2-complete.jar myCompilerLexer.java myCompilerParser.java myCompiler_test.java
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test test1.c > test1.ll
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test test2.c > test2.ll
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test test3.c > test3.ll

t1:
	clang test1.ll
	./a.out

t2:
	clang test2.ll
	./a.out

t3:
	clang test3.ll
	./a.out

clean:
	rm -rf myCompilerLexer.java
	rm -rf myCompilerParser.java
	rm -rf *.class
	rm -rf *.tokens
	rm -rf *.ll
	rm -rf a.out
