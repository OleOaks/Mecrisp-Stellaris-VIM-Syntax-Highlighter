#!/bin/sh

# Number of rows and columns
rows=3
cols=3

# Initialize the array
for i in $(seq "$rows"); do
  for j in $(seq "$cols"); do
    array[$i,$j]="Element $i,$j"
  done
done

# Access elements of the simulated 2D array
for i in $(seq "$rows"); do
  for j in $(seq "$cols"); do
    echo "Element at row $i, column $j: ${array[$i,$j]}"
  done
done
