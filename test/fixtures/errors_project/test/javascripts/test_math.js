module("Math");

test("Addition is hard", function() {
	expect(2);
	equal(1 + 1, 3, "This math is wrong");
	equal(2 + 2, 5, "This math is also wrong");
});

test("This expects the wrong number of assertions", function() {
	expect(2);
	equal(2 - 1, 1, "Two minus one equals one");
});
