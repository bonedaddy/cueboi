# cueboi 

learnin cue


# Links

* [Website](https://cuelang.org/)
* [Getting Started](https://cuelang.org/docs/install/)


# Examples:


Example spec

```cue
pec :: {
  kind: string

  name: {
    first:   !=""  // must be specified and non-empty
    middle?: !=""  // optional, but must be non-empty when specified
    last:    !=""
  }

  // The minimum must be strictly smaller than the maximum and vice versa.
  minimum?: int & <maximum
  maximum?: int & >minimum
}

// A spec is of type Spec
spec: Spec
spec: {
  knid: "Homo Sapiens" // error, misspelled field

  name: first: "Jane"
  name: last:  "Doe"
}
```