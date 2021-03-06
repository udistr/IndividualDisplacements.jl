
"""
    VelCopy(du,u,p::DataFrame,t)

Interpolate velocity from MITgcm float_trajectories output and return
position increment `du`.
"""
function VelCopy(du,u,p::DataFrame,t)
    tt=t/3600.0
    tt0=Int32(floor(tt))
    w=tt-tt0
    du[1]=(1.0-w)*p[tt0+1,:uVel]+w*p[tt0+2,:uVel]
    du[2]=(1.0-w)*p[tt0+1,:vVel]+w*p[tt0+2,:vVel]
end

"""
    read_flt(dirIn::String,prec::DataType)

Read displacements from MITgcm/pkg/flt output file into a DataFrame.
"""
function read_flt(dirIn::String,prec::DataType)

   #load the data into one array
   prec==Float64 ? reclen=8 : reclen=4
   n1=13

   filIn="float_trajectories"
   tmp1=readdir(dirIn)
   tmp1=filter(x -> occursin(filIn,x),tmp1)
   filList=filter(x -> occursin(".data",x),tmp1)
   #hack:
   #filList=filter(x -> occursin("002.002.data",x),tmp1)
   nf=length(filList)

   n2=Array{Int,1}(undef,nf)
   for ff=1:nf
      fil=dirIn*filList[ff]
      #println(fil)
      tmp=stat(fil)
      n2[ff]=Int64(tmp.size/n1/reclen)-1
   end

   arr = Array{prec,2}(undef,(n1+1,sum(n2)));
   ii=0;
   #@softscope for ff=1:nf
   for ff=1:nf
      fil=dirIn*filList[ff]
      fid = open(fil)
      tmp = Array{prec,2}(undef,(n1,n2[ff]+1))
      read!(fid,tmp)
      arr[1:n1,ii+1:ii+n2[ff]] = hton.(tmp[:,2:n2[ff]+1])
      arr[n1+1,ii+1:ii+n2[ff]] .= ff
      ii=ii+n2[ff]
   end

   #sort the whole dataset by time
   jj = sort!([1:ii;], by=i->arr[2,i]); arr=arr[:,jj];
   #arr = sort!(arr, dims=2, by=i->arr[2,i]);

   #nfloats=Int(maximum(arr[1,:]))
   #npoints=counts(Int.(arr[1,:]))

   #reformat data as a DataFrame
   df=DataFrame()
   df.ID=Int.(arr[1,:])
   df.time=Int.(arr[2,:])
   df.lon=arr[3,:]
   df.lat=arr[4,:]
   df.dep=arr[5,:]
   if true
      df.i=arr[6,:]
      df.j=arr[7,:]
      df.k=arr[8,:]
      df.etaN=arr[9,:]
      df.uVel=arr[10,:]
      df.vVel=arr[11,:]
      df.theta=arr[12,:]
      df.salt=arr[13,:]
      df.tile=Int.(arr[14,:])
   end

   nfloats=maximum(df.ID);
   nsteps=maximum(counts(df.ID));

   println("# floats=$nfloats")
   println("# steps=$nsteps")

   return df
end

"""
    read_drifters(pth,lst;chnk=Inf,rng=(missing,missing))

Read near-surface drifter data (https://doi.org/10.1002/2016JC011716) from the
Global Drifter Program (https://doi.org/10.25921/7ntx-z961) into a DataFrame

Note: need to use NetCDF.jl as NCDatasets.jl errors when TIME = Inf

```
pth="Drifter_hourly_v013/"
lst=["driftertrajGPS_1.03.nc","driftertrajWMLE_1.02_block1.nc","driftertrajWMLE_1.02_block2.nc",
   "driftertrajWMLE_1.02_block3.nc","driftertrajWMLE_1.02_block4.nc","driftertrajWMLE_1.02_block5.nc",
   "driftertrajWMLE_1.02_block6.nc","driftertrajWMLE_1.03_block7.nc"]

#df=read_drifters( pth*lst[end],chnk=1000,rng=(2014.1,2014.2) )

df = DataFrame(lon=[], lat=[], t=[], ID=[])
for fil in lst
   println(fil)
   append!(df,read_drifters( pth*fil,chnk=10000,rng=(2005.0,2020.0) ))
   println(size(df))
end

#sort!(df, [:t, :lat])
#CSV.write(pth*"Drifter_hourly_2005_2019.csv", df)
#unID=unique(df[!,:ID])
```
"""
function read_drifters(fil::String;chnk=Inf,rng=(missing,missing))
   t=ncread(fil,"TIME")
   t_u=ncgetatt(fil,"TIME","units")
   lo=ncread(fil,"LON")
   la=ncread(fil,"LAT")
   ID=ncread(fil,"ID")

   ii=findall(isfinite.(lo.*la.*t))
   t_ii=t[ii]
   t_ii=timedecode.(t_ii, t_u)
   tmp=dayofyear.(t_ii)+(hour.(t_ii) + minute.(t_ii)/60 ) /24
   t_ii=year.(t_ii)+tmp./daysinyear.(t_ii)
   isfinite(rng[1]) ? jj=findall( (t_ii.>rng[1]).&(t_ii.<=rng[2])) : jj=1:length(ii)

   ii=ii[jj]
   t=t_ii[jj]
   lo=lo[ii]
   la=la[ii]
   ID=ID[ii]

   df = DataFrame(lon=[], lat=[], t=[], ID=[])
   !isinf(chnk) ? nn=Int(ceil(length(ii)/chnk)) : nn=1
   for jj=1:nn
      #println([jj nn])
      !isinf(chnk) ? i=(jj-1)*chnk.+(1:chnk) : i=(1:length(ii))
      i=i[findall(i.<length(ii))]
      append!(df,DataFrame(lon=lo[i], lat=la[i], t=t[i], ID=ID[i]))
   end

   return df
end
