# Chi

A nicer syntax for working with C libraries.


## Features

- Chaining syntax.
- Assertions.
- Shorthands for declaring and initialising variables.
- Return several values.
- Default return values.
- Default parametres.
- Default to struct arrays with bounds (and checking) (and _implicit de-struct-ing_).
- Shorthands for appending to arrays.
- Various loops over arrays: inOrder, until, reduce, replace, filter


---

# fnName
» param [const int*] « null
« returnVal [const int*] « null

iff *param > 0

iff param.fn(3)
	» v [float × 4]
	» t [int]

1 » v.1
5 » v

v.until( i »
	o i.isPrime()
	o i == pi )
» returnVal

```c
bool fnName(const int* param, const int** returnVal)
{
	*returnVal = NULL;
	
	if(!(*param > 0)) {
		printf("fnName: Failed on *param > 0\n");
		return false;
	}
	
	floatArray v = emptyArray;
	float vBlock[4] = {0, 0, 0, 0};
	v.block = vBlock;
	v.size = 4;

	int t = 0;	
	int ok = fn(param, 3, v.block, &t);
	v.length = 4;
	
	if(!ok) {
		printf("fnName: Failed on fn(param, 3, v.block, &t)\n");
		return false;
	}
	
	if(0 >= 0 && 0 < v.length) {
		v.block[0] = 1;
	} else {
		printf("fnName: Can't replace v at index 1 with 1 - out of bounds.\n");
	}
	
	if(v.length < v.size) {
		v.block[v.length] = 5;
		v.length++;
	} else {
		printf("fnName: Can't append 5 to v - array is full.\n");
	}
	
	for(int counter = 0; counter < v.length; counter++) {
		floatIndex i = {counter, v.block[counter]};
		int* result = NULL;
		result = result? result : isPrime(i.val);
		result = result? result :  i.val == pi;
		if(result) {
			*returnVal = result;
			break;
		}
	}
	
	return true;
}
```

---

Parsing
```c
const int * fnName ( const int * param );
```
1. Remove all { ... } – replace with ;
2. Separate by ;
3. Find all ( ... )
4. Word before ( is function name
5. Everything before is return type
6. Separate parametres by ,
7. Last word of each is parametre name
8. Rest is type
