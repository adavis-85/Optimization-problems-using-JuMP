
Pkg.add("JuMP")
Pkg.add("GLPK")
using JuMP
using GLPK

##From ch. 15 AMPL book.  Task assignment through ratings.

M=Model(with_optimizer(GLPK.Optimizer)

people=["allen","black","chung","clark","conners","cumming",
        "demming","eng","farmer","forest","godman","harris","holmes",
        "johnson","knorr","manheim","morris","nathan",
        "neuman","patrick","rollins","schuman","silver",
        "stein","stock","truman","wolman","young"]
    
projects=["a","ed","ez","g","h1","h2","rb","sc"]

##These are the projects rated by each person on a 1-7 scale of which they would
##like to do most.
 abilities=[1 3 4 7 7 5 2 6;
            6 4 2 5 5 7 1 3;
            6 2 3 1 1 7 5 4;
            7 6 1 2 2 3 5 4;
            7 6 1 3 3 4 5 2;
            6 7 4 2 2 1 3 7;
            2 5 4 6 6 1 3 7;
            4 7 2 1 1 6 3 5;
            7 6 5 2 2 1 3 4;
            6 7 2 5 5 1 3 4;
            7 6 2 4 4 5 1 3;
            4 7 5 3 3 1 2 6;
            6 7 4 3 3 3 5 1;
            7 2 4 6 6 5 3 1;
            7 4 1 2 2 5 6 3;
            4 7 2 1 1 3 6 5;
            7 5 4 6 6 3 1 2;
            4 7 5 6 6 3 1 2;
            7 5 4 6 6 3 1 2;
            1 7 5 4 4 2 3 6;
            6 2 3 1 1 7 5 4;
            4 7 3 5 5 1 2 6;
            4 7 3 1 1 2 5 6;
            6 4 2 5 5 7 1 3;
            5 2 1 6 6 7 4 3;
            6 3 2 7 7 5 1 4;
            6 7 4 2 2 3 5 1;
            1 3 4 7 7 6 2 5]

##Container to make indexing the tasks by the people according to each project.
Rank=Containers.DenseAxisArray(abilities,people,projects)

##Each project must have between three to four members.
Group=Containers.DenseAxisArray([3;4],["min","max"])
    
##Which project each person will get assigned to.
@variable(M,0<=Assign[people,projects])
    
##The amount of people assigned to each group has boundaries set.
@constraint(M,[j in projects],Group["min"]<=sum(Assign[i,j] for i  in people)<=Group["max"]) 
    
##Each person needs to be assigned to one project.
@constraint(M,[i in people],sum(Assign[i,j] for j in projects)==1)
    
##Finding the project for each person with the highest rating possible while
##meeting all the constraints.
@objective(M,Min,sum(Rank[i,j]*Assign[i,j] for i in people,j in projects))

optimize!(M)
    
value.(Assign)

##People who have a car.
cars=["chung","demming","eng","holmes","manheim","morris","nathan","patrick","rollins","young"]

##Some projects require a car to get to.  
cars_req=[1;0;0;2;2;2;1;1]
    
##Container to index cars by projects.
Req_cars=Containers.DenseAxisArray(cars_req,projects)

##The number of people assigned to each project also needs to have the people who own cars
##in it while maintaining that the best rating possible can be assigned.
@constraint(M,[j in projects],sum(Assign[i,j] for i in people if i in cars)==Req_cars[j])
                    
optimize!(M)
                    
value.(Assign)
