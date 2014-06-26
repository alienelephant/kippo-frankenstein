# Copyright (c) 2009 Upi Tamminen <desaster@gmail.com>
# See the COPYRIGHT file for more information

# Random commands when running new executables

from kippo.core.honeypot import HoneyPotCommand

commands = {}
clist = []

class command_prompt01(HoneyPotCommand):
    def start(self):
        self.write('Are you sure? [y/N]: ')

    def lineReceived(self, data):
        self.writeln('Interrupted system call')
        self.exit()
clist.append(command_prompt01)

class command_prompt02(HoneyPotCommand):
    def start(self):
        self.write('> ')

    def lineReceived(self, data):
        self.writeln('Function not implemented')
        self.exit()
clist.append(command_prompt02)

class command_ioerr(HoneyPotCommand):
    def call(self):
        self.writeln('I/O error')
clist.append(command_ioerr)

class command_needlib(HoneyPotCommand):
    def call(self):
        self.writeln('Can not access a needed shared library')
clist.append(command_needlib)

class command_toomanylib(HoneyPotCommand):
    def call(self):
        self.writeln('Attempting to link in too many shared libraries')
clist.append(command_toomanylib)

class command_nomem(HoneyPotCommand):
    def call(self):
        self.writeln('Out of memory')
clist.append(command_nomem)

class command_noop(HoneyPotCommand):
    def call(self):
        self.writeln('Operation not permitted')
clist.append(command_noop)

class command_noperm(HoneyPotCommand):
    def call(self):
        self.writeln('Permission denied')
clist.append(command_noperm)

class command_segfault(HoneyPotCommand):
    def call(self):
        self.writeln('Segmentation fault')
clist.append(command_segfault)

class command_libgnome(HoneyPotCommand):
    def call(self):
        self.writeln('error while loading shared libraries: libgnome.so.32: cannot open shared object file: No such file or directory')
clist.append(command_libgnome)

class command_xconnect(HoneyPotCommand):
    def call(self):
        self.writeln('unable to open display ":0"')
clist.append(command_xconnect)

# vim: set sw=4 et:
