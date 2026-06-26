#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

DEFAULT_JAVA_HOME="/Users/albertosanmartin/java25/jdk-25.0.3.jdk/Contents/Home"
JAVA25_HOME="${JAVA25_HOME:-$DEFAULT_JAVA_HOME}"

JAVAC_CMD="$JAVA25_HOME/bin/javac"
JAVA_CMD="$JAVA25_HOME/bin/java"
JAVAC_FLAGS=(--release 25)

if [[ ! -x "$JAVAC_CMD" || ! -x "$JAVA_CMD" ]]; then
  echo "Aviso: no se encontro JDK 25 en $JAVA25_HOME"
  echo "Se usaran java/javac disponibles en PATH"
  JAVAC_CMD="javac"
  JAVA_CMD="java"
else
  echo "Usando JDK 25 local: $JAVA25_HOME"
fi

DEFAULT_CAP_DIR="cap03"
CAP_DIR="${1:-$DEFAULT_CAP_DIR}"
MAIN_CLASS="${2:-}"

if [[ "$CAP_DIR" != cap* ]]; then
  MAIN_CLASS="$CAP_DIR"
  CAP_DIR="$DEFAULT_CAP_DIR"
fi

if ! compgen -G "$CAP_DIR/*.java" > /dev/null; then
  echo "No se encontraron archivos .java en $CAP_DIR"
  echo "Uso: ./compile-run.sh [capXX] [NombreClaseConMain]"
  exit 1
fi

BIN_ROOT="$PWD/bin"
mkdir -p "$BIN_ROOT"

echo "Compilando proyecto completo..."
for dir in cap*; do
  [[ -d "$dir" ]] || continue
  if ! compgen -G "$dir/*.java" > /dev/null; then
    continue
  fi

  out_dir="$BIN_ROOT/$dir"
  mkdir -p "$out_dir"
  "$JAVAC_CMD" "${JAVAC_FLAGS[@]}" -d "$out_dir" "$dir"/*.java
done

echo "Compilacion exitosa."

BIN_CP=""
for d in "$BIN_ROOT"/cap*; do
  [[ -d "$d" ]] || continue
  if [[ -n "$BIN_CP" ]]; then
    BIN_CP="$BIN_CP:$d"
  else
    BIN_CP="$d"
  fi
done

if [[ -z "$BIN_CP" ]]; then
  echo "No se pudo construir el classpath desde $BIN_ROOT"
  exit 1
fi

to_run_class() {
  local java_file="$1"
  local class_name
  class_name="$(basename "$java_file" .java)"

  local pkg
  pkg="$(sed -n 's/^package[[:space:]][[:space:]]*\(.*\);/\1/p' "$java_file" | head -n 1)"

  if [[ -n "$pkg" ]]; then
    echo "$pkg.$class_name"
  else
    echo "$class_name"
  fi
}

if [[ -z "$MAIN_CLASS" ]]; then
  for f in "$CAP_DIR"/*.java; do
    if grep -q "public static void main" "$f"; then
      MAIN_CLASS="$(basename "$f" .java)"
      break
    fi
  done
fi

if [[ -z "$MAIN_CLASS" ]]; then
  echo "No se encontro clase con metodo main en $CAP_DIR"
  exit 0
fi

RUN_CLASS="$MAIN_CLASS"
if [[ "$MAIN_CLASS" != *.* ]] && [[ -f "$CAP_DIR/$MAIN_CLASS.java" ]]; then
  RUN_CLASS="$(to_run_class "$CAP_DIR/$MAIN_CLASS.java")"
fi

echo "Ejecutando $RUN_CLASS..."
"$JAVA_CMD" -cp "$BIN_CP" "$RUN_CLASS"
