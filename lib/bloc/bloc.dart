import 'package:bloc/bloc.dart';
import 'package:costos/database/database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


//EVENTOS
abstract class CarroEvento {}

class Inicializado extends CarroEvento {}

class CarroSeleccionado extends CarroEvento {
  final int indiceSeleccionado;

  CarroSeleccionado({required this.indiceSeleccionado});
}

class GetCarros extends CarroEvento {}

class GetCarrosdl extends CarroEvento {}

class InsertarCarro extends CarroEvento {
  final String apodo;

  InsertarCarro({
    required this.apodo,
  });
}

class EliminarCarro extends CarroEvento {
  final int idCarro;

  EliminarCarro({required this.idCarro});
}

class UpdateCarro extends CarroEvento {
  final String apodo;
  final int idcarro;

  UpdateCarro({required this.apodo, required this.idcarro});
}

class ArchivarCarro extends CarroEvento {
  final int idcarro;

  ArchivarCarro({required this.idcarro});
}
// ESTADOS
abstract class CarroEstado {
  get mensajeError => null;
}

class EstadoInicial extends CarroEstado {}

class CarroSeleccionadoEstado extends CarroEstado {
  final int idSeleccionado;

  CarroSeleccionadoEstado({required this.idSeleccionado});
}

class GetAllCarros extends CarroEstado {
  final List<Map<String, dynamic>> carros;
  final List<Map<String, dynamic>> carrosArchivados;

  GetAllCarros({required this.carros, required this.carrosArchivados});
}

class CarroInsertado extends CarroEstado {}

class CarroEliminado extends CarroEstado {}

class CarroActualizado extends CarroEstado {}

class CarroArchivado extends CarroEstado {}

class ErrorGetAllCarros extends CarroEstado {
  @override
  final String mensajeError;

  ErrorGetAllCarros({required this.mensajeError});
}

class ErrorAlInsertarCarro extends CarroEstado {
  @override
  final String mensajeError;

  ErrorAlInsertarCarro({required this.mensajeError});
}

class ErrorAlEliminarCarro extends CarroEstado {
  @override
  final String mensajeError;

  ErrorAlEliminarCarro({required this.mensajeError});
}

class ErrorAlActualizarCarro extends CarroEstado {
  @override
  final String mensajeError;

  ErrorAlActualizarCarro({required this.mensajeError});
}

class ErrorAlArchivarCarro extends CarroEstado {
  @override
  final String mensajeError;

  ErrorAlArchivarCarro({required this.mensajeError});
}

//BLOC

class CarroBloc extends Bloc<CarroEvento, CarroEstado> {
  final CarrosDatabase dbCarro;
  late List<Map<String, dynamic>> allCarros = []; // Lista de todos los carros
  late List<Map<String, dynamic>> carrosArchivados =
      []; // Lista de carros archivados

  CarroBloc(this.dbCarro) : super(EstadoInicial()) {
    on<Inicializado>((event, emit) {
      emit(EstadoInicial());
    });

//Carros
    on<CarroSeleccionado>((event, emit) {
      final int idSeleccionado = event.indiceSeleccionado;
      emit(CarroSeleccionadoEstado(idSeleccionado: idSeleccionado));
    });

    on<GetCarros>((event, emit) async {
      try {
        final allCarros = await dbCarro.getCarros();
        final carrosArchivados =
            allCarros.where((carro) => carro['archivado'] == 1).toList();
        emit(GetAllCarros(
            carros: allCarros, carrosArchivados: carrosArchivados));
      } catch (e) {
        emit(ErrorGetAllCarros(
            mensajeError: 'Error al cargar todos los carros: $e'));
      }
    });

    on<InsertarCarro>((event, emit) async {
      try {
        await dbCarro.addCarro(event.apodo);

        emit(CarroInsertado());
        add(GetCarros());
      } catch (e) {
        emit(ErrorAlInsertarCarro(mensajeError: 'Error al insertar el carro.'));
      }
    });

    on<EliminarCarro>((event, emit) {
      try {
        // Llama al método de la base de datos para eliminar el carro
        dbCarro.deleteCarro(event.idCarro);
        emit(CarroEliminado());
        add(GetCarros());
      } catch (e) {
        emit(ErrorAlEliminarCarro(mensajeError: 'Error al eliminar el carro.'));
      }
    });

    on<UpdateCarro>((event, emit) async {
      try {
        dbCarro.updateCarro(event.apodo, event.idcarro);

        emit(CarroActualizado());
        add(GetCarros());
      } catch (e) {
        emit(ErrorAlActualizarCarro(
            mensajeError: 'Error al insertar el carro.'));
      }
    });

    on<ArchivarCarro>((event, emit) async {
      try {
        dbCarro.archivarCarro(event.idcarro);

        emit(CarroArchivado());
        add(GetCarros());
      } catch (e) {
        emit(ErrorAlArchivarCarro(mensajeError: 'Error al insertar el carro.'));
      }
    });
  }
}