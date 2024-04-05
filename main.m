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

for i = 1 : total_usr_pgs
    disp(i)
    ctl.user_write_page(i);
end

