int triangle(int a, int b, int c) {
    int match=0, result=-1;
    
    if(a==b) match=match+1;
    if(a==c) match=match+2;
    if(b==c) match=match+3;
    if(match==0) {
        if( a+b <= c) result=2;
        else if( b+c <= a) result=2;
        else if(a+c <= b) result =2;
        else result=3;
    } else {
        if(match == 1) {
            if(a+b <= c) result =2;
            else result=1;
        } else {
            if(match ==2) {
                if(a+c <=b) result = 2;
                else result=1;
            } else {
                if(match==3) {
                    if(b+c <= a) result=2;
                    else result=1;
                } else result = 0;
            } }}

    // 0: equilateral, 1:isoscele, 2:non-triangle, 3:scalene 
    return result;
}

