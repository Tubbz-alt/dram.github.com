module sam
  use iso_c_binding
  use python

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
         globals, '__builtins__' // char(0), py_eval_get_builtins())

    p = py_run_string( &
         'import sys; &
         & sys.path.append("tools/sam"); &
         & import samparser' // char(0), &
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
         'p = samparser.SamParser();' // &
         'p.parse_file("' // trim(path) // '")' // char(0), &
         py_file_input, globals, c_null_ptr)

    p = py_run_string('"".join(p.doc.serialize_xml())' // char(0), &
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