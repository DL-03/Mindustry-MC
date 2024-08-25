/* hjson_m.h */

#ifndef GODOT_HJSON_H
#define GODOT_HJSON_H

#include "core/object/ref_counted.h"

class HJSON : public RefCounted {
	GDCLASS(HJSON, RefCounted);

protected:
	static void _bind_methods();

public:
	bool say_text(String p_txt);

	HJSON();
};

#endif // GODOT_HJSON_M_H