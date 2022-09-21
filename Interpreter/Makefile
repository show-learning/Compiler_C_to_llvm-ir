all:
	java -cp antlr-3.5.2-complete.jar org.antlr.Tool myInterp.g
	javac -cp antlr-3.5.2-complete.jar:. *.java
	java -cp antlr-3.5.2-complete.jar:. myInterp_test test.c > t1.out
	java -cp antlr-3.5.2-complete.jar:. myInterp_test test2.c > t2.out
	java -cp antlr-3.5.2-complete.jar:. myInterp_test test3.c > t3.out
clean:
	rm -rf myInterpLexer.java
	rm -rf myInterpParser.java
	rm -rf *.out
	rm -rf *.class
	rm -rf *.tokens
