function [L, R] = gen_dice(I_l, I_r, indicator, show_plot)

% Generate DiCE images with enhanced contrast 
% 
% Inputs
% I_l: input left-image of range [0,1] in gamma-corrected space 
% I_r: input right-image of range [0,1] in gamma-corrected space 
% indicator: target ratio of contrast
% show_plot: if true plot the tone-curves
% 
% Outputs
% L, R: images processed by DiCE

I_l_in = I_l;
I_r_in = I_r;

% convert to linear space
gamma=2.2;
I_l_in=I_l_in.^gamma;
I_r_in=I_r_in.^gamma;

I_l_in=max(10.^-2.7,I_l_in);
I_r_in=max(10.^-2.7,I_r_in);

% convert to log space
L_l_in=log10(compute_luminance(I_l_in));
L_r_in=log10(compute_luminance(I_r_in));

I_min = min(min(L_l_in(:)),min(L_r_in(:)));
I_max = max(max(L_l_in(:)),max(L_r_in(:)));

% compute the maximum difference of DiCE tone-curves from the base
% tone-curve (identity map).
dev = 1.35*(1-indicator)/(1+indicator);

% process images with interleaved tone-curves in the logarithmic domain
segs = 2; % number of linear segments
L_l_out=L_l_in + interleave(-2.7, 0, L_l_in, segs, dev);
L_r_out=L_r_in - interleave(-2.7, 0, L_r_in, segs, dev);

% plot DiCE interleaved tone-curves
if show_plot
    plot(sort(L_l_in(:)),sort(L_l_in(:))+interleave(I_min, I_max, sort(L_l_in(:)), segs, dev));
    hold on;
    plot(sort(L_l_in(:)),sort(L_l_in(:))-interleave(I_min, I_max, sort(L_l_in(:)), segs, dev));
end

% colour transfer
log_rgb_l = L_l_out+log10(I_l_in)-L_l_in;
log_rgb_r = L_r_out+log10(I_r_in)-L_r_in;

% convert back to gamma-corrected space 
L = (10.^log_rgb_l).^(1/gamma);
R = (10.^log_rgb_r).^(1/gamma);

end


function Y = compute_luminance( img )
% Return 2D matrix of luminance values for 3D matrix with an RGB image

dims = find(size(img)>1,1,'last');

if( dims == 3 )
    Y = img(:,:,1) * 0.212656 + img(:,:,2) * 0.715158 + img(:,:,3) * 0.072186;
elseif( dims == 1 || dims == 2 )
    Y = img;
else
    error( 'compute_luminance: wrong matrix dimension' );
end

end

function [l] = interleave(l_min, l_max, x, segs, dev)
% Generate smooth interleaved tone-curves

grids = segs + 1;
s_l = zeros(1,grids); 

r_l = 0;
for ll=1:grids
    if (ll==1)
        r_l = 0;
    elseif( mod(ll,4) == 1 || mod(ll,4) == 2 )
        r_l = r_l+dev;
    else
        r_l = r_l-dev;
    end
    s_l(ll) = r_l;
end

disconti = (l_min + l_max) / 2;
interval = 0.05;
pt = interp1(linspace(l_min, l_max, grids), s_l, disconti - interval);
spline_l = spline([disconti - interval, disconti, disconti + interval], [pt dev-0.5*(dev-pt) pt]);

l = ones(size(x));

l(~isConti(x,disconti,interval)) = ppval(spline_l, x(~isConti(x,disconti,interval)));
l(isConti(x,disconti,interval)) = interp1(linspace(l_min, l_max, grids), s_l, clamp(x(isConti(x,disconti,interval)), l_min, l_max));

end

function res = isConti(x, disconti, interval)

res = x<disconti-interval | x>disconti+interval;

end

function Y = clamp( X, min, max )
  Y = X;
  Y(X<min) = min;
  Y(X>max) = max;
end
