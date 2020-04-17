# cueboi 

learnin cue


# Links

* [Website](https://cuelang.org/)
* [Getting Started](https://cuelang.org/docs/install/)
* [Using within Go programs](https://cuelang.org/docs/integrations/go/)
* [Using with JSON](https://cuelang.org/docs/integrations/json/)
* [Using with YAML](https://cuelang.org/docs/integrations/yaml/)
* [Concepts](https://cuelang.org/docs/concepts/)

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


# Notes

* `?: != ""` means the value is optional, but must be non-emtpy when specified
* Duplicate fields are allowed if they dont conflict
  * Fiels are merged and duplicated fields handled recursively
  * In lists, all elements must match accordingly