#include <iostream>

class Estudiantes{
    public:
        std::string nombre;
        int edad;
        float promedio;

        Estudiantes(std::string nombre, int edad, float promedio){
            this->edad = edad;
            this->nombre = nombre;
            this->promedio = promedio;
        }





};


int main(){

    Estudiantes sample("Paco",10,15.4);
    
    std::cout<<"Nombre: "<<sample.nombre;

    
    return 0;
}