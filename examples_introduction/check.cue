schema: {
    name: string
    age: int
    human: true // always true
}
schema_bool: {
    name: string
    age: int
    human: bool // wont always be true
}
viola: schema
viola: {
    name: "Viola"
    age: 38
}
alien: schema_bool
alien: {
    name: "the borg",
    age: 999999999999
    human: false
}