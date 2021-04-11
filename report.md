---
title: "Final Year Project"
author: "Justin Chadwell"
date: "2021-03-23"

toc: true
toc-own-page: true
titlepage: true

titlepage-color: "3C78D8"
titlepage-text-color: "EEEEEE"
titlepage-rule-color: "EEEEEE"
---

# Abstract

Blah blah blah.

# Introduction

- Explain context of CTF competitions
- Explain automatic flag generation
- Explain the broad strokes design and differences of this approach to other
  approaches

## Problem statement

## Related work

What already exists?

## Report Overview

# Design

## Goals

Explain the current (and original) design goals of the system

## Stages

Detail the main mechanics and stages of the language (since those are used to
roughly structure the rest of the report)

## Specification

Probably some fancy BNF grammars, (simplified) language specification and list
of features

# Implementation

Explain all the awesome technical implementation details.

## Lexical analysis and parsing

Explain moving through stream -> tokens -> tree -> graph

## Type checking

Explain how our rough type-checking modelling works. Can include some neat
diagrams of the graphs we can use.

Talk about the limitations of our model, and where we need some manual
overrides.

## External library integration

The vast majority of pwnable CTF challenges require some interaction with libc,
the C standard library, either for the utility functions, such as file
input/output and networking tools, or to exploit vulnerable functions such as
`system` or `gets`. While it would be feasible to integrate into libc using a
form of the C-language literals as detailed above, this would essentially
require the challenge designer to write C *and* vulnspec, without any form of
safety and sanity checks from type-checking.

As such, we provide a utility to generate listings of all functions, variables
and types in libc, which can then be referenced using a special syntax from
vulnspec specifications. This utility is bundled along with the
`builtin_generator` tool which is used to generate primitive types and the
metatype graph from the previous section.

In the `config.yaml` in the builtins directory, in addition to all the fields
already detailed, we introduce a `libraries` key which specifies information
relevant to parsing and loading data from as many libraries as we want -
however, for mostly practical reasons, we only include libc, however, this
approach could be extended to any number of third-party libraries.

```yaml
...

libraries:
  libc:
    root: "../musl-1.2.1"
    include:
      - ./include/
    include_paths:
      - ./obj/include/
      - ./arch/generic/
      - ./arch/x86_64/

...
```

Each field's purpose is shown below:

| field | purpose |
| :- | :- |
| `root` | location of library relative to the current directory |
| `include` | list of locations to search for header files |
| `include_paths` | list of locations to recursively search for included files |

Note that we use the more lightweight libmusl, as opposed to the more common
and frequently used glibc. We expected that libmusl would prove simpler to
programatically analyze, with fewer internal complex dependencies, and
empirical tests confirmed this. Since the process mostly only extracts the
public functions of the library, all results from libmusl are transferrable to
when we use glibc (which is what we use for testing).

The builtin generation process is fairly straightforward from the provided
data. Initially, we scan for common build autotools and makefile build scripts,
such as `configure` and `Makefile` respectively, which we run before continuing
to the next stage. For some libraries, this *might* not be required, however,
quite a number of more sophisticated and complex libraries automatically
generate header and source files which may need to be scanned in later stages.

Next, we recursively traverse all the specified `include` directories, looking
for `.h` header files, collecting them into a data structure as we go. As we do
this, we also open each header file, scanning for all it's includes using a
simple regular expression - the scanner then searches for this include in the
`include_paths` directories, adding it as a child of the top-level header if
found. Then we repeat this process, scanning this new file includes, looking
for those, etc.

This scanning process may seem needlessly complex, however, not all important
constructs in a header will be directly declared in that header. For example,
the `stdint.h` header does not actually include a definition of `uint8_t`,
instead loading it from an internal source - by recursively searching for that
source, we can find the true definition and implicitly connect it to `stdint.h`.

Once we have collected each header file, we can scan it. Initially, we
attempted an approach based on regular expressions - however, parsing even a
very small subset of C with this quickly becomes unwieldy. Therefore, we
switched to a `ctags` based approach, using Universal Ctags. As we run the
`ctags` program over each header file, we get back a list of tag objects which
represent variables, types and function declarations from that file, along with
their type signatures.

From these tags, we now translate each C-style name into a vulnspec-style name,
by appending `"@<lib>.<header-name>"` - e.g. `printf` becomes
`printf@libc.stdio`. We also translate each C-style type signature into a
vulnspec-style type, using a stack model (**More elaboration needed**). We can
then write these to JSON files, ready for use in processing specifications that
utilize libraries.

## Interpretation

One of the most complex aspects of the project is in how the high-level
abstract representation of the graph of blocks and chunks can be translated
down into low-level C primitives. Mechanically, this reduces to deciding where
in memory each chunk should be placed, and deciding the process by which each
block can be called. We call each collection of decisions an "interpretation",
the results of which are executed by an "interpeter" modifying the graph.

The output of this process is a new graph, represented by a "program" object,
which contains a collection of functions (with their own arguments, local
variables and statements), and a number of global variables and optional
external variables (only if the specification requires them).

### Generation

...how exactly we assign interpretations.

After all blocks and chunk have been assigned an interpretation, we can begin
to apply those through all statements in the specification. We do this in two
passes, to remove as much complexity as possible in the first pass to make the
the latter, more complex, pass easier to reason about. In the first pass, we
remove all calls to inline blocks, while in the second pass, we remove all
calls to function blocks.

### Inline call reduction

...

### Function call reduction

In this next pass, we can now resolve all calls to the remaining blocks, those
that are assigned a "function" interpretation. At this stage, we don't create
the functions themselves, but simply compute what the calls to them should look
like. However, this is not as simple as the previous stage, we can't just
insert a call of the form `block()` - some number of arguments may need to be
passed!

The need for introducing function arguments occurs when a chunk that is used in
the block is assigned a "local" interpretation and is also accessed in some
other block that eventually (either directly or indirectly) calls to it.

For example, suppose that a block $x$ calls block $y$, which we can notate as
$x \rightarrow y$. If a variable $\alpha$ is declared in block $x$ as a local
variable, then for $y$ to access this variable, the call $x \rightarrow y$ can
be modified to pass $\alpha$ as a parameter. By performing this computation for
all variables, for all calls, we can compute the function signature of each
block, and so modify all the vulnspec block calls into function-style calls.

#### Rooting

To determine which function calls need to be patched with which parameters, we
first need to "root" each chunk, i.e. find a function block such that all
references to a chunk are contained in that block and it's descendants. We can
then add that chunk's variables to the collection of local variables (at a
later stage when we actually construct the function).

This process is essentially a variation of the lowest common ancestor problem
in graph theory. However, the usual techniques for calculating this are for trees
or directed acyclic graphs, which aren't sufficient for this problem since the
call graph may contain cycles through the expression of recursive or
co-recursive blocks.

A naive algorithm (and what we initially implemented) finds every block that
references a local variable, then computes all possible paths to that block.
After finding all the paths, the naive algorithm takes the common prefix of all
paths to find the "best" location to place a variable. This result will be
valid, however, as we show later with an example, it may not be optimal.

The more complex "deepest-valid" algorithm starts the same way, computing all
paths to a variable. Then, it finds the complete set of valid owners by finding
the set of all blocks that are present in all paths (since the root block has
to be present in every possible execution), removing those blocks which are
part of a cycle. Finally, the deepest of these blocks can be selected to be the
owner.

To see the difference in these algorithms, consider the following
specification, assuming that all chunks are local and all blocks are functions:

```
chunk a : int
chunk b : int
chunk c : int
chunk d : int
chunk e : int

block x {
  a = 0
  e = 4
  call y
  call z
}

block y {
  b = 1
  c = 2
  e = 4
  call z
}

block z {
  c = 2
  d = 3
  e = 4
}
```

By traversing the call graph, we can easily compute all paths to each variable.

- $a$ and $b$ are both referenced once, by $x$ and $x \rightarrow y$ respectively.
- $c$ is referenced by $x \rightarrow y$, $x \rightarrow y \rightarrow z$ and $x \rightarrow z$
- $d$ is referenced by $x \rightarrow y \rightarrow z$ and $x \rightarrow z$
- $e$ is referenced in all blocks by $x$, $x \rightarrow y$, $x \rightarrow y \rightarrow z$ and $x \rightarrow z$

The naive method, which computes the common prefixes of all paths will
correctly place $a$, $c$ and $e$ in $x$ and $b$ in $y$. However, it will
sub-optimally place $d$ into $x$, when it could be easily placed into $z$.

The deepest-valid algorithm correctly places $d$, by first detecting $x$ and
$z$ as valid locations for the variable, and then choosing the deepest of the
two.

Placing all the variables, we can compute the following:

- $a$, $c$ and $e$ can be only declared in $x$
- $b$ can be declared in $x$ or $y$, and so is declared in the deepest, $y$
- $d$ can be declared in $x$ or $z$, and so is declared in the deepest, $z$

#### Signature

With each chunk rooted, we can now easily find what each function signature
should be. For each function call between the root of a variable's chunk and
the same variable's usage, we need to pass that variable in the function call.

Intuitively, this works because based on the above rooting stage, we know that
each block that requires a variable will have access to it through an ancestor
block. Then inductively, we can show that a block with direct access to a
variable in its scope will pass access to that variable to all it's children
which it calls. Because of this, all descendants of the root block that need
access to the variable can get it!

Practically, the signatures of function calls can be constructed by iterating
through all paths to all variable (after skipping to the root), and patching
each call to also include the variable name that is needed at a lower level.

For example, for the variable $e$ above (rooted at $x$), from the path $x
\rightarrow y \rightarrow z$, we know that calls $x \rightarrow y$ and
$y \rightarrow z$ must contain $x$ as a parameter. Repeating this for all
variables and paths, we can create a full picture of all rooted variables and
the function signatures:

| Block | Parameters | Local variables |
| :- | :- | :- |
| $x$ | $()$ | $(a, c, e)$ |
| $y$ | $(c, e)$ | $(b)$ |
| $z$ | $(c, e)$ | $(d)$ |

### Parameter lifting

Unfortunately, the above description only covers half the story - it accurately
describes how to decide where in memory variables should be located, and how to
share access to them, however, using only this information, the function
signatures will be clearly incorrect.

For example:

```
chunk a : int

block x {
  a = 1
  call y
}

block y {
  a = 2
}
```

Using just the above algorithms, we can deduce that the function signature of
$y$ should be $\textbf{fn} (int) void$. However, since $y$ assigns to the
variable $a$, this would only change a copy of $a$, instead of the value of $a$
itself. To resolve this, we perform a process of "lifting", which lifts simple
variables into more complex l-value expressions, in this case changing the
function signature to accept a pointer to $a$, which allows $y$ to modify the
value correctly.

...

### Finalization

In the final stage, having translated all statements and expressions in each
block correctly, we can now translate the final remaining blocks into
functions.

We can use the already-computed function signatures to construct a list of
arguments, the rooting information to work out local variables, and the
transformed contents of the block to form the main body of the function.

## Randomization

### Templates

...

### NOPs

Introducing randomizations by applying NOPs, and the general approach, as well
as pitfalls to avoid.

### Random name generation

...

## Packaging

Talk through generating the correct compiler options, and explain some of the
tooling around this.

Also, talk about the docker wrapping, and automatically generating flexible
environments for the challenges.

If I get round to it, also talk about a python web server for generating,
building and transferring custom binaries.

Additionally, this would be the place to talk about how solution scripts are
automatically generated, and the provided utilities that go along with them.

# Results

No clue exactly what these will be yet.

# Conclusion

## Summary

## Evaluation

## Future work

# References

