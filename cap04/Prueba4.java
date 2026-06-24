package cap04;
import cap03.Persona;
public class Prueba4 {
    public static void main(String[] args) {
        Persona persona = new Persona("Juan", 30);
        System.out.println(persona);

        IO.println("Bienvenido al Playground de Java 25");

        String nombre = IO.readln("¿Cuál es tu nombre? ");
        IO.println("Encantado de conocerte, " + nombre);

        String lenguaje = IO.readln("¿Qué lenguaje te gusta más? ");
        IO.println("Interesante elección: " + lenguaje);

    }
}
