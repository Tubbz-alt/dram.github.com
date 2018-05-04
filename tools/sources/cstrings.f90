module cstrings
  use iso_c_binding, only: &
       c_ptr
  use strings, only: &
       string_pool, &
       string_pool_finalize, &
       string_pool_initialize, &
       string_to_c_string_with_pool

  implicit none

  private

  public &
       cstring, &
       cstring_finalize, &
       cstring_initialize

  integer, parameter :: pool_initial_capacity = 16

  type(string_pool) cstring_pool

contains

  function cstring(string)
    character(*), intent(in) :: string
    type(c_ptr) cstring
    cstring = string_to_c_string_with_pool(string, cstring_pool)
  end function cstring

  subroutine cstring_finalize
    call string_pool_finalize(cstring_pool)
  end subroutine cstring_finalize

  subroutine cstring_initialize
    call string_pool_initialize(cstring_pool, pool_initial_capacity)
  end subroutine cstring_initialize

end module cstrings
