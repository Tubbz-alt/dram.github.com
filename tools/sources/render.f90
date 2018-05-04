module render
  use cstrings, only: &
       cstring
  use exslt, only: &
       exslt_date_register
  use iso_c_binding, only: &
       c_loc, &
       c_null_ptr, &
       c_ptr
  use strings, only: &
       string
  use xslt, only: &
       xslt_apply_stylesheet, &
       xslt_parse_stylesheet_file, &
       xslt_run_stylesheet_user

  implicit none

  private

  public render_initialize, render_archive, render_article, render_home

  logical initialized
  type(c_ptr) &
       article_stylesheet, main_stylesheet, archive_stylesheet, home_stylesheet

contains

  subroutine render_initialize
    call exslt_date_register()

    main_stylesheet = xslt_parse_stylesheet_file( &
         cstring('tools/stylesheets/main.xsl'))

    article_stylesheet = xslt_parse_stylesheet_file( &
         cstring('tools/stylesheets/article.xsl'))

    home_stylesheet = xslt_parse_stylesheet_file( &
         cstring('tools/stylesheets/home.xsl'))

    archive_stylesheet = xslt_parse_stylesheet_file( &
         cstring('tools/stylesheets/archive.xsl'))

    initialized = .true.
  end subroutine render_initialize

  subroutine render_article(content, output, date)
    character(*) date, output
    type(c_ptr) content
    intent(in) content, date, output
    optional date

    integer i
    type(c_ptr) p
    type(c_ptr), allocatable, target :: params (:)

    if (.not. initialized) call render_initialize

    if (present(date)) then
       params = [ &
            cstring('date'), &
            cstring('"' // date // '"'), &
            c_null_ptr &
            ]
    else
       params = [c_null_ptr]
    end if

    p = xslt_apply_stylesheet(article_stylesheet, content, c_loc(params))

    i = xslt_run_stylesheet_user( &
         main_stylesheet, p, c_null_ptr, cstring(trim(output)), &
         c_null_ptr, c_null_ptr, c_null_ptr, c_null_ptr)
  end subroutine render_article

  subroutine render_home(posts, output)
    type(c_ptr), intent(in) :: posts
    character(*), intent(in) :: output

    type(c_ptr) p

    if (.not. initialized) call render_initialize

    p = xslt_apply_stylesheet(home_stylesheet, posts, c_null_ptr)
    call render_main(p, output, title="dram.me")
  end subroutine render_home

  subroutine render_archive(posts, output)
    type(c_ptr), intent(in) :: posts
    character(*), intent(in) :: output

    type(c_ptr) p

    if (.not. initialized) call render_initialize

    p = xslt_apply_stylesheet(archive_stylesheet, posts, c_null_ptr)
    call render_main(p, output, title="Archive")
  end subroutine render_archive

  subroutine render_main(content, output, title)
    character(*) output, title
    type(c_ptr) content
    intent(in) content, output, title
    optional title

    integer i
    type(c_ptr), allocatable, target :: params (:)

    if (.not. initialized) call render_initialize

    if (present(title)) then
       params = [ &
            cstring('title'), &
            cstring('"' // title // '"'), &
            c_null_ptr &
            ]
    else
       params = [c_null_ptr]
    end if

    i = xslt_run_stylesheet_user( &
         main_stylesheet, content, c_loc(params), cstring(trim(output)), &
         c_null_ptr, c_null_ptr, c_null_ptr, c_null_ptr)
  end subroutine render_main
end module render
