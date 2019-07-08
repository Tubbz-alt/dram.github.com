#ifndef RENDER_HPP
#define RENDER_HPP

#include <optional>
#include <string>

#include <boost/filesystem.hpp>

#include <libxml/tree.h>

void render_article(xmlDocPtr content, boost::filesystem::path output,
                    std::optional<std::string> date);
void render_home(xmlDocPtr posts, boost::filesystem::path output);
void render_archive(xmlDocPtr posts, boost::filesystem::path output);

#endif
