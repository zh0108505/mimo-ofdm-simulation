%%%%%%%%%%%%%%%parameter%%%%%%%%%%%%%%%%%%%%%%%%%%%
coding_rate = 1/2; %% Declaring coding rate [1/3 or 1/2]

FFTLength = 2048; %106*12; % 子载波数量
CP = 144; % 循环前缀长度
M=16;
Nsym=1;
pilot_sym_num=1;
guard_band = [floor(FFTLength * 0.10); floor(FFTLength * 0.10)];
data_subcarrier_bit_num_per_sym = (FFTLength-sum(guard_band))* log2(M);
data_subcarrier_num_per_sym = (FFTLength-sum(guard_band));

number_of_transmit_antenna=1;
number_of_receive_antenna = 1;
pilot_subcarrier_indices=[guard_band(1)+1:3:FFTLength-guard_band(2)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%% Initializing parameters for 24 bit Cyclic Redundancy Check (CRC) error detection
crc_24_generator = comm.CRCGenerator('Polynomial',[1 1 zeros(1, 16) 1 1 0 0 0 1 1]);
crc_bit = 24;
crc_24_detector = comm.CRCDetector('Polynomial',[1 1 zeros(1, 16) 1 1 0 0 0 1 1]);
%%% Initializing parameters for 24 bit Cyclic Redundancy Check (CRC) error detection

%%% Initializing encoder and decoder based on coding rate
ldpc_encoder = comm.LDPCEncoder(dvbs2ldpc(coding_rate));
ldpc_decoder = comm.LDPCDecoder(dvbs2ldpc(coding_rate));
ldpc_config = ldpcEncoderConfig(dvbs2ldpc(coding_rate));
ldpc_num_bits = ldpc_config.NumInformationBits;
%%% Initializing encoder and decoder based on coding rate

%%% Initializing modulation parameters

%Constellation = qammod([0:63],64,'UnitAveragePower',true);
%hQAMMod = comm.GeneralQAMModulator(Constellation); 

%hQAMDeMod = comm.GeneralQAMDemodulator(Constellation,'DecisionMethod','Hard decision')
%hSoftQAMDeMod = comm.GeneralQAMDemodulator(Constellation,'BitOutput',true,'DecisionMethod','Log-likelihood ratio');

%%% Initializing modulation parameters

%%%%%%AWGN channel%%%%%%%%%%%%%%%%
awgn_channel = comm.AWGNChannel('NoiseMethod', 'Variance', 'VarianceSource', 'Input port');


%SNR_linear = 10^(SNR_dB(k)/10);
%noise_var = 1/(2*SNR_linear); % 复数噪声方差
%%%%%%%%%%%%%%%%%%%%AWGN channel%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%OFDM 信道调制与解调obj 初始化 start%%%%%%%%%%%%%%%%%%%%%%%%%%%
ofdmMod = comm.OFDMModulator('FFTLength',FFTLength,'CyclicPrefixLength',CP,'NumGuardBandCarriers',guard_band, ...
    'NumSymbols',Nsym,'NumTransmitAntennas',  number_of_transmit_antenna,'PilotCarrierIndices', pilot_subcarrier_indices.', ...
    'PilotInputPort', true);

ofdmDemod = comm.OFDMDemodulator('FFTLength',FFTLength,'CyclicPrefixLength',CP,'NumGuardBandCarriers',guard_band, ...
    'NumSymbols',Nsym, 'NumReceiveAntennas', number_of_receive_antenna,'PilotCarrierIndices', pilot_subcarrier_indices.', ...
    'PilotOutputPort', true);
%%%%%%%%%%%%%%%%%%OFDM 信道调制与解调obj 初始化 end%%%%%%%%%%%%%%%%%%%%%%%
