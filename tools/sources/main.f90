program main
  use apr
  use iso_c_binding
  use posix
  use sam, only: sam_parse
  use render, only: render_archive, render_article, render_home
  use xml

  implicit none

  integer, parameter :: name_max = 132

  type post
     character(10) date
     character(name_max) source, target, name, title
  end type post

  type(c_ptr) apr_pool
  type(post), allocatable :: posts (:)

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
    type(c_ptr) cptr
    type(apr_array_header_t), pointer :: fptr
    integer i, unit
    integer, parameter :: n = len('_sources/posts/') + 1

    i = apr_pool_initialize()

    i = apr_pool_create_ex(apr_pool, c_null_ptr, c_null_ptr, c_null_ptr)

    block
      character(:), allocatable, target :: pattern
      pattern = '_sources/posts/*.sam' // char(0)
      i = apr_match_glob(c_loc(pattern), cptr, apr_pool)
    end block

    call c_f_pointer(cptr, fptr)

    block
      type(c_ptr), pointer :: entries (:)

      call c_f_pointer(fptr % elts, entries, [fptr % nelts])

      allocate(posts (size(entries)))

      do i = 1, size(posts)
         block
           character(posix_strlen(entries(i))), pointer :: filename

           call c_f_pointer(entries(i), filename)
           posts(i) % source = '_sources/posts/' // filename
         end block

         posts(i) % date = posts(i) % source (n : n + 9)

         posts(i) % name = posts(i) % source ( &
              n + 11 : index(posts(i) % source, '.sam', back=.true.) - 1 &
              )

         posts(i) % target = 'blog' &
              // '/' // posts(i) % date (1 : 4)  & ! year
              // '/' // posts(i) % date (6 : 7)  & ! month
              // '/' // posts(i) % date (9 : 10) & ! day
              // '/' // trim(posts(i) % name) // '.html'

         open(newunit=unit, file=posts(i) % source, action='read')
         read(unit, '(9x, a)') posts(i) % title
         close(unit)
      end do
    end block

    call generate_posts
    call generate_pages

    call sort_posts

    call render_home(post_list(limit=10), 'index.html')
    call render_archive(post_list(limit=0), 'blog/archive.html')

    call apr_pool_clear(apr_pool)
    call apr_pool_terminate()
  end block

contains

  subroutine generate_posts
    type(c_ptr) cptr
    integer i
    integer(c_size_t) length

    do i = 1, size(posts)
       if (source_modified(posts(i) % source, posts(i) % target)) then
          call sam_parse(posts(i) % source, cptr, length)
          if (c_associated(cptr)) then
             cptr = xml_parse_memory(cptr, int(length))
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

    if (limit == 0 .or. limit > size(posts)) then
       count = size(posts)
    else
       count = limit
    end if

    do i = 1, count
       block
         type(c_ptr) cptr, post
         character(:), allocatable, target :: date, title, uri

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
    type(c_ptr) cptr
    type(apr_array_header_t), pointer :: fptr
    integer di, i
    character(*), parameter :: directories(*) = ['blog/', 'logo/']

    do di = 1, size(directories)
       block
         character(:), allocatable, target :: pattern
         pattern = '_sources/pages/' // directories(di) // '*.sam' // char(0)
         i = apr_match_glob(c_loc(pattern), cptr, apr_pool)
       end block

       call c_f_pointer(cptr, fptr)

       block
         type(c_ptr), pointer :: pages(:)

         call c_f_pointer(fptr % elts, pages, [fptr % nelts])

         do i = 1, size(pages)
            block
              character(posix_strlen(pages(i))), pointer :: name
              integer(c_size_t) length
              character(:), allocatable :: source, target

              call c_f_pointer(pages(i), name)

              source = '_sources/pages/' // directories(di) // name
              target = directories(di) // name (:len(name) - 4) // '.html'

              if (source_modified(source, target)) then
                 call sam_parse(source, cptr, length)

                 if (c_associated(cptr)) then
                    cptr = xml_parse_memory(cptr, int(length))
                    call render_article(cptr, target)
                 end if
              end if
            end block
         end do
       end block
    end do
  end subroutine generate_pages

  function source_modified(source, target)
    character(*), intent(in) :: source, target

    logical source_modified

    integer status, source_stat(13), target_stat(13)

    call stat(source, source_stat)
    call stat(target, target_stat, status)
    source_modified = status /= 0 .or. source_stat(10) > target_stat(10)
  end function source_modified

  subroutine sort_posts
    integer i, j
    type(post) t

    do i = 1, size(posts)
       do j = i + 1, size(posts)
          if (posts(j) % source > posts(i) % source) then
             t = posts(i)
             posts(i) = posts(j)
             posts(j) = t
          end if
       end do
    end do
  end subroutine sort_posts

end program main
