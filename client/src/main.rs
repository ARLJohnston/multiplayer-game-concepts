use json::object;
use std::net::UdpSocket;

use bevy::prelude::*;

fn setup_camera(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.spawn(Camera2dBundle {
			camera: Camera {
		    clear_color: ClearColorConfig::Custom(Color::hex("2f2f2f").unwrap()),
			  ..default()
		  },
			..default() //Fill remaining args with default values
	  });

    let texture = asset_server.load("lucy.png");

    commands.spawn(SpriteBundle {
				sprite: Sprite {
		        custom_size: Some(Vec2::new(100.0, 100.0)),
		        ..default()
				},
				texture,
		    ..default()
	  });
}

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

    App::new()
	    .add_plugins(DefaultPlugins)
			.add_systems(Startup, setup_camera)
			.run();
}
