function [finger_loc1,finger_loc2] = fingerLoc(im)
    global init_crop
    global se
    
    % Find new addition to the image
    
    im2 = rgb2hsv(im);
    
    dif = imabsdiff(im2,init_crop);
    im = uint8((dif(:,:,2)>.3)).*im;
    
    %Threshold green
    fingers = findFingerTips(im);
    
    %Group pixels
    fingers = imopen(fingers,se);
    fingers = imclose(fingers,se);
    
    
    %Find centers of objects with > 50 area
    
    region = regionprops(fingers,'Centroid','Area','BoundingBox');
    [x,y] = size(region);
    if x>0
        area = extractfield(region,'Area');
        n = length(area);
        cent = zeros(n,2); %Preallocate
        %bb = zeros(n,2); % bounding box
        
        %Extract centers
        for i = 1:x
            cent(i,:) = extractfield(region(i),'Centroid'); 
            %bb(i,:) = extractfield(region(i),'Centroid');
        end
        
        finger_loc = cent(area>50,:);
        finger_loc1 = finger_loc(:,1);
        finger_loc2 = finger_loc(:,2);
    else
        finger_loc1 = [];
        finger_loc2 = [];
    end
end
    