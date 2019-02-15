function check(self)

assert(~isempty(self.x),'Xolotl object not configured')
assert(~isempty(self.prefix),'No prefix specified')
assert(~isempty(self.data_dump),'data_dump not specified')