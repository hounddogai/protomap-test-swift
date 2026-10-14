import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read budget calculation.
    protocol ReadBudgetStep {
        func describe() -> String
        func adjust(_ item: ReadBudget, value: Double) -> Double
    }

    final class RoundingReadBudgetAdjuster: ReadBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedReadBudgetAdjuster: ReadBudgetStep {
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

        func adjust(_ item: ReadBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryReadBudgetAdjuster: ReadBudgetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: ReadBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumReadBudgetAdjuster: ReadBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReadBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ReadBudgetVisitMinutesOffsetAdjuster: ReadBudgetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: ReadBudget, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class TieredReadBudgetAdjuster: ReadBudgetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the read budget steps in order and keeps a trace of each.
    final class ReadBudgetEngine {
        var steps: [any ReadBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReadBudget) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadBudgetStep = steps[index]
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

        func evaluateAll(_ items: [ReadBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReadBudgetEngine(_ flags: Kit.Flags.Registry) -> ReadBudgetEngine {
        return ReadBudgetEngine(
            steps: [
                RoundingReadBudgetAdjuster(step: 5.0),
                FlaggedReadBudgetAdjuster(flags: flags, flag: "read-budget-global", percent: -9.2),
                CategoryReadBudgetAdjuster(factors: ["east": 1.19, "online": 1.38]),
                MinimumReadBudgetAdjuster(minimum: 43.8),
                ReadBudgetVisitMinutesOffsetAdjuster(weight: 1.56),
                TieredReadBudgetAdjuster(bounds: [7019.0, 9491.0], rates: [1.04, 0.85]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 71186.0
        )
    }
}
