#ifndef SAM_HPP
#define SAM_HPP

#include <string>

#include <boost/optional.hpp>

#include <libxml/tree.h>

boost::optional<xmlDocPtr> sam_parse(std::string path);

#endif
