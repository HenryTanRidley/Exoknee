%% ============================================================
%  Calculate checksum (complement + 1 of accumulated sum)
%  Input:  data - byte array starting from ID (excluding header FF FF)
%  Output: ck - checksum value (0~255)
%  Yueshan Tan, 8/1/2026
%% ============================================================
function ck = calc_checksum(data)
    sumVal = sum(data);
    ck = bitand(bitcmp(sumVal, 'uint32'), 255);  % inverted
end