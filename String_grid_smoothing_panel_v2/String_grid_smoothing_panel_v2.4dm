/*---------------------------------------------------------------------
**   Programmer:           KLP
**   Date:                 2026-05-27
**   12D Model:            V15
**   Version:              002
**   Macro Name:           String_grid_smoothing_panel.4dm
**   Type:                 SOURCE
**
**   Brief description: 
**     A 12dPL terrain-processing tool designed to reduce noise, sensor jitter, 
**     and "spikes" within existing String_grid elements. This macro is 
**     specifically optimized for LiDAR-derived terrain where preserving sharp 
**     civil features like kerbs, channel inverts, and embankments is critical 
**     for engineering design .
**
** Multi-Stage Filtering Workflow:
**     1. Median Spike Filter: A non-linear stage used for the targeted removal 
**        of isolated vegetation blunders and "salt-and-pepper" noise .
**     2. Bilateral Smoothing: The primary edge-aware refinement stage that 
**        weights neighbors based on both horizontal distance and vertical 
**        elevation differences .
**     3. Gaussian Smoothing: An optional stage for broad surface softening, 
**        typically reserved for cartographic or floodplain presentation .
**
**---------------------------------------------------------------------
**   Update/Modification
**
**  This macro may be reproduced, modified and used without restriction.
**  The author grants all users Unlimited Use of the source code and any
**  associated files, for no fee. Unlimited Use includes compiling, running,
**  and modifying the code for individual or integrated purposes.
**  The author also grants 12d Solutions Pty Ltd and other users permission
**  to incorporate this macro, in whole or in part, into other macros or programs.
**---------------------------------------------------------------------
*/
#define DEBUG_FILE      0
#define ECHO_DEBUG_FILE 0
#define ECHO_LINE_NO    0

#define BUILD "version.0.002"

// ----------------------------- INCLUDES -----------------------------
#include "standard_library.H"
#include "size_of.h"

/*global variables*/{

}

// helper: simple ascending sort for Real fixed array
void sort_real_array(Real &vals[], Integer n)
{
    Integer i = 0;
    Integer j = 0;
    Real tmp = 0.0;

    for(i = 1; i <= n - 1; i++) {
        for(j = i + 1; j <= n; j++) {
            if(vals[j] < vals[i]) {
                tmp = vals[i];
                vals[i] = vals[j];
                vals[j] = tmp;
            }
        }
    }
}

// helper: apply supplied median spike logic only
// Optimised: cache grid heights once, preserve in-place/cascading behaviour
Integer apply_median_spike_filter(
    Element grid,
    Integer xmin,
    Integer ymin,
    Integer xmax,
    Integer ymax,
    Integer median_window_size,
    Real spike_tolerance,
    Real median_max_vertical_change,
    Integer min_valid_neighbours,
    Integer &median_clipped_count
)
{
    Integer ix = 0;
    Integer iy = 0;
    Integer nx = 0;
    Integer ny = 0;
    Integer idx = 0;
    Integer nidx = 0;
    Integer rc = 0;

    Integer x_count = xmax - xmin + 1;
    Integer y_count = ymax - ymin + 1;
    Integer total = x_count * y_count;

    Integer half_window = median_window_size / 2;
    Integer altered = 0;
    Integer count = 0;
    Integer mid = 0;

    Real z = 0.0;
    Real median = 0.0;
    Real diff = 0.0;
    Real raw_change = 0.0;
    Real capped_change = 0.0;

    Real source_z[total];
    Integer valid[total];
    Integer changed[total];

    Integer max_neighbours = median_window_size * median_window_size;
    Real vals[max_neighbours];

    median_clipped_count = 0;

    for(idx = 1; idx <= total; idx++) {
        valid[idx] = 0;
        changed[idx] = 0;
        source_z[idx] = 0.0;
    }

    for(iy = ymin; iy <= ymax; iy++) {
        for(ix = xmin; ix <= xmax; ix++) {
            idx = (iy - ymin) * x_count + (ix - xmin) + 1;

            rc = Get_grid_height(grid,ix,iy,z);
            if(rc == 0) {
                valid[idx] = 1;
                source_z[idx] = z;
            }
        }
    }

    for(iy = ymin; iy <= ymax; iy++) {
        for(ix = xmin; ix <= xmax; ix++) {
            idx = (iy - ymin) * x_count + (ix - xmin) + 1;

            if(!valid[idx]) continue;

            z = source_z[idx];
            count = 0;

            for(ny = iy - half_window; ny <= iy + half_window; ny++) {
                for(nx = ix - half_window; nx <= ix + half_window; nx++) {

                    if(nx < xmin || nx > xmax || ny < ymin || ny > ymax) continue;
                    if(nx == ix && ny == iy) continue;

                    nidx = (ny - ymin) * x_count + (nx - xmin) + 1;

                    if(valid[nidx]) {
                        count++;
                        vals[count] = source_z[nidx];
                    }
                }
            }

            if(count < min_valid_neighbours) continue;

            sort_real_array(vals,count);

            if((count % 2) == 1) {
                mid = (count + 1) / 2;
                median = vals[mid];
            } else {
                mid = count / 2;
                median = (vals[mid] + vals[mid + 1]) / 2.0;
            }

            diff = z - median;
            if(diff < 0.0) diff = -diff;

            if(diff > spike_tolerance) {
                raw_change = median - z;
                capped_change = raw_change;

                if(median_max_vertical_change > 0.0) {
                    if(capped_change > median_max_vertical_change) {
                        capped_change = median_max_vertical_change;
                        median_clipped_count++;
                    }
                    if(capped_change < -median_max_vertical_change) {
                        capped_change = -median_max_vertical_change;
                        median_clipped_count++;
                    }
                }

                source_z[idx] = z + capped_change;
                changed[idx] = 1;
                altered++;
            }
        }
    }

    for(iy = ymin; iy <= ymax; iy++) {
        for(ix = xmin; ix <= xmax; ix++) {
            idx = (iy - ymin) * x_count + (ix - xmin) + 1;

            if(changed[idx]) {
                Set_grid_height(grid,ix,iy,source_z[idx]);
            }
        }
    }

    return(altered);
}

// helper: apply supplied Gaussian weighted smoothing logic only
// Optimised: precomputes kernel offsets and weights once
Integer apply_gaussian_filter(
    Element grid,
    Integer xmin,
    Integer ymin,
    Integer xmax,
    Integer ymax,
    Real spacing_x,
    Real spacing_y,
    Real gauss_radius,
    Real gauss_sigma,
    Integer gauss_passes,
    Real max_vertical_change
)
{
    Integer ix = 0;
    Integer iy = 0;
    Integer nx = 0;
    Integer ny = 0;
    Integer pass = 0;
    Integer rc = 0;

    Integer x_count = xmax - xmin + 1;
    Integer y_count = ymax - ymin + 1;
    Integer total = x_count * y_count;

    Integer idx = 0;
    Integer nidx = 0;

    Integer x_radius = 0;
    Integer y_radius = 0;

    Real z = 0.0;
    Real original_z[total];
    Real source_z[total];
    Real target_z[total];
    Integer valid[total];

    Real dx = 0.0;
    Real dy = 0.0;
    Real d2 = 0.0;
    Real radius2 = gauss_radius * gauss_radius;
    Real sigma2 = 2.0 * gauss_sigma * gauss_sigma;
    Real sum_w = 0.0;
    Real sum_z = 0.0;
    Real new_z = 0.0;
    Real change = 0.0;
    Real abs_spacing_x = spacing_x;
    Real abs_spacing_y = spacing_y;

    Integer altered = 0;

    if(abs_spacing_x < 0.0) abs_spacing_x = -abs_spacing_x;
    if(abs_spacing_y < 0.0) abs_spacing_y = -abs_spacing_y;

    if(abs_spacing_x <= 0.0 || abs_spacing_y <= 0.0) return(0);

    x_radius = Ceil(gauss_radius / abs_spacing_x);
    y_radius = Ceil(gauss_radius / abs_spacing_y);

    Integer max_kernel = (2 * x_radius + 1) * (2 * y_radius + 1);
    Integer k = 0;
    Integer kernel_count = 0;
    Integer kx[max_kernel];
    Integer ky[max_kernel];
    Real kw[max_kernel];

    for(ny = -y_radius; ny <= y_radius; ny++) {
        for(nx = -x_radius; nx <= x_radius; nx++) {

            dx = nx * spacing_x;
            dy = ny * spacing_y;
            d2 = dx * dx + dy * dy;

            if(d2 <= radius2) {
                kernel_count++;
                kx[kernel_count] = nx;
                ky[kernel_count] = ny;
                kw[kernel_count] = Exp(-(d2) / sigma2);
            }
        }
    }

    for(iy = ymin; iy <= ymax; iy++) {
        for(ix = xmin; ix <= xmax; ix++) {
            idx = (iy - ymin) * x_count + (ix - xmin) + 1;

            rc = Get_grid_height(grid,ix,iy,z);
            if(rc == 0) {
                valid[idx] = 1;
                original_z[idx] = z;
                source_z[idx] = z;
                target_z[idx] = z;
            } else {
                valid[idx] = 0;
                original_z[idx] = 0.0;
                source_z[idx] = 0.0;
                target_z[idx] = 0.0;
            }
        }
    }

    for(pass = 1; pass <= gauss_passes; pass++) {
        for(iy = ymin; iy <= ymax; iy++) {
            for(ix = xmin; ix <= xmax; ix++) {
                idx = (iy - ymin) * x_count + (ix - xmin) + 1;

                if(!valid[idx]) continue;

                sum_w = 0.0;
                sum_z = 0.0;

                for(k = 1; k <= kernel_count; k++) {
                    nx = ix + kx[k];
                    ny = iy + ky[k];

                    if(nx < xmin || nx > xmax || ny < ymin || ny > ymax) continue;

                    nidx = (ny - ymin) * x_count + (nx - xmin) + 1;
                    if(!valid[nidx]) continue;

                    sum_w += kw[k];
                    sum_z += source_z[nidx] * kw[k];
                }

                if(sum_w > 0.0) {
                    new_z = sum_z / sum_w;
                    change = new_z - source_z[idx];

                    if(change > max_vertical_change) {
                        new_z = source_z[idx] + max_vertical_change;
                    }

                    if(change < -max_vertical_change) {
                        new_z = source_z[idx] - max_vertical_change;
                    }

                    target_z[idx] = new_z;
                } else {
                    target_z[idx] = source_z[idx];
                }
            }
        }

        for(idx = 1; idx <= total; idx++) {
            if(valid[idx]) source_z[idx] = target_z[idx];
        }
    }

    for(iy = ymin; iy <= ymax; iy++) {
        for(ix = xmin; ix <= xmax; ix++) {
            idx = (iy - ymin) * x_count + (ix - xmin) + 1;

            if(valid[idx]) {
                change = source_z[idx] - original_z[idx];
                if(change < 0.0) change = -change;

                if(change > 0.000001) {
                    rc = Set_grid_height(grid,ix,iy,source_z[idx]);
                    if(rc == 0) altered++;
                }
            }
        }
    }

    return(altered);
}

// helper: apply supplied median spike logic only using cached arrays
Integer apply_median_spike_filter_array(
    Real &source_z[],
    Integer &valid[],
    Integer x_count,
    Integer xmin,
    Integer ymin,
    Integer xmax,
    Integer ymax,
    Integer median_window_size,
    Real spike_tolerance,
    Real median_max_vertical_change,
    Integer min_valid_neighbours,
    Integer &median_clipped_count
)
{
    Integer ix = 0;
    Integer iy = 0;
    Integer nx = 0;
    Integer ny = 0;
    Integer idx = 0;
    Integer nidx = 0;

    Integer half_window = median_window_size / 2;
    Integer altered = 0;
    Integer count = 0;
    Integer mid = 0;

    Real z = 0.0;
    Real median = 0.0;
    Real diff = 0.0;
    Real raw_change = 0.0;
    Real capped_change = 0.0;

    Integer max_neighbours = median_window_size * median_window_size;
    Real vals[max_neighbours];

    median_clipped_count = 0;

    for(iy = ymin; iy <= ymax; iy++) {
        for(ix = xmin; ix <= xmax; ix++) {
            idx = (iy - ymin) * x_count + (ix - xmin) + 1;

            if(!valid[idx]) continue;

            z = source_z[idx];
            count = 0;

            for(ny = iy - half_window; ny <= iy + half_window; ny++) {
                for(nx = ix - half_window; nx <= ix + half_window; nx++) {

                    if(nx < xmin || nx > xmax || ny < ymin || ny > ymax) continue;
                    if(nx == ix && ny == iy) continue;

                    nidx = (ny - ymin) * x_count + (nx - xmin) + 1;

                    if(valid[nidx]) {
                        count++;
                        vals[count] = source_z[nidx];
                    }
                }
            }

            if(count < min_valid_neighbours) continue;

            sort_real_array(vals,count);

            if((count % 2) == 1) {
                mid = (count + 1) / 2;
                median = vals[mid];
            } else {
                mid = count / 2;
                median = (vals[mid] + vals[mid + 1]) / 2.0;
            }

            diff = z - median;
            if(diff < 0.0) diff = -diff;

            if(diff > spike_tolerance) {
                raw_change = median - z;
                capped_change = raw_change;

                if(median_max_vertical_change > 0.0) {
                    if(capped_change > median_max_vertical_change) {
                        capped_change = median_max_vertical_change;
                        median_clipped_count++;
                    }
                    if(capped_change < -median_max_vertical_change) {
                        capped_change = -median_max_vertical_change;
                        median_clipped_count++;
                    }
                }

                source_z[idx] = z + capped_change;
                altered++;
            }
        }
    }

    return(altered);
}

// helper: apply supplied Gaussian weighted smoothing logic only using cached arrays
Integer apply_gaussian_filter_array(
    Real &source_z[],
    Integer &valid[],
    Integer x_count,
    Integer y_count,
    Integer xmin,
    Integer ymin,
    Integer xmax,
    Integer ymax,
    Real spacing_x,
    Real spacing_y,
    Real gauss_radius,
    Real gauss_sigma,
    Integer gauss_passes,
    Real max_vertical_change
)
{
    Integer ix = 0;
    Integer iy = 0;
    Integer nx = 0;
    Integer ny = 0;
    Integer pass = 0;

    Integer total = x_count * y_count;
    Integer idx = 0;
    Integer nidx = 0;

    Integer x_radius = 0;
    Integer y_radius = 0;

    Real target_z[total];

    Real dx = 0.0;
    Real dy = 0.0;
    Real d2 = 0.0;
    Real radius2 = gauss_radius * gauss_radius;
    Real sigma2 = 2.0 * gauss_sigma * gauss_sigma;
    Real sum_w = 0.0;
    Real sum_z = 0.0;
    Real new_z = 0.0;
    Real change = 0.0;
    Real abs_spacing_x = spacing_x;
    Real abs_spacing_y = spacing_y;

    Integer altered = 0;

    if(abs_spacing_x < 0.0) abs_spacing_x = -abs_spacing_x;
    if(abs_spacing_y < 0.0) abs_spacing_y = -abs_spacing_y;

    if(abs_spacing_x <= 0.0 || abs_spacing_y <= 0.0) return(0);

    x_radius = Ceil(gauss_radius / abs_spacing_x);
    y_radius = Ceil(gauss_radius / abs_spacing_y);

    Integer max_kernel = (2 * x_radius + 1) * (2 * y_radius + 1);
    Integer k = 0;
    Integer kernel_count = 0;
    Integer kx[max_kernel];
    Integer ky[max_kernel];
    Real kw[max_kernel];

    for(ny = -y_radius; ny <= y_radius; ny++) {
        for(nx = -x_radius; nx <= x_radius; nx++) {

            dx = nx * spacing_x;
            dy = ny * spacing_y;
            d2 = dx * dx + dy * dy;

            if(d2 <= radius2) {
                kernel_count++;
                kx[kernel_count] = nx;
                ky[kernel_count] = ny;
                kw[kernel_count] = Exp(-(d2) / sigma2);
            }
        }
    }

    for(idx = 1; idx <= total; idx++) {
        target_z[idx] = source_z[idx];
    }

    for(pass = 1; pass <= gauss_passes; pass++) {
        for(iy = ymin; iy <= ymax; iy++) {
            for(ix = xmin; ix <= xmax; ix++) {
                idx = (iy - ymin) * x_count + (ix - xmin) + 1;

                if(!valid[idx]) continue;

                sum_w = 0.0;
                sum_z = 0.0;

                for(k = 1; k <= kernel_count; k++) {
                    nx = ix + kx[k];
                    ny = iy + ky[k];

                    if(nx < xmin || nx > xmax || ny < ymin || ny > ymax) continue;

                    nidx = (ny - ymin) * x_count + (nx - xmin) + 1;
                    if(!valid[nidx]) continue;

                    sum_w += kw[k];
                    sum_z += source_z[nidx] * kw[k];
                }

                if(sum_w > 0.0) {
                    new_z = sum_z / sum_w;
                    change = new_z - source_z[idx];

                    if(change > max_vertical_change) {
                        new_z = source_z[idx] + max_vertical_change;
                    }

                    if(change < -max_vertical_change) {
                        new_z = source_z[idx] - max_vertical_change;
                    }

                    target_z[idx] = new_z;
                } else {
                    target_z[idx] = source_z[idx];
                }
            }
        }

        for(idx = 1; idx <= total; idx++) {
            if(valid[idx]) {
                source_z[idx] = target_z[idx];
            }
        }
    }

    for(idx = 1; idx <= total; idx++) {
        if(valid[idx]) {
            change = source_z[idx] - target_z[idx];
            if(change < 0.0) change = -change;
            if(change > 0.000001) altered++;
        }
    }

    return(altered);
}


// helper: apply Bilateral weighted smoothing logic using cached arrays
Integer apply_bilateral_filter_array(
    Real &source_z[],
    Integer &valid[],
    Integer x_count,
    Integer y_count,
    Integer xmin,
    Integer ymin,
    Integer xmax,
    Integer ymax,
    Real spacing_x,
    Real spacing_y,
    Integer bilateral_window_size,
    Real bilateral_sigma_spatial,
    Real bilateral_sigma_range,
    Real bilateral_noise_threshold,
    Real max_vertical_change,
    Integer &clipped_count
)
{
    Integer ix = 0;
    Integer iy = 0;
    Integer nx = 0;
    Integer ny = 0;

    Integer total = x_count * y_count;
    Integer idx = 0;
    Integer nidx = 0;

    Integer half_window = bilateral_window_size / 2;
    Integer max_kernel = bilateral_window_size * bilateral_window_size;
    Integer k = 0;
    Integer kernel_count = 0;
    Integer kx[max_kernel];
    Integer ky[max_kernel];
    Real spatial_w[max_kernel];

    Real target_z[total];

    Real abs_spacing_x = spacing_x;
    Real abs_spacing_y = spacing_y;
    Real dx = 0.0;
    Real dy = 0.0;
    Real d2 = 0.0;
    Real spatial_sigma2 = 2.0 * bilateral_sigma_spatial * bilateral_sigma_spatial;
    Real range_sigma2 = 2.0 * bilateral_sigma_range * bilateral_sigma_range;

    Real centre_z = 0.0;
    Real neighbour_z = 0.0;
    Real dz = 0.0;
    Real range_w = 0.0;
    Real weight = 0.0;
    Real sum_w = 0.0;
    Real sum_z = 0.0;
    Real new_z = 0.0;
    Real change = 0.0;
    Real abs_change = 0.0;

    Integer altered = 0;

    clipped_count = 0;

    if(abs_spacing_x < 0.0) abs_spacing_x = -abs_spacing_x;
    if(abs_spacing_y < 0.0) abs_spacing_y = -abs_spacing_y;

    if(abs_spacing_x <= 0.0 || abs_spacing_y <= 0.0) return(0);
    if(bilateral_window_size < 3) return(0);
    if((bilateral_window_size % 2) == 0) return(0);
    if(bilateral_sigma_spatial <= 0.0) return(0);
    if(bilateral_sigma_range <= 0.0) return(0);

    for(ny = -half_window; ny <= half_window; ny++) {
        for(nx = -half_window; nx <= half_window; nx++) {
            dx = nx * abs_spacing_x;
            dy = ny * abs_spacing_y;
            d2 = dx * dx + dy * dy;

            kernel_count++;
            kx[kernel_count] = nx;
            ky[kernel_count] = ny;
            spatial_w[kernel_count] = Exp(-(d2) / spatial_sigma2);
        }
    }

    for(idx = 1; idx <= total; idx++) {
        target_z[idx] = source_z[idx];
    }

    for(iy = ymin; iy <= ymax; iy++) {
        for(ix = xmin; ix <= xmax; ix++) {
            idx = (iy - ymin) * x_count + (ix - xmin) + 1;

            if(!valid[idx]) continue;

            centre_z = source_z[idx];
            sum_w = 0.0;
            sum_z = 0.0;

            for(k = 1; k <= kernel_count; k++) {
                nx = ix + kx[k];
                ny = iy + ky[k];

                if(nx < xmin || nx > xmax || ny < ymin || ny > ymax) continue;

                nidx = (ny - ymin) * x_count + (nx - xmin) + 1;
                if(!valid[nidx]) continue;

                neighbour_z = source_z[nidx];
                dz = neighbour_z - centre_z;

                range_w = Exp(-(dz * dz) / range_sigma2);
                weight = spatial_w[k] * range_w;

                sum_w += weight;
                sum_z += neighbour_z * weight;
            }

            if(sum_w > 0.0) {
                new_z = sum_z / sum_w;
                change = new_z - centre_z;
                abs_change = change;
                if(abs_change < 0.0) abs_change = -abs_change;

                if(abs_change < bilateral_noise_threshold) {
                    new_z = centre_z;
                    change = 0.0;
                }

                if(max_vertical_change > 0.0) {
                    if(change > max_vertical_change) {
                        new_z = centre_z + max_vertical_change;
                        clipped_count++;
                    }

                    if(change < -max_vertical_change) {
                        new_z = centre_z - max_vertical_change;
                        clipped_count++;
                    }
                }

                target_z[idx] = new_z;

                abs_change = new_z - centre_z;
                if(abs_change < 0.0) abs_change = -abs_change;
                if(abs_change > 0.000001) altered++;
            } else {
                target_z[idx] = centre_z;
            }
        }
    }

    for(idx = 1; idx <= total; idx++) {
        if(valid[idx]) {
            source_z[idx] = target_z[idx];
        }
    }

    return(altered);
}

// ----------------------------- PANEL -----------------------------

// helper: update Median and Bilateral defaults from grid resolution, vertical RMSE and preset
void update_median_bilateral_defaults(
    Real_Box rb_grid_resolution,
    Real_Box rb_vertical_rmse,
    Choice_Box cb_smoothing_preset,
    Integer_Box ib_median_window_size,
    Real_Box rb_spike_tolerance,
    Real_Box rb_median_max_vertical_change,
    Integer_Box ib_min_valid_neighbours,
    Integer_Box ib_bilateral_window_size,
    Real_Box rb_bilateral_sigma_spatial,
    Real_Box rb_bilateral_sigma_range,
    Real_Box rb_bilateral_noise_threshold,
    Real_Box rb_bilateral_max_vertical_change,
    Colour_Message_Box cmbMsg)
{
    Real grid_resolution = 1.0;
    Real vertical_rmse = 0.035;
    Text preset = "Light";

    if(Validate(rb_grid_resolution,grid_resolution) == 0) {
        Set_data(cmbMsg,"Preset update skipped: invalid grid resolution",1);
        return;
    }

    if(Validate(rb_vertical_rmse,vertical_rmse) == 0) {
        Set_data(cmbMsg,"Preset update skipped: invalid vertical RMSE",1);
        return;
    }

    if(Validate(cb_smoothing_preset,preset) == 0) {
        preset = "Light";
    }

    if(grid_resolution <= 0.0) {
        Set_data(cmbMsg,"Preset update skipped: grid resolution must be greater than zero",1);
        return;
    }

    if(vertical_rmse <= 0.0) {
        Set_data(cmbMsg,"Preset update skipped: vertical RMSE must be greater than zero",1);
        return;
    }

    if(preset == "Strong") {
        Set_data(ib_median_window_size,5);
        Set_data(rb_spike_tolerance,6.0 * vertical_rmse);
        Set_data(rb_median_max_vertical_change,3.0 * vertical_rmse);
        Set_data(ib_min_valid_neighbours,8);

        Set_data(ib_bilateral_window_size,5);
        Set_data(rb_bilateral_sigma_spatial,3.0 * grid_resolution);
        Set_data(rb_bilateral_sigma_range,3.0 * vertical_rmse);
        Set_data(rb_bilateral_noise_threshold,0.5 * vertical_rmse);
        Set_data(rb_bilateral_max_vertical_change,2.0 * vertical_rmse);
    }
    else if(preset == "Medium") {
        Set_data(ib_median_window_size,3);
        Set_data(rb_spike_tolerance,5.0 * vertical_rmse);
        Set_data(rb_median_max_vertical_change,2.0 * vertical_rmse);
        Set_data(ib_min_valid_neighbours,6);

        Set_data(ib_bilateral_window_size,5);
        Set_data(rb_bilateral_sigma_spatial,2.0 * grid_resolution);
        Set_data(rb_bilateral_sigma_range,2.0 * vertical_rmse);
        Set_data(rb_bilateral_noise_threshold,0.25 * vertical_rmse);
        Set_data(rb_bilateral_max_vertical_change,1.5 * vertical_rmse);
    }
    else {
        Set_data(ib_median_window_size,3);
        Set_data(rb_spike_tolerance,4.0 * vertical_rmse);
        Set_data(rb_median_max_vertical_change,1.5 * vertical_rmse);
        Set_data(ib_min_valid_neighbours,5);

        Set_data(ib_bilateral_window_size,3);
        Set_data(rb_bilateral_sigma_spatial,1.0 * grid_resolution);
        Set_data(rb_bilateral_sigma_range,1.5 * vertical_rmse);
        Set_data(rb_bilateral_noise_threshold,0.0);
        Set_data(rb_bilateral_max_vertical_change,1.0 * vertical_rmse);
    }

    Set_data(cmbMsg,"Preset applied: " + preset,0);
}


void mainPanel(){
 
    Text panelName="String grid smoothing";
    Panel              panel  = Create_panel              (panelName,TRUE);
    Vertical_Group     vgroup = Create_vertical_group     (-1         );
    Colour_Message_Box cmbMsg = Create_colour_message_box (""         );

    ///////////////////CREATE INPUT WIDGETS////////////////
    // create some input fields

    // Snippet: panel widget creation
    // Signature: New_Select_Box Create_new_select_box(Text title,Text select_title,Integer mode,Message_Box message)
    New_Select_Box nsb_in_grid_name = Create_new_select_box("Input String_grid","Select input String_grid",SELECT_STRING,cmbMsg);

    // Signature: Real_Box Create_real_box(Text title,Message_Box message)
    Real_Box rb_grid_resolution = Create_real_box("String_grid resolution (m)",cmbMsg);

    // Signature: Real_Box Create_real_box(Text title,Message_Box message)
    Real_Box rb_vertical_rmse = Create_real_box("String_grid vertical RMSE (m)",cmbMsg);

    // Signature: Choice_Box Create_choice_box(Text title,Message_Box message)
    Choice_Box cb_smoothing_preset = Create_choice_box("Smoothing preset",cmbMsg);

    Text preset_choices[3];
    preset_choices[1] = "Light";
    preset_choices[2] = "Medium";
    preset_choices[3] = "Strong";
    Set_data(cb_smoothing_preset,3,preset_choices);
    Set_data(cb_smoothing_preset,"Light");

    // Signature: Name_Box Create_name_box(Text title,Message_Box message)
    Name_Box nb_out_grid_name = Create_name_box("Output String_grid name",cmbMsg);

    // Signature: Model_Box Create_model_box(Text title,Message_Box message,Integer mode)
    Model_Box mb_out_model_name = Create_model_box("Output model",cmbMsg,CHECK_MODEL_CREATE);

    // Signature: Named_Tick_Box Create_named_tick_box(Text title,Integer state,Text response)
    Named_Tick_Box ntb_use_median_filter = Create_named_tick_box("Apply median spike correction",1,"use_median_filter");

    // Signature: Integer_Box Create_integer_box(Text title,Message_Box message)
    Integer_Box ib_median_window_size = Create_integer_box("Median window size",cmbMsg);

    // Signature: Real_Box Create_real_box(Text title,Message_Box message)
    Real_Box rb_spike_tolerance = Create_real_box("Spike tolerance",cmbMsg);

    // Signature: Real_Box Create_real_box(Text title,Message_Box message)
    Real_Box rb_median_max_vertical_change = Create_real_box("Median maximum vertical change",cmbMsg);

    // Signature: Integer_Box Create_integer_box(Text title,Message_Box message)
    Integer_Box ib_min_valid_neighbours = Create_integer_box("Minimum valid neighbours",cmbMsg);

    // Signature: Named_Tick_Box Create_named_tick_box(Text title,Integer state,Text response)
    Named_Tick_Box ntb_use_bilateral_filter = Create_named_tick_box("Apply bilateral edge-aware smoothing",1,"use_bilateral_filter");

    // Signature: Integer_Box Create_integer_box(Text title,Message_Box message)
    Integer_Box ib_bilateral_window_size = Create_integer_box("Bilateral window size",cmbMsg);

    // Signature: Real_Box Create_real_box(Text title,Message_Box message)
    Real_Box rb_bilateral_sigma_spatial = Create_real_box("Bilateral spatial sigma",cmbMsg);

    // Signature: Real_Box Create_real_box(Text title,Message_Box message)
    Real_Box rb_bilateral_sigma_range = Create_real_box("Bilateral range sigma",cmbMsg);

    // Signature: Real_Box Create_real_box(Text title,Message_Box message)
    Real_Box rb_bilateral_noise_threshold = Create_real_box("Bilateral noise threshold",cmbMsg);

    // Signature: Real_Box Create_real_box(Text title,Message_Box message)
    Real_Box rb_bilateral_max_vertical_change = Create_real_box("Bilateral maximum vertical change",cmbMsg);

    // Signature: Named_Tick_Box Create_named_tick_box(Text title,Integer state,Text response)
    Named_Tick_Box ntb_use_gaussian_filter = Create_named_tick_box("Apply Gaussian broad smoothing",0,"use_gaussian_filter");

    // Signature: Real_Box Create_real_box(Text title,Message_Box message)
    Real_Box rb_gauss_radius = Create_real_box("Gaussian radius",cmbMsg);

    // Signature: Real_Box Create_real_box(Text title,Message_Box message)
    Real_Box rb_gauss_sigma = Create_real_box("Gaussian sigma",cmbMsg);

    // Signature: Integer_Box Create_integer_box(Text title,Message_Box message)
    Integer_Box ib_gauss_passes = Create_integer_box("Gaussian passes",cmbMsg);

    // Signature: Real_Box Create_real_box(Text title,Message_Box message)
    Real_Box rb_max_vertical_change = Create_real_box("Gaussian maximum vertical change",cmbMsg);

    Set_data(rb_grid_resolution,1.000);
    Set_data(rb_vertical_rmse,0.035);
    Set_data(ib_median_window_size,3);
    Set_data(rb_spike_tolerance,0.140);
    Set_data(rb_median_max_vertical_change,0.0525);
    Set_data(ib_min_valid_neighbours,5);
    Set_data(ib_bilateral_window_size,3);
    Set_data(rb_bilateral_sigma_spatial,1.000);
    Set_data(rb_bilateral_sigma_range,0.0525);
    Set_data(rb_bilateral_noise_threshold,0.000);
    Set_data(rb_bilateral_max_vertical_change,0.035);
    Set_data(rb_gauss_radius,3.000);
    Set_data(rb_gauss_sigma,1.000);
    Set_data(ib_gauss_passes,1);
    Set_data(rb_max_vertical_change,0.500);

  
    ///////////////ADDING BUTTONS ALONG THE BOTTOM///////////////////////////
    Horizontal_Group bgroup = Create_button_group();
    Button process     = Create_button       ("&Process" ,"process");
    Button finish      = Create_finish_button("Finish"   ,"Finish" );
    Button help_button = Create_help_button  (panel      ,"Help"   );
    Append(process      ,bgroup);
    Append(finish       ,bgroup);
    Append(help_button  ,bgroup);

    //////////// Group containers ///////////////////////////////////////////
    Vertical_Group vg_input_output    = Create_vertical_group(-1);
    Vertical_Group vg_median_filter   = Create_vertical_group(-1);
    Vertical_Group vg_bilateral_filter = Create_vertical_group(-1);
    Vertical_Group vg_gaussian_filter = Create_vertical_group(-1);

    // Signature: Integer Set_border(Vertical_Group group,Text text)
    Set_border(vg_input_output,"Input / Output");
    Set_border(vg_median_filter,"Median Spike Correction");
    Set_border(vg_bilateral_filter,"Bilateral Edge-Aware Smoothing");
    Set_border(vg_gaussian_filter,"Gaussian Broad Surface Smoothing");

    // Signature: Integer Set_border(Vertical_Group group,Integer bx,Integer by)
    Set_border(vg_input_output,10,8);
    Set_border(vg_median_filter,10,8);
    Set_border(vg_bilateral_filter,10,8);
    Set_border(vg_gaussian_filter,10,8);

        // Tooltips
    Set_tooltip(nsb_in_grid_name,
        "Select the existing input String_Grid containing elevations to smooth.");

    Set_tooltip(rb_grid_resolution,
        "Grid spacing in model units. Used only to populate Median and Bilateral preset defaults.");

    Set_tooltip(rb_vertical_rmse,
        "Vertical RMSE of the source surface in metres. Used only to populate Median and Bilateral preset defaults.");

    Set_tooltip(cb_smoothing_preset,
        "Select Light, Medium or Strong. Median and Bilateral fields update automatically.");

    Set_tooltip(nb_out_grid_name,
        "Enter the name for the new smoothed output String_Grid.");

    Set_tooltip(mb_out_model_name,
        "Select or create the model where the new output String_Grid will be placed.");

    Set_tooltip(ntb_use_median_filter,
        "Enable median spike filtering. Best for isolated high or low elevation spikes.");

    Set_tooltip(ib_median_window_size,
        "Odd window size for median filter. Use 3 for normal use. Larger values are slower and more aggressive.");

    Set_tooltip(rb_spike_tolerance,
        "Maximum allowed difference from neighbourhood median. Conservative default 0.25 reduces risk of changing real channels.");

    Set_tooltip(rb_median_max_vertical_change,
        "Maximum vertical movement allowed for each median correction. Use small values to avoid filling channels.");

    Set_tooltip(ib_min_valid_neighbours,
        "Minimum valid neighbouring cells required before a median value is used.");

    Set_tooltip(ntb_use_bilateral_filter,
        "Enable Bilateral weighted smoothing. Best for 1 m LiDAR DEM cleanup while preserving kerbs and sharp terrain breaks.");

    Set_tooltip(ib_bilateral_window_size,
        "Odd Bilateral window size. Conservative default is 3 to better preserve channels and drains.");

    Set_tooltip(rb_bilateral_sigma_spatial,
        "Spatial sigma in model units. Conservative 1 m default for 1 m grids.");

    Set_tooltip(rb_bilateral_sigma_range,
        "Range sigma in elevation units. Conservative 0.05 m default helps avoid smoothing across drains, kerbs and channels.");

    Set_tooltip(rb_bilateral_noise_threshold,
        "Minimum vertical change required before writing a Bilateral adjustment. Use 0.0 to apply all weighted results.");

    Set_tooltip(rb_bilateral_max_vertical_change,
        "Maximum Bilateral vertical change per cell. Conservative 0.05 m default limits feature loss.");

    Set_tooltip(ntb_use_gaussian_filter,
        "Enable Gaussian weighted smoothing. Best for light general smoothing of noisy grids.");

    Set_tooltip(rb_gauss_radius,
        "Neighbour search radius for Gaussian smoothing. Larger radius increases runtime.");

    Set_tooltip(rb_gauss_sigma,
        "Gaussian sigma controlling smoothing strength. Larger sigma gives broader smoothing.");

    Set_tooltip(ib_gauss_passes,
        "Number of Gaussian smoothing passes. Runtime increases approximately linearly with passes.");

    Set_tooltip(rb_max_vertical_change,
        "Maximum vertical change allowed per Gaussian pass. Smaller values preserve terrain more strongly.");

    Append(nsb_in_grid_name     ,vg_input_output);
    Append(rb_grid_resolution ,vg_input_output);
    Append(rb_vertical_rmse   ,vg_input_output);
    Append(cb_smoothing_preset,vg_input_output);
    Append(nb_out_grid_name   ,vg_input_output);
    Append(mb_out_model_name  ,vg_input_output);

    Append(ntb_use_median_filter  ,vg_median_filter);
    Append(ib_median_window_size        ,vg_median_filter);
    Append(rb_spike_tolerance           ,vg_median_filter);
    Append(rb_median_max_vertical_change,vg_median_filter);
    Append(ib_min_valid_neighbours      ,vg_median_filter);

    Append(ntb_use_bilateral_filter       ,vg_bilateral_filter);
    Append(ib_bilateral_window_size       ,vg_bilateral_filter);
    Append(rb_bilateral_sigma_spatial     ,vg_bilateral_filter);
    Append(rb_bilateral_sigma_range       ,vg_bilateral_filter);
    Append(rb_bilateral_noise_threshold   ,vg_bilateral_filter);
    Append(rb_bilateral_max_vertical_change,vg_bilateral_filter);

    Append(ntb_use_gaussian_filter,vg_gaussian_filter);
    Append(rb_gauss_radius        ,vg_gaussian_filter);
    Append(rb_gauss_sigma         ,vg_gaussian_filter);
    Append(ib_gauss_passes        ,vg_gaussian_filter);
    Append(rb_max_vertical_change ,vg_gaussian_filter);

    ///////////////ADDING WIDGETS TO PANEL///////////////////////////
    // add your widgets to vgroup

    // Signature: Integer Append(Widget widget,Vertical_Group group)
    Append(vg_input_output   ,vgroup);
    Append(vg_median_filter   ,vgroup);
    Append(vg_bilateral_filter,vgroup);
    Append(vg_gaussian_filter ,vgroup);


    Append(cmbMsg    ,vgroup);
    Append(bgroup    ,vgroup);


    Append(vgroup,panel);
    Show_widget(panel);
    Integer doit = 1;
    while(doit)
    {
        Text cmd="",msg = "";
        Integer id,ret = Wait_on_widgets(id,cmd,msg);
 
        switch(cmd)
        {
        case "keystroke" :
        case "set_focus"  :
        {
            continue;
        }
        break;
        case "kill_focus" :
        {
            if(id == Get_id(rb_grid_resolution) || id == Get_id(rb_vertical_rmse)) {
                update_median_bilateral_defaults(
                    rb_grid_resolution,
                    rb_vertical_rmse,
                    cb_smoothing_preset,
                    ib_median_window_size,
                    rb_spike_tolerance,
                    rb_median_max_vertical_change,
                    ib_min_valid_neighbours,
                    ib_bilateral_window_size,
                    rb_bilateral_sigma_spatial,
                    rb_bilateral_sigma_range,
                    rb_bilateral_noise_threshold,
                    rb_bilateral_max_vertical_change,
                    cmbMsg);
            }
            continue;
        }
        break;
        case "CodeShutdown" :
        {
            Set_exit_code(cmd);
        }
        break;
        }
        switch(id)
        {
        case Get_id(panel) :
        {
            if(cmd == "Panel Quit") doit = 0;
            if(cmd == "Panel About") about_panel(panel);
        }
        break; 
        case Get_id(cb_smoothing_preset) :
        case Get_id(rb_grid_resolution) :
        case Get_id(rb_vertical_rmse) :
        {
            update_median_bilateral_defaults(
                rb_grid_resolution,
                rb_vertical_rmse,
                cb_smoothing_preset,
                ib_median_window_size,
                rb_spike_tolerance,
                rb_median_max_vertical_change,
                ib_min_valid_neighbours,
                ib_bilateral_window_size,
                rb_bilateral_sigma_spatial,
                rb_bilateral_sigma_range,
                rb_bilateral_noise_threshold,
                rb_bilateral_max_vertical_change,
                cmbMsg);
        }
        break;
        case Get_id(process) :
        {
            if(cmd == "process")
            {
                // declare your widget variables

                Text in_grid_name = "";
                Text out_grid_name = "";
                Text out_model_name = "";

                Text median_window_size_text = "";
                Text spike_tolerance_text = "";
                Text median_max_vertical_change_text = "";
                Text min_valid_neighbours_text = "";

                Text bilateral_window_size_text = "";
                Text bilateral_sigma_spatial_text = "";
                Text bilateral_sigma_range_text = "";
                Text bilateral_noise_threshold_text = "";
                Text bilateral_max_vertical_change_text = "";

                Text gauss_radius_text = "";
                Text gauss_sigma_text = "";
                Text gauss_passes_text = "";
                Text max_vertical_change_text = "";

                Integer use_median_filter = 0;
                Integer median_window_size = 0;
                Real spike_tolerance = 0.0;
                Real median_max_vertical_change = 0.0;
                Integer min_valid_neighbours = 0;

                Integer use_bilateral_filter = 0;
                Integer bilateral_window_size = 0;
                Real bilateral_sigma_spatial = 0.0;
                Real bilateral_sigma_range = 0.0;
                Real bilateral_noise_threshold = 0.0;
                Real bilateral_max_vertical_change = 0.0;

                Integer use_gaussian_filter = 0;
                Real gauss_radius = 0.0;
                Real gauss_sigma = 0.0;
                Integer gauss_passes = 0;
                Real max_vertical_change = 0.0;

                Integer valid = 1;
                Text error_msg = "";

                // Signature: Integer Get_data(New_Select_Box select,Text &string)
                Get_data(nsb_in_grid_name,in_grid_name);

                Text clean_in_grid_name = in_grid_name;
                Integer tab_pos = Find_text(clean_in_grid_name,"\t");

                if(tab_pos > 0) {
                    clean_in_grid_name = Get_subtext(clean_in_grid_name,1,tab_pos - 1);
                }

                // Signature: Integer Get_data(Name_Box box,Text &data)
                Get_data(nb_out_grid_name,out_grid_name);

                // Signature: Integer Get_data(Model_Box box,Text &data)
                Get_data(mb_out_model_name,out_model_name);

                // Signature: Integer Get_data(Integer_Box box,Text &data)
                Get_data(ib_median_window_size,median_window_size_text);

                // Signature: Integer Get_data(Real_Box box,Text &data)
                Get_data(rb_spike_tolerance,spike_tolerance_text);

                // Signature: Integer Get_data(Real_Box box,Text &data)
                Get_data(rb_median_max_vertical_change,median_max_vertical_change_text);

                // Signature: Integer Get_data(Integer_Box box,Text &data)
                Get_data(ib_min_valid_neighbours,min_valid_neighbours_text);

                // Signature: Integer Get_data(Integer_Box box,Text &data)
                Get_data(ib_bilateral_window_size,bilateral_window_size_text);

                // Signature: Integer Get_data(Real_Box box,Text &data)
                Get_data(rb_bilateral_sigma_spatial,bilateral_sigma_spatial_text);

                // Signature: Integer Get_data(Real_Box box,Text &data)
                Get_data(rb_bilateral_sigma_range,bilateral_sigma_range_text);

                // Signature: Integer Get_data(Real_Box box,Text &data)
                Get_data(rb_bilateral_noise_threshold,bilateral_noise_threshold_text);

                // Signature: Integer Get_data(Real_Box box,Text &data)
                Get_data(rb_bilateral_max_vertical_change,bilateral_max_vertical_change_text);

                // Signature: Integer Get_data(Real_Box box,Text &data)
                Get_data(rb_gauss_radius,gauss_radius_text);

                // Signature: Integer Get_data(Real_Box box,Text &data)
                Get_data(rb_gauss_sigma,gauss_sigma_text);

                // Signature: Integer Get_data(Integer_Box box,Text &data)
                Get_data(ib_gauss_passes,gauss_passes_text);

                // Signature: Integer Get_data(Real_Box box,Text &data)
                Get_data(rb_max_vertical_change,max_vertical_change_text);

                // Signature: Integer From_text(Text text,Integer &value)
                From_text(median_window_size_text,median_window_size);
                From_text(min_valid_neighbours_text,min_valid_neighbours);
                From_text(bilateral_window_size_text,bilateral_window_size);
                From_text(gauss_passes_text,gauss_passes);

                // Signature: Integer From_text(Text text,Real &value)
                From_text(spike_tolerance_text,spike_tolerance);
                From_text(median_max_vertical_change_text,median_max_vertical_change);
                From_text(bilateral_sigma_spatial_text,bilateral_sigma_spatial);
                From_text(bilateral_sigma_range_text,bilateral_sigma_range);
                From_text(bilateral_noise_threshold_text,bilateral_noise_threshold);
                From_text(bilateral_max_vertical_change_text,bilateral_max_vertical_change);
                From_text(gauss_radius_text,gauss_radius);
                From_text(gauss_sigma_text,gauss_sigma);
                From_text(max_vertical_change_text,max_vertical_change);

                // Signature: Integer Validate(Named_Tick_Box box,Integer &result)
                // result = 0 unticked, result = 1 ticked
                // return value 0 indicates validation error for this call
                if(Validate(ntb_use_median_filter,use_median_filter) == 0) {
                    valid = 0;
                    error_msg += "Could not validate median filter tick box\n";
                }

                if(Validate(ntb_use_bilateral_filter,use_bilateral_filter) == 0) {
                    valid = 0;
                    error_msg += "Could not validate Bilateral filter tick box\n";
                }

                if(Validate(ntb_use_gaussian_filter,use_gaussian_filter) == 0) {
                    valid = 0;
                    error_msg += "Could not validate Gaussian filter tick box\n";
                }

                // validate widgets

                if(in_grid_name == "") {
                    valid = 0;
                    error_msg += "Input String_grid is blank\n";
                }

                if(out_grid_name == "") {
                    valid = 0;
                    error_msg += "Output String_grid name is blank\n";
                }

                if(out_model_name == "") {
                    valid = 0;
                    error_msg += "Output model name is blank\n";
                }

                if(use_median_filter) {
                    if(median_window_size < 3) {
                        valid = 0;
                        error_msg += "Median window size must be >= 3\n";
                    }
                    if(median_window_size > 3) {
                        Print("Warning: Median window size greater than 3 can greatly increase runtime.");
                    }

                    if((median_window_size % 2) == 0) {
                        valid = 0;
                        error_msg += "Median window size must be odd\n";
                    }

                    if(spike_tolerance < 0.0) {
                        valid = 0;
                        error_msg += "Spike tolerance must be >= 0\n";
                    }

                    if(median_max_vertical_change < 0.0) {
                        valid = 0;
                        error_msg += "Median maximum vertical change must be >= 0\n";
                    }

                    if(min_valid_neighbours < 1) {
                        valid = 0;
                        error_msg += "Minimum valid neighbours must be >= 1\n";
                    }
                }

                if(use_bilateral_filter) {
                    if(bilateral_window_size < 3) {
                        valid = 0;
                        error_msg += "Bilateral window size must be >= 3\n";
                    }

                    if((bilateral_window_size % 2) == 0) {
                        valid = 0;
                        error_msg += "Bilateral window size must be odd\n";
                    }

                    if(bilateral_window_size > 5) {
                        Print("Warning: Bilateral window size greater than 5 can greatly increase runtime.");
                    }

                    if(bilateral_sigma_spatial <= 0.0) {
                        valid = 0;
                        error_msg += "Bilateral spatial sigma must be > 0\n";
                    }

                    if(bilateral_sigma_range <= 0.0) {
                        valid = 0;
                        error_msg += "Bilateral range sigma must be > 0\n";
                    }

                    if(bilateral_noise_threshold < 0.0) {
                        valid = 0;
                        error_msg += "Bilateral noise threshold must be >= 0\n";
                    }

                    if(bilateral_max_vertical_change < 0.0) {
                        valid = 0;
                        error_msg += "Bilateral maximum vertical change must be >= 0\n";
                    }
                }

                if(use_gaussian_filter) {
                    if(gauss_radius <= 0.0) {
                        valid = 0;
                        error_msg += "Gaussian radius must be > 0\n";
                    }

                    if(gauss_radius > 3.0) {
                        Print("Warning: Gaussian radius greater than 3 can greatly increase runtime.");
                    }

                    if(gauss_sigma <= 0.0) {
                        valid = 0;
                        error_msg += "Gaussian sigma must be > 0\n";
                    }

                    if(gauss_passes < 1) {
                        valid = 0;
                        error_msg += "Gaussian passes must be >= 1\n";
                    }

                    if(gauss_passes > 1) {
                        Print("Warning: Multiple Gaussian passes increase runtime approximately linearly.");
                    }

                    if(max_vertical_change < 0.0) {
                        valid = 0;
                        error_msg += "Maximum vertical change must be >= 0\n";
                    }
                }

                if(!use_median_filter && !use_bilateral_filter && !use_gaussian_filter) {
                    valid = 0;
                    error_msg += "At least one smoothing stage must be enabled\n";
                }

                if(!valid) {
                    Set_data(cmbMsg,error_msg);
                    continue;
                }

                Clear_console();

                Set_data(cmbMsg,"Processing String_grid smoothing. Large grids may take several minutes. Please wait...");

                Print("String_grid smoothing started.");
                Print("Large grids may take several minutes.");
                Print();

                // do calc

                Element in_grid;
                Element out_grid;
                Model out_model;
                
                Text grid_type = "";

                Integer xmin = 0;
                Integer ymin = 0;
                Integer xmax = 0;
                Integer ymax = 0;

                Real origin_x = 0.0;
                Real origin_y = 0.0;
                Real spacing_x = 0.0;
                Real spacing_y = 0.0;
                Real grid_angle = 0.0;

                Real min_diff = 0.0;
                Real max_diff = 0.0;
                Real mean_diff = 0.0;
                Real std_diff = 0.0;
                Integer diff_count = 0;

                Real process_start_time = 0.0;
                Real process_end_time = 0.0;
                Real process_elapsed_time = 0.0;

                Integer input_cell_count = 0;
                Real input_cell_count_million = 0.0;

                Integer rc = 0;

                // Signature: Integer Validate(New_Select_Box select,Element &string)
                rc = Validate(nsb_in_grid_name,in_grid);
                if(rc == 0) {
                    Set_data(cmbMsg,"Input String_grid validation failed: " + in_grid_name);
                    continue;
                }

                // Signature: Integer Get_model(Element element,Model &model)
                Model in_model;
                rc = Get_model(in_grid,in_model);
                if(rc != 0) {
                    Set_data(cmbMsg,"Could not get input grid model from selected String_grid");
                    continue;
                }

                // Signature: Integer Get_type(Element element,Text &type)
                rc = Get_type(in_grid,grid_type);
                if(rc != 0) {
                    Set_data(cmbMsg,"Could not read input element type");
                    continue;
                }

                if(grid_type != "String_Grid") {
                    Set_data(cmbMsg,"Selected element is not a Grid String. Type = " + grid_type);
                    continue;
                }

                // Signature: Integer Get_grid_range(Element elt,Integer &xmin,Integer &ymin,Integer &xmax,Integer &ymax)
                rc = Get_grid_range(in_grid,xmin,ymin,xmax,ymax);
                if(rc != 0) {
                    Set_data(cmbMsg,"Could not read input grid range");
                    continue;
                }

                input_cell_count = (xmax - xmin + 1) * (ymax - ymin + 1);
                input_cell_count_million = input_cell_count / 1000000.0;

                // Signature: Integer Get_grid_geometry(Element elt,Real &origin_x,Real &origin_y,Real &spacing_x,Real &spacing_y,Real &angle)
                rc = Get_grid_geometry(in_grid,origin_x,origin_y,spacing_x,spacing_y,grid_angle);
                if(rc != 0) {
                    Set_data(cmbMsg,"Could not read input grid geometry");
                    continue;
                }

                // Signature: Model Get_model_create(Text name)
                out_model = Get_model_create(out_model_name);

                // Signature: Element Create_grid_string()
                out_grid = Create_grid_string();

                // Signature: Integer Set_name(Element element,Text name)
                rc = Set_name(out_grid,out_grid_name);
                if(rc != 0) {
                    Set_data(cmbMsg,"Could not set output grid name");
                    continue;
                }

                // Signature: Integer Set_model(Element element,Model model)
                rc = Set_model(out_grid,out_model);
                if(rc != 0) {
                    Set_data(cmbMsg,"Could not set output grid model");
                    continue;
                }

                // Signature: Integer Set_grid_range(Element elt,Integer xmin,Integer ymin,Integer xmax,Integer ymax)
                rc = Set_grid_range(out_grid,xmin,ymin,xmax,ymax);
                if(rc != 0) {
                    Set_data(cmbMsg,"Could not set output grid range");
                    continue;
                }

                // Signature: Integer Set_grid_geometry(Element elt,Real origin_x,Real origin_y,Real spacing_x,Real spacing_y,Real angle)
                rc = Set_grid_geometry(out_grid,origin_x,origin_y,spacing_x,spacing_y,grid_angle);
                if(rc != 0) {
                    Set_data(cmbMsg,"Could not set output grid geometry");
                    continue;
                }

                // Signature: Integer Get_time(Real &time)
                Get_time(process_start_time);

                Integer ix = 0;
                Integer iy = 0;
                Integer idx = 0;

                Integer grid_columns = xmax - xmin + 1;
                Integer grid_rows = ymax - ymin + 1;
                Integer total_cells = grid_columns * grid_rows;

                Integer copied_cells = 0;
                Integer skipped_cells = 0;
                Integer written_cells = 0;

                Real in_z = 0.0;
                Real out_z = 0.0;
                Real diff = 0.0;
                Real sum_diff = 0.0;
                Real sum_diff_sq = 0.0;
                Real variance = 0.0;

                Real original_z[total_cells];
                Real work_z[total_cells];
                Integer valid_cell[total_cells];

                for(idx = 1; idx <= total_cells; idx++) {
                    original_z[idx] = 0.0;
                    work_z[idx] = 0.0;
                    valid_cell[idx] = 0;
                }

                for(iy = ymin; iy <= ymax; iy++) {
                    for(ix = xmin; ix <= xmax; ix++) {
                        idx = (iy - ymin) * grid_columns + (ix - xmin) + 1;

                        // Signature: Integer Get_grid_height(Element elt,Integer xc,Integer yc,Real &ht)
                        rc = Get_grid_height(in_grid,ix,iy,in_z);

                        if(rc == 0) {
                            original_z[idx] = in_z;
                            work_z[idx] = in_z;
                            valid_cell[idx] = 1;
                            copied_cells++;
                        } else {
                            skipped_cells++;
                        }
                    }
                }

                Integer median_altered_cells = 0;
                Integer median_clipped_cells = 0;

                if(use_median_filter) {
                    median_altered_cells = apply_median_spike_filter_array(
                        work_z,
                        valid_cell,
                        grid_columns,
                        xmin,
                        ymin,
                        xmax,
                        ymax,
                        median_window_size,
                        spike_tolerance,
                        median_max_vertical_change,
                        min_valid_neighbours,
                        median_clipped_cells
                    );
                }

                Integer bilateral_altered_cells = 0;
                Integer bilateral_clipped_cells = 0;

                if(use_bilateral_filter) {
                    bilateral_altered_cells = apply_bilateral_filter_array(
                        work_z,
                        valid_cell,
                        grid_columns,
                        grid_rows,
                        xmin,
                        ymin,
                        xmax,
                        ymax,
                        spacing_x,
                        spacing_y,
                        bilateral_window_size,
                        bilateral_sigma_spatial,
                        bilateral_sigma_range,
                        bilateral_noise_threshold,
                        bilateral_max_vertical_change,
                        bilateral_clipped_cells
                    );
                }

                Integer gaussian_altered_cells = 0;

                if(use_gaussian_filter) {
                    gaussian_altered_cells = apply_gaussian_filter_array(
                        work_z,
                        valid_cell,
                        grid_columns,
                        grid_rows,
                        xmin,
                        ymin,
                        xmax,
                        ymax,
                        spacing_x,
                        spacing_y,
                        gauss_radius,
                        gauss_sigma,
                        gauss_passes,
                        max_vertical_change
                    );
                }

                diff_count = 0;
                min_diff = 0.0;
                max_diff = 0.0;
                mean_diff = 0.0;
                std_diff = 0.0;
                sum_diff = 0.0;
                sum_diff_sq = 0.0;

                for(iy = ymin; iy <= ymax; iy++) {
                    for(ix = xmin; ix <= xmax; ix++) {
                        idx = (iy - ymin) * grid_columns + (ix - xmin) + 1;

                        if(valid_cell[idx]) {
                            out_z = work_z[idx];

                            // Signature: Integer Set_grid_height(Element elt,Integer xc,Integer yc,Real ht)
                            rc = Set_grid_height(out_grid,ix,iy,out_z);

                            if(rc == 0) {
                                written_cells++;
                            }

                            diff = out_z - original_z[idx];

                            diff_count++;

                            if(diff_count == 1) {
                                min_diff = diff;
                                max_diff = diff;
                            } else {
                                if(diff < min_diff) min_diff = diff;
                                if(diff > max_diff) max_diff = diff;
                            }

                            sum_diff += diff;
                            sum_diff_sq += diff * diff;
                        }
                    }
                }

                if(diff_count > 0) {
                    mean_diff = sum_diff / diff_count;
                    variance = (sum_diff_sq / diff_count) - (mean_diff * mean_diff);
                    if(variance < 0.0) variance = 0.0;
                    std_diff = Sqrt(variance);
                }

                // Signature: Integer Calc_extent(Element element)
                Calc_extent(out_grid);

                // Signature: Integer Calc_extent(Model model)
                Calc_extent(out_model);
                // Signature: Integer Get_time(Real &time)
                Get_time(process_end_time);

                process_elapsed_time = process_end_time - process_start_time;
                if(process_elapsed_time < 0.0) {
                    process_elapsed_time += 86400.0;
                }

                Real max_lowering = 0.0;
                Real max_raising = 0.0;

                if(min_diff < 0.0) max_lowering = -min_diff;
                if(max_diff > 0.0) max_raising = max_diff;

                Print("String_grid smoothing report\n");
                Print("----------------------------\n");
                Print("Input grid: " + clean_in_grid_name + "\n");
                Print("Output grid: " + out_grid_name + "\n");                Print("Output model: " + out_model_name + "\n");
                Print();
                Print("Input data size: " + To_text(input_cell_count) + " cells (approx. " + To_text(input_cell_count_million,1) + " million points)\n");
                //Print("Grid index range: X " + To_text(xmin) + " to " + To_text(xmax) + ", Y " + To_text(ymin) + " to " + To_text(ymax));
                Print("Grid dimensions: " + To_text(grid_columns) + " columns x " + To_text(grid_rows) + " rows\n");
                Print("Grid origin: " + To_text(origin_x,3) + ", " + To_text(origin_y,3) + "\n");
                Print("Grid spacing: " + To_text(spacing_x,3) + " x " + To_text(spacing_y,3) + " model units\n");
                Print();
                Print("Processing summary\n");
                Print("------------------\n");
                Print("Loaded input grid height cells: " + To_text(copied_cells) + "\n");
                Print("Written output grid height cells: " + To_text(written_cells) + "\n");
                Print("Skipped/undefined cells: " + To_text(skipped_cells) + "\n");
                Print("Median altered cells: " + To_text(median_altered_cells) + "\n");
                Print("Median max-change clipped cells: " + To_text(median_clipped_cells) + "\n");
                Print("Bilateral altered cells: " + To_text(bilateral_altered_cells) + "\n");
                Print("Bilateral max-change clipped cells: " + To_text(bilateral_clipped_cells) + "\n");
                Print("Gaussian altered cells: " + To_text(gaussian_altered_cells) + "\n");
                Print();
                Print("Vertical difference summary\n");
                Print("---------------------------\n");
                Print("Difference definition: output Z - input Z\n");
                Print("Compared cells: " + To_text(diff_count) + "\n");
                Print("Maximum lowering: " + To_text(max_lowering,6) + "\n");
                Print("Maximum raising: " + To_text(max_raising,6) + "\n");
                Print("Mean vertical change: " + To_text(mean_diff,6) + "\n");
                Print("Standard deviation of change: " + To_text(std_diff,6) + "\n");
                Print();
                Print("Processing time: " + To_text(process_elapsed_time,1) + " seconds\n");
                Print("String_grid smoothing finished.");
                Print();

                Set_data(cmbMsg,"Process finished. See output window for report.");
            }
        }

        break;
        default :
        {
            if(cmd == "Finish")doit = 0;
        }
        break; 
        }
    }
}
void main(){

    // do some checks before you go to the main panel


    mainPanel();
}