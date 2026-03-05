clc;
close all;
%% 信号产生
simout=load('qpsk_8000.mat');
simout=simout.simout;

fs=2*10^8;%采样率200Mhz
st=0:length(simout)-1;
s_qpsk=(simout.').*exp(j*2*pi*20000000*st/fs);%取实部为QPSK调制
%% 滤波器系数设置
N=50;%滤波器阶数
Wn1=[0.75,0.85];%1为fs的一半
Wn2=[0.15,0.25];
A=fir1(N,Wn1,'bandpass');
B=fir1(N,Wn2,'bandpass');
%% 功率放大
fc=6*10^7;%载波60MHZ
t=1:length(s_qpsk);
s_carri=s_qpsk.*exp(j*2*pi*fc*(t-1)/fs);%上变频
s_carri_b=filter(A,1,s_carri);%带通滤波
h = spectrum.welch; 
hpsd_carri_b=psd(h,s_carri_b,'fs',fs);
figure(1);
plot(hpsd_carri_b);%功率放大前的功率谱密度
a=[1.0513+0.0904j,-0.068-0.0023j,0.0289+0.0054j,0.0542-0.29j,0.2234+0.2317j,-0.0621-0.0932j,-0.9657-0.7028j,-0.2451-0.3735j,0.1229+0.1508j];
%a=[2.3,4.2,1.3,-1.2,-3.2,9.1,0.5,2.67,1.7];
HPA_s=volterra(a,s_carri_b);
% h=spectrum.welch;
hpsd=psd(h,HPA_s,'fs',fs);
figure(2);
plot(hpsd);
%% 预失真+功放-----多项式法
b=[1.0513+0.0904j,-0.068-0.0023j,0.0289+0.0054j,0.0542-0.29j,0.2234+0.2317j,-0.0621-0.0932j,-0.9657-0.7028j,-0.2451-0.3735j,0.1229+0.1508j];
%b=[2.3,4.2,1.3,-1.2,-3.2,9.1,0.5,2.67,1.7];
w=zeros(1,length(b));
w=[0.01+0.01j,0.01+0.01j,0.01+0.01j,0.01+0.01j,0.01+0.01j,0.01+0.01j,0.01+0.01j,0.01+0.01j,0.01+0.01j];
%w=[0.00679765478699548-0.000259498756269653i,0.00837971394159005-0.000111941227697152i,0.0114287412467534+0.000135048972435035i,0.00999572083062263-3.11814652641192e-07i,0.00999748855999973-1.58555811669834e-07i,0.0100016305410513+1.47719343296075e-07i,0.00999993931875462-4.06509747496053e-09i,0.00999995731939103-2.60788444989852e-09i,0.0100000155833265+1.43812621935027e-09i];
s_qpsk=[0,0,s_qpsk];
u=0.05;%LMS算法的参数
DPD_s0=zeros(1,length(HPA_s)+2);
DPD_s1=zeros(1,length(HPA_s)+2);
DPD_s=zeros(1,length(HPA_s)+2);
LVB1=zeros(1,N+1);
LVB2=zeros(1,N+1);
HPA_s_p=zeros(1,length(HPA_s)+2);
e=zeros(1,length(HPA_s));
y=zeros(1,length(HPA_s)+2);
lamda=0.99;%QRD-RLS算法的参数
y_q=zeros(1,length(HPA_s)+2);
Y_q=ones(9,9);
X_q=zeros(1,9);
for n=3:length(HPA_s)+2,
    %预失真
    S_qpsk=[s_qpsk(n),s_qpsk(n-1),s_qpsk(n-2),abs(s_qpsk(n))^2*s_qpsk(n),abs(s_qpsk(n-1))^2*s_qpsk(n-1),abs(s_qpsk(n-2))^2*s_qpsk(n-2),abs(s_qpsk(n))^4*s_qpsk(n),abs(s_qpsk(n-1))^4*s_qpsk(n-1),abs(s_qpsk(n-2))^4*s_qpsk(n-2)];
    DPD_s0(n)=w*S_qpsk.';
    %上变频
    DPD_s1(n)=DPD_s0(n)*exp(j*2*pi*fc*(n-3)/fs);
    %滤波
    LVB1=[DPD_s1(n),LVB1(1:N)];
    DPD_s(n)=A*LVB1.';
    %功放
    DPD_S=[DPD_s(n),DPD_s(n-1),DPD_s(n-2),abs(DPD_s(n))^2*DPD_s(n),abs(DPD_s(n-1))^2*DPD_s(n-1),abs(DPD_s(n-2))^2*DPD_s(n-2),abs(DPD_s(n))^4*DPD_s(n),abs(DPD_s(n-1))^4*DPD_s(n-1),abs(DPD_s(n-2))^4*DPD_s(n-2)];
    HPA_s_p(n)=b*DPD_S.';
    %下变频
    DPD_s2(n)=HPA_s_p(n)*exp(j*2*pi*fc*(n-3)/fs);
    %滤波
    LVB2=[DPD_s2(n),LVB2(1:N)];
    DPD_s3(n)= B*LVB2.';
    %LMS自适应算法
    y(n)=DPD_s3(n)/2;%假设功率放大4倍
    Y=[y(n),y(n-1),y(n-2),abs(y(n))^2*y(n),abs(y(n-1))^2*y(n-1),abs(y(n-2))^2*y(n-2),abs(y(n))^4*y(n),abs(y(n-1))^4*y(n-1),abs(y(n-2))^4*y(n-2)];
    e(n-2)=DPD_s0(n)-w*Y.';
    w=w-u*Y*e(n-2);
    %自适应算法---QRD-RLS
%      X_q=[DPD_s0(n),X_q(1),X_q(2),X_q(3),X_q(4),X_q(5),X_q(6),X_q(7),X_q(8)];%期望信号
%      y_q(n)=DPD_s3(n)/2;%假设功放放大4倍
%      Y_q_t=[y_q(n),y_q(n-1),y_q(n-2),abs(y_q(n))^2*y_q(n),abs(y_q(n-1))^2*y_q(n-1),abs(y_q(n-2))^2*y_q(n-2),abs(y_q(n))^4*y_q(n),abs(y_q(n-1))^4*y_q(n-1),abs(y_q(n-2))^4*y_q(n-2)];
%      Y_q=[Y_q_t;Y_q(1,:);Y_q(2,:);Y_q(3,:);Y_q(4,:);Y_q(5,:);Y_q(6,:);Y_q(7,:);Y_q(8,:)];%预失真训练器的输入信号
%      Am=[1,0,0,0,0,0,0,0,0;0,lamda,0,0,0,0,0,0,0;0,0,lamda^2,0,0,0,0,0,0;0,0,0,lamda^3,0,0,0,0,0;0,0,0,0,lamda^4,0,0,0,0;0,0,0,0,0,lamda^5,0,0,0;0,0,0,0,0,0,lamda^6,0,0;0,0,0,0,0,0,0,lamda^7,0;0,0,0,0,0,0,0,0,lamda^8];%权重矩阵
%      [Q,R]=qr(Am*Y_q);
%      U=Q'*(Am*X_q.');
%      w=(U\R);%R是上三角矩阵，逐个回代即可解w
end
% h=spectrum.welch;
hpsd_HPA_s_p=psd(h,HPA_s_p(2000:end),'fs',fs);
figure(3);
plot(hpsd_HPA_s_p);
%% 预失真+功放-----查找表法
ram1=ones(1,80000);
ram2=zeros(1,80000);
ram3=zeros(1,10000);%考虑记忆效应的作用时要初始化这个表
%b_c=[2.3,4.2,1.3,-1.2,-3.2,9.1,0.5,2.67,1.7];
b_c=[1.0513+0.0904j,-0.068-0.0023j,0.0289+0.0054j,0.0542-0.29j,0.2234+0.2317j,-0.0621-0.0932j,-0.9657-0.7028j,-0.2451-0.3735j,0.1229+0.1508j];
% b_c=[1.0513+0.0904j,0,0,0.0542-0.29j,0,0,-0.9657-0.7028j,0,0];
DPD_c_s0=zeros(1,length(HPA_s)+2);
DPD_c_s1=zeros(1,length(HPA_s)+2);
s_qpsk_c=zeros(1,length(HPA_s)+2);
LVB_c1=zeros(1,N+1);
LVB_c2=zeros(1,N+1);
HPA_s_c=zeros(1,length(HPA_s)+2);
s_abs_square=ones(1,length(HPA_s)+2);
u_p=-0.001;
u_s=0.98;
v_max_square=0.6;
R_max=10000;
%预失真
for i=3:length(HPA_s)+2,
    s_abs(i)=abs(s_qpsk(i));
    s_abs_square(i)=s_abs(i)^2;
    if(s_abs_square(i)<=v_max_square),
        n_s=floor(s_abs_square(i)/v_max_square*length(ram1));
    else
        n_s=length(ram1)-1;
    end;
    b_s_a=ram1(n_s+1);
    b_s_f=ram2(n_s+1);
    R_y=s_abs_square(i-1)/s_abs_square(i);
    if(R_y<=R_max),
        n_y=floor(R_y/R_max*length(ram3));
    else 
        n_y=length(ram3)-1;
    end;
    DPD_c_s0(i)=(s_qpsk(i)*b_s_a+abs(ram3(n_y+1)))*exp(j*(b_s_f+angle(ram3(n_y+1))));
%     DPD_c_s0(i)=(s_qpsk(i)*b_s_a)*exp(j*(b_s_f));
    %上变频
    DPD_c_s1(i)=DPD_c_s0(i)*exp(j*2*pi*fc*(i-3)/fs);
    %滤波
    LVB_c1=[DPD_c_s1(i),LVB_c1(1:N)];
    s_qpsk_c(i)=A*LVB_c1.';
%功率放大
    DPD_S_C=[s_qpsk_c(i),s_qpsk_c(i-1),s_qpsk_c(i-2),abs(s_qpsk_c(i))^2*s_qpsk_c(i),abs(s_qpsk_c(i-1))^2*s_qpsk_c(i-1),abs(s_qpsk_c(i-2))^2*s_qpsk_c(i-2),abs(s_qpsk_c(i))^4*s_qpsk_c(i),abs(s_qpsk_c(i-1))^4*s_qpsk_c(i-1),abs(s_qpsk_c(i-2))^4*s_qpsk_c(i-2)];
%     DPD_S_C=[s_qpsk_c(i),abs(s_qpsk_c(i))^2*s_qpsk_c(i),abs(s_qpsk_c(i))^4*s_qpsk_c(i)];
    HPA_s_c(i)=b_c*DPD_S_C.';
  %下变频
  DPD_c_s2(i)=HPA_s_c(i)*exp(j*2*pi*fc*(i-3)/fs);
  %滤波
   LVB_c2=[DPD_c_s2(i),LVB_c2(1:N)];
   DPD_c_s3(i)= B*LVB_c2.';
%自适应算法---LMS
    e_p=2*s_abs(i)-abs(DPD_c_s3(i));%功率放大4倍
    e_s=angle(s_qpsk(i))-angle(DPD_c_s3(i));
    ram1(n_s+1)=ram1(n_s+1)+e_p*u_p;
    ram2(n_s+1)=ram2(n_s+1)+e_s*u_s;
end
% h = spectrum.welch; 
hpsd_HPA_s_c=psd(h,HPA_s_c(2000:end),'fs',fs);
figure(4);
plot(hpsd_HPA_s_c);