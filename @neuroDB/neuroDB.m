classdef neuroDB < handle


properties

	x@xolotl

	NaV_range = [0 5e3];
	CaT_range = [0 125];
	CaS_range = [0 200];
	A_range = [0 500];
	KCa_range = [0 300];
	Kd_range = [0 2e3];
	H_range = [0 1];
	Leak_range = [0 1];


	prefix@char

	results@Data

	workers
	current_pool
	num_workers

	sim_chunk_size = 1e3

	deletion_probability = .05

	handles

	keep_only_burst_period = [-Inf Inf];
	keep_only_duty_cycle = [0  1];

end

methods

	% constructor
	function self = neuroDB()


	end % constructor 

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

	end


	function runOnAllCores(self)

		self.current_pool = gcp;
		self.num_workers = self.current_pool.NumWorkers - 1;

		disp('Starting workers...')

		for j = self.num_workers:-1:1
			F(j) = parfeval(@self.simulate,0);
			textbar(self.num_workers - j + 1,self.num_workers)
		end

		self.workers = F;

	end
	

	function self = set.prefix(self, value)

		self.prefix = value;

		% make xolotl object 
		A = 0.0628;
		channels = {'NaV','CaT','CaS','ACurrent','KCa','Kd','HCurrent'};
		E =         [50   30  30 -80 -80 -80   -20];
		x = xolotl;
		x.add('compartment','AB','Cm',10,'A',A);
		% add Calcium mechanism
		x.AB.add('prinz/CalciumMech');
		for i = 1:length(channels)
			x.AB.add([self.prefix channels{i}],'gbar',rand*10,'E',E(i));
		end
		x.AB.add('Leak','gbar',0);

		x.t_end = 20e3;
		x.dt = .1;

		x.transpile;
		x.compile;

		self.x = x;

		results = new(Data(xtools.V2metrics(zeros(1e4,1))));
		results.add('all_g',8);
		results.add('CV_ISI_down',10);
		results.add('CV_ISI_up',10);
		results.add('f_down',10);
		results.add('f_up',10);
		self.results = results;

		save_dir = [fileparts(fileparts(which(mfilename))) filesep self.prefix];

		if exist(save_dir,'dir') ~= 7
			mkdir(save_dir)
		end

		self.results.consolidate(save_dir);

	end






end % methods



methods (Static)

	

end


end % classdef