# Rules - Typed runtime argument validator for Roblox a
## Basic validators
### `Rules.void` - Ensures that the passed argument is *void*
#### Signatures
```luau
Rules.void(...: unknown): (boolean, string?)
Rules.Void(...: unknown): (boolean, string?)
```
#### Examples
```luau
Rules.void() -- true
Rules.void(nil) -- false, "Value isn't void"
Rules.void((function() return end)()) -- true, "Value isn't void"
```

### `Rules.none` - Ensures that the passed argument is nil
#### Signatures
```luau
Rules.none(Value: unknown): (boolean, string?)
Rules.None(Value: unknown): (boolean, string?)
```
#### Examples
```luau
Rules.none() -- true
Rules.none(nil) -- true
Rules.none(123) -- false, "Value isn't nil"
```

### `Rules.optional` - Ensures that the passed argument matches the passed rule or is nil
#### Signatures
```luau
Rules.optional(Validator: Rule): (Value: unknown) -> (boolean, string?)
Rules.Optional(Validator: Rule): (Value: unknown) -> (boolean, string?)
```
#### Examples
```luau
local IsOptionallyString = Rules.optional(Rules.string)
IsOptionallyString("i am a string") -- true
IsOptionallyString(nil) -- true
IsOptionallyString(123) -- false, "Value isn't a string"
```

### `Rules.any` - Ensures that the passed argument is not nil
#### Signatures
```luau
Rules.any(Value: unknown): (boolean, string?)
Rules.Any(Value: unknown): (boolean, string?)
```
#### Examples
```luau
Rules.any(123) -- true
Rules.any("is this a string") -- true
Rules.any(nil) -- false, "Value is nil"
```

### `Rules.literal` - Ensures that the passed argument matches the literal exactly
#### Signatures
```luau
Rules.literal(Expected: any): (Value: unknown) -> (boolean, string?)
Rules.Literal(Expected: any): (Value: unknown) -> (boolean, string?)
```
#### Examples
```luau
local IsHamburger = Rules.literal("Hamburger")
IsHamburger("Hamburger") -- true
IsHamburger("Bread") -- false, "Value is not Hamburger"
```

## Primitive validators
|Type     |Member         |
|---------|---------------|
|boolean  |Rules.boolean  |
|thread   |Rules.thread   |
|function |Rules.callback |
|number   |Rules.number   |
|string   |Rules.string   |
|table    |Rules.table    |
|userdata |Rules.luauserdata|


*Each member has a PascalCase version (e.g `Rules.Boolean`)*

todo