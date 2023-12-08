import 'package:bloc/bloc.dart';
import 'package:costos/bloc/bloc.dart';
import 'package:costos/database/database.dart';
import 'categoriasbloc.dart';


//Eventos
abstract class MovimientoEvento {}

class MovimientoInicializado extends MovimientoEvento {}

class MovimientoSeleccionado extends MovimientoEvento {
  final int indiceSeleccionado;

  MovimientoSeleccionado({required this.indiceSeleccionado});
}

class GetMovimientos extends MovimientoEvento {}

class GetCarrosDl extends MovimientoEvento {}

class InsertarMovimiento extends MovimientoEvento {
  final String nombremovimiento;
  final int idcarro;
  final int idcategoria;
  final int gastototal;
  final String fechagasto;

  InsertarMovimiento({
    required this.nombremovimiento,
    required this.idcarro,
    required this.idcategoria,
    required this.gastototal,
    required this.fechagasto,
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
  final String fechagasto;

  UpdateMovimiento({
    required this.nombremovimiento,
    required this.idcarro,
    required this.idcategoria,
    required this.gastototal,
    required this.idmovimiento,
    required this.fechagasto,
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

class GetAllCarrosDl extends MovimientoEstado {
  final List<Map<String, dynamic>> carrosdl;

  GetAllCarrosDl({required this.carrosdl});
}

class MovimientoInsertado extends MovimientoEstado {}

class MovimientoEliminado extends MovimientoEstado {}

class MovimientoActualizado extends MovimientoEstado {}

class ErrorGetAllMovimientos extends MovimientoEstado {
  @override
  final String mensajeError;

  ErrorGetAllMovimientos({required this.mensajeError});
}

class ErrorGetAllCarrosDl extends MovimientoEstado {
  @override
  final String mensajeError;

  ErrorGetAllCarrosDl({required this.mensajeError});
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
  final CategoriaBloc categoriaBloc;
  final CarroBloc carroBloc;
  final CarrosDatabase dbCarro;
  MovimientoBloc(this.dbCarro, this.categoriaBloc, this.carroBloc)
      : super(EstadoMovimientoInicial()) {
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
          event.fechagasto,
        );

        emit(MovimientoInsertado());
        add(GetMovimientos());
        carroBloc.add(GetCarros());
        categoriaBloc.add(GetCategorias());
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

        carroBloc.add(GetCarros());
        categoriaBloc.add(GetCategorias());
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
          event.fechagasto,
        );

        emit(MovimientoActualizado());
        add(GetMovimientos());

        carroBloc.add(GetCarros());
        categoriaBloc.add(GetCategorias());
      } catch (e) {
        emit(ErrorAlActualizarMovimiento(
            mensajeError: 'Error al insertar el carro.'));
      }
    });
  }
}