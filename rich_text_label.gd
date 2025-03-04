extends RichTextLabel

func _ready() -> void:
	var textLabel: RichTextLabel = $"."
	var hitbox: CollisionShape2D = $Area2D/CollisionShape2D
	var midpointOfLabel :Vector2 = textLabel.get_size() * 0.5
	hitbox.set_position(midpointOfLabel)
	hitbox.shape.set_size(textLabel.get_size())
