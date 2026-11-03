extends RefCounted
## Boards written as text, one string per row, bottom row first:
##   0 / 1   a bit          _   an empty cell
##   [1]     a locked bit   1*  a bit carrying a spare switch
## Each row parses to N entries: null or {b, locked?, spare?}.


static func parse_line(s: String) -> Array:
	var cells := []
	var i := 0
	while i < s.length():
		var ch := s[i]
		if ch == "_":
			cells.append(null)
		elif ch == "[":
			cells.append({b = int(s[i + 1]), locked = true})
			i += 2
		elif ch == "0" or ch == "1":
			var c := {b = int(ch)}
			if i + 1 < s.length() and s[i + 1] == "*":
				c.spare = true
				i += 1
			cells.append(c)
		i += 1
	return cells
