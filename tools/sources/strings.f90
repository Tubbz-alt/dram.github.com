module strings
  implicit none

  private

  public cstring, string

  type string
     character(:), allocatable :: value
  end type string

contains

  function cstring(s)
    character(*), intent(in) :: s
    type(string) :: cstring
    cstring = string(s // char(0))
  end function cstring

end module strings
