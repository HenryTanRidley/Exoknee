%% Set permanent 0 position(write into ROM)- command 0x19
function setZeroROM(sbldc, id)
    % command: 3E 19 ID 00 CMD_SUM
    cmd = [hex2dec('3E'), hex2dec('19'), id, 0, 0];
    cmd(5) = bitand(sum(cmd(1:4)), 255);
    
    %fprintf('Send command: ');
    %fprintf('%02X ', cmd);
    %fprintf('\n');
    
    flushinput(sbldc);
    fwrite(sbldc, cmd, 'uint8');
    pause(0.5);
    
    % read response 8 bytes
    if sbldc.BytesAvailable >= 8
        resp = fread(sbldc, 8, 'uint8')';
        fprintf('Response: ');
        fprintf('%02X ', resp);
        fprintf('\n');
        
        if resp(1)==hex2dec('3E') && resp(2)==hex2dec('19')
            zeroVal = typecast(uint8([resp(6), resp(7)]), 'uint16');
            fprintf('OK, Present position is set to 0(ROM)\n');
            return;
        end
    end
    fprintf('Set failure\n');
end