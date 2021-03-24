---
title: "Final Year Project"
author: "Justin Chadwell"
date: "2021-03-23"

toc: true

book: true
titlepage: true
toc-own-page: true
classoption: [oneside]

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

Explain how we integrate with libc, and describe the tooling I've used to do
this. This is quite a neat approach, independent of the work for this project.

## Interpretation models

Explain how we produce a code graph suitable for code generation.

### Parameter lifting

Details of how we modify/patch types as we move variables across function
boundaries.

### NOPs

Introducing randomizations by applying NOPs, and the general approach, as well
as pitfalls to avoid.

## Randomization

Explain our "other" randomization techniques, such as templating and random
name generation through markov chains.

## Packaging

Talk through generating the correct compiler options, and explain some of the
tooling around this.

Also, talk about the docker wrapping, and automatically generating flexible
environments for the challenges.

If I get round to it, also talk about a python web server for generating,
building and transferring custom binaries.

# Results

No clue exactly what these will be yet.

# Conclusion

## Summary

## Evaluation

## Future work

# References

