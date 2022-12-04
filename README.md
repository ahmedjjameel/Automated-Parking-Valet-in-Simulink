### Automated Parking Valet in Simulink

This example shows how to construct an automated parking valet system in Simulink® with Automated Driving Toolbox™.

### Introduction
Automatically parking a car that is left in front of a parking lot is a challenging problem. The vehicle's automated systems are expected to take over and steer the vehicle to an available parking spot. This example focuses on planning a feasible path through the environment, generating a trajectory from this path, and using a feasible controller to execute the trajectory. Map creation and dynamic obstacle avoidance are excluded from this example.

The global route plan is described as a sequence of lane segments to traverse to reach a parking spot. Before simulation, the PreLoadFcn callback function of the model loads a route plan, which is stored as a table. The table specifies the start and end poses of the segment, as well as properties of the segment, such as the speed limit.

routePlan =

  5×3 table

       StartPose              EndPose           Attributes
    ________________    ____________________    __________

     4     12      0      56      11       0    1×1 struct
    56     11      0      70      19      90    1×1 struct
    70     19     90      70      32      90    1×1 struct
    70     32     90      52      38     180    1×1 struct
    53     38    180    36.3      44      90    1×1 struct

Planning is a hierarchical process, with each successive layer responsible for a more fine-grained task. The behavior layer [1] sits at the top of this stack. The Behavior Planner block triggers a sequence of navigation tasks based on the global route plan by providing an intermediate goal and configuration for the Motion Planning and Trajectory Generation blocks. Each path segment is navigated using these steps:

Motion Planning: Plan a feasible path through the environment map using the optimal rapidly exploring random tree (RRT*) algorithm (pathPlannerRRT).

Trajectory Generation: Smooth the reference path by fitting splines [2] to it using the Path Smoother Spline block. Then convert the smoothed path into a trajectory by generating a speed profile using the Velocity Profiler block.

Vehicle Control: The HelperPathAnalyzer provides the reference signal for the Vehicle Controller subsystem that controls the steering and the velocity of the vehicle.

Goal Checking: Check if the vehicle has reached the final pose of the segment using helperGoalChecker.




### Simulation Results
The Visualization block shows how the vehicle tracks the reference path. It also displays vehicle speed and steering command in a scope. The following images are the simulation results for this example:

![Media1](https://user-images.githubusercontent.com/81799459/205506192-b3e2acb4-4405-41d0-9960-d9cbb668df93.gif)


Simulation stops at about 45 seconds, which is when the vehicle reaches the destination.

