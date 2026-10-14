import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution budget calculation.
    protocol SubstitutionBudgetModifier {
        func describe() -> String
        func adjust(_ item: SubstitutionBudget, value: Double) -> Double
    }

    final class FlaggedSubstitutionBudgetAdjuster: SubstitutionBudgetModifier {
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

        func adjust(_ item: SubstitutionBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleSubstitutionBudgetAdjuster: SubstitutionBudgetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SubstitutionBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SubstitutionBudgetUpdatedAtOffsetAdjuster: SubstitutionBudgetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: SubstitutionBudget, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CapSubstitutionBudgetAdjuster: SubstitutionBudgetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SubstitutionBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the substitution budget steps in order and keeps a trace of each.
    final class SubstitutionBudgetEngine {
        var steps: [any SubstitutionBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SubstitutionBudget) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [SubstitutionBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSubstitutionBudgetEngine(_ flags: Kit.Flags.Registry) -> SubstitutionBudgetEngine {
        return SubstitutionBudgetEngine(
            steps: [
                FlaggedSubstitutionBudgetAdjuster(flags: flags, flag: "substitution-budget-legacy", percent: 7.4),
                TitleSubstitutionBudgetAdjuster(factors: ["online": 0.79, "retail": 0.93]),
                SubstitutionBudgetUpdatedAtOffsetAdjuster(weight: 1.57),
                CapSubstitutionBudgetAdjuster(cap: 18156.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 56862.8
        )
    }
}
