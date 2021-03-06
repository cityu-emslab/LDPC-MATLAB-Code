clear all
clc

% Reference:
%   "CooECC: A Cooperative Error Cprrection Scheme to Reduce LDPC Decoding Latency in NANA Flash"
%    "Read and Write Voltage Signal Optimization for Multi-Level-Cell (MLC) NAND Flash Memory"
%    "Adaptive Read Thresholds for NANA Flash"
%    "Optimizing NAND Flash-Based SSDs via Retention Relaxation"

% load('256_512.mat'); H=H1;
load('H_1021_9216.mat');  H=newH;   % Constructed by 'Check_Matrix_Construction.m'
[m,n]=size(H);
% [P,rearranged_cols]=H2P(H);
load('rearranged_cols.mat')   % Generated by 'H2P.m'
load('P.mat')      % Generated by 'H2P.m'

frame=500;
iter=6;

SNR=[3.2];%  3.6 4 4.4 4.6 5 5.4 5.8];
sigma_cells = [0.3269 0.3228 0.3184 0.3135 0.3082 0.3023 0.2954 0.2873];   % 'rberVStimeANDsigma.m'
% d = [0.127 0.125 0.1225 0.12 0.117 0.114 0.11 0.106];   % 'MutualInformationVSdistance.m'
d = [0.184 0.179 0.174 0.169 0.163 0.157 0.15 0.142];   %  'Entropy.m', when theta=0.2

Strategy=0;

ls=length(SNR);
berlsb0=zeros(1,ls);
bermsb0=zeros(1,ls);
berlsb=zeros(1,ls);
bermsb=zeros(1,ls);
%     berlsb2=zeros(1,ls);
%     bermsb2=zeros(1,ls);
%     nerrlsb0=cell(ls,1);
%     nerrmsb0=cell(ls,1);
%     nerrlsb2=cell(ls,1);
%     nerrmsb2=cell(ls,1);
for SNRindex=1:length(SNR)
    
    sigma_c=sigma_cells(SNRindex);
    
    points=[-2-d(SNRindex) -2+d(SNRindex) 0-d(SNRindex) 0+d(SNRindex) 2-d(SNRindex) 2+d(SNRindex)];

    N0 = 1/(exp(SNR(SNRindex)*log(10)/10));
    sigma=sqrt(N0/2);   % noise variance
    
    total_errlsb0=0;
    total_errmsb0=0;
    total_errlsb=0;
    total_errmsb=0;
    %         total_errlsb2=0;
    %         total_errmsb2=0;
    loop=0;
    while loop<frame
        % MLC 
        slsb=round(rand(1, n-m));
        smsb=round(rand(1, n-m));
        
        s=[slsb;smsb]';
        
        % 4-PAM modulation
        tx0=PAM4mod(s);  
        noise=sigma*randn(1,n);
        rx0=tx0+noise(1:(n-m)); % add noise�>received signal
        
        % 4-PAM demodulation
        rx0=PAM4demod(rx0);  
        rxlsb0=rx0(1:(n-m));
        rxmsb0=rx0((n-m+1):end);
        
        u1=[mod(slsb*P',2) slsb];
        ulsb=reorder_bits(u1,rearranged_cols);
        
        u2=[mod(smsb*P',2) smsb];
        umsb=reorder_bits(u2,rearranged_cols);
        
        u=[ulsb;umsb]';
        
        % 4-PAM modulation
        tx=PAM4mod(u);
        rx=tx+noise;
        
        [LLR,Pr]=computePandLLR_6ReferenceVoltages(rx,sigma_c,points);
%         [LLR,Pr]=computePandLLR_9ReferenceVoltages(rx,sigma_c,points);

        [vlsb,vmsb] = decodeProbDomain(rx, H,iter,Pr);    % LDPC Belief-Propagation decoder
%         [vlsb,vmsb] = decodeProbDomain_mex(rx, H,iter,Pr);
        ulsb = extract_mesg(vlsb,rearranged_cols);
        umsb = extract_mesg(vmsb,rearranged_cols);
        
%         [vlsb2,vmsb2] = decodeMS(rx, H, iter,LLR);     % LDPC Min Sum decoder
%         [vlsb2,vmsb2] = decodeMS_mex(rx, H, iter,LLR);
%         ulsb2 = extract_mesg(vlsb2,rearranged_cols);
%         umsb2 = extract_mesg(vmsb2,rearranged_cols);
        
        errmaxlsb0=find(slsb~=rxlsb0); 
        nerrlsb0=length(errmaxlsb0);
        total_errlsb0=total_errlsb0+nerrlsb0;
        
        errmaxmsb0=find(smsb~=rxmsb0); 
        nerrmsb0=length(errmaxmsb0);
        total_errmsb0=total_errmsb0+nerrmsb0;
        
        errmaxlsb=find(slsb~=ulsb); % BP
        nerrlsb=length(errmaxlsb);
        total_errlsb=total_errlsb+nerrlsb;
        
        errmaxmsb=find(smsb~=umsb); % BP
        nerrmsb=length(errmaxmsb);
        total_errmsb=total_errmsb+nerrmsb;
        
%         errmaxlsb2=find(slsb~=ulsb2); % MS
%         nerrlsb2=length(errmaxlsb2);
%         total_errlsb2=total_errlsb2+nerrlsb2;
%         
%         errmaxmsb2=find(smsb~=umsb2); % MS
%         nerrmsb2=length(errmaxmsb2);
%         total_errmsb2=total_errmsb2+nerrmsb2;
        
        loop=loop+1;
    end
    
    errratiolsb0=total_errlsb0/(length(slsb)*frame);
    berlsb0(SNRindex)=errratiolsb0;  % lsb-rber
    
    errratiomsb0=total_errmsb0/(length(smsb)*frame);
    bermsb0(SNRindex)=errratiomsb0;  % msb-rber
    
    errratiolsb=total_errlsb/(length(slsb)*frame);
    berlsb(SNRindex)=errratiolsb;
    
    errratiomsb=total_errmsb/(length(smsb)*frame);
    bermsb(SNRindex)=errratiomsb;
    
%     errratiolsb2=total_errlsb2/(length(slsb)*frame);
%     berlsb2(SNRindex)=errratiolsb2;
%     
%     errratiomsb2=total_errmsb2/(length(smsb)*frame);
%     bermsb2(SNRindex)=errratiomsb2;
    
    
end

excelname=['H_1021_9216_it=6_fr=500_sym_Strategy',num2str(Strategy),'.xlsx'];
figname=['H_1021_9216_it=6_fr=500_sym_Strategy',num2str(Strategy),'.fig'];

data=[SNR',berlsb0',bermsb0',berlsb',bermsb'];  % ,berlsb2',bermsb2'   

datacell=num2cell(data);
title0={'theta','Uncode-lsb','Uncode-msb','BP-lsb','BP-msb'};   %,'MS-lsb','MS-msb'
result=[title0;datacell];
xlswrite(excelname,result);
close

figure
semilogy(SNR,berlsb0,'-.*g',SNR,bermsb0,'-<g',SNR,berlsb,'-.*b',SNR,bermsb,'-<b');  % ,SNR,berlsb2,'-.*r',SNR,bermsb2,'-<r'
legend('Uncode-lsb','Uncode-msb','BP-lsb','BP-msb')   %  ,'MS-lsb','MS-msb'
xlabel('SNR')
ylabel('BER/RBER')
grid on
title('Iteration=6,frame=500')
axis([0.1 0.5 10^-8 10^-0])
saveas(gcf,figname);   



