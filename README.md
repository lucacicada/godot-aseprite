# Godot Aseprite

<p align="center"><img src="ase256.png" alt="Aseprite Logo"/></p>

Aseprite file parser for Godot Engine.

## ERR_FILE_CORRUPT

The parser perform several strict checks to ensure the file is valid.
At the moment, it return a generic `ERR_FILE_CORRUPT` error if the file is malformed.

In the future, a warning message will be printed.

## Security note

This parser is vulnerable to gzip bombs as`decompress_dynamic` calls are unbounded (`-1`).

The compression format used by Aseprite is ZLIB; it does not store the uncompressed size of the deflated buffer. Without this information, it is not possible to know at runtime how large the uncompressed buffer will be.

A heuristic could be implemented to limit this class of attacks, `compressed_size * 5.7` is a good estimate, exceeding an order of magnitude is likely a malformed file. A compression rate of `10:1` is extreme for images.

Be careful using this parser for untrusted files, especially if you plan to use it for
network shared resources.

In addition, the .aseprite format can be used to store filenames, potentially leaking personal info.
