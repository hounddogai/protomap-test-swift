import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession budget calculation.
    protocol AccessionBudgetStep {
        func describe() -> String
        func adjust(_ item: AccessionBudget, value: Double) -> Double
    }

    final class FlaggedAccessionBudgetAdjuster: AccessionBudgetStep {
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

        func adjust(_ item: AccessionBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAccessionBudgetAdjuster: AccessionBudgetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAccessionBudgetAdjuster: AccessionBudgetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AccessionBudgetUpdatedAtOffsetAdjuster: AccessionBudgetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: AccessionBudget, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class LabelAccessionBudgetAdjuster: AccessionBudgetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AccessionBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAccessionBudgetAdjuster: AccessionBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the accession budget steps in order and keeps a trace of each.
    final class AccessionBudgetEngine {
        var steps: [any AccessionBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AccessionBudget) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionBudgetStep = steps[index]
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

        func evaluateAll(_ items: [AccessionBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAccessionBudgetEngine(_ flags: Kit.Flags.Registry) -> AccessionBudgetEngine {
        return AccessionBudgetEngine(
            steps: [
                FlaggedAccessionBudgetAdjuster(flags: flags, flag: "accession-budget-adaptive", percent: 2.6),
                TieredAccessionBudgetAdjuster(bounds: [511.0, 922.0, 7576.0], rates: [1.18, 0.92, 1.1]),
                PercentAccessionBudgetAdjuster(percent: 16.8),
                AccessionBudgetUpdatedAtOffsetAdjuster(weight: 1.82),
                LabelAccessionBudgetAdjuster(factors: ["online": 1.31]),
                CapAccessionBudgetAdjuster(cap: 14473.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 69572.9
        )
    }
}
