#define _SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS 1     //Para silenciar un warning tonto
#include <iostream>         //Librerias standar
#include <vector>
#include <cstdlib>
#include <atomic>
#include <thread>
#include <sstream>
#include <string>
#include <cassert>
#include <random>
//Librerias de stxxl
#include <stxxl/mng>
#include <stxxl/io>
#include <stxxl/vector>
#include <stxxl/bits/mng/prefetch_pool.h>
#include <iterator>
#define block_size (1024 * 64)
#define Num_vias 16
#define Num_block 100
typedef stxxl::typed_block<block_size, double> block_type;      //Definiciones de bloque 
typedef unsigned long long direccion;
typedef std::vector<block_type::bid_type> Bids;

class via {
public:
    bool validez = false;
    unsigned long long etiqueta = 0;
    unsigned long long last_uso = 0;
    block_type* dato = nullptr;
    stxxl::request_ptr lectura;     // lectura en vuelo (vacío si no hay)
};

typedef std::vector<via> tipo_conjunto;     //Conjuntos que contienen vias
typedef std::vector<tipo_conjunto> tipo_cache;          //Cache 
//Funciones para efectuar la simulacion

void simulacion(int vias, int conjuntos, Bids& bids, int iteraciones, int patron) ;
bool coincide_etiqueta(const via& v, unsigned long long etiqueta_buscada);
void cargar_bloque(via& v, const block_type::bid_type& bid);
void esperar_via(via& v);
unsigned long long generar_direccion(int patron, int j, unsigned long long rango,
                                     std::mt19937_64& gen,
                                     std::uniform_int_distribution<unsigned long long>& dist);
 
//Funciones empleadas para la interfaz grafica 
bool leer_linea(std::string& linea);
int pedir_simulaciones();
int pedir_patron();
bool preguntar_continuar();
int pedir_vias();
//Funciones para la lectura concurrente de la etiqueta
bool coincide_etiqueta(const via& v, unsigned long long etiqueta_buscada);
int buscar_en_conjunto_paralelo(const tipo_conjunto& conjunto, unsigned long long etiqueta_buscada);

void imprimir_cache(const tipo_cache& cache);
void liberar_cache(tipo_cache& cache);
void inicializar_cache(tipo_cache& cache, int num_conjuntos, int num_vias);
 
int encontrar_via_lru(const tipo_conjunto& conjunto);       
void actualizar_lru(tipo_conjunto& conjunto, int via, unsigned long long reloj);
bool acceder_cache(tipo_conjunto& conjunto, unsigned long long etiqueta_buscada,
    unsigned long long& reloj, int& via_usada);


int main() {
    Bids bids;
    stxxl::block_manager* bm = stxxl::block_manager::get_instance();
    bm->new_blocks<block_type>(100, stxxl::striping(), std::back_inserter(bids));

   do {
        int vias_a_usar = pedir_vias();
        if (vias_a_usar == 0) break;                     

        int num_simulaciones = pedir_simulaciones();
        if (num_simulaciones == 0) break;

        int patron = pedir_patron();
        if (patron == 0) break;;
        
        int conjuntos = Num_vias / vias_a_usar;    
        std::cout << "Configuracion: " << conjuntos << " conjuntos x "
                  << vias_a_usar << " vias\n";

        simulacion(vias_a_usar, conjuntos,bids,num_simulaciones,patron);
    } while (preguntar_continuar());

    // Aqui: liberar los bloques de disco UNA sola vez.
   bm->delete_blocks(bids.begin(), bids.end());
    return 0;
}


// Función que compara la etiqueta de una vía con una etiqueta dada.
// Devuelve true si coinciden y la vía es válida.
bool coincide_etiqueta(const via& v, unsigned long long etiqueta_buscada) {
    return v.validez && (v.etiqueta == etiqueta_buscada);
}

// Función principal que compara todas las vías de un conjunto en paralelo.
// Devuelve el índice de la vía donde se encontró el acierto, o -1 si no se encontró.
int buscar_en_conjunto_paralelo(const tipo_conjunto& conjunto, unsigned long long etiqueta_buscada) {
    int num_vias = conjunto.size();
    std::vector<std::thread> hilos;
    std::vector<std::atomic<int>> resultados(num_vias); // Usamos atomic para escritura segura

    // Inicializar resultados a -1 (no encontrado)
    for (int i = 0; i < num_vias; ++i) {
        resultados[i].store(-1);
    }

    // Lanzar un hilo por cada vía
    for (int i = 0; i < num_vias; ++i) {
        hilos.emplace_back([&conjunto, &resultados, i, etiqueta_buscada]() {
            if (coincide_etiqueta(conjunto[i], etiqueta_buscada)) {
                resultados[i].store(i); // Guardamos el índice de la vía que coincide
            }
            });
    }

    // Esperar a que todos los hilos terminen
    for (auto& hilo : hilos) {
        hilo.join();
    }

    // Buscar el primer resultado válido
    for (int i = 0; i < num_vias; ++i) {
        if (resultados[i].load() != -1) {
            return resultados[i].load(); // Devolvemos el índice de la vía
        }
    }

    return -1; // No se encontró en ninguna vía
}


void imprimir_cache(const tipo_cache& cache) {      //Imprime el estado de la cache
    for (size_t j = 0; j < cache.size(); ++j) {
        std::cout << "Conjunto " << j << ":" << std::endl;
        for (size_t v = 0; v < cache[j].size(); ++v) {
            std::cout << "  Via " << v
                << " | validez=" << cache[j][v].validez
                << " | etiqueta=" << cache[j][v].etiqueta
                << std::endl;
        }
    }
}


void liberar_cache(tipo_cache& cache) {     //Libera los bloques dinamicos que cada via posee
    for (size_t j = 0; j < cache.size(); ++j) {
        for (size_t v = 0; v < cache[j].size(); ++v) {
            delete cache[j][v].dato;
            cache[j][v].dato = nullptr; // Evitar punteros colgantes
        }
    }
}


// Inicializa la caché con el número de conjuntos y vías indicados.
// Recibe la caché por referencia y la deja lista para usarse,
// asignando un bloque STXXL dinámico a cada vía.
void inicializar_cache(tipo_cache& cache, int num_conjuntos, int num_vias) {    //inicializa la cache con los n vias y n conjuntos dados
    // Redimensionar la caché a la geometría indicada
    cache.resize(num_conjuntos);
    for (int j = 0; j < num_conjuntos; ++j) {
        cache[j].resize(num_vias);
    }

    // Asignar un bloque dinámico a cada vía
    for (int j = 0; j < num_conjuntos; ++j) {
        for (int v = 0; v < num_vias; ++v) {
            cache[j][v].dato = new block_type;
            cache[j][v].validez = false;
            cache[j][v].etiqueta = 0;
            cache[j][v].last_uso = 0;
        }
    }
}


//Las funciones desde aqui se encargan de aplicar la politica LRU 


// Devuelve el índice de la vía menos recientemente usada (LRU)
// dentro del conjunto. Si hay vías inválidas, devuelve la primera de ellas.
int encontrar_via_lru(const tipo_conjunto& conjunto) {      //Devuelve el indice del menos usado 
    int via_lru = 0;
    unsigned long long uso_minimo = conjunto[0].last_uso;
    bool hay_libre = false;
    int primera_libre = -1;

    for (size_t v = 0; v < conjunto.size(); ++v) {
        // Si encontramos una vía libre, la preferimos
        if (!conjunto[v].validez) {
            if (!hay_libre) {
                hay_libre = true;
                primera_libre = v;
            }
        }

        // Buscamos el menor ultimo_uso (solo entre vías válidas)
        if (conjunto[v].validez && conjunto[v].last_uso < uso_minimo) {
            uso_minimo = conjunto[v].last_uso;
            via_lru = v;
        }
    }

    // Si hay una vía libre, la devolvemos
    if (hay_libre) {
        return primera_libre;
    }

    // Si todas están ocupadas, devolvemos la LRU
    return via_lru;
}



void actualizar_lru(tipo_conjunto& conjunto, int via, unsigned long long reloj) {// Marca la vía indicada como la más recientemente usada.
    conjunto[via].last_uso = reloj;
}

// Procesa un acceso a la caché para una etiqueta dada en un conjunto concreto.
// Devuelve:
//    >= 0  -> índice de la vía donde hubo acierto
//    -1    -> hubo fallo, pero se encontró o reemplazó una vía (el índice se devuelve por referencia)
// El parámetro 'via_usada' devuelve la vía que se debe usar (hit o miss).
bool acceder_cache(tipo_conjunto& conjunto, unsigned long long etiqueta_buscada,
    unsigned long long& reloj, int& via_usada) {
    // 1. Buscar en paralelo si hay acierto
    int via_hit = buscar_en_conjunto_paralelo(conjunto, etiqueta_buscada);

    if (via_hit != -1) {
        // ACIERTO: actualizar LRU
        reloj++;
        actualizar_lru(conjunto, via_hit, reloj);
        via_usada = via_hit;
        return true;  // Hit
    }

    // 2. FALLO: buscar vía libre o víctima LRU
    int via_victima = encontrar_via_lru(conjunto);

    // 3. Reemplazar: actualizar etiqueta, validez y LRU
    conjunto[via_victima].etiqueta = etiqueta_buscada;
    conjunto[via_victima].validez = true;

    reloj++;
    actualizar_lru(conjunto, via_victima, reloj);

    via_usada = via_victima;
    return false;  // Miss
}

//Funciones para la simulacion

int Calcular_direccion_bloque(unsigned long long peticion){
    unsigned long long direccion_bloque;
    direccion_bloque=peticion/block_size;
    return direccion_bloque;
}
void etiqueta_indice( int direccion_bloque, int Num_conjuntos, unsigned long long *etiqueta, int *indice){
    *indice= direccion_bloque % Num_conjuntos;
    *etiqueta= direccion_bloque/Num_conjuntos;
}
//Funciones para la interfaz grafica

static_assert(Num_vias % 8 == 0, "TOTAL_LINEAS debe ser multiplo de 8");

// Lee un Linea completa y regresa true si era una linea valida
 bool leer_linea(std::string& linea) {
    return static_cast<bool>(std::getline(std::cin, linea));
}

// Pide las vias hasta recibir 2, 4 u 8. Devuelve 0 si la entrada se cerro.
int pedir_vias() {
    std::string linea;
    while (true) {
        std::cout << "Numero de vias por conjunto (2, 4 u 8): ";
        if (!leer_linea(linea)) return 0;

        std::istringstream ss(linea);
        int vias = 0;
        char sobrante;
        // Valido solo si: se leyo un entero, no sobra texto ("4abc" no vale)
        // y el valor es 2, 4 u 8.
        if ((ss >> vias) && !(ss >> sobrante) &&
            (vias == 2 || vias == 4 || vias == 8||vias == 0))
            return vias;

        std::cout << "Valor no valido.\n";
    }
}

// Pide la cantidad de simulaciones (entero >= 1). Devuelve 0 si la entrada se cerro.
int pedir_simulaciones() {
    std::string linea;
    while (true) {
        std::cout << "Cantidad de simulaciones a realizar (>= 1): ";
        if (!leer_linea(linea)) return 0;

        std::istringstream ss(linea);
        int n = 0;
        char sobrante;
        if ((ss >> n) && !(ss >> sobrante) && n >= 1)
            return n;

        std::cout << "Valor no valido.\n";
    }
}


// Pregunta si se repite. Devuelve false si responde n/N o si la entrada se cerro.
bool preguntar_continuar() {
    std::string linea;
    bool veredicto=true;
    while (true) {
        std::cout << "Hacer otra simulacion? (s/n): ";
        if (!leer_linea(linea)) break;;

        if (linea == "s" || linea == "S") break;;
        if (linea == "n" || linea == "N"){
            veredicto=false;
            break;
            
        };
        std::cout << "Responde s o n.\n";
    }
    return veredicto;
}

// Simulacion
void cargar_bloque(via& v, const block_type::bid_type& bid) {
    assert(v.dato != nullptr);
    esperar_via(v);                 // un buffer, una operacion en vuelo
    v.lectura = v.dato->read(bid);
}

int pedir_patron() {
    std::string linea;
    while (true) {
        std::cout << "Patron de acceso (1=aleatorio, 2=secuencial, 3=coincidencias(varias caidas en un mismo bloque)): ";
        if (!leer_linea(linea)) return 0;

        std::istringstream ss(linea);
        int p = 0;
        char sobrante;
        if ((ss >> p) && !(ss >> sobrante) && p >= 1 && p <= 3)
            return p;

        std::cout << "Valor no valido.\n";
    }
}

// Espera la lectura pendiente de la via (si la hay) y la marca como terminada.
void esperar_via(via& v) {
    if (v.lectura.get() != nullptr) {
        v.lectura->wait();
        v.lectura = nullptr;
    }
}


void simulacion(int vias, int conjuntos, Bids& bids, int iteraciones, int patron)  {
    unsigned long long hits = 0, misses = 0;
    double porcent_hits=0,porcent_miss=0;
    const int PETICIONES = 1000;
    const unsigned long long rango = (unsigned long long)block_size * bids.size() - 1;
    std::mt19937_64 gen(12345);   // semilla fija
    std::uniform_int_distribution<unsigned long long> dist(0, rango);
    for(int i=0;i<iteraciones;i++){
        unsigned long long reloj=0;
        tipo_cache cache;
        inicializar_cache(cache, conjuntos, vias);
        for (int j=0;j<PETICIONES;j++) {
            unsigned long long dir =generar_direccion(patron,j,rango,gen,dist);
            unsigned long long direccion_block = Calcular_direccion_bloque(dir);
            unsigned long long etiqueta;
            int indice, via;
            etiqueta_indice(direccion_block, conjuntos, &etiqueta, &indice);
            if (acceder_cache(cache[indice], etiqueta, reloj, via)) {
                hits++;                       // acierto: no se carga nada
            }else {
                misses++;
                cargar_bloque(cache[indice][via], bids[direccion_block]);

                unsigned long long sig = direccion_block + 1;
                if (sig <= Num_block - 1) {
                    unsigned long long et_sig;
                    int idx_sig, via_sig;
                    etiqueta_indice(sig, conjuntos, &et_sig, &idx_sig);

                    if (buscar_en_conjunto_paralelo(cache[idx_sig], et_sig) == -1) {
                        acceder_cache(cache[idx_sig], et_sig, reloj, via_sig);
                        cargar_bloque(cache[idx_sig][via_sig], bids[sig]);
                    }
                }
            } 
        }
        porcent_hits += (double)hits / PETICIONES;
        porcent_miss += (double)misses / PETICIONES;
        hits = 0;
        misses = 0;
        for (auto& conjunto : cache)
            for (auto& v : conjunto)
                esperar_via(v);
        liberar_cache(cache); 
    }
        ;

    porcent_hits=porcent_hits/iteraciones;
    porcent_miss=porcent_miss/iteraciones;
    std::cout << "Hits: % " << 100.0* porcent_hits << "  Misses: %" <<100.0 * porcent_miss << "\n";
}
    
    
// 1 = aleatorio, 2 = secuencial, 3 = Coincidencias
unsigned long long generar_direccion(int patron, int j, unsigned long long rango,
                                     std::mt19937_64& gen,
                                     std::uniform_int_distribution<unsigned long long>& dist) {
    unsigned long long dir;

    switch (patron) {
    case 2:
        dir = ((unsigned long long)j * 4096ULL) % (rango + 1);
        break;
    case 3:
        dir = ((unsigned long long)(j % 6) * 8ULL) * block_size;
        break;
    default:
        dir = dist(gen);
        break;
    }

    return dir;
}




