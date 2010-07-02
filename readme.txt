Title: OTLib Readme

Version 1.0 

Copyright (c) 2010 Team Omnivore

http://omnivr.net

Topic: License
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Topic: Code Conventions
    * Whenever we mention "fori", we mean looping over table 't' with for i=1, #t do ... end.
    * Whenever a function name is suffixed by "I", it uses fori (instead of pairs) to function.
    This is because fori is much faster and should be used instead of pairs whenever it can be.
    For a more on this, see <A Discussion On fori>.
    * Whenever the term "hash table" is used, we mean a traditional lua table that can contain
    mixed types of keys. For example, { apple="green", done=true, "bear" } is a hash table.
    * Whenever the terms "array", "array table", "list", or "list table" are used, we mean a table
    that is setup like an array and only contains values that are indexed by contiguous numbers. 
    For example, { "apple", "pear", "kiwi" } is a list or array of fruit. A list may or may not
    contain duplicate values.
    * Whenever the term "set" is used, we mean a table that only contains values of true or nil.
    For example, { apple=true, pear=true, kiwi=true } is a set of fruit. Sets are preferred over
    lists whenever you're making frequent checks to see if a certain value exists, since the 
    complexity is around O( log( #set ) ) for a check against a set and is O( #list ) for a list.
    A set may not contain duplicate values by definition.
