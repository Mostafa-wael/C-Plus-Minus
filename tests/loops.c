
print("while loops");
a = 0;
while (a < 20) {
    print(a);
    a = a + 1;
}
print(a);
while (a < 20) {
    if (a == 10) {
        print(a);
    }
    a = a + 1;
}
print(a);
////////////////////////////////
print("for loops");
for (a=2 ; a<10; a = a+1 ) {
    print(a);
}
for (a=2 ; a<10; a= a+1 ) {
    print(a);
    b = a;
    while (b < 10) {
        if (b == 5) {
            print("hi");
            print(b);
        }
        
        b = b + 1;
    }
}
////////////////////////////////
print("repeat loops");
a = 0;
repeat {
    print(a);
    a = a + 1;
    print(a);
} until (a == 1);
repeat {
    print(a);
    a = a + 1;
    if (a == 1) {
        print(a);
    }
} until (a == 1);
////////////////////////////////
print("switch case loops");
switch (a) {
    default:
        print("default");
        break;
}
switch (a) {
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

switch (a) {
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
exit;