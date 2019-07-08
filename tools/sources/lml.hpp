#ifndef LML_HPP
#define LML_HPP

#include <optional>
#include <string>

#include <boost/filesystem.hpp>

#include <libxml/tree.h>

std::optional<xmlDocPtr> lml_parse(boost::filesystem::path path);

#endif
