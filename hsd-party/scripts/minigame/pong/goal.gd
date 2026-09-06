extends Node2D
class_name MinigamePong_Goal

@export var goal_effect_sprite: Sprite2D

var color: Color
var pong_game: MinigamePong
var pong_plyer_nr: int

func setup(_pong_plyer_nr: int ,_color: Color, _pong_game: MinigamePong) -> void:
	self.pong_plyer_nr = _pong_plyer_nr
	self.color = _color
	self.pong_game = _pong_game

func _ready() -> void:
	goal_effect_sprite.modulate = color

func score(_ball: MinigamePong_Ball, _col: KinematicCollision2D) -> void:
	pong_game.score(pong_plyer_nr, _ball)