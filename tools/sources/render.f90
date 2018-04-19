module render
  use exslt
  use iso_c_binding
  use strings
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
    character(*) date, output
    type(c_ptr) content
    intent(in) content, date, output
    optional date

    character(:) path
    integer i
    type(c_ptr) p, params (:)
    type(string) param_strings (:)
    allocatable path, param_strings, params
    target path, param_strings, params

    if (.not. initialized) call render_initialize

    if (present(date)) then
       param_strings = [ &
            string('date' // char(0)), &
            string('"' // date // '"' // char(0)) &
            ]
       params = [ &
            c_loc(param_strings(1) % value), &
            c_loc(param_strings(2) % value), &
            c_null_ptr &
            ]
    else
       params = [c_null_ptr]
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
    character(*) output, title
    type(c_ptr) content
    intent(in) content, output, title
    optional title

    character(:) path
    integer i
    type(c_ptr) params (:)
    type(string) param_strings (:)
    allocatable path, param_strings, params
    target path, param_strings, params

    if (.not. initialized) call render_initialize

    if (present(title)) then
       param_strings = [ &
            string('title' // char(0)), &
            string('"' // title // '"' // char(0)) &
            ]
       params = [ &
            c_loc(param_strings(1) % value), &
            c_loc(param_strings(2) % value), &
            c_null_ptr &
            ]
    else
       params = [c_null_ptr]
    end if

    path = trim(output) // char(0)
    i = xslt_run_stylesheet_user( &
         main_stylesheet, content, c_loc(params), c_loc(path), &
         c_null_ptr, c_null_ptr, c_null_ptr, c_null_ptr)
  end subroutine render_main
end module render
