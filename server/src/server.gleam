import gleam/bit_array
import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/json.{float, object, string}

// import juno.{type Value}

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

type Entity {
  Entity(guid: String, pos: Coords)
}

type Coords {
  Coords(x: Float, y: Float)
}

pub fn main() {
  let assert Ok(socket) = udp_open(5050)

  let selector =
    process.new_selector()
    |> process.selecting_anything(fn(packet) {
      let assert Ok(#(_, _, ip, port, payload)) =
        packet
        |> udp_packet

      let position_decoder =
        dynamic.decode2(
          Coords,
          dynamic.field("x", of: dynamic.float),
          dynamic.field("y", of: dynamic.float),
        )

      let decoder =
        dynamic.decode2(
          Entity,
          dynamic.field("guid", of: dynamic.string),
          dynamic.field("position", of: position_decoder),
        )

      let assert Ok(payload) = bit_array.to_string(payload)

      // let assert Ok(payload) =
      //   payload
      //   |> json.decode(using:decoder)

      let assert Ok(Entity(guid, position)) =
        json.decode(from: payload, using: decoder)

      let reply =
        object([
          #("guid", string(guid)),
          #(
            "position",
            object([
              #("x", float(position.x +. 10.0)),
              #("y", float(position.y +. 10.0)),
            ]),
          ),
        ])

      udp_send(socket, ip, port, bit_array.from_string(json.to_string(reply)))
    })

  process.select_forever(selector)

  let _ = udp_close(socket)
}
