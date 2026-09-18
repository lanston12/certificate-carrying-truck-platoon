function cells = cell_parameters(p)
% Two deliberately small overlapping operating regions. Bounds are
% simulation assumptions to be checked against the implemented plant.
cells(1).id = 'C1';
cells(1).name = 'cool nominal braking';
cells(1).temp_C = [25 115];
cells(1).pressure_Pa = [0 p.pressure_max];
cells(1).rho_factor = [0.88 1.02];
cells(1).rho_rate_factor = 0.0035; % max absolute efficacy-factor rate /s
cells(1).tau_a = 0.12;
cells(1).tau_a_max = 0.16;
cells(1).tau_jitter = 0.04;
cells(1).brake_lower = 2.0; % m/s^2, conservative scenario guard
cells(2).id = 'C2';
cells(2).name = 'warm degraded braking';
cells(2).temp_C = [100 300];
cells(2).pressure_Pa = [0 p.pressure_max];
cells(2).rho_factor = [0.68 0.96];
cells(2).rho_rate_factor = 0.0035;
cells(2).tau_a = 0.18;
cells(2).tau_a_max = 0.23;
cells(2).tau_jitter = 0.05;
cells(2).brake_lower = 1.5;
for j = 1:numel(cells)
    cells(j).mass_kg = [min(p.masses) max(p.masses)];
    cells(j).h = p.headway;
    cells(j).tau_a_range = [cells(j).tau_a-cells(j).tau_jitter cells(j).tau_a_max];
    cells(j).tau_c = p.comm_delay;
    cells(j).d_c = p.comm_delay_rate;
    % Frozen search candidate from deterministic seed 17, independently
    % re-audited after setting the common route headway to 3.0 s.
    cells(j).alpha = 1.469684564020977;
    cells(j).alpha_d = 0.11279419684118;
    cells(j).delta_port = 5;
    cells(j).split_weight = 0.5855203069423992;
    cells(j).eta = 0.2771884222623144;
    cells(j).vartheta2 = 35.08295112336388;
    cells(j).komega = 2544.057675984996;
    cells(j).qbar = p.accel_virtual_limit;
    cells(j).qdotbar = p.accel_virtual_slew;
    cells(j).umin = p.force_min;
    cells(j).umax = p.force_max;
    cells(j).udotbar = p.force_slew;
    cells(j).cpi = p.headway*cells(j).tau_a - cells(j).tau_a^2/2;
    cells(j).kappa_pi = 1.02*(1+1/cells(j).eta)*cells(j).cpi^2;
end
end
