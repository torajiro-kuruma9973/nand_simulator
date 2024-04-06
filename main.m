clear;
close all;
clc;

% ctl = Controller();
% ctl.user_write_page(1);
% ctl.user_write_page(1);
% ctl.user_write_page(1);
% ctl.user_write_page(5);
% ctl.user_write_page(2);

ctl = Controller();
total_usr_pgs = ctl.amount_user_pages;

% 1. sequential write (provisioning)

for i = 1 : total_usr_pgs
    disp(i)
    ctl.user_write_page(i);
end

% ctl.user_write_page(6);
% ctl.user_write_page(1);
% ctl.user_write_page(11);
% ctl.user_write_page(5);
% ctl.user_write_page(16);
% vec = [35 16 54 41 89 88 75 15 3 63];
% s = size(vec);
% for i = 1 : s(2)
%     page = vec(1, i);
%     if(page == 63)
%         disp("Let me check...")
%     end
%     disp("Step " + i + " ...Random write: page " + page);
%     ctl.user_write_page(page);
% end

total_write = 1000000; % 1000 random write
vec = zeros(1, total_write);
for step = 1 : total_write
    page = randi(total_usr_pgs);
    disp("Step " + step + " ...Random write: page " + page);
    ctl.user_write_page(page);
    %vec(1, step) = ctl.valid_pages_num_in_blk;
end


