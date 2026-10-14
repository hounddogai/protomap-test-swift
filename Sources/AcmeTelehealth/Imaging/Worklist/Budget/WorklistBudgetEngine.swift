import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist budget calculation.
    protocol WorklistBudgetModifier {
        func describe() -> String
        func adjust(_ item: WorklistBudget, value: Double) -> Double
    }

    final class LabelWorklistBudgetAdjuster: WorklistBudgetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WorklistBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class WorklistBudgetRefillsOffsetAdjuster: WorklistBudgetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: WorklistBudget, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class TieredWorklistBudgetAdjuster: WorklistBudgetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWorklistBudgetAdjuster: WorklistBudgetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWorklistBudgetAdjuster: WorklistBudgetModifier {
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

        func adjust(_ item: WorklistBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the worklist budget steps in order and keeps a trace of each.
    final class WorklistBudgetEngine {
        var steps: [any WorklistBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WorklistBudget) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [WorklistBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWorklistBudgetEngine(_ flags: Kit.Flags.Registry) -> WorklistBudgetEngine {
        return WorklistBudgetEngine(
            steps: [
                LabelWorklistBudgetAdjuster(factors: ["west": 1.2, "east": 1.38]),
                WorklistBudgetRefillsOffsetAdjuster(weight: 0.79),
                TieredWorklistBudgetAdjuster(bounds: [2647.0, 7401.0], rates: [0.83, 0.84]),
                MinimumWorklistBudgetAdjuster(minimum: 6.2),
                FlaggedWorklistBudgetAdjuster(flags: flags, flag: "worklist-budget-batched", percent: 0.3),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 78370.0
        )
    }
}
