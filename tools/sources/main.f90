program main
  use glib, only: &
       g_dir_close, &
       g_dir_read_name
  use glib_aux, only: &
       glib_aux_open_directory
  use iso_c_binding, only: &
       c_associated, &
       c_f_pointer, &
       c_loc, &
       c_null_ptr, &
       c_ptr, &
       c_size_t
  use posix, only: &
       posix_strlen
  use sam, only: &
       sam_parse
  use render, only: &
       render_archive, &
       render_article, &
       render_home
  use xml, only: &
       xml_encode_entities_reentrant, &
       xml_new_child, &
       xml_new_doc, &
       xml_new_node, &
       xml_parse_memory, &
       xml_set_root_element

  implicit none

  type post_t
     character(:), allocatable :: date, source, target, name
     character(132) title
  end type post_t

  type(post_t), allocatable :: posts (:)

  block
    integer unit
    integer, parameter :: n = len('_sources/posts/') + 1
    type(c_ptr) dir, filename
    type(post_t) post

    allocate(posts(0))

    dir = glib_aux_open_directory('_sources/posts')

    do
       filename = g_dir_read_name(dir)

       if (.not. c_associated(filename)) exit

       block
         character(posix_strlen(filename)), pointer :: name
         call c_f_pointer(filename, name)
         post % source = '_sources/posts/' // name
       end block

       post % date = post % source (n : n + 9)

       post % name = post % source ( &
            n + 11 : index(post % source, '.sam', back=.true.) - 1 &
            )

       post % target = 'blog' &
            // '/' // post % date (1 : 4)  & ! year
            // '/' // post % date (6 : 7)  & ! month
            // '/' // post % date (9 : 10) & ! day
            // '/' // trim(post % name) // '.html'

       open(newunit=unit, file=post % source, action='read')
       read(unit, '(9x, a)') post % title
       close(unit)

       posts = [posts, post]
    end do

    call g_dir_close(dir)

    call generate_posts
    call generate_pages

    call sort_posts

    call render_home(post_list(limit=10), 'index.html')
    call render_archive(post_list(limit=0), 'blog/archive.html')
  end block

contains

  subroutine generate_posts
    integer(c_size_t) length
    integer i
    type(c_ptr) cptr

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

    character(:), allocatable, target :: version, tag
    integer i, count
    type(c_ptr) node, root

    version = '1.0' // char(0)
    post_list = xml_new_doc(c_loc(version))
    tag = 'posts' // char(0)
    root = xml_new_node(c_null_ptr, c_loc(tag))
    node = xml_set_root_element(post_list, root)

    if (limit == 0 .or. limit > size(posts)) then
       count = size(posts)
    else
       count = limit
    end if

    do i = 1, count
       block
         character(:), allocatable, target :: date, title, uri
         type(c_ptr) cptr, post

         tag = 'post' // char(0)
         post = xml_new_child(root, c_null_ptr, c_loc(tag), c_null_ptr)

         title = trim(posts(i) % title) // char(0)
         cptr = xml_encode_entities_reentrant(post_list, c_loc(title))
         tag = 'title' // char(0)
         node = xml_new_child(post, c_null_ptr, c_loc(tag), cptr)

         date = posts(i) % date // char(0)
         tag = 'creation-date' // char(0)
         node = xml_new_child(post, c_null_ptr, c_loc(tag), c_loc(date))

         tag = 'uri' // char(0)
         uri = '/' // trim(posts(i) % target) // char(0)
         node = xml_new_child(post, c_null_ptr, c_loc(tag), c_loc(uri))
       end block
    end do
  end function post_list

  subroutine generate_pages
    character(*), parameter :: directories(*) = ['blog/', 'logo/']
    integer i
    type(c_ptr) dir, filename

    do i = 1, size(directories)
       dir = glib_aux_open_directory('_sources/pages/' // directories(i))

       do
          filename = g_dir_read_name(dir)

          if (.not. c_associated(filename)) exit

          block
            character(:), allocatable :: source, target
            character(posix_strlen(filename)), pointer :: name
            integer(c_size_t) length
            type(c_ptr) cptr

            call c_f_pointer(filename, name)

            source = '_sources/pages/' // directories(i) // name
            target = directories(i) // name (:len(name) - 4) // '.html'

            if (source_modified(source, target)) then
               call sam_parse(source, cptr, length)

               if (c_associated(cptr)) then
                  cptr = xml_parse_memory(cptr, int(length))
                  call render_article(cptr, target)
               end if
            end if
          end block
       end do

       call g_dir_close(dir)
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
    type(post_t) t

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
