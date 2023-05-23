print("conditions");
int a = 10;
print("First if statement start");
if (a == 11){
    a = 11;
}
print("second if statement start");
if (a == 100){
    a = 100;
}
else if (a == 12){
    if (a == 14){
        a = 14;
    }
    else{
        a = 13;
    }
}
else if (a == 13){
   if (a == 15){
        a = 15;
    }
    else if (a == 11){
        a = 11;
    }
}
else{
    a = 14;
}
print("Third if statement start");
if (a == 11){
    a = 11;
}


a = 8;
////////////////////////////////
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
exit;