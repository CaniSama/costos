import 'package:costos/bloc/bloc.dart';
import 'package:costos/bloc/categoriasbloc.dart';
import 'package:costos/bloc/movimientosbloc.dart';
import 'package:costos/database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final carrosDatabase = CarrosDatabase();
  await carrosDatabase.initializeDatabase();
  final categoriaBlocInstance = CategoriaBloc(carrosDatabase);
  final carroBlocInstance = MiBloc(carrosDatabase);
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<MiBloc>(
          create: (context) => carroBlocInstance,
        ),
        BlocProvider<CategoriaBloc>(
          create: (context) => categoriaBlocInstance,
        ),
        BlocProvider<MovimientoBloc>(
          create: (context) => MovimientoBloc(
              carrosDatabase, categoriaBlocInstance, carroBlocInstance),
        ),
      ],
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
    //CARROS
    BlocProvider.of<MiBloc>(context).add(Inicializado());
    BlocProvider.of<MiBloc>(context).add(GetCarros());
    //CATEGORIAS
    BlocProvider.of<CategoriaBloc>(context).add(CategoriaInicializada());
    BlocProvider.of<CategoriaBloc>(context).add(GetCategorias());
    //MOVIMIENTOS
    BlocProvider.of<MovimientoBloc>(context).add(MovimientoInicializado());
    BlocProvider.of<MovimientoBloc>(context).add(GetMovimientos());
  }

  int _indiceSeleccionado = 0;

  final List<Widget> _paginas = [
    const ListaCarros(),
    const ListaCategorias(),
    const ListaMovimientos(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Control de Gastos Vehicular')),
        backgroundColor: const Color.fromARGB(255, 122, 125, 139),
        actions: const [],
      ),
      body: BlocBuilder<MiBloc, CarroEstado>(
        builder: (context, state) {
          return _paginas[_indiceSeleccionado];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.car_crash_outlined),
            label: 'Carros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Gastos',
          )
        ],
        currentIndex: _indiceSeleccionado,
        onTap: _onTabTapped,
        backgroundColor: const Color.fromARGB(255, 122, 125, 139),
        selectedItemColor: Colors.white,
        
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _indiceSeleccionado = index;
    });
  }
}

class ListaCarros extends StatelessWidget {
  const ListaCarros({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MiBloc, CarroEstado>(
        builder: (context, state) {
          if (state is GetAllCarros) {
            return _listaCarros(state.carros);
          } else if (state is ErrorGetAllCarros) {
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
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

Widget _listaCarros(List<Map<String, dynamic>>? carros) {
  if (carros != null && carros.isNotEmpty) {
    return ListView.builder(
      itemCount: carros.length,
      itemBuilder: (context, index) {
        final carro = carros[index];
        int carroID = carros[index]['idcarro'];
        int archivado = carros[index]['archivado'];
        int totalGasto = carro['totalgasto'] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 2,
          color: archivado == 1 ? Colors.white : const Color.fromARGB(255, 184, 178, 178),
          child: ListTile(
            title: Text(
              carro['apodo'] ?? 'No Apodo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: archivado == 1 ? Colors.black : Colors.white,
              ),
            ),
            subtitle: Text(
              'Gasto Total: $totalGasto',
              style: TextStyle(
                fontSize: 14,
                color: archivado == 1 ? Colors.black : Colors.white,
              ),
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  onPressed: () {
                    archivado == 1
                        ? _mostrarModalEditar(context, carro)
                        : null;
                  },
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Center(
                            child: archivado == 1
                                ? const Text('¿Archivar Carro?')
                                : const Text('¿Volver a activar?'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                context
                                    .read<MiBloc>()
                                    .add(ArchivarCarro(idcarro: carroID));
                                Navigator.of(context).pop();
                              },
                              child: const Text('Archivar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.archive, color: Colors.red),
                  tooltip: 'Archivar',
                ),
              ],
            ),
          ),
        );
      },
    );
  } else {
    return const Center(
      child: Text(
        'No hay carros disponibles',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
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
}

class AgregarCarro extends StatefulWidget {
  const AgregarCarro({super.key});

  @override
  State<AgregarCarro> createState() => _AgregarCarroState();
}

class _AgregarCarroState extends State<AgregarCarro> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController apodoController = TextEditingController();
  bool isButtonDisabled = true;
  String? errorText;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MiBloc, CarroEstado>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nuevo Carro'),
            backgroundColor: const Color.fromARGB(255, 19, 121, 73),
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
                        errorText: errorText,
                      ),
                      onChanged: (value) {
                        setState(() {
                          isButtonDisabled = value.isEmpty ||
                              containsSpecialCharacters(value) ||
                              !containsLetter(value);

                          // Actualizar el mensaje de error
                          if (value.isEmpty) {
                            errorText = 'Por favor, ingrese un apodo';
                          } else if (containsSpecialCharacters(value)) {
                            errorText = 'No se permiten caracteres especiales';
                          } else if (!containsLetter(value)) {
                            errorText = 'Debe contener al menos una letra';
                          } else {
                            errorText = null; // No hay error
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese un apodo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),
                    ElevatedButton(
                      onPressed: isButtonDisabled
                          ? null
                          : () {
                              _insertarCarro(context);
                              Navigator.of(context).pop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 44, 47, 219),
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

  bool containsSpecialCharacters(String value) {
    final specialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    return specialCharacters.hasMatch(value);
  }

  bool containsLetter(String value) {
    final letterRegex = RegExp(r'[a-zA-Z]');
    return letterRegex.hasMatch(value);
  }

  void _insertarCarro(BuildContext context) {
    final miBloc = BlocProvider.of<MiBloc>(context);

    if (_formKey.currentState?.validate() ?? false) {
      miBloc.add(
        InsertarCarro(
          apodo: apodoController.text,
        ),
      );
    }
  }
}



// Agrega un nuevo método para mostrar el modal de edición
void _mostrarModalEditar(BuildContext context, Map<String, dynamic> carro) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 1.2,
        child: EditarCarro(carro: carro),
      );
    },
  );
}

// Crea un nuevo widget para la edición del carro
class EditarCarro extends StatefulWidget {
  final Map<String, dynamic> carro;

  const EditarCarro({super.key, required this.carro});

  @override
  State<EditarCarro> createState() => _EditarCarroState();
}

class _EditarCarroState extends State<EditarCarro> {
  late TextEditingController apodoController;
  bool isButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    apodoController = TextEditingController(text: widget.carro['apodo']);
    // Agrega inicializaciones de otros campos si es necesario
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Carro'),
        backgroundColor: const Color.fromARGB(255, 56, 92, 153),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                  errorText: _validateApodo(apodoController.text),
                ),
                onChanged: (value) {
                  setState(() {
                    isButtonDisabled = _validateApodo(value) != null;
                  });
                },
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: isButtonDisabled
                    ? null
                    : () {
                        _actualizarCarro(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 44, 47, 219),
                ),
                child: const Text('Actualizar Carro'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateApodo(String value) {
    if (value.isEmpty) {
      return 'Por favor, ingrese un apodo';
    } else if (containsSpecialCharacters(value)) {
      return 'No se permiten caracteres especiales';
    }
    return null;
  }

  bool containsSpecialCharacters(String value) {
    final specialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    return specialCharacters.hasMatch(value);
  }

  void _actualizarCarro(BuildContext context) {
    final miBloc = BlocProvider.of<MiBloc>(context);

    if (apodoController.text.isNotEmpty) {
      miBloc.add(
        UpdateCarro(
          apodo: apodoController.text,
          idcarro: widget.carro['idcarro'],
        ),
      );
      Navigator.of(context).pop(); // Cierra el modal después de la actualización
    }
  }
}

//CATEGORIAS

class ListaCategorias extends StatelessWidget {
  const ListaCategorias({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CategoriaBloc, CategoriaEstado>(
        builder: (context, state) {
          if (state is GetAllCategorias) {
            return _listaCategorias(state.categorias);
          } else if (state is ErrorGetAllCategorias) {
            return Center(child: Text('Error: ${state.mensajeError}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarModal(context, 'Nueva Categoria');
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

Widget _listaCategorias(List<Map<String, dynamic>>? categorias) {
  if (categorias != null && categorias.isNotEmpty) {
    return ListView.builder(
      itemCount: categorias.length,
      itemBuilder: (context, index) {
        final categoria = categorias[index];
        int categoriaID = categorias[index]['idcategoria'];
        int archivado = categorias[index]['archivado'];
        int totalGasto = categoria['totalgasto'] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 2,
          color: archivado == 1 ? Colors.white : const Color.fromARGB(255, 184, 178, 178),
          child: ListTile(
            title: Text(
              categoria['nombrecategoria'] ?? 'No hay nombre',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: archivado == 1 ? Colors.black : Colors.white,
              ),
            ),
            subtitle: Text(
              'Gasto Total: $totalGasto',
              style: TextStyle(
                fontSize: 14,
                color: archivado == 1 ? Colors.black : Colors.white,
              ),
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  onPressed: () {
                    _mostrarModalEditarCategoria(context, categoria);
                  },
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Center(
                            child: archivado == 1
                                ? const Text('¿Archivar Categoría?')
                                : const Text('¿Volver a activar?'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<CategoriaBloc>().add(
                                    ArchivarCategoria(
                                        idcategoria: categoriaID));
                                Navigator.of(context).pop();
                              },
                              child: const Text('Archivar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.archive, color: Colors.red),
                  tooltip: 'Archivar',
                ),
              ],
            ),
          ),
        );
      },
    );
  } else {
    return const Center(
      child: Text(
        'No hay categorías disponibles',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}



  void _mostrarModal(BuildContext context, String categorias) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return const FractionallySizedBox(
          heightFactor: 1.2,
          child: AgregarCategoria(),
        );
      },
    );
  }
}

class AgregarCategoria extends StatefulWidget {
  const AgregarCategoria({super.key});

  @override
  State<AgregarCategoria> createState() => _AgregarCategoriaState();
}

class _AgregarCategoriaState extends State<AgregarCategoria> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nombreController = TextEditingController();
  bool isButtonDisabled = true;
  String? errorText;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriaBloc, CategoriaEstado>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nueva Categoria'),
            backgroundColor: const Color.fromARGB(255, 19, 121, 73),
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
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre Categoria',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        errorText: errorText,
                      ),
                      onChanged: (value) {
                        setState(() {
                          isButtonDisabled = value.isEmpty ||
                              containsSpecialCharacters(value) ||
                              !containsLetter(value);
                          // Actualizar el mensaje de error
                          errorText = value.isEmpty
                              ? 'Por favor, ingrese un nombre para la categoria'
                              : null;
                          if (containsSpecialCharacters(value)) {
                            errorText = 'No se permiten caracteres especiales';
                          } else if (!containsLetter(value)) {
                            errorText = 'Debe contener al menos una letra';
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese un nombre para la categoria';
                        } else if (containsSpecialCharacters(value)) {
                          return 'No se permiten caracteres especiales';
                        } else if (!containsLetter(value)) {
                          return 'Debe contener al menos una letra';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),
                    ElevatedButton(
                      onPressed: isButtonDisabled
                          ? null
                          : () {
                              _insertarCategoria(context);
                              Navigator.of(context).pop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 44, 47, 219),
                      ),
                      child: const Text('Insertar Categoria'),
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

  bool containsSpecialCharacters(String value) {
    final specialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    return specialCharacters.hasMatch(value);
  }

  bool containsLetter(String value) {
    final letterRegex = RegExp(r'[a-zA-Z]');
    return letterRegex.hasMatch(value);
  }

  void _insertarCategoria(BuildContext context) {
    final miBloc = BlocProvider.of<CategoriaBloc>(context);

    if (_formKey.currentState?.validate() ?? false) {
      miBloc.add(
        InsertarCategoria(
          nombrecategoria: nombreController.text,
        ),
      );
    }
  }
}


void _mostrarModalEditarCategoria(
    BuildContext context, Map<String, dynamic> categoria) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 1.2,
        child: EditarCategoria(categoria: categoria),
      );
    },
  );
}

class EditarCategoria extends StatefulWidget {
  final Map<String, dynamic> categoria;

  const EditarCategoria({super.key, required this.categoria});

  @override
  State<EditarCategoria> createState() => _EditarCategoriaState();
}

class _EditarCategoriaState extends State<EditarCategoria> {
  late TextEditingController nombreController;
  bool isButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    nombreController =
        TextEditingController(text: widget.categoria['nombrecategoria']);
    // Agrega inicializaciones de otros campos si es necesario
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Categoria'),
        backgroundColor: const Color.fromARGB(255, 56, 92, 153),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de Categoria',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  errorText: _validateNombre(nombreController.text),
                ),
                onChanged: (value) {
                  setState(() {
                    isButtonDisabled = _validateNombre(value) != null;
                  });
                },
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: isButtonDisabled
                    ? null
                    : () {
                        _actualizarCategoria(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 44, 47, 219),
                ),
                child: const Text('Actualizar Categoria'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateNombre(String value) {
    if (value.isEmpty) {
      return 'Por favor, ingrese un nombre de categoria';
    } else if (containsSpecialCharacters(value)) {
      return 'No se permiten caracteres especiales';
    }
    return null;
  }

  bool containsSpecialCharacters(String value) {
    final specialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    return specialCharacters.hasMatch(value);
  }

  void _actualizarCategoria(BuildContext context) {
    final miBloc = BlocProvider.of<CategoriaBloc>(context);

    if (nombreController.text.isNotEmpty) {
      miBloc.add(
        UpdateCategoria(
          nombrecategoria: nombreController.text,
          idcategoria: widget.categoria['idcategoria'],
        ),
      );
      Navigator.of(context).pop(); // Cierra el modal después de la actualización
    }
  }
}

//GASTOS

class ListaMovimientos extends StatefulWidget {
  const ListaMovimientos({super.key});

  @override
  State<ListaMovimientos> createState() => _ListaMovimientosState();
}

class _ListaMovimientosState extends State<ListaMovimientos> {

  TextEditingController barraBusqueda = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MovimientoBloc, MovimientoEstado>(
        builder: (context, state) {
          if (state is GetAllMovimientos) {
            List<Map<String, dynamic>> gastosFiltrados = state.movimientos
                .where((movimiento) =>
                    movimiento['nombremovimiento']!
                        .toLowerCase()
                        .contains(barraBusqueda.text.toLowerCase()) ||
                    movimiento['apodo']!
                        .toLowerCase()
                        .contains(barraBusqueda.text.toLowerCase()) ||
                    movimiento['nombrecategoria']!
                        .toLowerCase()
                        .contains(barraBusqueda.text.toLowerCase()) ||
                    movimiento['fechagasto']!
                        .toLowerCase()
                        .contains(barraBusqueda.text.toLowerCase()))
                .toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: barraBusqueda,
                    decoration: InputDecoration(
                      labelText: 'Buscar',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: _listaMovimientos(gastosFiltrados),
                ),
              ],
            );
          } else if (state is ErrorGetAllMovimientos) {
            return Center(child: Text('Error: ${state.mensajeError}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarModal(context, 'Nuevo Movimiento');
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

Widget _listaMovimientos(List<Map<String, dynamic>>? movimientos) {
  
  if (movimientos != null && movimientos.isNotEmpty) {
    return ListView.builder(
      itemCount: movimientos.length,
      itemBuilder: (context, index) {
        final movimiento = movimientos[index];
        int movimientoID = movimientos[index]['idmovimiento'];
        final gastototal = movimiento['gastototal'].toString();
        final fechagasto = movimiento['fechagasto'];
        String idcarro = movimiento['apodo'];
        String idcategoria = movimiento['nombrecategoria'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 2,
          child: ListTile(
            title: Text(
              movimiento['nombremovimiento'] ?? 'No hay nombre',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
              subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asociado a: $idcarro'),
                Text('categoría: $idcategoria'),
                Text('Gasto: $gastototal'),
                Text('Fecha del gasto: $fechagasto'),
              ],
            ),
             trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  onPressed: () {
                    _mostrarModalEditarMovimiento(context, movimiento);
                  },
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Editar',
                ),
                 IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Center(
                            child: Text('¿Eliminar Movimiento?'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<MovimientoBloc>().add(
                                    EliminarMovimiento(
                                        idmovimiento: movimientoID));
                                Navigator.of(context).pop();
                              },
                              child: const Text('Eliminar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Borrar',
                ),
              ],
            ),
          ),
        );
      },
    );
  } else {
    return const Center(
      child: Text(
        'No hay gastos disponibles',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

  void _mostrarModal(BuildContext context, String movimiento) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return const FractionallySizedBox(
          heightFactor: 1.2,
          child: AgregarMovimiento(),
        );
      },
    );
  }


class AgregarMovimiento extends StatefulWidget {
  const AgregarMovimiento({super.key});

  @override
  State<AgregarMovimiento> createState() => _AgregarMovimientoState();
}

class _AgregarMovimientoState extends State<AgregarMovimiento> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nombreController = TextEditingController();
  int carroSeleccionado = 1;
  int categoriaSeleccionada = 1;
  TextEditingController gastosController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isButtonDisabled = true;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now()
          .subtract(const Duration(days: 365)), // Restringe un año hacia atrás
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Gasto'),
        backgroundColor: const Color.fromARGB(255, 19, 121, 73),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    BlocBuilder<MiBloc, CarroEstado>(
                      builder: (context, carroState) {
                        if (carroState is GetAllCarros) {
                          List<Map<String, dynamic>> carros = carroState.carros;
                          return DropdownButton<int>(
                            onChanged: (newValue) {
                              setState(() {
                                carroSeleccionado = newValue!;
                              });
                            },
                            value: carroSeleccionado, // Valor seleccionado
                            items: carros.map((carro) {
                              return DropdownMenuItem<int>(
                                value: carro['idcarro'],
                                child: Text(carro['apodo'].toString()),
                              );
                            }).toList(),
                          );
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    ),
                    BlocBuilder<CategoriaBloc, CategoriaEstado>(
                      builder: (context, categoriaState) {
                        if (categoriaState is GetAllCategorias) {
                          List<Map<String, dynamic>> categorias =
                              categoriaState.categorias;

                          return DropdownButton<int>(
                            value: categoriaSeleccionada,
                            onChanged: (newValue) {
                              setState(() {
                                categoriaSeleccionada = newValue!;
                              });
                            },
                            items: categorias.map((categoria) {
                              return DropdownMenuItem<int>(
                                value: categoria['idcategoria'],
                                child: Text(
                                    categoria['nombrecategoria'].toString()),
                              );
                            }).toList(),
                          );
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                TextFormField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Concepto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorText: isButtonDisabled
                        ? 'Por favor, ingrese un nombre para el gasto'
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      isButtonDisabled = value.isEmpty ||
                          !containsLetter(value) ||
                          value.trimLeft() != value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese un nombre para el gasto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10.0),
                TextFormField(
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  controller: gastosController,
                  decoration: InputDecoration(
                    labelText: 'Total del gasto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese una cantidad';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                      'Seleccionar fecha: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                ),
                const SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: isButtonDisabled
                      ? null
                      : () {
                          _insertarMovimiento(context);
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 44, 47, 219),
                  ),
                  child: const Text('Insertar Gasto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool containsLetter(String value) {
    final letterRegex = RegExp(r'[a-zA-Z]');
    return letterRegex.hasMatch(value);
  }

  void _insertarMovimiento(BuildContext context) {
    final miBloc = BlocProvider.of<MovimientoBloc>(context);
    int numeroIngresado = int.tryParse(gastosController.text)!;
    String fechaSeleccionada =
        DateFormat('yyyy-MM-dd').format(selectedDate).toString();

    if (_formKey.currentState?.validate() ?? false) {
      miBloc.add(
        InsertarMovimiento(
          nombremovimiento: nombreController.text,
          idcarro: carroSeleccionado,
          idcategoria: categoriaSeleccionada,
          gastototal: numeroIngresado,
          fechagasto: fechaSeleccionada,
        ),
      );
    }
  }
}


void _mostrarModalEditarMovimiento(
    BuildContext context, Map<String, dynamic> movimiento) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 1.2,
        child: EditarMovimiento(movimiento: movimiento),
      );
    },
  );
}

class EditarMovimiento extends StatefulWidget {
  final Map<String, dynamic> movimiento;

  const EditarMovimiento({super.key, required this.movimiento});

  @override
  State<EditarMovimiento> createState() => _EditarMovimientoState();
}

class _EditarMovimientoState extends State<EditarMovimiento> {
  TextEditingController nombreController = TextEditingController();
  int carroSeleccionado = 1;
  int categoriaSeleccionada = 1;
  TextEditingController gastosController = TextEditingController();
  DateTime selectedFecha = DateTime.now();
  bool isButtonDisabled = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedFecha,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedFecha) {
      setState(() {
        selectedFecha = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    nombreController.text = widget.movimiento['nombremovimiento'];
    carroSeleccionado = widget.movimiento['idcarro'];
    categoriaSeleccionada = widget.movimiento['idcategoria'];
    gastosController.text = widget.movimiento['gastototal'].toString();
    String fechaDB = widget.movimiento['fechagasto'];
    selectedFecha = DateTime.parse(fechaDB);
    print(selectedFecha);
    _validateFields();
  }

  void _validateFields() {
    setState(() {
      isButtonDisabled =
          nombreController.text.isEmpty || gastosController.text.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Gasto'),
        backgroundColor: const Color.fromARGB(255, 56, 92, 153),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  BlocBuilder<MiBloc, CarroEstado>(
                    builder: (context, carroState) {
                      if (carroState is GetAllCarros) {
                        List<Map<String, dynamic>> carros = carroState.carros;

                        return DropdownButton<int>(
                          onChanged: (newValue) {
                            setState(() {
                              carroSeleccionado = newValue!;
                            });
                          },
                          value: carroSeleccionado,
                          items: carros.map((carro) {
                            return DropdownMenuItem<int>(
                              value: carro['idcarro'],
                              child: Text(carro['apodo'].toString()),
                            );
                          }).toList(),
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                  const SizedBox(height: 10.0),
                  BlocBuilder<CategoriaBloc, CategoriaEstado>(
                    builder: (context, categoriaState) {
                      if (categoriaState is GetAllCategorias) {
                        List<Map<String, dynamic>> categorias =
                            categoriaState.categorias;

                        return DropdownButton<int>(
                          value: categoriaSeleccionada,
                          onChanged: (newValue) {
                            setState(() {
                              categoriaSeleccionada = newValue!;
                            });
                          },
                          items: categorias.map((categoria) {
                            return DropdownMenuItem<int>(
                              value: categoria['idcategoria'],
                              child:
                                  Text(categoria['nombrecategoria'].toString()),
                            );
                          }).toList(),
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              TextFormField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre Gasto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un nombre para el gasto';
                  }
                  return null;
                },
                onChanged: (_) {
                  _validateFields();
                },
              ),
              const SizedBox(height: 10.0),
              TextFormField(
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                controller: gastosController,
                decoration: InputDecoration(
                  labelText: 'Total del gasto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese una cantidad';
                  }
                  return null;
                },
                onChanged: (_) {
                  _validateFields();
                },
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text(
                    'Seleccionar fecha: ${DateFormat('yyyy-MM-dd').format(selectedFecha)}'),
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: isButtonDisabled
                    ? null
                    : () {
                        _actualizarMovimiento(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 44, 47, 219),
                ),
                child: const Text('Actualizar Gasto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _actualizarMovimiento(BuildContext context) {
    final miBloc = BlocProvider.of<MovimientoBloc>(context);
    int numeroIngresado = int.tryParse(gastosController.text)!;
    String fechaSeleccionada =
        DateFormat('yyyy-MM-dd').format(selectedFecha).toString();

    if (nombreController.text.isNotEmpty) {
      miBloc.add(
        UpdateMovimiento(
          nombremovimiento: nombreController.text,
          idcarro: carroSeleccionado,
          idcategoria: categoriaSeleccionada,
          gastototal: numeroIngresado,
          fechagasto: fechaSeleccionada,
          idmovimiento: widget.movimiento['idmovimiento'],
        ),
      );
      Navigator.of(context)
          .pop(); // Cierra el modal después de la actualización
    }
  }
}
