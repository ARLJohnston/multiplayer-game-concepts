use serde_json::json;
use serde_json::Value;
use std::net::UdpSocket;

use bevy::prelude::*;

fn character_movement(
    mut characters: Query<(&mut Transform, &Sprite)>,
    input: Res<ButtonInput<KeyCode>>,
    time: Res<Time>,
) {
    for (mut transform, _) in &mut characters {
        let target = "127.0.0.1:5050";
        let socket = UdpSocket::bind("127.0.0.1:6969").expect("Couldn't connect to {target}");

        let json = json!({
                    "guid" : "15234y",
                    "position" : {
              "x": transform.translation.x,
              "y": transform.translation.y
            },
        });

        socket
            .send_to(json.to_string().as_bytes(), target)
            .expect("Unable to send data to {target}");

        if input.pressed(KeyCode::KeyW) {
            transform.translation.y += 100.0 * time.delta_seconds()
        }
        if input.pressed(KeyCode::KeyS) {
            transform.translation.y -= 100.0 * time.delta_seconds()
        }
        if input.pressed(KeyCode::KeyA) {
            transform.translation.x -= 100.0 * time.delta_seconds()
        }
        if input.pressed(KeyCode::KeyD) {
            transform.translation.x += 100.0 * time.delta_seconds()
        }

        println!("Way Before transform: {}", transform.translation.y);
        let mut buf = vec![0; 1024];

        match socket.recv_from(&mut buf) {
            Ok((len, _src)) => {
                let recv_json: Value =
                    serde_json::from_slice(&buf[..len]).expect("Unable to decode json");

                match recv_json["position"]["y"].as_f64() {
                    Some(val) => transform.translation.y += val as f32,
                    _ => (),
                }
            }
            _ => (),
        }
    }
}

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

fn setup_framelimit(mut settings: ResMut<bevy_framepace::FramepaceSettings>) {
    use bevy_framepace::Limiter;
    settings.limiter = Limiter::from_framerate(30.0)
}

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(ImagePlugin::default_nearest()).build())
        .add_plugins(bevy_framepace::FramepacePlugin)
        .add_systems(Startup, setup_camera)
        .add_systems(Startup, setup_framelimit)
        .add_systems(Update, character_movement)
        .run();
}
