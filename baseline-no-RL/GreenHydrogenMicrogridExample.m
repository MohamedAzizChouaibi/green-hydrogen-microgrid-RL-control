%% Green Hydrogen Microgrid
% 
% This example shows a DC islanded microgrid that provides power to an 
% electrolyzer using a solar array and an energy storage system. You can 
% use this model to evaluate the operational characteristics of producing 
% green hydrogen over a 7-day period by power from a solar array, or from 
% a combination of a solar array and an energy storage system. The model 
% includes electrical, thermal liquid, and thermal gas domains.
% 

% Copyright 2021-2023 The MathWorks, Inc.

%% Model

open_system('GreenHydrogenMicrogrid')

set_param(find_system('GreenHydrogenMicrogrid','FindAll', 'on','type','annotation','Tag','ModelFeatures'),'Interpreter','off')

%% Simulation Results from Simscape Logging
%%
%
% The plot below shows the power of the electrolyzer, solar and storage 
% system, battery state of charge, and produced hydrogen.
%


GreenHydrogenMicrogridPlotResults;


%%

