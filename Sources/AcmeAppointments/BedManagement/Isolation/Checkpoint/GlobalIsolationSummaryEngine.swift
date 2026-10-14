import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the global isolation summary calculation.
    protocol GlobalIsolationSummaryModifier {
        func describe() -> String
        func adjust(_ item: GlobalIsolationSummary, value: Double) -> Double
    }

    final class RoundingGlobalIsolationSummaryAdjuster: GlobalIsolationSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalIsolationSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredGlobalIsolationSummaryAdjuster: GlobalIsolationSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalIsolationSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedGlobalIsolationSummaryAdjuster: GlobalIsolationSummaryModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: GlobalIsolationSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalIsolationSummaryAdjuster: GlobalIsolationSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalIsolationSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGlobalIsolationSummaryAdjuster: GlobalIsolationSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalIsolationSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global isolation summary steps in order and keeps a trace of each.
    final class GlobalIsolationSummaryEngine {
        var steps: [any GlobalIsolationSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalIsolationSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalIsolationSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalIsolationSummaryModifier = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [GlobalIsolationSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalIsolationSummaryEngine(_ flags: Kit.Flags.Registry) -> GlobalIsolationSummaryEngine {
        return GlobalIsolationSummaryEngine(
            steps: [
                RoundingGlobalIsolationSummaryAdjuster(step: 1.0),
                TieredGlobalIsolationSummaryAdjuster(
                    bounds: [1132.0, 1990.0, 4604.0, 4803.0],
                    rates: [1.11, 1.15, 1.07, 0.89]
                ),
                FlaggedGlobalIsolationSummaryAdjuster(
                    flags: flags,
                    flag: "global-isolation-summary-weighted",
                    percent: -5.5
                ),
                MinimumGlobalIsolationSummaryAdjuster(minimum: 24.8),
                CapGlobalIsolationSummaryAdjuster(cap: 12956.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 36070.9
        )
    }
}
