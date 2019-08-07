function runOnAllCores(self)

% check things to make sure they're OK
self.check;

% save the model in case we forget what it is
x = self.x;

save([self.DataDump filesep 'model.xolotl'],'x')

self.CurrentPool = gcp;
self.NumWorkers = self.CurrentPool.NumWorkers - 1;

disp('Starting workers...')

for j = self.NumWorkers:-1:1
	corelib.textbar(self.NumWorkers - j + 1,self.NumWorkers)
	F(j) = parfeval(@self.simulate,0);
	
end

self.workers = F;


