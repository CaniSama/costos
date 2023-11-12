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
    return const MaterialApp(
      home: Scaffold(body: Mio()),
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
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showAddPersonModal(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _deleteSelected();
                },
                icon: const Icon(Icons.remove),
                label: const Text('Borrar'),
              ),
            ),
          ],
        ),
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
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddPersonModal(BuildContext context) async {
    String newName = '';

    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  newName = value;
                },
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar el modal
                  _addPerson(newName);
                },
                child: const Text('Agregar'),
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

  void _deleteSelected() async {
    if (itemSeleccionado != null) {
      await db.rawDelete('DELETE FROM PERSONAS WHERE NOMBRE = ?', [itemSeleccionado]);
      itemSeleccionado = null;
      _updateList();
    }
  }

  Future<List<String>> _getAllNames() async {
    var queryResult = await db.rawQuery('SELECT NOMBRE FROM PERSONAS');
    return queryResult.map((e) => e['NOMBRE'] as String).toList();
  }

  void _updateList() {
    setState(() {});
  }
}

