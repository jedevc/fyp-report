chunk x : int = 0
block main {
  while x < 10 {
    printf@libc.stdio("Hello world! %d\n", x)
    ...
    x = x + 1
  }
}

