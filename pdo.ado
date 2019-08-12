program define pdo , rclass
	syntax , file(string) [debug]
	
	if "`debug'" == "debug"{
		do "`file'"
	}
	else{
		project , do("`file'")
	}
end
