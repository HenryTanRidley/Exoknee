%% Serial Bus Servo Control/Motor Control Test
% Compatible with MATLAB R2019a and earlier (using serial object)
% Yueshan Tan, 8/10/2026
% This code is meant to be run as a whole. 
% Segments of the code can be run to control the servo and BLDC to a given position
% COM numbers need to be checked in dev manager before running
clc;
clear;
close all;

%% ============================================================
%  1. Configuration Parameters of servo
%% ============================================================
portName = 'COM4';          % Serial port name
baudRate = 115200;          % Baud rate
servoID = 1:8;              % 8 servo IDs
pos = [312, 824, 1336, 1848, 2360, 2872, 3384, 3640]; % 8 target positions

%% ============================================================
%  2. Open Serial Port (Legacy serial object)
%% ============================================================
try
    s = serial(portName, 'BaudRate', baudRate);  % Create serial object
    s.Timeout = 1;                               % Set timeout (seconds)
    s.InputBufferSize = 1024;                    % Set input buffer size
    s.OutputBufferSize = 1024;                   % Set output buffer size
    fopen(s);                                    % Open serial port
    fprintf('Serial port %s opened successfully!\n', portName);
catch ME
    error('Failed to open servo serial port %s, error: %s', portName, ME.message);
end
i=1;
servoid = servoID(1);
target = pos(i);

currentPos = readPosition(s, servoid);

%%%%%copy and paste to run: rotate to the nearest cam position%%%
if currentPos == -1
        fprintf('Servo ID%d read failed (no response), skipped\n', id);
        continue;
end
fprintf('Servo ID%d current position: %d (angle: %.2f°)', id, currentPos, currentPos*360/4096);
[~, idx] = min(abs(pos - currentPos));  % Find the nearest target
nearestTarget = pos(idx);
fprintf(' -> nearest target: %d (angle: %.2f°)\n', nearestTarget, nearestTarget*360/4096);

writePosition(s, 1, pos(6), 50);
%%%%%copy and paste to run from position (1)%%%
for i=1:1:6
writePosition(s, 1, pos(i), 0);
pause(4);
end

%BLDC -200degrees: 3E A8 01 08 EF E0 B1 FF FF 50 46 00 00 25 
% +200 degrees 3E A8 01 08 EF 20 4E 00 00 50 46 00 00 04 

% Configuration of BLDC
BldcPortName = 'COM3';          % Serial port name
baudRate = 115200;          % Baud rate
bldcID = 1;                % Motor ID (1~32)
try
    sbldc = serial(BldcPortName, 'BaudRate', baudRate);
    sbldc.Timeout = 1;
    sbldc.InputBufferSize = 1024;
    sbldc.OutputBufferSize = 1024;
    fopen(sbldc);
    fprintf('BLDC port %s opened successfully!\n', BldcPortName);
catch ME
    error('Failed to open BLDC serial port %s, error: %s', BldcPortName, ME.message);
end

angleIncrement = int32(1000 * 100);  % 1800:180degree
maxSpeed = uint32(30000);   % 300 degrees per second
bldc_writeFullframe(sbldc, angleIncrement, maxSpeed,bldcID);



id = 1;  % motor id
cmd = [hex2dec('3E'), hex2dec('9C'), id, 0, 0];
cmd(5) = bitand(sum(cmd(1:4)), 255);  % check sum

% 2. write out
flushinput(sbldc);
fwrite(sbldc, cmd, 'uint8');

% 3. read torque current
pause(0.1);
if sbldc.BytesAvailable >= 13
    resp = fread(sbldc, 13, 'uint8')';
    % DATA[1~2] = torque iq
    iqBytes = uint8([resp(7), resp(8)]);
    iq = typecast(iqBytes, 'int16');

    fprintf('Torque current iq: %d (LSB)\n', iq);
    
else
    fprintf('read failure?no answer\n');
end



% DATA: angleIncrement (4 bytes) + maxSpeed (4 bytes) + DATA_SUM
bcmd = [hex2dec('3E'), hex2dec('A8'), bldcID, 8, 0];

angleBytes = typecast(angleIncrement, 'uint8');

speedBytes = typecast(maxSpeed, 'uint8');

data = [angleBytes(1), angleBytes(2), angleBytes(3), angleBytes(4), ...
        speedBytes(1), speedBytes(2), speedBytes(3), speedBytes(4)];

cmdSum = bldc_calcChecksum(bcmd(1:4));
bcmd(5) = cmdSum;

dataSum = bldc_calcChecksum(data);
data = [data, dataSum];

fullFrame = [bcmd, data];

fprintf('Sending frame (hex): ');
fprintf('%02X ', fullFrame);
fprintf('\n');

flushinput(sbldc);
fwrite(sbldc, fullFrame, 'uint8');


fprintf('\n=== Execution Started ===\n');
i=1;
servoid = servoID(1);
target = pos(i);

currentPos = readPosition(s, servoid);
if currentPos == -1
        fprintf('Servo ID%d read failed (no response), skipped\n', id);
        continue;
end
fprintf('Servo ID%d current position: %d (angle: %.2f°)', id, currentPos, currentPos*360/4096);


writePosition(s, id, nearestTarget, 0);

% TX:  3E 1F 01 00 5E 
% RX:  3E 1F 01 00 5E 
% TX:  3E 12 01 00 51 
% RX:  3E 12 01 00 51 
% TX:  3E 1F 01 00 5E 
% RX:  3E 1F 01 02 60 32 20 52 
% TX:  3E 12 01 00 51 
% RX:  3E 12 01 3A 8B 44 47 34 30 52 37 00 00 00 00 00 00 00 00 00 00 00 00 00 00 4D 47 34 30 31 30 45 
% RX:  2D 69 31 30 00 00 00 00 00 00 00 00 00 36 33 37 30 18 4B 35 34 56 00 43 00 40 01 2C 01 ED 00 9D 
% TX:  3E 16 01 00 55 
% RX:  3E 16 01 6C C1 1C 07 00 00 11 C1 00 00 ED 03 C8 00 01 FF 00 00 00 00 00 00 00 00 00 00 00 00 00 
% RX:  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
% RX:  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 FF FF 00 00 00 00 00 0A FF FF B3 01 00 
% RX:  00 01 FF FF FF 00 00 00 00 00 FF FF FF 34 12 AA 55 A7 
% TX:  3E 14 01 00 53 
% RX:  3E 14 01 68 BB 00 01 04 04 00 00 02 00 02 02 00 00 00 01 64 64 BC 02 B8 0B 58 02 64 00 C8 00 64 
% RX:  00 00 FF 28 0A 00 01 4C 04 6C 07 DC 05 0A 00 64 00 C8 00 64 00 C4 09 32 00 00 00 00 00 28 00 1E 
% RX:  00 00 00 32 00 32 00 00 00 E8 03 FF FF 60 E3 16 00 FF FF FF FF 00 00 00 00 00 00 00 00 00 00 FF 
% RX:  FF 00 00 00 00 00 00 00 00 78 56 AA 55 65 
% TX:  3E 10 01 00 4F 
% RX:  3E 10 01 00 4F 
% TX:  3E A7 01 04 EA E8 03 00 00 EB 
% RX:  3E A7 01 07 ED 1B 00 00 00 00 10 17 42 
% TX:  3E A7 01 04 EA FC 08 00 00 04 
% RX:  3E A7 01 07 ED 1B 0C 00 00 00 C6 17 04 
% TX:  3E A7 01 04 EA 70 17 00 00 87 
% RX:  3E A7 01 07 ED 1B 13 00 00 00 69 19 B0 
% TX:  3E A7 01 04 EA E0 2E 00 00 0E 
% RX:  3E A7 01 07 ED 1B 0F 00 00 00 AD 1D F4 
% TX:  3E A7 01 04 EA 20 D1 FF FF EF 
% RX:  3E A7 01 07 ED 1B 05 00 00 00 36 26 7C 
% TX:  3E A8 01 08 EF 10 27 00 00 10 27 00 00 6E 
% RX:  3E A8 01 07 EE 1B 06 00 00 00 AD 1D EB 
% TX:  3E A8 01 08 EF F0 D8 FF FF 10 27 00 00 FD 
% RX:  3E A8 01 07 EE 1B 12 00 00 00 C9 24 1A 
% RX:  
% TX:  3E A8 01 08 EF 68 C5 FF FF 98 3A 00 00 FD 
% RX:  3E A8 01 07 EE 1B EA FF 00 00 AD 1D CE 
% TX:  3E A8 01 08 EF 98 3A 00 00 98 3A 00 00 A4 
% RX:  3E A8 01 07 EE 1B E1 FF 00 00 02 13 10 
% TX:  3E A8 01 08 EF 50 46 00 00 50 46 00 00 2C 
% RX:  3E A8 01 07 EE 1B 1A 00 00 00 AD 1D FF 
% RX:  
% TX:  3E A8 01 08 EF 58 9E FF FF 50 46 00 00 8A 
% RX:  3E A8 01 07 EE 1B 21 00 FB FF 7A 2A DA 
% TX:  3E A8 01 08 EF A8 61 00 00 50 46 00 00 9F 
% RX:  3E A8 01 07 EE 1B E4 FF 00 00 B3 18 C9 

    
for i = 1:length(servoID)
    id = servoID(i);
    target = pos(i);
    
    % 4.1 Read current position
    currentPos = readPosition(s, id);
    if currentPos == -1
        fprintf('Servo ID%d read failed (no response), skipped\n', id);
        continue;
    end
    fprintf('Servo ID%d current position: %d (angle: %.2f°)', id, currentPos, currentPos*360/4096);
    
    % 4.2 Find the nearest target position from the predefined list
    [~, idx] = min(abs(pos - currentPos));  % Find the nearest target
    nearestTarget = pos(idx);
    fprintf(' -> nearest target: %d (angle: %.2f°)\n', nearestTarget, nearestTarget*360/4096);
    %[09:55:20.651] READ[0x38]: FF FF 01 04 02 38 02 BE
    %[09:55:20.624] RECV: FF F5 01 04 00 0D 37 B6
    %[09:55:40.339] MOTION[0x2A] Pos=0B38 Time=0000: FF FF 01 07 03 2A 0B 38 00 00 87
    
    % 4.3 Send move command (with 500ms movement time)
    writePosition(s, id, nearestTarget, 500);
    fprintf('  Sent ID%d move to %d\n', id, nearestTarget);
end

%% ============================================================
%  5. Close Serial Port
%% ============================================================
fclose(s);
delete(s);
clear s;
fclose(sbldc);
delete(sbldc);
clear sbldc;

fprintf('\n=== Execution Complete, Serial Port Closed ===\n');


%% ============================================================
%  Subfunction Definitions
%% ============================================================

