%% Automated Parking Valet in Simulink 
% This example shows how to construct an automated parking valet system in
% Simulink(R) with Automated Driving Toolbox(TM). It closely follows the
% <docid:driving_ug#mw_a648d83c-5fe4-4459-9978-5e4d0ea396e5 Automated
% Parking Valet> MATLAB(R) example.
%
% Copyright 2017-2019 The MathWorks, Inc.

%% Introduction
% Automatically parking a car that is left in front of a parking lot is a
% challenging problem. The vehicle's automated systems are expected to take
% over and steer the vehicle to an available parking spot. This example
% focuses on planning a feasible path through the environment, generating a
% trajectory from this path, and using a feasible controller to execute the
% trajectory. Map creation and dynamic obstacle avoidance are excluded from
% this example.

%% 
% Before simulation, the
% |<matlab:openExample('driving/AutomatedParkingValetSimulinkExample','supportingFile','helperSLCreateCostmap.m')
% helperSLCreateCostmap>| function is called within the |PreLoadFcn| callback 
% function of the model. For details on using callback functions,
% see <docid:simulink_ug#btp1paz Model Callbacks>. The
% |helperSLCreateCostmap| function creates a static map of the parking lot
% that contains information about stationary obstacles, road markings, and
% parked cars. The map is represented as a
% |<docid:driving_ref#mw_b3dc1e85-22ec-48ee-85ae-ec370da8d0b4 vehicleCostmap>| object.
%
% To use the |<docid:driving_ref#mw_b3dc1e85-22ec-48ee-85ae-ec370da8d0b4
% vehicleCostmap>| object in Simulink(R), the
% |<matlab:openExample('driving/AutomatedParkingValetSimulinkExample','supportingFile','helperSLCreateUtilityStruct.m')
% helperSLCreateUtilityStruct>| function converts the
% |<docid:driving_ref#mw_b3dc1e85-22ec-48ee-85ae-ec370da8d0b4
% vehicleCostmap>| into a struct array in the block's mask initialization.
% For more details, see <docid:simulink_ug#btlg32q-1 Initialize Mask>.
costmap = helperSLCreateCostmap();
h = figure;
plot(costmap, 'Inflation', 'off')
legend off

%% 
% The global route plan is described as a sequence of lane segments to
% traverse to reach a parking spot. Before simulation, the |PreLoadFcn|
% callback function of the model loads a route plan, which is stored as a
% table. The table specifies the start and end poses of the segment, as
% well as properties of the segment, such as the speed limit.
data      = load('routePlanSL.mat');
routePlan = data.routePlan %#ok<NOPTS>

hold on
currentPose = [4 12 0]; % [x, y, theta]
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
%%
% The inputs and outputs of many blocks in this example are Simulink buses
% (|<docid:simulink_ref#bvh6_eb-1 Simulink.Bus>| classes). In
% the |PreLoadFcn| callback function of the model, the
% |<matlab:openExample('driving/AutomatedParkingValetSimulinkExample','supportingFile','helperSLCreateUtilityBus.m')
% helperSLCreateUtilityBus>| function creates these buses.

%% 
open_system('AutomatedParkingValet');
set_param('AutomatedParkingValet','SimulationCommand','Update');
%%
% Planning is a hierarchical process, with each successive layer responsible 
% for a more fine-grained task. The behavior layer [1] sits at the top of 
% this stack. The *Behavior Planner* block triggers a sequence of navigation  
% tasks based on the global route plan by providing an intermediate goal and 
% configuration for the *Motion Planning* and *Trajectory Generation* blocks. 
% Each path segment is navigated using these steps:
%
% # *Motion Planning*: Plan a feasible path through the environment map
% using the optimal rapidly exploring random tree (RRT*) algorithm
% (|<docid:driving_ref#mw_3e6efb93-e83e-4c4b-9e7b-0bebb1c1179c
% pathPlannerRRT>|).
% # *Trajectory Generation*: Smooth the reference path by fitting splines
% [2] to it using the
% <docid:driving_ref#mw_cb1a0173-cd06-4470-8d19-22363a73bd38 Path Smoother
% Spline> block. Then convert the smoothed path into a trajectory by
% generating a speed profile using the <docid:driving_ref#mw_cc6417b7-a690-4ff9-a962-ba0cd1faff81 Velocity Profiler> block.
% # *Vehicle Control*: The
% |<matlab:openExample('driving/AutomatedParkingValetSimulinkExample','supportingFile','HelperPathAnalyzer.m')
% HelperPathAnalyzer>| provides the reference signal for the Vehicle Controller
% subsystem that controls the steering and the velocity of the vehicle.
% # *Goal Checking*: Check if the vehicle has reached the final pose of the
% segment using |<matlab:openExample('driving/AutomatedParkingValetSimulinkExample','supportingFile','helperGoalChecker.m')
% helperGoalChecker>|.

%% Explore the Subsystems
% The Vehicle Controller subsystem contains a
% <docid:driving_ref#mw_c24d94d4-eda0-4afc-a933-ae8ccad7c525 Lateral
% Controller Stanley> block and a
% <docid:driving_ref#mw_96bd4718-f217-425b-93c1-4989f270f415 Longitudinal
% Controller Stanley> block to regulate the pose and the velocity of the
% vehicle, respectively. To handle realistic vehicle dynamics [3], the
% *Vehicle model* parameter in the Lateral Controller Stanley block is set
% to |Dynamic bicycle model|. With this configuration, additional inputs,
% such as the path curvature, the current yaw rate of the vehicle, and the
% current steering angle are required to compute the steering command. The
% Longitudinal Controller Stanley block uses a switching
% Proportional-Integral controller to calculate the acceleration and the
% deceleration commands that actuate the brake and throttle in the vehicle.
% 
%%
open_system('AutomatedParkingValet/Vehicle Controller');
%%
% To demonstrate the performance, the vehicle controller is applied to the
% Vehicle Model block, which contains a simplified steering system [3] that
% is modeled as a first-order system and a
% <docid:vdynblks_ref#mw_663703c2-aa89-4eac-b073-421cdc5818bc Vehicle Body
% 3DOF> block shared between Automated Driving Toolbox(TM) and Vehicle
% Dynamics Blockset(TM). Compared with the kinematic bicycle model used in
% the <docid:driving_ug#mw_a648d83c-5fe4-4459-9978-5e4d0ea396e5
% Automated Parking Valet> MATLAB(R) example, this Vehicle Model block is
% more accurate because it considers the inertial effects, such as tire
% slip and steering servo actuation.
%%
open_system('AutomatedParkingValet/Vehicle Model');
%% Simulation Results
% The Visualization block shows how the vehicle tracks the reference
% path. It also displays vehicle speed and steering command in a scope. 
% The following images are the simulation results for this example:
%%
sim('AutomatedParkingValet')
snapnow
close 'Automated Parking Valet'
%%
% Simulation stops at about 45 seconds, which is when the vehicle reaches 
% the destination.
%%
scope = 'AutomatedParkingValet/Visualization/Commands';
open_system(scope);
snapnow
close_system(scope);
%%
bdclose all;
%% Conclusions
% This example shows how to implement an automated parking valet in Simulink.

%% References
% [1] Buehler, Martin, Karl Iagnemma, and Sanjiv Singh. _The DARPA Urban
%     Challenge: Autonomous Vehicles in City Traffic_ (1st ed.).
%     Springer Publishing Company, Incorporated, 2009.
%
% [2] Lepetic, Marko, Gregor Klancar, Igor Skrjanc, Drago Matko, and Bostjan
%     Potocnik, "Time Optimal Path Planning Considering Acceleration
%     Limits." _Robotics and Autonomous Systems_, Volume 45, Issues 3-4,
%     2003, pp. 199-210.
%
% [3] Hoffmann, Gabriel M., Claire J. Tomlin, Michael Montemerlo, and 
%     Sebastian Thrun. "Autonomous Automobile Trajectory Tracking for 
%     Off-Road Driving: Controller Design, Experimental Validation and 
%     Racing." _American Control Conference_, 2007, pp. 2296-2301.
