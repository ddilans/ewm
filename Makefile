# do not include any other makefiles above this line.
THISMAKEFILE=$(lastword $(MAKEFILE_LIST))
# allow trivial out-of-tree builds
src_dir=$(dir $(THISMAKEFILE))
VPATH=$(src_dir)

############################################################################
# Installation paths

prefix = /usr
bindir = $(prefix)/bin
datarootdir = $(prefix)/share
desktopfilesdir = $(datarootdir)/applications

############################################################################
# Features

# Uncomment to enable info banner on holding Ctrl+Alt+I.
OPT_CPPFLAGS += -DINFOBANNER

# Uncomment to show the same banner on moves and resizes.  Can be SLOW!
#OPT_CPPFLAGS += -DINFOBANNER_MOVERESIZE

# Uncomment to support the Xrandr extension (thanks, Yura Semashko).
OPT_CPPFLAGS += -DRANDR
OPT_LDLIBS   += -lXrandr

# Uncomment to support shaped windows.
OPT_CPPFLAGS += -DSHAPE
OPT_LDLIBS   += -lXext

# Uncomment to enable solid window drags.  This can be slow on old systems.
OPT_CPPFLAGS += -DSOLIDDRAG

# Uncomment to compile in certain text messages like help.  Recommended.
OPT_CPPFLAGS += -DSTDIO

# Uncomment to support virtual desktops.
OPT_CPPFLAGS += -DVWM

# Uncomment to move pointer around on certain actions.
#OPT_CPPFLAGS += -DWARP_POINTER

# Uncomment to use Ctrl+Alt+q instead of Ctrl+Alt+Escape.  Useful for Cygwin.
#OPT_CPPFLAGS += -DKEY_KILL=XK_q

# Uncomment to include whatever debugging messages I've left in this release.
#OPT_CPPFLAGS += -DDEBUG   # miscellaneous debugging
#OPT_CPPFLAGS += -DXDEBUG  # show some X calls

############################################################################
# Include file and library paths

# Most Linux distributions don't separate out X11 from the rest of the
# system, but some other OSs still require extra information:

# Solaris 10:
#OPT_CPPFLAGS += -I/usr/X11/include
#LDFLAGS  += -R/usr/X11/lib -L/usr/X11/lib

# Solaris <= 9 doesn't support RANDR feature above, so disable it there
# Solaris 9 doesn't fully implement ISO C99 libc, to suppress warnings, use:
#OPT_CPPFLAGS += -D__EXTENSIONS__

# Mac OS X:
#LDFLAGS += -L/usr/X11R6/lib

############################################################################
# Build tools

# Change this if you don't use gcc:
CC = gcc

# Override if desired:
CFLAGS = -Os
WARN = -Wall -W -Wstrict-prototypes -Wpointer-arith -Wcast-align \
	-Wshadow -Waggregate-return -Wnested-externs -Winline -Wwrite-strings \
	-Wundef -Wsign-compare -Wmissing-prototypes -Wredundant-decls

# Enable to spot explicit casts that strip constant qualifiers.
# generally not needed, since an explicit cast should signify
# the programmer guarantees no undefined behaviour.
#WARN += -Wcast-qual

# For Cygwin:
#EXEEXT = .exe

# Override INSTALL_STRIP if you don't want a stripped binary
INSTALL = install
INSTALL_STRIP = -s
INSTALL_DIR = $(INSTALL) -d -m 0755
INSTALL_FILE = $(INSTALL) -m 0644
INSTALL_PROGRAM = $(INSTALL) -m 0755 $(INSTALL_STRIP)

############################################################################
# You shouldn't need to change anything beyond this point

version = 1.1.1
distdir = ewm-$(version)

# Generally shouldn't be overridden:
#  _XOPEN_SOURCE=700 incorporates POSIX.1-2008, for putenv, sigaction and strdup
EVILWM_CPPFLAGS = $(CPPFLAGS) $(OPT_CPPFLAGS) -DVERSION=\"$(version)\" \
	-D_XOPEN_SOURCE=700
EVILWM_CFLAGS = -std=c99 $(CFLAGS) $(WARN)
EVILWM_LDFLAGS = $(LDFLAGS)
EVILWM_LDLIBS = -lX11 $(OPT_LDLIBS) $(LDLIBS)

HEADERS = ewm.h keymap.h list.h log.h xconfig.h
OBJS = client.o events.o ewmh.o list.o main.o misc.o new.o screen.o xconfig.o

.PHONY: all
all: ewm$(EXEEXT)

$(OBJS): $(HEADERS)

%.o: %.c
	$(CC) $(EVILWM_CFLAGS) $(EVILWM_CPPFLAGS) -c $<

ewm$(EXEEXT): $(OBJS)
	$(CC) -o $@ $(OBJS) $(EVILWM_LDFLAGS) $(EVILWM_LDLIBS)

.PHONY: install
install: ewm$(EXEEXT)
	$(INSTALL_DIR) $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) ewm$(EXEEXT) $(DESTDIR)$(bindir)/
	$(INSTALL_DIR) $(DESTDIR)$(desktopfilesdir)
	$(INSTALL_FILE) $(src_dir)/ewm.desktop $(DESTDIR)$(desktopfilesdir)/

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(bindir)/ewm$(EXEEXT)
	rm -f $(DESTDIR)$(desktopfilesdir)/ewm.desktop

.PHONY: dist
dist:
	git archive --format=tar --prefix=$(distdir)/ HEAD > $(distdir).tar
	gzip -f9 $(distdir).tar

.PHONY: debuild
debuild: dist
	-cd ..; rm -rf $(distdir)/ $(distdir).orig/
	mv $(distdir).tar.gz ../ewm_$(version).orig.tar.gz
	cd ..; tar xfz ewm_$(version).orig.tar.gz
	rsync -axH debian --exclude='debian/.git/' --exclude='debian/_darcs/' ../$(distdir)/
	cd ../$(distdir); debuild

.PHONY: clean
clean:
	rm -f ewm$(EXEEXT) $(OBJS)
