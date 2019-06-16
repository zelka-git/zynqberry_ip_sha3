/* определяет типы данных */
#include <sys/types.h>
/* "Главный" по сокетам */
#include <sys/socket.h>
/* sockaddr_in struct, sin_family, sin_port, in_addr_t, in_port_t, ...*/
#include <netinet/in.h>

#include <stdio.h>
#include <memory.h>
#include <string.h>
#include <errno.h>

//for fpga
#include <sys/mman.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <getopt.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>


uint32_t BaseAddress=0x43c00000;
uint32_t mem_size=0x43c00200;

char Uint8toChar(uint8_t symbolIn){
        if(symbolIn>=0 && symbolIn <=9){
                return (char)(48+symbolIn);
        } else if(symbolIn>=10 && symbolIn <16){
                return (char)(87+symbolIn);
        }else
        {
                printf("число должно быть от 0 до 15");
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
    //alloc_mem_size = (((mem_size / page_size) + 1) * page_size);
	alloc_mem_size=1;
      page_mask = (page_size - 1);

    mem_pointer = mmap(NULL,
                       alloc_mem_size,
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
   // alloc_mem_size = (((mem_size / page_size) + 1) * page_size);
	alloc_mem_size=1;
    page_mask = (page_size - 1);

    mem_pointer = mmap(NULL,
                       alloc_mem_size,
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
//max length text 143byte
char* sha3(char *text){
	uint8_t A[144];
        uint32_t a[36];
	int len=strlen(text);
	for(int i=0; i<len; i++){
		A[i]=(uint8_t)text[i];
	}
	if(len==143){
		A[143]=0x61;
	}else if(len==142){
		A[142]=0x60;
		A[143]=0x01;
	}else{
		A[len]=0x60;
		for(int i=len+1; i<143;i++){
			A[i]=0;
		}
		A[143]=0x01;
	}
        for(int i = 0; i<36; i++){
		a[i]=0;
		for (int j=0; j<4; j++){
			a[i] += (uint32_t)A[i*4+j] << j*8;
		}
		sendRegData(BaseAddress+4*4+i*4, a[i]);
	}
	sendRegData(BaseAddress+2*4, 0x00000000);//start=0
//	printf("Start programm=1\n");
	sendRegData(BaseAddress+2*4, 0xFFFFFFFF);//start=1
//	uint64_t countc=0;
//	while (readRegData(BaseAddress+49*4)==0){
//		countc++;
//	}
//	printf("countc=%llu\n",countc);	
//	printf("\n");
	char* rezult=(char*) malloc(57*sizeof(char));
	uint32_t data;
	for(int i = 0 ;i<7; i++){
		data=readRegData(BaseAddress+40*4+i*4);
//		printf("%x\n",data);
		for(int j=0; j<8; j++){
			rezult[i*8+j]=Uint8toChar((data>>(4*j)) & 0x0000000f);
		}
	}
//	rezult[56]='\0';
        char* rezultOut=rezult; 
	// printf("\n");
	// for(int i=0;i<56;i++){
	// 	printf("%c",rezult[i]);
	// }
	sendRegData(BaseAddress+2*4, 0x00000000);//start=0
	return rezultOut;
}


/**@brief Получает от клиента последовательность байт, не длиннее 43 и печатает её на экран по
 * завершении соединения. Клиенту отправляет "Hi, dear!"*/
int main(int argc, char * argv[])
{
      /*создаём сокет*/
      int s = socket(AF_INET, SOCK_STREAM, 0);
      if(s < 0)
      {
              perror("Error calling socket");
              return 0;
      }

      /*определяем прослушиваемый порт и адрес*/
      struct sockaddr_in addr;
      addr.sin_family = AF_INET;
      addr.sin_port = htons(18666);
      addr.sin_addr.s_addr = htonl(INADDR_ANY);
      if( bind(s, (struct sockaddr *)&addr, sizeof(addr)) < 0 )
      {
              perror("Error calling bind");
              return 0;
      }

      /*помечаем сокет, как пассивный - он будет слушать порт*/
      if( listen(s, 5) )
      {
              perror("Error calling listen");
              return 0;
      }

      /*начинаем слушать, для соединения создаём другой сокет, в котором можем общаться.*/
      int s1 = accept(s, NULL, NULL);
      if( s1 < 0 )
      {
              perror("Error calling accept");
              return 0;
      }

      /*читаем данные из сокета*/
      char buffer[44];
      int counter = 0;
      char *response;
      for(;;)
      {
              memset(buffer, 0, sizeof(char)*44);
              /*следует помнить, что данные поступают неравномерно*/
              int rc = recv(s1, buffer, 43, 0);
              if( rc < 0 )
              {
                      /*чтение может быть прервано системным вызовом, это нормально*/
                      if( errno == EINTR )
                              continue;
                      perror("Can't receive data.");
                      return 0;
              }
              if( rc == 0 )
                      break;
             // printf("%s\n", buffer);
              //вставить sha3 на buffer
              response = sha3(buffer);
             // printf("response=\n%s\n",response);
      }
    //   char response[] = "Hi, dear!";
//response="Hi, dear!";
//       if( sendto( s1, response, sizeof(response), 0, (struct sockaddr *)&addr, sizeof(addr) ) < 0 )
if( sendto( s1, response, 56, 0, (struct sockaddr *)&addr, sizeof(addr) ) < 0 )
              perror("Error sending response");
//      printf("Response send\n");
      return 0;
}

