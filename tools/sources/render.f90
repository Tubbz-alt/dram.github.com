module render
  use exslt
  use iso_c_binding
  use xml
  use xslt

  implicit none

  private

  public render_initialize, render_archive, render_article, render_home

  logical initialized
  type(c_ptr) &
       article_stylesheet, main_stylesheet, archive_stylesheet, home_stylesheet

contains

  subroutine render_initialize
    call exslt_date_register()

    main_stylesheet = &
         xslt_parse_stylesheet_file('tools/stylesheets/main.xsl\0')

    article_stylesheet = &
         xslt_parse_stylesheet_file('tools/stylesheets/article.xsl\0')

    home_stylesheet = &
         xslt_parse_stylesheet_file('tools/stylesheets/home.xsl\0')

    archive_stylesheet = &
         xslt_parse_stylesheet_file('tools/stylesheets/archive.xsl\0')

    initialized = .true.
  end subroutine render_initialize

  subroutine render_article(content, output, date)
    type(c_ptr), intent(in) :: content
    character(*), intent(in) :: output
    character(*), optional, intent(in) :: date

    character(13), target :: param_strings (2)
    type(c_ptr) p, params (3)
    integer i

    if (.not. initialized) call render_initialize

    if (present(date)) then
       param_strings(1) = 'date' // char(0)
       param_strings(2) = '"' // date // '"' // char(0)
       params(1) = c_loc(param_strings(1))
       params(2) = c_loc(param_strings(2))
       params(3) = c_null_ptr
    else
       params(1) = c_null_ptr
    end if

    p = xslt_apply_stylesheet(article_stylesheet, content, params)

    params(1) = c_null_ptr

    i = xslt_run_stylesheet_user( &
         main_stylesheet, p, params, trim(output) // char(0), &
         c_null_ptr, c_null_ptr, c_null_ptr, c_null_ptr)
  end subroutine render_article

  subroutine render_home(posts, output)
    type(c_ptr), intent(in) :: posts
    character(*), intent(in) :: output

    type(c_ptr) p
    type(c_ptr), parameter :: params (*) = [c_null_ptr]

    if (.not. initialized) call render_initialize

    p = xslt_apply_stylesheet(home_stylesheet, posts, params)
    call render_main(p, output, title="dram.me")
  end subroutine render_home

  subroutine render_archive(posts, output)
    type(c_ptr), intent(in) :: posts
    character(*), intent(in) :: output

    type(c_ptr) p
    type(c_ptr), parameter :: params (*) = [c_null_ptr]

    if (.not. initialized) call render_initialize

    p = xslt_apply_stylesheet(archive_stylesheet, posts, params)
    call render_main(p, output, title="Archive")
  end subroutine render_archive

  subroutine render_main(content, output, title)
    type(c_ptr), intent(in) :: content
    character(*), intent(in) :: output
    character(*), optional, intent(in) :: title

    integer i
    character(10), target :: param_strings (2)
    type(c_ptr) params (3)

    if (.not. initialized) call render_initialize

    if (present(title)) then
       param_strings(1) = 'title' // char(0)
       param_strings(2) = '"' // title // '"' // char(0)
       params(1) = c_loc(param_strings(1))
       params(2) = c_loc(param_strings(2))
       params(3) = c_null_ptr
    else
       params(1) = c_null_ptr
    end if

    i = xslt_run_stylesheet_user( &
         main_stylesheet, content, params, trim(output) // char(0), &
         c_null_ptr, c_null_ptr, c_null_ptr, c_null_ptr)
  end subroutine render_main
end module render
