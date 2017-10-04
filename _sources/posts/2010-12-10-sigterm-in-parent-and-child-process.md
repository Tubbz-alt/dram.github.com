Title: 父子进程中的SIGTERM

在 daemon 程序设计中，如果进行多进程处理，往往就需要考虑这样一个问题：如何在父进程中 kill 所有子进程。因为 daemon 的 pid 文件只保存了父进程的 PID ，所以外界只能通过信号与父进程通信，子进程的退出工作需要由父进程间接下达。

在 `int kill(pid_t pid, int sig)` 中如果 pid 参数为 0 ，那么会向该进程所在进程组里的所有进程发送信号，可以通过它来实现父进程与子进程的通信。

但有一点需要注意，父进程在调用 `kill(0, SIGTERM)` 时，不单给子进程发送 `SIGTERM` 信号，同时还会给自己发送。所以在调用 `kill()` 之后，需要调用 `exit()` 直接退出。子进程在接收到 `SIGTERM` 之后也会相继退出。 