/// @desc Destroy resources
buffer_delete(buffer);
buffer_delete(surf_buffer);
if (surface_exists(surf)) surface_free(surf);
