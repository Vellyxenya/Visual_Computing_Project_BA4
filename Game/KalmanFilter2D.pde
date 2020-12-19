class KalmanFilter2D {
  
  float q = 1; // process variance
  float r = 6.0; // estimate of measurement variance, change to see effect
  float xhat = 0.0; // a posteriori estimate of x
  float yhat = 0.0;
  float xhatminus; // a priori estimate of x
  float yhatminus;
  float p = 1.0; // a posteriori error estimate
  float pminus; // a priori error estimate
  float kG = 0.0; // kalman gain
  
  KalmanFilter2D() {
  };
  
  KalmanFilter2D(float q, float r) {
    q(q);
    r(r);
  }
  
  void q(float q) {
    this.q = q;
  }
  
  void r(float r) {
    this.r = r;
  }
  
  float xhat() {
    return this.xhat;
  }
  
  float yhat() {
    return this.yhat;
  }
  
  PVector vectorHat() {
    return new PVector(xhat, yhat);
  }
  
  void predict() {
    xhatminus = xhat;
    yhatminus = yhat;
    pminus = p + q;
  }
  
  PVector correct(float x, float y) {
    kG = pminus / (pminus + r);
    xhat = xhatminus + kG * (x - xhatminus);
    yhat = yhatminus + kG * (y - yhatminus);
    p = (1 - kG) * pminus;
    return new PVector(xhat, yhat);
  }
  
  PVector predict_and_correct(float x, float y) {
    predict();
    return correct(x, y);
  }
  
  PVector predict_and_correct(PVector v) {
    predict();
    return correct(v.x, v.y);
  }
}
