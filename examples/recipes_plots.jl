using Random, Plots, DataFrames, ColorSchemes

"""
    PlotBasic(df::DataFrame,nn::Integer,dMax::Float64=0.)

Plot random subset of size nn trajectories.
"""
function PlotBasic(df::DataFrame,nn::Integer,dMax::Float64=0.)
   IDs = randperm(maximum(df.ID))
   COs=["w" "y" "g" "k"]

   plt=plot(leg=false)
   for ii=1:nn
      tmp=df[df.ID .== IDs[ii], :]
      if dMax > 0.
         d=abs.(diff(tmp[!,:lon]))
         jj=findall(d .> dMax)
         tmp[jj,:lon].=NaN; tmp[jj,:lat].=NaN
         d=abs.(diff(tmp[!,:lat]))
         jj=findall(d .> dMax)
         tmp[jj,:lon].=NaN; tmp[jj,:lat].=NaN
      end
      CO=COs[mod(ii,4)+1]
      plot!(tmp[!,:lon],tmp[!,:lat],linewidth=0.3)
   end
   return plt
end

"""
    scatter_subset(df,t)

```
nf=size(u0,2)
t=[ceil(i/nf) for i in 1:367*nf]
df[!,:t]=2000 .+ 10/365 * t

@gif for t in 2000:0.1:2016
   scatter_subset(df,t)
end
```
"""
function scatter_subset(df,t)
    dt=0.25
    df_t = df[ (df.t.>t-dt).&(df.t.<=t) , :]
    scatter(df_t.lon,df_t.lat,markersize=2,
    xlims=(-180.0,180.0),ylims=(-90.0,90.0))
end

"""
    phi_and_subset(Γ,ϕ,df,t,dt=5.0)

```
t=maximum(df[!,:t])
phi_and_subset(Γ,ϕ,df,t)
```
"""
function phi_and_subset(Γ,ϕ,df,t=missing,dt=5.0)
    ismissing(t) ? t=maximum(df[!,:t]) : nothing
    df_t = df[ (df.t.>t-dt).&(df.t.<=t) , :]
    nx,ny=size(ϕ[1])
    contourf(vec(Γ["XC"][1][:,1]),vec(Γ["YC"][1][1,:]),
        transpose(ϕ[1]),c = :blues,linewidth = 0.1)
    scatter!(df_t.x,df_t.y,markersize=2.0,c=:red,
    xlims=(0,nx),ylims=(0,ny),leg=:none,marker = (:circle, stroke(0)))
end
