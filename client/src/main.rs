use json::object;
use std::net::UdpSocket;

fn main() {
    let json_instance = object!{
			"code": 200,
				success: true,
				payload: {
	    epic: true
		}
    };
    println!("Json: {json_instance}");

    let sself: &str = "localhost:5051";
    let target: &str = "localhost:5050";
	let socket = UdpSocket::bind(sself).expect("Couldn't connect to {target}");

    let string_json = json::stringify(json_instance);
    let serialised_json: &[u8] = string_json.as_bytes();

    socket.send_to(serialised_json, target).expect("Unable to send data to {target}");
}
