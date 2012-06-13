module("Math");

test("Addition works", function() {
	expect(2);
	equal(1 + 1, 2, "One plus one does equal two");
	equal(2 + 2, 4, "Two plus two does equal four");
});

test("Subtraction works", function() {
	expect(1);
	equal(2 - 1, 1, "Two minus one equals one");
});
