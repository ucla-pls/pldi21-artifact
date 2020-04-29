# Benchmarks removed from the data-set

## Covariant Arrays

You can cast arrays to other arrays, this is not enforced byt the java
typesystem.

```
Object [] a = new Car[1];
a[0] = "I'm not a car";
```

-   url22ade473db_sureshsajja_CodingProblems, because it contains a bug in the
	  compiler, which expolits Covarient Arrays.
	  (here)[https://github.com/sureshsajja/CodingProblems/blob/master/src/main/java/com/coderevisited/generics/CovariantArrays.java]

-  url2984a84cec_yusuke2255_relation_resolver, same problem

-  url484e914e4f_JasperZXY_TestJava, same problem

## Overloads the std-library

-  url03c33a0cf1_m_m_m_java8_backports. Reimplements many items in the stdlibrary. This 
	 makes it hard to figure out items which were meant by the compiler.
