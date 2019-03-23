all: TestJavaFX.jar

TestJavaFX.jar: TestJavaFX.java
	javac $^
	jar -cfe TestJavaFX.jar TestJavaFX TestJavaFX.class FXApplication.class
