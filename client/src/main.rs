use serde_json::json;
use serde_json::Value;
use std::net::UdpSocket;
use std::time::Duration;

use bevy::prelude::*;

#[derive(Resource)]
pub struct GameState {
    socket: UdpSocket,
    timer: Timer,
    x: f32,
    y: f32,
}

impl Default for GameState {
    fn default() -> Self {
        let socket = UdpSocket::bind("127.0.0.1:6969").expect("Couldn't connect to {target}");
        socket.set_nonblocking(true).unwrap();

        GameState {
            socket,
            timer: Timer::new(Duration::from_secs(1), TimerMode::Repeating),
            x: 0.,
            y: 0.,
        }
    }
}

fn character_movement(
    mut characters: Query<(&mut Transform, &Sprite)>,
    mut game_state: ResMut<GameState>,
    input: Res<ButtonInput<KeyCode>>,
    time: Res<Time>,
) {
    for (mut transform, _) in &mut characters {
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

        let socket = &game_state.socket;
        let mut buf = vec![0; 1024];
        match socket.recv_from(&mut buf) {
            Ok((len, _src)) => {
                let recv_json: Value =
                    serde_json::from_slice(&buf[..len]).expect("Unable to decode json");

                println!("{}", serde_json::to_string_pretty(&recv_json).unwrap());

                match recv_json["position"]["x"].as_f64() {
                    Some(val) => transform.translation.x = val as f32,
                    _ => (),
                }

                match recv_json["position"]["y"].as_f64() {
                    Some(val) => transform.translation.y = val as f32,
                    _ => (),
                }
            }
            _ => (),
        }

        game_state.x = transform.translation.x;
        game_state.y = transform.translation.y;
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

fn server_report(time: Res<Time>, mut game_state: ResMut<GameState>) {
    game_state.timer.tick(time.delta());
    if game_state.timer.finished() {
        let socket = &game_state.socket;
        let target = "127.0.0.1:5050";

        let json = json!({
              "guid" : "15234y",
              "position" : {
                  "x": game_state.x,
                  "y":game_state.y,
              },
        });

        let serialized_data = serde_json::to_vec(&json).expect("Failed to serialize JSON");

        socket
            .send_to(&serialized_data, target)
            .expect("Unable to send data to {target}");
    }
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
        .add_systems(Update, server_report)
        .run();
}
