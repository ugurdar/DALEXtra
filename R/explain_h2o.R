#' Create explainer from your h2o model
#'
#' DALEX is designed to work with various black-box models like tree ensembles, linear models, neural networks etc.
#' Unfortunately R packages that create such models are very inconsistent. Different tools use different interfaces to train, validate and use models.
#' One of those tools, we would like to make more accessible is H2O.
#'
#'
#' @param model object - a model to be explained
#' @param data data.frame or matrix - data that was used for fitting. If not provided then will be extracted from the model
#' @param y numeric vector with outputs / scores. If provided then it shall have the same size as \code{data}
#' @param predict_function function that takes two arguments: model and new data and returns numeric vector with predictions
#' @param residual_function function that takes three arguments: model, data and response vector y. It should return a numeric vector with model residuals for given data. If not provided, response residuals (\eqn{y-\hat{y}}) are calculated.
#' @param ... other parameters
#' @param label character - the name of the model. By default it's extracted from the 'class' attribute of the model
#' @param verbose if TRUE (default) then diagnostic messages will be printed
#'
#' @return explainer object ready to work with DALEX
#'
#' @importFrom DALEX explain
#'
#'
#' @examples
#' \dontrun{
#' titanic_test <- read.csv(system.file("extdata", "titanic_test.csv", package = "DALEXtra"))
#' titanic_train <- read.csv(system.file("extdata", "titanic_train.csv", package = "DALEXtra"))
#' library("DALEX")
#' h2o::h2o.init()
#' h2o::h2o.no_progress()
#' titanic_h2o <- h2o::as.h2o(titanic_train)
#' titanic_h2o["survived"] <- h2o::as.factor(titanic_h2o["survived"])
#' titanic_test_h2o <- h2o::as.h2o(titanic_test)
#' model <- h2o::h2o.gbm(
#' training_frame = titanic_h2o,
#' y = "survived",
#' distribution = "bernoulli",
#' ntrees = 5000,
#' max_depth = 4,
#' min_rows =  12,
#' learn_rate = 0.001
#' )
#' explain_h2o(model, titanic_test[,1:17], titanic_test[,18])
#'}
#' @rdname explain_h2o
#' @export
#'

explain_h2o <-
  function(model,
           data = NULL,
           y = NULL,
           predict_function = NULL,
           residual_function = NULL,
           ...,
           label = NULL,
           verbose = TRUE) {
    switch(
      class(model),
      "H2ORegressionModel" = {
        predict_function <- function(X.model, newdata, ...) {
          if (!class(newdata) == "H2OFrame") {
            newdat <- h2o::as.h2o(newdata)
          }
          as.vector(h2o::h2o.predict(X.model, newdata = newdata))

        }
      },
      "H2OBinomialModel" = {
        predict_function <- function(X.model, newdata, ...) {
          if (!class(newdata) == "H2OFrame") {
            newdata <- h2o::as.h2o(newdata)
          }

          res <-
            as.data.frame(h2o::h2o.predict(X.model, newdata = newdata))
          res$p1
        }
      },
      stop("Model is not explainable h2o object")


    )

    if (class(y) == "H2OFrame") {
      y <- as.numeric(as.vector(y))
    }

    h2o::h2o.init()
    explain(
      model,
      data = data,
      y = y,
      predict_function = predict_function,
      residual_function = residual_function,
      label = label,
      verbose = verbose,
      ... = ...
    )


  }