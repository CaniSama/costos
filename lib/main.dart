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
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<MiBloc>(
          create: (context) => MiBloc(carrosDatabase),
        ),
        BlocProvider<CategoriaBloc>(
          create: (context) => CategoriaBloc(carrosDatabase),
        ),
        BlocProvider<MovimientoBloc>(
          create: (context) => MovimientoBloc(carrosDatabase),
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
        backgroundColor: const Color.fromARGB(255, 108, 108, 109),
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
        backgroundColor: const Color.fromARGB(255, 108, 108, 109),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
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
        return ListTile(
          title: Text(carro['apodo'] ?? 'No Apodo'),
          
          trailing: Row(
            mainAxisSize: MainAxisSize.min, // Ajusta el tamaño del Row al contenido
            children: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Center(child: Text('¿Eliminar Carro?')),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<MiBloc>().add(EliminarCarro(idCarro: carroID));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Eliminar'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.delete),
                tooltip: 'Borrar',
              ),
              const Padding(padding: EdgeInsets.all(8.0)),
              IconButton(
                onPressed: () {
                  _mostrarModalEditar(context, carro);
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
              ),
              const Padding(padding: EdgeInsets.all(8.0)),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Center(
                            child: archivado == 1
                                ? const Text('¿Archivar Carro?')
                                : const Text('¿Volver a activar?')),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<MiBloc>().add(ArchivarCarro(idcarro: carroID));
                              Navigator.of(context).pop();
                            },
                            child: const Text('Archivar'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.archive),
                tooltip: 'Archivar',
              ),
            ],
          ),
          tileColor: archivado == 1 ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 221, 67, 56),
        );
      },
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
}

class AgregarCarro extends StatefulWidget {
  const AgregarCarro({super.key});

  @override
  State<AgregarCarro> createState() => _AgregarCarroState();
}

class _AgregarCarroState extends State<AgregarCarro> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController apodoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MiBloc, CarroEstado>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nuevo Carro'),
            backgroundColor: const Color.fromARGB(255, 108, 108, 109),
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
                    ElevatedButton(
                      onPressed: () {
                        _insertarCarro(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 54, 120, 243)                
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
        backgroundColor: const Color.fromARGB(255, 108, 108, 109), // Color para identificar la edición
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un apodo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: () {
                  _actualizarCarro(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 54, 120, 243) 
                ),
                child: const Text('Actualizar Carro'),
              ),
            ],
          ),
        ),
      ),
    );
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
      Navigator.of(context)
          .pop(); // Cierra el modal después de la actualización
    }
  }
}

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
        return ListTile(
          title: Text(categoria['nombrecategoria'] ?? 'No hay nombre'),
          tileColor: archivado == 1 ? Colors.white : Colors.red,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Center(
                          child: Text('¿Eliminar Categoria?'),
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
                                    EliminarCategoria(idcategoria: categoriaID),
                                  );
                              Navigator.of(context).pop();
                            },
                            child: const Text('Eliminar'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.delete),
                tooltip: 'Borrar',
              ),
              const Padding(padding: EdgeInsets.all(8.0)),
              IconButton(
                onPressed: () {
                  _mostrarModalEditarCategoria(context, categoria);
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
              ),
              const Padding(padding: EdgeInsets.all(8.0)),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Center(
                          child: archivado == 1
                              ? const Text('¿Archivar Categoria?')
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
                                    ArchivarCategoria(idcategoria: categoriaID),
                                  );
                              Navigator.of(context).pop();
                            },
                            child: const Text('Archivar'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.archive),
                tooltip: 'Archivar',
              ),
            ],
          ),
        );
      },
    );
  } else {
    return const Center(child: Text('No hay categorias disponibles'));
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriaBloc, CategoriaEstado>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nueva Categoria'),
            backgroundColor: const Color.fromARGB(255, 108, 108, 109),
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
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese un nombre para la categoria';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),
                    ElevatedButton(
                      onPressed: () {
                        _insertarCategoria(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 54, 120, 243) 
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

// Agrega un nuevo método para mostrar el modal de edición
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

// Crea un nuevo widget para la edición del carro
class EditarCategoria extends StatefulWidget {
  final Map<String, dynamic> categoria;

  const EditarCategoria({super.key, required this.categoria});

  @override
  State<EditarCategoria> createState() => _EditarCategoriaState();
}

class _EditarCategoriaState extends State<EditarCategoria> {
  late TextEditingController nombreController;

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
        backgroundColor: const Color.fromARGB(255, 108, 108, 109), // Color para identificar la edición
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
                  labelText: 'Apodo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un nombre de categoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: () {
                  _actualizarCategoria(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 54, 120, 243) 
                ),
                child: const Text('Actualizar Categoria'),
              ),
            ],
          ),
        ),
      ),
    );
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
      Navigator.of(context)
          .pop(); // Cierra el modal después de la actualización
    }
  }
}

class ListaMovimientos extends StatefulWidget {
  const ListaMovimientos({Key? key}) : super(key: key);

  @override
  _ListaMovimientosState createState() => _ListaMovimientosState();
}

class _ListaMovimientosState extends State<ListaMovimientos> {
  final TextEditingController _filtroController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 158, 158, 156),
        title: const Text('Lista de Movimientos'),
        actions: [
          IconButton(
            onPressed: () {
              _mostrarFiltroDialog(context);
            },
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: BlocBuilder<MovimientoBloc, MovimientoEstado>(
        builder: (context, state) {
          if (state is GetAllMovimientos) {
            List<Map<String, dynamic>> movimientos = state.movimientos;
            if (_filtroController.text.isNotEmpty) {
              movimientos = _filtrarMovimientos(movimientos);
            }
            return _listaMovimientos(movimientos);
          } else if (state is ErrorGetAllMovimientos) {
            return Center(child: Text('Error: ${state.mensajeError}'));
          } else {
            return Center(child: Text('${state.mensajeError}'));
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

Widget _listaMovimientos(List<Map<String, dynamic>> movimientos) {
  if (movimientos.isNotEmpty) {
    return ListView.builder(
      itemCount: movimientos.length,
      itemBuilder: (context, index) {
        final movimiento = movimientos[index];
        int movimientoID = movimiento['idmovimiento'];
        int gastototal = movimiento['gastototal'] ?? 0; // Obtener el monto del gasto
        return ListTile(
          title: Text(movimiento['nombremovimiento'] ?? 'No hay nombre'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gasto: \$${gastototal.toString()}'),
              
            ],
          ), // Subtítulo para mostrar el monto
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                                    EliminarMovimiento(idmovimiento: movimientoID),
                                  );
                              Navigator.of(context).pop();
                            },
                            child: const Text('Eliminar'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.delete),
                tooltip: 'Borrar',
              ),
              const Padding(padding: EdgeInsets.all(8.0)),
              IconButton(
                onPressed: () {
                  _mostrarModalEditarMovimiento(context, movimiento);
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
              ),
            ],
          ),
          
        );
      },
    );
  } else {
    return const Center(child: Text('No hay gastos disponibles'));
  }
}


  List<Map<String, dynamic>> _filtrarMovimientos(List<Map<String, dynamic>> movimientos) {
    String filtro = _filtroController.text.toLowerCase();
    return movimientos.where((movimiento) {
      return movimiento['nombremovimiento'].toString().toLowerCase().contains(filtro);
    }).toList();
  }

  void _mostrarFiltroDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtrar Movimientos'),
          content: TextField(
            controller: _filtroController,
            decoration: const InputDecoration(labelText: 'Ingrese el filtro'),
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
                // Puedes aplicar el filtro aquí si lo deseas
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
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
        backgroundColor: const Color.fromARGB(255, 108, 108, 109),
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
                ),
                const SizedBox(height: 10.0),
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
                            child: SizedBox(
                              width: 200.0, // Ajusta el ancho del dropdown según tus necesidades
                              child: Text(
                                carro['apodo'].toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                            child: SizedBox(
                              width: 200.0, // Ajusta el ancho del dropdown según tus necesidades
                              child: Text(
                                categoria['nombrecategoria'].toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
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
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: const Color.fromARGB(255, 54, 120, 243),

                  ),
                  child: Text(
                    'Seleccionar fecha: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
                const SizedBox(height: 16.0), // Agrega más espacio entre los botones
                ElevatedButton(
                  onPressed: () {
                    _insertarMovimiento(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 54, 120, 243),
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

// Agrega un nuevo método para mostrar el modal de edición
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

// Crea un nuevo widget para la edición del carro
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
    selectedFecha = DateTime.parse(
        fechaDB); // Asigna la fecha de la base de datos a selectedDate // Añadir este print para verificar el valor de selectedDate
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Gasto'),
         backgroundColor: const Color.fromARGB(255, 158, 158, 156),
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
              ),
              const SizedBox(height: 10.0),
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
                          child: Text(categoria['nombrecategoria'].toString()),
                        );
                      }).toList(),
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
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
                 style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 54, 120, 243) 
                ),
                onPressed: () => _selectDate(context),
                
                child: Text(
                    'Seleccionar fecha: ${DateFormat('yyyy-MM-dd').format(selectedFecha)}'),
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: () {
                  _actualizarMovimiento(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 54, 120, 243) 
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