function[] = find_key(x_key,y_key)
global keyim;
global time;
global frequency;

im = keyim;
if (x_key < size(im,2)) && (y_key < size(im,1)) 
    key = (im(y_key, x_key)-108)/6;
    f = frequency(key+1);
    y = sin(2*pi()*f*time);%./(0.00001*x.*x+1); 
    sound(y,1000)
end
pause(0.3);