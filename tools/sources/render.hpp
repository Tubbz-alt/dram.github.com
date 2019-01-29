#ifndef RENDER_HPP
#define RENDER_HPP

#include <string>

#include <boost/filesystem.hpp>
#include <boost/optional.hpp>

#include <libxml/tree.h>

void render_article(xmlDocPtr content, boost::filesystem::path output,
                    boost::optional<std::string> date);
void render_home(xmlDocPtr posts, boost::filesystem::path output);
void render_archive(xmlDocPtr posts, boost::filesystem::path output);

#endif
