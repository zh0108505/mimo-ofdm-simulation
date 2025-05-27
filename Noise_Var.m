function [y] = Noise_Var(SNR_dB)
    SNR_linear = 10^(SNR_dB/10);
    y =1/SNR_linear;
