# JsonModel

JsonModel is a set of utilities built on top of the Swift Codable protocol to allow 
for polymorphic serialization and documentation using a subset of 
[JSON Schema draft 7](https://json-schema.org/understanding-json-schema/index.html).

See the unit tests and the `ResultModel` target for examples for how to use this 
library to support polymorphic serialization.

### Version 1.1

Moved definitions for the `ResultData` protocol used by Sage Bionetworks
into this library to simplify the dependency chain for the libraries and 
frameworks used by our organization.

### Version 1.6

Added ResultModel library with a placeholder file so that libraries that depend
on the `ResultData` protocol can support both a version of the library where the 
actual model is defined using `import JsonModel` and version
2 where the model for results is defined using `import ResultModel`.

```
    .package(name: "JsonModel",
             url: "https://github.com/Sage-Bionetworks/JsonModel-Swift.git",
             "1.6.0"..<"3.0.0"),
```

### Version 2

Moved the results protocols and objects into a separate target within the JsonModel
library. To migrate to this version, you will need to `import ResultModel` anywhere
that you reference `ResultData` model objects.

## License

JsonModel is available under the BSD license:

Copyright (c) 2017-2022, Sage Bionetworks
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of Sage Bionetworks nor the names of any
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL SAGE BIONETWORKS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

