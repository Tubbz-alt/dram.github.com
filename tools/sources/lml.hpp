#ifndef LML_HPP
#define LML_HPP

#include <string>

#include <boost/filesystem.hpp>
#include <boost/optional.hpp>

#include <libxml/tree.h>

boost::optional<xmlDocPtr> lml_parse(boost::filesystem::path path);

#endif
