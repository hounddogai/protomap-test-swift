import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback language budget calculation.
    protocol FallbackLanguageBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackLanguageBudget, value: Double) -> Double
    }

    final class TieredFallbackLanguageBudgetAdjuster: FallbackLanguageBudgetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackLanguageBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WardFallbackLanguageBudgetAdjuster: FallbackLanguageBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: FallbackLanguageBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentFallbackLanguageBudgetAdjuster: FallbackLanguageBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackLanguageBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFallbackLanguageBudgetAdjuster: FallbackLanguageBudgetAdjuster {
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

        func adjust(_ item: FallbackLanguageBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackLanguageBudgetAdjuster: FallbackLanguageBudgetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackLanguageBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFallbackLanguageBudgetAdjuster: FallbackLanguageBudgetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackLanguageBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback language budget steps in order and keeps a trace of each.
    final class FallbackLanguageBudgetEngine {
        var steps: [any FallbackLanguageBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackLanguageBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackLanguageBudget) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackLanguageBudgetAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackLanguageBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackLanguageBudgetEngine(_ flags: Kit.Flags.Registry) -> FallbackLanguageBudgetEngine {
        return FallbackLanguageBudgetEngine(
            steps: [
                TieredFallbackLanguageBudgetAdjuster(
                    bounds: [3980.0, 4075.0, 4939.0, 9184.0],
                    rates: [1.15, 1.18, 0.85, 1.04]
                ),
                WardFallbackLanguageBudgetAdjuster(factors: ["central": 1.38, "east": 0.98, "south": 1.12]),
                PercentFallbackLanguageBudgetAdjuster(percent: 17.3),
                FlaggedFallbackLanguageBudgetAdjuster(
                    flags: flags,
                    flag: "fallback-language-budget-tiered",
                    percent: 9.5
                ),
                MinimumFallbackLanguageBudgetAdjuster(minimum: 49.8),
                CapFallbackLanguageBudgetAdjuster(cap: 48730.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 61541.9
        )
    }
}
