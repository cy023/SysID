clc; clear; close all;
addpath("D:\Project\SysID\System Modeling")
addpath("D:\Project\SysID\Discretization")

%% Transform the spring-mass-damper system to the state-space matrix form
DOF = 2;
m = ones(1, DOF) * 1;
b = ones(1, DOF) * 0.1;
k = ones(1, DOF) * 1;

[Ac, Bc, Cc, Dc] = Spring_Mass_Damper_System_ss(DOF, m, b, k);

%% Transform a continuous time state space to a discrete time state space
fs = 10;        % sampling frequency
Ts = 1 / fs;    % sampling period
L  = 1000;      % length of input signal
chops = 5;
sample_t = linspace(0, Ts*L, L);

Ts = 1
[Ad, Bd, Cd, Dd] = css2dss(Ac, Bc, Cc, Dc, Ts);

%%
L = 1000;
u_rand = rand([2, L]) * 10;
q = size(u_rand,1);  % number of output
m = size(u_rand,1);  % number of input
L = size(u_rand,2);  % number of sampLe

[Y, y_rand] = responseWithNoise(Ad, Bd, Cd, Dd, u_rand);

%%
figure();
subplot(3,1,1);
plot(u_rand(1,:)); hold on
plot(u_rand(2,:)); hold off
title("u\_rand");

subplot(3,1,2);
plot(y_rand(1,:)); hold on
plot(y_rand(2,:)); hold off
title("y\_rand");

%%
freq = linspace(0, fs/2, L/2);
y1_fft = abs(fft(y_rand(1, :)));
y2_fft = abs(fft(y_rand(2, :)));
y1_fft = y1_fft(1:L/2);
y2_fft = y2_fft(1:L/2);

subplot(3,1,3);
plot(freq, y1_fft); hold on
plot(freq, y2_fft); hold off
grid on;
legend("output 1", "output 2");
xlabel("frequency (Hz)");
ylabel("Amplitude");
title("output random exitation");

%% Do circular correlation algorithm, R_yu and R_uu in each section
chop_Y = reshape(     Y, [q, 2*L/chops, chops]);
chop_U = reshape(u_rand, [m,   L/chops, chops]);
chop_y = reshape(y_rand, [q,   L/chops, chops]);

N = 1 + (L/chops-1)*2;
chop_Ryu = zeros([m, N, chops]);
chop_Ruu = zeros([q, N, chops]);
chop_Sy  = zeros([m, L/chops, chops]);
chop_Su  = zeros([q, L/chops, chops]);

for chop = 1 : chops
    for j = 1 : q 
        chop_Ryu(j, :, chop) = xcorr(chop_y(j, :, chop), chop_U(j, :, chop), 'biased');
        chop_Ruu(j, :, chop) = xcorr(chop_U(j, :, chop), chop_U(j, :, chop), 'biased');
        chop_Sy(j,:,chop) = fft(chop_y(j, :, chop));
        chop_Su(j,:,chop) = fft(chop_U(j, :, chop));
    end
end

flat_Ryu = reshape(chop_Ryu, [q, N*chops]);
flat_Ruu = reshape(chop_Ruu, [q, N*chops]);
flat_Sy  = reshape(chop_Sy,  [q, L]);
flat_Su  = reshape(chop_Su,  [q, L]);

time = linspace(0, N*chops*Ts, N*chops);

%
figure();
subplot(2,1,1);
plot(time, abs(flat_Ryu(1, :))); hold on
plot(time, abs(flat_Ryu(2, :))); hold off
grid on;
legend("flat R_{yu}(1)", "flat R_{yu}(2)");
title("flat R_{yu}");

subplot(2,1,2);
plot(time, abs(flat_Ruu(1, :))); hold on
plot(time, abs(flat_Ruu(2, :))); hold off
grid on;
legend("flat R_{uu}(1)", "flat R_{uu}(2)");
title("flat R_{uu}");

%
figure();
subplot(2,1,1);
plot(abs(flat_Sy(1, :))); hold on
plot(abs(flat_Sy(2, :))); hold off
grid on;
legend("flat S_{y}(1)", "flat S_{y}(2)");
title("flat S_{y}");

subplot(2,1,2);
plot(abs(flat_Su(1, :))); hold on
plot(abs(flat_Su(2, :))); hold off
grid on;
legend("flat S_{u}(1)", "flat S_{u}(2)");
title("flat S_{u}");

%%
mean_Ryu = mean(chop_Ryu(:, 1:N, :), 3);
mean_Ruu = mean(chop_Ruu(:, 1:N, :), 3);
time = linspace(0, N*Ts, N);

%
figure();
subplot(2,1,1);
plot(time, mean_Ruu(1, :)); hold on
plot(time, mean_Ruu(2, :)); hold off
grid on;
legend("R_{uu}(1)", "R_{uu}(2)");
xlabel("time (s)");
ylabel("Value");
title("Mean of R_{uu}");

subplot(2,1,2);
plot(time, mean_Ryu(1, :)); hold on
plot(time, mean_Ryu(2, :)); hold off
grid on;
legend("R_{yu}(1)", "R_{yu}(2)");
xlabel("time (s)");
ylabel("Value");
title("Mean of R_{yu}");


%%
mean_Sy = mean(chop_Sy(:, :, :), 3);
mean_Su = mean(chop_Su(:, :, :), 3);
freq = linspace(0, fs/2, L/chops);

%
figure();
subplot(2,1,1);
plot(freq, abs(mean_Su(1, :))); hold on
plot(freq, abs(mean_Su(2, :))); hold off
grid on;
legend("S_{uu}(1)", "S_{uu}(2)");
xlabel("frequency (Hz)");
ylabel("Amplitude");
title("Mean of density spectrum");

subplot(2,1,2);
plot(freq, abs(mean_Sy(1, :))); hold on
plot(freq, abs(mean_Sy(2, :))); hold off
grid on;
legend("S_{yu}(1)", "S_{yu}(2)");
xlabel("frequency (Hz)");
ylabel("Amplitude");
title("Mean of density spectrum");

%%
Gz = mean_Sy .* (mean_Su.^-1);

figure();
plot(freq, abs(Gz(1, :))); hold on
plot(freq, abs(Gz(2, :))); hold off
grid on;
legend("G_z1", "G_z2");
title("Mean of density spectrum");

%%
y_ifft = [ifft(Gz(1, :)); ifft(Gz(2, :))];
t      = linspace(0, Ts*L/chops, L/chops);

figure();
plot(t, abs(y_ifft(1, :))); hold on
plot(t, abs(y_ifft(2, :))); hold off
grid on;
legend("Y^*_1", "Y^*_2");
title("New Markov parameters");
