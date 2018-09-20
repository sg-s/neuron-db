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


	prefix = 'prinz/';

	results@Data

	workers
	current_pool
	num_workers

	sim_chunk_size = 1e3

end

methods

	% constructor
	function self = neuroDB()

		results = new(Data(xtools.V2metrics(zeros(1e4,1))));
		results.add('all_g',8);
		self.results = results;

		% make xolotl object 
		A = 0.0628;
		channels = {'NaV','CaT','CaS','ACurrent','KCa','Kd','HCurrent'};
		E =         [50   30  30 -80 -80 -80   -20];
		x = xolotl;
		x.add('compartment','AB','Cm',10,'A',A);
		% add Calcium mechanism
		x.AB.add('CalciumMech1');
		for i = 1:length(channels)
			x.AB.add([self.prefix channels{i}],'gbar',rand*10,'E',E(i));
		end
		x.AB.add('Leak','gbar',0);

		x.t_end = 20e3;
		x.dt = .1;

		x.transpile;
		x.compile;

		self.x = x;


	end % constructor 

	function consolidate(self)

		metrics = self.metrics;
		all_g = self.all_g;

		if isempty(metrics)
			disp('No metrics, aborting')
			return
		end

		fn = fieldnames(metrics);

		for i = 1:length(fn)
			disp(['Generating ' fn{i} ' vector...'] )
			eval([fn{i} ' = vertcat(metrics.(fn{i}));'])
		end

		save('consolidated.db','all_g','-v7.3','-nocompression')
		for i = 1:length(fn)
			save('consolidated.db',fn{i},'-nocompression','-append')
		end

		disp('Deleting unconsolidated DB files...')
		all_files = dir([fileparts(which(mfilename)) filesep '*.neuroDB']);
		for i = 1:length(all_files)
			delete([all_files(i).folder filesep all_files(i).name] )
		end


	end

	function varargout = show(self, idx)

		self.x.set('*gbar',self.all_g(idx,:))
		self.x.reset;
		self.x.integrate;

		if nargout == 1
			V = self.x.integrate;
			varargout{1} = V;
			return

		end
		self.x.plot;

	end


	function self = loadDB(self)

		% load consolidated.db, if it exists 
		all_files = dir([fileparts(which(mfilename)) filesep 'consolidated.db']);
		if ~isempty(all_files)
			load(all_files(1).name,'-mat')
			var_names = whos('-file',all_files(1).name);

			for i = 1:length(var_names)
				if strcmp(var_names(i).name,'all_g')
					eval(['self.' var_names(i).name '=' var_names(i).name ';']);
				else
					eval(['self.metrics.' var_names(i).name '=' var_names(i).name ';']);
				end
			end

		end

		% load results of prev sim
		disp('Merging new files into DB...')
		clear var_names
		all_files = dir([fileparts(which(mfilename)) filesep '*.neuroDB']);
		for i = 1:length(all_files)
			textbar(i,length(all_files))
			load([all_files(i).folder filesep all_files(i).name],'-mat')

			if ~exist('var_names','var')
				var_names = [fieldnames(metrics); 'all_g'];
			end

			for j = 1:length(var_names)
				if strcmp(var_names{j},'all_g')
					self.all_g = vertcat(self.all_g,all_g);
				else
					this_var = var_names{j};
					try
						eval(['self.metrics.' this_var ' = vertcat(self.metrics.' this_var ', vertcat(metrics.' this_var  '));']);
					catch
						eval(['self.metrics.' this_var ' = vertcat(metrics.' this_var  ');']);
					end
				end
			end
		end
		disp([mat2str(size(self.all_g,1)) '  models loaded'])


		self.consolidate;

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






end % methods



methods (Static)

	

end


end % classdef