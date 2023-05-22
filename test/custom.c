print("Custom");
{
    int a = 1;
    const float b = 2.0;
    bool c = true;
    int d;

    {
        d = 9;
        float e = 8.0;
    }
    print(a);
    print(b);
    print(c);
    print(d);
}
