/* register_types.cpp */

#include "register_types.h"

#include "core/object/class_db.h"
#include "hjson_m.h"

void initialize_tts_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	ClassDB::register_class<TTS>();
}

void uninitialize_tts_module(ModuleInitializationLevel p_level) {
	// Nothing to do here in this example.
}