CURL   = curl -L -o
CF     = clang-format -style=file -i
GITREF = git clone -o gh --depth 1
#
PY     = python3
PIP    = pip3
PEP    = autopep8 --ignore $(PEPS) -i
#
RUSTUP = $(CAR)/bin/rustup
CARGO  = $(CAR)/bin/cargo
#
OPAM   = /usr/local/bin/opam
OCAMLC = $(ODIR)/ocamlc
UTOP   = $(ODIR)/utop
DUNE   = $(ODIR)/dune
OFMT   = $(ODIR)/ocamlformat
OLSP   = $(ODIR)/ocamllsp
