{ pkgs ? import <nixpkgs> { } }:
with pkgs;
mkShell {
  buildInputs = [
    beam.packages.erlang_26.elixir_1_16
    beamPackages.rebar3
    postgresql
    # needed for setting LANG
    glibcLocales
    colima
    docker
  ];
  LANG = "en_US.UTF-8";
  LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  SECRET_KEY_BASE="BCQ/fBA/6p9vu6+iWMY2g/TJPoOaZ+zWMuZomMUZj3XSNc6LlKH6wz9VfFqVybIn";
}
