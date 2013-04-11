// Leave in default module

test("The source code was loaded", function() {
	expect(1);
	equal(APP.one(), 1, "We have loaded it");
});
