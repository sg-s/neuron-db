% small script to show how this works

if ~exist('n','var')
	n = neuroDB;
end

% find bursting models with some specific props

show_these = find(n.metrics.n_spikes_per_burst_mean > 4 & n.metrics.n_spikes_per_burst_mean < 6 & n.metrics.spike_peak_std < 5 & n.metrics.duty_cycle_mean > .2 & n.metrics.duty_cycle_mean < .5 & n.metrics.duty_cycle_std < .1 & n.metrics.min_V_mean < -60);  


disp([mat2str(length(show_these)) ' models found matching these criteria'])

% show distributions and correlations of gbars of this


figure('outerposition',[300 300 1400 1400],'PaperUnits','points','PaperSize',[1400 1400]); hold on
for i = 1:8
	for j = i:8
		subplot(8,8,(i-1)*8 + j); hold on

		if i == j
			g = n.all_g(show_these,i);
			hist(g)
		else
			plot(n.all_g(show_these,i),n.all_g(show_these,j),'ko')
		end
	end
end

% % find spiking neurons
% show_these = find((isnan(n.metrics.burst_period) | n.metrics.n_spikes_per_burst_mean == 1) & n.metrics.firing_rate > 3);


show_these = shuffle(show_these);

time = (n.x.dt:n.x.dt:n.x.t_end)*1e-3;

figure('outerposition',[300 300 1800 1200],'PaperUnits','points','PaperSize',[1800 1200]); hold on
for i = 1:4
	ax(i) = subplot(2,2,i); hold on
	plot_handles(i) = plot(ax(i),time,time*NaN,'k');
	set(ax(i),'XLim',[0 5],'YLim',[-90 60])
end



for i = 1:length(show_these)

	plot_here = (rem(i,4) + 1);

	V = n.show(show_these(i));
	plot_handles(plot_here).YData = V;
	drawnow

end
