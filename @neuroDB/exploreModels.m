% small script to show how this works
% this shows spiking neurons 

function exploreModels(self, type)

if nargin < 2
	type = 'spiking';
end


if strcmp(type,'spiking')
	show_these = find(self.results.isi_std./self.results.isi_mean < .01 & self.results.firing_rate > 0); 
else
	% bursting models 
	show_these = find(self.results.burst_period_std < .1 ...
	            & self.results.duty_cycle_std./self.results.duty_cycle_mean < .1 ...
	            & self.results.min_V_in_burst_mean > self.results.min_V_mean ...
	            & self.results.min_V_mean < -60 ...
	            & self.results.spike_peak_std./self.results.spike_peak_mean < .1); 
end



disp([mat2str(length(show_these)) ' models found matching these criteria'])

% show distributions and correlations of gbars of this

clear handles

handles.fig = figure('outerposition',[300 300 1400 1400],'PaperUnits','points','PaperSize',[1400 1400]); hold on
for i = 1:8
	for j = i:8
		

		if i == j
			% g = self.results.all_g(show_these,i);
			% hist(g)
		else
			subplot(8,8,(i-1)*8 + j); hold on
			handles.gbars(i,j) = scatter(NaN,NaN,10,'MarkerFaceColor',[.5 .5 .5],'MarkerEdgeColor','k','MarkerFaceAlpha',.1,'MarkerEdgeAlpha',.1);
		end
	end
end


handles.ax.V = subplot(3,2,5); hold on
handles.ax.V.Position = [.05 .05 .5 .3];
if strcmp(type,'spiking')
	self.x.t_end = 1e3;
	time = (self.x.dt:self.x.dt:self.x.t_end)*1e-3;
	set(handles.ax.V,'XLim',[0 1],'YLim',[-90 60])
else
	self.x.t_end = 5e3;
	time = (self.x.dt:self.x.dt:self.x.t_end)*1e-3;
	set(handles.ax.V,'XLim',[0 5],'YLim',[-90 60])
end
handles.V = plot(handles.ax.V,time,time*NaN,'k');


handles.ax.f = axes; hold on
handles.ax.f.Position = [.05 .4 .3 .25];

if strcmp(type,'spiking')
	% plot distribution of all firing rates
	[hy,hx] = histcounts(self.results.firing_rate(show_these),200);
	hx = hx(1:end-1) + mean(diff(hx));
	stairs(handles.ax.f,hx,hy,'k','LineWidth',2)
	set(handles.ax.f,'YScale','log')
	xlabel(handles.ax.f,'Firing rate (Hz)')
	ylabel(handles.ax.f,'# of models')
	handles.f_marker = plot(handles.ax.f,[5 5],[1 max(hy)],'r');
else
	% bursting. make a 2D heatmap on duty cycle and burst period
	T = self.results.burst_period(show_these);
	DC = self.results.duty_cycle_mean(show_these);
	[N,Xedges,Yedges] = histcounts2(T,DC,linspace(0,3000,300),linspace(0,1,100));
	set(handles.ax.f,'YTick',linspace(0,300,4),'YTickLabel',{'0','1','2','3'})
	set(handles.ax.f,'XTick',linspace(0,100,6),'XTickLabel',{'0','.2','.4','.6','.8','1'})
	imagesc(handles.ax.f,log10(N));
	handles.Xedges = Xedges;
	handles.Yedges = Yedges;
	xlabel(handles.ax.f,'Duty cycle')
	ylabel(handles.ax.f,'Burst period (s)')

	handles.f_marker1 = plot(handles.ax.f,[NaN NaN],[NaN NaN],'r');
	handles.f_marker2 = plot(handles.ax.f,[NaN NaN],[NaN NaN],'r');

end


set(handles.fig,'WindowButtonDownFcn',@self.spiking_callback)

handles.type = type;

handles.show_these = show_these;

self.handles = handles;



return



% % find spiking neurons
% show_these = find((isnan(n.metrics.burst_period) | n.metrics.n_spikes_per_burst_mean == 1) & n.metrics.firing_rate > 3);


show_these = shuffle(show_these);


for i = 1:length(show_these)

	V = n.show(show_these(i));
	plot_handles.YData = V;
	drawnow

end
