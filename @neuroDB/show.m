function varargout = show(self, idx)

self.x.set('*gbar',self.results.all_g(idx,:))
self.x.reset;
self.x.integrate;

if nargout == 1
	V = self.x.integrate;
	varargout{1} = V;
	return

end
self.x.plot;

