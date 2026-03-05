function [y]=volterra(a,x)
%阶数为5，深度为2
a10=a(1,1);a11=a(1,2);a12=a(1,3);
a30=a(1,4);a31=a(1,5);a32=a(1,6);
a50=a(1,7);a51=a(1,8);a52=a(1,9);
%ain = abs(x);%输入信号的幅度
x=[0,0,x];
for n=3:length(x),
    y(n-2)=a10*x(n)+a11*x(n-1)+a12*x(n-2)+a30*x(n)*(abs(x(n))^2)+a31*abs(x(n-1))^2*x(n-1)+a32*abs(x(n-2))^2*x(n-2)+a50*abs(x(n))^4*x(n)+a51*abs(x(n-1))^4*x(n-1)+a52*abs(x(n-2))^4*x(n-2);
end
end
