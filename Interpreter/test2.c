void main()
{
	int a;
	int b;
	a = 1;
	b = 2;
	if(a > b){
		printf("a=%d > b=%d\n", a,b);
		b = b + a;
	}
	else if(a < b){
		printf("a=%d < b=%d\n", a,b);
		a = a + b;
	}
	else{
		printf("a=%d == b=%d\n", a,b);
		a = a - b; 
	}
		
}