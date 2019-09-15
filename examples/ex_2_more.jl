# ---
# jupyter:
#   jupytext:
#     formats: ipynb,jl:light
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.4'
#       jupytext_version: 1.2.1
#   kernelspec:
#     display_name: Julia 1.1.0
#     language: julia
#     name: julia-1.1
# ---

# ## This notebook
#
# - [x] read gridded output + `float_trajectory*data` => `uvetc` dictionnary.
# - [x] recompute `u,v` from gridded output
# - [x] compare with `u,v` from `float_traj*data`
# - [x] solve for float trajectory with `DifferentialEquations.jl`
#
# _Notes:_ For documentation see <https://gaelforget.github.io/MeshArrays.jl/stable/>, <https://docs.juliadiffeq.org/latest/solvers/ode_solve.html> and <https://en.wikipedia.org/wiki/Displacement_(vector)>

# # 1) Get gridded variables via MeshArrays.jl

# +
using IndividualDisplacements, PyPlot, MeshArrays, Plots, DifferentialEquations

dirIn="flt_example/"
prec=Float32
df=IndividualDisplacements.ReadDisplacements(dirIn,prec)
PyPlot.figure()
IndividualDisplacements.PlotBasic(df,300)
#gcf()
# -

# Put grid variables in a dictionary:

# +
import IndividualDisplacements: myread

mygrid=gcmgrid("flt_example/","ll",1,[(80,42)], [80 42], Float32, read, write)
nr=8

GridVariables=Dict("XC" => myread(mygrid.path*"XC",MeshArray(mygrid,Float32)),
"YC" => myread(mygrid.path*"YC",MeshArray(mygrid,Float32)),
"XG" => myread(mygrid.path*"XG",MeshArray(mygrid,Float32)),
"YG" => myread(mygrid.path*"YG",MeshArray(mygrid,Float32)),
"dx" => 5000.0);
# -

# Put velocity fields in a dictionary:

# +
t0=0.0 #approximation / simplification
t1=18001.0*3600.0

u0=myread(mygrid.path*"U.0000000001",MeshArray(mygrid,Float32,nr))
u1=myread(mygrid.path*"U.0000018001",MeshArray(mygrid,Float32,nr))
v0=myread(mygrid.path*"V.0000000001",MeshArray(mygrid,Float32,nr))
v1=myread(mygrid.path*"V.0000018001",MeshArray(mygrid,Float32,nr))

kk=3 #3 to match -1406.25 in pkg/flt output
u0=u0[:,kk]; u1=u1[:,kk];
v0=v0[:,kk]; v1=v1[:,kk];

uvt = Dict("u0" => u0, "u1" => u1, "v0" => v0, "v1" => v1, "t0" => t0, "t1" => t1) ;
# -

# Merge the two dictionaries:

uvetc=merge(uvt,GridVariables);

# ## Visualize velocity fields

# +
mskW=myread(mygrid.path*"hFacW",MeshArray(mygrid,Float32,nr))
mskW=1.0 .+ 0.0 * mask(mskW[:,kk],NaN,0.0)
mskS=myread(mygrid.path*"hFacS",MeshArray(mygrid,Float32,nr))
mskS=1.0 .+ 0.0 * mask(mskS[:,kk],NaN,0.0)

msk=Dict("mskW" => mskW, "mskS" => mskS)

uvetc=merge(uvetc,msk);
# -

heatmap(mskW[1,1].*u0[1,1],title="U at the start")

heatmap(mskS[1,1].*v0[1,1],title="V at the start")

heatmap(mskW[1,1].*u1[1,1]-u0[1,1],title="U end - U start")

# ## First look at  `float_trajectory*data`

tmp=df[df.ID .== 200, :]
tmp[1:4,:]

# ## Super-impose trajectory over velocity field

PyPlot.contourf(GridVariables["XG"].f[1], GridVariables["YC"].f[1], mskW.f[1].*u0.f[1])
PyPlot.plot(tmp[:,:lon],tmp[:,:lat],color="r")
colorbar()

PyPlot.contourf(GridVariables["XG"].f[1], GridVariables["YC"].f[1], mskS.f[1].*v0.f[1])
PyPlot.plot(tmp[:,:lon],tmp[:,:lat],color="r")
colorbar()

# ## Recompute velocities from gridded output

# +
comp_vel=IndividualDisplacements.VelComp
get_vel=IndividualDisplacements.VelCopy

uInit=[tmp[1,:lon];tmp[1,:lat]]
nSteps=Int32(tmp[end,:time]/3600)-2
du=fill(0.0,2);
# -

# Visualize and compare with actual grid point values -- jumps on the tangential component are expected with linear scheme:

tmpu=fill(0.0,100)
tmpv=fill(0.0,100)
tmpx=fill(0.0,100)
for i=1:100
    tmpx[i]=500.0 *i
    comp_vel(du,[tmpx[i];0.499],uvetc,0.0)
    tmpu[i]=du[1]
    tmpv[i]=du[2]
end
Plots.plot(tmpx,tmpu)
Plots.plot!(uvetc["XG"].f[1][1:10,1],uvetc["u0"].f[1][1:10,1],marker=".")
Plots.plot!(tmpx,tmpv)
Plots.plot!(uvetc["XG"].f[1][1:10,1],uvetc["v0"].f[1][1:10,1],marker=".")

tmpu=fill(0.0,100)
tmpv=fill(0.0,100)
tmpy=fill(0.0,100)
for i=1:100
    tmpy[i]=500.0 *i
    comp_vel(du,[0.499;tmpy[i]],uvetc,0.0)
    tmpu[i]=du[1]
    tmpv[i]=du[2]
end
Plots.plot(tmpx,tmpu)
Plots.plot!(uvetc["YG"].f[1][1,1:10],uvetc["u0"].f[1][1,1:10],marker=".")
Plots.plot!(tmpx,tmpv)
Plots.plot!(uvetc["YG"].f[1][1,1:10],uvetc["v0"].f[1][1,1:10],marker=".")

# ## Compare recomputed velocities with those from `pkg/flt`

nSteps=2998
tmpu=fill(0.0,nSteps); tmpv=fill(0.0,nSteps);
tmpx=fill(0.0,nSteps); tmpy=fill(0.0,nSteps);
refu=fill(0.0,nSteps); refv=fill(0.0,nSteps);
for i=1:nSteps
    get_vel(du,[tmp[i,:lon],tmp[i,:lat]],tmp,tmp[i,:time])
    refu[i]=du[1]
    refv[i]=du[2]
    comp_vel(du,[tmp[i,:lon],tmp[i,:lat]],uvetc,tmp[i,:time])
    tmpu[i]=du[1]
    tmpv[i]=du[2]
end
#
Plots.plot(tmpu)
Plots.plot!(tmpv)
Plots.plot!(refu)
Plots.plot!(refv)

# ## Solve for position time series using DifferentialEquations.jl

using DifferentialEquations
tspan = (0.0,nSteps*3600.0)
#prob = ODEProblem(get_vel,uInit,tspan,tmp)
prob = ODEProblem(comp_vel,uInit,tspan,uvetc)
sol = solve(prob,Tsit5(),reltol=1e-8,abstol=1e-8)
sol[1:4]

# +
ref=transpose([tmp[1:nSteps,:lon] tmp[1:nSteps,:lat]])
maxLon=80*5.e3
maxLat=42*5.e3
show(size(ref))
for i=1:nSteps-1
    ref[1,i+1]-ref[1,i]>maxLon/2 ? ref[1,i+1:end]-=fill(maxLon,(nSteps-i)) : nothing
    ref[1,i+1]-ref[1,i]<-maxLon/2 ? ref[1,i+1:end]+=fill(maxLon,(nSteps-i)) : nothing
    ref[2,i+1]-ref[2,i]>maxLat/2 ? ref[2,i+1:end]-=fill(maxLat,(nSteps-i)) : nothing
    ref[2,i+1]-ref[2,i]<-maxLat/2 ? ref[2,i+1:end]+=fill(maxLat,(nSteps-i)) : nothing
end

using Plots
Plots.plot(sol[1,:],sol[2,:],linewidth=5,title="Using Recomputed Velocities",
     xaxis="lon",yaxis="lat",label="Julia Solution") # legend=false
Plots.plot!(ref[1,:],ref[2,:],lw=3,ls=:dash,label="MITgcm Solution")
# -


