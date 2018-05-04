module sam
  use cstrings, only: &
       cstring
  use iso_c_binding, only: c_associated, c_loc, c_null_ptr, c_ptr, c_size_t
  use python, only: &
       py_dict_new, py_dict_set_item_string, py_err_print, &
       py_eval_get_builtins, py_eval_input, py_file_input, &
       py_finalize, py_initialize, py_run_string, &
       py_unicode_as_utf8_and_size

  implicit none

  private

  public sam_initialize, sam_parse, sam_finalize

  logical initialized
  type(c_ptr) globals

contains

  subroutine sam_initialize
    integer i
    type(c_ptr) p

    call py_initialize()

    globals = py_dict_new()

    i = py_dict_set_item_string( &
         globals, cstring('__builtins__'), py_eval_get_builtins())

    p = py_run_string( &
         cstring( &
         'import sys; &
         & sys.path.append("tools/sam"); &
         & import samparser'), &
         py_file_input, globals, c_null_ptr)

    initialized = .true.
  end subroutine sam_initialize

  subroutine sam_parse(path, memory, size)
    character(*), intent(in) :: path
    type(c_ptr), intent(out) :: memory
    integer(c_size_t), intent(out) :: size

    type(c_ptr) p

    if (.not. initialized) call sam_initialize

    p = py_run_string( &
         cstring( &
         'p = samparser.SamParser(); p.parse_file("' // trim(path) // '")'), &
         py_file_input, globals, c_null_ptr)

    p = py_run_string( &
         cstring('"".join(p.doc.serialize_xml())'), &
         py_eval_input, globals, c_null_ptr)

    if (c_associated(p)) then
       memory = py_unicode_as_utf8_and_size(p, size)
    else
       call py_err_print()
    end if
  end subroutine sam_parse

  subroutine sam_finalize
    if (initialized) call py_finalize()
  end subroutine sam_finalize
end module sam
