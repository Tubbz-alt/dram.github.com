#ifndef SAM_HPP
#define SAM_HPP

#include <string>

#include <boost/filesystem.hpp>
#include <boost/optional.hpp>

#include <libxml/tree.h>

boost::optional<xmlDocPtr> sam_parse(boost::filesystem::path path);

#endif
