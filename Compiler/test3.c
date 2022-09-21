void main()
{
    int i;
    for (i = 0;i < 10; i = i + 1){
        if(i < 5){
            i = i * 2;
        }
        printf("i = %d\n",i);
    }
    while (i >= 5)
    {
        i = i % 4 + 3;
        printf("i = %d\n",i);
    }
    do
    {
        i = i % 3 + 2;
        printf("i = %d\n",i);
    } while (i > 2);
    i = 0;
}
