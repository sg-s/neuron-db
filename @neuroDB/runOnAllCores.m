function runOnAllCores(self)

% check things to make sure they're OK
self.check;


self.current_pool = gcp;
self.num_workers = self.current_pool.NumWorkers - 1;

disp('Starting workers...')

for j = self.num_workers:-1:1
	corelib.textbar(self.num_workers - j + 1,self.num_workers)
	F(j) = parfeval(@self.simulate,0);
	
end

self.workers = F;


