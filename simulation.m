SNR_dB = -20:2:40;        % 信噪比范围

err_array = zeros(length(SNR_dB),1)
M=16;
number_of_bits_per_frame = 1000;
System_initialize
for k = 1:length(SNR_dB)
    SNR = SNR_dB(k);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%发送%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    raw_data = logical(randi([0 1], number_of_bits_per_frame, 1)); %% Generating random data bits
    crc_coded_data = step(crc_24_generator, raw_data); %% Adding CRC bits for error checking
    ldpc_extra_bits = ldpc_num_bits - length(crc_coded_data);
    ldpc_data = [crc_coded_data; randi([0 1], ldpc_extra_bits, 1)];
    ldpc_encoded_data = ldpc_encoder(ldpc_data);
    tx_signal = qammod(ldpc_encoded_data,M,'InputType','bit','UnitAveragePower',true);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%发送%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
    %%%%%%%%%%%%%%%%%%%%%%%%%信道%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tx_signal = awgn_channel(tx_signal,Noise_Var(SNR));
    %%%%%%%%%%%%%%%%%%%%%%%%%信道%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%接收%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    demoudellr = qamdemod(tx_signal, M,'OutputType','llr','UnitAveragePower',true);
    
    ldpc_decoded_data = ldpc_decoder(demoudellr); %% Decoding the data bits using convolutional decoder
    ldpc_useful_data = ldpc_decoded_data(1:length(crc_coded_data), 1); %% Filtering the decoded data bits
    
    [crc_decoded_data, frame_error] = step(crc_24_detector, ldpc_useful_data); %% Detecting frame error using CRC detector
    
    if frame_error == 1
        disp("error")
    end
    
    isequal(crc_decoded_data,raw_data);
    [num, err] = biterr(crc_decoded_data,raw_data)  ;
    err_array(k) = err;
end

semilogy(SNR_dB,err_array)
  

