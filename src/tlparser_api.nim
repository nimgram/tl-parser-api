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
import std/strutils
import tlparser_api/private/constructors, std/json
export TLApiConstructor, TLApiParameter

type TLApi* = object
  functions*: seq[TLApiConstructor]
  classes*: seq[TLApiConstructor]
  interfaces*: seq[(string, string)]


const FUNCTIONS_SEPARATOR = "functions"
const TYPES_SEPARATOR = "types"
const SEPARATOR_DASHES_COUNT = 3

const SEPARATOR_DASHES = "-".repeat(SEPARATOR_DASHES_COUNT)

proc parseFile*(filename: string): TLApi = 
    var writeFunctions = false
    let file = open(filename, fmRead)
    for line in file.lines():
      if line.startsWith("//@description"):
        if writeFunctions:
          result.functions.add(parseConstructor(line, file))
        else:
          result.classes.add(parseConstructor(line, file))
      elif line.startsWith("//@class "):
        var class = line
        class.removePrefix("//@class ")
        let classSplit = class.split(" ", 1)
        var classDescription = ""
        for description in classSplit[1].split("@"):
            if description.startsWith("description"):
                classDescription = description
                classDescription.removePrefix("description")
        result.interfaces.add((classSplit[0], classDescription))
      if line.contains(SEPARATOR_DASHES):
        let separatorName = line.split(SEPARATOR_DASHES)[1]

        case separatorName
        of FUNCTIONS_SEPARATOR:
            writeFunctions = true
        of TYPES_SEPARATOR:
            writeFunctions = false
        else:
            raise newException(FieldDefect, "Unknown separator " & separatorName)
