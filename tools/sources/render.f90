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
    character(:), allocatable, target :: name

    call exslt_date_register()

    name = 'tools/stylesheets/main.xsl' // char(0)
    main_stylesheet = xslt_parse_stylesheet_file(c_loc(name))

    name = 'tools/stylesheets/article.xsl' // char(0)
    article_stylesheet = xslt_parse_stylesheet_file(c_loc(name))

    name = 'tools/stylesheets/home.xsl' // char(0)
    home_stylesheet = xslt_parse_stylesheet_file(c_loc(name))

    name = 'tools/stylesheets/archive.xsl' // char(0)
    archive_stylesheet = xslt_parse_stylesheet_file(c_loc(name))

    initialized = .true.
  end subroutine render_initialize

  subroutine render_article(content, output, date)
    type(c_ptr), intent(in) :: content
    character(*), intent(in) :: output
    character(*), optional, intent(in) :: date

    character(13), target :: param_strings (2)
    character(:), allocatable, target :: path
    integer i
    type(c_ptr) p
    type(c_ptr), target :: params (3)

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

    p = xslt_apply_stylesheet(article_stylesheet, content, c_loc(params))

    path = trim(output) // char(0)
    i = xslt_run_stylesheet_user( &
         main_stylesheet, p, c_null_ptr, c_loc(path), &
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
    type(c_ptr), intent(in) :: content
    character(*), intent(in) :: output
    character(*), optional, intent(in) :: title

    character(10), target :: param_strings (2)
    character(:), allocatable, target :: path
    integer i
    type(c_ptr), target :: params (3)

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

    path = trim(output) // char(0)
    i = xslt_run_stylesheet_user( &
         main_stylesheet, content, c_loc(params), c_loc(path), &
         c_null_ptr, c_null_ptr, c_null_ptr, c_null_ptr)
  end subroutine render_main
end module render
