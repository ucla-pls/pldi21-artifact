public class Main {
  public String m (I a) { return a.m(); }

  public static void main (String [] args) { 
    System.out.println(new Main().m(new A()));
  }
}
