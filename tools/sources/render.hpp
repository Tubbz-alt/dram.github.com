#ifndef RENDER_HPP
#define RENDER_HPP

#include <string>

#include <boost/optional.hpp>

#include <libxml/tree.h>

void render_article(xmlDocPtr content, std::string output,
                    boost::optional<std::string> date);
void render_main(xmlDocPtr content, std::string output,
                 boost::optional<std::string> title);
void render_home(xmlDocPtr posts, std::string output);
void render_archive(xmlDocPtr posts, std::string output);

#endif
