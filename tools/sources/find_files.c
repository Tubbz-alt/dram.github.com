#include <glob.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int find_files(char const *pattern, int name_max, char **output, int *count)
{
	glob_t gl;

	if (glob(pattern, 0, 0, &gl) != 0)
		perror("glob");
	else {
		char *buffer = malloc(name_max * gl.gl_pathc + 1);
		char *p = buffer;

		for (int i = 0; i < gl.gl_pathc; i++, p += name_max)
			sprintf(p, "%-*s", name_max, gl.gl_pathv[i]);

		*count = gl.gl_pathc;
		*output = buffer;
	}

	globfree(&gl);
}
