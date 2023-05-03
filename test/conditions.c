print("conditions");
if (a == 10) {
    print("if");
    print("another if");
}
else if (a == 11) {
    print("elif");
    print("another elif");
}
else {
    print("else");
    print("another else");
    if (a == 10) {
        print("if");
        print("another if");
    }
    else {
        print("else");
        print("another else");
    }
}
if (a == 10) {
    print("if");
    print("another if");
}
else if(a == 11) {
    print("else");
    print("another else");
}
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