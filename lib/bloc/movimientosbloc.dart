import 'package:bloc/bloc.dart';
import 'package:costos/database/database.dart';

//Eventos
abstract class MovimientoEvento {}

class MovimientoInicializado extends MovimientoEvento {}

class MovimientoSeleccionado extends MovimientoEvento {
  final int indiceSeleccionado;

  MovimientoSeleccionado({required this.indiceSeleccionado});
}

class GetMovimientos extends MovimientoEvento {}

class GetCarrosCategoriasList extends MovimientoEvento {}

class InsertarMovimiento extends MovimientoEvento {
  final String nombremovimiento;
  final int idcarro;
  final int idcategoria;
  final int gastototal;

  InsertarMovimiento({
    required this.nombremovimiento,
    required this.idcarro,
    required this.idcategoria,
    required this.gastototal,
  });
}

class EliminarMovimiento extends MovimientoEvento {
  final int idmovimiento;

  EliminarMovimiento({required this.idmovimiento});
}

class UpdateMovimiento extends MovimientoEvento {
  final String nombremovimiento;
  final int idcarro;
  final int idcategoria;
  final int gastototal;
  final int idmovimiento;

  UpdateMovimiento({
    required this.nombremovimiento,
    required this.idcarro,
    required this.idcategoria,
    required this.gastototal,
    required this.idmovimiento,
  });
}

//Estados

abstract class MovimientoEstado {
  get mensajeError => null;
}

class EstadoMovimientoInicial extends MovimientoEstado {}

class MovimientoSeleccionadoEstado extends MovimientoEstado {
  final int idSeleccionado;

  MovimientoSeleccionadoEstado({required this.idSeleccionado});
}

class GetAllMovimientos extends MovimientoEstado {
  final List<Map<String, dynamic>> movimientos;

  GetAllMovimientos({required this.movimientos});
}

class GetAllCarrosCategoriasList extends MovimientoEstado {
  final List<Map<String, dynamic>> carros;
  final List<Map<String, dynamic>> categorias;

  GetAllCarrosCategoriasList({required this.carros, required this.categorias});
}

class MovimientoInsertado extends MovimientoEstado {}

class MovimientoEliminado extends MovimientoEstado {}

class MovimientoActualizado extends MovimientoEstado {}

class ErrorGetAllMovimientos extends MovimientoEstado {
  @override
  final String mensajeError;

  ErrorGetAllMovimientos({required this.mensajeError});
}

class ErrorGetAllCarrosCategoriasList extends MovimientoEstado {
  @override
  final String mensajeError;

  ErrorGetAllCarrosCategoriasList({required this.mensajeError});
}

class ErrorAlInsertarMovimiento extends MovimientoEstado {
  @override
  final String mensajeError;

  ErrorAlInsertarMovimiento({required this.mensajeError});
}

class ErrorAlEliminarMovimiento extends MovimientoEstado {
  @override
  final String mensajeError;

  ErrorAlEliminarMovimiento({required this.mensajeError});
}

class ErrorAlActualizarMovimiento extends MovimientoEstado {
  @override
  final String mensajeError;

  ErrorAlActualizarMovimiento({required this.mensajeError});
}
//Bloc

class MovimientoBloc extends Bloc<MovimientoEvento, MovimientoEstado> {
  final CarrosDatabase dbCarro;
  MovimientoBloc(this.dbCarro) : super(EstadoMovimientoInicial()) {
    on<MovimientoInicializado>((event, emit) {
      emit(EstadoMovimientoInicial());
    });

    on<MovimientoSeleccionado>((event, emit) {
      final int idSeleccionado = event.indiceSeleccionado;
      emit(MovimientoSeleccionadoEstado(idSeleccionado: idSeleccionado));
    });

    on<GetMovimientos>((event, emit) async {
      try {
        final movimientos = await dbCarro.getMovimientos();
        emit(GetAllMovimientos(movimientos: movimientos));
      } catch (e) {
        emit(ErrorGetAllMovimientos(
            mensajeError: 'Error al cargar todas las movimientos: $e'));
      }
    });

    on<InsertarMovimiento>((event, emit) async {
      try {
        await dbCarro.addMovimiento(
          event.nombremovimiento,
          event.idcarro,
          event.idcategoria,
          event.gastototal,
        );

        emit(MovimientoInsertado());
        add(GetMovimientos());
        // add(GetMovimientos());
      } catch (e) {
        emit(ErrorAlInsertarMovimiento(
            mensajeError: 'Error al insertar el movimiento.'));
      }
    });

    on<EliminarMovimiento>((event, emit) {
      try {
        dbCarro.deleteMovimiento(event.idmovimiento);
        emit(MovimientoEliminado());
        add(GetMovimientos());
      } catch (e) {
        emit(ErrorAlEliminarMovimiento(
            mensajeError: 'Error al eliminar el movimiento.'));
      }
    });

    on<UpdateMovimiento>((event, emit) async {
      try {
        dbCarro.updateMovimiento(
          event.nombremovimiento,
          event.idcarro,
          event.idcategoria,
          event.gastototal,
          event.idmovimiento,
        );

        print(event.nombremovimiento);
        print(event.idcarro);
        print(event.idcategoria);
        print(event.gastototal);
        print(event.idmovimiento);

        emit(MovimientoActualizado());
        add(GetMovimientos());
      } catch (e) {
        emit(ErrorAlActualizarMovimiento(
            mensajeError: 'Error al insertar el carro.'));
      }
    });
  }
}