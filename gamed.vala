/*
 Copyright 2012 (C) Raster Software Vigo (Sergio Costas)

 GAMEd is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.

 GAMEd is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>. */

using GLib;
using Gee;

[DBus (name = "com.rastersoft.gamed")]
public class dbus_class: Object {
	
	public void set_priority(int new_priority) {
		var k = new checker(new_priority);
	}
	
}

class checker: Object {

	private	string[] programs;
	private string[] configuration;
	private int c_priority;

	public checker(int priority=127) {
		
		this.programs = {};
		this.configuration = {};
		
		this.read_config();
		if (priority!=127) {
			this.do_check(priority);
		} else {
			this.do_check(this.c_priority);
		}
		
	}
	
	public int read_config() {

		FileInputStream file_read;

		this.c_priority=-15;
		
		var config_file = GLib.File.new_for_path("/etc/gamed.conf");
		if (!config_file.query_exists (null)) {
			return -1;
		}

		try {
			file_read=config_file.read(null);
		} catch {
			return -2;
		}

		var in_stream = new DataInputStream (file_read);
		
		string line;

		while ((line = in_stream.read_line (null, null)) != null) {
			configuration+=line;
			if ((line.length==0)||(line[0]=='#')) {
				continue;
			}
			if (line.has_prefix("priority:")) {
				this.c_priority=int.parse(line.substring(9));
				stdout.printf("Current priority: %d\n",this.c_priority);
				continue;
			}
			programs+=line;
		}
		in_stream.close();
		return 0;
	}
	
	private void save_config() {
		
		var config_file = GLib.File.new_for_path("/etc/gamed.conf");
		var file_write = config_file.replace(null, false,FileCreateFlags.NONE);
		bool found_priority=false;
		foreach(string s in this.configuration) {
			if (s.has_prefix("priority:")) {
				if (found_priority==false) {
					found_priority=true;
					file_write.write(("priority:%d\n".printf(this.c_priority)).data);
				}
				continue;
			}
			file_write.write(("%s\n".printf(s)).data);
		}
		if (found_priority==false) {
			file_write.write(("priority:%d\n".printf(this.c_priority)).data);
		}
		file_write.close();
	}
	
	public int do_check(int priority) {
		
		string name;

		if (priority<(-15)) {
			priority=-15;
		}

		if (priority!=this.c_priority) {
			this.c_priority=priority;
			this.save_config();
		}

		var d = GLib.Dir.open("/proc");
		while ((name = d.read_name()) != null) {
			var path = GLib.Path.build_filename("/proc",name,"exe");
			var newfile = GLib.File.new_for_path(path);
			string cadena;
			
			char buf[1024];
			if(!newfile.query_exists(null)) {
				continue;
			}
			Posix.readlink(path,buf);
			cadena=(string)buf;
			if (cadena.length==0) {
				continue;
			}

			foreach (var s in this.programs) {
				if (s==cadena) {
					GLib.stdout.printf("Setting priority for %s (%s)\n",s,name);
					var cadena2="renice -n %d -p %s".printf(priority,name);
					Posix.system(cadena2);
					break;
				}
			}
		}
		return 0;
	}
	
}

void on_bus_aquired (DBusConnection conn) {
    
    try {
		var l=conn.register_object<dbus_class> ("/com/rastersoft/gamed", new dbus_class());
	} catch (IOError e) {
		Posix.exit(-1);
	}
}

int main(string[] args) {

	stdout.printf("GAMEd, version 1.2.0\n");

	var k = new checker();
	k = null;
	
	Bus.own_name (BusType.SYSTEM, "com.rastersoft.gamed", BusNameOwnerFlags.NONE, on_bus_aquired , () => {
		}, () => {
		GLib.stderr.printf ("GAMEd is already running\n");
		Posix.exit(-1);
	});

	new MainLoop ().run ();

	return 0;	
}
