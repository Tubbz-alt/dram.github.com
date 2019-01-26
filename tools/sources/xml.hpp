#ifndef XML_HPP
#define XML_HPP

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

#endif
