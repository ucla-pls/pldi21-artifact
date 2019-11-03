public class Main { 

    public static void main (String [] args) {
        System.out.println(new A().m());
    }

    public static class A implements I {
    }

    public static interface I extends J { 
        public default int m () {
            return 5;
        }
    }
    
    public static interface J { 
        int m (); 
    }
}
