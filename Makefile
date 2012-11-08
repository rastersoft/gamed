gamed: gamed.vala
	valac --pkg=gee-1.0 --pkg=glib-2.0 --pkg=gio-2.0 --pkg=posix gamed.vala -o gamed

clean:
	rm gamed

install: gamed
	/usr/bin/install -d /usr/local/bin
	/usr/bin/install -d /etc/dbus-1/system.d
	/usr/bin/install -d /etc/xdg/autostart
	/usr/bin/install -d /usr/local/share/dbus-1/system-services
	/usr/bin/install gamed /usr/local/bin
	/usr/bin/install renice_gamed /usr/local/bin
	/usr/bin/install gamed.conf /etc
	/usr/bin/install com.rastersoft.gamed.conf /etc/dbus-1/system.d/
	/usr/bin/install com.rastersoft.gamed.service /usr/local/share/dbus-1/system-services/
	/usr/bin/install gamed.desktop /etc/xdg/autostart/

uninstall:
	/bin/rm /usr/local/bin/gamed
	/bin/rm /usr/local/bin/renice_gamed
	/bin/rm /etc/gamed.conf
	/bin/rm /etc/dbus-1/system.d/com.rastersoft.gamed.conf
	/bin/rm /usr/local/share/dbus-1/system-services/com.rastersoft.gamed.service
	/bin/rm /etc/xdg/autostart/gamed.desktop
