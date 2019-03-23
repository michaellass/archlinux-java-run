PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
JAVADIR = $(PREFIX)/share/java
LICENSEDIR = $(PREFIX)/share/licenses

JARS = tests/TestJavaFX.jar

.PHONY: install tests clean

install:
	tmpfile=`mktemp`; \
	echo "Using temporary file $$tmpfile"; \
	sed 's|###JAVADIR###|$(JAVADIR)|g' archlinux-java-run.sh > "$$tmpfile"; \
	install -Dm 755 "$$tmpfile" $(DESTDIR)$(BINDIR)/archlinux-java-run; \
	rm "$$tmpfile"
	install -dm 755 $(DESTDIR)$(JAVADIR)/archlinux-java-run
	cp $(JARS) $(DESTDIR)$(JAVADIR)/archlinux-java-run/
	install -Dm 644 LICENSE $(DESTDIR)$(LICENSEDIR)/archlinux-java-run/LICENSE

tests:
	$(MAKE) -C tests

clean:
	$(MAKE) -C tests clean
