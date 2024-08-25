/* hjson_m.cpp */

#include "hjson_m.h"

#include <hjson.h>

bool HJSON::say_text(String p_txt) {

	//convert Godot String to Godot CharString to C string
	return festival_say_text(p_txt.ascii().get_data());
}

void HJSON::_bind_methods() {

	ClassDB::bind_method(D_METHOD("say_text", "txt"), &HJSON::say_text);
}

HJSON::HJSON() {
	festival_initialize(true, 210000); //not the best way to do it as this should only ever be called once.
}