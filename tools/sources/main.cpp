#include <algorithm>
#include <ctime>
#include <fstream>
#include <iostream>
#include <regex>
#include <string>
#include <vector>

#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>
#include <boost/optional.hpp>

#include <libxml/tree.h>

#include "lml.hpp"
#include "render.hpp"
#include "sam.hpp"
#include "xml.hpp"

struct Post {
  boost::filesystem::path source, target;
  std::string date, name, title;
};

bool source_modified(boost::filesystem::path source,
                     boost::filesystem::path target) {
  std::time_t source_time, target_time;

  source_time = boost::filesystem::last_write_time(source);

  try {
    target_time = boost::filesystem::last_write_time(target);
    return source_time > target_time;
  } catch (...) {
    return true;
  }
}

void generate_posts(const std::vector<Post> &posts) {
  for (Post p : posts) {
    if (source_modified(p.source, p.target)) {
      boost::optional<xmlDocPtr> xml = nullptr;

      if (p.source.extension() == ".sam") {
        xml = sam_parse(p.source);
      } else if (p.source.extension() == ".lml") {
        xml = lml_parse(p.source);
      }

      if (xml) {
        render_article(xml.value(), p.target, p.date);
        xmlFreeDoc(xml.value());
      }
    }
  }
}

xmlDocPtr post_list(const std::vector<Post> &posts,
                    boost::optional<size_t> limit) {
  xmlDocPtr doc = xmlNewDoc("1.0"_xml);
  xmlNodePtr root = xmlNewNode(nullptr, "posts"_xml);
  xmlDocSetRootElement(doc, root);

  std::vector<Post>::const_iterator end;

  if (limit)
    end = posts.begin() + std::min(limit.value(), posts.size());
  else
    end = posts.end();

  for (std::vector<Post>::const_iterator post = posts.begin(); post != end;
       ++post) {
    xmlNodePtr node = xmlNewChild(root, nullptr, "post"_xml, nullptr);

    xmlNewChild(node, nullptr, "title"_xml,
                xmlEncodeEntitiesReentrant(doc, xml_string(post->title)));
    xmlNewChild(node, nullptr, "creation-date"_xml, xml_string(post->date));
    xmlNewChild(node, nullptr, "uri"_xml,
                xml_string(("/" / post->target).string()));
  }

  return doc;
}

void generate_pages() {
  std::vector<boost::filesystem::path> directories = {"blog", "logo"};

  for (boost::filesystem::path directory : directories) {
    for (boost::filesystem::directory_entry entry :
         boost::filesystem::directory_iterator("_sources/pages" / directory)) {
      boost::filesystem::path source = entry.path();
      boost::filesystem::path target =
          directory / source.filename().replace_extension(".html");

      if (source_modified(source, target)) {
        boost::optional<xmlDocPtr> xml = nullptr;

        if (source.extension() == ".sam") {
          xml = sam_parse(source);
        } else if (source.extension() == ".lml") {
          xml = lml_parse(source);
        }

        if (xml) {
          render_article(xml.value(), target, boost::none);
          xmlFreeDoc(xml.value());
        }
      }
    }
  }
}

int main(void) {
  std::vector<Post> posts;

  for (boost::filesystem::directory_entry entry :
       boost::filesystem::directory_iterator("_sources/posts")) {
    Post post;

    post.source = entry.path();

    std::string filename = entry.path().stem().string();
    std::smatch m;
    std::regex_match(filename, m,
                     std::regex{"(\\d{4})-(\\d{2})-(\\d{2})-(.+)"});
    post.date = m.str(1) + '-' + m.str(2) + '-' + m.str(3);
    post.name = m.str(4);
    post.target = "blog/" + m.str(1) + '/' + m.str(2) + '/' + m.str(3) + '/' +
                  m.str(4) + ".html";

    boost::filesystem::ifstream in(post.source);
    std::getline(in, post.title);
    if (post.title[0] == '[') {
      std::getline(in, post.title);
      post.title = post.title.substr(9, post.title.size() - 10);
    } else {
      post.title = post.title.substr(9, post.title.size() - 9);
    }
    in.close();

    posts.push_back(post);
  }

  generate_posts(posts);
  generate_pages();

  std::sort(posts.begin(), posts.end(),
            [](Post a, Post b) { return a.source > b.source; });

  render_home(post_list(posts, 10), "index.html");
  render_archive(post_list(posts, boost::none), "blog/archive.html");
}
