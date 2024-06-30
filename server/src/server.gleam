import gleam/bit_array
import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/erlang/atom
import gleam/erlang/process.{type Selector, type Subject}
import gleam/float
import gleam/io
import gleam/json.{float, object, string}
import gleam/otp/actor
import udp.{
  type IPAddress, type Port, type Socket, udp_close, udp_open, udp_send,
}

fn ip_address(value: Dynamic) -> Result(IPAddress, List(DecodeError)) {
  value
  |> dynamic.tuple4(dynamic.int, dynamic.int, dynamic.int, dynamic.int)
}

fn udp_selector() -> Selector(Message) {
  process.new_selector()
  |> process.selecting_record5(
    atom.create_from_string("udp"),
    fn(_, ip, port, payload) {
      let ip = ip_address(ip)
      let port = dynamic.int(port)
      let payload = dynamic.bit_array(payload)

      case ip, port, payload {
        Ok(ip), Ok(port), Ok(payload) -> {
          Udp(ip, port, payload)
        }
        _, _, _ -> Unhandled
      }
    },
  )
}

fn json_decoder(payload: BitArray) -> Result(Entity, json.DecodeError) {
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

  json.decode(from: payload, using: decoder)
}

type Entity {
  Entity(guid: String, pos: Coords)
}

type Coords {
  Coords(x: Float, y: Float)
}

pub fn main() {
  let _sub = process.new_subject()

  let selector = udp_selector()

  let assert Ok(act) = new(5050)

  let _packet =
    process.select_forever(selector)

  process.sleep_forever()
  actor.send(act, Shutdown)
}

fn game_logic(entity: Entity) -> json.Json {
  let Entity(guid, Coords(x, y)) = entity
  let x = case float.absolute_value(x) >. 100.0 {
    True -> 0.0
    False -> x
  }

  let y = case float.absolute_value(x) >. 480.0 {
    True -> 0.0
    False -> x
  }
  object([
    #("guid", string(guid)),
    #("position", object([#("x", float(x)), #("y", float(y))])),
  ])
}

// Actor

type Message {
  Udp(address: IPAddress, port: Port, data: BitArray)
  Unhandled
  Shutdown
}

fn new(port: Port) -> Result(Subject(Message), actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let assert Ok(socket) = udp_open(port)
      actor.Ready(socket, udp_selector())
    },
    init_timeout: 1000,
    loop: handle_message,
  ))
}

fn handle_message(
  message: Message,
  socket: Socket,
) -> actor.Next(Message, Socket) {
  case message {
    Udp(ip, port, payload) -> {
      case json_decoder(payload) {
        Ok(Entity(guid, Coords(x, y))) -> {
          let reply = game_logic(Entity(guid, Coords(x, y)))

          let _ =
            udp_send(
              socket,
              ip,
              port,
              bit_array.from_string(json.to_string(reply)),
            )
          actor.continue(socket)
        }
        _ -> {
          io.debug("Indecipherable JSON packet:")
          io.debug(message)
          actor.continue(socket)
        }
      }
    }
    Unhandled -> {
      io.debug("Unhandled Message Received")
      actor.continue(socket)
    }
    Shutdown -> {
      let _ = udp_close(socket)
      actor.Stop(process.Normal)
    }
  }
}
