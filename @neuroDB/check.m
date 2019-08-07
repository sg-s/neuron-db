% Checks that neuroDB is configured correctly

function check(self)

assert(~isempty(self.x),'Xolotl object not configured')
assert(~isempty(self.DataDump),'DataDump not specified')