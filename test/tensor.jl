using BayesianDataFusion
using Base.Test

using DataFrames

A = rand(7,2);
B = rand(8,2);
C = rand(9,2);

X = Float64[ sum(A[i,:].*B[j,:].*C[k,:]) for i in 1:size(A,1), j in 1:size(B,1), k in 1:size(C,1)]

df = DataFrame(A=Int64[], B=Int64[], C=Int64[], v=Float64[])
for i=1:size(A,1), j=1:size(B,1), k=1:size(C,1)
  push!(df, {i,j,k,X[i,j,k]})
end

rd = RelationData(df)
assignToTest!(rd.relations[1], 100)
result = BMRF(rd, burnin=50, psamples=10)
