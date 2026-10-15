class Perfil {
  final String uId;
  final String nombre;
  final String email;
  final String? fotoUrl;

  Perfil({
    required this.uId,
    required this.nombre,
    required this.email,
    this.fotoUrl,
  });
}