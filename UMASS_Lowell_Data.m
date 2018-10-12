function UMASS_Lowell_Data
filename = 'Vertical_Test1.csv';
[rpm,thrust] = read_file(filename);


figure
plot(rpm)

figure
plot(thrust)



function [rpm,thrust] = read_file(filename)
% fid = fopen(filename,'r');
% 
% thrust = []; %empty matrix for force readings, columns (fx,fy,fz)
% rpm = []; %empty matrix for torque readings, columns (tx,ty,tz)
% coun = 0;

% while ~feof(fid)
%     if coun < 2 %read the first 8 lines, and do nothing
%         coun = coun+1;
%         line = fgetl(fid);
%         
%     else %read and manipulate the remaining lines of the file
%         line = fgetl(fid);
%         
%         %isolates each component of the line
%         [time,remain] = strtok(line,','); %isolate the status(hex), and store as l1
%         [ESC,remain] = strtok(remain,','); %isolate the RDT sequence and store as RDT
%         [S1,remain] = strtok(remain,','); %isolate the F/T sequence and store as FT
%         [S2,remain] = strtok(remain,','); %isolate the Fx value
%         [S3,remain] = strtok(remain,','); %isolate the Fy value
%         [Ax,remain] = strtok(remain,','); %isolate the Fz value
%         [Ay,remain] = strtok(remain,','); %isolate the Tx value
%         [Az,remain] = strtok(remain,','); %isolate the Ty value
%         [T,remain] = strtok(remain,','); %isolate the Tz value
%         [Thrust,remain] = strtok(remain,','); %isolate the status(hex), and store as l1
%         [V,remain] = strtok(remain,','); %isolate the RDT sequence and store as RDT
%         [C,remain] = strtok(remain,','); %isolate the F/T sequence and store as FT
%         [Me,remain] = strtok(remain,','); %isolate the Fx value
%         [RPM,remain] = strtok(remain,','); %isolate the Fy value
%     
%     if RPM ~= ""
%         rpm = [rpm,str2double(RPM)];
%     end
%     if Thrust ~= ""
%         thrust = [thrust,str2double(Thrust)];
%     end
%     
%     end
% end
% fclose(fid); %close the file

vals = csvread(filename,1);
rpm = vals(:,14);
thrust = vals(:,10);

