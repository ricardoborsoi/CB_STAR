%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: 
%           GSA fuses the upsampled HyperSpectral (HS) and PANchromatic (PAN) images by 
%           exploiting the Gram-Schmidt Adaptive (GSA) algorithm.
% 
% Interface:
%           I_Fus_GSA = GSA(HS,PAN,posi)
%
% Inputs:
%           HS:         HS image;
%           PAN:        PAN image.
%
% Outputs:
%           I_Fus_GSA:  GSA pasharpened image.
% 
% References:
%           [Aiazzi07]   B. Aiazzi, S. Baronti, and M. Selva, �Improving component substitution Pansharpening through multivariate regression of MS+Pan
%                        data,?IEEE Transactions on Geoscience and Remote Sensing, vol. 45, no. 10, pp. 3230?239, October 2007.
%           [Vivone14]   G. Vivone, L. Alparone, J. Chanussot, M. Dalla Mura, A. Garzelli, G. Licciardi, R. Restaino, and L. Wald, �A Critical Comparison Among Pansharpening Algorithms? 
%                        IEEE Transaction on Geoscience and Remote Sensing, 2014. (Accepted)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function I_Fus_GSA = GSA(HS,PAN,posi)

imageHR = double(PAN);
imageLR_LP = double(HS);

%%%%%%%% Upsampling
ratio1 = size(PAN,1)/size(HS,1);

%imageLR = interp23tapGeneral(imageLR_LP,ratio1,posi);
imageLR = upsampling(imageLR_LP,ratio1);

%%% Remove means from imageLR
imageLR0 = zeros(size(imageLR));
for ii = 1 : size(imageLR,3), imageLR0(:,:,ii) = imageLR(:,:,ii) - mean2(imageLR(:,:,ii)); end

%%% Remove means from imageLR_LP
imageLR_LP0 = zeros(size(HS));
for ii = 1 : size(HS,3), imageLR_LP0(:,:,ii) = imageLR_LP(:,:,ii) - mean2(imageLR_LP(:,:,ii)); end

%%% Sintetic intensity
imageHR0 = imageHR - mean2(imageHR);
imageHR0 = imresize(imageHR0,size(HS(:,:,1)));
alpha(1,1,:) = estimation_alpha(cat(3,imageLR_LP0,ones(size(HS,1),size(HS,2))),imageHR0,'global');
I = sum(cat(3,imageLR0,ones(size(imageLR,1),size(imageLR,2))) .* repmat(alpha,[size(imageLR,1) size(imageLR,2) 1]),3); 

%%% Remove mean from I
I0 = I - mean2(I);

%%% Coefficients
g = ones(1,1,size(imageLR,3)+1);
for ii = 1 : size(imageLR,3)
    h = imageLR0(:,:,ii);
    c = cov(I0(:),h(:));
    g(1,1,ii+1) = c(1,2)/var(I0(:));
end

imageHR = imageHR - mean2(imageHR);

%%% Detail Extraction
delta = imageHR - I0;
deltam = repmat(delta(:),[1 size(imageLR,3)+1]);

%%% Fusion
V = I0(:);
for ii = 1 : size(imageLR,3)
    h = imageLR0(:,:,ii);
    V = cat(2,V,h(:));
end

gm = zeros(size(V));
for ii = 1 : size(g,3)
    gm(:,ii) = squeeze(g(1,1,ii)) .* ones(size(imageLR,1).*size(imageLR,2),1);
end

V_hat = V + deltam .* gm;

%%% Reshape fusion result
I_Fus_GSA = reshape(V_hat(:,2:end),[size(imageLR,1) size(imageLR,2) size(imageLR,3)]);

% Final Mean Equalization
for ii = 1 : size(imageLR,3)
    h = I_Fus_GSA(:,:,ii);
    I_Fus_GSA(:,:,ii) = h - mean2(h) + mean2(imageLR(:,:,ii));
end

end