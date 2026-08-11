%% ============================================================
%  Send write command (move servo to target position)
%  Input:  s         - serial port object
%          id        - servo ID
%          targetPos - target position (0~4095)
%          timeMs    - movement time in milliseconds (optional, default 0)
%% ============================================================
function writePosition(s, id, targetPos, timeMs)
    if nargin < 4
        timeMs = 0;
    end
    posH = bitshift(targetPos, -8);
    posL = bitand(targetPos, 255);
    timeH = bitshift(timeMs, -8);
    timeL = bitand(timeMs, 255);
    
    % Build write command: FF FF ID 07 03 2A PH PL TH TL CK
    % Instruction type = 0x03 (not 0x04)
    cmd = [hex2dec('FF'), hex2dec('FF'), id, 7, 3, hex2dec('2A'), ...
           posH, posL, timeH, timeL];
    ck = calc_checksum(cmd(3:end));
    cmd = [cmd, ck];
    
    fwrite(s, cmd, 'uint8');
    pause(0.05);
end