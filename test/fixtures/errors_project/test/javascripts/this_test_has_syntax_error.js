module("Math");

test("Addition is hard", function() {
	var obj = {key = "value"}; // Doing it wrong
});

test("This expects the wrong number of assertions", function() {
	expect(2);
	equal(2 - 1, 1, "Two minus one equals one");
});
