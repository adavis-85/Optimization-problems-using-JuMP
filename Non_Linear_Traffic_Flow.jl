
Pkg.add("JuMP")
Pkg.add("Ipopt")

using JuMP
using GLPK
using Ipopt
#########################################################################################
##From Ch. 18 Non-Linear programs
##An example of both a shortest path algorithm and maximum flow through a network.

##The nodes that send the units through
from=["a","a","c","b","c"]

##The nodes that accept the units
to=["b","c","b","d","d"]

##Creating the Tuple for in this case roads for traffic to go through
r=Tuple{String,String}[]

##inputing each road
for i in 1:length(from)
    push!(r,(from[i],to[i]))
    end

##The capacity at each road
capacity=[10;30;10;30;10]

##The time that it takes to travel each road
Time=[5;1;2;1;5]

##The rate at which time travel increases on each road per each car
sensitivity=[.1;.9;.9;.9;.1]

Capacity=Containers.DenseAxisArray(capacity,r)

Sensitivity=Containers.DenseAxisArray(sensitivity,r)

Time=Containers.DenseAxisArray(Time,r)


m=Model(with_optimizer(Ipopt.Optimizer))

##The nodes which aren't an entrance or an exit
diff=["b","c"]

##Variable for the paths of each road
@variable(m,path[r]>=0)

##Each car sent to each node from the entrance must leave that node
@constraint(m,[d in diff],sum(path[(r[i])] for i in 1:length(to) if r[i][2]==d)
                ==sum(path[(r[j])] for j in 1:length(from) if r[j][1]==d))

##Set the shortest path to one
@constraint(m,sum(path[(r[i])] for i in 1:length(from) if r[i][1]=="a")==1)
                              
##Minimize the time that it takes to go from the entrance to the exit
@objective(m,Min,sum(Time[(r[i])]*path[(r[i])] for i in 1:5))
                                            
optimize!(m)

value.(path)
           
##Variable for the amount of traffic, set to at or equal to the capacity at each node
@variable(m,0<=Traffic[d=r]<=Capacity[d])
                                            
##The traffic at each node must leave that node
@constraint(m,[d in diff],sum(Traffic[(r[i])] for i in 1:length(to) if r[i][2]==d)==
                sum(Traffic[(r[j])] for j in 1:length(from) if r[j][1]==d))     
                                               
##Maximize the amount of total traffic that the network can take
@objective(m,Max,sum(Traffic[(r[i])] for i in 1:5))
                                                                        
optimize!(m)
    
value.(Traffic)    
                                                                        
####################################################################################
                            
##Cars per minute entering road
@variable(m,X[r]>=0)
                               
##Travel time per road
@variable(m,T[r])
                      
##The travel time function.  Creates a concave function from the data.
@NLconstraint(m,[d in 1:length(from)],T[(r[d])]==Time[(r[d])] + 
                (Sensitivity[(r[d])]*X[(r[d])])/(1-X[(r[d])]/Capacity[(r[d])]))    

##Cars per minute using the network
Car_per_minute_using=6

##Cars per minute arriving at each node must leave that node
@NLconstraint(m,[d in diff],sum(X[(r[i])] for i in 1:length(to) if r[i][2]==d)==
                          sum(X[(r[j])] for j in 1:length(from) if r[j][1]==d))          
                                                            
##Set each node leaving from the entrance on the shortest path                                                                                                    
@NLconstraint(m,sum(X[(r[i])] for i in 1:length(from) if r[i][1]=="a")==1)

##Setting the capacity of the volume of each node to be a little less than the limit.
##Not doing this will cause the objective to have an error. 
##Else  (Sensitivity[(r[d])]*X[(r[d])])/(1-X[(r[d])]/Capacity[(r[d])]))  would equal   
##(Sensitivity[(r[d])]*X[(r[d])])/(1-1) which would be division by zero.                                                                                                                                                                                                                                        
@NLconstraint(m,[d in r],X[(d)]<=.9999*Capacity[(d)])

##Minimizing the sum of the cars per minute entering the road with the travel time per
##road.                                                                                                                    
@NLobjective(m,Min,sum(T[(d)]*X[(d)]/Car_per_minute_using for d in r))
                                                                                                                    
optimize!(m)
                                                                                                                    
value.(T)
 
value.(X)                                                                                                                    
                                                                                                                    
