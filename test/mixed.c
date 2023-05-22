{
    int a = 3;
    int b = 10;
    int c = a + b;
    int d = b - a + c + (2 * 3);
    print("declaration");
    {
        const int a = 5;
        int b = -5;
        print(b);
        print(-b);
        float f = 5.5;
        print(b);
        bool c = true;
        // string d = "hello";
        // void e = 0;
        print(c); // 1
        print(d); // hello
        {
            const int a = 10;
            print(a);
        }
    }
    ////////////////////////////////
    {
        print("logic");
        bool a = true;
        bool b = false;
        print(a);      // 1
        print(b);      // 0
        print(a == b); // 0
        print(a != b); // 1
        print(a < b);  // 0
        print(a > b);  // 1
        print(a <= b); // 0
        print(a >= b); // 1
    }
    // ////////////////////////////////
    print("More logic");
    {
        print(!a); // 0
        // print(a && b);             // 0
        // print(a || b);             // 1
        // print((a && a && b) || a); // 1
    }
    // ////////////////////////////////
    {
        print("assignment");
        int a = 10; // 1010
        int b = 10; // 1010
        int c = 2;  // 0010
        int d = a * b + c;
        print(a == 10);
        print(b == 10);
        print(c == 2);
        print(d == 102); // 102
    }
    // ////////////////////////////////
    print("arithmetic");
    {
        int a = 10;       // 1010
        int b = 10;       // 1010
        print(-a == -10); // -10
        // print(-3-4);
        print(a + b == 20);             // 20
        print(a - b == 0);              // 0
        print(a / b == 1);              // 1
        print(a % c == 0);              // 0
        print(a * b - b + a / b == 91); // 91
        print(100 - 5);
        print(-100 - 5 + 5);
    }
    // ////////////////////////////////
    print("bitwise");
    {
        int a = 10; // 1010
        int b = 10; // 1010
        int c = 2;  // 0010
        int d = a * b + c;
        print((a | c) == 10);       // 1010 | 0010 = 1010 = 10
        print((a & c) == 2);        // 1010 & 0010 = 0010 = 2
        print((a ^ c) == 8);        // 1010 ^ 0010 = 1000 = 8
        print((a << c) == 40);      // 1010 << 0010 = 101000 = 40
        print((a >> c) == 2);       // 1010 >> 0010 = 10 = 2
        print((~a) == -11);         // -11
        print((a << c) >> c == 10); // 10
    }

    // ////////////////////////////////
    {
        int a = 10; // 1010
        if (a == 10)
        {
            print("if");
        }
        else if (a == 11)
        {
            print("elif");
        }
        else if (a == 12)
        {
            print("elif");
        }
        else
        {
            int a = 10;
            if (a == 10)
            {
                print("if");
                print("another if");
            }
            else if (a == 11)
            {
                print("else");
                print("another else");
            }
        }
    }
    // ////////////////////////////////
    {
        int a = 10; // 1010
        print("while loops");
        while (a < 20)
        {
            print(a);
            a = a + 1;
        }
        print(a);
        while (a < 20)
        {
            if (a == 10)
            {
                print(a);
            }
            a = a + 1;
        }
        print(a);
    }
    // ////////////////////////////////
    print("for loops");
    for (a = 2; a < 10; a = a + 1)
    {
        print(a);
    }
    for (a = 2; a < 10; a = a + 1)
    {
        print(a);
        b = a;
        while (b < 10)
        {
            if (b == 5)
            {
                print("hi");
                print(b);
            }

            b = b + 1;
        }
    }
    // ////////////////////////////////
    print("repeat loops");
    a = 0;
    repeat
    {
        print(a);
        a = a + 1;
        print(a);
    }
    until(a == 1);
    repeat
    {
        print(a);
        a = a + 1;
        if (a == 1)
        {
            print(a);
        }
    }
    until(a == 1);
    // ////////////////////////////////
    print("switch case loops");
    switch (a)
    {
    default:
        print("default");
        break;
    }
    switch (a)
    {
    case 1:
        print("1");
        break;

    case 2:
        print("2");
        break;

    case 3:
        print("3");
        break;
    }

    // switch (a)
    // {
    // case 1:
    //     print("1");
    //     break;

    // case 2:
    //     print("2");
    //     break;

    // case 3:
    //     print("3");
    //     break;

    // default:
    //     print("default");
    //     break;
    // }
    // ////////////////////////////////
    // print("functions");
    // a + 1;
    // x(1, 2);
    // print("x");
    // int y()
    // {
    //     print("y");
    //     return 1;
    // }
    // int x(int a, int b)
    // {
    //     print("add");
    //     return a + b;
    // }
    // a = y();
    // print("y done");
    // ////////////////////////////////
    // print("enums");
    // enum Color
    // {
    //     RED = 10,
    //     GREEN,
    //     BLUE = 12,
    //     RED
    // };
    // print(0);
    // {
    //     Color c1;
    //     Color c2 = RED;
    //     Color c3 = 3 + 5;
    // }
    // string a = "hi";
    // int b = 5;
    // print(true);
    // print(b);
    // exit;
