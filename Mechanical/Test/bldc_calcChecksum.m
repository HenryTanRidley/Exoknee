function ck = bldc_calcChecksum(bytes)
    ck = bitand(sum(bytes), 255);
    
end