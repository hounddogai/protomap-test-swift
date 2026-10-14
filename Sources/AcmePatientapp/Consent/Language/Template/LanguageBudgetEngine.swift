import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language budget calculation.
    protocol LanguageBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: LanguageBudget, value: Double) -> Double
    }

    final class FlaggedLanguageBudgetAdjuster: LanguageBudgetAdjuster {
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

        func adjust(_ item: LanguageBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LanguageBudgetMinimumOffsetAdjuster: LanguageBudgetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: LanguageBudget, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class NameLanguageBudgetAdjuster: LanguageBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LanguageBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLanguageBudgetAdjuster: LanguageBudgetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLanguageBudgetAdjuster: LanguageBudgetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLanguageBudgetAdjuster: LanguageBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the language budget steps in order and keeps a trace of each.
    final class LanguageBudgetEngine {
        var steps: [any LanguageBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguageBudget) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageBudgetAdjuster = steps[index]
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

        func evaluateAll(_ items: [LanguageBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguageBudgetEngine(_ flags: Kit.Flags.Registry) -> LanguageBudgetEngine {
        return LanguageBudgetEngine(
            steps: [
                FlaggedLanguageBudgetAdjuster(flags: flags, flag: "language-budget-weighted", percent: -3.0),
                LanguageBudgetMinimumOffsetAdjuster(weight: 0.83),
                NameLanguageBudgetAdjuster(factors: ["south": 0.7, "east": 1.19]),
                TieredLanguageBudgetAdjuster(
                    bounds: [4764.0, 5889.0, 6866.0, 7518.0],
                    rates: [1.14, 0.85, 1.08, 1.07]
                ),
                MinimumLanguageBudgetAdjuster(minimum: 21.6),
                PercentLanguageBudgetAdjuster(percent: -8.8),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 8758.0
        )
    }
}
