#include <cuda_runtime.h>
#include <device_launch_parameters.h>

#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>

//__global__ void strcmp(int* result, char* str, int i, int n) {
//	// Strings to be compared
//	int x = blockIdx.x, y = threadIdx.x;
//
//	int xy = x * n + y;
//
//	// If start of comparison
//	if (i == 0)
//		result[xy] = str[x] - str[y];
//	
//	// Previous result is zero, i.e. undecided
//	else if (result[xy] == 0) {
//		int i1 = x + i, i2 = y + i;
//
//		// Check if within bounds
//		if (i1 < n && i2 < n)
//			result[xy] = str[i1] - str[i2];
//	}
//}

__global__ void strcmp(int* result, char* str, int n) {
	// Strings to be compared
	int x = blockIdx.x, y = threadIdx.x;

	//int xy = x * n + y;

	// If start of comparison
	int r = str[x] - str[y], i;

	for (i = 1; i < n; i++) {
		if (r != 0) {
			break;
		}

		int i1 = x + i, i2 = y + i;
		if (i1 < n && i2 < n) {
			r = str[i1] - str[i2];
		}
		else break;
	}
	result[x * n + y] = r;
}

__global__ void oddeven(int* result, int* arr, int odd, int n) {
	int id = blockIdx.x;
	int lower = id * 2 + odd;
	int higher = lower + 1;

	// Check if within bounds
	if (higher < n) {
		int xy = arr[lower] * n + arr[higher];
		//printf("\nid=%d odd=%d low=%d high=%d compIndex=%d compVal=%d\n", id, odd, lower, higher, xy, result[xy]);

		//printf("Before: %d\t%d\t%d\t%d\t%d\n", arr[0], arr[1], arr[2], arr[3], arr[4]);
		// If string comparison is negative then swap
		if (result[xy] > 0) {
			int temp = arr[lower];
			arr[lower] = arr[higher];
			arr[higher] = temp;
		}

		//printf("After: %d\t%d\t%d\t%d\t%d\n", arr[0], arr[1], arr[2], arr[3], arr[4]);
	}
}

void randomDnaCodeGenerator(int size, char string[]) {
	int i;
	char a = 'A';
	char c = 'C';
	char g = 'G';
	char t = 'T';
	char dollar = '$';
	//time_t tick;

	//srand((unsigned) time(&tick));

	for (i = 0; i < size-1; i++) {
		switch (rand() % 4) {
		case 0: string[i] = a;
			break;
		case 1: string[i] = c;
			break;
		case 2: string[i] = g;
			break;
		case 3: string[i] = t;
			break;
		}
	}

	string[size] = dollar;
	string[size + 1] = 0;
}

int main() {
	int size = 10000;
	char dna[10000];

	randomDnaCodeGenerator(size, dna);

	printf("DNA: %s\n\n", dna);

	int arr[sizeof(dna) / sizeof(char)];

	int n = 0;
	while (dna[n] != '$')
	{
		arr[n] = n;
		n++;
	}
	arr[n] = n; // For '$'

	n++; // n is the number of Elements

	char* cudaDNA;
	int * cudaARR;

	int rSize = n * n;
	int* cudaResult;

	float elapsed = 0;
	cudaEvent_t start, stop;

	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaMalloc(&cudaDNA, n * sizeof(char));
	cudaMemcpy(cudaDNA, dna, n * sizeof(char), cudaMemcpyHostToDevice);

	cudaMalloc(&cudaARR, n * sizeof(int));
	cudaMemcpy(cudaARR, arr, n * sizeof(int), cudaMemcpyHostToDevice);

	cudaMalloc(&cudaResult, rSize * sizeof(int));

	int i;

	cudaEventRecord(start);
	//for (i = 0; i < n; i++)
		//strcmp << < n, n >> >(cudaResult, cudaDNA, i, n);

		strcmp << < n, n >> >(cudaResult, cudaDNA, n);

	for(i = 0;i < n; i++)
		oddeven <<<n / 2, 2 >>>(cudaResult, cudaARR, i % 2, n);
	cudaEventRecord(stop);

	int* result;
	result = (int*) malloc(rSize * sizeof(int));
	cudaMemcpy(result, cudaResult, rSize * sizeof(int), cudaMemcpyDeviceToHost);
	cudaMemcpy(arr, cudaARR, n * sizeof(int), cudaMemcpyDeviceToHost);

	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&elapsed, start, stop);

	/*for (i = 1; i <= rSize; i++) {
		printf("%d ", result[i-1]);
		if (i % n == 0)
			printf("\n");
	}*/

	//printf("\n");
	/*for (i = 0; i < n; i++)
		printf("%d ", arr[i]);*/

	printf("\n\nElapsed Time: %f", elapsed);

	cudaFree(cudaDNA);
	cudaFree(cudaARR);
	cudaFree(cudaResult);
	free(result);

	getch();
	return 0;
}