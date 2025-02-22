%% Test script for ihMT_fit_M0b_v2.m 

B1_ref = 0.9520; % disp value 

msat = 0.0342; % disp value 

flipA = 6; 
TR = 100;
DummyEcho = 2; 
echoSpacing = 7.66; 
numExcitation = 10;

%fitValues_dual = load('/Users/amiedemmans/Documents/ihMT_Tests/Test4/fitValues_D.mat');
fitValues_dual = load('/Users/reson/Documents/ihMT/ihMT_Tests/Test4/fitValues_D.mat');
fitValues_dual = fitValues_dual.fitValues;
fitValues_single = load('/Users/reson/Documents/ihMT/ihMT_Tests/Test4/fitValues_S.mat');
fitValues_single = fitValues_single.fitValues;

[~, dual] = minc_read('dual_reg.mnc'); 
[~, T1_map] = minc_read('T1map.mnc');
[~, S0_map] = minc_read('M0map.mnc'); 
[~, mask] = minc_read('mask.mnc'); 
[~, b1] = minc_read('b1.mnc');
[~, pos] = minc_read('pos_reg.mnc');
[~, neg] = minc_read('neg_reg.mnc');

tempMask = mask;
tempMask(T1_map > 2500) = 0;
tempMask(T1_map < 650) = 0;
tempMask(isnan(T1_map)) = 0;

Raobs = (1./T1_map) *1000; 
Raobs(isinf(Raobs)) = 0;  


sat_dual = ihMT_calcMTsatThruLookupTablewithDummyV3( dual, B1_ref, T1_map, tempMask,S0_map, echoSpacing, numExcitation, TR, flipA, DummyEcho);
M0b_dual = zeros(size(sat_dual));
tic %  ~ 2hrs to run 
for i = 80 % went to 149
    
    for j = 1:size(sat_dual,2) %j = axialStart:axialStop  % % for axial slices
        for k =  1:size(sat_dual,3) % sagital slices  65
            
            if tempMask(i,j,k) > 0 %&& dual_s(i,j,k,3) > 0
                                
                 [M0b_dual(i,j,k), ~]  = ihMT_fit_M0b_v2( B1_ref(i,j,k), Raobs(i,j,k), sat_dual(i,j,k), fitValues);
                % [M0b_pos(i,j,k),  ~]  = ihMT_fit_M0b_v2( b1(i,j,k), R1_s(i,j,k), sat_pos(i,j,k), fitValues_single);               
                % [M0b_neg(i,j,k),  ~]  = ihMT_fit_M0b_v2( b1(i,j,k), R1_s(i,j,k), sat_neg(i,j,k), fitValues_single);
                 
            end
        end
    end
    disp(i/size(sat_dual,1) *100)
    toc 
end
figure; imshow3Dfull(M0b_dual, [0,0.25]);
x = 127;
y = 86; 
z = 96;



B1_ref = B1_ref(z, y, x);   % A single scalar value
Raobs = Raobs(z, y, x); % A single scalar value
msat = sat_dual(z, y, x); % A single scalar value




% i = 1:size(sat_dual, 1);
% j = 1:size(sat_dual,2); 
% k = 1:size(sat_dual, 3);


% i = 126:129;
% j = 126:129; 
% k = 126:129;


%i = 64; j = 66; k = 46;

% B1_ref = B1_ref(i, j, k); 
% msat = sat_dual(i, j, k);
% Raobs = Raobs(i,j,k);

fit_eqn = fitValues.fit_SS_eqn;
% fit_eqn = sprintf(fit_eqn, repmat(Raobs, fitValues.numTerms,1));

% Initialize degrees
B1_degree = 0;
Raobs_degree = 0;

% Extract powers from fit_eqn
B1_powers = regexp(fit_eqn, 'b1\.\^(\d+)', 'tokens');
Raobs_powers = regexp(fit_eqn, 'Raobs\.\^(\d+)', 'tokens');

% Extract constant from fit_eqn 
constants =  regexp(fit_eqn, '[\+\-]?\d+\.\d+', 'match');
constants = str2double(constants); 

if ~isempty(B1_powers)
    B1_degree = (cellfun(@(x) str2double(x), [B1_powers{:}]));
end
if ~isempty(Raobs_powers)
    Raobs_degree = (cellfun(@(x) str2double(x), [Raobs_powers{:}]));
end 

V = zeros(1, 3); 
for j = 1:90
    
        % The terms of the model will correspond to powers of B1, and Raobs
        Value =  constants(j) * (B1_ref.^(B1_degree(j))) .* (Raobs.^(Raobs_degree(j)));
        if j<31
            V(3) = V(3)+Value;
        elseif j>=31 && j<61
            V(2) = V(2)+Value;
        else 
            V(1) = V(1)+Value;
        end 

end
V(3) = V(3)-msat;
fitV = roots(V);


fitV(fitV<0) = NaN;
[~,temp] = min(abs(fitV-0.1));
M0b = fitV(temp);
if isnan(M0b)
    M0b = 0; 
end 




% Construct vandermonde matrix for matrix division with constants: 
V = zeros(length(B1_ref), fitValues.numTerms); 
idx = 1;
for j = 0:B1_degree
    for k = 0:Raobs_degree
        % The terms of the model will correspond to powers of B1, and Raobs
        V(:, idx) =  constants(idx) .* (B1_ref.^(j)) .* (Raobs.^(k));
        idx = idx+1;
    end
end

% Vandermonde without constants
V = zeros(length(B1_ref), fitValues.numTerms); 
idx = 1;
for j = 0:B1_degree
    for k = 0:Raobs_degree
        % The terms of the model will correspond to powers of B1, and Raobs
        V(:, idx) =  (B1_ref.^(j)) .* (Raobs.^(k));
        idx = idx+1;
    end
end

try
    fitvals = V \ msat; 
    M0b = fitvals(1);
catch
    disp('An error occurred during matrix division:');
    disp('B1_ref:');
    disp(B1_ref);
    disp('msat values:');
    disp(msat);
    disp('Raobs');
    disp(Raobs);
    disp('Matrix V:');
    disp(V);
    return;
end  






% fit_eqn = fitValues.fit_SS_eqn_sprintf;
% fit_eqn = sprintf(fit_eqn, repmat(Raobs, fitValues.numTerms,1));
% 
% % Use matrix division: 
% X = zeros(length(msat), fitValues.numTerms); 
% 
% for i = 1:fitValues.numTerms
%     X(:, i) = B1_ref.^i;
% end 
% 
% try
%     fitvals = X \ msat; 
%     M0b = fitvals(1);
% catch
%     disp('An error occurred during matrix division:');
%     disp('B1_ref:');
%     disp(B1_ref);
%     disp('msat values:');
%     disp(msat);
%     disp('Fit Equation (post sprintf):');
%     disp(fit_eqn);
%     disp('Matrix X:');
%     disp(X);
%     return;
% end
% 
% 
% V = bsxfun(@power, B1_ref(:), 0:(fitValues.numTerms - 1));
% 
% % Fit options for least squares --> linear least squares also doesnt work 
% opts = fitoptions('Method', 'LinearLeastSquares', 'Upper', 0.5, 'Lower', 0.0);
% opts.Robust = 'Bisquare';
% 
% % Define the fit model using the Vandermonde matrix
% myfittype = fittype('V * M0b', 'dependent', {'z'}, 'independent', {'b1'}, 'coefficients', {'M0b'});
% fitpos = fit(V, msat(:), myfittype, opts);
% fitvals = coeffvalues(fitpos);
% 
% % Extract the M0b coefficient
% M0b = fitvals(1);





% Previous version 
% opts = fitoptions( 'Method', 'NonlinearLeastSquares','Upper',0.5,'Lower',0.0,'StartPoint',0.1);
% opts.Robust = 'Bisquare';
% 
% myfittype = fittype( fit_eqn ,'dependent', {'z'}, 'independent',{'b1'},'coefficients', {'M0b'});
% 
% disp('B1_ref:');
% disp(B1_ref);
% disp('Size B1_ref: ');
% disp(size(B1_ref));
% disp('msat values:');
% disp(msat);
% disp('size msat: ');
% disp(size(msat));
% disp('Fit Equation (post sprintf):');
% disp(fit_eqn);
% disp('Fit Type:');
% disp(myfittype);
% disp('Fit Options:');
% disp(opts);
% 
% try
% fitpos = fit(B1_ref, msat, myfittype,opts);
% catch ME
%     % Display the error message
%     disp('An error occurred during fitting:');
%     disp(ME.message);
% 
%     % Optional: Display additional details about where the error occurred
%     disp('Error identifier:');
%     disp(ME.identifier);
% 
%     disp('Error stack trace:');
%     for k = 1:length(ME.stack)
%         disp(['In file: ', ME.stack(k).file]);
%         disp(['Function: ', ME.stack(k).name]);
%         disp(['Line: ', num2str(ME.stack(k).line)]);
%     end
% end





