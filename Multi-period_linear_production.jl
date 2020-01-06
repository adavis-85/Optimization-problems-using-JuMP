
Pkg.add("JuMP")
Pkg.add("GLPK")

using JuMP
using GLPK

##This is from chapter 4 LargerModels from the Ampl book.

M=Model(with_optimizer(GLPK.Optimizer))

T=4 

##Create the tensor which will hold the revenue per ton sold.
revenue=zeros(2,4,3)

##First scenario
revenue[:,:,1]=[25 26 27 27;
                30 35 37 39]

##Second scenario
revenue[:,:,2]=[23 24 25 25;
                30 33 35 36]

##Third scenario
revenue[:,:,3]=[21 27 33 35;
                30 32 33 33]

##The cost of production for each product.  In this example they are bands and coils
prodcost=[10;
          11]

##The initial inventory in tons of each product
inv0=[10;
       0]

##The cost of keeping inventory per ton for each time period(week)
invcost=[2.5;
           3]

##Tons per hour able to be produced
rate=[200;
      140]

##The time available(hours) for each time period(week)
avail=[40;
       40;
       32;
       40]

##The limit in tons able to be sold per week
market=[6000 6000 4000 6500;
        4000 2500 3500 4200]

##The tensor to hold the same market amounts to be applied to each revenue scenario
Markets=zeros(2,4,3)

for i in 1:3
       Markets[:,:,i]=market
end

##How much to make 
@variable(M,Make[i in 1:2,j in 1:4,p in 1:3]>=0)

##How much that is to be held in inventory
@variable(M,Inv[i in 1:2,j in 0:4,p in 1:3]>=0)

##How many tons sold
@variable(M,0<=Sell[i in 1:2,j in 1:4,p in 1:3]<=markets[i,j,p])

##The tons produced and taken from our inventory must equal the tons sold and put into
##the inventory
@constraint(M,[i in 1:2,j in 1:4,p in 1:3],
    Make[i,j,p]+ Inv[i,j-1,p]==Sell[i,j,p] + Inv[i,j,p])

##The initial inventory amount is set
@constraint(M,[j in 1:2,s in 1:3],Inv[j,0,s]==inv0[j])

##The amount taken to produce the optimum amounts cannot exceed the amount available 
##per time period
@constraint(M,[t in 1:T,s in 1:3],sum(1/rate[p]*Make[p,t,s] 
             for p in 1:2)<=avail[t])

##The likelyhood of choosing which scenario will be or look the best to the company
prob=[.45;
      .35;
       .2]

##Finding the maximum profit across all the scenarios
@objective(M,Max,sum(sum(revenue[p,t,s]*Sell[p,t,s]-prodcost[p]*Make[p,t,s]
            -invcost[p]*Inv[p,t,s] for p in 1:2,t in 1:4)*prob[s] for s in 1:3))

optimize!(M)

termination_status(M)

JuMP.value.(Sell)

JuMP.value.(Make)

JuMP.value.(Inv)

##The following constraints are non-anticipatory.  They give the optimum price after a first
##week.  After the first week then the data can be updated and the scenarios run again
@constraint(M,[p in 1:2,s in 1:2],Make[p,1,s]==Make[p,1,s+1])

@constraint(M,[p in 1:2,s in 1:2],Sell[p,1,s]==Sell[p,1,s+1])

@constraint(M,[p in 1:2,s in 1:2],Inv[p,1,s]==Inv[p,1,s+1])

optimize!(M)

##Find which scenario will be the most profitable
profits=zeros(3)

 for s in 1:3
       profits[s]=(sum(revenue[p,t,s]*value.(Sell[p,t,s])
            -prodcost[p]*value.(Make[p,t,s])-invcost[p]*value.(Inv[p,t,s])
            for p in 1:2,t in 1:4))
end

profits




