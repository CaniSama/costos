import 'package:costos/bloc/bloc.dart';
import 'package:costos/database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final carrosDatabase = CarrosDatabase();
  await carrosDatabase.initializeDatabase();
  runApp(
    BlocProvider(
    create: (context) => MiBloc(carrosDatabase),
    child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: MainApp()),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<MiBloc>(context).add(Inicializado());
    BlocProvider.of<MiBloc>(context).add(TraerTodosLosCarros());
  }

  int _indiceSeleccionado = 0;

  final List<Widget> _paginas = [
    const ListaCarros(),
    const ListaGastos(),
    const ListaCategorias(),
    
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Control de Gastos Vehicular')),
        backgroundColor:  const Color.fromARGB(255, 136, 134, 136),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: (){
              _borrarTablaCarros(context);
            }, 
          ),
        ],
      ),
      body: _paginas[_indiceSeleccionado],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.car_crash),
            label: 'Carros',
          ),
            BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on_rounded),
            label: 'Gastos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorias',
          ),
        ],
        currentIndex: _indiceSeleccionado,
        onTap: _onTabTapped,
        backgroundColor: const Color.fromARGB(255, 136, 134, 136),
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color.fromARGB(255, 26, 25, 25),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _indiceSeleccionado = index;
    });
  }
}

void _borrarTablaCarros(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: const Text('¿Estás seguro de que quieres borrar todos los datos?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _borrarDatos(context);
                Navigator.of(context).pop();
              },
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
  }

void _borrarDatos(BuildContext context) {
    final miBloc = BlocProvider.of<MiBloc>(context);
    miBloc.add(BorrarTodosLosCarros());
  }

class ListaCarros extends StatelessWidget {
  const ListaCarros({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MiBloc, Estado>(
        builder: (context, state) {
          print("Current state: $state");
          if (state is TodosLosCarrosCargados) {
            return _listaCarros(state.carros);
          } else if (state is ErrorTraerCarros) {
            return Center(child: Text('Error: ${state.mensajeError}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarModal(context, 'Nuevo Carro');
        },
        backgroundColor: const Color.fromARGB(255, 55, 139, 58),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _listaCarros(List<Map<String, dynamic>>? carros) {
    if (carros != null) {
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: carros.length,
              itemBuilder: (context, index) {
                final carro = carros[index];
                return ListTile(
                  title: Text(carro['APODO'] ?? 'No Apodo'),
                  subtitle: Text(
                    '${carro['MARCA'] ?? 'No Marca'} ${carro['MODELO'] ?? 'No Modelo'} (${carro['ANIO'] ?? 'No Año'})',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _eliminarCarro(context, carro['ID']);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      return const Center(child: Text('No hay carros disponibles'));
    }
  }

  void _mostrarModal(BuildContext context, String carros) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return const FractionallySizedBox(
          heightFactor: 1.2,
          child: AgregarCarro(),
        );
      },
    );
  }

  void _eliminarCarro(BuildContext context, int carroId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: const Text('¿Estás seguro de que quieres eliminar este carro?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _borrarCarro(context, carroId);
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _borrarCarro(BuildContext context, int carroId) {
    final miBloc = BlocProvider.of<MiBloc>(context);
    miBloc.add(EliminarCarro(idCarro: carroId));
  }
}

class AgregarCarro extends StatefulWidget {
  const AgregarCarro({super.key});

  @override
  State<AgregarCarro> createState() => _AgregarCarroState();
}

class _AgregarCarroState extends State<AgregarCarro> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController apodoController = TextEditingController();
  TextEditingController modeloController = TextEditingController();
  TextEditingController marcaController = TextEditingController();
  TextEditingController anioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MiBloc, Estado>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nuevo Carro'),
            backgroundColor: const Color.fromARGB(255, 136, 134, 136),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: apodoController,
                      decoration: InputDecoration(
                        labelText: 'Apodo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese un apodo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      controller: modeloController,
                      decoration: InputDecoration(
                        labelText: 'Modelo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese un modelo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      controller: marcaController,
                      decoration: InputDecoration(
                        labelText: 'Marca',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese una marca';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      controller: anioController,
                      decoration: InputDecoration(
                        labelText: 'Año',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese un año';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),
                    ElevatedButton(
                      onPressed: () {
                        _insertarCarro(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 60, 39, 176),
                      ),
                      child: const Text('Insertar Carro'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _insertarCarro(BuildContext context) {
    final miBloc = BlocProvider.of<MiBloc>(context);

    if(_formKey.currentState?.validate() ?? false){
      miBloc.add(
      InsertarCarro(
        apodo: apodoController.text,
      ),
    );
  }
 }  
}   

class ListaCategorias  extends StatelessWidget {
  const ListaCategorias ({super.key});
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class ListaGastos  extends StatelessWidget {
  const ListaGastos ({super.key});
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}