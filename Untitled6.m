clear;
clf;
clc;
cam = webcam;
setGlobalx()

%% Calibration

im_piano = calibrate();

while 1
    im = snapshot(cam);
    [x,y] = fingerLoc(im);
    [x_key, y_key] = transform(x,y);
    find_key(x_key,ykey);
end
