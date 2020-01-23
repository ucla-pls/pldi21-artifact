/**
  The goal of this example is to check the reduction of a class with lambdas in it.
*/
import java.lang.Runnable;
public class Main {

  public static void main (String [] args) {
    Runnable a = () -> System.out.println("Actually printed");
    a.run();
  }

  public void unrelated() {
    Runnable a = () -> System.out.println("Not printed");
    a.run();
  }
}
