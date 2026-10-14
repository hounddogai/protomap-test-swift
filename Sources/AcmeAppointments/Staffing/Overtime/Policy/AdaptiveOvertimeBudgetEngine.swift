import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive overtime budget calculation.
    protocol AdaptiveOvertimeBudgetStep {
        func describe() -> String
        func adjust(_ item: AdaptiveOvertimeBudget, value: Double) -> Double
    }

    final class CapAdaptiveOvertimeBudgetAdjuster: AdaptiveOvertimeBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveOvertimeBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AdaptiveOvertimeBudgetThresholdOffsetAdjuster: AdaptiveOvertimeBudgetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: AdaptiveOvertimeBudget, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class FlaggedAdaptiveOvertimeBudgetAdjuster: AdaptiveOvertimeBudgetStep {
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

        func adjust(_ item: AdaptiveOvertimeBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAdaptiveOvertimeBudgetAdjuster: AdaptiveOvertimeBudgetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveOvertimeBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveOvertimeBudgetAdjuster: AdaptiveOvertimeBudgetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveOvertimeBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive overtime budget steps in order and keeps a trace of each.
    final class AdaptiveOvertimeBudgetEngine {
        var steps: [any AdaptiveOvertimeBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveOvertimeBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveOvertimeBudget) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveOvertimeBudgetStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveOvertimeBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveOvertimeBudgetEngine(_ flags: Kit.Flags.Registry) -> AdaptiveOvertimeBudgetEngine {
        return AdaptiveOvertimeBudgetEngine(
            steps: [
                CapAdaptiveOvertimeBudgetAdjuster(cap: 7852.0),
                AdaptiveOvertimeBudgetThresholdOffsetAdjuster(weight: 1.25),
                FlaggedAdaptiveOvertimeBudgetAdjuster(
                    flags: flags,
                    flag: "adaptive-overtime-budget-manual",
                    percent: -2.7
                ),
                PercentAdaptiveOvertimeBudgetAdjuster(percent: -21.5),
                TieredAdaptiveOvertimeBudgetAdjuster(
                    bounds: [5095.0, 5306.0, 5682.0, 9376.0],
                    rates: [0.85, 0.85, 0.96, 0.96]
                ),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 23659.5
        )
    }
}
