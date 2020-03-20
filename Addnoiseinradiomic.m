clc;
clear;
Rootpath='D:\Dataset\CTDenoisingDataset\NSCLC-Radiomics\';
Fileindex=textread([Rootpath,'UseableIndex.txt']);
RMSE1=0;
CGANlowTest='D:\Dataset\CTDenoisingDataset\CGANData\LownoisedTestdataset\val\';
CGANlowDicom='D:\Dataset\CTDenoisingDataset\CGANData\LownoisedTestdataset\Dicom\';
count=0;
for i=1:size(Fileindex,1)    
    Path1=[Rootpath,'LUNG1-',sprintf('%03d',Fileindex(i))];
    File2=dir(fullfile(Path1));
    for t=1:size(File2,1)
        if strfind(File2(t).name,'StudyID')
            Path2=[Path1,'\',File2(t).name];
        end        
    end
    Path3=[Path2,'\AdjustImage\']
    File4=dir([fullfile(Path3),'*.dcm']);
    %f=fopen([Path3,'max_min.txt'],'W+');
    TestFile=[Path3,'TestFile'];
    %mkdir(TestFile);
    %NoisedDicom=[TestFile,'\Dicom4'];
    %mkdir(NoisedDicom);
    %StandardImage=[TestFile,'\Standard4'];
    %mkdir(StandardImage);
    %NoisedFile=[TestFile,'\Noised4'];
    %mkdir(NoisedFile);
    for j=1:size(File4,1)
        j
       info=dicominfo([Path3,File4(j).name]);
       Image=dicomread(info);
       %Intensitymin=min(min(Image));
       %Intensitymax=max(max(Image));
      % fprintf(f,'%d\t%d\n',Intensitymin,Intensitymax);
       theta=0:179;
       Noised_Radon_Image=[];       
       for t=1:180
           Radon_Image_line=radon(Image,theta(t));
           for s=1:729
                Radon_Image_line(s)=(1+normrnd(0,0.0025))*Radon_Image_line(s);
           end    
           Noised_Radon_Image=[Noised_Radon_Image,Radon_Image_line];
       end
       [Radon_Image,x]=radon(Image,theta);
       Original_Image=Image;
       %low=min(min(Image));
       %high=max(max(Image));
       %maxgray=high-low;
       rate=double(256.0/2000);
       Antiradon_Image=uint16(iradon(Radon_Image,theta));
       Radon_noise=Image-(Antiradon_Image(2:513,2:513));
       Antinoisedimage=uint16(iradon(Noised_Radon_Image,theta));
       NoisedImage=Antinoisedimage(2:513,2:513)-Radon_noise;
       NoisedImage(find(NoisedImage>2000))=2000;
       NoisedImage2=double(NoisedImage);
       NoisedImage2=uint8(NoisedImage2.*rate);
       Image(find(Image>2000))=2000;
       Image=double(Image);
       Image=uint8(Image.*rate);
       Image_to_write(:,:,1)=[NoisedImage2,Image];
       Image_to_write(:,:,2)=[NoisedImage2,Image];
       Image_to_write(:,:,3)=[NoisedImage2,Image];

       RMSE1=RMSE1+immse(NoisedImage, Original_Image);
       %dicomwrite(NoisedImage,[NoisedDicom,sprintf('%06d',j),'.dcm'],info);
       dicomwrite(NoisedImage,[CGANlowDicom,sprintf('%06d',count),'.dcm'],info);
       imwrite(Image_to_write,[CGANlowTest,sprintf('%06d',count),'.jpg']);
       count=count+1;
       %imwrite(Image,[StandardImage,'\',sprintf('%06d',j),'.jpg']);
       %imwrite(NoisedImage2,[NoisedFile,'\',sprintf('%06d',j),'.jpg']);
    end
    RMSE1=RMSE1/size(File4,1);
end