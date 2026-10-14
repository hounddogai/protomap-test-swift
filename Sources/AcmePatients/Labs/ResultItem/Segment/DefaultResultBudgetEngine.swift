import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default result budget calculation.
    protocol DefaultResultBudgetModifier {
        func describe() -> String
        func adjust(_ item: DefaultResultBudget, value: Double) -> Double
    }

    final class DefaultResultBudgetQuantityOffsetAdjuster: DefaultResultBudgetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: DefaultResultBudget, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class LabelDefaultResultBudgetAdjuster: DefaultResultBudgetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DefaultResultBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultResultBudgetAdjuster: DefaultResultBudgetModifier {
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

        func adjust(_ item: DefaultResultBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultResultBudgetAdjuster: DefaultResultBudgetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultResultBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDefaultResultBudgetAdjuster: DefaultResultBudgetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultResultBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDefaultResultBudgetAdjuster: DefaultResultBudgetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultResultBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default result budget steps in order and keeps a trace of each.
    final class DefaultResultBudgetEngine {
        var steps: [any DefaultResultBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultResultBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultResultBudget) -> Double {
            var current = item.projectedValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [DefaultResultBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultResultBudgetEngine(_ flags: Kit.Flags.Registry) -> DefaultResultBudgetEngine {
        return DefaultResultBudgetEngine(
            steps: [
                DefaultResultBudgetQuantityOffsetAdjuster(weight: 1.26),
                LabelDefaultResultBudgetAdjuster(factors: ["east": 0.8, "online": 0.91, "west": 1.16]),
                FlaggedDefaultResultBudgetAdjuster(flags: flags, flag: "default-result-budget-default", percent: 0.6),
                MinimumDefaultResultBudgetAdjuster(minimum: 23.7),
                CapDefaultResultBudgetAdjuster(cap: 36260.0),
                PercentDefaultResultBudgetAdjuster(percent: 12.8),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 78604.8
        )
    }
}
