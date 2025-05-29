%{
number_of_subcarrier_pre_symbol_per=12;
number_of_transmit_antenna=1;
number_of_receive_antenna = 1;
%Pilot_Generator(number_of_subcarrier_pre_symbol_per,number_of_transmit_antenna)

numBits = 10000; % 比特数量
FFTLength = 2048; %106*12; % 子载波数量
CP = 144; % 循环前缀长度
M=16;
Nsym=1;
pilot_sym_num=1;



%raw_data = randi([0 1], numBits, 1); %% Generating random data bits
%data = repmat(data,N * log2(M),1);
guard_band = [floor(FFTLength * 0.10); floor(FFTLength * 0.10)];
data_subcarrier_bit_num_per_sym = (FFTLength-sum(guard_band))* log2(M);
data_subcarrier_num_per_sym = (FFTLength-sum(guard_band));

%%%%%%%%%%%%%%%%%导频生成%%%%%%%%%%%%%%%%%%%%%%%%
pilot_subcarrier_indices=[[guard_band(1)+1:3:FFTLength-guard_band(2)]];

pilot_subcarrier_bit_num_per_sym = length(pilot_subcarrier_indices)*2;  %% 导频bit
pilot_subcarrier =  randi([0 1], pilot_subcarrier_bit_num_per_sym*pilot_sym_num*number_of_transmit_antenna,1);
pilot_signal = qammod(pilot_subcarrier,4,'InputType','bit','UnitAveragePower',true);
%%%%%%%%%%%%%%%%%%%%%%%%%导频生成%%%%%%%%%%%%%%%%%%%%%%%%%

data = randi([0 1], data_subcarrier_bit_num_per_sym*Nsym*number_of_transmit_antenna-length(pilot_signal)*log2(M)*pilot_sym_num,1);
tx_signal = qammod(data,M,'InputType','bit','UnitAveragePower',true);

datareshape = reshape(tx_signal, [data_subcarrier_num_per_sym-length(pilot_signal),Nsym,number_of_transmit_antenna]);

ofdmMod = comm.OFDMModulator('FFTLength',FFTLength,'CyclicPrefixLength',CP,'NumGuardBandCarriers',guard_band, ...
    'NumSymbols',Nsym,'NumTransmitAntennas',  number_of_transmit_antenna,'PilotCarrierIndices', pilot_subcarrier_indices.', ...
    'PilotInputPort', true);

ofdmDemod = comm.OFDMDemodulator('FFTLength',FFTLength,'CyclicPrefixLength',CP,'NumGuardBandCarriers',guard_band, ...
    'NumSymbols',Nsym, 'NumReceiveAntennas', number_of_receive_antenna,'PilotCarrierIndices', pilot_subcarrier_indices.', ...
    'PilotOutputPort', true);

ofdmData = step(ofdmMod, datareshape,pilot_signal);

[ofdmDataOut,channel_path_gain] = step(ofdmDemod, ofdmData);
demoudellr = qamdemod(ofdmDataOut, M,'OutputType','bit','UnitAveragePower',true);
%%%%%%%%%%%%%导频输出%%%%%%%%%%%%%%%%%%%%%%%%%%
demodpilot = qamdemod(channel_path_gain, 4,'OutputType','bit','UnitAveragePower',true);
isequal(demodpilot,pilot_subcarrier)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

datasend=reshape(data, [data_subcarrier_bit_num_per_sym*Nsym*number_of_transmit_antenna-length(pilot_signal)*log2(M)*pilot_sym_num,Nsym,number_of_transmit_antenna]);
isequal(demoudellr,datasend)

%}

 % M = 8;
 %  % Configure a MIMO channel object
 %  chan = comm.MIMOChannel(...
 %      "SampleRate",                1000,...
 %      "PathDelays",                [0 1e-3],...
 %      "AveragePathGains",          [3 5],...
 %      "NormalizePathGains",        false,...
 %      "MaximumDopplerShift",       5,...
 %      "TransmitCorrelationMatrix", cat(3, eye(2), [1 0.1;0.1 1]),...
 %      "ReceiveCorrelationMatrix",  cat(3, [1 0.2;0.2 1], eye(2)),...
 %      "RandomStream",              "mt19937ar with seed",...
 %      "Seed",                      33,...
 %      "PathGainsOutputPort",       true);
 % 
 %  % Split PSK signals into two streams and pass them through the channel
 %  chanIn = pskmod(randi([0 M-1],5e4,2),M,pi/8);
 %  [chanlOut, pathGains] = chan(chanIn);
 % 
 %  % Confirm that the transmit and receive spatial correlation values are
 %  % close to the TransmitCorrelationMatrix and ReceiveCorrelationMatrix
 %  % properties values of chan, respectively.
 %  disp('Tx spatial correlation, first path, first Rx:');
 %  disp(corrcoef(squeeze(pathGains(:,1,:,1)))); % Close to an identity matrix
 %  disp('Tx spatial correlation, second path, second Rx:');
 %  disp(corrcoef(squeeze(pathGains(:,2,:,2)))); % Close to [1 0.1;0.1 1]
 %  disp('Rx spatial correlation, first path, second Tx:');
 %  disp(corrcoef(squeeze(pathGains(:,1,2,:)))); % Close to [1 0.2;0.2 1]
 %  disp('Rx spatial correlation, second path, first Tx:');
 %  disp(corrcoef(squeeze(pathGains(:,2,1,:)))); % Close to an identity matrix

  % Example 2: 
  %   Filter an input signal using the "Sum of sinusoids" technique for
  %   the fading process. The input signal is first filtered through the
  %   channel with the InitialTimeSource property set to "Property". The 
  %   same signal is converted into frames which are successively
  %   filtered through the same channel with the InitialTimeSource 
  %   property set to "Input port". The fading samples of both 
  %   configurations are compared.

  %Generate random QPSK signals for two transmit antennas
  Ns = 500; Nt = 2; Nr = 2;
  chanIn = pskmod(randi([0 3],Ns,2), 4);

  %Configure a MIMO channel object that uses the "Sum of sinusoids" 
  %technique. The fading process starts at the initial time of 0.
  chan = comm.MIMOChannel(...
      "SampleRate",                       10000, ...
      "PathDelays",                [4e-1 2e-1],...
      "AveragePathGains",          [10 20],...
      "NormalizePathGains",               false, ...
      "MaximumDopplerShift",              10, ... 
      "SpatialCorrelationSpecification",  "None", ...
      "NumReceiveAntennas",               Nt, ...
      "NumTransmitAntennas",              Nr, ...
      "RandomStream",                     "mt19937ar with seed", ...
      "PathGainsOutputPort",              true, ...
      "FadingTechnique",                  "Filtered Gaussian noise", ...
      "Visualization","Impulse and frequency responses");

  %Pass QPSK signals through the channel
  [~, pathGains1] = chan(chanIn);

  %The input signal is converted into frames which are successively
  %filtered through the same channel. The transmission time of each
  %frame is controlled by the initial time input.
  release(chan);
  chan.InitialTimeSource = "Input port";
  frameSpacing = 100;     % The spacing between frames in samples
  frameSize = 10;         % Frame size in samples   

  pathGains2 = zeros(Ns, 1, Nt, Nr);
  % for i = 1:(length(chanIn)/frameSpacing)
  %     inIdx = frameSpacing*(i-1) + (1:frameSize);
  %     initialTime = (inIdx(1)-1) * (1/chan.SampleRate);
  %     [~, pathGains2(inIdx,1,:,:)] = chan(chanIn(inIdx,:), initialTime);  
  % end

  %Plot fading samples for transmit and receive antenna 1 from both
 % implementations
  %plot(abs(pathGains1(:,1,1,1)),'o-b'); hold on;
  %plot(abs(pathGains1(:,2,1,1)),'*-r'); hold on;
 %plot(abs(pathGains2(:,1,1,1)),'*-r'); 
  grid on; 
  axis square;
  legend('InitialTimeSource : Property', 'InitialTimeSource : Input port');
  xlabel('Time (s)'); ylabel('|Output|');

    path1 = pathGains1(:,1,1,1);
    path2 = pathGains1(:,2,1,1);
    h1 = fft(path1.');
    h2 = fft(path2.');
    plot(abs(h1),'o-b'); hold on;
    plot(abs(h2),'*-r')
    grid on;
     axis square;
     xlim([-10,600]);

% fs = 10e6;                                                % Hz
% pathDelays = [0 30 150 310 370 710 1090 1730 2510]*1e-9;  % Seconds
% avgPathGains = [0 -1.5 -1.4 -3.6 -0.6 -9.1 -7 -12 -16.9]; % dB
% fD = 100;   
% 
% dp{1} = doppler('Jakes');
% mimoChan = comm.MIMOChannel(SampleRate=fs, ...
%     PathDelays=pathDelays, ...
%     AveragePathGains=avgPathGains, ...
%     MaximumDopplerShift=fD, ...
%     Visualization='Doppler spectrum', ...
%     DopplerSpectrum=dp);
% 
% x = randi([0 1],1000,2);
% y = mimoChan(x);
