import 'package:bloc/bloc.dart';
import 'package:costos/database/database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


//EVENTOS
abstract class Evento {}

class BorrarTodosLosCarros extends Evento{}

class Inicializado extends Evento {}

class CarroSeleccionado extends Evento {
  final int indiceSeleccionado;

  CarroSeleccionado({required this.indiceSeleccionado});
}

class InsertarCarro extends Evento {
  final String apodo;

  InsertarCarro({
    required this.apodo,

  });
}

class EliminarCarro extends Evento {
  final int idCarro;

  EliminarCarro({required this.idCarro});
}

class TraerTodosLosCarros extends Evento{}

class UpdateCarro extends Evento {
  final String apodo;
  final int idcarro;

  UpdateCarro({required this.apodo, required this.idcarro});
}

class ArchivarCarro extends Evento {
  final int idcarro;

  ArchivarCarro({required this.idcarro});
}

// ESTADOS
class Estado {}

class EstadoInicial extends Estado {}

class CarroSeleccionadoEstado extends Estado {
  final int idSeleccionado;

  CarroSeleccionadoEstado({required this.idSeleccionado});
}

class CarroInsertado extends Estado {}

class CarroEliminado extends Estado {}

class CarroActualizado extends Estado {}

class CarroArchivado extends Estado {}

class GetAllCarros extends Estado {
  final List<Map<String, dynamic>> carros;

  GetAllCarros({required this.carros});
}

class TodosLosCarrosCargados extends Estado{
  final List<Map<String, dynamic>> carros;

  TodosLosCarrosCargados({required this.carros});
}

class ErrorAlInsertarCarro extends Estado {
  final String mensajeError;

  ErrorAlInsertarCarro({required this.mensajeError});
}

class ErrorAlEliminarCarro extends Estado {
  final String mensajeError;

  ErrorAlEliminarCarro({required this.mensajeError});
}

class ErrorTraerCarros extends Estado{
  final String mensajeError;

  ErrorTraerCarros({required this.mensajeError});
}

class ErrorAlActualizarCarro extends Estado {
  final String mensajeError;

  ErrorAlActualizarCarro({required this.mensajeError});
}

class ErrorAlArchivarCarro extends Estado {
  final String mensajeError;

  ErrorAlArchivarCarro({required this.mensajeError});
}

//BLOC

class MiBloc extends Bloc<Evento, Estado> {
  final CarrosDatabase carrosDatabase;

  MiBloc(this.carrosDatabase) : super(EstadoInicial()) {
    on<Inicializado>((event, emit) {
      emit(EstadoInicial());
    });

    on<CarroSeleccionado>((event, emit) {
      final int idSeleccionado = event.indiceSeleccionado;
      emit(CarroSeleccionadoEstado(idSeleccionado: idSeleccionado));
    });

    on<InsertarCarro>((event, emit) async {
      try {
        await carrosDatabase.addCarro(
          event.apodo
        );
        print("Carro insertado event triggered");
        emit(CarroInsertado());
        add(TraerTodosLosCarros());
      } catch (e) {
        emit(ErrorAlInsertarCarro(mensajeError: 'Error al insertar el carro: $e'));
      }
    });

    on<EliminarCarro>((event, emit) async{
      try {
        await carrosDatabase.deleteCarro(event.idCarro);
        emit(CarroEliminado());
      } catch (e) {
        emit(ErrorAlEliminarCarro(mensajeError: 'Error al eliminar el carro: $e'));
      }
    });

    on<TraerTodosLosCarros>((event, emit) async{
      try{
        final carros = await carrosDatabase.getCarros();
        print("Carros loaded: $carros");
        emit(TodosLosCarrosCargados(carros: carros));
      } catch (e){
        print("Error loading cars: $e");
        emit(ErrorTraerCarros(mensajeError: 'Error al cargar todos los carros: $e'));
      }
    });

    on<UpdateCarro>((event, emit) async {
      try {
        carrosDatabase.updateCarro(event.apodo, event.idcarro);

        emit(CarroActualizado());
        add(TraerTodosLosCarros());
      } catch (e) {
        emit(ErrorAlActualizarCarro(
            mensajeError: 'Error al insertar el carro.'));
      }
    });

    on<ArchivarCarro>((event, emit) async {
      try {
        carrosDatabase.archivarCarro(event.idcarro);

        emit(CarroArchivado());
        add(TraerTodosLosCarros());
      } catch (e) {
        emit(ErrorAlArchivarCarro(mensajeError: 'Error al insertar el carro.'));
      }
    });
  }
}