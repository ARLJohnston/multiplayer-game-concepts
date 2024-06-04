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

fn udp_packet(
  value: Dynamic,
) -> Result(#(Dynamic, Dynamic, IPAddress, Port, BitArray), List(DecodeError)) {
  value
  |> dynamic.tuple5(
    //UDP tag
    dynamic.dynamic,
    //Socket, we only open one socket
    dynamic.dynamic,
    ip_address,
    dynamic.int,
    dynamic.bit_array,
  )
}

pub fn main() {
  let assert Ok(socket) = udp_open(5050)

  let selector =
    process.new_selector()
    |> process.selecting_anything(fn(packet) {
      let assert Ok(#(_, _, ip, port, payload)) =
        packet
        |> udp_packet

      io.debug(payload)
    })

  process.select_forever(selector)
  |> io.debug

  let _ = udp_close(socket)
  io.debug(socket)
}
