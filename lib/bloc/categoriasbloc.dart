import 'package:bloc/bloc.dart';
import 'package:costos/database/database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//eventos
abstract class CategoriaEvento {}

class CategoriaInicializada extends CategoriaEvento {}

class CategoriaSeleccionada extends CategoriaEvento {
  final int indiceSeleccionado;

  CategoriaSeleccionada({required this.indiceSeleccionado});
}

class GetCategorias extends CategoriaEvento {}

class InsertarCategoria extends CategoriaEvento {
  final String nombrecategoria;

  InsertarCategoria({required this.nombrecategoria});
}

class EliminarCategoria extends CategoriaEvento {
  final int idcategoria;

  EliminarCategoria({required this.idcategoria});
}

class UpdateCategoria extends CategoriaEvento {
  final String nombrecategoria;
  final int idcategoria;

  UpdateCategoria({required this.nombrecategoria, required this.idcategoria});
}

class ArchivarCategoria extends CategoriaEvento {
  final int idcategoria;

  ArchivarCategoria({required this.idcategoria});
}

//estados
abstract class CategoriaEstado {
  get mensajeError => null;
}

class EstadoCategoriaInicial extends CategoriaEstado {}

class CategoriaSeleccionadoEstado extends CategoriaEstado {
  final int idSeleccionado;

  CategoriaSeleccionadoEstado({required this.idSeleccionado});
}

class GetAllCategorias extends CategoriaEstado {
  final List<Map<String, dynamic>> categorias;

  GetAllCategorias({required this.categorias});
}

class CategoriaInsertada extends CategoriaEstado {}

class CategoriaEliminada extends CategoriaEstado {}

class CategoriaActualizada extends CategoriaEstado {}

class CategoriaArchivada extends CategoriaEstado {}

class ErrorGetAllCategorias extends CategoriaEstado {
  @override
  final String mensajeError;

  ErrorGetAllCategorias({required this.mensajeError});
}

class ErrorAlInsertarCategoria extends CategoriaEstado {
  @override
  final String mensajeError;

  ErrorAlInsertarCategoria({required this.mensajeError});
}

class ErrorAlEliminarCategoria extends CategoriaEstado {
  @override
  final String mensajeError;

  ErrorAlEliminarCategoria({required this.mensajeError});
}

class ErrorAlActualizarCategoria extends CategoriaEstado {
  @override
  final String mensajeError;

  ErrorAlActualizarCategoria({required this.mensajeError});
}

class ErrorAlArchivarCategoria extends CategoriaEstado {
  @override
  final String mensajeError;

  ErrorAlArchivarCategoria({required this.mensajeError});
}

//bloc
class CategoriaBloc extends Bloc<CategoriaEvento, CategoriaEstado> {
  final CarrosDatabase dbCarro;
  CategoriaBloc(this.dbCarro) : super(EstadoCategoriaInicial()) {
    on<CategoriaInicializada>((event, emit) {
      emit(EstadoCategoriaInicial());
    });

    on<CategoriaSeleccionada>((event, emit) {
      final int idSeleccionado = event.indiceSeleccionado;
      emit(CategoriaSeleccionadoEstado(idSeleccionado: idSeleccionado));
    });

    on<GetCategorias>((event, emit) async {
      try {
        final categorias = await dbCarro.getCategorias();
        emit(GetAllCategorias(categorias: categorias));
      } catch (e) {
        emit(ErrorGetAllCategorias(
            mensajeError: 'Error al cargar todas las categorias: $e'));
      }
    });

    on<InsertarCategoria>((event, emit) async {
      try {
        await dbCarro.addCategoria(event.nombrecategoria);

        emit(CategoriaInsertada());
        add(GetCategorias());
      } catch (e) {
        emit(ErrorAlInsertarCategoria(
            mensajeError: 'Error al insertar la categoria.'));
      }
    });

    on<EliminarCategoria>((event, emit) {
      try {
        // Llama al método de la base de datos para eliminar el carro
        dbCarro.deleteCategoria(event.idcategoria);
        emit(CategoriaEliminada());
        add(GetCategorias());
      } catch (e) {
        emit(ErrorAlEliminarCategoria(
            mensajeError: 'Error al eliminar la categoria.'));
      }
    });

    on<UpdateCategoria>((event, emit) async {
      try {
        dbCarro.updateCategoria(event.nombrecategoria, event.idcategoria);

        emit(CategoriaActualizada());
        add(GetCategorias());
      } catch (e) {
        emit(ErrorAlActualizarCategoria(
            mensajeError: 'Error al insertar el carro.'));
      }
    });

    on<ArchivarCategoria>((event, emit) async {
      try {
        dbCarro.archivarCategoria(event.idcategoria);

        emit(CategoriaArchivada());
        add(GetCategorias());
      } catch (e) {
        emit(ErrorAlArchivarCategoria(
            mensajeError: 'Error al archivar categoria.'));
      }
    });
  }
}