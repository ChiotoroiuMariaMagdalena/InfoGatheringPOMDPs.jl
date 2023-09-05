using Plots; default(fontfamily="Computer Modern", framestyle=:box)
using StatsBase
using Plots.Measures
using DataFrames

function worst_reward(pomdp) 
    minimum([reward(pomdp, s, a) for a in pomdp.terminal_actions for s in states(pomdp)])
end

function symbol_histogram(unique_syms, symarray; kwargs...)
    counts = [sum(symarray .== s) for s in unique_syms]
    syms = string.(unique_syms)
    margin = 0.6*maximum(length.(syms))
    plot(1:length(syms), counts ./ sum(counts), seriestype=:bar, xrotation=60, xticks=(1:length(syms), syms), ylabel="Frequency", label="", normalize=:pdf, bottom_margin=margin*mm; kwargs...)
end

function combine_actions(actions)
    combined_actions = []
    for as in actions
        for a in as
            if a isa Symbol
                push!(combined_actions, string(a))
            elseif a isa ObservationAction
                push!(combined_actions, a.name)
            else
                error("Unknown action type: ", typeof(a))
            end
        end
    end
    return combined_actions
end

function histogram_with_cdf(data, bins=nothing; kwargs...)
    if !isnothing(bins)
        h = fit(Histogram, data, bins, closed=:right)
    else
        h = fit(Histogram, data, nbins=10, closed=:right)
    end
    h = StatsBase.normalize(h, mode=:probability)
    edges = h.edges[1]
    counts = h.weights
    cdf_values = cumsum(counts) ./ sum(counts)
    p = plot(h, seriestype=:bar, ylabel="Probability", ylims=(0,1.1), label="Probability", legend=:topleft, margin=5mm; kwargs...)

    plot!(edges[2:end], cdf_values, label="CDF", lw=2)
    return p
end

function policy_results_summary(pomdp, results, policy_name)
    p_final_action = symbol_histogram(pomdp.terminal_actions, results[:final_action], xlabel = "Final Action", title="$policy_name  - Final Action")
    
    p_pes = histogram_with_cdf(results[:PES], 0:0.1:1, xlims=(0,1), xlabel="PES", title="$policy_name - PES")
    
    rlow = worst_reward(pomdp)
    p_expected_loss = histogram_with_cdf(results[:expected_loss], range(rlow, 0, length=100), xlims=(rlow,0), xlabel="Expected Loss", title="$policy_name - Expected Loss")

    all_actions = actions(pomdp)
    all_actions = [a isa Symbol ? string(a) : a.name for a in all_actions]
    p_actions = symbol_histogram(all_actions, combine_actions(results[:actions]), xlabel="Actions", title="$policy_name  - Actions")

    p_data = plot(legend=false, grid=false, axis=false, ticks=nothing, border=:none, size=(800,400))
    annotate!(0,0.9,("Mean Discounted Reward: $(round(mean(results[:reward]), digits=2))", :left))
    annotate!(0,0.8,("Mean Observation Cost: $(round(mean(results[:obs_cost]), digits=2))", :left))
    annotate!(0,0.7,("Mean Number of Observations: $(round(mean(results[:num_obs]), digits=2))", :left))
    annotate!(0,0.6,("Mean Correct Scenario: $(round(mean(results[:correct_scenario]), digits=2))", :left))
    annotate!(0,0.5,("Mean Correct Go/NoGo: $(round(mean(results[:correct_gonogo]), digits=2))", :left))

    plot(p_final_action, p_actions, p_data, p_pes, p_expected_loss, layout=(2,3), legend=false, size=(1400,800), left_margin=5mm, right_margin=5mm)
end

function policy_comparison_summary(policy_results, policy_names)
    bottom_margin = 0.6*maximum(length.(policy_names))*mm
    p_reward = bar(policy_names, [mean(r[:reward]) for r in policy_results], xrotation=60, bottom_margin=bottom_margin, ylabel="Mean Discounted Reward", title="Mean Discounted Reward", legend=false)
    p_obs_cost = bar(policy_names, [mean(r[:obs_cost]) for r in policy_results], xrotation=60, bottom_margin=bottom_margin, ylabel="Mean Observation Cost", title="Mean Observation Cost", legend=false, yflip=true)
    p_num_obs = bar(policy_names, [mean(r[:num_obs]) for r in policy_results], xrotation=60, bottom_margin=bottom_margin, ylabel="Mean Number of Observations", title="Mean Number of Observations", legend=false)
    p_correct_scenario = bar(policy_names, [mean(r[:correct_scenario]) for r in policy_results], xrotation=60, bottom_margin=bottom_margin, ylabel="Mean Correct Scenario", title="Mean Correct Scenario", legend=false)
    p_correct_gonogo = bar(policy_names, [mean(r[:correct_gonogo]) for r in policy_results], xrotation=60, bottom_margin=bottom_margin, ylabel="Mean Correct Go/NoGo", title="Mean Correct Go/NoGo", legend=false)
    plot(p_reward, p_obs_cost, p_num_obs, p_correct_scenario, p_correct_gonogo, layout=(2,3), legend=false, size=(1400,800), margin=5mm)
end

function train_states_comparison_summary(results)
    p_reward = plot()
    p_obs_cost = plot()
    p_num_obs = plot()
    p_correct_scenario = plot()
    p_correct_gonogo = plot()
    p_legend = plot(legend=false, grid=false, axis=false, ticks=nothing, border=:none, size=(800,400))

    for (policy_name, pol_results) in results
        plot!(p_reward, pol_results[:Ngeologies], [mean(r[:reward]) for r in pol_results[:results]],xlabel="No. Geologies", ylabel="Mean Discounted Reward", legend = false)
        plot!(p_obs_cost, pol_results[:Ngeologies], [mean(r[:obs_cost]) for r in pol_results[:results]],  xlabel="No. Geologies", ylabel="Mean Observation Cost", legend = false)
        plot!(p_num_obs, pol_results[:Ngeologies], [mean(r[:num_obs]) for r in pol_results[:results]], xlabel="No. Geologies", ylabel="Mean Number of Observations", legend = false)
        plot!(p_correct_scenario, pol_results[:Ngeologies], [mean(r[:correct_scenario]) for r in pol_results[:results]], xlabel="No. Geologies", ylabel="Mean Correct Scenario", legend = false)
        plot!(p_correct_gonogo, pol_results[:Ngeologies], [mean(r[:correct_gonogo]) for r in pol_results[:results]], xlabel="No. Geologies", ylabel="Mean Correct Go/NoGo", legend = false)
        plot!(p_legend, [], [], label=policy_name, legend=:topleft)
    end
    plot(p_reward, p_obs_cost, p_num_obs, p_correct_scenario, p_correct_gonogo, p_legend, layout=(2,3),size=(1400,800), margin=5mm)
end
