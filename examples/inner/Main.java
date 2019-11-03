public class Main {
    public void main () {
    }
    public class A <X> {
        public class B <Y> {
            public <Z> A<Boolean>[] m (Z a) { return null; }
        }
    }
    public class C {
        public void m (A<Boolean>.B<Integer> a) {}
    }
}
