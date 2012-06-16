module("Basics");

test("This has one failure", function() {
	bogusFunction(); // undefined error
});

test("This has no failures", function() {
	expect(1);
	equal(APP.one(), 1, "It is 1");
});
