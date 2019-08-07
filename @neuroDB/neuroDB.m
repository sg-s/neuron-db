classdef neuroDB < handle


properties

	x@xolotl

	bounds@struct
	
	prefix@char

	results@Data

	workers
	CurrentPool
	NumWorkers

	% how many models to save in one data dump?
	SimChunkSize = 1e3


	% with what probability should I drop channeles?
	% only applies when SampleFcn is not set
	DeletionProbability = .05

	handles

	% keep only
	KeepOnly@struct
	


	
	DataDump

	% allow user-defined custom sample function
	SampleFcn@function_handle

	% allow user to run some function on the model
	% after we sample it
	PostSampleFcn@function_handle

	% allow user-defined custom keep only function
	KeepOnlyFcn@function_handle

end

methods

	% constructor
	function self = neuroDB()

		% set up some bounds
		bounds.NaV = [0 2e3];
		bounds.CaT = [0 300];
		bounds.CaS = [0 400];
		bounds.ACurrent = [0 1e3];
		bounds.KCa = [0 1e3];
		bounds.Kd = [0 2e3];
		bounds.HCurrent = [0 100];
		bounds.Leak = [0 10];
		self.bounds = bounds;

		KeepOnly.BurstPeriod = [-Inf Inf];
		KeepOnly.duty_cycle = [0  1];
		self.KeepOnly = KeepOnly;



	end % constructor 




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

		self.results = new(Data(xtools.V2metrics(zeros(1e4,1))));
		self.results.add('all_g',8);
		self.results.add('CV_ISI_down',10);
		self.results.add('CV_ISI_up',10);
		self.results.add('f_down',10);
		self.results.add('f_up',10);

	end


	function self = set.DataDump(self,value)
		self.DataDump = value;
		if exist(self.DataDump,'dir') ~= 7
			mkdir(self.DataDump)
		end

		if self.results.size == 0
			self.results = Data(self.DataDump);
		else
			self.results.consolidate(self.DataDump);
		end

		

	end






end % methods



methods (Static)

	

end


end % classdef