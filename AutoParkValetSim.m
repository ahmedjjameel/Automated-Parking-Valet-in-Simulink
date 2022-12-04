%% Automated Parking Valet in Simulink 
% This example shows how to construct an automated parking valet system in
% Simulink(R) with Automated Driving Toolbox(TM).

clear; close all; clc;

costmap = helperSLCreateCostmap();
h = figure;
plot(costmap, 'Inflation', 'off')
legend off

%% The global route plan is described as a sequence of lane segments to
% traverse to reach a parking spot.

data      = load('routePlanSL.mat');
routePlan = data.routePlan      %#ok<NOPTS>

hold on
currentPose = [4 12 0];         % [x, y, theta]
vehicleDims = costmap.CollisionChecker.VehicleDimensions;
helperPlotVehicle(currentPose, vehicleDims, 'DisplayName', 'Current Pose')
legend('Location', 'northwest');

for n = 1 : height(routePlan)
    % Extract the goal waypoint
    vehiclePose = routePlan{n, 'EndPose'};
    
    % Plot the pose
    legendEntry = sprintf('Goal %i', n);
    helperPlotVehicle(vehiclePose, vehicleDims, 'DisplayName', legendEntry);
end
hold off
snapnow
close(h);

%% The inputs and outputs of many blocks in this example are Simulink buses
 
open_system('AutomatedParkingValet');
set_param('AutomatedParkingValet','SimulationCommand','Update');

%% Explore the Subsystems

%open_system('AutomatedParkingValet/Vehicle Controller');

%open_system('AutomatedParkingValet/Vehicle Model');

%% Simulation Results
% The Visualization block shows how the vehicle tracks the reference
% path. It also displays vehicle speed and steering command in a scope. 
% The following images are the simulation results for this example:
%%
sim('AutomatedParkingValet')
snapnow
%close 'Automated Parking Valet'

%% Simulation stops at about 45 seconds, which is when the vehicle reaches 
% the destination.

% scope = 'AutomatedParkingValet/Visualization/Commands';
% open_system(scope);
% snapnow
% close_system(scope);
%%
%%bdclose all;
%% Conclusions
% This example shows how to implement an automated parking valet in Simulink.
