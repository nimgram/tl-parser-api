# Nimgram
# Copyright (C) 2020-2022 Daniele Cortesi <https://github.com/dadadani>
# This file is part of Nimgram, under the MIT License
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import std/strutils, std/tables

type TLApiParameter* = object
    name*: string
    `type`*: string
    description*: string

type TLApiConstructor* = object
    description*: string
    rootObject*: string
    name*: string
    parameters*: seq[TLApiParameter]

proc splitType(constructor: string): (string, string) =
    let eqSplit = constructor.split("=", 1)
    if eqSplit.len > 1:
        let constructorType = eqSplit[1].strip()
        if not constructorType.isEmptyOrWhitespace():
            return (eqSplit[0].strip(), constructorType)

    raise newException(CatchableError, "The type is missing")

proc splitName(constructor: string): (string, string) =
    let wsSplit = constructor.split(" ", 1)
    if wsSplit.len > 1:
        return (wsSplit[0], wsSplit[1].strip())
    return (wsSplit[0], "")


proc parseConstructor*(firstLine: string, file: File): TLApiConstructor = 
    var typesDescription: Table[string, string]
    var firstLine = firstLine
    firstLine.removePrefix("//")
    for description in firstLine.split("@"):
        if description.startsWith("description"):
            result.description = description
            result.description.removePrefix("description")
        elif not description.isEmptyOrWhitespace():
            let nameSplit = description.split(" ", 1)
            typesDescription[nameSplit[0]] = nameSplit[1]

    for line in file.lines():
        if line.startsWith("//-"):
            var descriptionNew = line
            removePrefix(descriptionNew, "//-")
            result.description.add("\n" & descriptionNew)
        elif line.startsWith("//@"):
            var descriptionNew = line
            descriptionNew.removePrefix("//")
            var descriptions = descriptionNew.split("@")
            for description in descriptions:
                if not description.isEmptyOrWhitespace():
                    let nameSplit = description.split(" ", 1)
                    typesDescription[nameSplit[0]] = nameSplit[1]
        elif line.startsWith("//"):
            discard
        else:
            let splittedType = splitType(line)            
            result.rootObject = splittedType[1].split(";", 1)[0]
            let splittedName = splitName(splittedType[0])
            result.name = splittedName[0]
            let parameters = splittedName[1].splitWhitespace()
            for parameter in parameters:
                let paramSplit = parameter.split(":", 1)
                result.parameters.add(TLApiParameter(name: paramSplit[0], `type`: paramSplit[1], description: (if typesDescription.contains(paramSplit[0]): typesDescription[paramSplit[0]] else: "")))
            break