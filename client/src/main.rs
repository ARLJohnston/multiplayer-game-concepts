use serde_json::json;
use serde_json::Value;
use std::net::UdpSocket;

use bevy::prelude::*;

#[derive(Resource)]
pub struct GameState {
    socket: UdpSocket,
    x: f32,
    y: f32,
}

impl Default for GameState {
    fn default() -> Self {
        let socket = UdpSocket::bind("127.0.0.1:6969").expect("Couldn't connect to {target}");
        socket.set_nonblocking(true).unwrap();
        GameState {
            socket,
            x: 0.,
            y: 0.,
        }
    }
}

fn character_movement(
    mut characters: Query<(&mut Transform, &Sprite)>,
    mut gameState: Res<GameState>,
    input: Res<ButtonInput<KeyCode>>,
    time: Res<Time>,
) {
    for (mut transform, _) in &mut characters {
        let json = json!({
                    "guid" : "15234y",
                    "position" : {
              "x": transform.translation.x, //Start with this as we only want to update from server when we get it
              "y": transform.translation.y
            },
        });
        let socket = &gameState.socket;
        let target = "127.0.0.1:5050";

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
        .init_resource::<GameState>()
        .add_systems(Startup, setup_camera)
        .add_systems(Startup, setup_framelimit)
        .add_systems(Update, character_movement)
        .run();
}
