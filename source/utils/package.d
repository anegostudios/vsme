module utils;

/// Call destroy on ref of type T, for use when classes implement their own useless destroy function.
void doDestroy(T)(ref T item) {
    destroy(item);
}