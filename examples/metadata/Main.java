import java.lang.*;
import java.io.*;

public class Main {
  public static void main(String [] argv) {
    try {
      InputStream is = Class.forName("Main").getClassLoader().getResourceAsStream("resources/file.txt");
      BufferedReader r = new BufferedReader(new InputStreamReader(is));
      String line;
      while ((line = r.readLine()) != null) {
        System.out.println(line);
      }
    } catch (Exception e) {
      System.out.println(e);
    }
  }
}
