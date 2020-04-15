classdef neuroDB < ConstructableHandle


properties

	x (1,1) xolotl

	bounds (1,1) struct


	results (1,1) Data

	workers
	CurrentPool
	NumWorkers

	% how many models to save in one data dump?
	SimChunkSize (1,1) double = 1e3


	% with what probability should I drop channeles?
	% only applies when SampleFcn is not set
	DeletionProbability (1,1) double = .05

	handles

	% keep only
	KeepOnly (1,1) struct
	


	
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
	function self = neuroDB(varargin)
        self = self@ConstructableHandle(varargin{:});   

		% set up some bounds
		bounds.NaV = [1e3 2e3];
		bounds.CaT = [0 300];
		bounds.CaS = [0 400];
		bounds.ACurrent = [0 1e3];
		bounds.KCa = [0 1e3];
		bounds.Kd = [0 2e3];
		bounds.HCurrent = [0 100];
		bounds.Leak = [0 10];
		self.bounds = bounds;

		KeepOnly.BurstPeriod = [];
		KeepOnly.DutyCycle = [];
		self.KeepOnly = KeepOnly;

		self.results = new(Data(xtools.V2metrics(zeros(1e4,1))));
		self.results.add('all_g',8);
		self.results.add('CV_ISI_down',10);
		self.results.add('CV_ISI_up',10);
		self.results.add('f_down',10);
		self.results.add('f_up',10);



	end % constructor 


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