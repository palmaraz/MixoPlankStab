model {

 # Model for the process ####

  for(t in 2:NTimeSteps){

    n[t,1:NSpecies] ~ dmnorm(mu[t,1:NSpecies], Tau[,])

    # Posterior predicted datasets
    n_ppc[t,1:NSpecies] ~ dmnorm(mu[t,1:NSpecies], Tau[,])

    for(i in 1:NSpecies){

      mu[t,i] <- n[t-1,i] + dt[t-1]*(r[i]*(1 + inprod(alpha[i,], exp.n[t-1,])/k[i]) + inprod(env_effect[i,], env_data[t-1,]))

      exp.n[t-1,i] <- exp(n[t-1,i]) - 1

      loglik_n[t,i] <- logdensity.mnorm(n[t,i], mu[t,i], Tau[i,i])

    }

  }

  mu[1,1:NSpecies] ~ dmnorm(n[1,1:NSpecies], Tau[,])

  n_ppc[1,1:NSpecies] ~ dmnorm(mu[1,1:NSpecies], Tau[,])

  for(i in 1:NSpecies){

    loglik_n[1,i] <- logdensity.mnorm(n[1,i], mu[1,i], Tau[i,i])

  }

  # Residuals of state equation:

  for(t in 1:NTimeSteps){

    for(i in 1:NSpecies){

      resid[t,i] <- n[t,i] - mu[t,i]

    }

  }

  # Interaction coefficients ####

  # Spike-and-Slab priors ####

  for(i in 1:NSpecies){

    alpha[i,i] <- -1
    inclusion.alpha[i,i] <- 1

    for(j in (i+1):NSpecies){

      inclusion.alpha[i,j] ~ dbern(prior_for_inclusion)
      active_alpha[i,j] ~ dnorm(0, 0.1)
      alpha[i,j] <- ifelse(inclusion.alpha[i,j]==0, 0, active_alpha[i,j])

      inclusion.alpha[j,i] ~ dbern(prior_for_inclusion)
      active_alpha[j,i] ~ dnorm(0, 0.1)
      alpha[j,i] <- ifelse(inclusion.alpha[j,i]==0, 0, active_alpha[j,i])

    }

  }

  prior_for_inclusion ~ dbeta(2,2)

  # Environmental effects ####

  for(i in 1:NSpecies){
    for(l in 1:NEnvVar){

      env_effect[i,l] ~ dnorm(0, 1)

    }
  }

  for(i in 1:NSpecies){

    # k[i] ~ dnorm(est.k[i], 0.25)T(0,)
    # r[i] ~ dnorm(0, 0.25)T(0,)

    # k[i] ~ dnorm(0, 0.1)T(0,)
    # k[i] ~ dnorm(est.k[i], 0.1)T(0,)

    k[i] ~ dnorm(est.k[i], 1/est.var.k[i])T(0,)
    r[i] ~ dnorm(0, 0.1)T(0,)

  }

  # Residual environmental covariance matrix (Sigma)

  Tau[1:NSpecies,1:NSpecies] ~ dscaled.wishart(rep(1,NSpecies), NSpecies)
  Sigma[1:NSpecies,1:NSpecies] <- inverse(Tau[,])

  ## Environmental synchrony ####

    for(i in 1:NSpecies){

      n_sigma2[i,i] <- Sigma[i,i]

      for(j in 1:NSpecies){

        Env_synchrony[i,j] <- Sigma[i,j]/sqrt(Sigma[i,i]*Sigma[j,j])

      }

    }

}

# END ####
