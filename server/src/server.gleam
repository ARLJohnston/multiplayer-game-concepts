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

@external(erlang, "udp_ffi", "udp_recv")
pub fn udp_recv(socket: Socket, max_packet_size: Int) -> Result(RecvData, Error)

@external(erlang, "udp_ffi", "udp_close")
pub fn udp_close(socket: Socket) -> Result(Nil, Error)

pub fn main() {
  let assert Ok(socket) = udp_open(5050)
  io.debug(socket)

  let address: IPAddress = #(127, 0, 0, 1)

  let assert Ok(sender) = udp_open(5051)
  let _ =
    udp_send(sender, address, 5050, bytes_builder.from_string("Hello, World"))
  let data = udp_recv(socket, 1024)
  io.debug("Recvd:")
  io.debug(data)
  io.debug("end recvd")

  let _ = udp_close(socket)
  io.debug(socket)
}
