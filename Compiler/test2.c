void main()
{
	int a,b;
	a = 1;
	b = 2;
	if(a > b){
        if(a == 1){
            a = a + b; 
        }
		printf("a=%d > b=%d\n", a,b);
		b = b + a;
	}
    if(a < b){
		printf("a=%d < b=%d\n", a,b);
		b = b + a;
	}
	else{
		printf("a=%d == b=%d\n", a,b);
		a = a - b; 
	}
	a = b;
}