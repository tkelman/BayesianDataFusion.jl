function pred(probe_vec, sample_m, sample_u, mean_rating)
  sum(sample_m[probe_vec[:,2],:].*sample_u[probe_vec[:,1],:],2) + mean_rating
end

function makeClamped(x, clamp::Vector{Float64})
  x2 = copy(x)
  x2[x2 .< clamp[1]] = clamp[1]
  x2[x2 .> clamp[2]] = clamp[2]
  return x2
end

function ConditionalNormalWishart(U::Matrix{Float64}, mu::Vector{Float64}, kappa::Real, T::Matrix{Float64}, nu::Real)
  N = size(U, 1)
  Ū = mean(U,1)
  S = cov(U, mean=Ū)
  Ū = Ū'

  mu_c = (kappa*mu + N*Ū) / (kappa + N)
  kappa_c = kappa + N
  T_c = inv( inv(T) + N * S + (kappa * N)/(kappa + N) * (mu - Ū) * (mu - Ū)' )
  nu_c = nu + N

  NormalWishart(vec(mu_c), kappa_c, T_c, nu_c)
end

function grab_col{Tv,Ti}(A::SparseMatrixCSC{Tv,Ti}, col::Integer)
  r = A.colptr[col]:A.colptr[col+1]-1
  A.rowval[r], A.nzval[r]
end

function sample_user(uu, Au::IndexedDF, mode::Int, mean_rating, sample_m, alpha, mu_u, Lambda_u, num_latent)
  #ff, v = grab_col(Au, uu)
  df = getData(Au, mode, uu)
  ff = df[:, mode == 1 ? 2 : 1]
  v  = array( df[:, end] )

  rr = v - mean_rating
  MM = sample_m[ff,:]

  covar = inv(Lambda_u + alpha * MM'*MM)
  mu = covar * (alpha * MM'*rr + Lambda_u * mu_u)

  # Sample from normal distribution
  chol(covar)' * randn(num_latent) + mu
end

function sample_beta(F, sample_u_c, Lambda_u, lambda_beta)
  N, D = size(sample_u_c)
  numF = size(F, 2)
  
  mv = MultivariateNormal(zeros(D), inv(Lambda_u) )
  Ft_y = F' * (sample_u_c + rand(mv, N)') + sqrt(lambda_beta) * rand(mv, numF)'
  
  # executed in parallel
  beta_list = pmap( d -> ridge_solve(F, Ft_y[:,d], lambda_beta), 1:D )
  beta = zeros(numF, D)
  for d = 1:D
    beta[:,d] = beta_list[d]
  end
  return beta, Ft_y
end
