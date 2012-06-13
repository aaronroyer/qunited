var QUNITED = {};

QUNITED.util = {
	// Join arbitrary number of path segments
	join: function() {
		var args = Array.prototype.slice.call(arguments, 0);
		switch(args.length) {
			case 0: return "";
			case 1: return args[0];
			case 2: return java.io.File(args[0], args[1]).toString();
			default:
				args.unshift(this.join(args.shift(), args.shift())); // Work on the first two and recurse
				return this.join.apply(null, args);
		}
	}
};
