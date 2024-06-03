import gleam/bytes_builder.{type BytesBuilder}
import gleam/io

//Phantom types!
pub type Socket

pub type Error

pub type IPAddress =
  #(Int, Int, Int, Int)

@external(erlang, "udp_ffi", "udp_open")
pub fn udp_open(port: Int) -> Result(Socket, Error)

@external(erlang, "udp_ffi", "udp_send")
pub fn udp_send(
  socket: Socket,
  target_ip: IPAddress,
  target_port: Int,
  data: BytesBuilder,
) -> Result(Nil, Error)

@external(erlang, "udp_ffi", "udp_close")
pub fn udp_close(socket: Socket) -> Result(Nil, Error)

pub fn main() {
  let assert Ok(socket) = udp_open(5051)
  io.debug(socket)

  let address: IPAddress = #(127, 0, 0, 1)

  let _ =
    udp_send(socket, address, 5050, bytes_builder.from_string("Hello, World"))
  let _ = udp_close(socket)
  io.debug(socket)
}
