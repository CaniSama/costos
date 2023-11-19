import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

late Database db;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfiWeb;
  String databasePath = '${await databaseFactory.getDatabasesPath()}/base.db';
  db = await databaseFactory.openDatabase(
    databasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE PERSONAS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NOMBRE TEXT(35));',
        );
      },
    ),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('costitos v1.1'),
        ),
        body: const Mio(),
      ),
    );
  }
}

class Mio extends StatefulWidget {
  const Mio({Key? key}) : super(key: key);

  @override
  State<Mio> createState() => _MioState();
}

class _MioState extends State<Mio> {
  String? itemSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _getAllNames(),
              builder: ((context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var lista = snapshot.data!;
                return ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(lista[index]),
                      tileColor:
                          itemSeleccionado == lista[index] ? Colors.grey : null,
                      onTap: () {
                        setState(() {
                          itemSeleccionado = lista[index];
                        });
                      },
                      onLongPress: () {
                        _showDeleteConfirmationModal(context, lista[index]);
                      },
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPersonModal(context);
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _showAddPersonModal(BuildContext context) async {
    String newName = '';
    bool containsSpecialCharacters = false;

    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        // Validar que no sea un espacio en blanco o caracteres especiales
                        if (value.isNotEmpty &&
                            !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                          // Si hay caracteres especiales o espacio, eliminarlos
                          newName = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
                          containsSpecialCharacters = true;
                        } else {
                          newName = value;
                          containsSpecialCharacters = false;
                        }
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  if (containsSpecialCharacters)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: RichText(
                        text: const TextSpan(
                          text: 'No se admiten caracteres especiales',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: newName.trim().isNotEmpty && !containsSpecialCharacters
                        ? () {
                            Navigator.pop(context); // Cerrar el modal
                            _addPerson(newName);
                          }
                        : null,
                    child: const Text('Agregar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationModal(
      BuildContext context, String itemName) async {
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Eliminar $itemName?'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar el modal
                  _deletePerson(itemName);
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addPerson(String name) async {
    await db.rawInsert('INSERT INTO PERSONAS (NOMBRE) VALUES(?)', [name]);
    _updateList();
  }

  void _deletePerson(String name) async {
    await db.rawDelete('DELETE FROM PERSONAS WHERE NOMBRE = ?', [name]);
    _updateList();
  }

  Future<List<String>> _getAllNames() async {
    var queryResult = await db.rawQuery('SELECT NOMBRE FROM PERSONAS');
    return queryResult.map((e) => e['NOMBRE'] as String).toList();
  }

  void _updateList() {
    setState(() {});
  }
}


