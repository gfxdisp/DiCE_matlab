% input images of range [0,1] in gamma-corrected space 
I_l = double(imread('church.png'))/255;
I_r = double(imread('church.png'))/255;
indicator = 0.63; % ratio of contrast
show_plot = true; % plot the tone-curves
[L, R] = gen_dice(I_l, I_r, indicator, show_plot);
imwrite(L, 'L.png');
imwrite(R, 'R.png');