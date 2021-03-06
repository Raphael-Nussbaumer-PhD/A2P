%% Create R2.in and protocol.dat
%
% Comment are from the Readme Manual (2.7a)
%
% INPUT (generated with this script):
% * R2.in           : geometry informaton 
% * protocol.dat    : index, 4 electrodes index 
% ( * mesh.dat      : for triangulare meshing)
%
% OUPUT:
% * R2.out            : main log exectution
% * electrodes.dat    : x,y-coordinate of electrodes
% * electrodes.vtk    : idem in vtk format
% FORWARD OUTPUT
% * R2_forward.dat    : similare to protocol.dat + calculated resistances +
% calculated apparent resistivities
% * forward_model.dat : x, y, resis, log10(resis)
% INVERSE

function d = Matlat2R2(d,elec)
% d is either the inverser (i) or forward (f) structure

%% BASIC GENERAL SETTING
% d.header                = d.header;      % title of up to 80 characters
% d.job_type              = d.job_type;    % 0 for forward solution only or 1 for inverse solution
d.mesh_type             = 4;                % mesh: 3-triangular, 4-regular quadrilateral, 5-generalised quadrilateral
d.flux_type             = 3.0;              % current flow: 2.0-2D (i.e. line electrodes) or 3.0-fully 3D (usual mode)
d.singular_type         = 0;                % Singularity: 1-removal applied , 0-no removal
% d.res_matrix            = d.res_matrix;  % resolution matrix: 1-'sensitivity' matrix, 2-true resolution matrix or 0-none
% d.filepath              = d.filepath;    % where to write the file

%% MESH CONSTRUCTION
switch d.mesh_type
    case 3 % Trigular Mesh
        d.scale         = NaN;                          % scaling factor for the mesh co-ordinates.
    case 4
        d.xx            = d.grid.x_n;             % array containing x coordinates of each of numnp_x node columns
        d.yy            = d.grid.y_n;      % array containing y coordinates of each of numnp_y node rows relative to the topog array.
        % Set yy(1) to zero and the other values to a positive number
        d.numnp_x       = numel(d.xx);                  % number of nodes in the x direction
        d.numnp_y       = numel(d.yy);                  % number of nodes in the y direction
        d.topog         = zeros(1,d.numnp_x);           % garray containing elevations of each of numnp_x node columns. If the topography is flat then set
        % topog to zero for all values.
    case 5
        d.numnp_x       = NaN;                          % number of nodes in the x direction
        d.numnp_y       = NaN;                          % number of nodes in the y direction
        d.xx            = NaN;                          % array containing x coordinates of each of numnp_x node columns
        d.yy            = NaN;                          % array containing y coordinates of each of numnp_y node columns.
        % Set yy(1) to zero and the other values to a positive number
end

%% RESISITIVITY
if d.job_type == 0  % one value per grid cells in the inside grid plus a cst value for the buffer zone
%     d.rho_numnp            = nan(d.numnp_y-1,d.numnp_x-1);
%     d.rho_numnp(1:(d.numnp_y-1-n_plus),(n_plus+1):(d.numnp_x-1-n_plus))    = d.rho;
%     idx = 1:((d.numnp_y-1)*(d.numnp_x-1));
%     d.elem_1 = [1                           idx(~isnan(d.rho_numnp(:)))];
%     d.elem_2 = [(d.numnp_y-1)*(d.numnp_x-1) idx(~isnan(d.rho_numnp(:)))];
%     d.value =  [d.rho_avg                d.rho_numnp(~isnan(d.rho_numnp(:)))'] ;
    d.elem_1 = 1:((d.numnp_y-1)*(d.numnp_x-1));
    d.elem_2 = 1:((d.numnp_y-1)*(d.numnp_x-1));
    d.value =  d.rho(:)' ;

elseif d.job_type == 1 % for inversion, only one average value is given...
%     d.elem_1 = [1                          ];% 3461 3509 3557 3605 3653 3701 3749 3797];
%     d.elem_2 = [(d.numnp_y-1)*(d.numnp_x-1)];% 3472 3520 3568 3616 3664 3712 3760 3808];
%     d.value =  [d.rho_avg               ];% 10   10   10   10   10   10   10   10] ;
 
warning('check this')
    d.elem_1 = 1:((d.numnp_y-1)*(d.numnp_x-1));
    d.elem_2 = 1:((d.numnp_y-1)*(d.numnp_x-1));
    d.value =  d.rho(:)' ;
end
d.num_regions = numel(d.value);          % number of resistivity regions

if d.num_regions == 0  % file, not working... instead set-up one value per grid cells, so num_regions is huge... 
    error('Using a input file is not yet implemented working')
end

%% INVERSE SOLUTION
if d.job_type==1 % inverse solution
    d.inverse_type      =  1;           % Inverse type: 0-pseudo-Marquardt, 1-regularised solution with linear filter (usual mode),
    d.target_decrease = 0;
    % 2-regularised type with quadratic filter, 3-qualitative solution or 4-blocked linear regularised type
    if d.mesh_type==4 || d.mesh_type==5 % quadrilateral mesh
        d.patch_size_x = 1;        % parameter block sizes in the x and y direction, respectively.
        d.patch_size_y = 1;
        if d.patch_size_x==0 && d.patch_size_y==0
            d.num_param_x   = NaN;    % number of parameter blocks in the x directions
            d.num_param_y   = NaN;    % number of parameter blocks in the y directions
            d.npxstart      = NaN;    % column number in the mesh where the parameters start
            d.npystart      = NaN;
            d.npx           = NaN;    % specifies the number of elements in each parameter block
            d.npy           = NaN;
        end
        d.data_type         = 1;   % 0-true data based inversion or 1-log data based.
        d.reg_mode          = 0;   % Regularisation: 0-normal, 1-relative to starting resistivity or 2-relative to a previous dataset
        % using the �Differenceinversion� of LaBrecque and Yang (2000)
        
        d.tolerance             = d.tolerance;      % desired misfit (usually 1.0)
        d.max_iterations        = d.max_iterations;        % maximum number of iteration
        d.error_mod             = 0;        % 0 -preserve the data weights, 1 or 2-update the weights as the inversion progresses (error_mod=2 is recommended)
        d.alpha_aniso           = d.alpha_aniso;      % anisotropy of the smoothing factor: > 1 for smoother horizontal, alpha_aniso < 1 for smoother
        % vertical models, or alpha_aniso=1 for normal (isotropic) regularisation
        if d.reg_mode==1
            d.alpha_s           = NaN;   % regularisation to the starting model
        end
        
        d.a_wgt                 = d.a_wgt;   % error variance with var(R) = (a_wgt*a_wgt) + (b_wgt*b_wgt) * (R*R)
        d.b_wgt                 = d.b_wgt;   % where R is the resistance measured
        if d.patch_size_x==0 && d.patch_size_y==0
            d.param_symbol
        end
    elseif d.mesh_type==3 % Trigular Mesh
        d.qual_ratio        = NaN;   % 0 for qualitative comparison with forward solution, i.e. only when one observed data set is available,
        % or qual_ratio is 1 if the observed data in protocol.dat contains a ratio of two datasets
    end
    d.rho_min                   = 0;        % minimum observed apparent resistivity to be used
    d.rho_max                   = 5000;     % maximum observed apparent resistivity to be used
    
end

%% REGION OUTPUT (new in 2.7)
d.num_xy_poly                   = 5;   % number of x,y co-ordinates that define a polyline bounding (4 corners + repeat the first corner)
d.x_poly                        = [d.xx(1)  d.xx(end) d.xx(end) d.xx(1)   d.xx(1)];% [x(1) x(end) x(end) x(1)   x(1)];   % co-ordinates of points on the polyline
d.y_poly                        = -[d.yy(1) d.yy(1)   d.yy(end) d.yy(end) d.yy(1)];%-[y(1) y(1)   y(end) y(end) y(1)];

%% ELECTRODE
d.num_electrodes                = elec.n;   % Number of electrodes
d.j_e                           = 1:d.num_electrodes;   % electrode number
if d.job_type==1 && d.inverse_type==3
    d.node      = NaN;                   % node number in the finite element mesh
else
    d.column    = d.elec_id;   % column index for the node the finite element mesh
    d.row       = ones(1,d.num_electrodes);                   % row index for the node in the finite element mesh
end

%% PROTOCOL
d.num_ind_meas                  = size(elec.data,1); 	% number of measurements to follow in file
d.j_p                           = 1:d.num_ind_meas;   %
d.elec                          = elec.data;
if d.job_type == 1 % inverse solution
    d.v_i_ratio                 = NaN;   %
    d.v_i_ratio_0               = NaN;   %
    d.data_sd                   = NaN;   %
    copyfile([d.filepath 'R2_forward.dat'],[d.filepath 'protocol.dat']) % used the output of the forward model
else
    createProtocoldat(d)
end

%% CREATE THE FILES
createR2in(d)


%% RUN .EXE
if ~d.readonly
    copyfile('R2/R2.exe',d.filepath,'f');
    pwd_temp = pwd;
    cd(d.filepath); tic;
    if ismac
        warning('You will need wine for mac in order to work !')
        status = unix('wine R2.exe');
    elseif isunix
        status = unix('wine R2.exe');
    elseif ispc
        [status] = system('R2.exe');
    else
        error('Cannot recognize platform')
    end

    cd(pwd_temp);
    %disp(['Model run in ' num2str(toc) ' secondes.'])

    if status~=0
        error('Model did not worked')
    end
end

%% OUPUT
d.pseudo_x=elec.pseudo_x;
d.pseudo_y=elec.pseudo_y;
d.output=readOutput(d);
end




