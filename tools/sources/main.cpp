#include <algorithm>
#include <ctime>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include <boost/filesystem.hpp>
#include <boost/optional.hpp>

#include <libxml/tree.h>

#include "lml.hpp"
#include "render.hpp"
#include "sam.hpp"
#include "xml.hpp"

struct post {
  std::string date, source, target, name, title;
};

bool source_modified(std::string source, std::string target) {
  std::time_t source_time, target_time;

  source_time = boost::filesystem::last_write_time(source);

  try {
    target_time = boost::filesystem::last_write_time(target);
    return source_time > target_time;
  } catch (...) {
    return true;
  }
}

void generate_posts(const std::vector<struct post> &posts) {
  for (struct post p : posts) {
    if (source_modified(p.source, p.target)) {
      boost::optional<xmlDocPtr> xml = nullptr;

      if (p.source.substr(p.source.size() - 4) == ".sam") {
        xml = sam_parse(p.source);
      } else if (p.source.substr(p.source.size() - 4) == ".lml") {
        xml = lml_parse(p.source);
      }

      if (xml) {
        render_article(xml.value(), p.target, p.date);
        xmlFreeDoc(xml.value());
      }
    }
  }
}

xmlDocPtr post_list(const std::vector<struct post> &posts,
                    boost::optional<size_t> limit) {
  xmlDocPtr doc = xmlNewDoc("1.0"_xml);
  xmlNodePtr root = xmlNewNode(nullptr, "posts"_xml);
  xmlDocSetRootElement(doc, root);

  std::vector<struct post>::const_iterator end;

  if (limit)
    end = posts.begin() + std::min(limit.value(), posts.size());
  else
    end = posts.end();

  for (std::vector<struct post>::const_iterator post = posts.begin();
       post != end; ++post) {
    xmlNodePtr node = xmlNewChild(root, nullptr, "post"_xml, nullptr);

    xmlNewChild(node, nullptr, "title"_xml,
                xmlEncodeEntitiesReentrant(doc, xml_string(post->title)));
    xmlNewChild(node, nullptr, "creation-date"_xml, xml_string(post->date));
    xmlNewChild(node, nullptr, "uri"_xml, xml_string('/' + post->target));
  }

  return doc;
}

void generate_pages() {
  std::vector<boost::filesystem::path> directories = {"blog", "logo"};

  for (boost::filesystem::path directory : directories) {
    for (boost::filesystem::directory_entry entry :
         boost::filesystem::directory_iterator("_sources/pages" / directory)) {
      std::string source = entry.path().string();
      boost::filesystem::path path = entry.path();
      std::string target =
          (directory / path.replace_extension(".html").filename()).string();

      if (source_modified(source, target)) {
        boost::optional<xmlDocPtr> xml = sam_parse(source);

        if (xml) {
          render_article(xml.value(), target, boost::none);
          xmlFreeDoc(xml.value());
        }
      }
    }
  }
}

int main(void) {
  std::vector<struct post> posts;

  for (boost::filesystem::directory_entry entry :
       boost::filesystem::directory_iterator("_sources/posts")) {
    struct post post;

    post.source = entry.path().string();

    std::string name = entry.path().filename().string();
    post.date = name.substr(0, 10);
    post.name = name.substr(11, name.size() - 15);

    post.target = "blog/" + post.date.substr(0, 4) // year
                  + '/' + post.date.substr(5, 2)   // month
                  + '/' + post.date.substr(8, 2)   // day
                  + '/' + post.name + ".html";

    std::ifstream in(post.source);
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
            [](struct post a, struct post b) { return a.source > b.source; });

  render_home(post_list(posts, 10), "index.html");
  render_archive(post_list(posts, boost::none), "blog/archive.html");
}
