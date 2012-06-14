module("Basics");

test("This has one failure", function() {
	expect(1);
	ok(false); // No message
});

test("This has no failures", function() {
	expect(1);
	equal(APP.one(), 1, "It is 1");
});
