program main
  use iso_c_binding
  use posix
  use sam, only: sam_parse
  use render, only: render_archive, render_article, render_home
  use xml

  implicit none

  integer, parameter :: name_max = 132

  type post
     character(10)       :: date
     character(name_max) :: source, target, name, title
  end type post

  integer                     :: post_count
  type    (post), allocatable :: posts (:)

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
    integer                        :: i, j, unit
    integer,             parameter :: n = len('_sources/posts/') + 1
    character(name_max), pointer   :: sources (:)

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

       open(newunit=unit, file=sources(j))
       read(unit, '(9x, a)') posts(i) % title
       close(unit)
    end do

    call generate_posts
    call generate_pages
    call render_home(post_list(limit=10), 'index.html')
    call render_archive(post_list(limit=0), 'blog/archive.html')

    call posix_free(cptr)
  end block

contains

  subroutine generate_posts
    type(c_ptr) cptr
    integer i
    integer(c_size_t) size

    do i = 1, post_count
       if (source_modified(posts(i) % source, posts(i) % target)) then
          call sam_parse(posts(i) % source, cptr, size)
          if (c_associated(cptr)) then
             cptr = xml_parse_memory(cptr, int(size))
             call render_article(cptr, posts(i) % target, date=posts(i) % date)
          end if
       end if
    end do
  end subroutine generate_posts

  function post_list(limit)
    integer, intent(in) :: limit
    type(c_ptr) post_list

    integer i, count
    type(c_ptr) node, root

    post_list = xml_new_doc('1.0\0')
    root = xml_new_node(c_null_ptr, 'posts\0')
    node = xml_set_root_element(post_list, root)

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

         title = trim(posts(i) % title) // char(0)
         cptr = xml_encode_entities_reentrant(post_list, title)
         node = xml_new_child( &
              post, c_null_ptr, 'title\0', cptr)

         date = posts(i) % date // char(0)
         node = xml_new_child( &
              post, c_null_ptr, 'creation-date\0', c_loc(date))

         uri = '/' // trim(posts(i) % target) // char(0)
         node = xml_new_child(post, c_null_ptr, 'uri\0', c_loc(uri))
       end block
    end do
  end function post_list

  subroutine generate_pages
    type     (c_ptr)             :: cptr
    integer                      :: i, page_count
    character(name_max), pointer :: pages (:)

    call c_find_files('_sources/pages/*/*.sam\0', name_max, cptr, page_count)

    call c_f_pointer(cptr, pages, [page_count])

    do i = 1, page_count
       block
         integer  (c_size_t) :: size
         character(name_max) :: target

         target = pages(i) ( &
              len('_sources/pages/') + 1 &
              : index(pages(i), '.sam', back=.true.) - 1 &
              ) // '.html'

         if (source_modified(pages(i), target)) then
            call sam_parse(pages(i), cptr, size)

            if (c_associated(cptr)) then
               cptr = xml_parse_memory(cptr, int(size))
               call render_article(cptr, target)
            end if
         end if
       end block
    end do

    call posix_free(cptr)
  end subroutine generate_pages

  function source_modified(source, target)
    character(*), intent(in) :: source, target

    logical source_modified

    integer status, source_stat(13), target_stat(13)

    call stat(source, source_stat)
    call stat(target, target_stat, status)
    source_modified = status /= 0 .or. source_stat(10) > target_stat(10)
  end function source_modified

end program main
