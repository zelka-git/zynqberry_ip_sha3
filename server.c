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

//for keccak
#include <stdint.h>
#include <fcntl.h>
#include <stdlib.h>
#include <math.h>

uint8_t S[200];

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

char* transformUint8ToChar(uint8_t *ArrayIn, int len){
         
        // printf("len=%u\n",len);
        char* ArrayOut=(char *) malloc((len*2+1) * sizeof (char));
        for (int i=0;i<len;i++){
                ArrayOut[i*2]=Uint8toChar(0x0f & ArrayIn[i]);
                ArrayOut[i*2+1]= Uint8toChar(ArrayIn[i] >> 4);      
                // printf("%d %x %c %c\n",i,ArrayIn[i], ArrayOut[i*2], ArrayOut[i*2+1]);  
        }
        ArrayOut[len*2]='\0';
        return ArrayOut;
}



int parameterRotateBit[5][5]={
    { 0, 1, 62, 28, 27 },
    { 36, 44, 6, 55, 20 },
    { 3, 10, 43, 25, 39 },
    { 41, 45, 15, 21, 8 },
    { 18, 2, 61, 56, 14 }
};
const uint64_t RC[] = {
	0x0000000000000001L, 0x0000000000008082L, 0x800000000000808aL,
	0x8000000080008000L, 0x000000000000808bL, 0x0000000080000001L,
	0x8000000080008081L, 0x8000000000008009L, 0x000000000000008aL,
	0x0000000000000088L, 0x0000000080008009L, 0x000000008000000aL,
	0x000000008000808bL, 0x800000000000008bL, 0x8000000000008089L,
	0x8000000000008003L, 0x8000000000008002L, 0x8000000000000080L,
	0x000000000000800aL, 0x800000008000000aL, 0x8000000080008081L,
	0x8000000000008080L, 0x0000000080000001L, 0x8000000080008008L
};

uint64_t arrayRotateRight(uint64_t B, int x){
	uint64_t Shift;
	Shift = ((B << x) + (B >> 64-x));
	return Shift;
}

void keccak(void){
	uint64_t A[5][5];
	uint64_t C[5], D[5];
	uint64_t nA[5][5];
	uint64_t I=0xffffffffffffffff;
	//string S how array uint64_t A[5][5]
	for (int i = 0 ; i < 5; i++){
		for (int j = 0; j < 5; j++){
			A[i][j]=0;
			for (int k = 0; k < 8; k++)			{
				A[i][j] += ((uint64_t)S[((j+5*i)*8)+k]) << k*8;
				uint64_t y =  ((uint64_t)S[((j+5*i)*8)+k]) << k*8;
			}
		}
	}

	for( int ir=0; ir<24;ir++){
		//transposition Q
		for(int i = 0; i < 5 ;i++){
			C[i]=A[i][0] ^ A[i][1] ^ A[i][2] ^ A[i][3] ^ A[i][4];
		}
		for(int i = 0; i < 5; i++){
			D[i]=C[(i+4) % 5] ^ arrayRotateRight(C[(i+1) % 5], 1);
		}
		for(int i = 0; i < 5; i++){
			for(int j = 0; j < 5; j++){
				A[i][j] = A[i][j] ^ D[i];
			}
		}
		//transposition p
		for(int i = 0; i < 5; i++){
			for(int j = 0; j < 5; j++){
				A[i][j] = arrayRotateRight(A[i][j],parameterRotateBit[i][j]);
			}
		}
		//transposition pi
		for(int i = 0; i < 5; i++){
			for(int j = 0; j < 5; j++){
				nA[i][j] = A[(i+3*j) % 5][i];
			}
		}		
		//transposition xi
		for(int i = 0; i < 5; i++){
			for(int j = 0; j < 5; j++){
				A[i][j] = nA[i][j] ^ ((nA[(i+1) % 5][j] ^ I) & nA[(i+2) % 5][j]);
			}
		}
		//transposition i	
		A[0][0] ^= RC[ir];	
	}
	//Array uint64_t A[5][5] in string S
	for (int i = 0 ; i < 5; i++){
		for (int j = 0; j < 5; j++){
			for (int k = 0; k < 8; k++){
				S[((j+5*i)*8)+k]=(uint8_t)(A[i][j] >> k*8);
			}
		}
	}
}

char* sha3(int type, char *text){
	int r,c;
	int hash_size = type;
	// char *file_path;
	//char *file_path="C:/Anzhelika/study 4 sem/text.txt";
	char *M;
	uint8_t *N;
	char Mi[9];
	int countOfMi;
	uint8_t *Rezult;
	//char M[]= "The quick brown fox jumps over the lazy dog";
	// file_path = 
	M = text;
  switch( hash_size ) {
   	case 224:
   		r=1152;
   		c=448;
   		break;
	case 256:
		r=1088;
   		c=512;
   		break;
	case 384:
		r=832;
   		c=768;
   		break;
	case 512:
		r=576;
   		c=1024;
		break;
	default:
		printf("options: 224|256|384|512 file_path\n");
		return "-1";
	}
	int size_file=strlen(M);
	int size_string;
	//determine the size of the string multiple (r/8)
	if ((size_file+1)%(r/8)!=0){
		size_string = ((int)(size_file/(r/8))+1)*(r/8);
	}else {
		size_string=size_file+1;
	}
	countOfMi=size_string/(r/8);
	// M=(char *) malloc((size_file+1) * sizeof (char));
	N=(uint8_t *) malloc((size_string) * sizeof (uint8_t));
	// fread(M,size_file,1,fd);
	// M[size_file]='\0';
	// fclose(fd);
	int delta_string = size_string-size_file;
	//printf("delta_string = %d\n",delta_string);
	int len=strlen(M);
	//printf("len M=%d\n",len);
	for (int i=0; i<len; i++){
	 	N[i]=(uint8_t)M[i];
	 	// printf("i-%d %d\n",i, N[i]);
	}
	//add to end of string 01 bit and bits 1|0..0|1 to size multiple r/8 
	if (delta_string==1){
	 	N[len]=0x61;
	}else if(delta_string==2){
	 	N[len]=0x60;
	 	N[len+1]=0x01;
  }else{
  	N[len]=0x60;
  	for(int i=0; i<delta_string-2;i++){
  		N[len+i+1]=0x00;
  	}
  	N[len+delta_string-1]=0x01;
  }
//   printf("%s\n\n", M);
  for(int i=0; i<(r+c)/8;i++){
  	S[i]=0;
  }
  //sponge algorithm
  for(int k = 0; k < countOfMi; k++)
  {
  	for(int i=k;i<(r*(k+1))/8;i++){
  		S[i] ^= N[i];

  	}
		keccak();
  	
  }
  //Give first hash_size bit
  Rezult=(uint8_t *) malloc((hash_size/8+1) * sizeof (uint8_t));
  for(int i=0; i < hash_size/8; i++){
  	Rezult[i]=S[i];
  }
  for (int i=0;i< hash_size/8; i++){
//  	printf("%x", Rezult[i]);
  }
//  printf("\n");
  // M=(char *) malloc((size_file+1) * sizeof (char));
  char* RezultChar= transformUint8ToChar(Rezult, hash_size/8);
//   printf("%s\n\n",RezultChar);
  return RezultChar;
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
              response = sha3(224, buffer);
             // printf("%s\n",response);
      }
//       char response[] = "Hi, dear!";
//       if( sendto( s1, response, sizeof(response), 0, (struct sockaddr *)&addr, sizeof(addr) ) < 0 )
if( sendto( s1, response, 56, 0, (struct sockaddr *)&addr, sizeof(addr) ) < 0 )
              perror("Error sending response");
//      printf("Response send\n");
      return 0;
}
