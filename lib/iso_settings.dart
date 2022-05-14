

class Iso_settings{


  List<double> makecolormatrix(double brightness){

    final a = List<double>.filled(20, 0);
    a[0] = brightness;
    a[6] = brightness;
    a[12] = brightness;
    a[18] = 1;

    return a;

  }

  int rangeconv(double val){

    double y = 3200-50;
    double x = 3.2-0.5;

    double ans = (val - 0.5)*(y/x);
    ans=ans+50;

    return ans.toInt();


  }



}