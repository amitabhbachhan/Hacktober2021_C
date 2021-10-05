def binarySearch(arr,l,r,x):
    if r > l:
        mid = l + (r-l)/2
        mid = int(mid)
        # if element is present at the middle itself
        if arr[mid] == x:
            return mid
        
        # if element is smaller then it will be available in left sub array
        if arr[mid] > x:
            return binarySearch(arr,l,mid-1,x)
        
        # if element is greater then mid
        return binarySearch(arr,mid+1,r,x)
    return -1

def exponentialSearch(arr,n,x):
    # if x is present at 0th position
    if arr[0] == x:
        return 0
    
    # find range of binary search
    i = 1
    while i <n and arr[i] <=x:
        i = i*2
    return binarySearch(arr,i/2,min(i,n),x)

arr = [2,4,35,45,56,66,76,87,89]
n = len(arr)
x = 90
result = exponentialSearch(arr,n,x)

if result == -1:
    print("Element not found")
else:
    print("ELement found at: ",result)
