#ifndef LML_HPP
#define LML_HPP

#include <string>

#include <boost/optional.hpp>

#include <libxml/tree.h>

boost::optional<xmlDocPtr> lml_parse(std::string path);

#endif
