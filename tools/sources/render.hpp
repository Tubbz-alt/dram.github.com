#ifndef RENDER_HPP
#define RENDER_HPP

#include <optional>
#include <string>

#include <libxml/tree.h>

inline const xmlChar *xml_string(const char *string) {
  return reinterpret_cast<const xmlChar *>(string);
}

inline const xmlChar *xml_string(std::string string) {
  return xml_string(string.c_str());
}

inline const xmlChar *operator"" _xml(const char *string, size_t) {
  return xml_string(string);
}

void render_article(xmlDocPtr content, std::string output,
                    std::optional<std::string> date);
void render_main(xmlDocPtr content, std::string output,
                 std::optional<std::string> title);
void render_home(xmlDocPtr posts, std::string output);
void render_archive(xmlDocPtr posts, std::string output);

#endif
