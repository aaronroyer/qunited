module("Miscellaneous")
test("Test that we have a body and that one element", function() {
	equal(document.getElementsByTagName("body").length, 1, "We have a body");
	ok(document.getElementById('the-only-div'), "Found our element");
});
