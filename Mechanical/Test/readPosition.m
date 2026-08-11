%% ============================================================
%  Read current position from servo
%  Input:  s  - serial port object, id - servo ID (1~250)
%  Output: posVal - current position value (0~4095), returns -1 on failure
%  Henry Tan, 7/30/2026
%% ============================================================
function posVal = readPosition(s, id)
    % Build read command: FF FF ID 04 02 38 02 CK
    cmd = [hex2dec('FF'), hex2dec('FF'), id, 4, 2, hex2dec('38'), 2];
    ck = calc_checksum(cmd(3:end));
    cmd = [cmd, ck];
    
    flushinput(s);
    fwrite(s, cmd, 'uint8');
    
    pause(0.1);
    waitTime = 0;
    while s.BytesAvailable < 8 && waitTime < 20
        pause(0.025);
        waitTime = waitTime + 1;
    end
    
    if s.BytesAvailable >= 8
        resp = fread(s, 8, 'uint8')';
        % Check receive header: FF F5
        if resp(1)==255 && resp(2)==245  % 0xF5 = 245 decimal
            posVal = bitshift(resp(6), 8) + resp(7);
            return;
        end
    end
    posVal = -1;
end