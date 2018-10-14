function spiking_callback(self, src, event)


if self.handles.ax.f ~= gca
	return
end


p = get(self.handles.ax.f,'CurrentPoint');

if strcmp(self.handles.type,'spiking')
	firing_rate = p(1,1);
	self.handles.f_marker.XData = [firing_rate firing_rate];

	% find a model closest to this firing rate 
	[~,show_this] = min(abs(self.results.firing_rate(self.handles.show_these) - firing_rate));

	% also show gbars of models with this (round) integer firing rate
	firing_rate = ceil(firing_rate);
	show_these = find(ceil(self.results.firing_rate) == firing_rate);
	

else
	DC = ceil(p(1,1));
	T = ceil(p(1,2));
	T = self.handles.Xedges(T);
	DC = self.handles.Yedges(DC);


	temp = abs(self.results.burst_period(self.handles.show_these) - T)./T + abs(self.results.duty_cycle_mean(self.handles.show_these) - DC)./DC;
	[~,show_this] = min(temp);

	DC = self.results.duty_cycle_mean(self.handles.show_these(show_this));
	T = self.results.burst_period(self.handles.show_these(show_this));

	X = find(self.handles.Xedges > T,1,'first');
	Y = find(self.handles.Yedges > DC,1,'first');

	self.handles.f_marker1.XData = [Y Y];
	self.handles.f_marker1.YData = [0 300];

	self.handles.f_marker2.XData = [0 100];
	self.handles.f_marker2.YData = [X X];

	% show gbars of some nearby models
	show_these = find(abs(self.results.burst_period - T)./T < .1 & abs(self.results.duty_cycle_mean - DC)./DC < .1);




end

show_these = intersect(show_these, self.handles.show_these);


V = self.show(self.handles.show_these(show_this));

self.handles.V.YData = V;


if length(show_these) > 1e3
	show_these = show_these(1:1e3);
end


for i = 1:8
	for j = i:8
		if i == j
			continue
		end

		self.handles.gbars(i,j).XData = self.results.all_g(show_these,j);
		self.handles.gbars(i,j).YData = self.results.all_g(show_these,i);


	end

end