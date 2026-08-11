function bldc_writeFullframe(sbldc, angleIncrement, maxSpeed,bldcID)
% DATA: angleIncrement (4 bytes) + maxSpeed (4 bytes) + DATA_SUM
bcmd = [hex2dec('3E'), hex2dec('A8'), bldcID, 8, 0];
% angle 
angleBytes = typecast(angleIncrement, 'uint8');
% speed
speedBytes = typecast(maxSpeed, 'uint8');

% data?angle(4 bytes) + speed(4bytes)
data = [angleBytes(1), angleBytes(2), angleBytes(3), angleBytes(4), ...
        speedBytes(1), speedBytes(2), speedBytes(3), speedBytes(4)];

% checksum
cmdSum = bldc_calcChecksum(bcmd(1:4));
bcmd(5) = cmdSum;

dataSum = bldc_calcChecksum(data);
data = [data, dataSum];

fullFrame = [bcmd, data];

%fprintf('Sending frame (hex): ');
%fprintf('%02X ', fullFrame);
%fprintf('\n');

flushinput(sbldc);
fwrite(sbldc, fullFrame, 'uint8');
end