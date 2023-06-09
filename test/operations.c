print("arithmetic");
int a = 10;
int b = 10;
int c = 2;
print(c);
print(-a == -10); // -10
print(-3 - 4);
print(a + b == 20);            // 20
print(a - b == 0);             // 0
print(a / b == 1);             // 1
print(a % c == 0);             // 0
print(a *b - b + a / b == 91); // 91
print(100 - 5);
print(-100 - 5 + 5);
////////////////////////////////
print("bitwise");
a = 10;
c = 2;
print((a | c) == 10);       // 1010 | 0010 = 1010 = 10
print((a & c) == 2);        // 1010 & 0010 = 0010 = 2
print((a ^ c) == 8);        // 1010 ^ 0010 = 1000 = 8
print((a << c) == 40);      // 1010 << 0010 = 101000 = 40
print((a >> c) == 2);       // 1010 >> 0010 = 10 = 2
print((~a) == -11);         // -11
print((a << c) >> c == 10); // 10
////////////////////////////////
print("logic");
a = 1;
b = 0;
print(a);      // 1
print(b);      // 0
print(a == b); // 0
print(a != b); // 1
print(a < b);  // 0
print(a > b);  // 1
print(a <= b); // 0
print(a >= b); // 1
////////////////////////////////
print("More logic");
print(!a); // 0
bool x = true;
bool y = false;
print(x &&y);              // 0
print((x && x && y) || x); // 1
exit;