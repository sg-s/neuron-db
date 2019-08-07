%%
% simulate picks a new model and simulates it, and measures its metrics
% and saves it

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

% also add fields from PostSampleFcn
if ~isempty(self.PostSampleFcn)
	temp = struct;
	temp = self.post_sample_func(x,temp);
	fn = fieldnames(temp);
	for i = 1:length(fn)
		results.add(fn{i},length(temp.(fn{i})));
	end
end


results.prealloc(self.SimChunkSize);

while true

	if rem(n_sims,self.SimChunkSize) == 0 
		time_idx = 1;
		tic
	end

	% pick a random point in the cube
	if isempty(self.SampleFcn)
		x.AB.NaV.gbar = rand*diff(self.bounds.NaV) + self.bounds.NaV(1);
		x.AB.CaT.gbar = rand*diff(self.bounds.CaT) + self.bounds.CaT(1);
		x.AB.CaS.gbar = rand*diff(self.bounds.CaS) + self.bounds.CaS(1);
		x.AB.ACurrent.gbar = rand*diff(self.bounds.A) + self.bounds.A(1);
		x.AB.KCa.gbar = rand*diff(self.bounds.KCa) + self.bounds.KCa(1);
		x.AB.Kd.gbar = rand*diff(self.bounds.Kd) + self.bounds.Kd(1);
		x.AB.HCurrent.gbar = rand*diff(self.bounds.H) + self.bounds.H(1);
		x.AB.Leak.gbar = rand*diff(self.bounds.Leak) + self.bounds.Leak(1);

		% allow for some channels to drop out
		g = x.get('*gbar');
		g(rand(8,1)>1 - self.DeletionProbability) = 0;
		x.set('*gbar',g);
	else
		% custom SampleFcn defined...
		self.SampleFcn(self.bounds, x)
	end

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

	if ~isempty(self.KeepOnly.BurstPeriod)
		if isnan(new_metrics.burst_period)
			disp('Undefined burst period...')
			continue
		end
	end

	if ~isempty(self.KeepOnly.DutyCycle)
		if isnan(new_metrics.duty_cycle_mean)
			disp('Undefined duty_cycle_mean...')
			continue
		end
	end

	% ignore things outside keep_only
	if new_metrics.duty_cycle_mean < self.KeepOnly.DutyCycle(1)
		disp('Duty cycle outside range...')
		continue
	end

	if new_metrics.duty_cycle_mean > self.KeepOnly.DutyCycle(2)
		disp('Duty cycle outside range...')
		continue
	end

	if new_metrics.burst_period < self.KeepOnly.BurstPeriod(1)
		disp('Burst period outside range...')
		continue
	end

	if new_metrics.burst_period > self.KeepOnly.BurstPeriod(2)
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
	if ~isempty(self.PostSampleFcn)
		try
			new_metrics = self.PostSampleFcn(x,new_metrics);
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

	if results.size == self.SimChunkSize
		% need to save 
		disp('Saving...')
		save_name = [self.DataDump filesep hashlib.md5hash(now) '.data'];
		results.save(save_name);

		results.reset;

		disp('A        CaS       CaT       H        KCa         Kd        Leak      NaV       FR (Hz)    Speed')
		disp('-------------------------------------------------------------------------------------------------------')

	end

end % while

