#ifndef SAM_HPP
#define SAM_HPP

#include <string>

#include <boost/optional.hpp>

boost::optional<std::string> sam_parse(std::string path);

#endif
