function multiAngle = readMultiTurnAngle(sbldc, id)
    % command: 3E 92 ID 00 CMD_SUM
    cmd = [hex2dec('3E'), hex2dec('92'), id, 0, 0];
    cmd(5) = bitand(sum(cmd(1:4)), 255);
    
    flushinput(sbldc);
    fwrite(sbldc, cmd, 'uint8');
    pause(0.1);
    
    if sbldc.BytesAvailable >= 13
        resp = fread(sbldc, 13, 'uint8')';
        if resp(1)==hex2dec('3E') && resp(2)==hex2dec('92')
            % DATA[0~7] = absolute position????int64?
            angleBytes = uint8(resp(6:13));
            multiAngle = typecast(angleBytes, 'int64');
            fprintf('Absolute angle: %.2f°\n', double(multiAngle) / 100);
            return;
        end
    end
    multiAngle = NaN;
    fprintf('read failure\n');
end