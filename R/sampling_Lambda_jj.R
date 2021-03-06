#' @title
#'   MCMC sampling of parameter "\eqn{\Lambda_{j,j}}" in the \emph{mixdpcluster} model for Bayesian clustering.
#'
#' @description
#'   Generates a sample from the the posterior distribution of the j-th diagonal element \eqn{(i,j)} of the \eqn{\Lambda} matrix in the \emph{mixdpcluster} model for bayesian clustering.
#'   The simulation is done via Metropolis-Hastings method.
#' 
#' 
#' @importFrom stats dgamma
#' @importFrom compiler cmpfun
#' 
#' @keywords internal
#' 

sampling_Lambda_jj <- function( n_sim_mh=1, sigma_jj_ini,j,
                                d_0_z, d_1_z, kappa=1,
                                Z, mu_Z, sigma_Z, sampling_prob,
                                max.time=10*60,n.burn=0,
                                accept_display=T, verbose=F,
                                USING_CPP=TRUE) {

  ###     Metropolis-Hastings for variances of sigma_Z given by 'Lambda'     ###
  # MH Sampling from 'sigma_jk' #

  n <- nrow(Z)

  # initializing the chain #
  sigma_jj_chain <- sigma_jj_ini
  accept_indic <- as.numeric(NA)

  it_t_0 <- Sys.time()
  it_t_i <- as.numeric(Sys.time()-it_t_0)

  while( (length(sigma_jj_chain)-1 < (n_sim_mh+n.burn)) & (it_t_i<max.time) ) {
    if(verbose) {cat(".")}

    it_t_i <- as.numeric(Sys.time()-it_t_0)

    # generate proposal "sigma_j_new"
    sigma_jj_prop <- rgamma( n=1, shape=kappa, rate=kappa/sigma_jj_chain[length(sigma_jj_chain)] )

    # posterior probability for the current value and proposal of a
    if( USING_CPP ) {
      log_f_post_sigma_jj_curr <- log_f_post_Lambda_jj_cpp( sigma_jj=sigma_jj_chain[length(sigma_jj_chain)],
                                                            d_0_z=d_0_z,
                                                            d_1_z=d_1_z,
                                                            Z=Z,
                                                            mu_Z=mu_Z,
                                                            sigma_Z=sigma_Z,
                                                            sampling_prob=sampling_prob)

      log_f_post_sigma_jj_prop <- log_f_post_Lambda_jj_cpp( sigma_jj=sigma_jj_prop,
                                                            d_0_z=d_0_z,
                                                            d_1_z=d_1_z,
                                                            Z=Z,
                                                            mu_Z=mu_Z,
                                                            sigma_Z=sigma_Z,
                                                            sampling_prob=sampling_prob)
    } else {
      log_f_post_sigma_jj_curr <- log_f_post_Lambda_jj( sigma_jj=sigma_jj_chain[length(sigma_jj_chain)],
                                                        d_0_z=d_0_z,
                                                        d_1_z=d_1_z,
                                                        Z=Z,
                                                        mu_Z=mu_Z,
                                                        sigma_Z=sigma_Z,
                                                        sampling_prob=sampling_prob)

      log_f_post_sigma_jj_prop <- log_f_post_Lambda_jj( sigma_jj=sigma_jj_prop,
                                                        d_0_z=d_0_z,
                                                        d_1_z=d_1_z,
                                                        Z=Z,
                                                        mu_Z=mu_Z,
                                                        sigma_Z=sigma_Z,
                                                        sampling_prob=sampling_prob)
    }
    log_r <- (log_f_post_sigma_jj_prop - log_f_post_sigma_jj_curr) + ( dgamma( x=sigma_jj_chain[length(sigma_jj_chain)], shape=kappa, rate=kappa/sigma_jj_prop, log=T )
                                                                       -dgamma( x=sigma_jj_prop, shape=kappa, rate=kappa/sigma_jj_chain[length(sigma_jj_chain)], log=T )
    )
    # exp(log_r)

    # if(is.na(log_r)) {browser()}
    #if( runif(1,0,1) > lik_ratio ) {
    if( log_r>=0 || runif(1,0,1) < exp(log_r) ) {
      sigma_jj_chain <- c( sigma_jj_chain, sigma_jj_prop )
      accept_indic <- c(accept_indic,1)
      if(verbose) {cat(length(unique(sigma_jj_chain))-1)}
    } else {
      sigma_jj_chain <- c( sigma_jj_chain, sigma_jj_chain[length(sigma_jj_chain)] )
      accept_indic <- c(accept_indic,0)
    }
  }

  if(it_t_i>max.time) {
    cat('\nError: There is a problem simulating from "sigma_j_prop" \n')
    stop('There is a problem simulating from "sigma_j_prop"')
  }

  if(accept_display) {
    return( list( sigma_jj = sigma_jj_chain[(n.burn+2):length(sigma_jj_chain)],
                  accept_indic = accept_indic[(n.burn+2):length(accept_indic)] ) )
  } else {
    return( sigma_jj_chain[(n.burn+2):length(sigma_jj_chain)] )
  }
}

sampling_Lambda_jj <- compiler::cmpfun(sampling_Lambda_jj)
