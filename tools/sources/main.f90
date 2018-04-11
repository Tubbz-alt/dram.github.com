program main
  use exslt
  use iso_c_binding
  use python
  use posix
  use xml
  use xslt

  implicit none

  integer, parameter :: name_max = 132

  type post
     character(10)       :: date
     character(name_max) :: source, target, name, title
  end type post

  integer                     :: post_count
  type    (post), allocatable :: posts (:)
  type    (c_ptr)             :: python_globals, main_stylesheet

  interface
     subroutine c_find_files(pattern, name_max, output, count) &
          bind(c, name='find_files')
       use :: iso_c_binding, only: c_char, c_int, c_ptr
       character(kind=c_char), intent(in)  :: pattern (*)
       integer  (c_int),       value       :: name_max
       type     (c_ptr),       intent(out) :: output
       integer  (c_int),       intent(out) :: count
     end subroutine c_find_files
  end interface

  block
    type     (c_ptr)               :: cptr
    integer                        :: i, j, res
    integer,             parameter :: n = len('_sources/posts/') + 1
    character(name_max), pointer   :: sources (:)

    call py_initialize()

    python_globals = py_dict_new()

    res = py_dict_set_item_string( &
         python_globals, '__builtins__' // c_null_char, py_eval_get_builtins())

    cptr = py_run_string( &
         'import sys; &
         & sys.path.append("tools/sam"); &
         & import samparser' // c_null_char, &
         py_file_input, python_globals, c_null_ptr)

    call exslt_register_all()

    main_stylesheet = &
         xslt_parse_stylesheet_file('tools/stylesheets/main.xsl\0')

    call c_find_files('_sources/posts/*.sam\0', name_max, cptr, post_count)

    call c_f_pointer(cptr, sources, [post_count])

    allocate(posts (post_count))

    do i = 1, post_count
       j = post_count + 1 - i

       posts(i) % source = sources(j)

       posts(i) % date = sources(j) (n : n + 9)

       posts(i) % name = sources(j) ( &
            n + 11 &
            : index(sources(j), '.sam', back=.true.) - 1 &
            )

       posts(i) % target = 'blog' &
            // '/' // posts(i) % date (1 : 4)  & ! year
            // '/' // posts(i) % date (6 : 7)  & ! month
            // '/' // posts(i) % date (9 : 10) & ! day
            // '/' // trim(posts(i) % name) // '.html'

       open(unit=1, file=sources(j))
       read(1, '(9x, a)') posts(i) % title
       close(1)
    end do

    call generate_posts
    call generate_post_archives
    call generate_pages
    call generate_home_page

    call py_finalize()

    call posix_free(cptr)
  end block

contains

  subroutine generate_posts
    type(c_ptr)                     :: cptr
    integer                         :: i
    integer(c_size_t)               :: size
    integer,          dimension(13) :: source_stat, target_stat

    do i = 1, post_count
       call stat(posts(i) % source, source_stat)
       call stat(posts(i) % target, target_stat)
       if (source_stat(10) > target_stat(10)) then
          cptr = py_run_string( &
               'p = samparser.SamParser();' // &
               'p.parse(open("' // trim(posts(i) % source) // '"));' // &
               c_null_char, &
               py_file_input, python_globals, c_null_ptr)

          cptr = py_run_string('"".join(p.serialize("xml"))' // c_null_char, &
               py_eval_input, python_globals, c_null_ptr)

          if (c_associated(cptr)) then
             cptr = py_unicode_as_utf8_and_size(cptr, size)
             cptr = xml_parse_memory(cptr, int(size))
             block
               type     (c_ptr)        :: article_stylesheet, doc
               character(13),   target :: param_strings (2)
               type     (c_ptr)        :: params (3)
               integer  (c_int)        :: res

               article_stylesheet = xslt_parse_stylesheet_file( &
                    'tools/stylesheets/article.xsl\0')

               param_strings(1) = 'date\0'
               param_strings(2) = '"' // posts(i) % date // '"\0'
               params(1) = c_loc(param_strings(1))
               params(2) = c_loc(param_strings(2))
               params(3) = c_null_ptr
               doc = xslt_apply_stylesheet(article_stylesheet, cptr, params)
               params(1) = c_null_ptr
               doc = xslt_apply_stylesheet(main_stylesheet, doc, params)
               res = xslt_save_result_to_filename( &
                    trim(posts(i) % target) // c_null_char, &
                    doc, main_stylesheet, 0)
             end block
          else
             call py_err_print()
          end if
       end if
    end do
  end subroutine generate_posts

  function get_post_list(limit) result(doc)
    integer,        intent(in) :: limit
    type    (c_ptr)            :: doc

    integer        :: i, count
    type   (c_ptr) :: node, root

    doc = xml_new_doc('1.0\0')
    root = xml_new_node(c_null_ptr, 'posts\0')
    node = xml_set_root_element(doc, root)

    if (limit == 0 .or. limit > post_count) then
       count = post_count
    else
       count = limit
    end if

    do i = 1, count
       block
         type     (c_ptr)            :: cptr, post
         character(name_max), target :: date, title, uri

         post = xml_new_child(root, c_null_ptr, 'post\0', c_null_ptr)

         title = trim(posts(i) % title) // '\0'
         cptr = xml_encode_entities_reentrant(doc, title)
         node = xml_new_child( &
              post, c_null_ptr, 'title\0', cptr)

         date = posts(i) % date // '\0'
         node = xml_new_child( &
              post, c_null_ptr, 'creation-date\0', c_loc(date))

         uri = '/' // trim(posts(i) % target) // '\0'
         node = xml_new_child(post, c_null_ptr, 'uri\0', c_loc(uri))
       end block
    end do
  end function get_post_list

  subroutine generate_post_archives
    type     (c_ptr)        :: archive_stylesheet, doc
    character(10),   target :: param_strings (2)
    type     (c_ptr)        :: params (3)
    integer  (c_int)        :: res

    archive_stylesheet = xslt_parse_stylesheet_file( &
         'tools/stylesheets/archive.xsl\0')

    params(1) = c_null_ptr
    doc = xslt_apply_stylesheet(archive_stylesheet, get_post_list(0), params)
    param_strings(1) = 'title\0'
    param_strings(2) = '"Archive"\0'
    params(1) = c_loc(param_strings(1))
    params(2) = c_loc(param_strings(2))
    params(3) = c_null_ptr
    doc = xslt_apply_stylesheet(main_stylesheet, doc, params)
    res = xslt_save_result_to_filename( &
         'blog/archive.html\0', doc, main_stylesheet, 0)
  end subroutine generate_post_archives

  subroutine generate_pages
    type     (c_ptr)             :: cptr
    integer                      :: i, page_count
    character(name_max), pointer :: pages (:)

    call c_find_files('_sources/pages/*/*.sam\0', name_max, cptr, page_count)

    call c_f_pointer(cptr, pages, [page_count])

    do i = 1, page_count
       block
         integer,            dimension(13) :: source_stat, target_stat
         character(name_max)               :: target

         target = pages(i) ( &
              len('_sources/pages/') + 1 &
              : index(pages(i), '.sam', back=.true.) - 1 &
              ) // '.html'
         call stat(pages(i), source_stat)
         call stat(target, target_stat)
         if (source_stat(10) > target_stat(10)) then
            call execute_command_line ( &
                 'python3 tools/sam/samparser.py ' // trim(pages(i)) // &
                 ' | xsltproc tools/stylesheets/article.xsl -' // &
                 ' | xsltproc --output ' // trim(target) // &
                 ' tools/stylesheets/main.xsl -' &
                 )
         end if
       end block
    end do

    call posix_free(cptr)
  end subroutine generate_pages

  subroutine generate_home_page
    type     (c_ptr)        :: home_stylesheet, doc
    character(10),   target :: param_strings (2)
    type     (c_ptr)        :: params (3)
    integer  (c_int)        :: res

    home_stylesheet = xslt_parse_stylesheet_file( &
         'tools/stylesheets/home.xsl\0')

    params(1) = c_null_ptr
    doc = xslt_apply_stylesheet(home_stylesheet, get_post_list(10), params)
    param_strings(1) = 'title\0'
    param_strings(2) = '"dram.me"\0'
    params(1) = c_loc(param_strings(1))
    params(2) = c_loc(param_strings(2))
    params(3) = c_null_ptr
    doc = xslt_apply_stylesheet(main_stylesheet, doc, params)
    res = xslt_save_result_to_filename('index.html\0', doc, main_stylesheet, 0)
  end subroutine generate_home_page
end program main
