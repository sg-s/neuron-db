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

	metrics
	all_g

	workers
	current_pool
	num_workers

end

methods

	% constructor
	function self = neuroDB()

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

		self.loadDB;

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


	function simulate(self)


		x = self.x;

		n_sims = 0;
		disp('A        CaS       CaT       H        KCa         Kd        Leak      NaV       FR (Hz)    Speed')
		disp('-------------------------------------------------------------------------------------------------------')

		while true

			if rem(n_sims,1000) == 0 
				temp = x.integrate;
				metrics = repmat(xtools.V2metrics(0*temp),1000,1);
				all_g = NaN(1000,8);
				idx =  1;
				time_idx = 1;
				tic
			end

			% pick a random point in the cube
			x.AB.NaV.gbar = rand*diff(self.NaV_range) + self.NaV_range(1);
			x.AB.CaT.gbar = rand*diff(self.CaT_range) + self.CaT_range(1);
			x.AB.CaS.gbar = rand*diff(self.CaS_range) + self.CaS_range(1);
			x.AB.ACurrent.gbar = rand*diff(self.A_range) + self.A_range(1);
			x.AB.KCa.gbar = rand*diff(self.KCa_range) + self.KCa_range(1);
			x.AB.Kd.gbar = rand*diff(self.Kd_range) + self.Kd_range(1);
			x.AB.HCurrent.gbar = rand*diff(self.H_range) + self.H_range(1);
			x.AB.Leak.gbar = rand*diff(self.Leak_range) + self.Leak_range(1);

			% transient
			x.reset;
			x.AB.CaS.E = 30;
			x.AB.CaT.E = 30;
			x.integrate;

			V = x.integrate;

			time_idx = time_idx + 1;

			t = toc;


			try
				metrics(idx) = xtools.V2metrics(V,'sampling_rate',1/x.dt);
			catch
				disp('Something went wrong with trying to measure the metrics')
				continue
			end


			if metrics(idx).firing_rate == 0
				disp('Silent neuron, skipping...')
				continue
			end

			all_g(idx,:) = x.get('*gbar');

			% show this live 
			for i = 1:8
				fprintf(flstring(oval(all_g(idx,i)),10))
			end

			fprintf(flstring(oval(metrics(idx).firing_rate),10))
			fprintf(flstring(oval(time_idx/t),10))
			fprintf('\n')


			n_sims = n_sims + 1;
			idx = idx + 1;

			if idx > 1000
				% need to save 
				disp('Saving...')
				save_name = [GetMD5(now) '.neuroDB'];
				save(save_name,'all_g','metrics','-v7.3');

				disp('A        CaS       CaT       H        KCa         Kd        Leak      NaV       FR (Hz)    Speed')
				disp('-------------------------------------------------------------------------------------------------------')

			end

		end

	end



end % methods



methods (Static)

	

end


end % classdef