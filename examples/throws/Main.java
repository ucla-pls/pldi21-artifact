public class Main extends Exception {

    public static void main (String [] args) {
        System.out.println(test2());
    }

    public static String test2 () {
        try { return test(); } catch (Exception e) { return "error"; }
    }
    
    public static String test () throws Main {
        return "hello";
    }

}
