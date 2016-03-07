%% groupregr_f
% Calculates least squares estimates using Nelder Mead's simplex method using a filter

%%
function [q, info] = groupregr_f(func, par, data, auxData, weights, filternm)
% created 2015/08/26 by Goncalo Marques

%% Syntax
% [q, info] = <../groupregr_f.m *groupregr_f*> (func, par, data, auxData, weights, filternm)

%% Description
% Calculates least squares estimates using Nelder Mead's simplex method.
%
% Input
%
% * func: character string with name of user-defined function;
%      see nrregr_st or nrregr  
% * par: structure with parameters
% * data: structure with data
% * auxData: structure with auxiliary data
% * weights: structure with weights
% * filternm: character string with name of user-defined filter function
%  
% Output
% 
% * q: structure with parameters, result of the least squares estimates
% * info: 1 if convergence has been successful; 0 otherwise

%% Remarks
% Set options with <nmregr_options.html *nmregr_options*>.
% Similar to <nrregr_st.html *nrregr_st*>, but slower and a larger bassin of attraction
%   and uses a filter.
% The number of fields in data is variable

   
   
  global report max_step_number max_fun_evals tol_simplex tol_fun simplex_size

  % option settings
  info = 1; % initiate info setting
  
  % prepare variable
  %   st: structure with dependent data values only
  st = data;
  [nm, nst] = fieldnmnst_st(st); % nst: number of data sets
    
  for i = 1:nst   % makes st only with dependent variables
    fieldsInCells = textscan(nm{i},'%s','Delimiter','.');
    auxVar = getfield(st, fieldsInCells{1}{:});   % data in field nm{i}
    k = size(auxVar, 2);
    if k >= 2
      st = setfield(st, fieldsInCells{1}{:}, auxVar(:,2));
    end
  end
  
  % Y: vector with all dependent data
  % W: vector with all weights
  Y = struct2vector(st, nm);
  W = struct2vector(weights, nm);
  
  free = par.free; % free is here removed, and after iteration added again
  q = rmfield(par, 'free'); % copy input parameter matrix into output
  
  parnm = fieldnames(free);
  qfreevec = [];          % vector with free parameters
  mapVec2Struct = {}; % cell vector with map to go from vector to structure
  for i = 1:length(parnm)
    currentFree = free.(parnm{i});
    lCurrentFree = length(currentFree);
    if lCurrentFree == 1 && currentFree == 1
      qfreevec = [qfreevec; par.(parnm{i})];
      mapVec2Struct{end + 1} = {parnm{i}, 1};
    elseif lCurrentFree > 1 && sum(currentFree) > 0
      for j = 1:lCurrentFree
        if free.(parnm{i})(j) == 1
          qfreevec = [qfreevec; par.(parnm{i})(j)];
          mapVec2Struct{end + 1} = {parnm{i}, j};
        end
      end
    end
  end
  
  n_par = numel(mapVec2Struct);
  if (n_par == 0)
    return; % no parameters to iterate
  end

  info = 1; % convergence has been successful
  
  % set options if necessary
  if ~exist('max_step_number','var') || isempty(max_step_number)
    nmregr_options('max_step_number', 200 * n_par);
  end
  if ~exist('max_fun_evals','var') || isempty(max_fun_evals)
    nmregr_options('max_fun_evals', 200 * n_par);
  end
  if ~exist('tol_simplex','var') || isempty(tol_simplex)
    nmregr_options('tol_simplex', 1e-4);
  end
  if ~exist('tol_fun','var') || isempty(tol_fun)
    nmregr_options('tol_fun', 1e-4);
  end
  if ~exist('simplex_size','var') || isempty(simplex_size)
    nmregr_options('simplex_size', 0.05);
  end
  if ~exist('report','var') || isempty(report)
    nmregr_options('report', 1);
  end

  % Initialize parameters
  rho = 1; chi = 2; psi = 0.5; sigma = 0.5;
  onesn = ones(1, n_par);
  two2np1 = 2:n_par + 1;
  one2n = 1:n_par;
  np1 = n_par + 1;

  % Set up a simplex near the initial guess.
  xin = qfreevec;    % Place input guess in the simplex
  v(:,1) = xin;
  f = feval(func, q, data, auxData);
  fv(:,1) = W' * (struct2vector(f, nm) - Y).^2;
  % Following improvement suggested by L.Pfeffer at Stanford
  usual_delta = simplex_size;     % 5 percent deltas is the default for non-zero terms
  zero_term_delta = 0.00025;      % Even smaller delta for zero elements of q
  for j = 1:n_par
    y = xin;
    f_test = 0;
    step_reducer = 1;             % step_reducer will serve to reduce usual_delta if the parameter set does not pass the filter
    y_test = y;
    while ~f_test
      if y(j) ~= 0
        y_test(j) = (1 + usual_delta / step_reducer) * y(j);
      else 
        y_test(j) = zero_term_delta / step_reducer;
      end
      q = parVec2Struct(q, y_test, mapVec2Struct);
      [f, f_test] = getPrediction(func, q, data, auxData, filternm);     
      if ~f_test 
        fprintf('The parameter set for the simplex construction is not realistic. \n');
        step_reducer = 2 * step_reducer;
      end
    end  
    v(:,j+1) = y_test;
    fv(:,j+1) = W' * (struct2vector(f, nm) - Y).^2;
  end     

  % sort so v(1,:) has the lowest function value 
  [fv,j] = sort(fv);
  v = v(:,j);

  how = 'initial';
  itercount = 1;
  func_evals = n_par + 1;
  if report == 1
    fprintf(['step ', num2str(itercount), ' ssq ', num2str(min(fv)), '-', ...
	    num2str(max(fv)), ' ', how, '\n']);
  end
  info = 1;

  % Main algorithm
  % Iterate until the diameter of the simplex is less than tol_simplex
  %   AND the function values differ from the min by less than tol_fun,
  %   or the max function evaluations are exceeded. (Cannot use OR instead of AND.)
  while func_evals < max_fun_evals && itercount < max_step_number
    if max(max(abs(v(:,two2np1)-v(:,onesn)))) <= tol_simplex && ...
       max(abs(fv(1)-fv(two2np1))) <= tol_fun
      break
    end
    how = '';
   
    % Compute the reflection point
   
    % xbar = average of the n (NOT n+1) best points
    xbar = sum(v(:,one2n), 2)/ n_par;
    xr = (1 + rho) * xbar - rho * v(:,np1);
    q = parVec2Struct(q, xr, mapVec2Struct);
    [f, f_test] = getPrediction(func, q, data, auxData, filternm);
    if ~f_test 
      fxr = fv(:,np1) + 1;
    else
      fxr = W' * (struct2vector(f, nm) - Y).^2;
    end
    func_evals = func_evals + 1;
   
    if fxr < fv(:,1)
      % Calculate the expansion point
      xe = (1 + rho * chi) * xbar - rho * chi * v(:, np1);
      q = parVec2Struct(q, xe, mapVec2Struct);
      [f, f_test] = getPrediction(func, q, data, auxData, filternm);
      if ~f_test
         fxe = fxr + 1;
      else
         fxe = W' * (struct2vector(f, nm) - Y).^2;
      end
      func_evals = func_evals + 1;
      if fxe < fxr
         v(:,np1) = xe;
         fv(:,np1) = fxe;
         how = 'expand';
      else
         v(:,np1) = xr; 
         fv(:,np1) = fxr;
         how = 'reflect';
      end
    else % fv(:,1) <= fxr
      if fxr < fv(:,n_par)
         v(:,np1) = xr; 
         fv(:,np1) = fxr;
         how = 'reflect';
      else % fxr >= fv(:,n_par) 
         % Perform contraction
         if fxr < fv(:,np1)
            % Perform an outside contraction
            xc = (1 + psi * rho) * xbar - psi * rho * v(:,np1);
            q = parVec2Struct(q, xc, mapVec2Struct);
            [f, f_test] = getPrediction(func, q, data, auxData, filternm);
            if ~f_test
              fxc = fxr + 1;
            else            
              fxc = W' * (struct2vector(f, nm) - Y).^2;
            end
            func_evals = func_evals + 1;
            
            if fxc <= fxr
               v(:,np1) = xc; 
               fv(:,np1) = fxc;
               how = 'contract outside';
            else
               % perform a shrink
               how = 'shrink'; 
            end
         else
            % Perform an inside contraction
            xcc = (1 - psi) * xbar + psi * v(:,np1);
            q = parVec2Struct(q, xcc, mapVec2Struct);
            [f, f_test] = getPrediction(func, q, data, auxData, filternm);
            if ~f_test
              fxcc = fv(:,np1) + 1;
            else
              fxcc = W' * (struct2vector(f, nm) - Y).^2;
            end
            func_evals = func_evals + 1;
            
            if fxcc < fv(:,np1)
               v(:,np1) = xcc;
               fv(:,np1) = fxcc;
               how = 'contract inside';
            else
               % perform a shrink
               how = 'shrink';
            end
         end
         if strcmp(how,'shrink')
            for j = two2np1
               f_test = 0;
               step_reducer = 1;             % step_reducer will serve to reduce usual_delta if the parameter set does not pass the filter
               while ~f_test
                  v_test = v(:,1) + sigma / step_reducer * (v(:,j) - v(:,1));
                  q = parVec2Struct(q, v_test, mapVec2Struct);
                  [f, f_test] = getPrediction(func, q, data, auxData, filternm);
                  if ~f_test 
                     fprintf('The parameter set for the simplex shrinking is not realistic. \n');
                     step_reducer = 2 * step_reducer;
                  end
               end
               v(:,j) = v_test;
               fv(:,j) = W' * (struct2vector(f, nm) - Y).^2;
            end
            func_evals = func_evals + n_par;
         end
      end
    end
    [fv,j] = sort(fv);
    v = v(:,j);
    itercount = itercount + 1;
    if (mod(itercount, 10) == 0 && report == 1)
      fprintf(['step ', num2str(itercount), ' ssq ', num2str(min(fv)), ...
	     '-', num2str(max(fv)), ' ', how, '\n']);
    end  
      
  end 

  q = parVec2Struct(q, v(:,1), mapVec2Struct);
  q.free = free; % add substructure free to q,

  fval = min(fv); 
  if func_evals >= max_fun_evals
    %if report > 0
    fprintf(['No convergences with ', ...
      num2str(max_fun_evals), ' function evaluations\n']);
    %end
    info = 0;
  elseif itercount >= max_step_number 
    %if report > 0
      fprintf(['No convergences with ', num2str(max_step_number), ' steps\n']);
    %end
    info = 0; 
  else
    %if report > 0
      fprintf('Successful convergence \n');              
    %end
    info = 1;
  end
   
function vec = struct2vector(struct, fieldNames)
% Constructs vector from fields fielNames of structure struct
% Used to transform prdData into vector for easy computation of loss function
  vec = [];
  for i = 1:size(fieldNames, 1)
    fieldsInCells = textscan(fieldNames{i},'%s','Delimiter','.');
    vec = [vec; getfield(struct, fieldsInCells{1}{:})];
  end

function q = parVec2Struct(q, vec, mapVec2Struct)
% Replaces values in q with the ones in vec using the map of fields in mapVec2Struct
  for i = 1:length(vec)
    q.(mapVec2Struct{i}{1})(mapVec2Struct{i}{2}) = vec(i);
  end

function [f, pass] = getPrediction(func, q, data, auxData, filternm)
  global cov_rules
% Tests if prameter set q passes the filters (default and customized) and if yes returns predictions 
  f = {};
  if strcmp(cov_rules, '1species')
    pass = feval(filternm, q);
  else
    pass = filter_multispecies(filternm, q);
  end
  if pass
    [f, pass] = feval(func, q, data, auxData);
  end

function pass = filter_multispecies(filternm, q)
% Tests if parameter set q passes the filternm filters for multiple species
  global pets cov_rules
  
  covRulesnm = ['cov_rules_', cov_rules];
  petsnumber = length(pets);
  pass = 1;
  for i = 1:petsnumber
    [pass, flag]  = feval(filternm, feval(covRulesnm, q, i));
    if ~pass
      return;
    end
  end



  