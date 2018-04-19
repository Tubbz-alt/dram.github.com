module strings
  implicit none

  private

  public string

  type string
     character(:), allocatable :: value
  end type string

end module strings
