module strings
  use iso_c_binding, only: &
       c_loc, &
       c_null_char, &
       c_ptr

  implicit none

  private

  public &
       string, &
       string_pool, &
       string_pool_allocate, &
       string_pool_finalize, &
       string_pool_initialize, &
       string_to_c_string, &
       string_to_c_string_with_pool

  type string
     character(:), allocatable :: value
  end type string

  type string_pointer
     type(string), pointer :: value
  end type string_pointer

  type string_pool
     integer :: offset, capacity
     type(string_pointer), allocatable :: pointers (:)
  end type string_pool

contains

  function string_pool_allocate(pool)
    type(string_pool), intent(inout) :: pool
    type(string), pointer :: string_pool_allocate

    type(string_pointer), allocatable :: buffer (:)

    allocate (string_pool_allocate)

    pool % pointers (pool % offset) % value => string_pool_allocate
    pool % offset = pool % offset + 1

    if (pool % offset > pool % capacity) then
       allocate (buffer (pool % capacity * 2), source=pool % pointers)
       call move_alloc(buffer, pool % pointers)
       pool % capacity = pool % capacity * 2
    end if
  end function string_pool_allocate

  subroutine string_pool_finalize(pool)
    type(string_pool), intent(inout) :: pool

    integer i

    do i = 1, pool % offset - 1
       deallocate (pool % pointers (i) % value)
    end do
  end subroutine string_pool_finalize

  subroutine string_pool_initialize(pool, capacity)
    type(string_pool), intent(inout) :: pool
    integer, intent(in) :: capacity

    pool % offset = 1
    pool % capacity = capacity
    allocate (pool % pointers (capacity))
  end subroutine string_pool_initialize

  function string_to_c_string(fstring, buffer)
    character(*), intent(in) :: fstring
    type(string), intent(inout), target :: buffer
    type(c_ptr) string_to_c_string

    buffer % value = fstring // c_null_char
    string_to_c_string = c_loc(buffer % value)
  end function string_to_c_string

  function string_to_c_string_with_pool(fstring, pool)
    character(*), intent(in) :: fstring
    type(string_pool), intent(inout) :: pool
    type(c_ptr) string_to_c_string_with_pool

    type(string), pointer :: buffer

    buffer => string_pool_allocate(pool)

    buffer % value = fstring // c_null_char
    string_to_c_string_with_pool = c_loc(buffer % value)
  end function string_to_c_string_with_pool

end module strings
