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


		self.current_pool = gcp;
		self.num_workers = self.current_pool.NumWorkers - 1;

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


	function self = loadDB(self)
		% load results of prev sim
		all_files = dir([fileparts(which(mfilename)) filesep '*.neuroDB']);
		for i = 1:length(all_files)
			load([all_files(i).folder filesep all_files(i).name],'-mat')
			self.metrics = [self.metrics; metrics];
			self.all_g = [self.all_g; all_g];
		end
		disp([mat2str(size(self.all_g,1)) '  models loaded'])


	end


	function runOnAllCores(self)


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
		disp('A        CaS       CaT       H        KCa         Kd        Leak      NaV       FR (Hz)')
		disp('---------------------------------------------------------------------------------------------')

		while true

			if rem(n_sims,1000) == 0 
				temp = x.integrate;
				metrics = repmat(xtools.V2metrics(0*temp),1000,1);
				all_g = NaN(1000,8);
				idx =  1;
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
			x.integrate;

			V = x.integrate;
			try
				metrics(idx) = xtools.V2metrics(V);
			catch
				disp('Something went wrong with trying to measure the metrics')
				continue
			end

			all_g(idx,:) = x.get('*gbar');

			% show this live 
			for i = 1:8
				fprintf(flstring(oval(all_g(idx,i)),10))
			end

			fprintf(flstring(oval(metrics(idx).firing_rate),10))

			fprintf('\n')


			n_sims = n_sims + 1;
			idx = idx + 1;

			if idx > 1000
				% need to save 
				disp('Saving...')
				save_name = [GetMD5(now) '.neuroDB'];
				save(save_name,'all_g','metrics');

				disp('A        CaS       CaT       H        KCa         Kd        Leak      NaV       FR (Hz)')
				disp('---------------------------------------------------------------------------------------------')

			end

		end

	end



end % methods



methods (Static)

	

end


end % classdef