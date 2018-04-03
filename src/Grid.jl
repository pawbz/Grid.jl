__precompile__()

module Grid

"""
Data type to represent 2D grid.
# Fields
* `x` : horizontal values
* `z` : vertical values
* `nx` : number of samples in horizontal direction
* `nz` : number of samples in vertical direction
* `δx` : sampling interval in horizontal direction
* `δz` : sampling interval in vertical direction
"""
type M2D
	x::Array{Float64,1}
	z::Array{Float64,1}
	nx::Int64
	nz::Int64
	npml::Int64
	δx::Float64
	δz::Float64
	"adding conditions that are to be false while construction"
	M2D(x, z, nx, nz, npml, δx, δz) = 
		any([
       		  δx < 0.0, length(x) != nx,
       		  δz < 0.0, length(z) != nz
		  ]) ? 
		error("error in M2D construction") : new(x, z, nx, nz, npml, δx, δz)
end

"Logical operation for `M2D`"
function Base.isequal(grid1::M2D, grid2::M2D)
	return all([(isequal(getfield(grid1, name),getfield(grid2, name))) for name in fieldnames(M2D)])
end

"""
Construct 2-D grid based on number of samples.

# Arguments

* `xmin::Float64` : first value of second dimension
* `xmax::Float64` : last value of second dimension
* `zmin::Float64` : first value of first dimension
* `zmax::Float64` : firs value of first dimension
* `nx::Int64` : size of second dimension
* `nz::Int64` : size of first dimension
* `npml::Int64` : number of PML layers 

# Return

* a `M2D` grid
"""
function M2D(xmin::Float64, xmax::Float64,
	zmin::Float64, zmax::Float64,
	nx::Int64, nz::Int64,
	npml::Int64 
	)
	x = Array(linspace(xmin,xmax,nx));
	z = Array(linspace(zmin,zmax,nz));
	return M2D(x, z, nx, nz, npml, x[2]-x[1], z[2]-z[1])
end

"""
Construct 2-D grid based on sampling intervals.

# Arguments

* `xmin::Float64` : first value of second dimension
* `xmax::Float64` : last value of second dimension
* `zmin::Float64` : first value of first dimension
* `zmax::Float64` : firs value of first dimension
* `δx::Float64` : second sampling interval
* `δz::Float64` : first sampling interval
* `npml::Int64` : number of PML layers 

# Return

* a `M2D` grid
"""
function M2D(xmin::Float64, xmax::Float64,
	zmin::Float64, zmax::Float64,
	δx::Float64, δz::Float64,
	npml::Int64,
	)
	x = [xx for xx in xmin:δx:xmax]
	z = [zz for zz in zmin:δz:zmax]
	nx, nz = size(x,1), size(z,1);
	return M2D(x, z, nx, nz, npml, x[2]-x[1], z[2]-z[1])
end


"""
Resample a 2-D grid.

# Arguments

* `grid::M2D` : input grid this is to be resampled
* `δx::Float64` : new second sampling interval
* `δz::Float64` : new first sampling interval

# Return

* a `M2D` resampled grid
"""
M2D_resamp(grid::M2D, δx::Float64, δz::Float64) = M2D(grid.x[1], grid.x[end], 
					grid.z[1], grid.z[end], δx, δz, grid.npml)


"""
Extend M2D by on its PML grid points on all sides.
"""
function M2D_pml_pad_trun(mgrid::M2D; flag::Int64=1)

	if(isequal(flag,1)) 
		xmin = mgrid.x[1] - mgrid.npml*mgrid.δx
		xmax = mgrid.x[end] + mgrid.npml*mgrid.δx
		zmin = mgrid.z[1] - mgrid.npml*mgrid.δz
		zmax = mgrid.z[end] + mgrid.npml*mgrid.δz
		return M2D(xmin,xmax,zmin,zmax, mgrid.nx+2*mgrid.npml,mgrid.nz+2*mgrid.npml,mgrid.npml)
	elseif(isequal(flag,-1))
		xmin = mgrid.x[1] + mgrid.npml*mgrid.δx
		xmax = mgrid.x[end] - mgrid.npml*mgrid.δx
		zmin = mgrid.z[1] + mgrid.npml*mgrid.δz
		zmax = mgrid.z[end] - mgrid.npml*mgrid.δz
		return M2D(xmin,xmax,zmin,zmax, mgrid.nx-2*mgrid.npml,mgrid.nz-2*mgrid.npml,mgrid.npml)
	else
		error("invalid flag")
	end
	
end

"""
Return the X and Z positions of the boundary of mgrid
* `attrib::Symbol` : 
  * `=:inner`
  * `=:outer`
* `onlycount::Bool=false`
"""
function M2D_boundary(mgrid::M2D, nlayer::Int64, attrib::Symbol; onlycount::Bool=false)
	if(attrib == :inner)
		x = mgrid.x; z = mgrid.z;
	elseif(attrib == :outer)
		# extending x and z and then choosing inner layers
		x = vcat(
	   		[mgrid.x[1]-(ilayer)*mgrid.δx for ilayer=1:nlayer:-1],
	   		mgrid.x,
			[mgrid.x[end]+(ilayer)*mgrid.δx for ilayer=1:nlayer],
			)
		z = vcat(
	   		[mgrid.z[1]-(ilayer)*mgrid.δz for ilayer=1:nlayer:-1],
	   		mgrid.z,
			[mgrid.z[end]+(ilayer)*mgrid.δz for ilayer=1:nlayer],
			)
	end
	nx = length(x); nz = length(z);
	bx = vcat(
		  x, x[end]*ones(nz-1),	  x[end-1:-1:1], x[1]*ones(nz-2))
	bz = vcat(
		  z[1]*ones(nx), z[2:end],  z[end]*ones(nx-1), z[end-1:-1:2])

	if(nlayer > 1)
		bx = vcat(bx,  x[2:end-1], x[end-1]*ones(nz-3), 
		  x[end-2:-1:2], x[2]*ones(nz-4))

		bz = vcat(bz,  z[2]*ones(nx-2), z[3:end-1],
		  z[end-1]*ones(nx-3), z[end-2:-1:3])
	end
	if(nlayer > 2)
		bx = vcat(bx,  x[3:end-2], x[end-2]*ones(nz-5), 
		  x[end-3:-1:3], x[3]*ones(nz-6)
		  )
		bz = vcat(bz,  z[3]*ones(nx-4), z[4:end-2],
		  z[end-2]*ones(nx-5), z[end-3:-1:4]
		  )
	end
	isequal(length(bz), length(bx)) ? nothing : error("unequal dimensions")
	if(onlycount)
		return length(bz)
	else
		return bz, bx, length(bz)
	end
end


"""
Data type to represent 1D grid.
# Fields
* `x` : values
* `nx` : number of samples
* `δx` : sampling interval
"""
type M1D
	x::Array{Float64}
	nx::Int64
	δx::Float64
	"adding conditions that are to be false while construction"
	M1D(x, nx, δx) = 
		any([δx < 0.0, length(x) != nx]) ? 
			error("error in M1D construction") : new(x, nx, δx)
end

"Logical operation for `M1D`"
function Base.isequal(grid1::M1D, grid2::M1D)
	return all([(isequal(getfield(grid1, name),getfield(grid2, name))) for name in fieldnames(M1D)])
end

"""
Construct 1-D grid based on number of samples.

# Arguments

* `xbeg::Float64` : first value
* `xend::Float64` : last value
* `nx::Int64` : number of samples
"""
function M1D(xbeg::Float64, xend::Float64, nx::Int64)
	x = Array(linspace(xbeg, xend, nx))
	δx = length(x)==1 ? 0. : x[2]-x[1]
	return M1D(x, nx, δx)
end

"""
Construct 1-D grid based on sampling interval.

# Arguments

* `xbeg::Float64` : first value
* `xend::Float64` : last value
* `δx::Float64` : number of samples
"""
function M1D(xbeg::Float64, xend::Float64, δx::Float64)
	x = [tt for tt in xbeg:δx:xend]
	δx = length(x)==1 ? 0. : x[2]-x[1]
	return M1D(x, size(x,1), δx)
end

"""
Grid with both positive and negative samples for a given lag.
Construction makes sure that the number of output grid samples is odd.

* xlag if scalar use same for both +ve and -ve lags, otherwise give vector

# Output
* Grid with both +ve and-ve lags
* number of +ve and -ve lags
"""
function M1D_lag(xlag, δx::Float64)
	if(length(xlag)==1)
		xlag=[xlag[1],xlag[1]]
	end
	nplag=round(Int,xlag[1]/δx)
	nnlag=round(Int,xlag[2]/δx)
	x=[0.0]
	x1=[(it-1)*δx for it in 2:nplag]
	if(x1≠[])
		x=vcat(x,x1)
	end
	nplag=length(x1)
	x2=[(it-1)*δx for it in 2:nnlag]
	if(x2≠[])
		x=vcat(-1.*flipdim(x2,1),x)
	end
	nnlag=length(x2)
	if(x==[])
		δx=0.
		x=zeros(1)
	end
	if(xlag[1]==xlag[2]≠0)
		isodd(length(x)) ? nothing : error("error in creating lag grid")
	end
	return M1D(x, size(x,1), δx), [nplag, nnlag] # lags are one less because of zero lag
end

"""
1-D grid with a different sampling interval
* Not yet implemented for fft grids
"""
function M1D_resamp(grid::M1D, δx::Float64) 
	return M1D(grid.x[1], grid.x[end], δx)
end

"""
1-D grid which is has a different size
"""
function M1D_truncate(grid::M1D, xbeg::Float64, xend::Float64)
	ix1 = indmin((grid.x - xbeg).^2.0);
	ix2 = indmin((grid.x - xend).^2.0);
	ixmin = minimum([ix1, ix2]); 
	ixmax = maximum([ix1, ix2]); 
	x = grid.x[ixmin:ixmax];
	return M1D(x, size(x,1), x[2]-x[1])
end


"grid after FFT"
M1D_fft(grid::M1D) = M1D_fft(grid.nx, inv(grid.nx*grid.δx))
M1D_rfft(grid::M1D) = M1D_rfft(grid.nx, inv(grid.nx*grid.δx))

"""
Frequency grid after rfft
"""
function M1D_rfft(nx::Int64, δ::Float64)
	vec = zeros(div(nx,2)+1);
	# zero lag
	vec[1] = 0.0;

	# +ve
	for i = 1: div(nx,2)
		vec[1+i] = δ * i
	end
	return M1D(vec, length(vec), δ)
end


function M1D_fft(nx::Int64, δ::Float64)
	vec = zeros(nx);
	# zero lag
	vec[1] = 0.0;

	if(isodd(nx))
		# +ve
		for i = 1: div(nx,2)
			vec[1+i] = δ * i
		end
		# -ve
		for i = 1: div(nx,2)
			vec[nx-i+1] = -δ * i
		end
	else
		# +ve
		for i = 1: div(nx,2)
			vec[1+i] = δ * i
		end
		# -ve one less the number of +ve lags
		for i = 1: div(nx,2)-1
			vec[nx-i+1] = -δ * i
		end
	end
	return M1D(vec, nx, δ)
end


"""
Return grid after cross-correlation.
The positive and negative lags are approximately given by lags.
"""
function M1D_xcorr(tgrid; lags=[1.,1.].*abs(tgrid.x[end]-tgrid.x[1]))

	plags=round(Int,  lags[1]*inv(tgrid.δx))
	nlags=round(Int,  lags[2]*inv(tgrid.δx))

	vec=vcat(-1.*collect(nlags:-1:0),collect(1:plags)).*tgrid.δx
	return M1D(vec, length(vec), tgrid.δx)
end


end # module
