import gleam/erlang/process.{type Pid}

//Phantom types!
pub type Socket

pub type Port =
  Int

pub type Error

pub type RecvData

pub type IPAddress =
  #(Int, Int, Int, Int)

@external(erlang, "udp_ffi", "udp_open")
pub fn udp_open(port: Port) -> Result(Socket, Error)

@external(erlang, "udp_ffi", "udp_send")
pub fn udp_send(
  socket: Socket,
  target_ip: IPAddress,
  target_port: Port,
  data: BitArray,
) -> Result(Nil, Error)

@external(erlang, "udp_ffi", "udp_recv")
pub fn udp_recv(socket: Socket, max_packet_size: Int) -> Result(RecvData, Error)

@external(erlang, "udp_ffi", "udp_close")
pub fn udp_close(socket: Socket) -> Result(Nil, Error)

@external(erlang, "udp_ffi", "test")
pub fn udp_test(pid: Pid) -> Nil
