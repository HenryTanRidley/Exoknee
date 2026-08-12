%% Read single-turn angle (Command 0x94)
function singleAngle = readSingleTurnAngle(sbldc, id)
    % Read current single-turn angle of the motor (0~359.99°)
    % Input:  sbldc - serial port object, id - motor ID (1~32)
    % Output: singleAngle - single-turn angle in degrees, returns NaN on failure
    
    % 1. Build command: 3E 94 ID 00 CMD_SUM
    cmd = [hex2dec('3E'), hex2dec('94'), id, 0, 0];
    cmd(5) = bitand(sum(cmd(1:4)), 255);
    
    % 2. Send command
    flushinput(sbldc);
    fwrite(sbldc, cmd, 'uint8');
    pause(0.1);
    
    % 3. Read response (9 bytes)
    if sbldc.BytesAvailable >= 9
        resp = fread(sbldc, 9, 'uint8')';
        
        % 4. Verify header
        if resp(1)==hex2dec('3E') && resp(2)==hex2dec('94')
            % 5. Extract angle data (DATA[0~3], little-endian, uint32)
            angleBytes = uint8([resp(6), resp(7), resp(8), resp(9)]);
            angleRaw = typecast(angleBytes, 'uint32');
            
            % 6. Convert to degrees (unit: 0.01°/LSB)
            singleAngle = double(angleRaw) / 1000;
            fprintf('Single-turn angle: %.2f° (raw: %d)\n', singleAngle, angleRaw);
            return;
        end
    end
    
    % Read failed
    singleAngle = NaN;
    fprintf('Failed to read single-turn angle\n');
end