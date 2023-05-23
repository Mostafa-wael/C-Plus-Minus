int a = 10;
int b = 20;
print("switch case loops////////////////////////////////////");
switch (a)
{
default:
    print("default");
    break;
}

print("switch case2 loops////////////////////////////////////");
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
print("switch case3 loops////////////////////////////////////");
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

default:
    print("default");
    break;
}
print("switch case4 loops////////////////////////////////////");
switch (a)
{
case 1:
    print("1");
    break;

case 2:
    switch (b)
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

    default:
        print("default");
        break;
    }

case 3:
    print("3");
    break;

default:
    print("default");
    break;
}
exit;