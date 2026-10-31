class_name TestCase
extends RefCounted
## Base mínima para os testes headless. Cada método público que começa com "test_" é um caso.
## Sem framework externo: o executor está em test_runner.gd.

var failures: Array[String] = []


func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (esperado %s, obtido %s)" % [message, str(expected), str(actual)])
