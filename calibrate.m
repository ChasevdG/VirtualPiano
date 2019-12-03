function [im_piano] = calibrate()
global im_raw;
global init_crop;
global cam;
global pTL;
global pTR;
global pBL;
global pBR;
global im_warp;
global im_rotated;
global x_left;


cont = 'n';

while(cont == 'n')
    
    % Image acquisition and preprocessing
    im_raw = snapshot(cam);
    init_crop = rgb2hsv(imcrop(im_raw,[1 120 640 139]));
    
%     im_raw = imread('image.png');

    subplot(2,1,1);
    imshow(im_raw);
    title('Raw Image');
    hold on;
    rectangle('Position',[1 120 639 139],'EdgeColor','r');
    hold off;
    im = imcrop(im_raw,[1 120 640 139]);     % Arbitrary frame to look at
    im = rgb2gray(im);
    im = adapthisteq(im);

    % Hough Transformation
    [line_top,line_bot] = HoughTrans(im); % Homemade function btw
    
    
    % Calculate angle of piano -> for rotation
    pTL = line_top(1).point1;
    pTR = line_top(end).point2;
    pBL = line_bot(1).point1;
    pBR = line_bot(end).point2;
    pBL(2) = pBL(2) + 50;
    pBR(2) = pBR(2) + 50;
    
    theta_top = atand((pTR(2)-pTL(2))/(pTR(1)-pTL(1)));
    theta_bot = atand((pBR(2)-pBL(2))/(pBR(1)-pBL(1)));
    theta = mean([theta_top,theta_bot]);
    
    
    % Crop and Rotate Image
    im_cropped = imcrop(im,[1,(min([pTL(2),pTR(2)])-1),640,abs(max([pBL(2),pBR(2)])-min([pTL(2),pTR(2)])+1)]);
%     im_rotated = imrotate(im_cropped,(180),'crop');
    im_rotated = imrotate(im_cropped,(180+theta),'crop');


    % Warp Image so that it is rectangular
    % https://au.mathworks.com/help/images/matrix-representation-of-geometric-transformations.html
    % Combination of tilt, shear, and scale transforms
    tform = projective2d([1 0 0
                          -0.88 2 -0.0028 
                          0 0 1]);
    im_warp = imwarp(im_rotated,tform);
    im_warp = im_warp(:,98:(end-100));

    % Detecting Harris Features
    points = detectHarrisFeatures(im_warp);

    % Find the 2 sides of the piano
    points_left = detectHarrisFeatures(im_warp(:,1:(length(im_warp)/2)));
    points_right = detectHarrisFeatures(im_warp(:,(length(im_warp)/2+1):end));
    x_bin_size = 700;             %% Can change the scan length if desired
    count_left = 0;
    x_left = 0;
    count_right = 0;
    x_right = 0;
    
    % Go through points on left half of warped image
    for i = 1:points_left.Count
        x_pos1 = points_left.Location(i,1);     % Start x value
        x_pos2 = x_pos1 + x_bin_size;           % End x value
        temp = 0;
        
        % Count number of points in chosen area
        for j = 1:points_left.Count
            if ((points_left.Location(j,1) >= x_pos1) && (points_left.Location(j,1) <= x_pos2))
                temp = temp + 1;
            end
        end
        
        % Store area with highest number of points - this will correspond
        % to the left side of the piano
        if (temp > count_left)
            count_left = temp;
            x_left = x_pos1;
        end
    end
    
    % Go through points on right half of warped image
    for i = points_right.Count:-1:1
        x_pos1 = points_right.Location(i,1);    % Start x value
        x_pos2 = x_pos1 - x_bin_size;           % End x value
        temp = 0;
        
        % Count number of points in chosen area
        for j = 1:points_right.Count
            if ((points_right.Location(j,1) <= x_pos1) && (points_right.Location(j,1) >= x_pos2))
                temp = temp + 1;
            end
        end
        
        % Store area with highest number of points - this will correspond
        % to the right side of the piano
        if (temp > count_right)
            count_right = temp;
            x_right = x_pos1 + (length(im_warp)/2);
        end
    end
    
    im_piano = im_warp(:,x_left:x_right);
    se = strel('rectangle',[8,1]);
    im_piano = imerode(im_piano,se);
    subplot(2,1,2);
    imshow(im_piano);
    title('Cropped Out Piano');
%     points = detectHarrisFeatures(im_piano,'MinQuality',0.03);
%     hold on;
%     plot(points.Location(:,1),points.Location(:,2),'ro');
%     hold off;

    clc;
    cont = input('Is this the piano? (y/n)   ','s');
    if (cont ~= 'n' && cont ~= 'y'), cont = 'n'; end
    
end