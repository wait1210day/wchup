#include <ch32v00x.h>

int main(void)
{
    for (;;) {
        __asm__ volatile ("nop");
    }
}
