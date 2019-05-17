	function simulate(self)


		self.check;

		x = self.x;

		n_sims = 0;
		disp('A        CaS       CaT       H        KCa         Kd        Leak      NaV       FR (Hz)    Speed')
		disp('-------------------------------------------------------------------------------------------------------')

		results = Data(xtools.V2metrics(zeros(1e4,1)));
		results = results.new();
		results.add('all_g',8);
		results.add('CV_ISI_down',10);
		results.add('CV_ISI_up',10);
		results.add('f_down',10);
		results.add('f_up',10);
		results.add('Ca_average',1);

		% also add fields from post_sample_func
		if ~isempty(self.post_sample_func)
			temp = struct;
			temp = self.post_sample_func(x,temp);
			fn = fieldnames(temp);
			for i = 1:length(fn)
				results.add(fn{i},length(temp.(fn{i})));
			end
		end


		results.prealloc(self.sim_chunk_size);

		while true

			if rem(n_sims,self.sim_chunk_size) == 0 
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

			% allow for some channels to drop out
			g = x.get('*gbar');
			g(rand(8,1)>1 - self.deletion_probability) = 0;
			x.set('*gbar',g);

			% transient
			x.reset;
			x.AB.CaS.E = 30;
			x.AB.CaT.E = 30;
			

			try
				x.integrate;
				V = x.integrate;
			catch
				% sometimes the integration fails because the 
				% mex file is "too short". goddamn it, matlab
				pause(2)
				continue
			end

			time_idx = time_idx + 1;

			t = toc;


			try
				new_metrics = xtools.V2metrics(V,'sampling_rate',1/x.dt);
			catch
				disp('Something went wrong with trying to measure the metrics')
				continue
			end

			if new_metrics.firing_rate == 0
				disp('Silent neuron...')
				continue
			end

			if ~isempty(self.keep_only_burst_period)
				if isnan(new_metrics.burst_period)
					disp('Undefined burst period...')
					continue
				end
			end

			if ~isempty(self.keep_only_duty_cycle)
				if isnan(new_metrics.duty_cycle_mean)
					disp('Undefined duty_cycle_mean...')
					continue
				end
			end

			% ignore things outside keep_only
			if new_metrics.duty_cycle_mean < self.keep_only_duty_cycle(1)
				disp('Duty cycle outside range...')
				continue
			end

			if new_metrics.duty_cycle_mean > self.keep_only_duty_cycle(2)
				disp('Duty cycle outside range...')
				continue
			end

			if new_metrics.burst_period < self.keep_only_burst_period(1)
				disp('Burst period outside range...')
				continue
			end

			if new_metrics.burst_period > self.keep_only_burst_period(2)
				disp('Burst period outside range...')
				continue
			end


		
			this_all_g = x.get('*gbar');

			% show this live 
			for i = 1:8
				fprintf(strlib.fix(strlib.oval(this_all_g(i)),10))
			end

			fprintf(strlib.fix(strlib.oval(new_metrics.firing_rate),10))
			fprintf(strlib.fix(strlib.oval(time_idx/t),10))
			fprintf('\n')

			% measure the f-I curve
			data = self.x.fI;
			new_metrics.f_up = data.f_up;
			new_metrics.f_down = data.f_down;
			new_metrics.CV_ISI_up = data.CV_ISI_up;
			new_metrics.CV_ISI_down = data.CV_ISI_down;


			% run the post_sample function
			if ~isempty(self.post_sample_func)
				try
					new_metrics = self.post_sample_func(x,new_metrics);
				catch
					% sometimes the integration fails because the 
					% mex file is "too short". goddamn it, matlab
					pause(2)
					continue
				end
			end

			% append
			new_metrics.all_g = this_all_g;
			new_metrics.Ca_average = x.get('*Ca_average');
			results+new_metrics;

			n_sims = n_sims + 1;

			if results.size == self.sim_chunk_size
				% need to save 
				disp('Saving...')
				save_name = [self.data_dump filesep hashlib.md5hash(now) '.data'];
				results.save(save_name);

				results.reset;

				disp('A        CaS       CaT       H        KCa         Kd        Leak      NaV       FR (Hz)    Speed')
				disp('-------------------------------------------------------------------------------------------------------')

			end

		end

