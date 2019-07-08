#ifndef SAM_HPP
#define SAM_HPP

#include <optional>
#include <string>

#include <boost/filesystem.hpp>

#include <libxml/tree.h>

std::optional<xmlDocPtr> sam_parse(boost::filesystem::path path);

#endif
