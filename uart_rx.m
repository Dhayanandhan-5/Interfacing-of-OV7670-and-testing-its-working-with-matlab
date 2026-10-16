clear s;
s = serialport("COM5", 115200);

% Configure a timeout (in seconds) so MATLAB doesn't freeze if data stops
s.Timeout = 10; 

fprintf('Waiting for  FPGA...\n');

% 2. Read exactly 60 bytes (30 pixels * 2 bytes each)
r_bytes = read(s, 153600, "uint8");

% 3. Combine pairs of 8-bit bytes into 16-bit integers
% Your FPGA sends Low Byte first, then High Byte
low_bytes  = double(r_bytes(1:2:end)); % Odds: 1, 3, 5... (Low Byte)
high_bytes = double(r_bytes(2:2:end)); % Evens: 2, 4, 6... (High Byte)

% Shift high byte by 8 bits and add the low byte
raw_data = bitshift(high_bytes, 8) + low_bytes;

clear s;



my_matrix = reshape(raw_data, 320, 240)';
binary_strings = dec2bin(my_matrix, 16);

% 3. Convert the character array into MATLAB string objects
string_array = string(binary_strings);

% 4. Reshape it back into your exact 240x320 image grid structure
binary_matrix = reshape(string_array, 240, 320);

fileID = fopen('binary_grid.txt', 'w');

% 2. Loop through every row and column to write the binary strings
for row = 1:240
    for col = 1:320
        % Write the binary string followed by a space
        fprintf(fileID, '%s ', binary_matrix(row, col));
    end
    % At the end of each row, hit Enter to start a new line
    fprintf(fileID, '\n');
end

% 3. Close the file securely
fclose(fileID);

% 4. Open the file automatically in MATLAB's text editor to look at it
%edit('binary_grid.txt');




%--------------------

rgb_text_matrix = strings(240, 320);

% 2. Loop through every single pixel position
for row = 1:240
    for col = 1:320
        % Get the full 16-character string for the current pixel
        full_bin = binary_matrix(row, col);
        
        % Convert string to character array so we can slice it by index
        char_bin = char(full_bin);
        
        % Slice the bits exactly according to your layout:
        red_bits   = char_bin(1:4);   % Bits [15:12]
        green_bits = char_bin(5:8);   % Bits [11:8]
        blue_bits  = char_bin(9:12);  % Bits [7:4]
        
        % Combine them back into a single "R,G,B" text block
        rgb_text_matrix(row, col) = sprintf('%s,%s,%s', red_bits, green_bits, blue_bits);
    end
end


% Write the segmented R,G,B grid to a text file
fileID2 = fopen('rgb_segmented_grid.txt', 'w');

for row = 1:240
    for col = 1:320
        % Write the R,G,B string followed by a space
        fprintf(fileID2, '%s ', rgb_text_matrix(row, col));
    end
    fprintf(fileID2, '\n'); % Move to next row
end

fclose(fileID2);

% Open the new file automatically to inspect it!
%edit('rgb_segmented_grid.txt');

%-=----------------

% 1. Create a blank matrix to hold the decimal "R,G,B" text strings
rgb_dec_matrix = strings(240, 320);

% 2. Loop through every pixel position
for row = 1:240
    for col = 1:320
        % Split the "R,G,B" binary text by commas into a 1x3 cell array
        % Example: "1111,1010,0011" becomes {'1111', '1010', '0011'}
        bin_split = split(rgb_text_matrix(row, col), ',');
        
        % Convert each binary piece to a standard decimal number
        r_dec = bin2dec(bin_split(1));
        g_dec = bin2dec(bin_split(2));
        b_dec = bin2dec(bin_split(3));
        
        % Put them back together as a text string separated by commas
        rgb_dec_matrix(row, col) = sprintf('%d,%d,%d', r_dec, g_dec, b_dec);
    end
end
% Write the comma-separated decimal grid to a text file
fileID3 = fopen('rgb_decimal_grid.txt', 'w');

for row = 1:240
    for col = 1:320
        % Write the decimal R,G,B string followed by a space
        fprintf(fileID3, '%s ', rgb_dec_matrix(row, col));
    end
    fprintf(fileID3, '\n'); % Move to next row down
end

fclose(fileID3);

% Open the file automatically to inspect it!
%edit('rgb_decimal_grid.txt');

%----------------------------

% 1. Initialize three separate matrices for Red, Green, and Blue (240x320)
% We use 'uint8' because MATLAB images need to be 8-bit integers (0-255)
Red_Matrix   = zeros(240, 320, 'uint8');
Green_Matrix = zeros(240, 320, 'uint8');
Blue_Matrix  = zeros(240, 320, 'uint8');

% 2. Loop through every single pixel to separate the values
for row = 1:240
    for col = 1:320
        % Read the comma-separated string from Step 3
        current_str = rgb_dec_matrix(row, col);
        
        % Extract the three numbers using sscanf
        % Example: "15,10,3" returns a vector [15; 10; 3]
        dec_values = sscanf(current_str, '%d,%d,%d');
        
        % Extract individual 4-bit values (range 0 to 15)
        r_4bit = dec_values(1);
        g_4bit = dec_values(2);
        b_4bit = dec_values(3);
        
        % Scale them to 8-bit (0-255) by multiplying by 17
        % Store them directly in your three standalone variables
        Red_Matrix(row, col)   = uint8(r_4bit * 17);
        Green_Matrix(row, col) = uint8(g_4bit * 17);
        Blue_Matrix(row, col)  = uint8(b_4bit * 17);
    end
end

% 3. Stack the three layers together to form the final 3D RGB image array
final_picture = zeros(240, 320, 3, 'uint8');
final_picture(:, :, 1) = Red_Matrix;   % Layer 1 = Red
final_picture(:, :, 2) = Green_Matrix; % Layer 2 = Green
final_picture(:, :, 3) = Blue_Matrix;  % Layer 3 = Blue

% 4. Display your final picture!
figure;
imshow(final_picture);
title('Final Reconstructed 12-bit RGB444 Image');
