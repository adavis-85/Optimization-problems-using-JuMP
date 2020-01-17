
Pkg.add("JuMP")
Pkg.add("GLPK")
using JuMP
using GLPK


##From ch. 17 AMPL book.  Transportation model with soft constraints.  The constraints are
##limits which we want to impose on a specific quantity of shipped goods.  

m=Model(with_optimizer(GLPK.Optimizer))

p=Containers.DenseAxisArray([1;2;3],orig,[1;2;3])

##These are the origin cities where the goods are shipped out of.
orig=["gary","clev","pitt"]

##These are the destinations shipped to.
dest=["fra","det","lan","win","stl","fre","laf"]

##Supplies of goods at each origin city
supply=[1400;2600;2900]

##The cost of shipping each goood from each origin city to each destination city.
cost=[39 14 11 14 16 82 8;
      27 9 12 9 26 95 17;
      24 14 17 14 28 99 29]

##Creating a container to more easily index the supply with other variables
S=Containers.DenseAxisArray(supply,orig)

##Container for the cost indexed by the origin city and destination city.
C=Containers.DenseAxisArray(cost,orig,dest)

#################################################################################
##These next four vectors are the "soft constraints" of the demand on the amounts 
##shipped.  

##The absolute minimum that needs to be shipped.  There will be a charge of two dollars a ton.
dminabs=[800;975;600;350;1200;1100;800]

##The preffered minimum amount to be shipped.  There will be no charge.
dminask=[850;1100;600;375;1500;1100;900]

##Preffered maximum amount to be shipped.  This goes along with the minimium.  
##There is no charge placed.
demaxask=[950;1225;625;450;1800;1100;1050]

##The absolute maximum that can be accepted.  There will be a charge of four dollars per
##ton on each good shipped on each unit above the preffered maximum.  This is also 
##known as a "penalty".
demmaxabs=[1100;1250;625;500;2000;1125;1175]
#################################################################################

##Container absolute minimum
Dminabs=Containers.DenseAxisArray(dminabs,dest)

##Container preferred minimum
Dminask=Containers.DenseAxisArray(dminask,dest)

##Container preferred maximum
Dmaxask=Containers.DenseAxisArray(demaxask,dest)

##Container absolte maximum
Dmaxabs=Containers.DenseAxisArray(demmaxabs,dest)

##Variable for the unknown demand, or possible amount received.
@variable(m,0<=Received[dest])

##Placing the bounds on the possible amount received.
@constraint(m,[j in dest],Dminabs[j]<=Received[j]<=Dmaxabs[j])

##The amount shipped for each separate rate.
@variable(m,trans[orig,dest,p]>=0)

##The amount transported from each origin city for each rate needs to equal
##the supply.
@constraint(m,[i in orig],sum(trans[i,j,p] for j in dest,p in p)==S[i])

##The amount transported needs to be less than or equal to the preffered amount.
@constraint(m,[j in dest],sum(trans[i,j,1] for i in orig)<=Dminask[j])

##The amount transported at the second rate ,which is 1 if a value needs to
##placed on it,has the limit placed on it for a 
##specific number of units. 
@constraint(m,[j in dest],sum(trans[i,j,2] for i in orig)<=Dmaxask[j]-Dminask[j])

##The amount transported for the third rate.
@constraint(m,[j in dest],sum(trans[i,j,3] for i in orig)<=Dmaxabs[j]-Dmaxask[j])

##Finding the minimum price of the units shipped for all three separe rates.  
##The demand/received amount was not known but the maximum and minimum was.  
@objective(m,Min,sum(2*C[i,j]*trans[i,j,1] for i in orig,j in dest) + 
    sum(C[i,j]*trans[i,j,2] for i in orig,j in dest) + 
    sum(4*C[i,j]*trans[i,j,3] for i in orig,j in dest))

optimize!(m)

value.(trans)

value.(Received)

sum(S)

sum(value.(Received))

##All units supplied were received


