#include <sys/mman.h>
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <getopt.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>
#include <errno.h>

uint32_t BaseAddress=0x43c00000;
uint32_t mem_size=0x43c00001;

char Uint8toChar(uint8_t symbolIn){
        if(symbolIn>=0 && symbolIn <=9){
                return (char)(48+symbolIn);
        } else if(symbolIn>=10 && symbolIn <16){
                return (char)(87+symbolIn);
        }else
        {
                printf("0 до 15");
        }
}

int sendRegData(uint32_t mem_address, int value){
    int mem_dev = open("/dev/mem", O_RDWR | O_SYNC);
    if(mem_dev == -1){
     printf("Failed to open /dev/mem sendRegData\n");
       return -1;
    }
    uint32_t alloc_mem_size, page_mask, page_size;
    void *mem_pointer, *virt_addr;

    page_size = sysconf(_SC_PAGESIZE);
    alloc_mem_size = (((mem_size / page_size) + 1) * page_size);
      page_mask = (page_size - 1);
	printf("\npage_mask=%u\n",page_mask);
    mem_pointer = mmap(NULL,
                       1,
                       PROT_READ | PROT_WRITE,
                       MAP_SHARED,
                       mem_dev,
                       (mem_address & ~page_mask)
                       );
      if(mem_pointer == MAP_FAILED){
          return -1;
    }                       
    virt_addr = (mem_pointer + (mem_address & page_mask));
    volatile unsigned int* p = (volatile unsigned int*)virt_addr;
    p[0] = value;              

    munmap(mem_pointer, alloc_mem_size);
    close(mem_dev);
     return value;
}

int readRegData(uint32_t mem_address) {
    int mem_dev = open("/dev/mem", O_RDWR | O_SYNC);

    if(mem_dev == -1) {
       printf("Failed to open /dev/mem readRegData\n");
       return -1;
    }

     uint32_t alloc_mem_size, page_mask, page_size;
    void *mem_pointer, *virt_addr;

    page_size = sysconf(_SC_PAGESIZE);
    alloc_mem_size = (((mem_size / page_size) + 1) * page_size);
    page_mask = (page_size - 1);

    mem_pointer = mmap(NULL,
                       1,
                        PROT_READ | PROT_WRITE,
                       MAP_SHARED,
                       mem_dev,
                       (mem_address & ~page_mask)
                       );

    if(mem_pointer == MAP_FAILED) {
          printf("Failed to map memory\n");
          return -1;
    }
      virt_addr = (mem_pointer + (mem_address & page_mask));
    volatile unsigned int* p = (volatile unsigned int*)virt_addr;
        int rtrn = p[0];    
   int munmprtrn = munmap(mem_pointer, alloc_mem_size);   
close(mem_dev);

    return rtrn;
  }

   int main(int argc, void *argv[]){
	uint32_t a[36];
	uint64_t out;
	char * text="The quick brown fox jumps over the lazy dog";//43
	uint8_t A[144];
	printf("Start programm\n\r");
	for (int i=0; i<43; i++){
		A[i]=(uint8_t)text[i];
	}
	A[43]=0x60;
	for (int i =44; i<143; i++){
		A[i]=0;
	}
	A[143]=0x01;
        for(int i = 0; i<36; i++){
		a[i]=0;
		for (int j=0; j<4; j++){
			a[i] += (uint32_t)A[i*4+j] << j*8;
		}
		sendRegData(BaseAddress+4*4+i*4, a[i]);
		printf("%x ",readRegData(BaseAddress+4*4+i*4));
		if(i==8 || i==16 || i==24 || i==34){
			printf("\n");
		}
	}
	sendRegData(BaseAddress+2*4, 0x00000000);//start=0
//	printf("Start programm=1\n");
	sendRegData(BaseAddress+2*4, 0xFFFFFFFF);//start=1
	uint64_t countc=0;
	while (readRegData(BaseAddress+49*4)==0){
		countc++;
	}
	printf("countc=%llu\n",countc);
	
	printf("\n");
	char rezult[56];
	uint32_t data;
	for(int i = 0 ;i<8; i++){
		data=readRegData(BaseAddress+40*4+i*4);
		printf("%x\n",data);
		for(int j=0; j<8; j++){
			rezult[i*8+j]=Uint8toChar((data>>(4*j)) & 0x0000000f);
		}
	}
	printf("\n");
	for(int i=0;i<56;i++){
		printf("%c",rezult[i]);
	}
	sendRegData(BaseAddress+2*4, 0x00000000);//start=0
        for(int i = 0; i<36; i++){
		sendRegData(BaseAddress+4*4+i*4, 0);	
	}	
	sendRegData(BaseAddress+2*4, 0xFFFFFFFF);//start=1
	countc=0;
	while (readRegData(BaseAddress+49*4)==0){
		countc++;
	}
	printf("\ncountc=%llu",countc);
	
	printf("\n");
	for(int i = 0 ;i<8; i++){
		data=readRegData(BaseAddress+40*4+i*4);
		printf("%x\n",data);
		for(int j=0; j<8; j++){
			rezult[i*8+j]=Uint8toChar((data>>(4*j)) & 0x0000000f);
		}
	}
	printf("\n");
for(int i=0;i<56;i++){
		printf("%c",rezult[i]);
	}
	sendRegData(BaseAddress+2*4, 0x00000000);//start=0
	printf("\nEnd programm\n\r");

}
