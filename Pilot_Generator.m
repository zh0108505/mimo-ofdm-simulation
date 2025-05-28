function [pilot_signal,pilot_bit] = Pilot_Generator(guard_band,pilot_subcarrier_indices,pilot_sym_num,FFTLength,number_of_transmit_antenna)

    pilot_subcarrier_indices=[guard_band(1)+1:3:FFTLength-guard_band(2)];
    pilot_subcarrier_bit_num_per_sym = length(pilot_subcarrier_indices)*2;  %% 导频bit
    pnseq = comm.PNSequence('Polynomial',[1 0 0 0 1 0 0 1], 'SamplesPerFrame', pilot_subcarrier_bit_num_per_sym*pilot_sym_num*number_of_transmit_antenna,...
                            'InitialConditions',[1 1 1 1 1 1 1]); %% Generating PN sequence
    pilot = pnseq(); %% Creating pilot symbols
 %   pilots = repmat(pilot, 1, 4 ); %% Expanding to all pilot tones
 %   pilots = 2*double(pilots.'<1)-1; %% Converting bipolar to unipolar
 %   pilots(4,:) = -1*pilots(4,:); %% Inverting last pilot symbol
 %   pilot_symbols = repmat(pilots,[1, 1, number_of_transmit_antenna]); %% Generating pilot symbols for multiple antennas

    pilot_bit=pilot;

    %pilot_subcarrier =  randi([0 1], pilot_subcarrier_bit_num_per_sym*pilot_sym_num*number_of_transmit_antenna,1);
    pilot_signal = qammod(pilot,4,'InputType','bit','UnitAveragePower',true);

end