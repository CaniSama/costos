import 'package:bloc_test/bloc_test.dart';
import 'package:test/test.dart';
import 'package:costos/bloc/bloc.dart';

void main() {
  group('MiBloc', () {
    test('emite EstadoInicial al inicio', () {
      expect(MiBloc().state, equals(EstadoInicial()));
    });

    blocTest<MiBloc, Estado>(
      'emite CarroInsertado cuando se inserta un carro',
      build: () => MiBloc(),
      act: (bloc) => bloc.add(InsertarCarro(
        apodo: 'Carro de prueba',
        marca: 'Marca de prueba',
        modelo: 'Modelo de prueba',
        anio: 2022,
      )),
      expect: () => [CarroInsertado()],
    );

    blocTest<MiBloc, Estado>(
      'emite CarroEliminado cuando se elimina un carro',
      build: () => MiBloc(),
      act: (bloc) => bloc.add(EliminarCarro(idCarro: 1)),
      expect: () => [CarroEliminado()],
    );

    blocTest<MiBloc, Estado>(
      'emite ErrorAlEliminarCarro cuando hay un error al eliminar',
      build: () => MiBloc(),
      act: (bloc) => bloc.add(EliminarCarro(idCarro: 1)),
      expect: () => [isA<ErrorAlEliminarCarro>()],
    );
  });
}
