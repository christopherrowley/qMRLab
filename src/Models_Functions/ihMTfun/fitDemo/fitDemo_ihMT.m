%% Settings

clc;
testData  = load('ihMTfun/fitDemo/ihMTdata_demo.mat');      % load demo data
Prot = load('ihMTfun/fitDemo/DemoProtocol.mat');     % load default protocol
fitValues = load('fitValues.mat');
MTparams = Prot.obj.Prot.MTw_dual.Mat;
PDparams = Prot.obj.Prot.PDw.Mat;
T1params = Prot.obj.Prot.T1w.Mat;

%% Fit demo

[M0b_app_dual,~,~,~]=sampleCode_calc_M0bappVsR1_1dataset(testData.ihMTdata_demo,MTparams,PDparams,T1params,fitValues,Prot.obj);
