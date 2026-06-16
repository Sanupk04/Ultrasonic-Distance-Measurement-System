#include "LPC13xx.h"

#define TRIG (1<<0)    // P3.0
#define ECHO (1<<1)    // P3.1

#define RS   (1<<0)    // P2.0
#define RW   (1<<1)    // P2.1
#define EN   (1<<2)    // P2.2

unsigned int range = 0, i;

/* -------- LCD FUNCTIONS -------- */
void lcd_delay()
{
    for(i=0; i<1000; i++);
}

void lcd_cmd(unsigned char cmd_val)
{
    LPC_GPIO1->DATA = cmd_val;          // D0-D7
    LPC_GPIO2->DATA &= ~(RS | RW);     // RS=0, RW=0
    LPC_GPIO2->DATA |= EN;             // EN pulse
    lcd_delay();
    LPC_GPIO2->DATA &= ~EN;
}

void lcd_data(unsigned char data_val)
{
    LPC_GPIO1->DATA = data_val;         // D0-D7
    LPC_GPIO2->DATA |= RS;             // RS=1
    LPC_GPIO2->DATA &= ~RW;            // RW=0
    LPC_GPIO2->DATA |= EN;             // EN pulse
    lcd_delay();
    LPC_GPIO2->DATA &= ~EN;
}

void lcd_init()
{
    lcd_cmd(0x38);   // 8-bit, 2-line, 5x8 font
    lcd_cmd(0x0E);   // Display ON, cursor ON
    lcd_cmd(0x06);   // Entry mode increment
    lcd_cmd(0x0C);   // Display ON, cursor OFF
    lcd_cmd(0x80);   // Move cursor to 1st line
}

void lcd_show(char *str)
{
    while(*str)
        lcd_data(*str++);
}

/* -------- DELAYS -------- */
void delay_us(unsigned int us)
{
    for(i=0; i<us*10; i++);   // rough microsecond delay
}

/* -------- ULTRASONIC -------- */
void ultrasonic_init()
{
    LPC_GPIO3->DIR |= TRIG;    // TRIG output
    LPC_GPIO3->DIR &= ~ECHO;   // ECHO input
}

void send_pulse()
{
    LPC_GPIO3->DATA |= TRIG;
    delay_us(10);              // 10us pulse
    LPC_GPIO3->DATA &= ~TRIG;
}

unsigned int get_range()
{
    unsigned int count = 0;
    send_pulse();

    while(!(LPC_GPIO3->DATA & ECHO));   // wait HIGH
    while(LPC_GPIO3->DATA & ECHO)
    {
        count++;
        delay_us(1);
    }

    return count / 58;   // convert to cm
}

/* -------- MAIN -------- */
int main(void)
{
    SystemInit();

    // GPIO directions
    LPC_GPIO1->DIR = 0xFF;              // LCD data
    LPC_GPIO2->DIR |= (RS | RW | EN);  // LCD control

    ultrasonic_init();
    lcd_init();

    lcd_show("Distance:");

    while(1)
    {
        lcd_cmd(0xC0);   // Move cursor to 2nd line

        range = get_range();

        lcd_data((range/100) + '0');          // hundreds
        lcd_data(((range/10)%10) + '0');      // tens
        lcd_data((range%10) + '0');           // ones

        lcd_show("cm");

        for(i=0; i<50000; i++);   // small delay
    }
}
