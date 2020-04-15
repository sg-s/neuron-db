% small script to show how this works

if ~exist('n','var')
	n = neuroDB;
	n.DataDump = 'prinz/';
	n.x = xolotl.examples.BurstingNeuron('prefix','prinz');
end





% find bursting models with some specific props

show_these = find(n.results.burst_period > .95e3 ...
	            & n.results.burst_period < 1.05e3 ...
	            & n.results.burst_period_std./n.results.burst_period < .01 ...
	            & n.results.duty_cycle_mean > .25 ...
	            & n.results.duty_cycle_mean < .3 ...
	            & n.results.duty_cycle_std./n.results.duty_cycle_mean < .01 ...
	            & n.results.n_spikes_per_burst_mean > 10 ...
	            & n.results.n_spikes_per_burst_mean < 15 ...
	            & n.results.min_V_in_burst_mean > n.results.min_V_mean ...
	            & n.results.min_V_mean < -60);  


disp([mat2str(length(show_these)) ' models found matching these criteria'])

% show distributions and correlations of gbars of this


figure('outerposition',[300 300 1400 1400],'PaperUnits','points','PaperSize',[1400 1400]); hold on
for i = 1:8
	for j = i:8
		subplot(8,8,(i-1)*8 + j); hold on

		if i == j
			g = n.results.all_g(show_these,i);
			hist(g)
		else
			scatter(n.results.all_g(show_these,j),n.results.all_g(show_these,i),10,'MarkerFaceColor',[.5 .5 .5],'MarkerEdgeColor','k','MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1)
		end
	end
end

n.x.t_end = 5e3;
ax_V = subplot(3,2,5); hold on
ax_V.Position = [.05 .05 .5 .3];
time = (n.x.dt:n.x.dt:n.x.t_end)*1e-3;
plot_handles = plot(ax_V,time,time*NaN,'k');
set(ax_V,'XLim',[0 5],'YLim',[-90 60])

% % find spiking neurons
% show_these = find((isnan(n.metrics.burst_period) | n.metrics.n_spikes_per_burst_mean == 1) & n.metrics.firing_rate > 3);


show_these = veclib.shuffle(show_these);


for i = 1:length(show_these)

	V = n.show(show_these(i));
	plot_handles.YData = V;
	drawnow

end
