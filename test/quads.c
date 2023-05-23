int a;
int b = 0;
for (a = 2; a < 10; a = a + 1)
{

    while (b < 10)
    {
        if (b == 5)
        {
            print("hi");
            print(b);
        }

        b = b + 1;
    }

    print(a);
    b = a;
}
exit;
