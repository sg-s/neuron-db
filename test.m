% small script to show how this works

if ~exist('n','var')
	n = neuroDB;
end

% find bursting models with some specific props

show_these = find(n.metrics.n_spikes_per_burst_mean > 4 & n.metrics.n_spikes_per_burst_mean < 10 & n.metrics.spike_peak_std < 5 & n.metrics.duty_cycle_mean > .2 & n.metrics.duty_cycle_std < .1);  

show_these = find(n.metrics.burst_period_std./n.metrics.burst_period > .05 & n.metrics.n_spikes_per_burst_mean > 4);

disp([mat2str(length(show_these)) ' models found matching these criteria'])

show_these = shuffle(show_these);

figure('outerposition',[300 300 1200 600],'PaperUnits','points','PaperSize',[1200 600]); hold on
for i = 1:length(show_these)

	cla
	V = n.show(show_these(i));
	plot(V)
	drawnow
	pause(3)

end
