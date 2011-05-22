# makefile for lcurses library for Lua

# dist location
DISTDIR=$(HOME)/dist
TMP=/tmp

# change these to reflect your Lua installation
LUAINC= /usr/include/lua5.1
LUALIB= /usr/lib
LUABIN= /usr/bin
#LUABIN= /mingw/bin

# no need to change anything below here
SHFLAGS= -shared
CFLAGS= $(INCS) $(DEFS) $(WARN) $(SHFLAGS) -O2 -fPIC
DEFS= # -DDEBUG
WARN= -Wall -Werror -ansi #-ansi -pedantic -Wall
INCS= -I$(LUAINC) #-I../curses
LIBS= -L$(LUALIB) -lpanel -lcurses #../curses/panel.a ../curses/pdcurses.a -llualib -llua

MYNAME= curses
MYLIB= l$(MYNAME)

OBJS= $(MYLIB).o

T= $(MYLIB).so

VER=0.2.1
TARFILE = $(DISTDIR)/$(MYLIB)-$(VER).tar.gz
TARFILES = \
	README Makefile \
	lcurses.c lpanel.c \
	lcurses.html \
	requireso.lua curses.lua curses.panel.lua \
	test.lua \
	cui.lua cui.ctrls.lua testcui.lua \
	firework.lua interp.lua

UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
SHFLAGS= -shared
endif
ifeq ($(UNAME), Darwin)
SHFLAGS= -bundle -undefined dynamic_lookup
endif

all: $T

lua: lcurses.c lua.c
	gcc -I. -DDEBUG -g -o lua lua.c lcurses.c -L. -llualib -llua -lpanel -lcurses -lm -ldl

cui: $T
	$(LUABIN)/lua -l$(MYNAME) -l$(MYNAME).panel testcui.lua

test:	$T
	$(LUABIN)/lua -l$(MYNAME) -l$(MYNAME).panel test.lua

$T:	$(OBJS)
	$(CC) $(SHFLAGS) -o $@  $(OBJS) $(LIBS)

lcurses.o: lcurses.c lpanel.c

clean:
	rm -f $(OBJS) $T core core.* a.out

dist:
	@echo 'Exporting...'
	@cvs export -r HEAD -d $(TMP)/$(MYLIB)-$(VER) $(MYLIB)
	@echo 'Compressing...'
	@tar -zcf $(TARFILE) -C $(TMP) $(MYLIB)-$(VER)
	@rm -fr $(TMP)/$(MYLIB)-$(VER)
	@lsum $(TARFILE) $(DISTDIR)/md5sums.txt
	@echo 'Done.'
