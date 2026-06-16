#include <reg51.h>
#include <intrins.h>

#define lcd_data P2

// LCD Control Pins
sbit rs  = P0^0;
sbit rw  = P0^1;
sbit en  = P0^2;

// Sensor Pins
sbit trig = P3^5;
sbit echo = P3^2;

void cmd(unsigned char a);
void dat(unsigned char b);
void lcd_init();
void show(unsigned char *s);
void lcd_delay();

void lcd_delay()
{
    unsigned int i;
    for(i=0; i<=1000; i++);
}

void cmd(unsigned char a)
{
    lcd_data = a;
    rs = 0; rw = 0; en = 1;
    lcd_delay();
    en = 0;
}

void dat(unsigned char b)
{
    lcd_data = b;
    rs = 1; rw = 0; en = 1;
    lcd_delay();
    en = 0;
}

void lcd_init()
{
    cmd(0x38);   // 8-bit, 2-line
    cmd(0x0c);   // Display ON, Cursor OFF
    cmd(0x06);   // Entry mode
    cmd(0x01);   // Clear screen
    lcd_delay();
}

void show(unsigned char *s)
{
    while(*s) dat(*s++);
}

void send_pulse(void)
{
    trig = 1;
    _nop_(); _nop_(); _nop_(); _nop_(); _nop_();
    _nop_(); _nop_(); _nop_(); _nop_(); _nop_();
    trig = 0;
}

unsigned int ultrasonic()
{
    unsigned int time;
    unsigned long timeout = 10000;   // Prevent infinite hanging

    send_pulse();

    // 1. Wait for Echo to go HIGH with timeout
    while(!echo && timeout > 0) timeout--;
    if(timeout == 0) return 0;   // Return 0 if sensor doesn't respond

    // 2. Start Timer and wait for Echo to go LOW
    TR0 = 1;
    TH0 = 0; TL0 = 0;
    while(echo);
    TR0 = 0;

    // 3. Calculate distance
    time = (TH0 << 8) | TL0;
    // Calculation for 11.0592MHz Crystal
    return (time * 1.085 * 0.0343) / 2;
}

void main()
{
    unsigned int range;
    TMOD = 0x01;   // Timer 0, Mode 1 (16-bit)
    lcd_init();

    while(1)
    {
        cmd(0x80);   // Line 1
        show("Distance: ");

        range = ultrasonic();

        cmd(0xC0);   // Move to second line
        if(range == 0)
        {
            show("Check Sensor...");
        }
        else
        {
            dat((range/100) + 48);         // Hundreds
            dat(((range/10)%10) + 48);     // Tens
            dat((range%10) + 48);          // Units
            show(" cm      ");
        }

        lcd_delay();   // Brief pause between readings
    }
}
