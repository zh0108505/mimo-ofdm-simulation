
close all;
clc;
clear; 

%%%%%%%%%%%%%%参数初始化start%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SNR_dB = -20:2:80;        % 信噪比范围
err_array = zeros(length(SNR_dB),1);
err_array_before_ldpc = zeros(length(SNR_dB),1);
number_of_bits_per_frame = 32300;


%%%%%%%%%%%%%%%参数初始化end%%%%%%%%%%%%%%%%%%%%%


System_initialize
for k = 1:length(SNR_dB)
    ldpc_decode_data_tmp =[];
    ofdmDataOuttmp = [];
    ofdmDmrsOutTmp = [];
    tx_signal_tmp = [];
    pilot_bit_tmp = [];
    SNR = SNR_dB(k);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%发送 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%发送bit 生成%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    raw_data = logical(randi([0 1], number_of_bits_per_frame, 1)); %% Generating random data bits

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%CRC+ldpc+mode%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    crc_coded_data = step(crc_24_generator, raw_data); %% Adding CRC bits for error checking
    ldpc_extra_bits = ldpc_num_bits - length(crc_coded_data);
    ldpc_data = [crc_coded_data; randi([0 1], ldpc_extra_bits, 1)];
    ldpc_encoded_data = ldpc_encoder(ldpc_data);
    tx_signal_tmp = qammod(ldpc_encoded_data,M,'InputType','bit','UnitAveragePower',true);
    tx_signal = tx_signal_tmp;
    %scatterplot(tx_signal);


    data_transfer_per_slot = data_subcarrier_num_per_sym*Nsym-length(pilot_subcarrier_indices)*pilot_sym_num;
    data_subcarrier_num_per_sym_exclude_dmrs = data_subcarrier_num_per_sym-length(pilot_subcarrier_indices);
    slot_num_need_to_trans = ceil(length(tx_signal)/data_transfer_per_slot);
    tx_signal = [tx_signal; complex(zeros(data_transfer_per_slot * slot_num_need_to_trans - length(tx_signal), 1))];
    
    for turn = 1:slot_num_need_to_trans
        reshaped_modulated_data = reshape(tx_signal((((turn - 1) * data_transfer_per_slot) + 1):(turn * data_transfer_per_slot), 1), ...
        data_subcarrier_num_per_sym_exclude_dmrs, Nsym, number_of_transmit_antenna);
        [pilot_signal,pilot_bit] = Pilot_Generator(guard_band,pilot_subcarrier_indices,pilot_sym_num,FFTLength,number_of_transmit_antenna);
        pilot_bit_tmp = [pilot_bit_tmp;pilot_bit];

        pilot_signal = reshape(pilot_signal, length(pilot_subcarrier_indices), pilot_sym_num,number_of_transmit_antenna);
        %%%%%%%%%%%%%%%%%OFDM 调制%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ofdmData = step(ofdmMod, reshaped_modulated_data,pilot_signal);

        %%%%%%%%%%%%%%%%%%%%%%%%%信道%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        signal_power = 10*log10(var(ofdmData)); %% Calculating signal power 数组方差
        noise_variance = (10.^(0.1.*(signal_power - SNR))) * 1; %% Calculating noise variance

        ofdmData = awgn_channel(ofdmData,noise_variance);
        %ofdmData = awgn(ofdmData, SNR);

        %%%%%%%%%%%%%%%%%OFDM 解调%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [ofdmDataOut,ofdmDmrsOut] = step(ofdmDemod, ofdmData);
        ofdmDataOuttmp = [ofdmDataOuttmp;ofdmDataOut(:)];
        ofdmDmrsOutTmp = [ofdmDmrsOutTmp;ofdmDmrsOut(:)];

    end

    %datasend_bit = qamdemod(ofdmDmrsOutTmp, M,'OutputType','bit','UnitAveragePower',true);

    %%%%%%%%%%%%%%%%%%%%QAM 信号解调%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    demoudebit = qamdemod(ofdmDataOuttmp(1:length(tx_signal_tmp)), M,'OutputType','bit','UnitAveragePower',true);
    demodpilot = qamdemod(ofdmDmrsOutTmp, 4,'OutputType','bit','UnitAveragePower',true);
    [num, err] = biterr(ldpc_encoded_data,demoudebit,1);
    err_array_before_ldpc(k) = err;
    fprintf("ldpc encode bit :%d\n",isequal(ldpc_encoded_data,demoudebit))
    fprintf("dmrs bit :%d\n",isequal(ldpc_encoded_data,demoudebit))

    demoudellr = qamdemod(ofdmDataOuttmp(1:length(tx_signal_tmp)), M,'OutputType','llr','UnitAveragePower',true);
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%LDPC CRC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    ldpc_decoded_data = ldpc_decoder(demoudellr); %% Decoding the data bits using convolutional decoder
    ldpc_useful_data = ldpc_decoded_data(1:length(crc_coded_data), 1); %% Filtering the decoded data bits
    fprintf("ldpc dcode bit :%d\n", isequal(ldpc_decoded_data,ldpc_data))

    [num, err] = biterr(ldpc_decoded_data,ldpc_data,1)  ;
    err_array(k) = err;
    [crc_decoded_data, frame_error] = step(crc_24_detector, ldpc_useful_data); %% Detecting frame error using CRC detector


    if frame_error == 1
        disp("error")
    end
     
    fprintf("crc bit :%d\n", isequal(crc_decoded_data,raw_data))
end

semilogy(SNR_dB,err_array,'r-.s', 'LineWidth', 1); hold on;
semilogy(SNR_dB,err_array_before_ldpc, 'b-*', 'LineWidth', 1);
legend('16QAM','16QAM+LDPC','Location', 'southWest');
xlabel('SNR (dB)'); ylabel('BER');
  

