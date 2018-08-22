%% prt_report_my_pet
% Creates report_my_pet.html 

%%
function prt_report_my_pet(metaData, metaPar, par, T, f, destinationFolder)
% created 2016/11/24 Starrlight;  modified 2018/08/22 Bas Kooijman

%% Syntax
% <../prt_report_my_pet.m *prt_report_my_pet*> (metaData, metaPar, par, T, f, destinationFolder) 

%% Description
% Read and writes report_my_pet.html. This pages contains a list of implied model
% properties of my_pet. 
%
% Input:
%
% * metaData: structure (output of <http://www.debtheory.org/wiki/index.php?title=Mydata_file *mydata_my_pet_par*> file)
% * metaPar: structure (output of <http://www.debtheory.org/wiki/index.php?title=Pars_init_file *pars_init_my_pet_par*> file)
% * par: structure (output of <http://www.debtheory.org/wiki/index.php?title=Pars_init_file *pars_init_my_pet_par*> file)
% * T: optional scalar with temperature in Kelvin (default: T_typical)
% * f: optional scalar scaled functional response (default: 1)
% * destinationFolder : optional string with destination folder the files
% are printed to (default: current folder)

%% Example of use
% load('results_my_pet.mat'); prt_report_my_pet(metaData, metaPar, par, T, f, destinationFolder)
% or
% prt_report_my_pet(my_pet)
% or
% prt_report_my_pet(my_pet,'', C2K(22), 1)


% Removes underscores and makes first letter of english name be in capital:

persistent allStat

if isstruct(metaData)
  species = metaData.species;
  species_en = metaData.species_en;
  model = metaPar.model;
  T_typical = metaData.T_typical;
else % use allStat.mat as data source
  if ~exist('allStat','var') || isempty(allStat)
    load('allStat')        % get all parameters and statistics in structure allStat
  end
  species = metaData;
  species_en = allStat.(species).species_en;
  model = allStat.(species).model;
  T_typical = allStat.(species).T_typical;
  
  parFields = get_parfields(model); 
  chem = { ...
    'd_X'; 'd_V'; 'd_E'; 'd_P';
    'mu_X'; 'mu_V'; 'mu_E'; 'mu_P'; 
    'mu_C'; 'mu_H'; 'mu_O'; 'mu_N';
    'n_CX'; 'n_HX'; 'n_OX'; 'n_NX';
    'n_CV'; 'n_HV'; 'n_OV'; 'n_NV';
    'n_CE'; 'n_HE'; 'n_OE'; 'n_NE';
    'n_CP'; 'n_HP'; 'n_OP'; 'n_NP';
    'n_CC'; 'n_HC'; 'n_OC'; 'n_NC';
    'n_CH'; 'n_HH'; 'n_OH'; 'n_NH';
    'n_CO'; 'n_HO'; 'n_OO'; 'n_NO';
    'n_CN'; 'n_HN'; 'n_ON'; 'n_NN'};
  parFields = [parFields'; chem];
  n_parFields = length(parFields);
  for i = 1:n_parFields
    par.(parFields{i}) = allStat.(species).(parFields{i});
  end
end

speciesprintnm = strrep(species, '_', ' ');
speciesprintnm_en = strrep(species_en, '_', ' ');
if speciesprintnm_en(1)>='a' && speciesprintnm_en(1)<='z'
  speciesprintnm_en(1)=char(speciesprintnm_en(1) - 32);
end

if exist('destinationFolder','var')
  fileName = [destinationFolder, 'report_', species, '.html'];
else
  fileName = ['report_', species, '.html'];
  if ~exist('f','var')
    f = 1;
    if ~exist('T','var')
      T = T_typical;
    end
  end
end

[stat, txtStat] = statistics_st(model, par, T, f);
% add zoom factor to statistics which are to be printed 
stat.z = par.z; txtStat.label.z = 'zoom factor'; txtStat.units.z = '-'; txtStat.temp.z = NaN;  txtStat.fresp.z = NaN;
stat = rmfield(stat, {'T','f'}); % remove fields T and f, bause it is already in txtStat
flds = fieldnmnst_st(stat); % fieldnames of all statistics
% [webStatFields, webColStat] = get_statfields(metaPar.model); % which statistics in what order should be printed in the table

oid = fopen(fileName, 'w+'); % open file for writing, delete existing content

fprintf(oid, '<!DOCTYPE html>\n');
fprintf(oid, '<HTML>\n');
fprintf(oid, '<HEAD>\n');
fprintf(oid,['  <TITLE> report ',species,'</TITLE>\n']);
fprintf(oid, '  <style>\n');

fprintf(oid, '    #InputSymbol {\n');
fprintf(oid, '      width: 10%%; /* Width of search field */\n');
fprintf(oid, '      font-size: 14px; /* Increase font-size */\n');
fprintf(oid, '      border: 1px solid #ddd; /* Add a grey border */\n');
fprintf(oid, '      margin-bottom: 12px; /* Add some space below the input */\n');
fprintf(oid, '    }\n\n');

fprintf(oid, '    #InputUnits {\n');
fprintf(oid, '      width: 10%%; /* Width of search field */\n');
fprintf(oid, '      font-size: 14px; /* Increase font-size */\n');
fprintf(oid, '      border: 1px solid #ddd; /* Add a grey border */\n');
fprintf(oid, '      margin-bottom: 12px; /* Add some space below the input */\n');
fprintf(oid, '    }\n\n');

fprintf(oid, '    #InputLabel {\n');
fprintf(oid, '      width: 10%%; /* Width of search field */\n');
fprintf(oid, '      font-size: 14px; /* Increase font-size */\n');
fprintf(oid, '      border: 1px solid #ddd; /* Add a grey border */\n');
fprintf(oid, '      margin-bottom: 12px; /* Add some space below the input */\n');
fprintf(oid, '    }\n\n');

fprintf(oid, '    #InputShort {\n');
fprintf(oid, '      width: 10%%; /* Width of toggle field */\n');
fprintf(oid, '      font-size: 14px; /* Increase font-size */\n');
fprintf(oid, '      border: 1px solid #ddd; /* Add a grey border */\n');
fprintf(oid, '      margin-bottom: 12px; /* Add some space below the input */\n');
fprintf(oid, '    }\n');
fprintf(oid, '  </style>\n\n');

fprintf(oid, '</HEAD>\n\n');
fprintf(oid, '<BODY>\n\n');

			
% print out search boxes before the tables

fprintf(oid, '      <div>\n');
fprintf(oid, '        <input type="text" id="InputSymbol" onkeyup="FunctionSymbol()" placeholder="Search for symbol ..">\n');
fprintf(oid, '        <input type="text" id="InputUnits"  onkeyup="FunctionUnits()"  placeholder="Search for units ..">\n');
fprintf(oid, '        <input type="text" id="InputLabel"  onkeyup="FunctionLabel()"  placeholder="Search for label ..">\n');
fprintf(oid, '        <input type="text" id="InputShort"  onkeyup="FunctionShort()"  placeholder="Short/Medium/Long" title="Type S or M or L">\n');
fprintf(oid, '      </div>\n\n');

% print the table with the properties :    
fprintf(oid, '      <TABLE id="Table">\n');
fprintf(oid, '        <TR BGCOLOR = "#FFE7C6"><TH colspan="6"><font size="5">Model %s for %s (%s): Implied properties at %g &deg;C and f = %g</font></TH></TR>\n', model, speciesprintnm, speciesprintnm_en, K2C(T), f);
fprintf(oid, '        <TR BGCOLOR = "#FFE7C6"> <TH>symbol</TH> <TH>value</TH> <TH>units</TH> <TH> &deg;C </TH> <TH>func resp</TH> <TH>description</TH> </TR>\n');
for i = 1:length(flds)
  if isnan(txtStat.fresp.(flds{i}))
    txtStat.fresp.(flds{i}) = 'NA';
  else
    txtStat.fresp.(flds{i}) = num2str(txtStat.fresp.(flds{i}));
  end
  if isnan(txtStat.temp.(flds{i}))
    txtStat.temp.(flds{i}) = 'NA';
  else
    txtStat.temp.(flds{i}) = num2str(K2C(txtStat.temp.(flds{i})));
  end
  fprintf(oid, '        <TR id="%s"> <TD>%s</TD> <TD>%g</TD> <TD>%s</TD> <TD>%s</TD> <TD align="center">%s</TD> <TD>%s</TD></TR>\n',...
    flds{i}, flds{i}, stat.(flds{i}), txtStat.units.(flds{i}), txtStat.temp.(flds{i}), txtStat.fresp.(flds{i}), txtStat.label.(flds{i}));
end 
fprintf(oid, '      </TABLE>\n\n');


fprintf(oid, '      <script>\n');
fprintf(oid, '        function FunctionSymbol() {\n');
fprintf(oid, '          // Declare variables\n');
fprintf(oid, '          var input, filter, table, tr, td, i;\n');
fprintf(oid, '          input = document.getElementById("InputSymbol");\n');
fprintf(oid, '          filter = input.value.toUpperCase();\n');
fprintf(oid, '          table = document.getElementById("Table");\n');
fprintf(oid, '          tr = table.getElementsByTagName("tr");\n\n');

fprintf(oid, '          // Loop through all table rows, and hide those who don''t match the search query\n');
fprintf(oid, '          for (i = 0; i < tr.length; i++) {\n');
fprintf(oid, '          td = tr[i].getElementsByTagName("td")[0];\n');
fprintf(oid, '          if (td) {\n');
fprintf(oid, '            if (td.innerHTML.toUpperCase().indexOf(filter) > -1) {\n');
fprintf(oid, '              tr[i].style.display = "";\n');
fprintf(oid, '            } else {\n');
fprintf(oid, '              tr[i].style.display = "none";\n');
fprintf(oid, '              }\n');
fprintf(oid, '            }\n');
fprintf(oid, '          }\n');
fprintf(oid, '        }\n\n');

fprintf(oid, '        function FunctionUnits() {\n');
fprintf(oid, '          // Declare variables\n');
fprintf(oid, '          var input, filter, table, tr, td, i;\n');
fprintf(oid, '          input = document.getElementById("InputUnits");\n');
fprintf(oid, '          filter = input.value.toUpperCase();\n');
fprintf(oid, '          table = document.getElementById("Table");\n');
fprintf(oid, '          tr = table.getElementsByTagName("tr");\n\n');

fprintf(oid, '          // Loop through all table rows, and hide those who don''t match the search query\n');
fprintf(oid, '          for (i = 0; i < tr.length; i++) {\n');
fprintf(oid, '          td = tr[i].getElementsByTagName("td")[2];\n');
fprintf(oid, '          if (td) {\n');
fprintf(oid, '            if (td.innerHTML.toUpperCase().indexOf(filter) > -1) {\n');
fprintf(oid, '              tr[i].style.display = "";\n');
fprintf(oid, '            } else {\n');
fprintf(oid, '              tr[i].style.display = "none";\n');
fprintf(oid, '              }\n');
fprintf(oid, '            }\n');
fprintf(oid, '          }\n');
fprintf(oid, '        }\n\n');

fprintf(oid, '        function FunctionLabel() {\n');
fprintf(oid, '          // Declare variables\n');
fprintf(oid, '          var input, filter, table, tr, td, i;\n');
fprintf(oid, '          input = document.getElementById("InputLabel");\n');
fprintf(oid, '          filter = input.value.toUpperCase();\n');
fprintf(oid, '          table = document.getElementById("Table");\n');
fprintf(oid, '          tr = table.getElementsByTagName("tr");\n\n');

fprintf(oid, '          // Loop through all table rows, and hide those who don''t match the search query\n');
fprintf(oid, '          for (i = 0; i < tr.length; i++) {\n');
fprintf(oid, '          td = tr[i].getElementsByTagName("td")[5];\n');
fprintf(oid, '          if (td) {\n');
fprintf(oid, '            if (td.innerHTML.toUpperCase().indexOf(filter) > -1) {\n');
fprintf(oid, '              tr[i].style.display = "";\n');
fprintf(oid, '            } else {\n');
fprintf(oid, '              tr[i].style.display = "none";\n');
fprintf(oid, '              }\n');
fprintf(oid, '            }\n');
fprintf(oid, '          }\n');
fprintf(oid, '        }\n\n');

fprintf(oid, '        function FunctionShort() {\n');
fprintf(oid, '          // Declare variables\n');
fprintf(oid, '          var input, filter, table, tr, td, i;\n');
fprintf(oid, '          input = document.getElementById("InputShort");\n');
fprintf(oid, '          filter = input.value.toUpperCase();\n');
fprintf(oid, '          table = document.getElementById("Table");\n');
fprintf(oid, '          tr = table.getElementsByTagName("tr");\n\n');

fprintf(oid, '          // Loop through all table rows, and show some from the long list\n');
fprintf(oid, '          if (filter == "S") {\n');
fprintf(oid, '            for (i = 0; i < tr.length; i++) {\n');
fprintf(oid, '              td = tr[i].getElementsByTagName("td")[0];\n');
fprintf(oid, '              if (td) {\n');
fprintf(oid, '                if (\n');
fprintf(oid, '                    td.innerHTML == "c_T" ||\n');
fprintf(oid, '                    td.innerHTML == "Ww_0" ||\n');
fprintf(oid, '                    td.innerHTML == "Ww_b" ||\n');
fprintf(oid, '                    td.innerHTML == "Ww_p" ||\n');
fprintf(oid, '                    td.innerHTML == "Ww_i" ||\n');
fprintf(oid, '                    td.innerHTML == "a_b" ||\n');
fprintf(oid, '                    td.innerHTML == "a_p" ||\n');
fprintf(oid, '                    td.innerHTML == "a_m" ||\n');
fprintf(oid, '                    td.innerHTML == "t_starve" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Ci" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Hi" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Oi" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Ni" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Xi" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Pi" ||\n');
fprintf(oid, '                    td.innerHTML == "p_Ti" ||\n');
fprintf(oid, '                    td.innerHTML == "r_B" ||\n');
fprintf(oid, '                    td.innerHTML == "R_i" ||\n');
fprintf(oid, '                    td.innerHTML == "del_V"\n');
fprintf(oid, '                  ) {\n');
fprintf(oid, '                  tr[i].style.display = "";\n');
fprintf(oid, '                } else {\n');
fprintf(oid, '                  tr[i].style.display = "none";\n');
fprintf(oid, '                }\n');
fprintf(oid, '              }\n');
fprintf(oid, '            }\n');
fprintf(oid, '          } else if (filter == "M") {\n');
fprintf(oid, '            for (i = 0; i < tr.length; i++) {\n');
fprintf(oid, '              td = tr[i].getElementsByTagName("td")[0];\n');
fprintf(oid, '              if (td) {\n');
fprintf(oid, '                if (\n');
fprintf(oid, '                    td.innerHTML == "z" ||\n');
fprintf(oid, '                    td.innerHTML == "c_T" ||\n');
fprintf(oid, '                    td.innerHTML == "s_M" ||\n');
fprintf(oid, '                    td.innerHTML == "s_Hbp" ||\n');
fprintf(oid, '                    td.innerHTML == "s_s" ||\n');
fprintf(oid, '                    td.innerHTML == "E_0" ||\n');
fprintf(oid, '                    td.innerHTML == "Ww_0" ||\n');
fprintf(oid, '                    td.innerHTML == "Ww_b" ||\n');
fprintf(oid, '                    td.innerHTML == "Ww_p" ||\n');
fprintf(oid, '                    td.innerHTML == "Ww_i" ||\n');
fprintf(oid, '                    td.innerHTML == "a_b" ||\n');
fprintf(oid, '                    td.innerHTML == "a_p" ||\n');
fprintf(oid, '                    td.innerHTML == "a_99" ||\n');
fprintf(oid, '                    td.innerHTML == "a_m" ||\n');
fprintf(oid, '                    td.innerHTML == "t_starve" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Ci" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Hi" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Oi" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Ni" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Xi" ||\n');
fprintf(oid, '                    td.innerHTML == "J_Pi" ||\n');
fprintf(oid, '                    td.innerHTML == "p_Ti" ||\n');
fprintf(oid, '                    td.innerHTML == "r_B" ||\n');
fprintf(oid, '                    td.innerHTML == "R_i" ||\n');
fprintf(oid, '                    td.innerHTML == "N_i" ||\n');
fprintf(oid, '                    td.innerHTML == "del_V" ||\n');
fprintf(oid, '                    td.innerHTML == "W_dWm" ||\n');
fprintf(oid, '                    td.innerHTML == "dWm" ||\n');
fprintf(oid, '                    td.innerHTML == "del_Wb" ||\n');
fprintf(oid, '                    td.innerHTML == "del_Wp" ||\n');
fprintf(oid, '                    td.innerHTML == "t_E" ||\n');
fprintf(oid, '                    td.innerHTML == "xi_WE"\n');
fprintf(oid, '                  ) {\n');
fprintf(oid, '                  tr[i].style.display = "";\n');
fprintf(oid, '                } else {\n');
fprintf(oid, '                  tr[i].style.display = "none";\n');
fprintf(oid, '                }\n');
fprintf(oid, '              }\n');
fprintf(oid, '            }\n');
fprintf(oid, '          } else {\n');
fprintf(oid, '              for (i = 0; i < tr.length; i++) {\n');
fprintf(oid, '                tr[i].style.display = "";\n');
fprintf(oid, '              }\n');
fprintf(oid, '          }\n');
fprintf(oid, '        }\n\n');

fprintf(oid, '      </script>\n');

fprintf(oid, '</BODY>\n');
fprintf(oid, '</HTML>\n');

fclose(oid);

web(fileName,'-browser')
%web(fileName)

