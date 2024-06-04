import gleam/bit_array
import gleam/bytes_builder.{type BytesBuilder}
import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/erlang/process.{type Subject}
import gleam/io

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
  data: BytesBuilder,
) -> Result(Nil, Error)

@external(erlang, "udp_ffi", "udp_recv")
pub fn udp_recv(socket: Socket, max_packet_size: Int) -> Result(RecvData, Error)

@external(erlang, "udp_ffi", "udp_close")
pub fn udp_close(socket: Socket) -> Result(Nil, Error)

fn ip_address(value: Dynamic) -> Result(IPAddress, List(DecodeError)) {
  value
  |> dynamic.tuple4(dynamic.int, dynamic.int, dynamic.int, dynamic.int)
}

pub fn main() {
  let assert Ok(socket) = udp_open(5050)

  let selector =
    process.new_selector()
    |> process.selecting_anything(fn(anything) {
      io.debug(anything)
      io.debug("Decode:")
      anything
      |> dynamic.tuple5(
        dynamic.dynamic,
        //UDP
        dynamic.dynamic,
        //Socket
        ip_address,
        dynamic.int,
        dynamic.list(dynamic.int),
      )
      |> io.debug
    })

  // Packet looks like:
  // Udp(//erl(#Port<0.4>), #(127, 0, 0, 1), 6969, [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100])
  // Udp(socket, from_ip, from_port, data)

  // let address: IPAddress = #(127, 0, 0, 1)

  // let assert Ok(sender) = udp_open(5051)
  // let _ =
  //   udp_send(sender, address, 5050, bytes_builder.from_string("Hello, World"))
  // let data = udp_recv(socket, 1024)
  // io.debug("Recvd:")
  // io.debug(data)
  // io.debug("end recvd")
  process.select_forever(selector)
  |> io.debug

  let _ = udp_close(socket)
  io.debug(socket)
}
