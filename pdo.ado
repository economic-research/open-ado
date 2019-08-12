program define pdo , rclass
	version 14
	syntax , file(string) [debug quietly]
	
	if "`debug'" == "debug"{
		`quietly' do "`file'"
	}
	else{
		project , do("`file'")
	}
end
